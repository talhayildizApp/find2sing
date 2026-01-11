import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../models/word_set_model.dart';

class ChallengeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _db.collection('challenges');

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('categories');

  CollectionReference<Map<String, dynamic>> get _songsRef =>
      _db.collection('songs');

  CollectionReference<Map<String, dynamic>> get _wordIndexRef =>
      _db.collection('challengeWordIndex');

  CollectionReference<Map<String, dynamic>> get _challengeRunsRef =>
      _db.collection('challengeRuns');

  Stream<List<CategoryModel>> getCategories({String? language}) {
    Query<Map<String, dynamic>> query = _categoriesRef
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder');
    if (language != null) {
      query = query.where('language', isEqualTo: language);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    });
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    final doc = await _categoriesRef.doc(categoryId).get();
    if (!doc.exists) return null;
    return CategoryModel.fromFirestore(doc);
  }

  Stream<List<CategoryModel>> getCategoriesByLanguage(String language) {
    // Simplified query - filter client-side to avoid composite index requirement
    return _categoriesRef
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .where((cat) => cat.isActive && cat.language == language)
          .toList();
      // Sort by sortOrder
      categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    });
  }

  Stream<List<ChallengeModel>> getChallengesByCategory(String categoryId) {
    // Client-side filtering to avoid composite index
    return _challengesRef
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .where((c) => c.isActive)
          .toList();
    });
  }

  /// Get challenge count for a category (real-time)
  Stream<int> getChallengeCountByCategory(String categoryId) {
    return _challengesRef
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .where((c) => c.isActive)
          .length;
    });
  }

  Stream<List<ChallengeModel>> getChallengesByLanguage(String language) {
    return _challengesRef
        .where('language', isEqualTo: language)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
    });
  }

  Future<ChallengeModel?> getChallenge(String challengeId) async {
    final doc = await _challengesRef.doc(challengeId).get();
    if (!doc.exists) return null;
    return ChallengeModel.fromFirestore(doc);
  }

  Stream<List<ChallengeModel>> getPopularChallenges({int limit = 10}) {
    // Client-side filtering to avoid composite index requirement
    return _challengesRef
        .snapshots()
        .map((snapshot) {
      final challenges = snapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .where((c) => c.isActive)
          .toList();
      // Sort by playCount descending
      challenges.sort((a, b) => b.playCount.compareTo(a.playCount));
      return challenges.take(limit).toList();
    });
  }

  /// Get featured challenges (isFeatured = true)
  Stream<List<ChallengeModel>> getFeaturedChallenges({int limit = 10}) {
    // Client-side filtering to avoid composite index requirement
    return _challengesRef
        .snapshots()
        .map((snapshot) {
      final challenges = snapshot.docs
          .map((doc) => ChallengeModel.fromFirestore(doc))
          .where((c) => c.isActive && c.isFeatured)
          .toList();
      // Sort by playCount descending for featured challenges
      challenges.sort((a, b) => b.playCount.compareTo(a.playCount));
      return challenges.take(limit).toList();
    });
  }

  Stream<List<ChallengeModel>> getFreeChallenges() {
    return _challengesRef
        .where('isActive', isEqualTo: true)
        .where('isFree', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
    });
  }

  Future<List<ChallengeSongModel>> getChallengeSongs(String challengeId) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null) return [];
    final songs = <ChallengeSongModel>[];
    for (final songId in challenge.songIds) {
      final doc = await _songsRef.doc(songId).get();
      if (doc.exists) {
        songs.add(ChallengeSongModel.fromFirestore(doc));
      }
    }
    return songs;
  }

  Stream<ChallengeProgressModel?> getChallengeProgress(String oderId, String challengeId) {
    return _db
        .collection('users')
        .doc(oderId)
        .collection('challengeProgress')
        .doc(challengeId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ChallengeProgressModel.fromFirestore(doc);
    });
  }

  Stream<List<ChallengeProgressModel>> getAllProgress(String oderId) {
    return _db
        .collection('users')
        .doc(oderId)
        .collection('challengeProgress')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeProgressModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> saveProgress(String oderId, ChallengeProgressModel progress) async {
    await _db
        .collection('users')
        .doc(oderId)
        .collection('challengeProgress')
        .doc(progress.challengeId)
        .set(progress.toFirestore(), SetOptions(merge: true));
  }

  Future<void> incrementPlayCount(String challengeId) async {
    await _challengesRef.doc(challengeId).update({
      'playCount': FieldValue.increment(1),
    });
  }

  Future<String> createCategory(CategoryModel category) async {
    final doc = await _categoriesRef.add(category.toFirestore());
    return doc.id;
  }

  Future<String> createChallenge(ChallengeModel challenge) async {
    final doc = await _challengesRef.add(challenge.toFirestore());
    await _categoriesRef.doc(challenge.categoryId).update({
      'challengeCount': FieldValue.increment(1),
      'challengeIds': FieldValue.arrayUnion([doc.id]),
    });
    return doc.id;
  }

  Future<String> createSong(ChallengeSongModel song) async {
    final doc = await _songsRef.add(song.toFirestore());
    return doc.id;
  }

  Future<List<String>> createSongsBatch(List<ChallengeSongModel> songs) async {
    final batch = _db.batch();
    final ids = <String>[];
    for (final song in songs) {
      final doc = _songsRef.doc();
      batch.set(doc, song.toFirestore());
      ids.add(doc.id);
    }
    await batch.commit();
    return ids;
  }

  // ==================== WORD INDEX METHODS ====================

  /// Get challenge songs with word sets
  Future<List<ChallengeSongWithWords>> getChallengeSongsWithWords(String challengeId) async {
    final snapshot = await _challengesRef
        .doc(challengeId)
        .collection('songs')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ChallengeSongWithWords.fromFirestore(doc))
        .toList();
  }

  /// Get random eligible word for challenge
  Future<String?> getRandomEligibleWord(String challengeId, List<String> solvedSongIds) async {
    final wordIndexDocs = await _wordIndexRef
        .where('challengeId', isEqualTo: challengeId)
        .get();

    final eligibleWords = <ChallengeWordIndexModel>[];

    for (final doc in wordIndexDocs.docs) {
      final wordIndex = ChallengeWordIndexModel.fromFirestore(doc);
      if (wordIndex.hasUnsolvedSongs(solvedSongIds)) {
        eligibleWords.add(wordIndex);
      }
    }

    if (eligibleWords.isEmpty) return null;

    return eligibleWords[_random.nextInt(eligibleWords.length)].word;
  }

  /// Validate song selection for a word
  Future<bool> validateSongSelection(String challengeId, String word, String songId) async {
    final indexDoc = await _wordIndexRef.doc('${challengeId}_$word').get();
    if (!indexDoc.exists) return false;

    final songIds = List<String>.from(indexDoc.data()?['songIds'] ?? []);
    return songIds.contains(songId);
  }

  /// Get word index for a specific word
  Future<ChallengeWordIndexModel?> getWordIndex(String challengeId, String word) async {
    final doc = await _wordIndexRef.doc('${challengeId}_$word').get();
    if (!doc.exists) return null;
    return ChallengeWordIndexModel.fromFirestore(doc);
  }

  /// Get all words for a challenge
  Future<List<String>> getAllChallengeWords(String challengeId) async {
    final snapshot = await _wordIndexRef
        .where('challengeId', isEqualTo: challengeId)
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['word'] as String)
        .toList();
  }

  // ==================== USER PROGRESS METHODS ====================

  /// Get user challenge progress
  Future<UserChallengeProgressModel?> getUserProgress(String uid, String challengeId) async {
    final doc = await _db
        .collection('userChallengeProgress')
        .doc('${uid}_$challengeId')
        .get();

    if (!doc.exists) return null;
    return UserChallengeProgressModel.fromFirestore(doc);
  }

  /// Update user challenge progress
  Future<void> updateUserProgress(String uid, String challengeId, String solvedSongId) async {
    final docRef = _db.collection('userChallengeProgress').doc('${uid}_$challengeId');
    
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      if (doc.exists) {
        transaction.update(docRef, {
          'solvedSongIds': FieldValue.arrayUnion([solvedSongId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'uid': uid,
          'challengeId': challengeId,
          'solvedSongIds': [solvedSongId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get songs for a challenge
  Future<List<ChallengeSongModel>> getSongsForChallenge(String challengeId) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null) return [];

    final songs = <ChallengeSongModel>[];
    for (final songId in challenge.songIds) {
      final doc = await _songsRef.doc(songId).get();
      if (doc.exists) {
        songs.add(ChallengeSongModel.fromFirestore(doc));
      }
    }
    return songs;
  }

  /// Get next word for challenge (with word index)
  Future<String?> getNextWord(String challengeId, List<String> solvedSongIds) async {
    // Try word index first
    final indexDocs = await _wordIndexRef
        .where('challengeId', isEqualTo: challengeId)
        .get();

    if (indexDocs.docs.isEmpty) {
      // Fallback: get word directly from songs
      return _getWordFromSongs(challengeId, solvedSongIds);
    }

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
    final index = _random.nextInt(eligibleWords.length);
    return eligibleWords[index];
  }

  /// Fallback: get word directly from songs
  Future<String?> _getWordFromSongs(String challengeId, List<String> solvedSongIds) async {
    final songs = await getSongsForChallenge(challengeId);
    final unsolvedSongs = songs.where((s) => !solvedSongIds.contains(s.id)).toList();
    
    if (unsolvedSongs.isEmpty) return null;

    // Collect all keywords from unsolved songs
    final allWords = <String>[];
    for (final song in unsolvedSongs) {
      allWords.addAll(song.topKeywords.isNotEmpty ? song.topKeywords : song.keywords);
    }

    if (allWords.isEmpty) return null;

    final index = _random.nextInt(allWords.length);
    return allWords[index];
  }

  /// Validate song selection - check if the word belongs to the selected song
  Future<bool> validateSelection(String challengeId, String word, String songId) async {
    final normalizedWord = word.toLowerCase().trim();
    
    // First try word index
    final docId = '${challengeId}_$normalizedWord';
    final indexDoc = await _wordIndexRef.doc(docId).get();
    
    if (indexDoc.exists) {
      final songIds = List<String>.from(indexDoc.data()?['songIds'] ?? []);
      return songIds.contains(songId);
    }

    // Fallback: check song directly
    final songDoc = await _songsRef.doc(songId).get();
    if (!songDoc.exists) return false;

    final song = ChallengeSongModel.fromFirestore(songDoc);
    return song.containsWord(word);
  }

  /// Get songs that contain a specific word
  Future<List<String>> getSongsForWord(String challengeId, String word) async {
    final normalizedWord = word.toLowerCase().trim();
    final docId = '${challengeId}_$normalizedWord';
    
    final indexDoc = await _wordIndexRef.doc(docId).get();
    if (indexDoc.exists) {
      return List<String>.from(indexDoc.data()?['songIds'] ?? []);
    }

    // Fallback: search songs directly
    final songs = await getSongsForChallenge(challengeId);
    return songs
        .where((s) => s.containsWord(word))
        .map((s) => s.id)
        .toList();
  }

  // ==================== CHALLENGE RUNS & LEADERBOARD ====================

  /// Save a challenge run
  Future<String> saveChallengeRun(ChallengeRunModel run) async {
    final docRef = await _challengeRunsRef.add(run.toFirestore());
    
    // Update leaderboard if Real mode and finished
    if (run.mode == 'real' && run.finished) {
      await _updateLeaderboardEntry(run);
    }
    
    return docRef.id;
  }

  /// Update leaderboard for Real mode
  Future<void> _updateLeaderboardEntry(ChallengeRunModel run) async {
    final leaderboardRef = _db
        .collection('leaderboards')
        .doc(run.challengeId)
        .collection('real')
        .doc(run.uid);

    final existing = await leaderboardRef.get();
    
    if (!existing.exists) {
      await leaderboardRef.set({
        'uid': run.uid,
        'bestScore': run.score,
        'bestDurationMs': run.durationMs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final currentBest = existing.data()?['bestScore'] ?? 0;
      if (run.score > currentBest) {
        await leaderboardRef.update({
          'bestScore': run.score,
          'bestDurationMs': run.durationMs,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Get leaderboard for a challenge (Real mode only)
  Future<List<LeaderboardEntry>> getLeaderboard(String challengeId, {int limit = 50}) async {
    final snapshot = await _db
        .collection('leaderboards')
        .doc(challengeId)
        .collection('real')
        .orderBy('bestScore', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => LeaderboardEntry.fromFirestore(doc)).toList();
  }

  /// Get user's rank on leaderboard
  Future<int?> getUserRank(String challengeId, String uid) async {
    final userDoc = await _db
        .collection('leaderboards')
        .doc(challengeId)
        .collection('real')
        .doc(uid)
        .get();

    if (!userDoc.exists) return null;

    final userScore = userDoc.data()?['bestScore'] ?? 0;
    
    final higherScores = await _db
        .collection('leaderboards')
        .doc(challengeId)
        .collection('real')
        .where('bestScore', isGreaterThan: userScore)
        .count()
        .get();

    return (higherScores.count ?? 0) + 1;
  }

  /// Get user's challenge runs
  Future<List<ChallengeRunModel>> getUserRuns(String uid, String challengeId) async {
    final snapshot = await _challengeRunsRef
        .where('uid', isEqualTo: uid)
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => ChallengeRunModel.fromFirestore(doc)).toList();
  }
}

/// Challenge run model
class ChallengeRunModel {
  final String id;
  final String uid;
  final String challengeId;
  final String mode; // 'timeRace', 'relax', 'real'
  final int score;
  final int correct;
  final int wrong;
  final int durationMs;
  final bool finished;
  final DateTime createdAt;

  ChallengeRunModel({
    required this.id,
    required this.uid,
    required this.challengeId,
    required this.mode,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.durationMs,
    required this.finished,
    required this.createdAt,
  });

  factory ChallengeRunModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeRunModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      challengeId: data['challengeId'] ?? '',
      mode: data['mode'] ?? 'relax',
      score: data['score'] ?? 0,
      correct: data['correct'] ?? 0,
      wrong: data['wrong'] ?? 0,
      durationMs: data['durationMs'] ?? 0,
      finished: data['finished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'challengeId': challengeId,
      'mode': mode,
      'score': score,
      'correct': correct,
      'wrong': wrong,
      'durationMs': durationMs,
      'finished': finished,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Leaderboard entry
class LeaderboardEntry {
  final String uid;
  final int bestScore;
  final int bestDurationMs;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.bestScore,
    required this.bestDurationMs,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      uid: doc.id,
      bestScore: data['bestScore'] ?? 0,
      bestDurationMs: data['bestDurationMs'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
