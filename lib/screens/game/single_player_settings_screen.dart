import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/local_game_ui_components.dart';
import 'game_config.dart';
import 'single_game_screen.dart';

// Color constants for settings sections
class _SettingsColors {
  static const Color timer = Color(0xFF3B82F6);       // Blue
  static const Color songMode = Color(0xFF8B5CF6);    // Purple
  static const Color endCondition = Color(0xFF10B981); // Green
  static const Color wordChange = Color(0xFFF59E0B);  // Orange
}

class SinglePlayerSettingsScreen extends StatefulWidget {
  const SinglePlayerSettingsScreen({super.key});

  @override
  State<SinglePlayerSettingsScreen> createState() =>
      _SinglePlayerSettingsScreenState();
}

class _SinglePlayerSettingsScreenState
    extends State<SinglePlayerSettingsScreen>
    with TickerProviderStateMixin {
  int _countdownSeconds = 30;
  SongMode _songMode = SongMode.single;
  EndCondition _endCondition = EndCondition.songCount;
  int _songTarget = 10;
  int _timeMinutes = 3;
  int _wordChangeCount = 3;

  // Animation controllers
  late AnimationController _heroAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocalGameScaffold(
      child: Stack(
        children: [
          // Scrollable content
          Column(
            children: [
              // Header - kompakt
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      _buildHeroSection(),

                      const SizedBox(height: 12),

                      // Tahmin Süresi
                      _CompactSettingsCard(
                        title: 'Tahmin Süresi',
                        description: 'Her kelime için tahmin süresi',
                        icon: Icons.timer_rounded,
                        accentColor: _SettingsColors.timer,
                        child: _buildCountdownSelector(),
                      ),

                      const SizedBox(height: 10),

                      // Şarkı Modu
                      _CompactSettingsCard(
                        title: 'Şarkı Modu',
                        description: 'Her kelime için kaç şarkı bulacaksın?',
                        icon: Icons.music_note_rounded,
                        accentColor: _SettingsColors.songMode,
                        child: _buildSongModeSelector(),
                      ),

                      const SizedBox(height: 10),

                      // Oyun Bitiş Şartı
                      _CompactSettingsCard(
                        title: 'Oyun Sonu',
                        description: 'Oyun nasıl sonlanacak?',
                        icon: Icons.flag_rounded,
                        accentColor: _SettingsColors.endCondition,
                        child: _buildEndConditionSelector(),
                      ),

                      const SizedBox(height: 10),

                      // Kelime Değiştirme Hakkı
                      _CompactSettingsCard(
                        title: 'Kelime Değiştirme',
                        description: 'Bilmediğiniz kelimeleri atlayın',
                        icon: Icons.refresh_rounded,
                        accentColor: _SettingsColors.wordChange,
                        child: _buildWordChangeSelector(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Start Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingStartButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: LocalGameColors.darkPurple,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Geri',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LocalGameColors.darkPurple,
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

  // Hero Section - Premium glassmorphism design
  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _heroAnimationController,
      builder: (context, child) {
        final bounce = _heroAnimationController.value * 6;
        final glow = 0.15 + (_heroAnimationController.value * 0.1);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            // Rich gradient background - Blue to Purple for single player
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6), // Blue
                Color(0xFF8B5CF6), // Purple
                Color(0xFFA855F7), // Light purple
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(-4, 8),
              ),
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(4, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Floating icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, -bounce),
                    child: _buildHeroIcon(
                      Icons.headphones_rounded,
                      const Color(0xFF3B82F6),
                      glowOpacity: glow,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Transform.translate(
                    offset: Offset(0, bounce * 0.7),
                    child: _buildHeroIcon(
                      Icons.person_rounded,
                      const Color(0xFF8B5CF6),
                      isLarge: true,
                      glowOpacity: glow,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Transform.translate(
                    offset: Offset(0, -bounce),
                    child: _buildHeroIcon(
                      Icons.music_note_rounded,
                      const Color(0xFFA855F7),
                      glowOpacity: glow,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Tek Oyunculu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎵', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Text(
                      'Kendini test et!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('🎵', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroIcon(IconData icon, Color color, {bool isLarge = false, double glowOpacity = 0.2}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 18 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLarge ? 22 : 18),
        boxShadow: [
          // Colored glow
          BoxShadow(
            color: color.withValues(alpha: glowOpacity + 0.2),
            blurRadius: isLarge ? 20 : 16,
            spreadRadius: isLarge ? 2 : 1,
          ),
          // Soft shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: isLarge ? 32 : 24,
        color: color,
      ),
    );
  }

  // Countdown selector - horizontal scroll
  Widget _buildCountdownSelector() {
    final options = [15, 30, 45];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: options.map((seconds) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CompactChip(
              label: '$seconds sn',
              isSelected: _countdownSeconds == seconds,
              onTap: () => setState(() => _countdownSeconds = seconds),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Song mode selector
  Widget _buildSongModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _CompactChip(
            label: 'Tek Şarkı',
            isSelected: _songMode == SongMode.single,
            onTap: () => setState(() => _songMode = SongMode.single),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactChip(
            label: 'Çoklu Şarkı',
            isSelected: _songMode == SongMode.multiple,
            onTap: () => setState(() => _songMode = SongMode.multiple),
          ),
        ),
      ],
    );
  }

  // End condition selector
  Widget _buildEndConditionSelector() {
    return Column(
      children: [
        // Segmented control
        _CompactSegmentedButton(
          segments: const ['Şarkı Sayısı', 'Süre'],
          selectedIndex: _endCondition == EndCondition.songCount ? 0 : 1,
          onChanged: (index) {
            setState(() {
              _endCondition = index == 0 ? EndCondition.songCount : EndCondition.time;
            });
          },
        ),
        const SizedBox(height: 10),

        // Value selection
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _endCondition == EndCondition.songCount
              ? _buildSongCountSelector()
              : _buildTimeSelector(),
        ),
      ],
    );
  }

  Widget _buildSongCountSelector() {
    final counts = [5, 10, 15, 20];
    return SingleChildScrollView(
      key: const ValueKey('songCount'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: counts.map((count) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CompactChip(
              label: '$count şarkı',
              isSelected: _songTarget == count,
              onTap: () => setState(() => _songTarget = count),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSelector() {
    final options = [1, 3, 5, 10];
    return SingleChildScrollView(
      key: const ValueKey('time'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: options.map((minutes) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CompactChip(
              label: '$minutes dk',
              isSelected: _timeMinutes == minutes,
              onTap: () => setState(() => _timeMinutes = minutes),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Word change selector
  Widget _buildWordChangeSelector() {
    final counts = [1, 3, 5];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: counts.map((count) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CompactChip(
              label: '$count kelime',
              isSelected: _wordChangeCount == count,
              onTap: () => setState(() => _wordChangeCount = count),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Floating Start Button with gradient
  Widget _buildFloatingStartButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.85),
            Colors.white,
          ],
          stops: const [0.0, 0.2, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.015);
            return Transform.scale(scale: scale, child: child);
          },
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SingleGameScreen(
                    countdownSeconds: _countdownSeconds,
                    songMode: _songMode,
                    endCondition: _endCondition,
                    songTarget: _songTarget,
                    timeMinutes: _timeMinutes,
                    wordChangeCount: _wordChangeCount,
                  ),
                ),
              );
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF8B5CF6),
                    Color(0xFFA855F7),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(-3, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(3, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Oyuna Başla!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
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
// COMPACT SETTINGS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CompactSettingsCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final IconData icon;
  final Color accentColor;

  const _CompactSettingsCard({
    required this.title,
    this.description,
    required this.child,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Gradient like SolvedSongsCard: white → light accent color
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFFFFE),
            Color.lerp(Colors.white, accentColor, 0.06)!,
            Color.lerp(Colors.white, accentColor, 0.10)!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LocalGameColors.darkPurple,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: LocalGameColors.darkPurple.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _CompactChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CompactChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [LocalGameColors.primaryPurple, Color(0xFF9B7EDE)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? null
              : Border.all(color: LocalGameColors.primaryPurple.withValues(alpha: 0.25)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LocalGameColors.primaryPurple.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : LocalGameColors.darkPurple,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT SEGMENTED BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CompactSegmentedButton extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  const _CompactSegmentedButton({
    required this.segments,
    required this.selectedIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LocalGameColors.softPurple,
        borderRadius: BorderRadius.circular(10),
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
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    segments[index],
                    style: TextStyle(
                      fontSize: 12,
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
