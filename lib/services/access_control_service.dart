import '../models/user_model.dart';
import '../models/challenge_model.dart';

/// Erişim durumu
enum AccessStatus {
  granted,      // Erişim var
  locked,       // Kilitli (satın alınabilir)
  loginRequired, // Giriş gerekli
  premiumOnly,  // Sadece premium
}

/// Erişim kontrol sonucu
class AccessResult {
  final AccessStatus status;
  final String? message;
  final double? price; // Satın alma fiyatı (locked ise)

  AccessResult({
    required this.status,
    this.message,
    this.price,
  });

  bool get hasAccess => status == AccessStatus.granted;
  bool get needsLogin => status == AccessStatus.loginRequired;
  bool get needsPurchase => status == AccessStatus.locked;
  bool get needsPremium => status == AccessStatus.premiumOnly;
}

/// Erişim kontrol servisi
class AccessControlService {
  
  /// Challenge'a erişim kontrolü
  static AccessResult checkChallengeAccess(
    UserModel? user,
    ChallengeModel challenge,
  ) {
    // Kullanıcı yok veya misafir
    if (user == null || user.isGuest) {
      return AccessResult(
        status: AccessStatus.loginRequired,
        message: 'Challenge modunu görmek için giriş yapmalısın',
      );
    }

    // Premium kullanıcı - her şeye erişim
    if (user.isActivePremium) {
      return AccessResult(status: AccessStatus.granted);
    }

    // Ücretsiz challenge
    if (challenge.isFree) {
      return AccessResult(status: AccessStatus.granted);
    }

    // Bu challenge satın alınmış mı?
    if (user.hasChallengeAccess(challenge.id)) {
      return AccessResult(status: AccessStatus.granted);
    }

    // Bu challenge'ın kategorisi satın alınmış mı?
    if (user.hasCategoryAccess(challenge.categoryId)) {
      return AccessResult(status: AccessStatus.granted);
    }

    // Erişim yok - satın alınabilir
    return AccessResult(
      status: AccessStatus.locked,
      message: 'Bu challenge\'ı oynamak için satın al',
      price: challenge.priceUsd,
    );
  }

  /// Kategoriye erişim kontrolü
  static AccessResult checkCategoryAccess(
    UserModel? user,
    CategoryModel category,
  ) {
    // Kullanıcı yok veya misafir
    if (user == null || user.isGuest) {
      return AccessResult(
        status: AccessStatus.loginRequired,
        message: 'Kategorileri görmek için giriş yapmalısın',
      );
    }

    // Premium kullanıcı - her şeye erişim
    if (user.isActivePremium) {
      return AccessResult(status: AccessStatus.granted);
    }

    // Bu kategori satın alınmış mı?
    if (user.hasCategoryAccess(category.id)) {
      return AccessResult(status: AccessStatus.granted);
    }

    // Erişim yok - satın alınabilir
    return AccessResult(
      status: AccessStatus.locked,
      message: 'Bu kategoriyi açmak için satın al',
      price: category.priceUsd,
    );
  }

  /// Challenge listesini görüntüleme kontrolü
  static AccessResult checkChallengeListAccess(UserModel? user) {
    if (user == null || user.isGuest) {
      return AccessResult(
        status: AccessStatus.loginRequired,
        message: 'Challenge modunu görmek için giriş yap',
      );
    }

    return AccessResult(status: AccessStatus.granted);
  }

  /// Kelime değiştirme hakkı kontrolü
  static bool canUseWordChange(UserModel? user) {
    if (user == null) return false;
    return user.effectiveWordChangeCredits > 0;
  }

  /// Reklam izleyerek hak kazanma kontrolü
  static bool canWatchAdForCredits(UserModel? user) {
    if (user == null) return false;
    if (user.isActivePremium) return false; // Premium'un gerek yok
    return user.canAddCredits; // Max 5'e ulaşmamışsa
  }

  /// Oyun sonu reklam kontrolü
  static bool shouldShowEndGameAd(UserModel? user) {
    if (user == null) return true; // Misafir - reklam göster
    return user.shouldShowEndGameAd;
  }

  /// İstatistik kaydetme kontrolü
  static bool canSaveStats(UserModel? user) {
    // Misafirler istatistik kaydedemez
    if (user == null || user.isGuest) return false;
    return true;
  }

  /// Liderlik tablosuna katılma kontrolü
  static bool canJoinLeaderboard(UserModel? user) {
    // Sadece kayıtlı kullanıcılar
    if (user == null || user.isGuest) return false;
    return true;
  }

  /// Premium özellik kontrolü
  static AccessResult checkPremiumFeature(UserModel? user, String featureName) {
    if (user == null || user.isGuest) {
      return AccessResult(
        status: AccessStatus.loginRequired,
        message: 'Bu özellik için giriş yapmalısın',
      );
    }

    if (!user.isActivePremium) {
      return AccessResult(
        status: AccessStatus.premiumOnly,
        message: '$featureName sadece Premium üyelere özel',
      );
    }

    return AccessResult(status: AccessStatus.granted);
  }

  /// Kullanıcı özellik özeti
  static UserFeatures getUserFeatures(UserModel? user) {
    if (user == null || user.isGuest) {
      return UserFeatures.guest();
    }

    // UserTierConfig'den direkt al
    return UserFeatures.fromTierConfig(user.tierConfig);
  }

  /// Kullanıcının tier'ine göre joker kredisi
  static int getJokerCredits(UserModel? user) {
    if (user == null) return 0;
    return user.effectiveJokerCredits;
  }

  /// Kullanıcı reklam izleyebilir mi?
  static bool canWatchRewardedAd(UserModel? user) {
    if (user == null || user.isGuest) return false;
    if (user.isActivePremium) return false;
    return user.wordChangeCredits < UserModel.maxWordChangeCredits;
  }
}

/// Kullanıcı özellikleri özeti - UserTierConfig'den türetilir
class UserFeatures {
  final bool canViewChallenges;
  final bool hasAds;
  final int adRewardCredits;
  final bool hasUnlimitedCredits;
  final bool canSaveProgress;
  final bool canJoinLeaderboard;
  final String tierName;
  final String tierEmoji;
  final UserTier tier;

  UserFeatures({
    required this.canViewChallenges,
    required this.hasAds,
    required this.adRewardCredits,
    required this.hasUnlimitedCredits,
    required this.canSaveProgress,
    required this.canJoinLeaderboard,
    required this.tierName,
    required this.tierEmoji,
    required this.tier,
  });

  /// UserTierConfig'den UserFeatures oluştur
  factory UserFeatures.fromTierConfig(UserTierConfig config) {
    return UserFeatures(
      canViewChallenges: config.canViewChallenges,
      hasAds: config.showEndGameAd,
      adRewardCredits: config.adRewardCredits,
      hasUnlimitedCredits: config.hasFullAccess,
      canSaveProgress: config.tier != UserTier.guest,
      canJoinLeaderboard: config.tier != UserTier.guest,
      tierName: config.label,
      tierEmoji: config.emoji,
      tier: config.tier,
    );
  }

  factory UserFeatures.guest() {
    return UserFeatures.fromTierConfig(UserTierConfig.getConfig(UserTier.guest));
  }

  factory UserFeatures.free() {
    return UserFeatures.fromTierConfig(UserTierConfig.getConfig(UserTier.free));
  }

  factory UserFeatures.purchased() {
    return UserFeatures.fromTierConfig(UserTierConfig.getConfig(UserTier.purchased));
  }

  factory UserFeatures.premium() {
    return UserFeatures.fromTierConfig(UserTierConfig.getConfig(UserTier.premium));
  }
}
