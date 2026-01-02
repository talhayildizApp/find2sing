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

    if (user.isActivePremium) {
      return UserFeatures.premium();
    }

    if (user.effectiveTier == UserTier.purchased) {
      return UserFeatures.purchased();
    }

    return UserFeatures.free();
  }
}

/// Kullanıcı özellikleri özeti
class UserFeatures {
  final bool canViewChallenges;
  final bool hasAds;
  final int adRewardCredits;
  final bool hasUnlimitedCredits;
  final bool canSaveProgress;
  final bool canJoinLeaderboard;
  final String tierName;

  UserFeatures({
    required this.canViewChallenges,
    required this.hasAds,
    required this.adRewardCredits,
    required this.hasUnlimitedCredits,
    required this.canSaveProgress,
    required this.canJoinLeaderboard,
    required this.tierName,
  });

  factory UserFeatures.guest() {
    return UserFeatures(
      canViewChallenges: false,
      hasAds: true,
      adRewardCredits: 1,
      hasUnlimitedCredits: false,
      canSaveProgress: false,
      canJoinLeaderboard: false,
      tierName: 'Misafir',
    );
  }

  factory UserFeatures.free() {
    return UserFeatures(
      canViewChallenges: true,
      hasAds: true,
      adRewardCredits: 2,
      hasUnlimitedCredits: false,
      canSaveProgress: true,
      canJoinLeaderboard: true,
      tierName: 'Ücretsiz Üye',
    );
  }

  factory UserFeatures.purchased() {
    return UserFeatures(
      canViewChallenges: true,
      hasAds: false,
      adRewardCredits: 3,
      hasUnlimitedCredits: false,
      canSaveProgress: true,
      canJoinLeaderboard: true,
      tierName: 'Üye',
    );
  }

  factory UserFeatures.premium() {
    return UserFeatures(
      canViewChallenges: true,
      hasAds: false,
      adRewardCredits: 0,
      hasUnlimitedCredits: true,
      canSaveProgress: true,
      canJoinLeaderboard: true,
      tierName: 'Premium',
    );
  }
}
