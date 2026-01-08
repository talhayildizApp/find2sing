import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import 'challenge_game_screen.dart';

/// Game-focused single-player mode selection with mood tags and quick decision UX
class ChallengeModeSelectScreen extends StatefulWidget {
  final ChallengeModel challenge;

  const ChallengeModeSelectScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeModeSelectScreen> createState() => _ChallengeModeSelectScreenState();
}

class _ChallengeModeSelectScreenState extends State<ChallengeModeSelectScreen>
    with SingleTickerProviderStateMixin {
  ChallengeSingleMode? _selectedMode;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildChallengeInfo(),
                        const SizedBox(height: 24),
                        
                        // Primary mode - recommended
                        _buildGameModeCard(
                          mode: ChallengeSingleMode.timeRace,
                          emoji: '⚡',
                          title: 'Time Race',
                          moodTag: 'HIZLI',
                          moodColor: const Color(0xFFF85149),
                          tagline: '5 dakikada tümünü bul',
                          rules: ['5 dk süre', 'Yanlış = 3sn freeze', 'Hız önemli'],
                          gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
                          isPrimary: true,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Secondary modes
                        _buildGameModeCard(
                          mode: ChallengeSingleMode.relax,
                          emoji: '🧘',
                          title: 'Relax',
                          moodTag: 'RAHAT',
                          moodColor: const Color(0xFF4CAF50),
                          tagline: 'Acele yok, keyfine bak',
                          rules: ['30sn / soru', 'Sakin tempo', 'Toplam süre'],
                          gradient: [const Color(0xFF66BB6A), const Color(0xFF81C784)],
                          isPrimary: false,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildGameModeCard(
                          mode: ChallengeSingleMode.real,
                          emoji: '🏆',
                          title: 'Real Challenge',
                          moodTag: 'REKABETÇİ',
                          moodColor: const Color(0xFFFFB958),
                          tagline: 'Liderboard\'a adını yaz',
                          rules: ['Doğru +1', 'Yanlış -3', 'Global skor'],
                          gradient: [const Color(0xFFFFB958), const Color(0xFFFFCE54)],
                          isPrimary: false,
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky CTA
          if (_selectedMode != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyCTA(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF394272).withValues(alpha:0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF394272),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Nasıl Oynayacaksın?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394272).withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCAB7FF), Color(0xFFE0D6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                widget.challenge.type == ChallengeType.artist ? '🎤' : '🎵',
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.challenge.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip('${widget.challenge.totalSongs} şarkı'),
                    const SizedBox(width: 6),
                    _buildInfoChip(widget.challenge.difficultyLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6C6FA4),
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required ChallengeSingleMode mode,
    required String emoji,
    required String title,
    required String moodTag,
    required Color moodColor,
    required String tagline,
    required List<String> rules,
    required List<Color> gradient,
    required bool isPrimary,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.0 : (isPrimary ? 0.98 : 0.97)),
        decoration: BoxDecoration(
          // Gradient like SolvedSongsCard: white → light mode color → lighter accent
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    const Color(0xFFFFFFFE),
                    Color.lerp(Colors.white, gradient[0], 0.08)!,
                    Color.lerp(Colors.white, gradient[1], 0.10)!,
                  ]
                : [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.88),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? gradient[0].withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.6),
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
        child: Padding(
          padding: EdgeInsets.all(isPrimary ? 18 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Emoji icon - seçiliyken daha belirgin
                          Container(
                            width: isPrimary ? 48 : 42,
                            height: isPrimary ? 48 : 42,
                            decoration: BoxDecoration(
                              color: gradient[0].withValues(alpha: isSelected ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: gradient[0].withValues(alpha: 0.3),
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: TextStyle(fontSize: isPrimary ? 24 : 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Title and tagline
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: isPrimary ? 19 : 17,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? gradient[0] : const Color(0xFF394272),
                                      ),
                                    ),
                                    if (isPrimary && !isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'ÖNERİLEN',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF7C4DFF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  tagline,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? gradient[0].withValues(alpha: 0.8)
                                        : const Color(0xFF6C6FA4).withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Mood tag badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: moodColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              moodTag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rules chips - always mode color tint
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: rules.map((rule) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: gradient[0].withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rule,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: gradient[0],
                            ),
                          ),
                        )).toList(),
                      ),
                      // Selection indicator
                      if (isSelected) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: gradient[0],
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Seçildi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: gradient[0],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildStickyCTA() {
    final modeConfig = _getModeConfig(_selectedMode!);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha:0.0),
            Colors.white.withValues(alpha:0.95),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.5],
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: double.infinity,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: modeConfig['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (modeConfig['gradient'] as List<Color>)[0].withValues(alpha:0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _startGame,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      modeConfig['emoji'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      modeConfig['cta'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getModeConfig(ChallengeSingleMode mode) {
    switch (mode) {
      case ChallengeSingleMode.timeRace:
        return {
          'emoji': '⚡',
          'cta': 'Yarışa Başla!',
          'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
        };
      case ChallengeSingleMode.relax:
        return {
          'emoji': '🧘',
          'cta': 'Rahat Oyna',
          'gradient': [const Color(0xFF66BB6A), const Color(0xFF81C784)],
        };
      case ChallengeSingleMode.real:
        return {
          'emoji': '🏆',
          'cta': 'Rekor Kır!',
          'gradient': [const Color(0xFFFFB958), const Color(0xFFFFCE54)],
        };
    }
  }

  void _startGame() {
    if (_selectedMode == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeGameScreen(
          challenge: widget.challenge,
          singleMode: _selectedMode!,
        ),
      ),
    );
  }
}
