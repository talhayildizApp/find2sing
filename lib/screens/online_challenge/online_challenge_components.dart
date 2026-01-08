import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/match_intent_model.dart';
import '../../widgets/challenge_ui_components.dart';
import '../../services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ONLINE CHALLENGE COMPONENTS
// Uses the app's existing design system from challenge_ui_components.dart
// ═══════════════════════════════════════════════════════════════════════════

// Re-export ChallengeColors for convenience
export '../../widgets/challenge_ui_components.dart' show ChallengeColors;

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE MODE THEME
// ─────────────────────────────────────────────────────────────────────────────

class OnlineModeTheme {
  final String name;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;

  const OnlineModeTheme({
    required this.name,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
  });

  static OnlineModeTheme forMode(ModeVariant? mode) {
    switch (mode) {
      case ModeVariant.timeRace:
        return const OnlineModeTheme(
          name: 'Time Race',
          emoji: '⚡',
          primaryColor: ChallengeColors.timeRace,
          secondaryColor: Color(0xFFFF8A80),
        );
      case ModeVariant.relax:
        return const OnlineModeTheme(
          name: 'Relax',
          emoji: '🧘',
          primaryColor: ChallengeColors.relax,
          secondaryColor: Color(0xFF81C784),
        );
      case ModeVariant.real:
        return const OnlineModeTheme(
          name: 'Real Challenge',
          emoji: '🏆',
          primaryColor: ChallengeColors.realChallenge,
          secondaryColor: Color(0xFFFFCC80),
        );
      default:
        return const OnlineModeTheme(
          name: 'Online',
          emoji: '🎮',
          primaryColor: ChallengeColors.primaryPurple,
          secondaryColor: Color(0xFFD1C4E9),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE GAME SCAFFOLD
// Cloud background + gradient overlay consistent with app design
// ─────────────────────────────────────────────────────────────────────────────

class OnlineGameScaffold extends StatelessWidget {
  final Widget child;
  final ModeVariant? mode;

  const OnlineGameScaffold({
    super.key,
    required this.child,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OnlineModeTheme.forMode(mode);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cloud background
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          // Mode-tinted gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.1),
                  ChallengeColors.softPurple.withValues(alpha: 0.3),
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
// ONLINE HEADER BAR
// Back button + Mode pill + Timer pill
// ─────────────────────────────────────────────────────────────────────────────

class OnlineHeaderBar extends StatelessWidget {
  final ModeVariant? mode;
  final VoidCallback onClose;
  final String timerText;
  final bool isUrgent;
  final bool isCritical;

  const OnlineHeaderBar({
    super.key,
    required this.mode,
    required this.onClose,
    required this.timerText,
    this.isUrgent = false,
    this.isCritical = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OnlineModeTheme.forMode(mode);
    final timerColor = isCritical
        ? ChallengeColors.wrong
        : isUrgent
            ? ChallengeColors.realChallenge
            : theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticService.tap();
              onClose();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: ChallengeColors.darkPurple,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Mode pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  theme.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Timer pill
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: isCritical ? 1.1 : 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isCritical ? timerColor : timerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCritical ? timerColor : timerColor.withValues(alpha: 0.4),
                ),
                boxShadow: isCritical
                    ? [
                        BoxShadow(
                          color: timerColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
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
                  const SizedBox(width: 6),
                  Text(
                    timerText,
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE SCOREBOARD
// Sen vs Rakip - horizontal card with turn indicator
// ─────────────────────────────────────────────────────────────────────────────

class OnlineScoreboard extends StatelessWidget {
  final String myName;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final bool isMyTurn;
  final ModeVariant? mode;
  final String scoreLabel;
  final int currentRound;
  final int totalRounds;

  const OnlineScoreboard({
    super.key,
    required this.myName,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.isMyTurn,
    this.mode,
    this.scoreLabel = 'Çözülen',
    this.currentRound = 1,
    this.totalRounds = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OnlineModeTheme.forMode(mode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // My score
          Expanded(
            child: _PlayerScoreCard(
              name: 'Sen',
              displayName: myName,
              score: myScore,
              isActive: isMyTurn,
              color: ChallengeColors.primaryPurple,
              scoreLabel: scoreLabel,
            ),
          ),

          // VS divider + Round info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
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
                const SizedBox(height: 6),
                Text(
                  'Tur $currentRound/$totalRounds',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ChallengeColors.darkPurple.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Opponent score
          Expanded(
            child: _PlayerScoreCard(
              name: opponentName,
              displayName: opponentName,
              score: opponentScore,
              isActive: !isMyTurn,
              color: theme.primaryColor,
              scoreLabel: scoreLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final String name;
  final String displayName;
  final int score;
  final bool isActive;
  final Color color;
  final String scoreLabel;

  const _PlayerScoreCard({
    required this.name,
    required this.displayName,
    required this.score,
    required this.isActive,
    required this.color,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: isActive
          ? BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
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
                  decoration: const BoxDecoration(
                    color: ChallengeColors.correct,
                    shape: BoxShape.circle,
                  ),
                ),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: ChallengeColors.darkPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isActive ? color : ChallengeColors.darkPurple,
            ),
          ),
          Text(
            scoreLabel,
            style: TextStyle(
              fontSize: 10,
              color: ChallengeColors.darkPurple.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE WORD DISPLAY
// Uses the sun image like single player game
// ─────────────────────────────────────────────────────────────────────────────

class OnlineWordDisplay extends StatelessWidget {
  final String word;
  final ModeVariant? mode;
  final int? timerSeconds;
  final int? totalSeconds;

  const OnlineWordDisplay({
    super.key,
    required this.word,
    this.mode,
    this.timerSeconds,
    this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    // Use WordHeroCard from challenge_ui_components
    return WordHeroCard(
      word: word,
      timerSeconds: timerSeconds,
      totalSeconds: totalSeconds,
      animate: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE SELECTION CARD
// Artist + Song selection with inline confirm
// ─────────────────────────────────────────────────────────────────────────────

class OnlineSelectionCard extends StatelessWidget {
  final String? selectedArtist;
  final String? selectedSong;
  final bool enabled;
  final VoidCallback? onArtistTap;
  final VoidCallback? onSongTap;
  final VoidCallback? onSubmit;
  final VoidCallback? onClear;
  final bool isSubmitting;
  final ModeVariant? mode;

  const OnlineSelectionCard({
    super.key,
    this.selectedArtist,
    this.selectedSong,
    this.enabled = true,
    this.onArtistTap,
    this.onSongTap,
    this.onSubmit,
    this.onClear,
    this.isSubmitting = false,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedArtist != null && selectedSong != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Selection row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFF8F0FF).withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Artist picker
                Expanded(
                  child: _OnlinePickerButton(
                    emoji: '🎤',
                    label: 'Sanatçı',
                    value: selectedArtist,
                    enabled: enabled,
                    onTap: onArtistTap,
                  ),
                ),
                const SizedBox(width: 12),
                // Song picker
                Expanded(
                  child: _OnlinePickerButton(
                    emoji: '🎵',
                    label: 'Şarkı',
                    value: selectedSong,
                    enabled: enabled && selectedArtist != null,
                    onTap: onSongTap,
                  ),
                ),
              ],
            ),
          ),

          // Confirmation bar (when both selected)
          if (hasSelection) ...[
            const SizedBox(height: 12),
            InlineConfirmCard(
              artist: selectedArtist!,
              songTitle: selectedSong!,
              onConfirm: onSubmit ?? () {},
              onClear: onClear,
              isLoading: isSubmitting,
            ),
          ],
        ],
      ),
    );
  }
}

class _OnlinePickerButton extends StatefulWidget {
  final String emoji;
  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback? onTap;

  const _OnlinePickerButton({
    required this.emoji,
    required this.label,
    this.value,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<_OnlinePickerButton> createState() => _OnlinePickerButtonState();
}

class _OnlinePickerButtonState extends State<_OnlinePickerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.isNotEmpty;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled
          ? () {
              HapticService.tap();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasValue
                  ? ChallengeColors.primaryPurple.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValue
                    ? ChallengeColors.primaryPurple.withValues(alpha: 0.4)
                    : Colors.grey.shade200,
                width: hasValue ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: hasValue
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: ChallengeColors.darkPurple,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Text(
                          '${widget.label} Seç',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ChallengeColors.darkPurple.withValues(alpha: 0.6),
                          ),
                        ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasValue
                      ? ChallengeColors.primaryPurple
                      : Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPPONENT TURN OVERLAY
// Full screen blur overlay when opponent is playing
// ─────────────────────────────────────────────────────────────────────────────

class OpponentTurnOverlay extends StatefulWidget {
  final String opponentName;
  final ModeVariant? mode;

  const OpponentTurnOverlay({
    super.key,
    required this.opponentName,
    this.mode,
  });

  @override
  State<OpponentTurnOverlay> createState() => _OpponentTurnOverlayState();
}

class _OpponentTurnOverlayState extends State<OpponentTurnOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OnlineModeTheme.forMode(widget.mode);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.white.withValues(alpha: 0.7),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing avatar
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.secondaryColor,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.opponentName.isNotEmpty
                              ? widget.opponentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status text
                  const Text(
                    'Sıra Rakipte',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ChallengeColors.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.opponentName} düşünüyor...',
                    style: TextStyle(
                      fontSize: 15,
                      color: ChallengeColors.darkPurple.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Loading indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(theme.primaryColor),
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
// FREEZE OVERLAY
// Uses existing ChallengeFreezeOverlay style
// ─────────────────────────────────────────────────────────────────────────────

class OnlineFreezeOverlay extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;

  const OnlineFreezeOverlay({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return ChallengeFreezeOverlay(
      secondsLeft: secondsRemaining,
      totalSeconds: totalSeconds,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEEDBACK TOAST
// Correct / Wrong feedback
// ─────────────────────────────────────────────────────────────────────────────

class OnlineFeedbackToast extends StatelessWidget {
  final String message;
  final bool isCorrect;
  final String? bonus;
  final bool isVisible;

  const OnlineFeedbackToast({
    super.key,
    required this.message,
    required this.isCorrect,
    this.bonus,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return ChallengeFeedbackToast(
      message: message,
      isCorrect: isCorrect,
      bonus: bonus,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BONUS INDICATORS
// Steal bonus, Comeback bonus
// ─────────────────────────────────────────────────────────────────────────────

class StealBonusToast extends StatelessWidget {
  final bool isVisible;
  final String message;

  const StealBonusToast({
    super.key,
    required this.isVisible,
    this.message = 'Çaldın! +2',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ChallengeColors.realChallenge, Color(0xFFFFCC80)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: ChallengeColors.realChallenge.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComebackBonusIndicator extends StatefulWidget {
  final int multiplier;
  final bool isVisible;

  const ComebackBonusIndicator({
    super.key,
    required this.multiplier,
    required this.isVisible,
  });

  @override
  State<ComebackBonusIndicator> createState() => _ComebackBonusIndicatorState();
}

class _ComebackBonusIndicatorState extends State<ComebackBonusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ChallengeColors.timeRace, ChallengeColors.realChallenge],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ChallengeColors.timeRace.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'x${widget.multiplier}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'BONUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RULES REMINDER CARD
// For Real Challenge mode - shows point rules
// ─────────────────────────────────────────────────────────────────────────────

class RulesReminderCard extends StatelessWidget {
  const RulesReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ChallengeColors.realChallenge.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RuleChip(
            icon: Icons.check_circle_rounded,
            text: '+1',
            color: ChallengeColors.correct,
          ),
          _RuleChip(
            icon: Icons.cancel_rounded,
            text: '-3',
            color: ChallengeColors.wrong,
          ),
          _RuleChip(
            icon: Icons.sports_handball_rounded,
            text: '+2 Çal',
            color: ChallengeColors.realChallenge,
          ),
        ],
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _RuleChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXIT CONFIRMATION DIALOG
// ─────────────────────────────────────────────────────────────────────────────

Future<bool> showOnlineExitConfirmation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ChallengeColors.wrong.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.exit_to_app_rounded,
              color: ChallengeColors.wrong,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Çıkmak istiyor musun?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ChallengeColors.darkPurple,
            ),
          ),
        ],
      ),
      content: Text(
        'Oyundan çıkarsan maçı kaybedersin.',
        style: TextStyle(
          fontSize: 15,
          color: ChallengeColors.darkPurple.withValues(alpha: 0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Devam Et',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ChallengeColors.primaryPurple,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: ChallengeColors.wrong),
          child: const Text(
            'Çık',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TURN BANNER
// Shows "Senin Sıran" or "Rakip Oynuyor"
// ─────────────────────────────────────────────────────────────────────────────

class OnlineTurnBanner extends StatelessWidget {
  final bool isMyTurn;
  final String? opponentName;
  final ModeVariant? mode;

  const OnlineTurnBanner({
    super.key,
    required this.isMyTurn,
    this.opponentName,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OnlineModeTheme.forMode(mode);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: isMyTurn
            ? LinearGradient(
                colors: [theme.primaryColor, theme.secondaryColor],
              )
            : null,
        color: isMyTurn ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMyTurn
            ? null
            : Border.all(color: ChallengeColors.realChallenge.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: isMyTurn
                ? theme.primaryColor.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SENİN SIRAN',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Sanatçı ve şarkı seç',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
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
              style: const TextStyle(
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
