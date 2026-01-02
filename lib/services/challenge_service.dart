import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import 'pricing_service.dart';

/// Challenge servisi - Firestore işlemleri
class ChallengeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Koleksiyon referansları
  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _db.collection('challenges');

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('categories');

  CollectionReference<Map<String, dynamic>> get _songsRef =>
      _db.collection('songs');

  // ============ KATEGORİLER ============

  /// Tüm aktif kategorileri getir
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

  /// Tek kategori getir
  Future<CategoryModel?> getCategory(String categoryId) async {
    final doc = await _categoriesRef.doc(categoryId).get();
    if (!doc.exists) return null;
    return CategoryModel.fromFirestore(doc);
  }

  // ============ CHALLENGE'LAR ============

  /// Kategoriye göre challenge'ları getir
  Stream<List<ChallengeModel>> getChallengesByCategory(String categoryId) {
    return _challengesRef
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
    });
  }

  /// Dile göre tüm challenge'ları getir
  Stream<List<ChallengeModel>> getChallengesByLanguage(String language) {
    return _challengesRef
        .where('language', isEqualTo: language)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
    });
  }

  /// Tek challenge getir
  Future<ChallengeModel?> getChallenge(String challengeId) async {
    final doc = await _challengesRef.doc(challengeId).get();
    if (!doc.exists) return null;
    return ChallengeModel.fromFirestore(doc);
  }

  /// Popüler challenge'ları getir (en çok oynanan)
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

  /// Ücretsiz challenge'ları getir
  Stream<List<ChallengeModel>> getFreeChallenges() {
    return _challengesRef
        .where('isActive', isEqualTo: true)
        .where('isFree', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeModel.fromFirestore(doc)).toList();
    });
  }

  // ============ ŞARKILAR ============

  /// Challenge'daki şarkıları getir
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

  // ============ İLERLEME ============

  /// Kullanıcının challenge ilerlemesini getir
  Stream<ChallengeProgressModel?> getChallengeProgress(
    String oderId,
    String challengeId,
  ) {
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

  /// Kullanıcının tüm ilerlemelerini getir
  Stream<List<ChallengeProgressModel>> getAllProgress(String oderId) {
    return _db
        .collection('users')
        .doc(oderId)
        .collection('challengeProgress')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeProgressModel.fromFirestore(doc))
          .toList();
    });
  }

  /// İlerleme kaydet/güncelle
  Future<void> saveProgress(String oderId, ChallengeProgressModel progress) async {
    await _db
        .collection('users')
        .doc(oderId)
        .collection('challengeProgress')
        .doc(progress.challengeId)
        .set(progress.toFirestore(), SetOptions(merge: true));
  }

  /// Challenge oynama sayısını artır
  Future<void> incrementPlayCount(String challengeId) async {
    await _challengesRef.doc(challengeId).update({
      'playCount': FieldValue.increment(1),
    });
  }

  // ============ ADMIN İŞLEMLERİ ============
  // (Bu metodlar normalde admin panelinden kullanılır)

  /// Yeni kategori oluştur
  Future<String> createCategory(CategoryModel category) async {
    final doc = await _categoriesRef.add(category.toFirestore());
    return doc.id;
  }

  /// Yeni challenge oluştur
  Future<String> createChallenge(ChallengeModel challenge) async {
    final doc = await _challengesRef.add(challenge.toFirestore());
    
    // Kategorideki challenge sayısını güncelle
    await _categoriesRef.doc(challenge.categoryId).update({
      'challengeCount': FieldValue.increment(1),
      'challengeIds': FieldValue.arrayUnion([doc.id]),
    });
    
    // Kategori fiyatını yeniden hesapla
    await _updateCategoryPrice(challenge.categoryId);
    
    return doc.id;
  }

  /// Kategori fiyatını güncelle
  Future<void> _updateCategoryPrice(String categoryId) async {
    final category = await getCategory(categoryId);
    if (category == null) return;

    final newPrice = PricingService.calculateCategoryPrice(category.challengeCount);
    
    await _categoriesRef.doc(categoryId).update({
      'priceUsd': newPrice,
    });
  }

  /// Yeni şarkı ekle
  Future<String> createSong(ChallengeSongModel song) async {
    final doc = await _songsRef.add(song.toFirestore());
    return doc.id;
  }

  /// Toplu şarkı ekle
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
