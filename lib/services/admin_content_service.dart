import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminContentService {
  AdminContentService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _categories => _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _challenges => _db.collection('challenges');
  CollectionReference<Map<String, dynamic>> get _songs => _db.collection('songs');
  CollectionReference<Map<String, dynamic>> get _wordSets => _db.collection('wordSets');

  /// Imports the seed format you generated earlier:
  /// {
  ///   "challenges":[{challengeId, doc, songs:[{songId, doc:{artist,title,wordSetId}}]}],
  ///   "wordSets":[{wordSetId, doc:{words:[...]}}]
  /// }
  ///
  /// In THIS repository schema:
  /// - songs are stored in /songs (global) with {challengeId, title, artist, keywords[], year}
  /// - challenges keep songIds[] + totalSongs
  ///
  /// We map:
  /// - seed doc.categoryId: "artist" => "artist_discography", "playlist" => "playlists"
  /// - seed wordSets.words => song.keywords
  Future<void> importSeedJson(String jsonText) async {
    final Map<String, dynamic> root = json.decode(jsonText) as Map<String, dynamic>;

    final List<dynamic> challenges = (root['challenges'] as List<dynamic>? ?? <dynamic>[]);
    final List<dynamic> wordSets = (root['wordSets'] as List<dynamic>? ?? <dynamic>[]);

    // 1) Write wordSets (optional but useful)
    await _writeInBatches(wordSets, (batch, item) {
      final m = item as Map<String, dynamic>;
      final wordSetId = (m['wordSetId'] ?? '').toString().trim();
      if (wordSetId.isEmpty) throw FormatException('Missing wordSetId');

      final doc = Map<String, dynamic>.from(m['doc'] as Map);
      batch.set(
        _wordSets.doc(wordSetId),
        {
          ...doc,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    // Cache wordSets in memory for keyword mapping
    final Map<String, List<String>> wordSetCache = {};
    for (final ws in wordSets) {
      final m = ws as Map<String, dynamic>;
      final id = (m['wordSetId'] ?? '').toString();
      final words = (m['doc']?['words'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      wordSetCache[id] = words;
    }

    // 2) Write challenges + songs
    for (final c in challenges) {
      final m = c as Map<String, dynamic>;
      final challengeId = (m['challengeId'] ?? '').toString().trim();
      if (challengeId.isEmpty) throw FormatException('Missing challengeId');

      final doc = Map<String, dynamic>.from(m['doc'] as Map);

      final String seedCategory = (doc['categoryId'] ?? '').toString();
      final mappedCategoryId = _mapSeedCategoryToRepoCategory(seedCategory);

      // Songs
      final List<dynamic> songs = (m['songs'] as List<dynamic>? ?? <dynamic>[]);
      final List<String> songIds = [];

      // Write challenge doc first
      await _challenges.doc(challengeId).set({
        // prefer repo schema fields
        'categoryId': mappedCategoryId,
        'title': (doc['title'] ?? challengeId).toString(),
        'subtitle': (doc['subtitle'] as String?) ?? null,
        'description': (doc['description'] as String?) ?? null,
        'type': (doc['type'] ?? seedCategory).toString().isEmpty ? 'mixed' : (doc['type'] ?? seedCategory).toString(),
        'difficulty': (doc['difficulty'] ?? 'medium').toString(),
        'language': (doc['language'] ?? 'tr').toString(),
        'priceUsd': (doc['priceUsd'] is num) ? (doc['priceUsd'] as num).toDouble() : 0.0,
        'isFree': (doc['isFree'] as bool?) ?? true,
        'isActive': (doc['isActive'] as bool?) ?? true,
        'playCount': (doc['playCount'] as int?) ?? 0,
        // will be updated after songs written
        'songIds': <String>[],
        'totalSongs': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Write songs in batches
      await _writeInBatches(songs, (batch, item) {
        final s = item as Map<String, dynamic>;
        final songId = (s['songId'] ?? '').toString().trim();
        if (songId.isEmpty) throw FormatException('Missing songId in challenge=$challengeId');

        final sdoc = Map<String, dynamic>.from(s['doc'] as Map);
        final artist = (sdoc['artist'] ?? '').toString();
        final title = (sdoc['title'] ?? '').toString();
        final wordSetId = (sdoc['wordSetId'] ?? '').toString();

        // keywords: prefer wordSets.words if present
        final keywords = (wordSetCache[wordSetId] ?? <String>[])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        songIds.add(songId);

        batch.set(
          _songs.doc(songId),
          {
            'id': songId,
            'challengeId': challengeId,
            'title': title,
            'artist': artist,
            'album': sdoc['album'],
            'keywords': keywords,
            'year': (sdoc['year'] is int) ? sdoc['year'] : 2000,
            'previewUrl': sdoc['previewUrl'],
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // Update challenge songIds + totalSongs
      songIds.sort();
      await _challenges.doc(challengeId).set({
        'songIds': songIds,
        'totalSongs': songIds.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> rebuildChallengeSongIds(String challengeId) async {
    final songsSnap = await _songs.where('challengeId', isEqualTo: challengeId).get();
    final ids = songsSnap.docs.map((d) => d.id).toSet().toList()..sort();

    await _challenges.doc(challengeId).set({
      'songIds': ids,
      'totalSongs': ids.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // -------------------------
  // CRUD helpers
  // -------------------------

  Future<void> upsertCategory({
    required String id,
    required String title,
    required String description,
    required String iconEmoji,
    required String type,
    required String language,
    required double priceUsd,
    required bool isActive,
    required int sortOrder,
  }) async {
    await _categories.doc(id).set({
      'id': id,
      'title': title,
      'description': description,
      'iconEmoji': iconEmoji,
      'type': type,
      'language': language,
      'priceUsd': priceUsd,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  Future<void> updateChallenge(String challengeId, Map<String, dynamic> patch) async {
    await _challenges.doc(challengeId).set({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteChallenge(String challengeId) async {
    // delete songs referencing this challenge (optional, but usually desired)
    final songs = await _songs.where('challengeId', isEqualTo: challengeId).get();
    await _writeInBatches(songs.docs, (batch, doc) => batch.delete(doc.reference));

    await _challenges.doc(challengeId).delete();
  }

  Future<void> upsertSong({
    required String songId,
    required String challengeId,
    required String title,
    required String artist,
    required int year,
    required List<String> keywords,
    String? album,
    String? previewUrl,
  }) async {
    await _songs.doc(songId).set({
      'id': songId,
      'challengeId': challengeId,
      'title': title,
      'artist': artist,
      'album': album,
      'year': year,
      'keywords': keywords.toSet().toList()..sort(),
      'previewUrl': previewUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // keep challenge songIds consistent
    await rebuildChallengeSongIds(challengeId);
  }

  Future<void> deleteSong(String songId) async {
    final doc = await _songs.doc(songId).get();
    final challengeId = (doc.data()?['challengeId'] ?? '').toString();
    await _songs.doc(songId).delete();
    if (challengeId.isNotEmpty) {
      await rebuildChallengeSongIds(challengeId);
    }
  }

  Future<void> upsertWordSet({
    required String wordSetId,
    required List<String> words,
  }) async {
    await _wordSets.doc(wordSetId).set({
      'words': words.toSet().toList()..sort(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteWordSet(String wordSetId) => _wordSets.doc(wordSetId).delete();

  // -------------------------
  // internal
  // -------------------------

  String _mapSeedCategoryToRepoCategory(String seedCategoryId) {
    switch (seedCategoryId) {
      case 'artist':
        return 'artist_discography';
      case 'playlist':
        return 'playlists';
      case 'album':
        return 'best_albums';
      default:
        // fallback: if you pass a real categoryId, keep it
        return seedCategoryId.isEmpty ? 'playlists' : seedCategoryId;
    }
  }

  Future<void> _writeInBatches<T>(
    List<T> items,
    void Function(WriteBatch batch, T item) writer,
  ) async {
    const maxBatch = 450;
    for (var i = 0; i < items.length; i += maxBatch) {
      final chunk = items.sublist(i, (i + maxBatch).clamp(0, items.length));
      final batch = _db.batch();
      for (final item in chunk) {
        writer(batch, item);
      }
      await batch.commit();
    }
  }
}
