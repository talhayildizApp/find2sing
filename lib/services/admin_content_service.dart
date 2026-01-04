// lib/services/admin_content_service.dart
//
// Admin-facing Firestore helper for content management.
// Assumes collections:
// - categories/{categoryId}
// - challenges/{challengeId}
// - songs/{songId}
//
// Songs schema written by this service:
// { id, categoryId, challengeId, language, artist, title, lyricsRaw, keywords[], topKeywords[], year, album, previewUrl, updatedAt, createdAt }
//
// Challenges schema (minimum):
// { title, categoryId, language, isActive, isFree, priceUsd, songIds[], totalSongs }

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminContentService {
  AdminContentService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get categories => _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get challenges => _db.collection('challenges');
  CollectionReference<Map<String, dynamic>> get songs => _db.collection('songs');

  // --------- Category CRUD ---------

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
    await categories.doc(id).set({
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

  Future<void> deleteCategory(String id) => categories.doc(id).delete();

  // --------- Challenge CRUD ---------

  Future<void> updateChallenge(String challengeId, Map<String, dynamic> patch) async {
    await challenges.doc(challengeId).set({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteChallenge(String challengeId, {bool deleteSongsToo = true}) async {
    if (deleteSongsToo) {
      final s = await songs.where('challengeId', isEqualTo: challengeId).get();
      await _writeInBatches(s.docs, (batch, doc) => batch.delete(doc.reference));
    }
    await challenges.doc(challengeId).delete();
  }

  Future<void> rebuildChallengeSongIds(String challengeId) async {
    final s = await songs.where('challengeId', isEqualTo: challengeId).get();
    final ids = s.docs.map((d) => d.id).toSet().toList()..sort();
    await challenges.doc(challengeId).set({
      'songIds': ids,
      'totalSongs': ids.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --------- Song CRUD ---------

  Future<void> upsertSong({
    required String songId,
    required String categoryId,
    required String challengeId,
    required String languageCode, // tr/en/de/es
    required String artist,
    required String title,
    required String lyricsRaw,
    required List<String> keywords,
    required List<String> topKeywords,
    int year = 2000,
    String? album,
    String? previewUrl,
  }) async {
    await songs.doc(songId).set({
      'id': songId,
      'categoryId': categoryId,
      'challengeId': challengeId,
      'language': languageCode,
      'artist': artist,
      'title': title,
      'lyricsRaw': lyricsRaw,
      'keywords': keywords.toSet().toList()..sort(),
      'topKeywords': topKeywords.toList(),
      'year': year,
      'album': album,
      'previewUrl': previewUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Keep challenge counters consistent
    await rebuildChallengeSongIds(challengeId);
  }

  Future<void> deleteSong(String songId) async {
    final doc = await songs.doc(songId).get();
    final challengeId = (doc.data()?['challengeId'] ?? '').toString();
    await songs.doc(songId).delete();
    if (challengeId.isNotEmpty) {
      await rebuildChallengeSongIds(challengeId);
    }
  }

  // --------- Word Index ---------

  CollectionReference<Map<String, dynamic>> get wordIndex => _db.collection('challengeWordIndex');

  /// Build word index for a challenge
  /// Creates challengeWordIndex/{challengeId}_{word} documents
  Future<int> buildWordIndex(String challengeId) async {
    // Get all songs for this challenge
    final songsSnapshot = await songs.where('challengeId', isEqualTo: challengeId).get();
    
    if (songsSnapshot.docs.isEmpty) {
      return 0;
    }

    // Build word -> songIds map
    final wordToSongs = <String, Set<String>>{};

    for (final songDoc in songsSnapshot.docs) {
      final data = songDoc.data();
      final songId = songDoc.id;
      
      // Get topKeywords (primary) or keywords (fallback)
      final topKeywords = List<String>.from(data['topKeywords'] ?? []);
      final keywords = List<String>.from(data['keywords'] ?? []);
      final allWords = topKeywords.isNotEmpty ? topKeywords : keywords;

      for (final word in allWords) {
        final normalizedWord = word.toLowerCase().trim();
        if (normalizedWord.length < 2) continue;
        
        wordToSongs.putIfAbsent(normalizedWord, () => <String>{});
        wordToSongs[normalizedWord]!.add(songId);
      }
    }

    // Delete existing word index for this challenge
    final existingIndex = await wordIndex
        .where('challengeId', isEqualTo: challengeId)
        .get();
    
    await _writeInBatches(existingIndex.docs, (batch, doc) => batch.delete(doc.reference));

    // Write new word index documents
    final wordEntries = wordToSongs.entries.toList();
    
    for (var i = 0; i < wordEntries.length; i += 450) {
      final chunk = wordEntries.sublist(i, (i + 450).clamp(0, wordEntries.length));
      final batch = _db.batch();
      
      for (final entry in chunk) {
        final docId = '${challengeId}_${entry.key}';
        batch.set(wordIndex.doc(docId), {
          'challengeId': challengeId,
          'word': entry.key,
          'songIds': entry.value.toList(),
        });
      }
      
      await batch.commit();
    }

    return wordToSongs.length;
  }

  /// Build word index for all challenges
  Future<Map<String, int>> buildAllWordIndexes() async {
    final results = <String, int>{};
    final challengesSnapshot = await challenges.get();
    
    for (final doc in challengesSnapshot.docs) {
      final count = await buildWordIndex(doc.id);
      results[doc.id] = count;
    }
    
    return results;
  }

  /// Get random eligible word for a challenge
  Future<String?> getRandomEligibleWord(String challengeId, List<String> solvedSongIds) async {
    final indexDocs = await wordIndex
        .where('challengeId', isEqualTo: challengeId)
        .get();

    if (indexDocs.docs.isEmpty) return null;

    // Filter words that have unsolved songs
    final eligibleWords = <String>[];
    
    for (final doc in indexDocs.docs) {
      final songIds = List<String>.from(doc.data()['songIds'] ?? []);
      final hasUnsolved = songIds.any((id) => !solvedSongIds.contains(id));
      if (hasUnsolved) {
        eligibleWords.add(doc.data()['word'] ?? '');
      }
    }

    if (eligibleWords.isEmpty) return null;

    // Random selection
    final index = DateTime.now().millisecondsSinceEpoch % eligibleWords.length;
    return eligibleWords[index];
  }

  /// Validate song selection for a word
  Future<bool> validateSongSelection(String challengeId, String word, String songId) async {
    final normalizedWord = word.toLowerCase().trim();
    final docId = '${challengeId}_$normalizedWord';
    
    final doc = await wordIndex.doc(docId).get();
    if (!doc.exists) return false;

    final songIds = List<String>.from(doc.data()?['songIds'] ?? []);
    return songIds.contains(songId);
  }

  // --------- Optional: Seed import (kept for convenience) ---------

  Future<void> importSeedJson(String jsonText) async {
    final Map<String, dynamic> root = json.decode(jsonText) as Map<String, dynamic>;
    final List<dynamic> challengesSeed = (root['challenges'] as List<dynamic>? ?? <dynamic>[]);

    for (final c in challengesSeed) {
      final m = c as Map<String, dynamic>;
      final challengeId = (m['challengeId'] ?? '').toString().trim();
      if (challengeId.isEmpty) throw FormatException('Missing challengeId');

      final doc = Map<String, dynamic>.from(m['doc'] as Map);

      await challenges.doc(challengeId).set({
        'title': (doc['title'] ?? challengeId).toString(),
        'categoryId': (doc['categoryId'] ?? '').toString(),
        'language': (doc['language'] ?? 'tr').toString(),
        'isActive': (doc['isActive'] as bool?) ?? true,
        'isFree': (doc['isFree'] as bool?) ?? true,
        'priceUsd': (doc['priceUsd'] is num) ? (doc['priceUsd'] as num).toDouble() : 0.0,
        'songIds': <String>[],
        'totalSongs': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // --------- internal ---------

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
