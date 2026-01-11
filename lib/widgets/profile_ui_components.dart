import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE UI COMPONENTS - Dynamic & Modern Profile Design System
// Hero stats + Quick stats grid + Achievements with progress + Recent activity
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────────────────────────────────────

class ProfileColors {
  static const Color primaryPurple = Color(0xFFCAB7FF);
  static const Color darkPurple = Color(0xFF394272);
  static const Color softPurple = Color(0xFFF5F0FF);
  static const Color accentOrange = Color(0xFFFFB958);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF85149);
  static const Color subtleText = Color(0xFF6C6FA4);
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE SCAFFOLD - Cloud background
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScaffold extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final String title;

  const ProfileScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.onSettings,
    this.title = 'Profilim',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                  ProfileColors.softPurple.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onBack != null) {
                onBack!();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: ProfileColors.darkPurple,
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ProfileColors.darkPurple,
            ),
          ),
          const Spacer(),
          // Settings button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSettings?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings_rounded,
                size: 18,
                color: ProfileColors.darkPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT PROFILE HEADER - Avatar + Name + Edit in one row
// ─────────────────────────────────────────────────────────────────────────────

class CompactProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final bool isPremium;
  final VoidCallback? onEditTap;

  const CompactProfileHeader({
    super.key,
    this.photoUrl,
    required this.displayName,
    required this.email,
    this.isPremium = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [ProfileColors.primaryPurple, Color(0xFF9B7EDE)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ProfileColors.primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ProfileColors.darkPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ProfileColors.darkPurple,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: ProfileColors.darkPurple.withValues(alpha: 0.6),
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

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT PLAYER ID CARD - Inline with copy/share
// ─────────────────────────────────────────────────────────────────────────────

class CompactPlayerIdCard extends StatefulWidget {
  final String? playerId;
  final bool isLoading;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const CompactPlayerIdCard({
    super.key,
    this.playerId,
    this.isLoading = false,
    this.onCopy,
    this.onShare,
  });

  @override
  State<CompactPlayerIdCard> createState() => _CompactPlayerIdCardState();
}

class _CompactPlayerIdCardState extends State<CompactPlayerIdCard> {
  bool _copied = false;

  void _handleCopy() {
    widget.onCopy?.call();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2D44), Color(0xFF1A1A2E)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ProfileColors.primaryPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: ProfileColors.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Oyuncu ID',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                widget.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ProfileColors.primaryPurple,
                        ),
                      )
                    : Text(
                        widget.playerId ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                onTap: _handleCopy,
                isActive: _copied,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.share_rounded,
                onTap: widget.onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? ProfileColors.success.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? ProfileColors.success : Colors.white70,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO STAT CARD - Spotlight single stat with animation
// ─────────────────────────────────────────────────────────────────────────────

class HeroStatCard extends StatefulWidget {
  final List<HeroStatData> stats;
  final Duration cycleDuration;

  const HeroStatCard({
    super.key,
    required this.stats,
    this.cycleDuration = const Duration(seconds: 4),
  });

  @override
  State<HeroStatCard> createState() => _HeroStatCardState();
}

class HeroStatData {
  final String label;
  final String value;
  final String emoji;
  final Color color;
  final String? subtitle;

  const HeroStatData({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
    this.subtitle,
  });
}

class _HeroStatCardState extends State<HeroStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    if (widget.stats.length > 1) {
      _startCycling();
    }
  }

  void _startCycling() {
    _timer = Timer.periodic(widget.cycleDuration, (_) {
      if (mounted) {
        _controller.reverse().then((_) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.stats.length;
          });
          _controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stats.isEmpty) return const SizedBox.shrink();

    final stat = widget.stats[_currentIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                stat.color.withValues(alpha: 0.15),
                stat.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: stat.color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: stat.color.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Emoji with glow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: stat.color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  stat.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(height: 16),
              // Value
              Text(
                stat.value,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: ProfileColors.darkPurple,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: stat.color.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                stat.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ProfileColors.darkPurple.withValues(alpha: 0.7),
                ),
              ),
              if (stat.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  stat.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: stat.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              // Dots indicator
              if (widget.stats.length > 1) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.stats.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? stat.color
                            : stat.color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK STATS GRID - 2x2 compact metrics
// ─────────────────────────────────────────────────────────────────────────────

class QuickStatsGrid extends StatelessWidget {
  final List<QuickStatItem> stats;

  const QuickStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: stats.map((stat) => _QuickStatCard(stat: stat)).toList(),
      ),
    );
  }
}

class QuickStatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final String? badge;

  const QuickStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isHighlighted = false,
    this.badge,
  });
}

class _QuickStatCard extends StatelessWidget {
  final QuickStatItem stat;

  const _QuickStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final isHighlighted = stat.isHighlighted;
    final hasTap = stat.onTap != null;

    return GestureDetector(
      onTap: hasTap
          ? () {
              HapticFeedback.lightImpact();
              stat.onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHighlighted
              ? stat.color.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted
              ? Border.all(color: stat.color.withValues(alpha: 0.4), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? stat.color.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isHighlighted ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stat.color.withValues(alpha: isHighlighted ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        stat.icon,
                        size: 18,
                        color: stat.color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isHighlighted ? stat.color : ProfileColors.darkPurple,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isHighlighted
                              ? stat.color.withValues(alpha: 0.8)
                              : ProfileColors.darkPurple.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    if (hasTap)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: stat.color.withValues(alpha: 0.6),
                      ),
                  ],
                ),
              ],
            ),
            // Badge (e.g., "Joker" label)
            if (stat.badge != null)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [stat.color, stat.color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: stat.color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    stat.badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
// ACHIEVEMENTS SECTION - Progress bars + unlock animations
// ─────────────────────────────────────────────────────────────────────────────

class AchievementsSection extends StatelessWidget {
  final List<AchievementData> achievements;

  const AchievementsSection({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ProfileColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 20,
                  color: ProfileColors.accentGold,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Başarılar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ProfileColors.darkPurple,
                ),
              ),
              const Spacer(),
              Text(
                '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ProfileColors.darkPurple.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...achievements.map((achievement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AchievementCard(achievement: achievement),
              )),
        ],
      ),
    );
  }
}

class AchievementData {
  final String emoji;
  final String title;
  final String description;
  final double progress; // 0.0 to 1.0
  final bool isUnlocked;
  final Color color;

  const AchievementData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.progress,
    required this.isUnlocked,
    this.color = ProfileColors.primaryPurple,
  });
}

class _AchievementCard extends StatelessWidget {
  final AchievementData achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Emoji with glow if unlocked
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: achievement.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 22,
                  color: achievement.isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: achievement.isUnlocked
                              ? ProfileColors.darkPurple
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (achievement.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ProfileColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: ProfileColors.success,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Kazanıldı',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ProfileColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: achievement.isUnlocked
                        ? ProfileColors.darkPurple.withValues(alpha: 0.6)
                        : Colors.grey.shade400,
                  ),
                ),
                if (!achievement.isUnlocked && achievement.progress > 0) ...[
                  const SizedBox(height: 8),
                  // Progress bar
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: achievement.progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                achievement.color,
                                achievement.color.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(achievement.progress * 100).toInt()}% tamamlandı',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: achievement.color,
                    ),
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
// RECENT ACTIVITY SECTION - Last matches with "See All"
// ─────────────────────────────────────────────────────────────────────────────

class RecentActivitySection extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final VoidCallback? onSeeAll;

  const RecentActivitySection({
    super.key,
    required this.activities,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 48,
              color: ProfileColors.subtleText,
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz oyun oynamadın',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ProfileColors.darkPurple.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'İlk oyununu oyna ve aktivitelerini burada gör!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ProfileColors.darkPurple.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ProfileColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: ProfileColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Son Aktiviteler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ProfileColors.darkPurple,
                ),
              ),
              const Spacer(),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ProfileColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Tümü',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ProfileColors.primaryPurple,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.take(5).map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentActivityCard(activity: activity),
              )),
        ],
      ),
    );
  }
}

class RecentActivityItem {
  final String gameType;
  final String result;
  final int score;
  final DateTime date;
  final bool isWin;

  const RecentActivityItem({
    required this.gameType,
    required this.result,
    required this.score,
    required this.date,
    required this.isWin,
  });
}

class _RecentActivityCard extends StatelessWidget {
  final RecentActivityItem activity;

  const _RecentActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: activity.isWin
            ? ProfileColors.success.withValues(alpha: 0.08)
            : ProfileColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activity.isWin
              ? ProfileColors.success.withValues(alpha: 0.2)
              : ProfileColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Game icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                activity.isWin ? '🎵' : '💔',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.gameType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ProfileColors.darkPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.result,
                  style: TextStyle(
                    fontSize: 12,
                    color: ProfileColors.darkPurple.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Score & time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activity.isWin
                      ? ProfileColors.success.withValues(alpha: 0.15)
                      : ProfileColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${activity.score}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        activity.isWin ? ProfileColors.success : ProfileColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(activity.date),
                style: TextStyle(
                  fontSize: 10,
                  color: ProfileColors.darkPurple.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return '${date.day}/${date.month}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE ACTION BUTTON - Logout etc.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isDestructive;

  const ProfileActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.color = ProfileColors.primaryPurple,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive ? ProfileColors.error : color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGGERED ANIMATION WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
