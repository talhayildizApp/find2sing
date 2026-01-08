import 'package:flutter/services.dart';

/// Global Haptic Feedback Service
/// Consistent haptic patterns across all game modes (basic, challenge, online)
/// 
/// Feedback Categories:
/// - Answers: correct, wrong
/// - Actions: add, change, submit, skip
/// - States: freeze, bonus, gameEnd
/// - UI: selection, tap, scroll
class HapticService {
  // ═══════════════════════════════════════════════════════════════════════════
  // ANSWER FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Correct answer - celebratory double tap
  /// Used in: Basic (add song), Challenge (correct selection), Online (correct)
  static void correct() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Wrong answer - firm single impact
  /// Used in: Challenge (wrong selection), Online (wrong)
  static void wrong() {
    HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Song added successfully - satisfying pop
  /// Used in: Basic (+ Ekle button)
  static void songAdded() {
    HapticFeedback.mediumImpact();
  }

  /// Word changed - quick click
  /// Used in: Basic (Değiştir button), Challenge (skip)
  static void wordChanged() {
    HapticFeedback.selectionClick();
  }

  /// Submit action - confirmation tap
  /// Used in: Challenge (Onayla), Online (submit answer)
  static void submit() {
    HapticFeedback.mediumImpact();
  }

  /// Selection in list/grid
  /// Used in: Challenge (artist/song selection), Online (selections)
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Light tap for UI interactions
  static void tap() {
    HapticFeedback.selectionClick();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Freeze started - warning pattern
  /// Used in: Challenge Time Race (3s freeze), Relax (1s freeze)
  static void freezeStart() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Freeze ended - release feedback
  static void freezeEnd() {
    HapticFeedback.mediumImpact();
  }

  /// Penalty applied (progressive freeze)
  static void penalty() {
    HapticFeedback.heavyImpact();
  }

  /// Bonus earned - excitement pattern
  /// Used in: Online (comeback bonus, +2 steal)
  static void bonus() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 60), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 140), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Leaderboard entry - achievement pattern
  static void leaderboard() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME FLOW FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Game started
  static void gameStart() {
    HapticFeedback.mediumImpact();
  }

  /// Turn changed (online)
  static void turnChange() {
    HapticFeedback.mediumImpact();
  }

  /// Game ended - win
  static void gameWin() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Game ended - loss
  static void gameLose() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Game ended - tie
  static void gameTie() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.mediumImpact();
    });
  }

  /// Challenge completed successfully
  static void challengeComplete() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 80), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 160), () {
      HapticFeedback.lightImpact();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME WARNINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Time warning - every 10 seconds in last 30
  static void timeWarning() {
    HapticFeedback.lightImpact();
  }

  /// Time critical - last 5 seconds
  static void timeCritical() {
    HapticFeedback.mediumImpact();
  }

  /// Time expired
  static void timeExpired() {
    HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REVIEWER (ONLINE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Review countdown tick (last 3 seconds)
  static void reviewTick() {
    HapticFeedback.selectionClick();
  }

  /// Review submitted (approve/reject)
  static void reviewSubmitted() {
    HapticFeedback.mediumImpact();
  }

  /// Auto-approve triggered
  static void autoApprove() {
    HapticFeedback.lightImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY ALIASES (backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  static void penaltyEnd() => freezeEnd();
  static void notification() => HapticFeedback.vibrate();
  static void success() => correct();
  static void error() => wrong();
}
