import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Firebase Analytics Servisi
/// 
/// Takip edilen olaylar:
/// - Ekran görüntülemeleri
/// - Oyun başlatma/bitirme
/// - Satın alma işlemleri
/// - Reklam izleme
/// - Challenge tamamlama
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Kullanıcı özelliklerini ayarla
  Future<void> setUserProperties(UserModel user) async {
    try {
      await _analytics.setUserId(id: user.uid);
      await _analytics.setUserProperty(name: 'user_tier', value: user.effectiveTier.name);
      await _analytics.setUserProperty(name: 'is_premium', value: user.isActivePremium.toString());
      await _analytics.setUserProperty(name: 'language', value: user.preferredLanguage);
    } catch (e) {
      debugPrint('Analytics setUserProperties error: $e');
    }
  }

  /// Kullanıcı çıkışında temizle
  Future<void> clearUser() async {
    try {
      await _analytics.setUserId(id: null);
    } catch (e) {
      debugPrint('Analytics clearUser error: $e');
    }
  }

  /// Ekran görüntüleme
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }

  // ==================== AUTH EVENTS ====================

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  // ==================== GAME EVENTS ====================

  Future<void> logGameStart({
    required String gameMode,
    String? difficulty,
    int? wordCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_start',
        parameters: {
          'game_mode': gameMode,
          if (difficulty != null) 'difficulty': difficulty,
          if (wordCount != null) 'word_count': wordCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logGameStart error: $e');
    }
  }

  Future<void> logGameEnd({
    required String gameMode,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required int timePlayed,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_end',
        parameters: {
          'game_mode': gameMode,
          'score': score,
          'total_questions': totalQuestions,
          'correct_answers': correctAnswers,
          'time_played': timePlayed,
          'accuracy': totalQuestions > 0 
              ? (correctAnswers / totalQuestions * 100).round() 
              : 0,
        },
      );
    } catch (e) {
      debugPrint('Analytics logGameEnd error: $e');
    }
  }

  Future<void> logSongFound({
    required String songId,
    required String artistName,
    required int attemptCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'song_found',
        parameters: {
          'song_id': songId,
          'artist_name': artistName,
          'attempt_count': attemptCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logSongFound error: $e');
    }
  }

  // ==================== CHALLENGE EVENTS ====================

  Future<void> logChallengeStart({
    required String challengeId,
    required String challengeName,
    required String mode,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_start',
        parameters: {
          'challenge_id': challengeId,
          'challenge_name': challengeName,
          'mode': mode,
        },
      );
    } catch (e) {
      debugPrint('Analytics logChallengeStart error: $e');
    }
  }

  Future<void> logChallengeComplete({
    required String challengeId,
    required String challengeName,
    required String mode,
    required int score,
    required int stars,
    required bool isNewHighScore,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_complete',
        parameters: {
          'challenge_id': challengeId,
          'challenge_name': challengeName,
          'mode': mode,
          'score': score,
          'stars': stars,
          'is_new_high_score': isNewHighScore,
        },
      );
    } catch (e) {
      debugPrint('Analytics logChallengeComplete error: $e');
    }
  }

  // ==================== PURCHASE EVENTS ====================

  Future<void> logPurchaseStart({
    required String itemId,
    required String itemType,
    required double price,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'purchase_start',
        parameters: {
          'item_id': itemId,
          'item_type': itemType,
          'price': price,
        },
      );
    } catch (e) {
      debugPrint('Analytics logPurchaseStart error: $e');
    }
  }

  Future<void> logPurchaseComplete({
    required String itemId,
    required String itemType,
    required double price,
    required String currency,
  }) async {
    try {
      await _analytics.logPurchase(
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemCategory: itemType,
            price: price,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Analytics logPurchaseComplete error: $e');
    }
  }

  Future<void> logPurchaseFailed({
    required String itemId,
    required String reason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'purchase_failed',
        parameters: {
          'item_id': itemId,
          'reason': reason,
        },
      );
    } catch (e) {
      debugPrint('Analytics logPurchaseFailed error: $e');
    }
  }

  // ==================== AD EVENTS ====================

  Future<void> logAdImpression({
    required String adType,
    required String adUnitId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ad_impression',
        parameters: {
          'ad_type': adType,
          'ad_unit_id': adUnitId,
        },
      );
    } catch (e) {
      debugPrint('Analytics logAdImpression error: $e');
    }
  }

  Future<void> logAdRewardEarned({
    required String adType,
    required int rewardAmount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ad_reward_earned',
        parameters: {
          'ad_type': adType,
          'reward_amount': rewardAmount,
        },
      );
    } catch (e) {
      debugPrint('Analytics logAdRewardEarned error: $e');
    }
  }

  // ==================== MATCHMAKING EVENTS ====================

  Future<void> logMatchmakingStart({required String mode}) async {
    try {
      await _analytics.logEvent(
        name: 'matchmaking_start',
        parameters: {'mode': mode},
      );
    } catch (e) {
      debugPrint('Analytics logMatchmakingStart error: $e');
    }
  }

  Future<void> logMatchFound({
    required String mode,
    required int waitTime,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'match_found',
        parameters: {
          'mode': mode,
          'wait_time_seconds': waitTime,
        },
      );
    } catch (e) {
      debugPrint('Analytics logMatchFound error: $e');
    }
  }

  // ==================== SOCIAL EVENTS ====================

  Future<void> logShare({
    required String contentType,
    required String method,
  }) async {
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: contentType,
        method: method,
      );
    } catch (e) {
      debugPrint('Analytics logShare error: $e');
    }
  }

  Future<void> logInviteSent({required String method}) async {
    try {
      await _analytics.logEvent(
        name: 'invite_sent',
        parameters: {'method': method},
      );
    } catch (e) {
      debugPrint('Analytics logInviteSent error: $e');
    }
  }

  // ==================== CUSTOM EVENTS ====================

  Future<void> logCustomEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logCustomEvent error: $e');
    }
  }
}
