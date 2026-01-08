import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// APP CARD SYSTEM - Global Card Design System for Find2Sing
// Elevated, colorful, thematic cards with press animations
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// CARD COLORS & THEME
// ─────────────────────────────────────────────────────────────────────────────

class AppCardColors {
  // Base colors
  static const Color darkPurple = Color(0xFF394272);
  static const Color softPurple = Color(0xFF6C6FA4);
  static const Color primaryPurple = Color(0xFFCAB7FF);
  static const Color lightPurple = Color(0xFFF5F3FF);

  // Challenge type gradients
  static const List<Color> timeRaceGradient = [Color(0xFFFF6B6B), Color(0xFFFF8E53)];
  static const List<Color> relaxGradient = [Color(0xFF4ECDC4), Color(0xFF44CF9C)];
  static const List<Color> realChallengeGradient = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const List<Color> defaultChallengeGradient = [Color(0xFFCAB7FF), Color(0xFFE4DBFF)];

  // Achievement states
  static const List<Color> achievementUnlockedGradient = [Color(0xFFFFD700), Color(0xFFFFA500)];
  static const List<Color> achievementLockedGradient = [Color(0xFFE0E0E0), Color(0xFFF5F5F5)];

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB958);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF2196F3);

  // Stats icon colors
  static const Color statsPurple = Color(0xFF9B7EDE);
  static const Color statsOrange = Color(0xFFFFB958);
  static const Color statsGreen = Color(0xFF4CAF50);
  static const Color statsBlue = Color(0xFF42A5F5);
  static const Color statsPink = Color(0xFFE91E63);
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOW SYSTEM - 3 Levels
// ─────────────────────────────────────────────────────────────────────────────

enum CardElevation { subtle, medium, strong }

class AppCardShadows {
  static List<BoxShadow> getShadow(CardElevation elevation, {Color? color}) {
    final shadowColor = color ?? AppCardColors.darkPurple;

    switch (elevation) {
      case CardElevation.subtle:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case CardElevation.medium:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case CardElevation.strong:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }

  // Glow effect for special cards
  static List<BoxShadow> getGlow(Color color, {double intensity = 0.4}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: intensity * 0.5),
        blurRadius: 40,
        spreadRadius: 4,
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE APP CARD - Reusable card with press animation
// ─────────────────────────────────────────────────────────────────────────────

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final CardElevation elevation;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? border;
  final Color? shadowColor;
  final bool enablePressAnimation;
  final bool enableHaptic;
  final double pressScale;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.elevation = CardElevation.medium,
    this.backgroundColor,
    this.gradient,
    this.border,
    this.shadowColor,
    this.enablePressAnimation = true,
    this.enableHaptic = true,
    this.pressScale = 0.97,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && widget.enablePressAnimation) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHaptic && widget.onTap != null) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = widget.backgroundColor ?? Colors.white.withValues(alpha: 0.92);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enablePressAnimation ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap != null ? _handleTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.gradient == null ? effectiveBackgroundColor : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.border,
            boxShadow: AppCardShadows.getShadow(
              _isPressed ? CardElevation.subtle : widget.elevation,
              color: widget.shadowColor,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHALLENGE CARD - Color-coded challenge type card
// ─────────────────────────────────────────────────────────────────────────────

enum ChallengeCardType { timeRace, relax, realChallenge, standard }

class ChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final ChallengeCardType type;
  final bool isLocked;
  final int? songCount;
  final String? difficulty;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ChallengeCard({
    super.key,
    required this.title,
    this.subtitle = '',
    this.emoji = '🎵',
    this.type = ChallengeCardType.standard,
    this.isLocked = false,
    this.songCount,
    this.difficulty,
    this.onTap,
    this.trailing,
  });

  List<Color> get _gradientColors {
    if (isLocked) {
      return [const Color(0xFFE8E8E8), const Color(0xFFF5F5F5)];
    }
    switch (type) {
      case ChallengeCardType.timeRace:
        return AppCardColors.timeRaceGradient;
      case ChallengeCardType.relax:
        return AppCardColors.relaxGradient;
      case ChallengeCardType.realChallenge:
        return AppCardColors.realChallengeGradient;
      case ChallengeCardType.standard:
        return AppCardColors.defaultChallengeGradient;
    }
  }

  Color get _shadowColor {
    if (isLocked) return Colors.black;
    switch (type) {
      case ChallengeCardType.timeRace:
        return AppCardColors.timeRaceGradient[0];
      case ChallengeCardType.relax:
        return AppCardColors.relaxGradient[0];
      case ChallengeCardType.realChallenge:
        return AppCardColors.realChallengeGradient[0];
      case ChallengeCardType.standard:
        return AppCardColors.primaryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      elevation: isLocked ? CardElevation.subtle : CardElevation.medium,
      shadowColor: _shadowColor,
      child: Row(
        children: [
          // Icon container with gradient
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: _shadowColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock_rounded, size: 24, color: Color(0xFF999999))
                  : Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isLocked ? const Color(0xFF888888) : AppCardColors.darkPurple,
                  ),
                ),
                if (subtitle.isNotEmpty || songCount != null || difficulty != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (songCount != null)
                        _buildChip('$songCount şarkı', type: type, isLocked: isLocked),
                      if (difficulty != null)
                        _buildChip(difficulty!, type: type, isLocked: isLocked),
                      if (subtitle.isNotEmpty)
                        _buildChip(subtitle, type: type, isLocked: isLocked, isHighlight: true),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Trailing or arrow
          trailing ??
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isLocked
                      ? null
                      : LinearGradient(
                          colors: [
                            _gradientColors[0].withValues(alpha: 0.2),
                            _gradientColors[1].withValues(alpha: 0.15),
                          ],
                        ),
                  color: isLocked ? const Color(0xFFF0F0F0) : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: isLocked ? const Color(0xFFCCCCCC) : _shadowColor,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, {
    required ChallengeCardType type,
    required bool isLocked,
    bool isHighlight = false,
  }) {
    Color bgColor;
    Color textColor;

    if (isLocked) {
      bgColor = const Color(0xFFF0F0F0);
      textColor = const Color(0xFF999999);
    } else if (isHighlight) {
      bgColor = AppCardColors.success.withValues(alpha: 0.12);
      textColor = const Color(0xFF2E7D32);
    } else {
      switch (type) {
        case ChallengeCardType.timeRace:
          bgColor = AppCardColors.timeRaceGradient[0].withValues(alpha: 0.1);
          textColor = AppCardColors.timeRaceGradient[0];
        case ChallengeCardType.relax:
          bgColor = AppCardColors.relaxGradient[0].withValues(alpha: 0.1);
          textColor = AppCardColors.relaxGradient[0];
        case ChallengeCardType.realChallenge:
          bgColor = AppCardColors.realChallengeGradient[0].withValues(alpha: 0.1);
          textColor = AppCardColors.realChallengeGradient[0];
        case ChallengeCardType.standard:
          bgColor = AppCardColors.lightPurple;
          textColor = AppCardColors.softPurple;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CARD - Thematic category card
// ─────────────────────────────────────────────────────────────────────────────

class CategoryCard extends StatelessWidget {
  final String title;
  final String emoji;
  final int challengeCount;
  final bool isLocked;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.title,
    this.emoji = '🎵',
    this.challengeCount = 0,
    this.isLocked = false,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        (isLocked
            ? [const Color(0xFFE8E8E8), const Color(0xFFF5F5F5)]
            : AppCardColors.defaultChallengeGradient);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      elevation: isLocked ? CardElevation.subtle : CardElevation.medium,
      shadowColor: isLocked ? null : colors[0],
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: SizedBox(
        width: 120,
        height: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, size: 14, color: Color(0xFF888888)),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isLocked ? const Color(0xFF888888) : AppCardColors.darkPurple,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$challengeCount challenge',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isLocked ? const Color(0xFF999999) : AppCardColors.softPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACHIEVEMENT CARD - Lock/unlock states with progress
// ─────────────────────────────────────────────────────────────────────────────

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final double progress;
  final String? progressText;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.title,
    this.description = '',
    this.emoji = '🏆',
    this.isUnlocked = false,
    this.progress = 0.0,
    this.progressText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      elevation: isUnlocked ? CardElevation.medium : CardElevation.subtle,
      shadowColor: isUnlocked ? AppCardColors.achievementUnlockedGradient[0] : null,
      child: Row(
        children: [
          // Achievement badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnlocked
                    ? AppCardColors.achievementUnlockedGradient
                    : AppCardColors.achievementLockedGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isUnlocked
                  ? AppCardShadows.getGlow(
                      AppCardColors.achievementUnlockedGradient[0],
                      intensity: 0.3,
                    )
                  : null,
            ),
            child: Center(
              child: isUnlocked
                  ? Text(emoji, style: const TextStyle(fontSize: 28))
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppCardColors.darkPurple
                              : const Color(0xFF888888),
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppCardColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 12, color: AppCardColors.success),
                            SizedBox(width: 3),
                            Text(
                              'Kazanıldı',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppCardColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked
                          ? AppCardColors.softPurple
                          : const Color(0xFF999999),
                    ),
                  ),
                ],
                if (!isUnlocked && progress > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppCardColors.warning,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      if (progressText != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          progressText!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppCardColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS CARD - Icon + color paired stat card
// ─────────────────────────────────────────────────────────────────────────────

class StatsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;

  const StatsCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppCardColors.statsPurple,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 12 : 16,
        horizontal: compact ? 12 : 16,
      ),
      elevation: CardElevation.subtle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with colored background
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
            ),
            child: Icon(
              icon,
              color: color,
              size: compact ? 20 : 24,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: AppCardColors.darkPurple,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),

          // Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: AppCardColors.softPurple.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK STATS ROW - Horizontal scrollable stats
// ─────────────────────────────────────────────────────────────────────────────

class QuickStatsRow extends StatelessWidget {
  final List<QuickStatItem> stats;

  const QuickStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return SizedBox(
            width: 80,
            child: StatsCard(
              icon: stat.icon,
              value: stat.value,
              label: stat.label,
              color: stat.color,
              compact: true,
            ),
          );
        },
      ),
    );
  }
}

class QuickStatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const QuickStatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppCardColors.statsPurple,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASSMORPHISM CARD - Frosted glass effect
// ─────────────────────────────────────────────────────────────────────────────

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? tintColor;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.blur = 10,
    this.tintColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tintColor ?? Colors.white).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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

// ─────────────────────────────────────────────────────────────────────────────
// LIST ITEM CARD - Standard list item with press animation
// ─────────────────────────────────────────────────────────────────────────────

class ListItemCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final bool showArrow;

  const ListItemCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      elevation: CardElevation.subtle,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppCardColors.darkPurple,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppCardColors.softPurple.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null && showArrow)
            Icon(
              Icons.chevron_right_rounded,
              color: AppCardColors.softPurple.withValues(alpha: 0.5),
              size: 22,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO CARD - Large featured card
// ─────────────────────────────────────────────────────────────────────────────

class HeroCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final double borderRadius;

  const HeroCard({
    super.key,
    required this.child,
    this.gradientColors = const [Color(0xFFD4C4FF), Color(0xFFEDE7FF)],
    this.onTap,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: borderRadius,
      elevation: CardElevation.strong,
      shadowColor: gradientColors[0],
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
