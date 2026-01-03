import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';

class ChallengeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _db.collection('challenges');

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('categories');

  CollectionReference<Map<String, dynamic>> get _songsRef =>
      _db.collection('songs');

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
    return _categoriesRef
        .where('isActive', isEqualTo: true)
        .where('language', isEqualTo: language)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<ChallengeModel>> getChallengesByCategory(String categoryId) {
    return _challengesRef
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
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
    return _challengesRef
        .where('isActive', isEqualTo: true)
        .orderBy('playCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
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
}
