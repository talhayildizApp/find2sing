import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/match_intent_model.dart';
import '../../widgets/local_game_ui_components.dart';
import '../online/online_match_screen.dart';
import '../premium/premium_screen.dart';
import 'friend_game_screen.dart';
import 'game_config.dart';

/// Oyun tipi
enum GameType { local, online }

// Color constants for settings sections
class _SettingsColors {
  static const Color gameType = Color(0xFF8B5CF6);   // Purple
  static const Color timer = Color(0xFF3B82F6);       // Blue
  static const Color endCondition = Color(0xFF10B981); // Green
  static const Color wordChange = Color(0xFFF59E0B);  // Orange
}

class FriendsSettingsScreen extends StatefulWidget {
  const FriendsSettingsScreen({super.key});

  @override
  State<FriendsSettingsScreen> createState() => _FriendsSettingsScreenState();
}

class _FriendsSettingsScreenState extends State<FriendsSettingsScreen>
    with TickerProviderStateMixin {
  // Oyun tipi (Local veya Online)
  GameType _gameType = GameType.local;

  // Geri sayım süresi
  int _countdownSeconds = 15;

  // Bitiş koşulu
  EndCondition _endCondition = EndCondition.songCount;

  // Şarkı hedefi
  int _songTarget = 10;

  // Süre hedefi (dakika)
  int _timeMinutes = 5;

  // Kelime değiştirme hakkı
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
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isPremium = user?.isActivePremium ?? false;

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
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 110), // Bottom padding for floating button
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title - kompakt
                      _buildTitleSection(),

                      const SizedBox(height: 12),

                      // Oyun Tipi Seçimi - kompakt
                      _buildGameTypeSection(isPremium),

                      const SizedBox(height: 10),

                      // Tahmin Süresi - horizontal scroll
                      _CompactSettingsCard(
                        title: 'Tahmin Süresi',
                        description: 'Her kelime için tahmin süresi',
                        icon: Icons.timer_rounded,
                        accentColor: _SettingsColors.timer,
                        child: _buildCountdownSelector(),
                      ),

                      const SizedBox(height: 10),

                      // Oyun Sonu Koşulu
                      _CompactSettingsCard(
                        title: 'Oyun Sonu',
                        description: 'Oyun nasıl sonlanacak?',
                        icon: Icons.flag_rounded,
                        accentColor: _SettingsColors.endCondition,
                        child: _buildEndConditionSelector(),
                      ),

                      const SizedBox(height: 10),

                      // Kelime Değiştirme Hakkı - horizontal scroll
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

          // Floating Start Button with gradient fade
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingStartButton(isPremium),
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
  Widget _buildTitleSection() {
    return AnimatedBuilder(
      animation: _heroAnimationController,
      builder: (context, child) {
        final bounce = _heroAnimationController.value * 6;
        final glow = 0.15 + (_heroAnimationController.value * 0.1);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            // Rich gradient background
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B5CF6), // Purple
                Color(0xFFA855F7), // Light purple
                Color(0xFFF59E0B), // Orange
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(-4, 8),
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(4, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Floating icon row with glassmorphism
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, -bounce),
                    child: _buildHeroIcon(
                      Icons.music_note_rounded,
                      const Color(0xFF8B5CF6),
                      glowOpacity: glow,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Transform.translate(
                    offset: Offset(0, bounce * 0.7),
                    child: _buildHeroIcon(
                      Icons.mic_rounded,
                      const Color(0xFFF59E0B),
                      isLarge: true,
                      glowOpacity: glow,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Transform.translate(
                    offset: Offset(0, -bounce),
                    child: _buildHeroIcon(
                      Icons.music_note_rounded,
                      const Color(0xFF10B981),
                      glowOpacity: glow,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title - clean white
              const Text(
                'Arkadaşınla Oyna',
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

              // Subtitle badge - glassmorphism style
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
                      'Müzik bilginizi yarıştırın!',
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

  // KOMPAKT Game Type Section - 120px height cards
  Widget _buildGameTypeSection(bool isPremium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header - kompakt
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _SettingsColors.gameType.withValues(alpha: 0.2),
                      _SettingsColors.gameType.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  size: 14,
                  color: _SettingsColors.gameType,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Oyun Modu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LocalGameColors.darkPurple,
                ),
              ),
            ],
          ),
        ),

        // Game type cards - increased height to prevent overflow
        SizedBox(
          height: 120,
          child: Row(
            children: [
              // Aynı Cihaz
              Expanded(
                child: _CompactGameTypeCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Aynı Cihaz',
                  subtitle: 'Yan yana',
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  isSelected: _gameType == GameType.local,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _gameType = GameType.local);
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Online
              Expanded(
                child: _CompactGameTypeCard(
                  icon: Icons.wifi_rounded,
                  title: 'Online',
                  subtitle: 'Uzaktan',
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  isSelected: _gameType == GameType.online,
                  isPremium: true,
                  isPremiumUnlocked: isPremium,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _gameType = GameType.online);
                    if (!isPremium) {
                      _showOnlinePremiumInfo();
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Info message for online mode - only show when premium is active
        if (_gameType == GameType.online && isPremium) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: LocalGameColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: LocalGameColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: LocalGameColors.success,
                ),
                SizedBox(width: 6),
                Text(
                  'Online mod aktif!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: LocalGameColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // HORIZONTAL SCROLL chips
  Widget _buildCountdownSelector() {
    final options = [10, 15, 20, 30];
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

  Widget _buildEndConditionSelector() {
    return Column(
      children: [
        // Segmented control - kompakt
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

        // Değer seçimi - horizontal scroll
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
    final counts = [5, 10, 15, 20, 25];
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
    final options = [3, 5, 7, 10];
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

  Widget _buildWordChangeSelector() {
    final counts = [0, 1, 2, 3, 5];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: counts.map((count) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CompactChip(
              label: count == 0 ? 'Kapalı' : '$count kelime',
              isSelected: _wordChangeCount == count,
              onTap: () => setState(() => _wordChangeCount = count),
            ),
          );
        }).toList(),
      ),
    );
  }

  // FLOATING Start Button with gradient fade
  Widget _buildFloatingStartButton(bool isPremium) {
    final canStart = _canStartGame(isPremium);

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
            final scale = canStart ? 1.0 + (_pulseController.value * 0.015) : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: GestureDetector(
            onTap: canStart
                ? () {
                    HapticFeedback.mediumImpact();
                    _startGame(context);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 56,
              decoration: BoxDecoration(
                gradient: canStart
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFA855F7),
                          Color(0xFFF59E0B),
                        ],
                      )
                    : null,
                color: canStart ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(18),
                boxShadow: canStart
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(-3, 6),
                        ),
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(3, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: canStart
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.shade400.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _gameType == GameType.online && !isPremium
                          ? Icons.lock_rounded
                          : Icons.play_arrow_rounded,
                      color: canStart ? Colors.white : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _gameType == GameType.online && !isPremium
                        ? 'Premium Gerekli'
                        : 'Oyuna Başla!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: canStart ? Colors.white : Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (canStart) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOnlinePremiumInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFFFB958)),
            const SizedBox(width: 8),
            const Text(
              'Premium Gerekli',
              style: TextStyle(color: Color(0xFF394272)),
            ),
          ],
        ),
        content: const Text(
          'Online multiplayer modunu kullanabilmek için her iki oyuncunun da '
          'Premium üye olması veya aynı kategoriyi satın almış olması gerekir.\n\n'
          'Premium ile tüm özelliklere sınırsız erişim kazanabilirsin!',
          style: TextStyle(color: Color(0xFF6C6FA4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB958),
            ),
            child: const Text(
              'Premium\'a Geç',
              style: TextStyle(color: Color(0xFF8C5A1F)),
            ),
          ),
        ],
      ),
    );
  }

  bool _canStartGame(bool isPremium) {
    if (_gameType == GameType.online && !isPremium) {
      return false;
    }
    return true;
  }

  void _startGame(BuildContext context) {
    if (_gameType == GameType.online) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineMatchScreen(
            mode: MatchMode.friendsWord,
            endCondition: _endCondition == EndCondition.songCount ? 'songCount' : 'time',
            targetRounds: _songTarget,
            timeMinutes: _timeMinutes,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendGameScreen(
          countdownSeconds: _countdownSeconds,
          songMode: SongMode.single,
          endCondition: _endCondition,
          songTarget: _songTarget,
          timeMinutes: _timeMinutes,
          wordChangeCount: _wordChangeCount,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT GAME TYPE CARD - Fixed height with no overflow
// ─────────────────────────────────────────────────────────────────────────────

class _CompactGameTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final bool isSelected;
  final bool isPremium;
  final bool isPremiumUnlocked;
  final VoidCallback? onTap;

  const _CompactGameTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.isSelected,
    this.isPremium = false,
    this.isPremiumUnlocked = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = gradientColors.first;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : LinearGradient(
                  colors: [Colors.white, mainColor.withValues(alpha: 0.05)],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.4)
                : mainColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with premium badge - smaller padding
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : mainColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected ? Colors.white : mainColor,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
                // Premium badge - more prominent, positioned at top right
                if (isPremium)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isPremiumUnlocked
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFD700), Color(0xFFFFB958), Color(0xFFFF8C00)],
                              ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isPremiumUnlocked
                                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                : const Color(0xFFFFB958).withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Title - with shadow when selected
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : LocalGameColors.darkPurple,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle - with shadow when selected
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : mainColor.withValues(alpha: 0.85),
                shadows: isSelected
                    ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT SETTINGS CARD - with description support
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
