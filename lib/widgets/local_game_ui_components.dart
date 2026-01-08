import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LOCAL FRIEND GAME UI COMPONENTS - Premium Split Screen Design System
// Symmetrical layout + Dramatic turn indicator + Music themed elements
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLORS
// ─────────────────────────────────────────────────────────────────────────────

class LocalGameColors {
  static const Color primaryPurple = Color(0xFFCAB7FF);
  static const Color darkPurple = Color(0xFF394272);
  static const Color softPurple = Color(0xFFF5F0FF);
  static const Color accentOrange = Color(0xFFFFB958);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF85149);

  // Player specific colors
  static const Color player1Color = Color(0xFFCAB7FF);
  static const Color player1Bg = Color(0xFFF0EBFF);
  static const Color player2Color = Color(0xFFFFB958);
  static const Color player2Bg = Color(0xFFFFF8ED);
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL GAME SCAFFOLD - Cloud background with split screen support
// ─────────────────────────────────────────────────────────────────────────────

class LocalGameScaffold extends StatelessWidget {
  final Widget child;
  final bool showBackground;

  const LocalGameScaffold({
    super.key,
    required this.child,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (showBackground)
            Image.asset(
              'assets/images/bg_music_clouds.png',
              fit: BoxFit.cover,
            ),
          if (showBackground)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                    LocalGameColors.softPurple.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYER CARD - Compact design with score + BULDUM button only
// ─────────────────────────────────────────────────────────────────────────────

class PlayerCard extends StatefulWidget {
  final int playerNumber;
  final int score;
  final int wordChanges;
  final bool isActive;
  final VoidCallback? onFound;
  final bool rotated; // true for player 2 (upside down)

  const PlayerCard({
    super.key,
    required this.playerNumber,
    required this.score,
    required this.wordChanges,
    required this.isActive,
    this.onFound,
    this.rotated = false,
  });

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Player 1: Purple gradient, Player 2: Orange gradient
  List<Color> get _buttonGradient {
    if (widget.playerNumber == 1) {
      return const [
        Color(0xFF9B7EDE), // Light purple
        Color(0xFF8B5CF6), // Purple
        Color(0xFF7C3AED), // Dark purple
      ];
    } else {
      return const [
        Color(0xFFFF6B35), // Vibrant orange
        Color(0xFFFFB958), // Accent orange
        Color(0xFFF59E0B), // Amber
      ];
    }
  }

  Color get _buttonShadowColor {
    return widget.playerNumber == 1
        ? const Color(0xFF8B5CF6)
        : const Color(0xFFFF6B35);
  }

  @override
  Widget build(BuildContext context) {
    final playerColor = widget.playerNumber == 1
        ? LocalGameColors.player1Color
        : LocalGameColors.player2Color;
    final bgColor = widget.playerNumber == 1
        ? LocalGameColors.player1Bg
        : LocalGameColors.player2Bg;

    Widget card = AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity = widget.isActive ? 0.25 + (_pulseController.value * 0.15) : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isActive
                  ? [Colors.white, bgColor.withValues(alpha: 0.8)]
                  : [
                      Colors.white.withValues(alpha: 0.4),
                      bgColor.withValues(alpha: 0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: widget.isActive
                ? Border.all(color: playerColor, width: 2.5)
                : Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: playerColor.withValues(alpha: glowIntensity),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          // Large score display
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score number - big and prominent
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: widget.isActive
                            ? playerColor
                            : Colors.grey.shade400,
                        height: 1,
                      ),
                      child: Text('${widget.score}'),
                    ),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.isActive
                            ? LocalGameColors.darkPurple.withValues(alpha: 0.7)
                            : Colors.grey.shade400,
                      ),
                      child: const Text('şarkı'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Word change indicator - compact
                if (widget.wordChanges > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: widget.isActive
                            ? LocalGameColors.accentOrange
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.wordChanges} kelime',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isActive
                              ? LocalGameColors.darkPurple.withValues(alpha: 0.6)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // BULDUM button - player colored
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: widget.isActive
                ? _buildFoundButton()
                : _buildInactiveIndicator(),
          ),
        ],
      ),
    );

    if (widget.rotated) {
      return Transform.rotate(
        angle: math.pi,
        child: card,
      );
    }
    return card;
  }

  Widget _buildFoundButton() {
    return GestureDetector(
      key: const ValueKey('found_button'),
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onFound?.call();
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.06),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _buttonGradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _buttonShadowColor.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: _buttonShadowColor.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '🎵',
                  style: TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'BULDUM!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInactiveIndicator() {
    return Container(
      key: const ValueKey('inactive_indicator'),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            'Bekle',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CENTER WORD DISPLAY - Sun themed word card with 180° rotation based on turn
// ─────────────────────────────────────────────────────────────────────────────

class CenterWordDisplay extends StatefulWidget {
  final String word;
  final int secondsLeft;
  final int maxSeconds;
  final int currentPlayer;
  final bool canChange;
  final VoidCallback? onChangeWord;
  final int? gameSecondsLeft; // Total game time remaining (optional)
  final bool showGameTimer; // Whether to show game timer

  const CenterWordDisplay({
    super.key,
    required this.word,
    required this.secondsLeft,
    required this.maxSeconds,
    required this.currentPlayer,
    required this.canChange,
    this.onChangeWord,
    this.gameSecondsLeft,
    this.showGameTimer = false,
  });

  @override
  State<CenterWordDisplay> createState() => _CenterWordDisplayState();
}

class _CenterWordDisplayState extends State<CenterWordDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  int _previousPlayer = 1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.secondsLeft <= 5) {
      _pulseController.repeat(reverse: true);
    }

    // Rotation controller for 180° turn animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    ));

    _previousPlayer = widget.currentPlayer;
    // Set initial rotation based on player
    if (widget.currentPlayer == 2) {
      _rotationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CenterWordDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle pulse animation
    if (widget.secondsLeft <= 5 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.secondsLeft > 5 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Handle rotation animation when player changes
    if (widget.currentPlayer != _previousPlayer) {
      _previousPlayer = widget.currentPlayer;
      if (widget.currentPlayer == 2) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = widget.secondsLeft <= 5;
    final progress = widget.secondsLeft / widget.maxSeconds;
    final playerColor = widget.currentPlayer == 1
        ? LocalGameColors.player1Color
        : LocalGameColors.player2Color;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isUrgent ? 1.0 + (_pulseController.value * 0.03) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateZ(_rotationAnimation.value),
            child: child,
          );
        },
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: playerColor.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: isUrgent ? 15 : 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sun background
              Image.asset(
                'assets/images/friend_sun.png',
                width: 280,
                height: 280,
              ),

              // Circular progress
              SizedBox(
                width: 260,
                height: 260,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? LocalGameColors.error : playerColor,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Player turn glow ring
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: playerColor.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
              ),

              // Word display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          playerColor,
                          playerColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: playerColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.currentPlayer == 1
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Oyuncu ${widget.currentPlayer}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Timer - combined word timer and game timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isUrgent
                              ? LocalGameColors.error.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: isUrgent ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Word timer
                        Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: isUrgent ? LocalGameColors.error : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.secondsLeft}s',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isUrgent ? LocalGameColors.error : Colors.orange,
                          ),
                        ),
                        // Game timer (if enabled)
                        if (widget.showGameTimer && widget.gameSecondsLeft != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 16,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.hourglass_bottom_rounded,
                            size: 16,
                            color: LocalGameColors.darkPurple.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatGameTime(widget.gameSecondsLeft!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: LocalGameColors.darkPurple.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Word
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.word.toUpperCase(),
                      style: TextStyle(
                        fontSize: _fontSizeForWord(widget.word),
                        fontWeight: FontWeight.w900,
                        color: LocalGameColors.darkPurple,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          const Shadow(
                            color: Colors.white,
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Change button
                  if (widget.canChange)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onChangeWord?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              Colors.white.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: LocalGameColors.accentOrange.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: LocalGameColors.accentOrange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: LocalGameColors.accentOrange,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Değiştir',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: LocalGameColors.accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Turn direction arrows (left and right) - positioned outside circle
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildTurnArrow(
                    isActive: widget.currentPlayer == 2,
                    pointsUp: true, // Points up to player 2
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildTurnArrow(
                    isActive: widget.currentPlayer == 1,
                    pointsUp: false, // Points down to player 1
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurnArrow({required bool isActive, required bool pointsUp}) {
    final playerColor = isActive
        ? (pointsUp ? LocalGameColors.player2Color : LocalGameColors.player1Color)
        : Colors.grey.shade300;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? playerColor : Colors.grey.shade300,
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? playerColor.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isActive ? 12 : 6,
            spreadRadius: isActive ? 2 : 0,
          ),
        ],
      ),
      child: Icon(
        pointsUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        color: isActive ? playerColor : Colors.grey.shade400,
        size: 22,
      ),
    );
  }

  double _fontSizeForWord(String word) {
    final len = word.replaceAll(' ', '').length;
    if (len <= 4) return 34;
    if (len <= 7) return 30;
    if (len <= 10) return 26;
    return 22;
  }

  String _formatGameTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TURN ARROW INDICATOR - Animated arrow showing whose turn
// ─────────────────────────────────────────────────────────────────────────────

class TurnArrowIndicator extends StatefulWidget {
  final int playerNumber;
  final bool pointingUp;

  const TurnArrowIndicator({
    super.key,
    required this.playerNumber,
    required this.pointingUp,
  });

  @override
  State<TurnArrowIndicator> createState() => _TurnArrowIndicatorState();
}

class _TurnArrowIndicatorState extends State<TurnArrowIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.playerNumber == 1
        ? LocalGameColors.player1Color
        : LocalGameColors.player2Color;

    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final offset = _bounceController.value * 8;
        return Transform.translate(
          offset: Offset(0, widget.pointingUp ? -offset : offset),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          widget.pointingUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME TIMER BAR - Floating timer for time-based games
// ─────────────────────────────────────────────────────────────────────────────

class GameTimerBar extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;

  const GameTimerBar({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = secondsLeft / totalSeconds;
    final isUrgent = progress <= 0.2;
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_rounded,
            size: 20,
            color: isUrgent ? LocalGameColors.error : LocalGameColors.darkPurple,
          ),
          const SizedBox(width: 10),
          Text(
            'Oyun Süresi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LocalGameColors.darkPurple.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUrgent
                  ? LocalGameColors.error.withValues(alpha: 0.1)
                  : LocalGameColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$minutes:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isUrgent ? LocalGameColors.error : LocalGameColors.darkPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM ACTION BAR - Menu and finish buttons
// ─────────────────────────────────────────────────────────────────────────────

class BottomActionBar extends StatelessWidget {
  final VoidCallback? onMenu;
  final VoidCallback? onFinish;

  const BottomActionBar({
    super.key,
    this.onMenu,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.home_rounded,
              label: 'Ana Menü',
              onTap: onMenu,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.flag_rounded,
              label: 'Bitir',
              onTap: onFinish,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [LocalGameColors.accentOrange, Color(0xFFFFCE54)],
                )
              : null,
          color: isPrimary ? null : LocalGameColors.darkPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? LocalGameColors.accentOrange.withValues(alpha: 0.4)
                  : LocalGameColors.darkPurple.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
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
// SETTINGS OPTION CHIP - Modern chip for settings selection
// ─────────────────────────────────────────────────────────────────────────────

class SettingsOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const SettingsOptionChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [LocalGameColors.primaryPurple, Color(0xFF9B7EDE)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? null
              : Border.all(color: LocalGameColors.primaryPurple.withValues(alpha: 0.3)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LocalGameColors.primaryPurple.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : LocalGameColors.darkPurple,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : LocalGameColors.darkPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS CARD - Color-coded glass morphism card for settings
// ─────────────────────────────────────────────────────────────────────────────

class SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;

  const SettingsCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? LocalGameColors.primaryPurple;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: LocalGameColors.darkPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM SEGMENTED BUTTON - Modern segmented control
// ─────────────────────────────────────────────────────────────────────────────

class CustomSegmentedButton extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  const CustomSegmentedButton({
    super.key,
    required this.segments,
    required this.selectedIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LocalGameColors.softPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged?.call(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    segments[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? LocalGameColors.darkPurple
                          : LocalGameColors.darkPurple.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
