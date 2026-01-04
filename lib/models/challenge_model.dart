import 'package:cloud_firestore/cloud_firestore.dart';

/// Challenge türleri
enum ChallengeType {
  artist,    // Sanatçı challenge (Tarkan, Sezen Aksu...)
  album,     // Albüm challenge
  playlist,  // Playlist/Tema challenge (90'lar, Rock...)
  mixed,     // Karışık
  era,       // Dönem challenge (90'lar, 2000'ler)
}

/// Challenge zorluğu
enum ChallengeDifficulty {
  easy,    // Kolay - popüler şarkılar
  medium,  // Orta
  hard,    // Zor - az bilinen şarkılar
}

/// Challenge oyun modu
enum ChallengePlayMode {
  solo,           // Tek oyunculu (aynı cihaz, mod seçimi sonra)
  friends,        // Arkadaşla (aynı cihaz)
  onlineTimeRace, // Online Time Race
  onlineRelax,    // Online Relax
  onlineReal,     // Online Real
}

/// Single-player challenge modları
enum ChallengeSingleMode {
  timeRace,  // Sabit süre (5dk), yanlış = 3s freeze
  relax,     // 30s/round, yanlış = 1s freeze (her 3 yanlışta +1s)
  real,      // 30s/round, doğru +1, yanlış -3 (leaderboard'a gider)
}

/// Tek bir Challenge
class ChallengeModel {
  final String id;
  final String categoryId;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final String language;
  
  final List<String> songIds;
  final int totalSongs;
  
  final double priceUsd;
  final bool isFree;
  
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int playCount;

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
      case ChallengeType.era:
        return 'Dönem';
    }
  }
}

/// Challenge Kategorisi
class CategoryModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String language;
  final String? iconEmoji;
  
  final int challengeCount;
  final List<String> challengeIds;
  
  final double priceUsd;
  final double discountPercent;
  
  final bool isActive;
  final int sortOrder;
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

  double get originalPrice => challengeCount * 0.99;
  double get savings => originalPrice - priceUsd;
}

/// Kullanıcının Challenge İlerlemesi
class ChallengeProgressModel {
  final String id;
  final String oderId;
  final String challengeId;
  final int foundSongs;
  final int totalSongs;
  final List<String> foundSongIds;
  final int bestTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime startedAt;
  final DateTime lastPlayedAt;
  final int playCount;

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

  double get progressPercent {
    if (totalSongs == 0) return 0;
    return (foundSongs / totalSongs) * 100;
  }

  String get progressText => '$foundSongs / $totalSongs';
}

/// Challenge içindeki şarkı (UPDATED - topKeywords, lyricsRaw dahil)
class ChallengeSongModel {
  final String id;
  final String categoryId;
  final String challengeId;
  final String language;
  final String title;
  final String artist;
  final String? album;
  final int year;
  final String? previewUrl;
  final String? lyricsRaw;
  final List<String> keywords;      // Unique, sorted (tümü)
  final List<String> topKeywords;   // Ranked by frequency (oyunda kullanılacak)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChallengeSongModel({
    required this.id,
    required this.categoryId,
    required this.challengeId,
    required this.language,
    required this.title,
    required this.artist,
    this.album,
    required this.year,
    this.previewUrl,
    this.lyricsRaw,
    required this.keywords,
    List<String>? topKeywords,
    this.createdAt,
    this.updatedAt,
  }) : topKeywords = topKeywords ?? keywords;

  factory ChallengeSongModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final kw = List<String>.from(data['keywords'] ?? []);
    
    return ChallengeSongModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      challengeId: data['challengeId'] ?? '',
      language: data['language'] ?? 'tr',
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      album: data['album'],
      year: data['year'] ?? 0,
      previewUrl: data['previewUrl'],
      lyricsRaw: data['lyricsRaw'],
      keywords: kw,
      topKeywords: List<String>.from(data['topKeywords'] ?? kw),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'categoryId': categoryId,
      'challengeId': challengeId,
      'language': language,
      'title': title,
      'artist': artist,
      'album': album,
      'year': year,
      'previewUrl': previewUrl,
      'lyricsRaw': lyricsRaw,
      'keywords': keywords,
      'topKeywords': topKeywords,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get displayName => '$artist - $title';
  
  /// Şarkının belirli bir kelimeyi içerip içermediğini kontrol et
  bool containsWord(String word) {
    final normalizedWord = word.toLowerCase().trim();
    return topKeywords.any((k) => k.toLowerCase() == normalizedWord) ||
           keywords.any((k) => k.toLowerCase() == normalizedWord);
  }
}
