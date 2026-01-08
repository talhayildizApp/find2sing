import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_room_model.dart';
import '../../models/match_intent_model.dart';
import '../../models/challenge_model.dart';
import '../online/online_match_screen.dart';

/// Online Challenge Result Screen - Competitive VS Layout
/// - Split-screen mentality: Sen vs Rakip
/// - Mode-specific theming
/// - Winner celebration / Loser consolation / Draw
/// - Rematch option
class ChallengeOnlineResultScreen extends StatefulWidget {
  final GameRoomModel room;
  final String myUid;
  final ChallengeModel? challenge;

  const ChallengeOnlineResultScreen({
    super.key,
    required this.room,
    required this.myUid,
    this.challenge,
  });

  @override
  State<ChallengeOnlineResultScreen> createState() =>
      _ChallengeOnlineResultScreenState();
}

class _ChallengeOnlineResultScreenState
    extends State<ChallengeOnlineResultScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _cardsController;
  late AnimationController _buttonsController;

  late Animation<double> _heroScale;
  late Animation<double> _cardsSlide;
  late Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _playEntryAnimations();
  }

  void _initAnimations() {
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut),
    );

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardsSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardsController, curve: Curves.easeOutCubic),
    );

    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _buttonsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeIn),
    );
  }

  void _playEntryAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _heroController.forward();
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 400));
    _cardsController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _buttonsController.forward();

    // Extra celebration for winner
    if (_isWinner) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardsController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  // Getters
  RoomPlayer? get _myPlayer => widget.room.players[widget.myUid];
  String get _opponentUid =>
      widget.room.players.keys.firstWhere((uid) => uid != widget.myUid,
          orElse: () => '');
  RoomPlayer? get _opponentPlayer =>
      _opponentUid.isNotEmpty ? widget.room.players[_opponentUid] : null;

  int get _myScore => _myPlayer?.score ?? 0;
  int get _opponentScore => _opponentPlayer?.score ?? 0;

  bool get _isWinner => _myScore > _opponentScore;
  bool get _isLoser => _myScore < _opponentScore;
  bool get _isDraw => _myScore == _opponentScore;

  // Mode-specific colors
  Color get _primaryColor {
    switch (widget.room.modeVariant) {
      case ModeVariant.timeRace:
        return const Color(0xFFFF6B6B);
      case ModeVariant.relax:
        return const Color(0xFF66BB6A);
      case ModeVariant.real:
        return const Color(0xFF7C4DFF);
      default:
        return const Color(0xFFCAB7FF);
    }
  }

  Color get _secondaryColor {
    switch (widget.room.modeVariant) {
      case ModeVariant.timeRace:
        return const Color(0xFFFFB74D);
      case ModeVariant.relax:
        return const Color(0xFF81C784);
      case ModeVariant.real:
        return const Color(0xFFB388FF);
      default:
        return const Color(0xFFE0D4FF);
    }
  }


  String get _modeLabel {
    switch (widget.room.modeVariant) {
      case ModeVariant.timeRace:
        return 'TIME RACE';
      case ModeVariant.relax:
        return 'RELAX';
      case ModeVariant.real:
        return 'REAL CHALLENGE';
      default:
        return 'ONLINE';
    }
  }

  IconData get _modeIcon {
    switch (widget.room.modeVariant) {
      case ModeVariant.timeRace:
        return Icons.flash_on_rounded;
      case ModeVariant.relax:
        return Icons.self_improvement_rounded;
      case ModeVariant.real:
        return Icons.emoji_events_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cloud background
          _buildCloudBackground(),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildModeBadge(),
                    const SizedBox(height: 24),
                    _buildHeroSection(),
                    const SizedBox(height: 32),
                    _buildVSSection(),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cloud image
        Image.asset(
          'assets/images/bg_music_clouds.png',
          fit: BoxFit.cover,
        ),
        // Color overlay based on result
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isWinner
                  ? [
                      const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      const Color(0xFFE8F5E9).withValues(alpha: 0.85),
                      const Color(0xFFE8F5E9).withValues(alpha: 0.95),
                    ]
                  : _isLoser
                      ? [
                          const Color(0xFFF85149).withValues(alpha: 0.15),
                          const Color(0xFFFFEBEE).withValues(alpha: 0.85),
                          const Color(0xFFFFEBEE).withValues(alpha: 0.95),
                        ]
                      : [
                          const Color(0xFFFFB958).withValues(alpha: 0.15),
                          const Color(0xFFFFF8E1).withValues(alpha: 0.85),
                          const Color(0xFFFFF8E1).withValues(alpha: 0.95),
                        ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_modeIcon, color: _primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(
            _modeLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _heroScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _heroScale.value,
          child: child,
        );
      },
      child: Column(
        children: [
          // Result badge
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isWinner
                    ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                    : _isLoser
                        ? [const Color(0xFFF85149), const Color(0xFFFF7B6B)]
                        : [const Color(0xFFFFB958), const Color(0xFFFFCE54)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isWinner
                          ? const Color(0xFF4CAF50)
                          : _isLoser
                              ? const Color(0xFFF85149)
                              : const Color(0xFFFFB958))
                      .withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _isWinner
                    ? '🏆'
                    : _isLoser
                        ? '😔'
                        : '🤝',
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Result title
          Text(
            _isWinner
                ? 'Kazandin!'
                : _isLoser
                    ? 'Kaybettin'
                    : 'Berabere!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _isWinner
                  ? const Color(0xFF4CAF50)
                  : _isLoser
                      ? const Color(0xFFF85149)
                      : const Color(0xFFFFB958),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isWinner
                ? 'Tebrikler, rakibini yendin!'
                : _isLoser
                    ? 'Bir dahaki sefere!'
                    : 'Cok yakin bir mac oldu!',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF6B7280).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVSSection() {
    return AnimatedBuilder(
      animation: _cardsSlide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardsSlide.value),
          child: Opacity(
            opacity: 1 - (_cardsSlide.value / 60),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // My card
            Expanded(
              child: _buildPlayerResultCard(
                name: 'Sen',
                score: _myScore,
                isWinner: _isWinner,
                isMe: true,
              ),
            ),
            // VS divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            // Opponent card
            Expanded(
              child: _buildPlayerResultCard(
                name: _opponentPlayer?.name ?? 'Rakip',
                score: _opponentScore,
                isWinner: _isLoser,
                isMe: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerResultCard({
    required String name,
    required int score,
    required bool isWinner,
    required bool isMe,
  }) {
    final cardColor = isWinner
        ? const Color(0xFF4CAF50)
        : isMe
            ? _primaryColor
            : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner
            ? const Color(0xFFE8F5E9)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: isWinner
            ? Border.all(color: const Color(0xFF4CAF50), width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Winner crown
          if (isWinner)
            const Text('👑', style: TextStyle(fontSize: 24)),
          if (isWinner) const SizedBox(height: 8),
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: cardColor.withValues(alpha: 0.2),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142).withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Score
          Text(
            '$score',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: cardColor,
            ),
          ),
          Text(
            'puan',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6B7280).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return AnimatedBuilder(
      animation: _cardsSlide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardsSlide.value * 0.5),
          child: Opacity(
            opacity: 1 - (_cardsSlide.value / 120),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_modeIcon, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Mac Istatistikleri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  icon: Icons.music_note_rounded,
                  value: '${(_myPlayer?.solvedCount ?? 0) + (_opponentPlayer?.solvedCount ?? 0)}',
                  label: 'Toplam Sarki',
                  color: _primaryColor,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xFFE0E0E0),
                ),
                _buildStatColumn(
                  icon: Icons.sync_rounded,
                  value: '${widget.room.roundIndex + 1}',
                  label: 'Round',
                  color: const Color(0xFF6B7280),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: const Color(0xFFE0E0E0),
                ),
                _buildStatColumn(
                  icon: Icons.compare_arrows_rounded,
                  value: '${(_myScore - _opponentScore).abs()}',
                  label: 'Puan Farki',
                  color: _isWinner
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF85149),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
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
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _buttonsFade,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonsFade.value,
          child: child,
        );
      },
      child: Column(
        children: [
          // Primary CTA - Rematch
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.replay_rounded, size: 24),
              label: const Text(
                'Rovans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // Use challenge.id if available, otherwise use room.challengeId
                final challengeId = widget.challenge?.id ?? widget.room.challengeId;
                if (challengeId != null) {
                  // Go directly to waiting screen for rematch with same mode
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OnlineMatchScreen(
                        mode: MatchMode.challengeOnline,
                        challengeId: challengeId,
                        modeVariant: widget.room.modeVariant,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary CTA - Main Menu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D3142),
                side: BorderSide(color: Colors.grey[300]!, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Ana Menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
