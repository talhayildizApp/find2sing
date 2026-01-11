import 'package:cloud_firestore/cloud_firestore.dart';

enum UserTier {
  guest,
  free,
  purchased,
  premium,
}

/// Kullanıcı seviyelerine göre haklar ve konfigürasyon
class UserTierConfig {
  final UserTier tier;
  final String label;
  final String emoji;
  final bool showEndGameAd;
  final int adRewardCredits;
  final int baseJokerCredits;
  final bool canViewChallenges;
  final bool hasFullAccess;

  const UserTierConfig({
    required this.tier,
    required this.label,
    required this.emoji,
    required this.showEndGameAd,
    required this.adRewardCredits,
    required this.baseJokerCredits,
    required this.canViewChallenges,
    required this.hasFullAccess,
  });

  static const configs = {
    UserTier.guest: UserTierConfig(
      tier: UserTier.guest,
      label: 'Misafir',
      emoji: '👤',
      showEndGameAd: true,
      adRewardCredits: 1,
      baseJokerCredits: 1,
      canViewChallenges: false,
      hasFullAccess: false,
    ),
    UserTier.free: UserTierConfig(
      tier: UserTier.free,
      label: 'Üye',
      emoji: '🎵',
      showEndGameAd: true,
      adRewardCredits: 2,
      baseJokerCredits: 2,
      canViewChallenges: true,
      hasFullAccess: false,
    ),
    UserTier.purchased: UserTierConfig(
      tier: UserTier.purchased,
      label: 'Satın Alan',
      emoji: '🎯',
      showEndGameAd: false,
      adRewardCredits: 3,
      baseJokerCredits: 3,
      canViewChallenges: true,
      hasFullAccess: false,
    ),
    UserTier.premium: UserTierConfig(
      tier: UserTier.premium,
      label: 'Premium',
      emoji: '👑',
      showEndGameAd: false,
      adRewardCredits: 0, // Reklam izlemeye gerek yok
      baseJokerCredits: 5, // Sabit 5 joker
      canViewChallenges: true,
      hasFullAccess: true,
    ),
  };

  static UserTierConfig getConfig(UserTier tier) => configs[tier]!;
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? playerId; // Unique shareable ID (e.g., "BUSH-4921")
  final List<String> fcmTokens;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserTier tier;
  final int totalSongsFound;
  final int totalGamesPlayed;
  final int totalTimePlayed;
  final int wordChangeCredits;
  static const int maxWordChangeCredits = 5;

  // Challenge Jokerleri - 3 adet, her biri ayrı reklam izleyerek kazanılır
  final List<bool> challengeJokers; // [joker1, joker2, joker3] - true = aktif, false = kullanıldı
  static const int maxChallengeJokers = 3;

  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String? premiumSubscriptionId;
  final List<String> purchasedChallenges;
  final List<String> purchasedCategories;
  final DateTime? lastAdWatched;
  final int totalAdsWatched;
  final String preferredLanguage;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.playerId,
    this.fcmTokens = const [],
    required this.createdAt,
    required this.lastLoginAt,
    this.tier = UserTier.free,
    this.totalSongsFound = 0,
    this.totalGamesPlayed = 0,
    this.totalTimePlayed = 0,
    this.wordChangeCredits = 3,
    this.challengeJokers = const [false, false, false], // Başlangıçta 3 joker yok
    this.isPremium = false,
    this.premiumExpiresAt,
    this.premiumSubscriptionId,
    this.purchasedChallenges = const [],
    this.purchasedCategories = const [],
    this.lastAdWatched,
    this.totalAdsWatched = 0,
    this.preferredLanguage = 'tr',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Oyuncu',
      photoUrl: data['photoUrl'],
      playerId: data['playerId'],
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
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
      challengeJokers: List<bool>.from(data['challengeJokers'] ?? [false, false, false]),
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

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'playerId': playerId,
      'fcmTokens': fcmTokens,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'tier': tier.name,
      'totalSongsFound': totalSongsFound,
      'totalGamesPlayed': totalGamesPlayed,
      'totalTimePlayed': totalTimePlayed,
      'wordChangeCredits': wordChangeCredits,
      'challengeJokers': challengeJokers,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null ? Timestamp.fromDate(premiumExpiresAt!) : null,
      'premiumSubscriptionId': premiumSubscriptionId,
      'purchasedChallenges': purchasedChallenges,
      'purchasedCategories': purchasedCategories,
      'lastAdWatched': lastAdWatched != null ? Timestamp.fromDate(lastAdWatched!) : null,
      'totalAdsWatched': totalAdsWatched,
      'preferredLanguage': preferredLanguage,
    };
  }

  factory UserModel.newUser({
    required String uid,
    required String email,
    String? displayName,
    String? playerId,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? email.split('@').first,
      playerId: playerId,
      fcmTokens: [],
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      tier: UserTier.free,
      wordChangeCredits: 3,
      challengeJokers: const [false, false, false],
    );
  }

  factory UserModel.guest() {
    return UserModel(
      uid: 'guest',
      email: '',
      displayName: 'Misafir',
      playerId: null,
      fcmTokens: [],
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      tier: UserTier.guest,
      wordChangeCredits: 3,
      challengeJokers: const [false, false, false],
    );
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? playerId,
    List<String>? fcmTokens,
    DateTime? lastLoginAt,
    UserTier? tier,
    int? totalSongsFound,
    int? totalGamesPlayed,
    int? totalTimePlayed,
    int? wordChangeCredits,
    List<bool>? challengeJokers,
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
      playerId: playerId ?? this.playerId,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      tier: tier ?? this.tier,
      totalSongsFound: totalSongsFound ?? this.totalSongsFound,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalTimePlayed: totalTimePlayed ?? this.totalTimePlayed,
      wordChangeCredits: wordChangeCredits ?? this.wordChangeCredits,
      challengeJokers: challengeJokers ?? this.challengeJokers,
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

  bool get isActivePremium {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  UserTier get effectiveTier {
    if (isActivePremium) return UserTier.premium;
    if (purchasedChallenges.isNotEmpty || purchasedCategories.isNotEmpty) {
      return UserTier.purchased;
    }
    if (uid == 'guest') return UserTier.guest;
    return tier;
  }

  int get adRewardCredits {
    switch (effectiveTier) {
      case UserTier.guest:
        return 1;
      case UserTier.free:
        return 2;
      case UserTier.purchased:
        return 3;
      case UserTier.premium:
        return 0;
    }
  }

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

  int get effectiveWordChangeCredits {
    if (isActivePremium) return maxWordChangeCredits;
    return wordChangeCredits.clamp(0, maxWordChangeCredits);
  }

  bool get canAddCredits {
    if (isActivePremium) return false;
    return wordChangeCredits < maxWordChangeCredits;
  }

  bool hasChallengeAccess(String challengeId) {
    if (isActivePremium) return true;
    return purchasedChallenges.contains(challengeId);
  }

  bool hasCategoryAccess(String categoryId) {
    if (isActivePremium) return true;
    return purchasedCategories.contains(categoryId);
  }

  bool get canViewChallenges {
    return effectiveTier != UserTier.guest;
  }

  bool get isGuest => uid == 'guest' || tier == UserTier.guest;
  bool get isRegistered => !isGuest && email.isNotEmpty;

  // Profil ekranı için getter'lar
  int get highScore => totalSongsFound;
  int get gamesPlayed => totalGamesPlayed;
  int get correctGuesses => totalSongsFound;

  /// Kullanıcının tier konfigürasyonu
  UserTierConfig get tierConfig => UserTierConfig.getConfig(effectiveTier);

  /// Tier'e göre base joker kredisi
  int get baseJokerCredits => tierConfig.baseJokerCredits;

  /// Premium için sabit 5, diğerleri için mevcut kredi (Tek başına/Arkadaşla modu için)
  int get effectiveJokerCredits {
    if (isActivePremium) return UserTierConfig.configs[UserTier.premium]!.baseJokerCredits;
    return wordChangeCredits.clamp(0, maxWordChangeCredits);
  }

  // ─────────────────────────────────────────────────────────────────
  // CHALLENGE JOKER METODLARI
  // ─────────────────────────────────────────────────────────────────

  /// Aktif challenge joker sayısı
  int get activeChallengeJokerCount {
    if (isActivePremium) return maxChallengeJokers; // Premium sınırsız
    return challengeJokers.where((j) => j).length;
  }

  /// Belirli bir joker aktif mi?
  bool isChallengeJokerActive(int index) {
    if (isActivePremium) return true;
    if (index < 0 || index >= challengeJokers.length) return false;
    return challengeJokers[index];
  }

  /// Reklam izleyerek kazanılabilecek joker var mı?
  bool get canEarnChallengeJoker {
    if (isActivePremium) return false;
    if (isGuest) return false;
    return challengeJokers.contains(false); // En az bir false (kazanılabilir) var mı
  }

  /// İlk kullanılabilir joker indexi (-1 = yok)
  int get firstAvailableChallengeJokerIndex {
    if (isActivePremium) return 0;
    for (int i = 0; i < challengeJokers.length; i++) {
      if (challengeJokers[i]) return i;
    }
    return -1;
  }

  /// İlk kazanılabilir (reklam izlenecek) joker indexi (-1 = hepsi dolu)
  int get firstEarnableChallengeJokerIndex {
    if (isActivePremium) return -1;
    for (int i = 0; i < challengeJokers.length; i++) {
      if (!challengeJokers[i]) return i;
    }
    return -1;
  }
}
