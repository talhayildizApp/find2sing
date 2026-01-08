import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GLOBAL GAME FEEDBACK SYSTEM
/// Consistent visual & haptic feedback across all game modes
/// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK TYPES & COLORS
// ─────────────────────────────────────────────────────────────────────────────

enum FeedbackType {
  correct,     // Green - correct answer, song added
  wrong,       // Red - wrong answer
  bonus,       // Orange/Gold - special bonus
  freeze,      // Blue/Ice - freeze penalty
  info,        // Purple - neutral info
  warning,     // Orange - time warning
  change,      // Gray - word changed
}

class FeedbackColors {
  static const Color correct = Color(0xFF4CAF50);
  static const Color correctBg = Color(0xFFE8F5E9);
  static const Color wrong = Color(0xFFF85149);
  static const Color wrongBg = Color(0xFFFFEBEE);
  static const Color bonus = Color(0xFFFFB958);
  static const Color bonusBg = Color(0xFFFFF3E0);
  static const Color freeze = Color(0xFF64B5F6);
  static const Color freezeBg = Color(0xFFE3F2FD);
  static const Color info = Color(0xFFCAB7FF);
  static const Color infoBg = Color(0xFFF5F0FF);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningBg = Color(0xFFFFF8E1);
  static const Color change = Color(0xFF9E9E9E);
  static const Color changeBg = Color(0xFFF5F5F5);
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK TOAST - Floating notification
// ─────────────────────────────────────────────────────────────────────────────

class FeedbackToast extends StatefulWidget {
  final String message;
  final FeedbackType type;
  final IconData? icon;
  final VoidCallback? onDismiss;
  final Duration duration;

  const FeedbackToast({
    super.key,
    required this.message,
    required this.type,
    this.icon,
    this.onDismiss,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FeedbackToast> createState() => _FeedbackToastState();
}

class _FeedbackToastState extends State<FeedbackToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case FeedbackType.correct:
        return FeedbackColors.correct;
      case FeedbackType.wrong:
        return FeedbackColors.wrong;
      case FeedbackType.bonus:
        return FeedbackColors.bonus;
      case FeedbackType.freeze:
        return FeedbackColors.freeze;
      case FeedbackType.info:
        return FeedbackColors.info;
      case FeedbackType.warning:
        return FeedbackColors.warning;
      case FeedbackType.change:
        return FeedbackColors.change;
    }
  }

  IconData get _defaultIcon {
    switch (widget.type) {
      case FeedbackType.correct:
        return Icons.check_circle_rounded;
      case FeedbackType.wrong:
        return Icons.cancel_rounded;
      case FeedbackType.bonus:
        return Icons.star_rounded;
      case FeedbackType.freeze:
        return Icons.ac_unit_rounded;
      case FeedbackType.info:
        return Icons.info_rounded;
      case FeedbackType.warning:
        return Icons.warning_rounded;
      case FeedbackType.change:
        return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _backgroundColor.withValues(alpha:0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon ?? _defaultIcon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK BANNER - Inline notification bar
// ─────────────────────────────────────────────────────────────────────────────

class FeedbackBanner extends StatelessWidget {
  final String message;
  final FeedbackType type;
  final IconData? icon;

  const FeedbackBanner({
    super.key,
    required this.message,
    required this.type,
    this.icon,
  });

  Color get _color {
    switch (type) {
      case FeedbackType.correct:
        return FeedbackColors.correct;
      case FeedbackType.wrong:
        return FeedbackColors.wrong;
      case FeedbackType.bonus:
        return FeedbackColors.bonus;
      case FeedbackType.freeze:
        return FeedbackColors.freeze;
      case FeedbackType.info:
        return FeedbackColors.info;
      case FeedbackType.warning:
        return FeedbackColors.warning;
      case FeedbackType.change:
        return FeedbackColors.change;
    }
  }

  Color get _bgColor {
    switch (type) {
      case FeedbackType.correct:
        return FeedbackColors.correctBg;
      case FeedbackType.wrong:
        return FeedbackColors.wrongBg;
      case FeedbackType.bonus:
        return FeedbackColors.bonusBg;
      case FeedbackType.freeze:
        return FeedbackColors.freezeBg;
      case FeedbackType.info:
        return FeedbackColors.infoBg;
      case FeedbackType.warning:
        return FeedbackColors.warningBg;
      case FeedbackType.change:
        return FeedbackColors.changeBg;
    }
  }

  IconData get _defaultIcon {
    switch (type) {
      case FeedbackType.correct:
        return Icons.check_circle_rounded;
      case FeedbackType.wrong:
        return Icons.cancel_rounded;
      case FeedbackType.bonus:
        return Icons.star_rounded;
      case FeedbackType.freeze:
        return Icons.ac_unit_rounded;
      case FeedbackType.info:
        return Icons.info_rounded;
      case FeedbackType.warning:
        return Icons.warning_rounded;
      case FeedbackType.change:
        return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? _defaultIcon, color: _color, size: 20),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              color: _color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORE POP - Animated score change indicator
// ─────────────────────────────────────────────────────────────────────────────

class ScorePop extends StatefulWidget {
  final int delta;
  final VoidCallback? onComplete;

  const ScorePop({
    super.key,
    required this.delta,
    this.onComplete,
  });

  @override
  State<ScorePop> createState() => _ScorePopState();
}

class _ScorePopState extends State<ScorePop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.delta >= 0;
    final color = isPositive ? FeedbackColors.correct : FeedbackColors.wrong;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha:0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${isPositive ? '+' : ''}${widget.delta}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SONG ADDED EFFECT - Mini celebration
// ─────────────────────────────────────────────────────────────────────────────

class SongAddedEffect extends StatefulWidget {
  final VoidCallback? onComplete;

  const SongAddedEffect({super.key, this.onComplete});

  @override
  State<SongAddedEffect> createState() => _SongAddedEffectState();
}

class _SongAddedEffectState extends State<SongAddedEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    HapticService.songAdded();
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FeedbackColors.correct,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FeedbackColors.correct.withValues(alpha:0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.music_note_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FREEZE OVERLAY - Ice effect for wrong answers
// ─────────────────────────────────────────────────────────────────────────────

class FreezeOverlay extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;

  const FreezeOverlay({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FeedbackColors.freezeBg.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: FeedbackColors.freeze.withValues(alpha:0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🥶', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'DONDURULDU',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1976D2),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$secondsLeft saniye',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64B5F6),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 1 - (secondsLeft / totalSeconds),
                  backgroundColor: FeedbackColors.freeze.withValues(alpha:0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1976D2),
                  ),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIME INDICATOR - Prominent animated countdown with gradient and glow
// ─────────────────────────────────────────────────────────────────────────────

class TimeIndicator extends StatelessWidget {
  final int seconds;
  final int totalSeconds;
  final bool showWarning;

  const TimeIndicator({
    super.key,
    required this.seconds,
    required this.totalSeconds,
    this.showWarning = true,
  });

  List<Color> get _gradientColors {
    final ratio = seconds / totalSeconds;
    if (ratio <= 0.2) {
      return [const Color(0xFFF85149), const Color(0xFFD32F2F)];
    }
    if (ratio <= 0.4) {
      return [const Color(0xFFFF9800), const Color(0xFFF57C00)];
    }
    return [Colors.green.shade400, Colors.green.shade600];
  }

  Color get _shadowColor {
    final ratio = seconds / totalSeconds;
    if (ratio <= 0.2) return const Color(0xFFF85149);
    if (ratio <= 0.4) return const Color(0xFFFF9800);
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = seconds <= 30;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isCritical ? 1.05 : 1.0),
      duration: Duration(milliseconds: isCritical ? 500 : 300),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor.withValues(alpha: 0.6),
                  blurRadius: 25,
                  spreadRadius: 6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatTime(seconds),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANGE RIGHT INDICATOR - Shows remaining word change rights
// ─────────────────────────────────────────────────────────────────────────────

class ChangeRightIndicator extends StatelessWidget {
  final int remaining;
  final int total;
  final bool isFree;

  const ChangeRightIndicator({
    super.key,
    required this.remaining,
    required this.total,
    this.isFree = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if total is 0
    if (total == 0 && !isFree) {
      return const SizedBox.shrink();
    }

    final Color mainColor = isFree
        ? FeedbackColors.correct
        : remaining > 0
            ? const Color(0xFF7C6BAF) // Darker purple for better visibility
            : FeedbackColors.wrong;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFree ? Icons.check_circle : Icons.swap_horiz_rounded,
            size: 18,
            color: mainColor,
          ),
          const SizedBox(width: 6),
          Text(
            isFree ? 'Ücretsiz' : '$remaining/$total',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: mainColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS INDICATOR - Challenge mode progress
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeProgressIndicator extends StatelessWidget {
  final int solved;
  final int total;
  final Color? color;

  const ChallengeProgressIndicator({
    super.key,
    required this.solved,
    required this.total,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? solved / total : 0.0;
    final effectiveColor = color ?? const Color(0xFFCAB7FF);
    final isComplete = solved == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: effectiveColor.withValues(alpha:0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? FeedbackColors.correct : effectiveColor,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              if (isComplete)
                const Icon(Icons.check_rounded, color: FeedbackColors.correct, size: 20)
              else
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: effectiveColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$solved / $total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF394272),
                ),
              ),
              Text(
                'şarkı çözüldü',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE - For "Bulduğun Şarkılar" etc.
// ─────────────────────────────────────────────────────────────────────────────

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? hint;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.music_off_rounded,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFCAB7FF),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C6FA4),
            ),
            textAlign: TextAlign.center,
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF6C6FA4).withValues(alpha:0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME INPUT FIELD - Styled text input for games
// ─────────────────────────────────────────────────────────────────────────────

class GameInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final String? prefixEmoji;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final bool enabled;

  const GameInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.prefixEmoji,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        enabled: enabled,
        onSubmitted: (_) => onSubmitted?.call(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF394272),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF6C6FA4).withValues(alpha:0.5),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: prefixEmoji != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(prefixEmoji!, style: const TextStyle(fontSize: 20)),
                )
              : prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Icon(prefixIcon, color: const Color(0xFFCAB7FF), size: 22),
                    )
                  : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFCAB7FF), width: 2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORD CARD - Displays current word with animation
// ─────────────────────────────────────────────────────────────────────────────

class WordCard extends StatelessWidget {
  final String word;
  final Color? color;
  final bool animate;

  const WordCard({
    super.key,
    required this.word,
    this.color,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFCAB7FF);

    return TweenAnimationBuilder<double>(
      key: ValueKey(word),
      tween: Tween(begin: animate ? 0.9 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [effectiveColor, effectiveColor.withValues(alpha:0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha:0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🎯 KELİME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              word.toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
