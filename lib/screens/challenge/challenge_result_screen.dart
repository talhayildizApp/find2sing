import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/challenge_model.dart';
import '../../services/leaderboard_service.dart';
import 'challenge_mode_select_screen.dart';
import 'challenge_detail_screen.dart';
import 'leaderboard_screen.dart';

/// Challenge Result Screen with Cloudy Theme + Mode-specific overlays
///
/// Features:
/// - Bulutlu background (bg_music_clouds.png)
/// - Mode-specific color overlay (orange/green/purple gradient)
/// - Floating music decorations
/// - Glassmorphism cards
/// - Hero badge with double shadow (color + white glow)
class ChallengeResultScreen extends StatefulWidget {
  final ChallengeModel challenge;
  final ChallengeSingleMode mode;
  final List<ChallengeSongModel> solvedSongs;
  final int totalSongs;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int durationSeconds;
  final bool timedOut;
  final bool isOnline;
  final String? opponentName;
  final int? opponentScore;

  const ChallengeResultScreen({
    super.key,
    required this.challenge,
    required this.mode,
    required this.solvedSongs,
    required this.totalSongs,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    required this.durationSeconds,
    this.timedOut = false,
    this.isOnline = false,
    this.opponentName,
    this.opponentScore,
  });

  @override
  State<ChallengeResultScreen> createState() => _ChallengeResultScreenState();
}

class _ChallengeResultScreenState extends State<ChallengeResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _statsController;
  late AnimationController _leaderboardController;
  late AnimationController _floatingController;

  late Animation<double> _celebrationScale;
  late Animation<double> _statsSlide;
  late Animation<double> _leaderboardFade;

  bool _leaderboardSaved = false;
  bool _savingLeaderboard = false;
  int? _leaderboardRank;
  bool _songsExpanded = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _playEntryAnimation();

    if (widget.mode == ChallengeSingleMode.real && !widget.isOnline) {
      _saveToLeaderboard();
    }
  }

  void _initAnimations() {
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _statsSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic),
    );

    _leaderboardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _leaderboardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leaderboardController, curve: Curves.easeIn),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _playEntryAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _celebrationController.forward();
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 400));
    _statsController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _leaderboardController.forward();
  }

  Future<void> _saveToLeaderboard() async {
    setState(() => _savingLeaderboard = true);

    try {
      final service = LeaderboardService();
      final rank = await service.submitScore(
        challengeId: widget.challenge.id,
        score: widget.score,
        timeSeconds: widget.durationSeconds,
      );

      if (mounted) {
        setState(() {
          _leaderboardSaved = true;
          _savingLeaderboard = false;
          _leaderboardRank = rank;
        });

        if (rank != null && rank <= 10) {
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingLeaderboard = false);
      }
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _statsController.dispose();
    _leaderboardController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // Mode-specific colors
  Color get _primaryColor {
    switch (widget.mode) {
      case ChallengeSingleMode.timeRace:
        return const Color(0xFFFF9500); // Orange
      case ChallengeSingleMode.relax:
        return const Color(0xFF4CAF50); // Green
      case ChallengeSingleMode.real:
        return const Color(0xFF7C4DFF); // Purple
    }
  }

  IconData get _modeIcon {
    switch (widget.mode) {
      case ChallengeSingleMode.timeRace:
        return Icons.flash_on_rounded;
      case ChallengeSingleMode.relax:
        return Icons.self_improvement_rounded;
      case ChallengeSingleMode.real:
        return Icons.emoji_events_rounded;
    }
  }

  String get _badgeLabel {
    switch (widget.mode) {
      case ChallengeSingleMode.timeRace:
        return 'Hızlı!';
      case ChallengeSingleMode.relax:
        return 'Rahat';
      case ChallengeSingleMode.real:
        return _getScoreBadge();
    }
  }

  String _getScoreBadge() {
    final percentage = widget.totalSongs > 0
        ? (widget.correctCount / widget.totalSongs * 100)
        : 0;
    if (percentage >= 80) return 'Mükemmel!';
    if (percentage >= 60) return 'Harika!';
    return 'İyi!';
  }

  bool get _isCompleted =>
      widget.solvedSongs.length == widget.totalSongs && !widget.timedOut;
  bool get _isWinner =>
      widget.isOnline &&
      widget.opponentScore != null &&
      widget.score > widget.opponentScore!;
  bool get _isLoser =>
      widget.isOnline &&
      widget.opponentScore != null &&
      widget.score < widget.opponentScore!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. CLOUDY BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_music_clouds.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. MODE-SPECIFIC COLOR OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withValues(alpha: 0.15),
                    _primaryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          // 3. FLOATING MUSIC DECORATIONS
          ..._buildMusicDecorations(),

          // 4. MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeroBadge(),
                  const SizedBox(height: 24),
                  _buildTitle(),
                  const SizedBox(height: 12),
                  _buildCategoryBadge(),
                  const SizedBox(height: 32),
                  _buildPrimaryStatCard(),
                  const SizedBox(height: 20),
                  if (widget.mode == ChallengeSingleMode.real && !widget.isOnline)
                    _buildLeaderboardFeedback(),
                  if (widget.isOnline && widget.mode == ChallengeSingleMode.real)
                    _buildOnlineResult(),
                  if (widget.solvedSongs.isNotEmpty) _buildSongsList(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMusicDecorations() {
    return [
      // Treble clef - top left
      Positioned(
        top: 100,
        left: 30,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 10 * _floatingController.value),
              child: child,
            );
          },
          child: Opacity(
            opacity: 0.15,
            child: Icon(
              Icons.music_note_rounded,
              size: 80,
              color: _primaryColor,
            ),
          ),
        ),
      ),

      // Music note - top right
      Positioned(
        top: 150,
        right: 40,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -8 * _floatingController.value),
              child: child,
            );
          },
          child: Opacity(
            opacity: 0.12,
            child: Icon(
              Icons.music_note_rounded,
              size: 60,
              color: _primaryColor,
            ),
          ),
        ),
      ),

      // Small notes - bottom left
      Positioned(
        bottom: 200,
        left: 50,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(5 * _floatingController.value, 0),
              child: child,
            );
          },
          child: Opacity(
            opacity: 0.1,
            child: Icon(
              Icons.music_note_rounded,
              size: 40,
              color: _primaryColor,
            ),
          ),
        ),
      ),

      // Small notes - bottom right
      Positioned(
        bottom: 300,
        right: 60,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-5 * _floatingController.value, 5 * _floatingController.value),
              child: child,
            );
          },
          child: Opacity(
            opacity: 0.08,
            child: Icon(
              Icons.music_note_rounded,
              size: 50,
              color: _primaryColor,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildHeroBadge() {
    return AnimatedBuilder(
      animation: _celebrationScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _celebrationScale.value,
          child: child,
        );
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [_primaryColor.withValues(alpha: 0.9), _primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            // Mode color glow
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
            // White glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 60,
              spreadRadius: 20,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(_modeIcon, color: Colors.white, size: 80),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  _badgeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    String title;
    if (widget.isOnline) {
      if (_isWinner) {
        title = 'Kazandın!';
      } else if (_isLoser) {
        title = 'Kaybettin';
      } else {
        title = 'Berabere!';
      }
    } else if (_isCompleted) {
      title = 'Tamamlandı!';
    } else if (widget.timedOut) {
      title = 'Süre Doldu!';
    } else {
      title = 'İyi Gidiyorsun!';
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF2D3142),
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        widget.challenge.title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  Widget _buildPrimaryStatCard() {
    return AnimatedBuilder(
      animation: _statsSlide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _statsSlide.value),
          child: Opacity(
            opacity: 1 - (_statsSlide.value / 50),
            child: child,
          ),
        );
      },
      child: _buildModeSpecificStatCard(),
    );
  }

  Widget _buildModeSpecificStatCard() {
    switch (widget.mode) {
      case ChallengeSingleMode.timeRace:
        return _buildTimeRaceCard();
      case ChallengeSingleMode.relax:
        return _buildRelaxCard();
      case ChallengeSingleMode.real:
        return _buildRealChallengeCard();
    }
  }

  // TIME RACE - Orange theme, time as primary
  Widget _buildTimeRaceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.timer_rounded, color: _primaryColor, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Tamamlama Süresi',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: widget.durationSeconds),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Text(
                _formatTime(value),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSecondaryStats(),
        ],
      ),
    );
  }

  // RELAX - Green theme, song count as primary
  Widget _buildRelaxCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: widget.correctCount),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Text(
                '$value',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor,
                ),
              );
            },
          ),
          const Text(
            'Şarkı Bildin',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded, color: _primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                _formatTime(widget.durationSeconds),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // REAL CHALLENGE - Purple theme, score as primary with gradient
  Widget _buildRealChallengeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF536DFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'PUAN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          // Score with single star
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: widget.score),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star_rounded,
                    size: 40,
                    color: Color(0xFFFFD700),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWhiteStatItem(
                icon: Icons.check_circle_rounded,
                value: '${widget.correctCount}',
                label: 'Doğru',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildWhiteStatItem(
                icon: Icons.cancel_rounded,
                value: '${widget.wrongCount}',
                label: 'Yanlış',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.check_circle_rounded,
          value: '${widget.correctCount}/${widget.totalSongs}',
          label: 'Doğru',
          color: const Color(0xFF4CAF50),
        ),
        Container(
          width: 1,
          height: 40,
          color: const Color(0xFFE0E0E0),
        ),
        _buildStatItem(
          icon: Icons.music_note_rounded,
          value: '${widget.totalSongs}',
          label: 'Şarkı',
          color: const Color(0xFF7C4DFF),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardFeedback() {
    // Don't show empty container
    if (!_savingLeaderboard && !_leaderboardSaved) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _leaderboardFade,
      builder: (context, child) {
        return Opacity(
          opacity: _leaderboardFade.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _leaderboardRank != null && _leaderboardRank! <= 10
              ? const LinearGradient(
                  colors: [Color(0xFFFFB958), Color(0xFFFFCE54)],
                )
              : null,
          color: _leaderboardRank == null || _leaderboardRank! > 10
              ? Colors.white.withValues(alpha: 0.95)
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _leaderboardRank != null && _leaderboardRank! <= 10
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          children: [
            if (_savingLeaderboard) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFCAB7FF)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Skor kaydediliyor...',
                style: TextStyle(color: Color(0xFF6C6FA4)),
              ),
            ] else if (_leaderboardSaved) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: _leaderboardRank != null && _leaderboardRank! <= 10
                        ? Colors.white
                        : const Color(0xFFFFB958),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _leaderboardRank != null && _leaderboardRank! <= 10
                            ? 'Top 10\'a Girdin!'
                            : 'Skor Kaydedildi!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color:
                              _leaderboardRank != null && _leaderboardRank! <= 10
                                  ? Colors.white
                                  : const Color(0xFF394272),
                        ),
                      ),
                      if (_leaderboardRank != null)
                        Text(
                          'Sıralama: #$_leaderboardRank',
                          style: TextStyle(
                            fontSize: 13,
                            color: _leaderboardRank! <= 10
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF6C6FA4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LeaderboardScreen(challenge: widget.challenge),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.leaderboard_rounded,
                    color: _leaderboardRank != null && _leaderboardRank! <= 10
                        ? Colors.white
                        : const Color(0xFFFFB958),
                  ),
                  label: Text(
                    'Liderlik Tablosu',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _leaderboardRank != null && _leaderboardRank! <= 10
                          ? Colors.white
                          : const Color(0xFFFFB958),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _leaderboardRank != null && _leaderboardRank! <= 10
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFFFFB958),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineResult() {
    if (widget.opponentName == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const Text('Sen',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6C6FA4))),
              Text(
                '${widget.score}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _isWinner ? const Color(0xFF4CAF50) : _primaryColor,
                ),
              ),
            ],
          ),
          Text(
            'VS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6C6FA4).withValues(alpha: 0.5),
            ),
          ),
          Column(
            children: [
              Text(widget.opponentName!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6C6FA4))),
              Text(
                '${widget.opponentScore}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _isLoser
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFB958),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _songsExpanded = !_songsExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.music_note_rounded, color: _primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Bulduğun Şarkılar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.solvedSongs.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _songsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          if (_songsExpanded)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.solvedSongs.length,
              itemBuilder: (context, index) {
                final song = widget.solvedSongs[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle,
                      color: Color(0xFF4CAF50), size: 20),
                  title: Text(song.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle:
                      Text(song.artist, style: const TextStyle(fontSize: 12)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary CTA
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _primaryColor.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            icon: Icon(
              widget.isOnline ? Icons.replay_rounded : Icons.play_arrow_rounded,
              size: 24,
            ),
            label: Text(
              widget.isOnline ? 'Rövanş' : 'Tekrar Oyna',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (widget.isOnline) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChallengeDetailScreen(challenge: widget.challenge),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChallengeModeSelectScreen(challenge: widget.challenge),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary CTA
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: OutlinedButton(
            child: const Text(
              'Ana Menü',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2D3142),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
