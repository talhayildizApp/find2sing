import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import '../../models/match_intent_model.dart';
import '../online/online_match_screen.dart';

/// Game-focused online mode selection matching single-player design
/// Soft gradients, mood tags, and quick decision UX
class ChallengeOnlineModeSelectScreen extends StatefulWidget {
  final ChallengeModel challenge;

  const ChallengeOnlineModeSelectScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeOnlineModeSelectScreen> createState() => _ChallengeOnlineModeSelectScreenState();
}

class _ChallengeOnlineModeSelectScreenState extends State<ChallengeOnlineModeSelectScreen>
    with SingleTickerProviderStateMixin {
  ModeVariant? _selectedMode;
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
                        const SizedBox(height: 16),

                        // Live match banner - soft and visible
                        _buildLiveMatchBanner(),

                        const SizedBox(height: 24),

                        // Primary mode - recommended
                        _buildGameModeCard(
                          mode: ModeVariant.timeRace,
                          emoji: '⚡',
                          title: 'Time Race',
                          moodTag: 'HIZLI',
                          moodColor: const Color(0xFFF85149),
                          tagline: '5 dakikada yarışı kazan',
                          rules: ['5 dk süre', 'Yanlış = 3sn freeze', 'Sıralı turlar'],
                          gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
                          isPrimary: true,
                        ),

                        const SizedBox(height: 12),

                        // Secondary modes
                        _buildGameModeCard(
                          mode: ModeVariant.relax,
                          emoji: '🎯',
                          title: 'Relax',
                          moodTag: 'RAHAT',
                          moodColor: const Color(0xFF4CAF50),
                          tagline: 'Sakin tempoda yarış',
                          rules: ['30sn / kelime', 'Yanlış = 1sn', 'Comeback x2/x3'],
                          gradient: [const Color(0xFF66BB6A), const Color(0xFF81C784)],
                          isPrimary: false,
                        ),

                        const SizedBox(height: 12),

                        _buildGameModeCard(
                          mode: ModeVariant.real,
                          emoji: '⚔️',
                          title: 'Real Challenge',
                          moodTag: 'REKABETÇİ',
                          moodColor: const Color(0xFFFFB958),
                          tagline: 'Risk al, puan kazan!',
                          rules: ['Doğru +1', 'Yanlış -3', 'Çal bonusu +2'],
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
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF394272).withValues(alpha: 0.08),
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
              'Online Yarış',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'CANLI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4CAF50),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394272).withValues(alpha: 0.06),
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

  Widget _buildLiveMatchBanner() {
    // Info-style banner - not clickable, just informational
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Very subtle background - more like an info section
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small info icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF58A6FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.people_alt_rounded,
                color: Color(0xFF58A6FF),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with online badge
                Row(
                  children: [
                    Text(
                      'Canlı Yarış',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF394272).withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF58A6FF), Color(0xFF7C4DFF)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ONLINE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Description - subtle text
                Text(
                  'Arkadaşınla eş zamanlı oyna, sırayla tahmin et ve yarışı kazan!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF394272).withValues(alpha: 0.6),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                // Feature chips - smaller and more subtle
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildFeatureChip('👥 2 Kişi'),
                    _buildFeatureChip('⏱️ Sıralı Tur'),
                    _buildFeatureChip('🏆 Gerçek Zamanlı'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF58A6FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF58A6FF).withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required ModeVariant mode,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.95),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF58A6FF), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF58A6FF).withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _continueToMatch,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Rakip Bul',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('⚔️', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _continueToMatch() {
    if (_selectedMode == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineMatchScreen(
          mode: MatchMode.challengeOnline,
          challengeId: widget.challenge.id,
          modeVariant: _selectedMode,
        ),
      ),
    );
  }
}
