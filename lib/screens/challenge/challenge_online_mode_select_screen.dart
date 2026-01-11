import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import '../../models/match_intent_model.dart';
import '../online/online_match_screen.dart';

/// Game-focused online mode selection with dynamic colors and immersive UX
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

  // Mode colors - matches single-player design
  List<Color> get _selectedGradient {
    switch (_selectedMode) {
      case ModeVariant.timeRace:
        return [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)];
      case ModeVariant.relax:
        return [const Color(0xFF66BB6A), const Color(0xFF81C784)];
      case ModeVariant.real:
        return [const Color(0xFFFFB958), const Color(0xFFFFCE54)];
      case null:
        return [const Color(0xFFCAB7FF), const Color(0xFFE0D6FF)];
    }
  }

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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _selectedGradient[0].withValues(alpha: 0.08),
              _selectedGradient[1].withValues(alpha: 0.03),
              Colors.white.withValues(alpha: 0.95),
            ],
            stops: const [0.0, 0.3, 0.6],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with reduced opacity when mode selected
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _selectedMode == null ? 1.0 : 0.6,
              child: Image.asset(
                'assets/images/bg_music_clouds.png',
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Challenge info card with description area
                          _buildChallengeCard(),

                          const SizedBox(height: 20),

                          // Section title
                          _buildSectionTitle(),

                          const SizedBox(height: 12),

                          // Mode cards
                          _buildGameModeCard(
                            mode: ModeVariant.timeRace,
                            emoji: '⚡',
                            title: 'Time Race',
                            moodTag: 'HIZLI',
                            tagline: '5 dakikada yarışı kazan',
                            rules: ['5 dk süre', 'Yanlış = 3sn freeze', 'Sıralı turlar'],
                            gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
                          ),

                          const SizedBox(height: 10),

                          _buildGameModeCard(
                            mode: ModeVariant.relax,
                            emoji: '🎯',
                            title: 'Relax',
                            moodTag: 'RAHAT',
                            tagline: 'Sakin tempoda yarış',
                            rules: ['30sn / kelime', 'Yanlış = 1sn', 'Comeback x2/x3'],
                            gradient: [const Color(0xFF66BB6A), const Color(0xFF81C784)],
                          ),

                          const SizedBox(height: 10),

                          _buildGameModeCard(
                            mode: ModeVariant.real,
                            emoji: '⚔️',
                            title: 'Real Challenge',
                            moodTag: 'REKABETÇİ',
                            tagline: 'Risk al, puan kazan!',
                            rules: ['Doğru +1', 'Yanlış -3', 'Çal bonusu +2'],
                            gradient: [const Color(0xFFFFB958), const Color(0xFFFFCE54)],
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
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF394272).withValues(alpha: 0.1),
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
          const SizedBox(width: 16),
          // Title with shadow for visibility
          Expanded(
            child: Text(
              'Online Yarış',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF394272),
                letterSpacing: -0.5,
                shadows: _selectedMode != null
                    ? [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedMode != null
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _selectedMode != null
                        ? Colors.white
                        : const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CANLI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _selectedMode != null
                        ? Colors.white
                        : const Color(0xFF4CAF50),
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

  Widget _buildChallengeCard() {
    final hasSelection = _selectedMode != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasSelection
              ? [
                  _selectedGradient[0],
                  _selectedGradient[1],
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F5FF),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasSelection
              ? _selectedGradient[0].withValues(alpha: 0.3)
              : const Color(0xFFCAB7FF).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedGradient[0].withValues(alpha: hasSelection ? 0.35 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Challenge emoji badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: hasSelection
                      ? Colors.white.withValues(alpha: 0.25)
                      : null,
                  gradient: hasSelection
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFCAB7FF), Color(0xFFB8A4F8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: hasSelection
                          ? Colors.black.withValues(alpha: 0.1)
                          : const Color(0xFFCAB7FF).withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.challenge.type == ChallengeType.artist ? '🎤' : '🎵',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title and chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: hasSelection ? Colors.white : const Color(0xFF394272),
                        letterSpacing: -0.3,
                      ),
                      child: Text(
                        widget.challenge.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasSelection
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '🎵 ${widget.challenge.totalSongs} şarkı',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasSelection ? Colors.white : const Color(0xFF7C4DFF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasSelection
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.challenge.difficultyLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasSelection ? Colors.white : const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Online info area
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasSelection
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF58A6FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasSelection
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFF58A6FF).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(
                      Icons.wifi_tethering_rounded,
                      size: 18,
                      color: hasSelection
                          ? Colors.white
                          : const Color(0xFF58A6FF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Online Yarış',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: hasSelection
                            ? Colors.white
                            : const Color(0xFF394272),
                      ),
                    ),
                    const Spacer(),
                    // Live badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasSelection
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'CANLI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Info chips row
                Row(
                  children: [
                    _buildOnlineInfoChip('👥', '2 Kişi', hasSelection),
                    const SizedBox(width: 8),
                    _buildOnlineInfoChip('🔄', 'Sıralı Tur', hasSelection),
                    const SizedBox(width: 8),
                    _buildOnlineInfoChip('⚡', 'Anlık', hasSelection),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineInfoChip(String emoji, String text, bool hasSelection) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasSelection
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFF58A6FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: hasSelection
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFF394272).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _selectedMode != null
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _selectedMode != null
            ? [
                BoxShadow(
                  color: _selectedGradient[0].withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        'Nasıl yarışmak istersin?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _selectedMode != null
              ? _selectedGradient[0]
              : const Color(0xFF394272),
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required ModeVariant mode,
    required String emoji,
    required String title,
    required String moodTag,
    required String tagline,
    required List<String> rules,
    required List<Color> gradient,
  }) {
    final isSelected = _selectedMode == mode;
    final isOtherSelected = _selectedMode != null && _selectedMode != mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : (isOtherSelected ? 0.97 : 1.0)),
        padding: EdgeInsets.all(isSelected ? 18 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    Colors.white,
                    Color.lerp(Colors.white, gradient[0], 0.15)!,
                    Color.lerp(Colors.white, gradient[1], 0.12)!,
                  ]
                : [
                    Colors.white.withValues(alpha: isOtherSelected ? 0.7 : 0.95),
                    Colors.white.withValues(alpha: isOtherSelected ? 0.6 : 0.9),
                  ],
          ),
          borderRadius: BorderRadius.circular(isSelected ? 24 : 20),
          border: Border.all(
            color: isSelected
                ? gradient[0].withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.8),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? gradient[0].withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: isOtherSelected ? 0.02 : 0.05),
              blurRadius: isSelected ? 24 : 10,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isOtherSelected ? 0.6 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Emoji badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 60 : 48,
                    height: isSelected ? 60 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? gradient
                            : [gradient[0].withValues(alpha: 0.2), gradient[1].withValues(alpha: 0.15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isSelected ? 16 : 14),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gradient[0].withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: isSelected ? 30 : 24),
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
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: isSelected ? 20 : 17,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? gradient[0] : const Color(0xFF394272),
                              ),
                              child: Text(title),
                            ),
                            if (!isSelected && !isOtherSelected && mode == ModeVariant.timeRace) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFCAB7FF), Color(0xFFB8A4F8)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ÖNERİLEN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: isSelected ? 14 : 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? gradient[0].withValues(alpha: 0.85)
                                : const Color(0xFF6C6FA4),
                          ),
                          child: Text(tagline),
                        ),
                      ],
                    ),
                  ),
                  // Mood tag or check
                  if (isSelected)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gradient[0], gradient[1]],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        moodTag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                ],
              ),
              // Rules - expanded when selected
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isSelected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: rules.map((rule) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: gradient[0].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: gradient[0].withValues(alpha: 0.8),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      // Expanded rules view
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: gradient[0].withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: rules.map((rule) => Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradient[0].withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _getRuleIcon(rule),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rule,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: gradient[0],
                                ),
                              ),
                            ],
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRuleIcon(String rule) {
    if (rule.contains('dk') || rule.contains('sn')) return '⏱️';
    if (rule.contains('Yanlış')) return '❌';
    if (rule.contains('Doğru')) return '✅';
    if (rule.contains('Comeback')) return '🔥';
    if (rule.contains('Çal') || rule.contains('bonus')) return '🎯';
    if (rule.contains('Sıralı') || rule.contains('turlar')) return '🔄';
    if (rule.contains('kelime')) return '💬';
    return '📌';
  }

  Widget _buildStickyCTA() {
    final modeConfig = _getModeConfig(_selectedMode!);

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
              gradient: LinearGradient(
                colors: modeConfig['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (modeConfig['gradient'] as List<Color>)[0].withValues(alpha: 0.45),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_search_rounded,
                      color: Colors.white,
                      size: 26,
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
                    const SizedBox(width: 8),
                    Text(modeConfig['emoji'] as String, style: const TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getModeConfig(ModeVariant mode) {
    switch (mode) {
      case ModeVariant.timeRace:
        return {
          'emoji': '⚡',
          'cta': 'Rakip Bul',
          'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
        };
      case ModeVariant.relax:
        return {
          'emoji': '🎯',
          'cta': 'Rakip Bul',
          'gradient': [const Color(0xFF66BB6A), const Color(0xFF81C784)],
        };
      case ModeVariant.real:
        return {
          'emoji': '⚔️',
          'cta': 'Rakip Bul',
          'gradient': [const Color(0xFFFFB958), const Color(0xFFFFCE54)],
        };
    }
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
