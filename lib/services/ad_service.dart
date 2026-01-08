import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';

/// Reklam türleri
enum AdType {
  rewarded,
  interstitial,
  banner,
}

/// AdMob Reklam Servisi
/// 
/// Hak kazanma kuralları:
/// - Misafir: +1 hak
/// - Ücretsiz Üye: +2 hak
/// - Satın Alan Üye: +3 hak
/// - Premium: İzlemeye gerek yok (her zaman 5)
/// 
/// Reklam gösterme kuralları:
/// - Misafir: Oyun sonu zorunlu reklam
/// - Ücretsiz Üye: Oyun sonu zorunlu reklam
/// - Satın Alan: Reklam yok
/// - Premium: Reklam yok
class AdService extends ChangeNotifier {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final AnalyticsService _analytics = AnalyticsService();

  bool _isInitialized = false;
  bool _isAdLoading = false;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;

  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isBannerAdReady = false;

  // Test modunda mı?
  static const bool _testMode = kDebugMode;

  // ==================== AD UNIT IDS ====================
  
  // iOS Ad Unit IDs
  static const String _iosRewardedAdUnitId = 'ca-app-pub-7417963509149588/7887083438';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-7417963509149588/9691459009';
  static const String _iosBannerAdUnitId = 'ca-app-pub-7417963509149588/1122703843';

  // Android Ad Unit IDs
  static const String _androidRewardedAdUnitId = 'ca-app-pub-7417963509149588/7643540856';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-7417963509149588/6929564292';
  static const String _androidBannerAdUnitId = 'ca-app-pub-7417963509149588/9200165103';

  // Test Ad Unit IDs
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  String get _rewardedAdUnitId {
    if (_testMode) return _testRewardedAdUnitId;
    return Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId;
  }

  String get _interstitialAdUnitId {
    if (_testMode) return _testInterstitialAdUnitId;
    return Platform.isIOS ? _iosInterstitialAdUnitId : _androidInterstitialAdUnitId;
  }

  String get _bannerAdUnitId {
    if (_testMode) return _testBannerAdUnitId;
    return Platform.isIOS ? _iosBannerAdUnitId : _androidBannerAdUnitId;
  }

  // ==================== GETTERS ====================

  bool get isInitialized => _isInitialized;
  bool get isAdLoading => _isAdLoading;
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isBannerAdReady => _isBannerAdReady;
  BannerAd? get bannerAd => _bannerAd;

  // ==================== INITIALIZATION ====================

  /// Reklam servisini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      
      // Request configuration
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: _testMode ? ['YOUR_TEST_DEVICE_ID'] : [], // TODO: Test cihaz ID'leri
      );
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      _isInitialized = true;
      notifyListeners();

      // İlk reklamları yükle
      await loadRewardedAd();
      await loadInterstitialAd();

      debugPrint('AdService initialized successfully');
    } catch (e) {
      debugPrint('AdService initialize error: $e');
    }
  }

  // ==================== REWARDED AD ====================

  /// Ödüllü reklam yükle
  Future<void> loadRewardedAd() async {
    if (_isAdLoading || _isRewardedAdReady) return;

    _isAdLoading = true;
    notifyListeners();

    try {
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _isAdLoading = false;
            notifyListeners();
            debugPrint('Rewarded ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdReady = false;
            _isAdLoading = false;
            notifyListeners();
            debugPrint('Rewarded ad failed to load: ${error.message}');
          },
        ),
      );
    } catch (e) {
      _isAdLoading = false;
      notifyListeners();
      debugPrint('Load rewarded ad error: $e');
    }
  }

  /// Ödüllü reklam göster ve hak kazan
  Future<int> showRewardedAd(UserTier userTier) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      await loadRewardedAd();
      if (!_isRewardedAdReady || _rewardedAd == null) return 0;
    }

    int earnedReward = 0;

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _analytics.logAdImpression(adType: 'rewarded', adUnitId: _rewardedAdUnitId);
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;
          notifyListeners();
          loadRewardedAd(); // Yeni reklam yükle
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;
          notifyListeners();
          debugPrint('Rewarded ad failed to show: ${error.message}');
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          earnedReward = _calculateReward(userTier);
          _analytics.logAdRewardEarned(adType: 'rewarded', rewardAmount: earnedReward);
          debugPrint('User earned reward: $earnedReward credits');
        },
      );

      return earnedReward;
    } catch (e) {
      debugPrint('Show rewarded ad error: $e');
      return 0;
    }
  }

  // ==================== INTERSTITIAL AD ====================

  /// Geçiş reklamı yükle
  Future<void> loadInterstitialAd() async {
    if (_isInterstitialAdReady) return;

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            notifyListeners();
            debugPrint('Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdReady = false;
            notifyListeners();
            debugPrint('Interstitial ad failed to load: ${error.message}');
          },
        ),
      );
    } catch (e) {
      debugPrint('Load interstitial ad error: $e');
    }
  }

  /// Geçiş reklamı göster (oyun sonu)
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      await loadInterstitialAd();
      if (!_isInterstitialAdReady || _interstitialAd == null) return false;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _analytics.logAdImpression(adType: 'interstitial', adUnitId: _interstitialAdUnitId);
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdReady = false;
          notifyListeners();
          loadInterstitialAd(); // Yeni reklam yükle
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdReady = false;
          notifyListeners();
          debugPrint('Interstitial ad failed to show: ${error.message}');
        },
      );

      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('Show interstitial ad error: $e');
      return false;
    }
  }

  // ==================== BANNER AD ====================

  /// Banner reklam oluştur
  BannerAd createBannerAd({
    AdSize size = AdSize.banner,
    Function()? onLoaded,
    Function(String)? onFailed,
  }) {
    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          notifyListeners();
          _analytics.logAdImpression(adType: 'banner', adUnitId: _bannerAdUnitId);
          onLoaded?.call();
          debugPrint('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerAdReady = false;
          notifyListeners();
          onFailed?.call(error.message);
          debugPrint('Banner ad failed to load: ${error.message}');
        },
      ),
    );

    bannerAd.load();
    return bannerAd;
  }

  /// Varsayılan banner yükle
  Future<void> loadBannerAd() async {
    _bannerAd?.dispose();
    _bannerAd = createBannerAd();
  }

  // ==================== HELPER METHODS ====================

  /// Seviyeye göre ödül hesapla
  int _calculateReward(UserTier tier) {
    switch (tier) {
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

  /// Kullanıcı reklam izlemeli mi? (hak kazanmak için)
  bool shouldShowRewardedAd(UserModel user) {
    if (user.isActivePremium) return false;
    if (!user.canAddCredits) return false;
    return true;
  }

  /// Oyun sonunda reklam gösterilmeli mi?
  bool shouldShowEndGameAd(UserModel user) {
    return user.shouldShowEndGameAd;
  }

  /// Reklam izleme sonrası kullanıcı verilerini güncelle
  UserModel applyRewardToUser(UserModel user, int reward) {
    if (reward <= 0) return user;

    final newCredits = (user.wordChangeCredits + reward)
        .clamp(0, UserModel.maxWordChangeCredits);

    return user.copyWith(
      wordChangeCredits: newCredits,
      lastAdWatched: DateTime.now(),
      totalAdsWatched: user.totalAdsWatched + 1,
    );
  }

  // ==================== DISPOSE ====================

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}

/// Reklam sonucu
class AdResult {
  final bool success;
  final int rewardAmount;
  final String? errorMessage;

  AdResult({
    required this.success,
    this.rewardAmount = 0,
    this.errorMessage,
  });

  factory AdResult.success(int reward) {
    return AdResult(success: true, rewardAmount: reward);
  }

  factory AdResult.failure(String message) {
    return AdResult(success: false, errorMessage: message);
  }
}
