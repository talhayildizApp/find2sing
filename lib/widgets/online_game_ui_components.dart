import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ONLINE GAME UI COMPONENTS - Music Themed Design System
// Cloud background + Vinyl/Cassette cards + Playlist style lists + Ticket scores
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────────────────────────────────────

class OnlineGameColors {
  static const Color primaryPurple = Color(0xFFCAB7FF);
  static const Color darkPurple = Color(0xFF394272);
  static const Color softPurple = Color(0xFFF5F0FF);
  static const Color accentOrange = Color(0xFFFFB958);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF85149);
  static const Color vinylBlack = Color(0xFF1A1A2E);
  static const Color goldAccent = Color(0xFFFFD700);
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOUD BACKGROUND SCAFFOLD - Consistent with auth/home screens
// ─────────────────────────────────────────────────────────────────────────────

class OnlineGameScaffold extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;
  final String? title;
  final Widget? titleWidget;

  const OnlineGameScaffold({
    super.key,
    required this.child,
    this.showBackButton = true,
    this.onBack,
    this.trailing,
    this.title,
    this.titleWidget,
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
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                  OnlineGameColors.softPurple.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                if (showBackButton || title != null || titleWidget != null || trailing != null)
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
          if (showBackButton)
            GestureDetector(
              onTap: () {
                HapticService.tap();
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: OnlineGameColors.darkPurple,
                  size: 22,
                ),
              ),
            ),
          if (showBackButton) const SizedBox(width: 12),
          Expanded(
            child: titleWidget ??
                (title != null
                    ? Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: OnlineGameColors.darkPurple,
                        ),
                      )
                    : const SizedBox.shrink()),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VINYL RECORD WORD CARD - Music themed word display
// ─────────────────────────────────────────────────────────────────────────────

class VinylWordCard extends StatefulWidget {
  final String word;
  final bool isMyTurn;
  final bool animate;
  final Color? accentColor;
  final int? wordSecondsLeft;
  final int? wordTotalSeconds;

  const VinylWordCard({
    super.key,
    required this.word,
    this.isMyTurn = false,
    this.animate = true,
    this.accentColor,
    this.wordSecondsLeft,
    this.wordTotalSeconds,
  });

  @override
  State<VinylWordCard> createState() => _VinylWordCardState();
}

class _VinylWordCardState extends State<VinylWordCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.animate && widget.isMyTurn) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(VinylWordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMyTurn && widget.animate) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? OnlineGameColors.primaryPurple;
    final hasTimer = widget.wordSecondsLeft != null && widget.wordTotalSeconds != null;

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.word),
      tween: Tween(begin: widget.animate ? 0.9 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: 240,
        height: 280, // Extra height for timer badge
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl record container
            Positioned(
              bottom: 0,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vinyl record - outer ring (rotating)
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              OnlineGameColors.vinylBlack,
                              OnlineGameColors.vinylBlack.withValues(alpha: 0.9),
                              const Color(0xFF2D2D44),
                              OnlineGameColors.vinylBlack,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                        child: CustomPaint(
                          painter: VinylGroovesPainter(
                            grooveColor: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),

                    // Center label (colorful) - just the word, no label
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.85),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        // Word - auto-sized to fit within the circle
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.word.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Shine effect - vinyl reflection
                    Positioned(
                      top: 20,
                      left: 30,
                      child: Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Inner ring detail for authentic vinyl look
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Word timer badge on top of vinyl (like single player)
            if (hasTimer)
              Positioned(
                top: 0,
                child: _buildWordTimerBadge(
                  widget.wordSecondsLeft!,
                  widget.wordTotalSeconds!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordTimerBadge(int secondsLeft, int totalSeconds) {
    final isCritical = secondsLeft <= 5;
    final isUrgent = secondsLeft <= 10;

    Color timerColor;
    Color bgColor;
    if (isCritical) {
      timerColor = Colors.white;
      bgColor = const Color(0xFFF85149);
    } else if (isUrgent) {
      timerColor = Colors.white;
      bgColor = const Color(0xFFFF9800);
    } else {
      timerColor = const Color(0xFF394272);
      bgColor = Colors.white;
    }

    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final timeText = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isCritical ? 1.15 : 1.0),
      duration: Duration(milliseconds: isCritical ? 300 : 150),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isCritical
                      ? bgColor.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.15),
                  blurRadius: isCritical ? 12 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 18,
                  color: timerColor,
                ),
                const SizedBox(width: 6),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: timerColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VinylGroovesPainter extends CustomPainter {
  final Color grooveColor;

  VinylGroovesPainter({required this.grooveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = grooveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw concentric grooves
    for (double r = 55; r < size.width / 2 - 10; r += 3) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CASSETTE TAPE SCORE CARD - Concert ticket style
// ─────────────────────────────────────────────────────────────────────────────

class ConcertTicketScoreCard extends StatelessWidget {
  final String playerName;
  final int score;
  final bool isMe;
  final bool isActive;
  final Color? accentColor;

  const ConcertTicketScoreCard({
    super.key,
    required this.playerName,
    required this.score,
    this.isMe = false,
    this.isActive = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ??
        (isMe ? OnlineGameColors.primaryPurple : OnlineGameColors.accentOrange);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: color, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isActive ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ticket stub effect
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: OnlineGameColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: OnlineGameColors.success.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              Text(
                isMe ? '🎤 Sen' : '🎸 $playerName',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Score with ticket styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [color, color.withValues(alpha: 0.8)]
                    : [Colors.grey.shade100, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : OnlineGameColors.darkPurple,
              ),
            ),
          ),

          // Perforated edge effect
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST STYLE SONG LIST - Music playlist UI
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistSongItem extends StatelessWidget {
  final String songTitle;
  final String artistName;
  final String word;
  final bool isAccepted;
  final bool isMyRound;
  final int? index;

  const PlaylistSongItem({
    super.key,
    required this.songTitle,
    required this.artistName,
    required this.word,
    required this.isAccepted,
    this.isMyRound = false,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Compact card design for horizontal scroll
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAccepted
              ? [
                  const Color(0xFFE8F5E9),
                  Colors.white,
                ]
              : [
                  const Color(0xFFFFEBEE),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAccepted
              ? OnlineGameColors.success.withValues(alpha: 0.3)
              : OnlineGameColors.error.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Status icon + Word badge
          Row(
            children: [
              // Status icon (compact)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: isAccepted
                        ? [OnlineGameColors.success, OnlineGameColors.success.withValues(alpha: 0.8)]
                        : [OnlineGameColors.error, OnlineGameColors.error.withValues(alpha: 0.8)],
                  ),
                ),
                child: Icon(
                  isAccepted ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              // Word badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: OnlineGameColors.primaryPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    word.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: OnlineGameColors.primaryPurple,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Song title
          Text(
            songTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: OnlineGameColors.darkPurple,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Artist
          Text(
            artistName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: OnlineGameColors.darkPurple.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE FEEDBACK WIDGET - Replaces dialogs
// ─────────────────────────────────────────────────────────────────────────────

class InlineFeedbackBanner extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback? onDismiss;

  const InlineFeedbackBanner({
    super.key,
    required this.message,
    required this.isSuccess,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? OnlineGameColors.success : OnlineGameColors.error;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (isSuccess) ...[
              const SizedBox(width: 8),
              const Text('🎵', style: TextStyle(fontSize: 18)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKSTAGE PASS INVITE CARD - For invite code display
// ─────────────────────────────────────────────────────────────────────────────

class BackstagePassCard extends StatelessWidget {
  final String code;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final bool copied;

  const BackstagePassCard({
    super.key,
    required this.code,
    this.onCopy,
    this.onShare,
    this.copied = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF2D2D44),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: OnlineGameColors.goldAccent.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: OnlineGameColors.goldAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  OnlineGameColors.goldAccent,
                  OnlineGameColors.goldAccent.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎫', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'BACKSTAGE PASS',
                  style: TextStyle(
                    color: OnlineGameColors.vinylBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: copied ? Icons.check_rounded : Icons.copy_rounded,
                label: copied ? 'Kopyalandı!' : 'Kopyala',
                onTap: onCopy,
                isHighlighted: copied,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'Paylaş',
                onTap: onShare,
                isPrimary: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withValues(alpha: 0.5),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Bu kodu arkadaşına gönder',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    OnlineGameColors.goldAccent,
                    OnlineGameColors.goldAccent.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isPrimary
              ? null
              : isHighlighted
                  ? OnlineGameColors.success.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? OnlineGameColors.vinylBlack : Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? OnlineGameColors.vinylBlack : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MUSIC BOX WAITING INDICATOR - Animated waiting state
// ─────────────────────────────────────────────────────────────────────────────

class MusicBoxWaitingIndicator extends StatefulWidget {
  final String? message;
  final Color? color;

  const MusicBoxWaitingIndicator({
    super.key,
    this.message,
    this.color,
  });

  @override
  State<MusicBoxWaitingIndicator> createState() =>
      _MusicBoxWaitingIndicatorState();
}

class _MusicBoxWaitingIndicatorState extends State<MusicBoxWaitingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late List<Animation<double>> _noteAnimations;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _noteAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? OnlineGameColors.primaryPurple;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.2),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        children: List.generate(3, (index) {
                          final angle = (index * 120) * math.pi / 180;
                          return Positioned(
                            left: 70 + 55 * math.cos(angle) - 8,
                            top: 70 + 55 * math.sin(angle) - 8,
                            child: AnimatedBuilder(
                              animation: _noteAnimations[index],
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.5 + _noteAnimations[index].value * 0.5,
                                  child: Text(
                                    ['🎵', '🎶', '🎼'][index],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),

              // Center music box
              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + _bounceController.value * 0.08,
                    child: child,
                  );
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎵', style: TextStyle(fontSize: 36)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 20),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: OnlineGameColors.darkPurple,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW COUNTDOWN TIMER - Dramatic countdown
// ─────────────────────────────────────────────────────────────────────────────

class ReviewCountdownTimer extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final bool isUrgent;

  const ReviewCountdownTimer({
    super.key,
    required this.secondsLeft,
    this.totalSeconds = 5,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = secondsLeft / totalSeconds;
    final color = isUrgent ? OnlineGameColors.error : OnlineGameColors.accentOrange;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isUrgent ? 1.1 : 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: isUrgent ? 24 : 16,
              spreadRadius: isUrgent ? 4 : 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            SizedBox(
              width: 76,
              height: 76,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // Number
            Text(
              '$secondsLeft',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TURN INDICATOR BANNER - Shows whose turn it is
// ─────────────────────────────────────────────────────────────────────────────

class TurnIndicatorBanner extends StatelessWidget {
  final bool isMyTurn;
  final String? opponentName;

  const TurnIndicatorBanner({
    super.key,
    required this.isMyTurn,
    this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: isMyTurn
            ? const LinearGradient(
                colors: [
                  OnlineGameColors.primaryPurple,
                  Color(0xFF9B7EDE),
                ],
              )
            : null,
        color: isMyTurn ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMyTurn
            ? null
            : Border.all(color: OnlineGameColors.accentOrange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: isMyTurn
                ? OnlineGameColors.primaryPurple.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMyTurn) ...[
            const Text('🎯', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            const Text(
              'Senin Sıran!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ] else ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: OnlineGameColors.accentOrange,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${opponentName ?? "Rakip"} düşünüyor...',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: OnlineGameColors.accentOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS INPUT FIELD - Frosted glass style input
// ─────────────────────────────────────────────────────────────────────────────

class GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const GlassInputField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: OnlineGameColors.darkPurple,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: OnlineGameColors.darkPurple.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: OnlineGameColors.darkPurple.withValues(alpha: 0.3),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: OnlineGameColors.primaryPurple)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: OnlineGameColors.primaryPurple,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM CTA BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class OnlineGameCTAButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const OnlineGameCTAButton({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? OnlineGameColors.darkPurple;
    final isActive = enabled && !isLoading;

    return GestureDetector(
      onTap: isActive
          ? () {
              HapticService.submit();
              onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [effectiveColor, effectiveColor.withValues(alpha: 0.85)],
                )
              : null,
          color: isActive ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.4),
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
                    strokeWidth: 2.5,
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
