// lib/services/rewards_service.dart
//
// Reklam izleme ve joker hakkı yönetimi servisi.
// Kullanıcı seviyesine göre reklam ödüllerini ve joker haklarını yönetir.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Reklam türleri
enum AdType {
  rewarded,      // Ödüllü reklam (joker için)
  interstitial,  // Geçiş reklamı (oyun sonu)
}

/// Reklam izleme sonucu
class AdWatchResult {
  final bool success;
  final int creditsEarned;
  final String? message;
  final int newTotalCredits;

  const AdWatchResult({
    required this.success,
    required this.creditsEarned,
    this.message,
    required this.newTotalCredits,
  });
}

/// Joker kullanım sonucu
class JokerUseResult {
  final bool success;
  final int remainingCredits;
  final String? message;

  const JokerUseResult({
    required this.success,
    required this.remainingCredits,
    this.message,
  });
}

/// Challenge joker sonucu
class ChallengeJokerResult {
  final bool success;
  final int jokerIndex;
  final String? message;
  final List<bool> newJokerState;

  const ChallengeJokerResult({
    required this.success,
    required this.jokerIndex,
    this.message,
    required this.newJokerState,
  });
}

/// Ödül ve hak yönetimi servisi
class RewardsService {
  static final RewardsService _instance = RewardsService._internal();
  factory RewardsService() => _instance;
  RewardsService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reklam izleyerek joker hakkı kazan
  Future<AdWatchResult> watchAdForCredits(UserModel user) async {
    if (user.isGuest) {
      return const AdWatchResult(
        success: false,
        creditsEarned: 0,
        message: 'Misafir kullanıcılar reklam izleyemez. Lütfen giriş yapın.',
        newTotalCredits: 0,
      );
    }

    if (user.isActivePremium) {
      return AdWatchResult(
        success: false,
        creditsEarned: 0,
        message: 'Premium üyeler zaten sınırsız joker hakkına sahip!',
        newTotalCredits: user.effectiveJokerCredits,
      );
    }

    // Maksimum krediye ulaşıldı mı?
    if (user.wordChangeCredits >= UserModel.maxWordChangeCredits) {
      return AdWatchResult(
        success: false,
        creditsEarned: 0,
        message: 'Maksimum joker hakkına ulaştınız!',
        newTotalCredits: user.wordChangeCredits,
      );
    }

    // Tier'e göre kazanılacak kredi
    final creditsToEarn = user.tierConfig.adRewardCredits;

    // Yeni toplam (maksimumu aşamaz)
    final newTotal = (user.wordChangeCredits + creditsToEarn)
        .clamp(0, UserModel.maxWordChangeCredits);
    final actualEarned = newTotal - user.wordChangeCredits;

    try {
      // Firestore güncelle
      await _db.collection('users').doc(user.uid).update({
        'wordChangeCredits': newTotal,
        'lastAdWatched': FieldValue.serverTimestamp(),
        'totalAdsWatched': FieldValue.increment(1),
      });

      debugPrint('RewardsService: User ${user.uid} earned $actualEarned credits. New total: $newTotal');

      return AdWatchResult(
        success: true,
        creditsEarned: actualEarned,
        message: '+$actualEarned Joker Hakkı Kazandın!',
        newTotalCredits: newTotal,
      );
    } catch (e) {
      debugPrint('RewardsService error: $e');
      return AdWatchResult(
        success: false,
        creditsEarned: 0,
        message: 'Bir hata oluştu. Lütfen tekrar deneyin.',
        newTotalCredits: user.wordChangeCredits,
      );
    }
  }

  /// Joker kullan (kelime değiştir)
  Future<JokerUseResult> useJoker(UserModel user) async {
    // Premium kullanıcılar sınırsız
    if (user.isActivePremium) {
      return JokerUseResult(
        success: true,
        remainingCredits: UserModel.maxWordChangeCredits,
        message: null,
      );
    }

    if (user.wordChangeCredits <= 0) {
      return const JokerUseResult(
        success: false,
        remainingCredits: 0,
        message: 'Joker hakkınız kalmadı! Reklam izleyerek hak kazanabilirsiniz.',
      );
    }

    final newCredits = user.wordChangeCredits - 1;

    try {
      await _db.collection('users').doc(user.uid).update({
        'wordChangeCredits': newCredits,
      });

      return JokerUseResult(
        success: true,
        remainingCredits: newCredits,
        message: null,
      );
    } catch (e) {
      debugPrint('RewardsService useJoker error: $e');
      return JokerUseResult(
        success: false,
        remainingCredits: user.wordChangeCredits,
        message: 'Bir hata oluştu.',
      );
    }
  }

  /// Oyun sonu reklamı gösterilmeli mi?
  bool shouldShowEndGameAd(UserModel? user) {
    if (user == null) return true;
    return user.tierConfig.showEndGameAd;
  }

  /// Kullanıcının reklam izleyerek kazanabileceği kredi
  int getAdRewardAmount(UserModel? user) {
    if (user == null) return 1;
    return user.tierConfig.adRewardCredits;
  }

  /// Kullanıcının mevcut joker sayısı
  int getCurrentJokerCount(UserModel? user) {
    if (user == null) return 0;
    return user.effectiveJokerCredits;
  }

  /// Kullanıcı reklam izleyebilir mi?
  bool canWatchAd(UserModel? user) {
    if (user == null) return false;
    if (user.isGuest) return false;
    if (user.isActivePremium) return false;
    return user.wordChangeCredits < UserModel.maxWordChangeCredits;
  }

  /// Günlük joker reset (opsiyonel - şimdilik kullanılmıyor)
  Future<void> resetDailyCredits(UserModel user) async {
    if (user.isGuest || user.isActivePremium) return;

    final baseCredits = user.tierConfig.baseJokerCredits;

    await _db.collection('users').doc(user.uid).update({
      'wordChangeCredits': baseCredits,
      'lastCreditReset': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // CHALLENGE JOKER METODLARI (3 adet, her biri ayrı reklam)
  // ─────────────────────────────────────────────────────────────────

  /// Reklam izleyerek challenge jokeri kazan (belirli index için)
  Future<ChallengeJokerResult> watchAdForChallengeJoker(UserModel user, int jokerIndex) async {
    if (user.isGuest) {
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Misafir kullanıcılar reklam izleyemez. Lütfen giriş yapın.',
        newJokerState: user.challengeJokers,
      );
    }

    if (user.isActivePremium) {
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Premium üyeler zaten sınırsız jokere sahip!',
        newJokerState: const [true, true, true],
      );
    }

    if (jokerIndex < 0 || jokerIndex >= UserModel.maxChallengeJokers) {
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Geçersiz joker.',
        newJokerState: user.challengeJokers,
      );
    }

    if (user.challengeJokers[jokerIndex]) {
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Bu joker zaten aktif!',
        newJokerState: user.challengeJokers,
      );
    }

    // Yeni joker state oluştur
    final newJokers = List<bool>.from(user.challengeJokers);
    newJokers[jokerIndex] = true;

    try {
      await _db.collection('users').doc(user.uid).update({
        'challengeJokers': newJokers,
        'lastAdWatched': FieldValue.serverTimestamp(),
        'totalAdsWatched': FieldValue.increment(1),
      });

      debugPrint('RewardsService: User ${user.uid} earned challenge joker #${jokerIndex + 1}');

      return ChallengeJokerResult(
        success: true,
        jokerIndex: jokerIndex,
        message: 'Joker ${jokerIndex + 1} Kazanıldı! 🎉',
        newJokerState: newJokers,
      );
    } catch (e) {
      debugPrint('RewardsService watchAdForChallengeJoker error: $e');
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Bir hata oluştu. Lütfen tekrar deneyin.',
        newJokerState: user.challengeJokers,
      );
    }
  }

  /// Challenge jokeri kullan (belirli index)
  Future<ChallengeJokerResult> useChallengeJoker(UserModel user, int jokerIndex) async {
    if (user.isActivePremium) {
      // Premium kullanıcılar sınırsız, state değişmiyor
      return ChallengeJokerResult(
        success: true,
        jokerIndex: jokerIndex,
        message: null,
        newJokerState: const [true, true, true],
      );
    }

    if (jokerIndex < 0 || jokerIndex >= user.challengeJokers.length) {
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Geçersiz joker.',
        newJokerState: user.challengeJokers,
      );
    }

    if (!user.challengeJokers[jokerIndex]) {
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Bu joker aktif değil! Reklam izleyerek kazanın.',
        newJokerState: user.challengeJokers,
      );
    }

    // Jokeri kullan (false yap)
    final newJokers = List<bool>.from(user.challengeJokers);
    newJokers[jokerIndex] = false;

    try {
      await _db.collection('users').doc(user.uid).update({
        'challengeJokers': newJokers,
      });

      return ChallengeJokerResult(
        success: true,
        jokerIndex: jokerIndex,
        message: null,
        newJokerState: newJokers,
      );
    } catch (e) {
      debugPrint('RewardsService useChallengeJoker error: $e');
      return ChallengeJokerResult(
        success: false,
        jokerIndex: jokerIndex,
        message: 'Bir hata oluştu.',
        newJokerState: user.challengeJokers,
      );
    }
  }

  /// Aktif challenge joker sayısı
  int getActiveChallengeJokerCount(UserModel? user) {
    if (user == null) return 0;
    return user.activeChallengeJokerCount;
  }

  /// Challenge jokerleri state'i
  List<bool> getChallengeJokerState(UserModel? user) {
    if (user == null) return [false, false, false];
    if (user.isActivePremium) return [true, true, true];
    return user.challengeJokers;
  }
}
