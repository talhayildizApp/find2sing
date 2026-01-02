import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Reklam türleri
enum AdType {
  rewarded,    // Ödüllü reklam (hak kazanma)
  interstitial, // Geçiş reklamı (oyun sonu)
  banner,       // Banner reklam
}

/// Reklam servisi
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
  bool _isInitialized = false;
  bool _isAdLoading = false;
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;

  // Test modunda mı? (Development için)
  final bool _testMode;

  // AdMob ID'leri (Production'da değişecek)
  // ignore: unused_field - AdMob entegrasyonunda kullanılacak
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID
  // ignore: unused_field - AdMob entegrasyonunda kullanılacak
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  // ignore: unused_field - AdMob entegrasyonunda kullanılacak
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID

  AdService({bool testMode = true}) : _testMode = testMode;

  bool get isInitialized => _isInitialized;
  bool get isAdLoading => _isAdLoading;
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  /// Reklam servisini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: Google Mobile Ads SDK'yı başlat
      // await MobileAds.instance.initialize();
      
      _isInitialized = true;
      notifyListeners();

      // İlk reklamları yükle
      await loadRewardedAd();
      await loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService initialize error: $e');
    }
  }

  /// Ödüllü reklam yükle
  Future<void> loadRewardedAd() async {
    if (_isAdLoading) return;

    _isAdLoading = true;
    notifyListeners();

    try {
      // TODO: Gerçek reklam yükleme
      // RewardedAd.load(
      //   adUnitId: _rewardedAdUnitId,
      //   request: const AdRequest(),
      //   rewardedAdLoadCallback: ...
      // );

      // Simülasyon için
      await Future.delayed(const Duration(milliseconds: 500));
      _isRewardedAdReady = true;
    } catch (e) {
      debugPrint('Load rewarded ad error: $e');
      _isRewardedAdReady = false;
    }

    _isAdLoading = false;
    notifyListeners();
  }

  /// Geçiş reklamı yükle
  Future<void> loadInterstitialAd() async {
    try {
      // TODO: Gerçek reklam yükleme
      await Future.delayed(const Duration(milliseconds: 500));
      _isInterstitialAdReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Load interstitial ad error: $e');
    }
  }

  /// Ödüllü reklam göster ve hak kazan
  /// [userTier] kullanıcı seviyesine göre hak miktarı değişir
  /// Returns: Kazanılan hak sayısı, hata durumunda 0
  Future<int> showRewardedAd(UserTier userTier) async {
    if (!_isRewardedAdReady) {
      await loadRewardedAd();
      if (!_isRewardedAdReady) return 0;
    }

    try {
      // TODO: Gerçek reklam gösterme
      // await _rewardedAd?.show(
      //   onUserEarnedReward: (ad, reward) { ... }
      // );

      // Simülasyon için
      if (_testMode) {
        await Future.delayed(const Duration(seconds: 1));
      }

      _isRewardedAdReady = false;
      notifyListeners();

      // Yeni reklam yükle
      loadRewardedAd();

      // Seviyeye göre hak hesapla
      return _calculateReward(userTier);
    } catch (e) {
      debugPrint('Show rewarded ad error: $e');
      return 0;
    }
  }

  /// Geçiş reklamı göster (oyun sonu)
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdReady) {
      await loadInterstitialAd();
      if (!_isInterstitialAdReady) return false;
    }

    try {
      // TODO: Gerçek reklam gösterme
      if (_testMode) {
        await Future.delayed(const Duration(seconds: 1));
      }

      _isInterstitialAdReady = false;
      notifyListeners();

      // Yeni reklam yükle
      loadInterstitialAd();

      return true;
    } catch (e) {
      debugPrint('Show interstitial ad error: $e');
      return false;
    }
  }

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
        return 0; // Premium'un izlemesine gerek yok
    }
  }

  /// Kullanıcı reklam izlemeli mi? (hak kazanmak için)
  bool shouldShowRewardedAd(UserModel user) {
    // Premium'un izlemesine gerek yok
    if (user.isActivePremium) return false;
    
    // Hak doluysa izlemeye gerek yok
    if (!user.canAddCredits) return false;
    
    return true;
  }

  /// Oyun sonunda reklam gösterilmeli mi?
  bool shouldShowEndGameAd(UserModel user) {
    return user.shouldShowEndGameAd;
  }

  /// Reklam izleme sonrası kullanıcı verilerini güncelle
  /// Returns: Güncellenmiş kullanıcı modeli
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

  /// Kaynakları temizle
  @override
  void dispose() {
    // Reklam objelerini temizle (AdMob entegrasyonunda)
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
