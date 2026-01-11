import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import '../../services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CHALLENGE UI COMPONENTS - Premium Design System
// Soft background + Glass cards + Searchable pickers
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeColors {
  static const Color primaryPurple = Color(0xFFCAB7FF);
  static const Color darkPurple = Color(0xFF394272);
  static const Color softPurple = Color(0xFFF5F0FF);
  static const Color timeRace = Color(0xFFFF6B6B);
  static const Color relax = Color(0xFF66BB6A);
  static const Color realChallenge = Color(0xFFFFB958);
  static const Color correct = Color(0xFF4CAF50);
  static const Color wrong = Color(0xFFF85149);
  static const Color freeze = Color(0xFF64B5F6);
  static const Color glassWhite = Color(0xFFFFFFFE);
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOUD BACKGROUND SCAFFOLD
// Reusable scaffold with cloud background + overlay gradient
// ─────────────────────────────────────────────────────────────────────────────

class CloudBackgroundScaffold extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final Color? overlayColor;
  final double overlayOpacity;

  const CloudBackgroundScaffold({
    super.key,
    required this.child,
    this.showLogo = false,
    this.overlayColor,
    this.overlayOpacity = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cloud background
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (overlayColor ?? Colors.white).withValues(alpha:overlayOpacity),
                  (overlayColor ?? Colors.white).withValues(alpha:0.1),
                  ChallengeColors.softPurple.withValues(alpha:0.3),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHALLENGE HEADER BAR
// Mode pill + Timer pill + Progress row
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeHeaderBar extends StatelessWidget {
  final ChallengeSingleMode mode;
  final int timerSeconds;
  final int totalTimerSeconds;
  final int solvedCount;
  final int totalCount;
  final int? score;
  final VoidCallback onClose;
  final bool isOnline;
  final String? playerName;
  final String? opponentName;
  final int? opponentScore;
  final bool isMyTurn;

  const ChallengeHeaderBar({
    super.key,
    required this.mode,
    required this.timerSeconds,
    required this.totalTimerSeconds,
    required this.solvedCount,
    required this.totalCount,
    this.score,
    required this.onClose,
    this.isOnline = false,
    this.playerName,
    this.opponentName,
    this.opponentScore,
    this.isMyTurn = true,
  });

  Color get _modeColor {
    switch (mode) {
      case ChallengeSingleMode.timeRace:
        return ChallengeColors.timeRace;
      case ChallengeSingleMode.relax:
        return ChallengeColors.relax;
      case ChallengeSingleMode.real:
        return ChallengeColors.realChallenge;
    }
  }

  String get _modeName {
    switch (mode) {
      case ChallengeSingleMode.timeRace:
        return 'Time Race';
      case ChallengeSingleMode.relax:
        return 'Relax';
      case ChallengeSingleMode.real:
        return 'Real Challenge';
    }
  }

  String get _modeEmoji {
    switch (mode) {
      case ChallengeSingleMode.timeRace:
        return '⚡';
      case ChallengeSingleMode.relax:
        return '🧘';
      case ChallengeSingleMode.real:
        return '🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = timerSeconds <= 30 && mode == ChallengeSingleMode.timeRace;
    final isCritical = timerSeconds <= 10;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          // HUD Row 1: Back + Mode Pill + Timer Pill
          Row(
            children: [
              // Back button (transparent, minimal)
              _HudBackButton(onTap: onClose),
              const SizedBox(width: 16),

              // Mode pill (game HUD style)
              _HudModePill(
                emoji: _modeEmoji,
                name: _modeName,
                color: _modeColor,
              ),

              const Spacer(),

              // Timer pill (prominent, game-like)
              _HudTimerPill(
                seconds: timerSeconds,
                color: isCritical
                    ? ChallengeColors.wrong
                    : isUrgent
                        ? ChallengeColors.realChallenge
                        : _modeColor,
                isUrgent: isUrgent || isCritical,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // HUD Row 2: Stats (minimal, game-like)
          if (isOnline)
            _buildOnlineScoreboard()
          else
            _buildHudStats(),
        ],
      ),
    );
  }

  Widget _buildHudStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HudStat(
          emoji: '🟢',
          label: 'Çözülen',
          value: '$solvedCount',
        ),
        const SizedBox(width: 20),
        _HudStat(
          emoji: '🟡',
          label: 'Kalan',
          value: '${totalCount - solvedCount}',
        ),
        if (mode == ChallengeSingleMode.real) ...[
          const SizedBox(width: 20),
          _HudStat(
            emoji: '⭐',
            label: 'Skor',
            value: '${score ?? 0}',
            highlight: true,
          ),
        ],
      ],
    );
  }

  Widget _buildOnlineScoreboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Player
          Expanded(
            child: _PlayerScoreCard(
              name: playerName ?? 'Sen',
              score: score ?? 0,
              isActive: isMyTurn,
              isPlayer: true,
            ),
          ),
          
          // VS divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ChallengeColors.softPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ChallengeColors.primaryPurple,
              ),
            ),
          ),

          // Opponent
          Expanded(
            child: _PlayerScoreCard(
              name: opponentName ?? 'Rakip',
              score: opponentScore ?? 0,
              isActive: !isMyTurn,
              isPlayer: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HUD COMPONENTS - Game-like, minimal, fast-readable
// ─────────────────────────────────────────────────────────────────────────────

class _HudBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HudBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha:0.2)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _HudModePill extends StatelessWidget {
  final String emoji;
  final String name;
  final Color color;

  const _HudModePill({
    required this.emoji,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudTimerPill extends StatelessWidget {
  final int seconds;
  final Color color;
  final bool isUrgent;

  const _HudTimerPill({
    required this.seconds,
    required this.color,
    this.isUrgent = false,
  });

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isUrgent ? 1.1 : 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUrgent
                ? [color, color.withValues(alpha:0.8)]
                : [color.withValues(alpha:0.3), color.withValues(alpha:0.15)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isUrgent ? color : color.withValues(alpha:0.5)),
          boxShadow: isUrgent
              ? [BoxShadow(color: color.withValues(alpha:0.5), blurRadius: 16, spreadRadius: 2)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⏱', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              _formatTime(seconds),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: isUrgent
                    ? [Shadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 4)]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool highlight;

  const _HudStat({
    required this.emoji,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha:0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: highlight ? ChallengeColors.realChallenge : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final String name;
  final int score;
  final bool isActive;
  final bool isPlayer;

  const _PlayerScoreCard({
    required this.name,
    required this.score,
    required this.isActive,
    required this.isPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPlayer ? ChallengeColors.primaryPurple : ChallengeColors.realChallenge;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isActive
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
              color: color.withValues(alpha:0.1),
            )
          : null,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: ChallengeColors.correct,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: ChallengeColors.darkPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD HERO CARD - Consistent with single_game_screen sun design
// Timer arc around sun, matching sizes
// ─────────────────────────────────────────────────────────────────────────────

class WordHeroCard extends StatelessWidget {
  final String word;
  final String? categoryName;
  final String? helperText;
  final int? timerSeconds;
  final int? totalSeconds;
  final int? gameTimeSeconds;
  final bool isGameTimeCountdown;
  final VoidCallback? onChangeWord;
  final Color? glowColor;
  final bool animate;

  const WordHeroCard({
    super.key,
    required this.word,
    this.categoryName,
    this.helperText,
    this.timerSeconds,
    this.totalSeconds,
    this.gameTimeSeconds,
    this.isGameTimeCountdown = false,
    this.onChangeWord,
    this.glowColor,
    this.animate = true,
  });

  String _formatTime(int seconds) {
    if (seconds <= 0) return '0:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Timer calculations
    final hasTimer = timerSeconds != null && totalSeconds != null && totalSeconds! > 0;
    final progress = hasTimer ? (timerSeconds! / totalSeconds!).clamp(0.0, 1.0) : 1.0;
    final seconds = timerSeconds ?? 0;

    // Kritik seviyeler (pulse animasyonu için)
    final isCritical = hasTimer && seconds <= 30; // Son 30 saniye kritik
    final isUrgent = hasTimer && seconds <= 10;   // Son 10 saniye çok kritik

    // Timer color - 5 dakikalık countdown için soft renk geçişi
    // Açık bulut arka planına uyumlu, göz yormayan tonlar
    // 5:00 - 4:00 → Koyu yeşil (rahat)
    // 4:00 - 3:00 → Koyu teal (hala iyi)
    // 3:00 - 2:00 → Koyu mavi (orta)
    // 2:00 - 1:00 → Koyu amber (dikkat)
    // 1:00 - 0:30 → Burnt orange (acele)
    // 0:30 - 0:00 → Koyu kırmızı (kritik)
    Color timerColor;
    if (seconds > 240) {
      // 4+ dakika: Koyu yeşil - rahat
      timerColor = const Color(0xFF2E7D32); // Dark green
    } else if (seconds > 180) {
      // 3-4 dakika: Koyu teal - hala iyi
      timerColor = const Color(0xFF00796B); // Dark teal
    } else if (seconds > 120) {
      // 2-3 dakika: Koyu mavi - orta
      timerColor = const Color(0xFF1565C0); // Dark blue
    } else if (seconds > 60) {
      // 1-2 dakika: Koyu amber - dikkat
      timerColor = const Color(0xFFE65100); // Dark orange
    } else if (seconds > 30) {
      // 30sn - 1dk: Burnt orange - acele
      timerColor = const Color(0xFFD84315); // Deep orange
    } else {
      // Son 30 saniye: Koyu kırmızı - kritik
      timerColor = const Color(0xFFC62828); // Dark red
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(word),
      tween: Tween(begin: animate ? 0.95 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      // Size matching single_game_screen (200x200 sun)
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sun background (same size as single_game_screen)
            Image.asset(
              'assets/images/friend_sun.png',
              width: 200,
              height: 200,
            ),

            // Word (centered on sun)
            Text(
              word.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF394272),
                letterSpacing: 1,
              ),
            ),

            // Timer badge (top - consistent positioning across all game modes)
            if (hasTimer)
              Positioned(
                top: 15,
                child: TweenAnimationBuilder<double>(
                  // Son 10 saniye daha büyük ve hızlı pulse
                  tween: Tween(begin: 1.0, end: isUrgent ? 1.15 : (isCritical ? 1.1 : 1.0)),
                  duration: Duration(milliseconds: isUrgent ? 200 : (isCritical ? 300 : 150)),
                  builder: (context, pulseScale, child) {
                    return Transform.scale(scale: pulseScale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      // Son 30 saniye dolgu rengi aktif
                      color: isCritical ? timerColor : timerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isCritical
                          ? [
                              BoxShadow(
                                // Son 10 saniye daha güçlü glow
                                color: timerColor.withValues(alpha: isUrgent ? 0.6 : 0.4),
                                blurRadius: isUrgent ? 12 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: isCritical ? Colors.white : timerColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(timerSeconds!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isCritical ? Colors.white : timerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Timer arc (around sun) - matching single_game_screen
            if (hasTimer)
              Positioned.fill(
                child: CustomPaint(
                  painter: _WordTimerArcPainter(
                    progress: progress,
                    color: timerColor,
                    strokeWidth: 4,
                  ),
                ),
              ),

            // Game time (secondary, bottom) - only for Relax mode
            if (gameTimeSeconds != null)
              Positioned(
                bottom: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_bottom,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(gameTimeSeconds!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Timer arc painter - matches single_game_screen style
class _WordTimerArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _WordTimerArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WordTimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS CARD - Frosted glass effect
// ─────────────────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha:0.85),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha:0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: size * 0.5,
              color: color ?? ChallengeColors.darkPurple,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PICKER FIELD - Dropdown-style field that opens bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool enabled;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? emoji;
  final Color? color;

  const PickerField({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    this.enabled = true,
    this.onTap,
    this.icon,
    this.emoji,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final effectiveColor = color ?? ChallengeColors.primaryPurple;

    return GestureDetector(
      onTap: enabled ? () {
        HapticService.tap();
        onTap?.call();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled
              ? (hasValue ? effectiveColor.withValues(alpha:0.08) : Colors.white)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? effectiveColor.withValues(alpha:0.4)
                : enabled
                    ? ChallengeColors.darkPurple.withValues(alpha:0.15)
                    : Colors.grey.shade300,
            width: hasValue ? 2 : 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon/Emoji
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 20))
            else if (icon != null)
              Icon(
                icon,
                size: 22,
                color: hasValue ? effectiveColor : ChallengeColors.darkPurple.withValues(alpha:0.4),
              ),
            const SizedBox(width: 12),

            // Label & Value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ChallengeColors.darkPurple.withValues(alpha:0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : placeholder,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? ChallengeColors.darkPurple
                          : ChallengeColors.darkPurple.withValues(alpha:0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled
                  ? ChallengeColors.darkPurple.withValues(alpha:0.4)
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCHABLE BOTTOM SHEET PICKER
// ─────────────────────────────────────────────────────────────────────────────

class SearchableBottomSheetPicker<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final String? Function(T)? itemSubtitle;
  final void Function(T) onSelect;
  final T? selectedItem;
  final String searchHint;
  final Color? accentColor;

  const SearchableBottomSheetPicker({
    super.key,
    required this.title,
    required this.items,
    required this.itemLabel,
    this.itemSubtitle,
    required this.onSelect,
    this.selectedItem,
    this.searchHint = 'Ara...',
    this.accentColor,
  });

  static Future<void> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    String? Function(T)? itemSubtitle,
    required void Function(T) onSelect,
    T? selectedItem,
    String searchHint = 'Ara...',
    Color? accentColor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchableBottomSheetPicker<T>(
        title: title,
        items: items,
        itemLabel: itemLabel,
        itemSubtitle: itemSubtitle,
        onSelect: onSelect,
        selectedItem: selectedItem,
        searchHint: searchHint,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<SearchableBottomSheetPicker<T>> createState() =>
      _SearchableBottomSheetPickerState<T>();
}

class _SearchableBottomSheetPickerState<T>
    extends State<SearchableBottomSheetPicker<T>> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.itemLabel(item).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? ChallengeColors.primaryPurple;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ChallengeColors.darkPurple,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Search field - ikon odaklı, minimal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Arama ikonu - büyük ve belirgin
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color: ChallengeColors.primaryPurple,
                      size: 22,
                    ),
                  ),
                  // Text field - minimal
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ChallengeColors.darkPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Items list
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: bottomPadding + 20,
                    ),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.selectedItem != null &&
                          widget.itemLabel(item) ==
                              widget.itemLabel(widget.selectedItem as T);

                      return _PickerItem(
                        label: widget.itemLabel(item),
                        subtitle: widget.itemSubtitle?.call(item),
                        isSelected: isSelected,
                        color: color,
                        onTap: () {
                          HapticService.selection();
                          widget.onSelect(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PickerItem({
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha:0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: color.withValues(alpha:0.4), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: ChallengeColors.darkPurple,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: ChallengeColors.darkPurple.withValues(alpha:0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOLVED SONGS CARD - Solid white card style (like image 2)
// ─────────────────────────────────────────────────────────────────────────────

class SolvedSongsCard extends StatelessWidget {
  final List<ChallengeSongModel> songs;
  final int maxVisible;
  final VoidCallback? onViewAll;

  const SolvedSongsCard({
    super.key,
    required this.songs,
    this.maxVisible = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFE),
            Color(0xFFF8F0FF),
            Color(0xFFE8FFE8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCAB7FF).withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Color(0xFFCAB7FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Bulduğun Şarkılar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ChallengeColors.darkPurple,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ChallengeColors.correct.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${songs.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ChallengeColors.correct,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Songs list or empty state
          if (songs.isEmpty)
            _buildEmptyState()
          else
            _buildSongsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Icon(
            Icons.music_off_rounded,
            color: Colors.grey.shade300,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz şarkı eklemedin',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yukarıdan şarkı ve sanatçı girerek başla!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    final visibleSongs = songs.length > maxVisible
        ? songs.sublist(songs.length - maxVisible)
        : songs;

    return Column(
      children: [
        ...visibleSongs.reversed.map((song) => _SolidSongListItem(song: song)),
        if (songs.length > maxVisible)
          GestureDetector(
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${songs.length - maxVisible} şarkı daha',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCAB7FF),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SolidSongListItem extends StatelessWidget {
  final ChallengeSongModel song;

  const _SolidSongListItem({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ChallengeColors.correct.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChallengeColors.correct.withValues(alpha:0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ChallengeColors.correct.withValues(alpha:0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: ChallengeColors.correct,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ChallengeColors.darkPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ChallengeColors.darkPurple.withValues(alpha:0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FREEZE OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeFreezeOverlay extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;

  const ChallengeFreezeOverlay({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: ChallengeColors.freeze.withValues(alpha:0.2),
          child: Center(
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ChallengeColors.freeze,
                          ChallengeColors.freeze.withValues(alpha:0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ChallengeColors.freeze.withValues(alpha:0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🥶', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'DONDURULDU',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: ChallengeColors.darkPurple,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$secondsLeft saniye',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ChallengeColors.freeze,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalSeconds > 0 ? (1 - (secondsLeft / totalSeconds)).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: ChallengeColors.freeze.withValues(alpha:0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          ChallengeColors.freeze,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TURN BANNER (Online)
// ─────────────────────────────────────────────────────────────────────────────

class TurnBanner extends StatelessWidget {
  final bool isMyTurn;
  final String? opponentName;

  const TurnBanner({
    super.key,
    required this.isMyTurn,
    this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: isMyTurn
            ? LinearGradient(
                colors: [
                  ChallengeColors.primaryPurple,
                  ChallengeColors.primaryPurple.withValues(alpha:0.8),
                ],
              )
            : null,
        color: isMyTurn ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMyTurn
            ? null
            : Border.all(color: ChallengeColors.realChallenge.withValues(alpha:0.3)),
        boxShadow: [
          BoxShadow(
            color: isMyTurn
                ? ChallengeColors.primaryPurple.withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isMyTurn) ...[
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            const Text(
              'SENİN SIRAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ] else ...[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ChallengeColors.realChallenge,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${opponentName ?? "Rakip"} oynuyor...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ChallengeColors.realChallenge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIMARY CTA BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeCTAButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? color;
  final IconData? icon;
  final bool isLoading;

  const ChallengeCTAButton({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.color,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ChallengeColors.primaryPurple;
    final isActive = enabled && !isLoading;

    return GestureDetector(
      onTap: isActive ? () {
        HapticService.submit();
        onTap?.call();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [effectiveColor, effectiveColor.withValues(alpha:0.8)],
                )
              : null,
          color: isActive ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha:0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: isActive ? Colors.white : Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK TOAST
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeFeedbackToast extends StatelessWidget {
  final String message;
  final bool isCorrect;
  final String? bonus;

  const ChallengeFeedbackToast({
    super.key,
    required this.message,
    required this.isCorrect,
    this.bonus,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? ChallengeColors.correct : ChallengeColors.wrong;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha:0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (bonus != null)
                  Text(
                    bonus!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TURN LOCK OVERLAY - "Rakip Oynuyor" overlay for online mode
// ─────────────────────────────────────────────────────────────────────────────

class TurnLockOverlay extends StatelessWidget {
  final String? opponentName;

  const TurnLockOverlay({super.key, this.opponentName});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.white.withValues(alpha:0.6),
          child: Center(
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ChallengeColors.realChallenge,
                            ChallengeColors.realChallenge.withValues(alpha:0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ChallengeColors.realChallenge.withValues(alpha:0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sıra Rakipte',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ChallengeColors.darkPurple),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${opponentName ?? "Rakip"} düşünüyor...',
                    style: TextStyle(fontSize: 15, color: ChallengeColors.darkPurple.withValues(alpha:0.6)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SELECTION INPUT CARD - Glassmorphism + gradient (like image 2)
// ─────────────────────────────────────────────────────────────────────────────

class SelectionInputCard extends StatelessWidget {
  final String? selectedArtist;
  final String? selectedSong;
  final bool enabled;
  final VoidCallback? onArtistTap;
  final VoidCallback? onSongTap;
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  const SelectionInputCard({
    super.key,
    this.selectedArtist,
    this.selectedSong,
    this.enabled = true,
    this.onArtistTap,
    this.onSongTap,
    this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha:0.95),
            const Color(0xFFF8F0FF).withValues(alpha:0.9),
            const Color(0xFFE8FFE8).withValues(alpha:0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Yan yana picker row (like image 3)
          Row(
            children: [
              // Artist picker
              Expanded(
                child: _GlassPickerField(
                  icon: '🎤',
                  label: 'Sanatçı',
                  value: selectedArtist,
                  enabled: enabled,
                  onTap: onArtistTap,
                ),
              ),
              const SizedBox(width: 12),
              // Song picker
              Expanded(
                child: _GlassPickerField(
                  icon: '🎵',
                  label: 'Şarkı',
                  value: selectedSong,
                  enabled: enabled,
                  onTap: onSongTap,
                ),
              ),
            ],
          ),
          
          // Show confirmation bar when both selected
          if (selectedArtist != null && selectedSong != null) ...[
            const SizedBox(height: 16),
            _ConfirmationBar(
              artist: selectedArtist!,
              song: selectedSong!,
              onConfirm: onSubmit,
              isLoading: isSubmitting,
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassPickerField extends StatefulWidget {
  final String icon;
  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback? onTap;

  const _GlassPickerField({
    required this.icon,
    required this.label,
    this.value,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<_GlassPickerField> createState() => _GlassPickerFieldState();
}

class _GlassPickerFieldState extends State<_GlassPickerField> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.isNotEmpty;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled ? () {
        HapticService.tap();
        widget.onTap?.call();
      } : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: hasValue
                ? const Color(0xFFCAB7FF).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasValue
                  ? const Color(0xFFCAB7FF).withValues(alpha: 0.4)
                  : Colors.grey.shade200,
              width: hasValue ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sol ikon - tek seferde
              Text(widget.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),

              // İçerik
              Expanded(
                child: hasValue
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.value!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Text(
                        '${widget.label} Seç',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
              ),

              // Dropdown ok
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: hasValue ? const Color(0xFFCAB7FF) : Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationBar extends StatelessWidget {
  final String artist;
  final String song;
  final VoidCallback? onConfirm;
  final bool isLoading;

  const _ConfirmationBar({
    required this.artist,
    required this.song,
    this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          // Song info
          Text('🎤', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artist,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // X button
          GestureDetector(
            onTap: () {
              // Could add clear functionality
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Onayla button
          GestureDetector(
            onTap: isLoading ? null : () {
              HapticService.submit();
              onConfirm?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha:0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Onayla',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep old HorizontalPickerRow for backwards compatibility
class HorizontalPickerRow extends StatelessWidget {
  final String? selectedArtist;
  final String? selectedSong;
  final bool enabled;
  final VoidCallback? onArtistTap;
  final VoidCallback? onSongTap;

  const HorizontalPickerRow({
    super.key,
    this.selectedArtist,
    this.selectedSong,
    this.enabled = true,
    this.onArtistTap,
    this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GamePickerButton(
            label: 'Sanatçı',
            value: selectedArtist,
            emoji: '🎤',
            enabled: enabled,
            onTap: onArtistTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GamePickerButton(
            label: 'Şarkı',
            value: selectedSong,
            emoji: '🎵',
            enabled: enabled,
            onTap: onSongTap,
          ),
        ),
      ],
    );
  }
}

class _GamePickerButton extends StatelessWidget {
  final String label;
  final String? value;
  final String emoji;
  final bool enabled;
  final VoidCallback? onTap;

  const _GamePickerButton({
    required this.label,
    this.value,
    required this.emoji,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    
    return GestureDetector(
      onTap: enabled ? () { 
        HapticService.tap(); 
        onTap?.call(); 
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: hasValue 
              ? LinearGradient(
                  colors: [
                    ChallengeColors.primaryPurple.withValues(alpha:0.2),
                    ChallengeColors.primaryPurple.withValues(alpha:0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasValue ? null : Colors.white.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue 
                ? ChallengeColors.primaryPurple.withValues(alpha:0.5)
                : Colors.white.withValues(alpha:0.3),
            width: hasValue ? 2 : 1,
          ),
          boxShadow: hasValue ? [
            BoxShadow(
              color: ChallengeColors.primaryPurple.withValues(alpha:0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha:0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : 'Seç',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                      color: hasValue ? Colors.white : Colors.white.withValues(alpha:0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: Colors.white.withValues(alpha:0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULT SCREEN COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class ResultHeroIcon extends StatelessWidget {
  final bool isWinner;
  final bool isTie;

  const ResultHeroIcon({super.key, required this.isWinner, this.isTie = false});

  @override
  Widget build(BuildContext context) {
    final color = isTie ? ChallengeColors.realChallenge : isWinner ? ChallengeColors.correct : ChallengeColors.wrong;
    final emoji = isTie ? '🤝' : isWinner ? '🏆' : '😔';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha:0.7)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha:0.4), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 56))),
      ),
    );
  }
}

class ResultScoreComparison extends StatelessWidget {
  final String playerName;
  final int playerScore;
  final String opponentName;
  final int opponentScore;

  const ResultScoreComparison({super.key, required this.playerName, required this.playerScore, required this.opponentName, required this.opponentScore});

  @override
  Widget build(BuildContext context) {
    final playerWon = playerScore > opponentScore;
    final tie = playerScore == opponentScore;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Expanded(child: Column(children: [
            Text(playerName, style: TextStyle(fontSize: 13, color: ChallengeColors.darkPurple.withValues(alpha:0.6))),
            const SizedBox(height: 4),
            Text('$playerScore', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: playerWon && !tie ? ChallengeColors.correct : ChallengeColors.darkPurple)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: ChallengeColors.softPurple, borderRadius: BorderRadius.circular(12)),
            child: const Text('VS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ChallengeColors.primaryPurple)),
          ),
          Expanded(child: Column(children: [
            Text(opponentName, style: TextStyle(fontSize: 13, color: ChallengeColors.darkPurple.withValues(alpha:0.6))),
            const SizedBox(height: 4),
            Text('$opponentScore', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: !playerWon && !tie ? ChallengeColors.correct : ChallengeColors.realChallenge)),
          ])),
        ],
      ),
    );
  }
}

class ResultStatRow extends StatelessWidget {
  final int correctCount;
  final int wrongCount;
  final int durationSeconds;

  const ResultStatRow({super.key, required this.correctCount, required this.wrongCount, required this.durationSeconds});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(icon: Icons.check_circle_rounded, value: '$correctCount', label: 'Doğru', color: ChallengeColors.correct),
        Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 24), color: ChallengeColors.darkPurple.withValues(alpha:0.1)),
        _StatItem(icon: Icons.cancel_rounded, value: '$wrongCount', label: 'Yanlış', color: ChallengeColors.wrong),
        Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 24), color: ChallengeColors.darkPurple.withValues(alpha:0.1)),
        _StatItem(icon: Icons.timer_rounded, value: _formatTime(durationSeconds), label: 'Süre', color: ChallengeColors.darkPurple),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: ChallengeColors.darkPurple.withValues(alpha:0.5))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE CONFIRM CARD - Small green confirmation card with inline approve
// Replaces the big bottom "Onayla" button
// ─────────────────────────────────────────────────────────────────────────────

class InlineConfirmCard extends StatelessWidget {
  final String artist;
  final String songTitle;
  final VoidCallback onConfirm;
  final VoidCallback? onClear;
  final bool isLoading;

  const InlineConfirmCard({
    super.key,
    required this.artist,
    required this.songTitle,
    required this.onConfirm,
    this.onClear,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: BoxDecoration(
          color: ChallengeColors.correct.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ChallengeColors.correct.withValues(alpha:0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: ChallengeColors.correct.withValues(alpha:0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Music icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ChallengeColors.correct.withValues(alpha:0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: ChallengeColors.correct,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    songTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ChallengeColors.darkPurple,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ChallengeColors.darkPurple.withValues(alpha:0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Clear button (optional)
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: ChallengeColors.darkPurple.withValues(alpha:0.5),
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Confirm button
            GestureDetector(
              onTap: isLoading ? null : () {
                HapticService.submit();
                onConfirm();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ChallengeColors.correct,
                      ChallengeColors.correct.withValues(alpha:0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ChallengeColors.correct.withValues(alpha:0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Onayla',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
