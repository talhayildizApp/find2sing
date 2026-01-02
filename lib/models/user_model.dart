import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı seviyeleri
enum UserTier {
  guest,      // Misafir - kayıt olmamış
  free,       // Ücretsiz üye
  purchased,  // Satın alma yapmış üye (tek seferlik)
  premium,    // Premium abone (aylık)
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  // Kullanıcı seviyesi
  final UserTier tier;
  
  // Oyun istatistikleri
  final int totalSongsFound;
  final int totalGamesPlayed;
  final int totalTimePlayed; // saniye cinsinden
  
  // Kelime değiştirme hakları
  final int wordChangeCredits; // Mevcut hak (max 5)
  static const int maxWordChangeCredits = 5;
  
  // Premium abonelik
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String? premiumSubscriptionId; // Store subscription ID
  
  // Satın alımlar (tek seferlik)
  final List<String> purchasedChallenges; // challenge ID'leri
  final List<String> purchasedCategories; // kategori ID'leri
  
  // Reklam takibi
  final DateTime? lastAdWatched;
  final int totalAdsWatched;
  
  // Tercihler
  final String preferredLanguage; // 'tr' veya 'en'

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.tier = UserTier.free,
    this.totalSongsFound = 0,
    this.totalGamesPlayed = 0,
    this.totalTimePlayed = 0,
    this.wordChangeCredits = 3, // Başlangıçta 3 hak
    this.isPremium = false,
    this.premiumExpiresAt,
    this.premiumSubscriptionId,
    this.purchasedChallenges = const [],
    this.purchasedCategories = const [],
    this.lastAdWatched,
    this.totalAdsWatched = 0,
    this.preferredLanguage = 'tr',
  });

  /// Firestore'dan UserModel oluştur
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Oyuncu',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tier: UserTier.values.firstWhere(
        (e) => e.name == data['tier'],
        orElse: () => UserTier.free,
      ),
      totalSongsFound: data['totalSongsFound'] ?? 0,
      totalGamesPlayed: data['totalGamesPlayed'] ?? 0,
      totalTimePlayed: data['totalTimePlayed'] ?? 0,
      wordChangeCredits: data['wordChangeCredits'] ?? 3,
      isPremium: data['isPremium'] ?? false,
      premiumExpiresAt: (data['premiumExpiresAt'] as Timestamp?)?.toDate(),
      premiumSubscriptionId: data['premiumSubscriptionId'],
      purchasedChallenges: List<String>.from(data['purchasedChallenges'] ?? []),
      purchasedCategories: List<String>.from(data['purchasedCategories'] ?? []),
      lastAdWatched: (data['lastAdWatched'] as Timestamp?)?.toDate(),
      totalAdsWatched: data['totalAdsWatched'] ?? 0,
      preferredLanguage: data['preferredLanguage'] ?? 'tr',
    );
  }

  /// Firestore'a kaydetmek için Map'e çevir
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'tier': tier.name,
      'totalSongsFound': totalSongsFound,
      'totalGamesPlayed': totalGamesPlayed,
      'totalTimePlayed': totalTimePlayed,
      'wordChangeCredits': wordChangeCredits,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null 
          ? Timestamp.fromDate(premiumExpiresAt!) 
          : null,
      'premiumSubscriptionId': premiumSubscriptionId,
      'purchasedChallenges': purchasedChallenges,
      'purchasedCategories': purchasedCategories,
      'lastAdWatched': lastAdWatched != null 
          ? Timestamp.fromDate(lastAdWatched!) 
          : null,
      'totalAdsWatched': totalAdsWatched,
      'preferredLanguage': preferredLanguage,
    };
  }

  /// Yeni kullanıcı oluştur
  factory UserModel.newUser({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      tier: UserTier.free,
      wordChangeCredits: 3,
    );
  }

  /// Misafir kullanıcı oluştur
  factory UserModel.guest() {
    return UserModel(
      uid: 'guest',
      email: '',
      displayName: 'Misafir',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      tier: UserTier.guest,
      wordChangeCredits: 3,
    );
  }

  /// Kopyala ve güncelle
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
    UserTier? tier,
    int? totalSongsFound,
    int? totalGamesPlayed,
    int? totalTimePlayed,
    int? wordChangeCredits,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    String? premiumSubscriptionId,
    List<String>? purchasedChallenges,
    List<String>? purchasedCategories,
    DateTime? lastAdWatched,
    int? totalAdsWatched,
    String? preferredLanguage,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      tier: tier ?? this.tier,
      totalSongsFound: totalSongsFound ?? this.totalSongsFound,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalTimePlayed: totalTimePlayed ?? this.totalTimePlayed,
      wordChangeCredits: wordChangeCredits ?? this.wordChangeCredits,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      premiumSubscriptionId: premiumSubscriptionId ?? this.premiumSubscriptionId,
      purchasedChallenges: purchasedChallenges ?? this.purchasedChallenges,
      purchasedCategories: purchasedCategories ?? this.purchasedCategories,
      lastAdWatched: lastAdWatched ?? this.lastAdWatched,
      totalAdsWatched: totalAdsWatched ?? this.totalAdsWatched,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  // ============ HESAPLAMALAR ============

  /// Aktif premium mi? (süre dolmamış)
  bool get isActivePremium {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true; // süresiz (test için)
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  /// Gerçek kullanıcı seviyesini hesapla
  UserTier get effectiveTier {
    if (isActivePremium) return UserTier.premium;
    if (purchasedChallenges.isNotEmpty || purchasedCategories.isNotEmpty) {
      return UserTier.purchased;
    }
    if (uid == 'guest') return UserTier.guest;
    return tier;
  }

  /// Reklam izleyince kazanılacak hak sayısı
  int get adRewardCredits {
    switch (effectiveTier) {
      case UserTier.guest:
        return 1;
      case UserTier.free:
        return 2;
      case UserTier.purchased:
        return 3;
      case UserTier.premium:
        return 0; // Premium'un izlemesine gerek yok
    }
  }

  /// Oyun sonunda reklam gösterilmeli mi?
  bool get shouldShowEndGameAd {
    switch (effectiveTier) {
      case UserTier.guest:
      case UserTier.free:
        return true;
      case UserTier.purchased:
      case UserTier.premium:
        return false;
    }
  }

  /// Mevcut kelime değiştirme hakkı (Premium için her zaman 5)
  int get effectiveWordChangeCredits {
    if (isActivePremium) return maxWordChangeCredits;
    return wordChangeCredits.clamp(0, maxWordChangeCredits);
  }

  /// Hak eklenebilir mi? (max 5)
  bool get canAddCredits {
    if (isActivePremium) return false; // Premium zaten full
    return wordChangeCredits < maxWordChangeCredits;
  }

  /// Challenge'a erişim var mı?
  bool hasChallengeAccess(String challengeId) {
    if (isActivePremium) return true;
    return purchasedChallenges.contains(challengeId);
  }

  /// Kategoriye erişim var mı?
  bool hasCategoryAccess(String categoryId) {
    if (isActivePremium) return true;
    return purchasedCategories.contains(categoryId);
  }

  /// Challenge modunu görebilir mi? (listele)
  bool get canViewChallenges {
    return effectiveTier != UserTier.guest;
  }

  /// Misafir mi?
  bool get isGuest => uid == 'guest' || tier == UserTier.guest;

  /// Kayıtlı kullanıcı mı?
  bool get isRegistered => !isGuest && email.isNotEmpty;
}
