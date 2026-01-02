import 'package:cloud_firestore/cloud_firestore.dart';

/// Challenge türleri
enum ChallengeType {
  artist,    // Sanatçı challenge (Tarkan, Sezen Aksu...)
  album,     // Albüm challenge
  playlist,  // Playlist/Tema challenge (90'lar, Rock...)
  mixed,     // Karışık
}

/// Challenge zorluğu
enum ChallengeDifficulty {
  easy,    // Kolay - popüler şarkılar
  medium,  // Orta
  hard,    // Zor - az bilinen şarkılar
}

/// Tek bir Challenge
class ChallengeModel {
  final String id;
  final String categoryId; // Hangi kategoriye ait
  final String title; // "Tarkan Challenge"
  final String? subtitle; // "90'ların efsanesi"
  final String? description;
  final String? imageUrl; // Kapak görseli
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final String language; // 'tr' veya 'en'
  
  // Challenge içeriği
  final List<String> songIds; // Şarkı ID'leri
  final int totalSongs; // Toplam şarkı sayısı
  
  // Fiyatlandırma
  final double priceUsd; // $0.99
  final bool isFree; // Ücretsiz mi?
  
  // Meta
  final bool isActive; // Yayında mı?
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int playCount; // Kaç kez oynandı

  ChallengeModel({
    required this.id,
    required this.categoryId,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.type,
    this.difficulty = ChallengeDifficulty.medium,
    required this.language,
    required this.songIds,
    required this.totalSongs,
    this.priceUsd = 0.99,
    this.isFree = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.playCount = 0,
  });

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChallengeModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      type: ChallengeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChallengeType.mixed,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => ChallengeDifficulty.medium,
      ),
      language: data['language'] ?? 'tr',
      songIds: List<String>.from(data['songIds'] ?? []),
      totalSongs: data['totalSongs'] ?? 0,
      priceUsd: (data['priceUsd'] ?? 0.99).toDouble(),
      isFree: data['isFree'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      playCount: data['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'difficulty': difficulty.name,
      'language': language,
      'songIds': songIds,
      'totalSongs': totalSongs,
      'priceUsd': priceUsd,
      'isFree': isFree,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'playCount': playCount,
    };
  }

  /// Zorluk etiketi
  String get difficultyLabel {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Kolay';
      case ChallengeDifficulty.medium:
        return 'Orta';
      case ChallengeDifficulty.hard:
        return 'Zor';
    }
  }

  /// Tür etiketi
  String get typeLabel {
    switch (type) {
      case ChallengeType.artist:
        return 'Sanatçı';
      case ChallengeType.album:
        return 'Albüm';
      case ChallengeType.playlist:
        return 'Playlist';
      case ChallengeType.mixed:
        return 'Karışık';
    }
  }
}

/// Challenge Kategorisi
class CategoryModel {
  final String id;
  final String title; // "Türkçe Pop"
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String language; // 'tr' veya 'en'
  final String? iconEmoji; // 🎤
  
  // İçerik
  final int challengeCount; // Bu kategorideki challenge sayısı
  final List<String> challengeIds; // Challenge ID'leri
  
  // Fiyatlandırma
  final double priceUsd; // Hesaplanmış kategori fiyatı
  final double discountPercent; // %40 indirim
  
  // Meta
  final bool isActive;
  final int sortOrder; // Sıralama
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.language,
    this.iconEmoji,
    required this.challengeCount,
    required this.challengeIds,
    required this.priceUsd,
    this.discountPercent = 40.0,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CategoryModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      language: data['language'] ?? 'tr',
      iconEmoji: data['iconEmoji'],
      challengeCount: data['challengeCount'] ?? 0,
      challengeIds: List<String>.from(data['challengeIds'] ?? []),
      priceUsd: (data['priceUsd'] ?? 0).toDouble(),
      discountPercent: (data['discountPercent'] ?? 40.0).toDouble(),
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'language': language,
      'iconEmoji': iconEmoji,
      'challengeCount': challengeCount,
      'challengeIds': challengeIds,
      'priceUsd': priceUsd,
      'discountPercent': discountPercent,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Normal fiyat (indirim öncesi)
  double get originalPrice => challengeCount * 0.99;

  /// Tasarruf miktarı
  double get savings => originalPrice - priceUsd;
}

/// Kullanıcının Challenge İlerlemesi
class ChallengeProgressModel {
  final String id;
  final String oderId;
  final String challengeId;
  final int foundSongs; // Bulunan şarkı sayısı
  final int totalSongs; // Toplam şarkı sayısı
  final List<String> foundSongIds; // Bulunan şarkı ID'leri
  final int bestTime; // En iyi süre (saniye)
  final bool isCompleted; // Tamamlandı mı?
  final DateTime? completedAt;
  final DateTime startedAt;
  final DateTime lastPlayedAt;
  final int playCount; // Kaç kez oynandı

  ChallengeProgressModel({
    required this.id,
    required this.challengeId,
    required this.oderId,
    this.foundSongs = 0,
    required this.totalSongs,
    this.foundSongIds = const [],
    this.bestTime = 0,
    this.isCompleted = false,
    this.completedAt,
    required this.startedAt,
    required this.lastPlayedAt,
    this.playCount = 0,
  });

  factory ChallengeProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChallengeProgressModel(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      oderId: data['oderId'] ?? '',
      foundSongs: data['foundSongs'] ?? 0,
      totalSongs: data['totalSongs'] ?? 0,
      foundSongIds: List<String>.from(data['foundSongIds'] ?? []),
      bestTime: data['bestTime'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPlayedAt: (data['lastPlayedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      playCount: data['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'oderId': oderId,
      'foundSongs': foundSongs,
      'totalSongs': totalSongs,
      'foundSongIds': foundSongIds,
      'bestTime': bestTime,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'startedAt': Timestamp.fromDate(startedAt),
      'lastPlayedAt': Timestamp.fromDate(lastPlayedAt),
      'playCount': playCount,
    };
  }

  /// İlerleme yüzdesi
  double get progressPercent {
    if (totalSongs == 0) return 0;
    return (foundSongs / totalSongs) * 100;
  }

  /// Tamamlanma oranı metni
  String get progressText => '$foundSongs / $totalSongs';
}

/// Challenge içindeki şarkı
class ChallengeSongModel {
  final String id;
  final String title; // Şarkı adı
  final String artist; // Sanatçı
  final String? album; // Albüm (opsiyonel)
  final List<String> keywords; // Anahtar kelimeler (eşleşme için)
  final int year; // Çıkış yılı
  final String? previewUrl; // Şarkı önizleme (opsiyonel)

  ChallengeSongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.keywords,
    required this.year,
    this.previewUrl,
  });

  factory ChallengeSongModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChallengeSongModel(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      album: data['album'],
      keywords: List<String>.from(data['keywords'] ?? []),
      year: data['year'] ?? 0,
      previewUrl: data['previewUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'keywords': keywords,
      'year': year,
      'previewUrl': previewUrl,
    };
  }
}
