import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// APP TEXT THEME - Find2Sing Typography System
// Consistent font sizes, weights, and hierarchy across the entire app
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// TEXT COLORS
// ─────────────────────────────────────────────────────────────────────────────

class AppTextColors {
  // Primary text colors
  static const Color primary = Color(0xFF394272);      // Headings, titles
  static const Color secondary = Color(0xFF6C6FA4);    // Body text, descriptions
  static const Color tertiary = Color(0xFF9A9CC0);     // Captions, hints
  static const Color disabled = Color(0xFFBDBDC7);     // Disabled states

  // On-surface colors
  static const Color onDark = Colors.white;
  static const Color onDarkSecondary = Color(0xFFE8E8FF);
  static const Color onPrimary = Colors.white;
  static const Color onAccent = Colors.white;

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFE65100);
  static const Color info = Color(0xFF1976D2);

  // Game-specific
  static const Color player1 = Color(0xFF7C4DFF);
  static const Color player2 = Color(0xFFFF6B6B);
  static const Color score = Color(0xFFFFB958);
  static const Color timer = Color(0xFFFF6B6B);
  static const Color word = Color(0xFF394272);
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY SCALE
// ─────────────────────────────────────────────────────────────────────────────

class AppTextTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY - Hero sections, splash screens
  // ═══════════════════════════════════════════════════════════════════════════

  /// Display Large - 48sp, w800
  /// Use: Hero text, app name, large numbers
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1.5,
    color: AppTextColors.primary,
  );

  /// Display Medium - 36sp, w800
  /// Use: Section heroes, large stats
  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -1.0,
    color: AppTextColors.primary,
  );

  /// Display Small - 32sp, w700
  /// Use: Result scores, countdown numbers
  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppTextColors.primary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADLINE - Page titles, section headers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Headline Large - 28sp, w800
  /// Use: Main page titles (Challenge, Profile)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppTextColors.primary,
  );

  /// Headline Medium - 24sp, w700
  /// Use: Screen subtitles, dialog titles
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppTextColors.primary,
  );

  /// Headline Small - 20sp, w700
  /// Use: Section titles, card headers
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppTextColors.primary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE - Card titles, list item headers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Title Large - 18sp, w700
  /// Use: Card titles, prominent list items
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
    color: AppTextColors.primary,
  );

  /// Title Medium - 16sp, w700
  /// Use: Standard card titles, navigation items
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0,
    color: AppTextColors.primary,
  );

  /// Title Small - 14sp, w700
  /// Use: Compact card titles, chip headers
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppTextColors.primary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY - Paragraphs, descriptions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Body Large - 16sp, w400
  /// Use: Main body text, descriptions
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppTextColors.secondary,
  );

  /// Body Medium - 14sp, w400
  /// Use: Secondary descriptions, list subtitles
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.1,
    color: AppTextColors.secondary,
  );

  /// Body Small - 12sp, w400
  /// Use: Captions, timestamps, metadata
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppTextColors.tertiary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LABEL - Buttons, badges, chips
  // ═══════════════════════════════════════════════════════════════════════════

  /// Label Large - 16sp, w700
  /// Use: Primary buttons, prominent CTAs
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0.5,
    color: AppTextColors.onPrimary,
  );

  /// Label Medium - 14sp, w600
  /// Use: Secondary buttons, tabs
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppTextColors.primary,
  );

  /// Label Small - 12sp, w600
  /// Use: Chips, badges, tags
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppTextColors.secondary,
  );

  /// Label XSmall - 10sp, w600
  /// Use: Micro badges, status indicators
  static const TextStyle labelXSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: AppTextColors.tertiary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS - Color variations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply custom color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply on-dark color for dark backgrounds
  static TextStyle onDark(TextStyle style) {
    return style.copyWith(color: AppTextColors.onDark);
  }

  /// Apply secondary color
  static TextStyle asSecondary(TextStyle style) {
    return style.copyWith(color: AppTextColors.secondary);
  }

  /// Apply disabled color
  static TextStyle asDisabled(TextStyle style) {
    return style.copyWith(color: AppTextColors.disabled);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME TEXT STYLES - Specialized styles for game screens
// ─────────────────────────────────────────────────────────────────────────────

class GameTextStyles {
  // ═══════════════════════════════════════════════════════════════════════════
  // WORD DISPLAY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main game word - Large prominent display
  static const TextStyle wordLarge = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 2,
    color: AppTextColors.word,
  );

  /// Medium word display
  static const TextStyle wordMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: 1.5,
    color: AppTextColors.word,
  );

  /// Small/compact word display
  static const TextStyle wordSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1,
    color: AppTextColors.word,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Large countdown timer
  static const TextStyle timerLarge = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2,
    color: AppTextColors.timer,
  );

  /// Medium timer display
  static const TextStyle timerMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1,
    color: AppTextColors.timer,
  );

  /// Small inline timer
  static const TextStyle timerSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: AppTextColors.timer,
  );

  /// Timer with custom urgency color
  static TextStyle timerUrgent(bool isUrgent) {
    return timerMedium.copyWith(
      color: isUrgent ? const Color(0xFFFF3B30) : AppTextColors.timer,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCORE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Large score display (result screens)
  static const TextStyle scoreLarge = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2,
    color: AppTextColors.score,
  );

  /// Medium score display (in-game)
  static const TextStyle scoreMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1,
    color: AppTextColors.score,
  );

  /// Small inline score
  static const TextStyle scoreSmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: AppTextColors.score,
  );

  /// Score with player color
  static TextStyle scoreForPlayer(int playerNumber) {
    return scoreMedium.copyWith(
      color: playerNumber == 1 ? AppTextColors.player1 : AppTextColors.player2,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYER LABELS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Player name label
  static const TextStyle playerName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
    color: AppTextColors.primary,
  );

  /// Player turn indicator
  static const TextStyle turnIndicator = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppTextColors.onDark,
  );

  /// Player 1 styled name
  static TextStyle player1Name = playerName.copyWith(
    color: AppTextColors.player1,
  );

  /// Player 2 styled name
  static TextStyle player2Name = playerName.copyWith(
    color: AppTextColors.player2,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Found song button text
  static const TextStyle foundButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppTextColors.onPrimary,
  );

  /// Pass/skip button text
  static const TextStyle passButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppTextColors.secondary,
  );

  /// Word change counter
  static const TextStyle wordChangeCounter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: AppTextColors.tertiary,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT TEXT STYLES - Specialized styles for result/completion screens
// ─────────────────────────────────────────────────────────────────────────────

class ResultTextStyles {
  // ═══════════════════════════════════════════════════════════════════════════
  // OUTCOME HEADERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Victory title
  static const TextStyle victoryTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: Color(0xFF4CAF50),
  );

  /// Defeat title
  static const TextStyle defeatTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: Color(0xFFFF6B6B),
  );

  /// Draw/Tie title
  static const TextStyle drawTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: Color(0xFFFFB958),
  );

  /// Generic completion title
  static const TextStyle completionTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppTextColors.primary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // FINAL SCORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main final score
  static const TextStyle finalScore = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -3,
    color: AppTextColors.primary,
  );

  /// Score comparison (vs opponent)
  static const TextStyle scoreComparison = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -1,
    color: AppTextColors.secondary,
  );

  /// Score label (under number)
  static const TextStyle scoreLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppTextColors.tertiary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stat value (number)
  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppTextColors.primary,
  );

  /// Stat label (description)
  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppTextColors.tertiary,
  );

  /// Time elapsed display
  static const TextStyle timeElapsed = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppTextColors.secondary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // FEEDBACK MESSAGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Success message
  static const TextStyle successMessage = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: Color(0xFF4CAF50),
  );

  /// Encouragement text
  static const TextStyle encouragement = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
    color: AppTextColors.secondary,
  );

  /// Achievement unlocked
  static const TextStyle achievementUnlocked = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.3,
    color: Color(0xFFFFD700),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CHALLENGE TEXT STYLES - Challenge mode specific
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeTextStyles {
  /// Challenge title (detail screen)
  static const TextStyle challengeTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppTextColors.primary,
  );

  /// Challenge description
  static const TextStyle challengeDescription = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTextColors.secondary,
  );

  /// Difficulty badge
  static const TextStyle difficultyBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.3,
    color: AppTextColors.onPrimary,
  );

  /// Song count
  static const TextStyle songCount = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppTextColors.secondary,
  );

  /// Category title
  static const TextStyle categoryTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: AppTextColors.primary,
  );

  /// Category subtitle
  static const TextStyle categorySubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
    color: AppTextColors.secondary,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE MODE TEXT STYLES
// ─────────────────────────────────────────────────────────────────────────────

class OnlineTextStyles {
  /// Invite code display
  static const TextStyle inviteCode = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 4,
    color: Color(0xFFFFD700),
  );

  /// Opponent name
  static const TextStyle opponentName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
    color: AppTextColors.primary,
  );

  /// Waiting message
  static const TextStyle waitingMessage = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: AppTextColors.secondary,
  );

  /// Turn indicator
  static const TextStyle turnText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppTextColors.onPrimary,
  );

  /// Review countdown
  static const TextStyle reviewCountdown = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1,
    color: Color(0xFFFF6B6B),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BUTTON TEXT STYLES
// ─────────────────────────────────────────────────────────────────────────────

class ButtonTextStyles {
  /// Primary CTA button
  static const TextStyle primaryCTA = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppTextColors.onPrimary,
  );

  /// Secondary button
  static const TextStyle secondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.3,
    color: AppTextColors.primary,
  );

  /// Text button (link style)
  static const TextStyle textButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: Color(0xFFCAB7FF),
  );

  /// Destructive action
  static const TextStyle destructive = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.3,
    color: Color(0xFFFF3B30),
  );

  /// Disabled button
  static const TextStyle disabled = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.3,
    color: AppTextColors.disabled,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT TEXT STYLES
// ─────────────────────────────────────────────────────────────────────────────

class InputTextStyles {
  /// Input text
  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    color: AppTextColors.primary,
  );

  /// Input placeholder
  static const TextStyle placeholder = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    color: AppTextColors.tertiary,
  );

  /// Input label
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppTextColors.primary,
  );

  /// Input helper text
  static const TextStyle helper = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    color: AppTextColors.tertiary,
  );

  /// Input error text
  static const TextStyle error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
    color: AppTextColors.error,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG TEXT STYLES
// ─────────────────────────────────────────────────────────────────────────────

class DialogTextStyles {
  /// Dialog title
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppTextColors.primary,
  );

  /// Dialog body
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTextColors.secondary,
  );

  /// Dialog action button
  static const TextStyle action = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: Color(0xFFCAB7FF),
  );

  /// Dialog destructive action
  static const TextStyle destructiveAction = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: Color(0xFFFF3B30),
  );
}
