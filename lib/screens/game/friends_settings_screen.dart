import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'friend_game_screen.dart';
import 'game_config.dart';

/// Oyun tipi
enum GameType { local, online }

class FriendsSettingsScreen extends StatefulWidget {
  const FriendsSettingsScreen({super.key});

  @override
  State<FriendsSettingsScreen> createState() => _FriendsSettingsScreenState();
}

class _FriendsSettingsScreenState extends State<FriendsSettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isPremium = user?.isActivePremium ?? false;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Column(
              children: [
                // Üst bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Ana Menü butonu
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(
                            Icons.home_rounded,
                            size: 18,
                            color: Color(0xFF394272),
                          ),
                          label: const Text(
                            'Ana Menü',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF394272),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: Center(
                    child: Container(
                      width: size.width * 0.9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FF),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: Text(
                                  'Arkadaşınla Oyna',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF394272),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Oyun Tipi Seçimi (Local / Online)
                              _buildGameTypeSection(isPremium),

                              const SizedBox(height: 16),

                              // Geri sayım süresi
                              _SettingsCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tahmin Süresi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6C6FA4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [10, 15, 20, 30].map((seconds) {
                                        return _OptionChip(
                                          label: '$seconds sn',
                                          isSelected: _countdownSeconds == seconds,
                                          onTap: () {
                                            setState(() => _countdownSeconds = seconds);
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Oyun bitiş koşulu
                              _SettingsCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Oyun Sonu',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6C6FA4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Şarkı sayısı seçeneği
                                    InkWell(
                                      onTap: () {
                                        setState(() =>
                                            _endCondition = EndCondition.songCount);
                                      },
                                      child: Row(
                                        children: [
                                          Radio<EndCondition>(
                                            value: EndCondition.songCount,
                                            groupValue: _endCondition,
                                            activeColor: const Color(0xFF6C6FA4),
                                            onChanged: (value) {
                                              setState(() => _endCondition = value!);
                                            },
                                          ),
                                          const Text('Şarkı Sayısı'),
                                          const Spacer(),
                                          _buildSongTargetDropdown(),
                                        ],
                                      ),
                                    ),

                                    // Süre seçeneği
                                    InkWell(
                                      onTap: () {
                                        setState(
                                            () => _endCondition = EndCondition.time);
                                      },
                                      child: Row(
                                        children: [
                                          Radio<EndCondition>(
                                            value: EndCondition.time,
                                            groupValue: _endCondition,
                                            activeColor: const Color(0xFF6C6FA4),
                                            onChanged: (value) {
                                              setState(() => _endCondition = value!);
                                            },
                                          ),
                                          const Text('Süre Bitince'),
                                          const Spacer(),
                                          Text(
                                            '$_timeMinutes Dakika',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF394272),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.expand_more,
                                            size: 20,
                                            color: Color(0xFF6C6FA4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Kelime değiştirme hakkı
                              _SettingsCard(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _showWordChangeSheet,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Kelime Değiştirme Hakkı',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6C6FA4),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '$_wordChangeCount',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF394272),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.expand_more,
                                            color: Color(0xFF6C6FA4),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Başla butonu
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _canStartGame(isPremium)
                                      ? () => _startGame(context)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFCAB7FF),
                                    disabledBackgroundColor:
                                        const Color(0xFFE0E0E0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: Text(
                                    _gameType == GameType.online && !isPremium
                                        ? 'Premium Gerekli'
                                        : 'Başla',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _canStartGame(isPremium)
                                          ? const Color(0xFF394272)
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Oyun tipi seçim bölümü
  Widget _buildGameTypeSection(bool isPremium) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oyun Tipi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C6FA4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GameTypeButton(
                  icon: Icons.people,
                  label: 'Aynı Cihaz',
                  subtitle: 'Yan yana oyna',
                  isSelected: _gameType == GameType.local,
                  onTap: () => setState(() => _gameType = GameType.local),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GameTypeButton(
                  icon: Icons.wifi,
                  label: 'Online',
                  subtitle: isPremium ? 'Uzaktan oyna' : 'Premium',
                  isSelected: _gameType == GameType.online,
                  isLocked: !isPremium,
                  onTap: () {
                    setState(() => _gameType = GameType.online);
                    if (!isPremium) {
                      _showOnlinePremiumInfo();
                    }
                  },
                ),
              ),
            ],
          ),

          // Online uyarı mesajı
          if (_gameType == GameType.online) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPremium
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPremium
                      ? const Color(0xFF81C784)
                      : const Color(0xFFFFB74D),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPremium ? Icons.check_circle : Icons.info_outline,
                    size: 20,
                    color: isPremium
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPremium
                          ? 'Online mod aktif! Arkadaşını davet edebilirsin.'
                          : 'Online mod için her iki oyuncunun da Premium üye olması gerekir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPremium
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongTargetDropdown() {
    return PopupMenuButton<int>(
      initialValue: _songTarget,
      onSelected: (value) {
        setState(() => _songTarget = value);
      },
      itemBuilder: (context) => [5, 10, 15, 20, 25]
          .map((count) => PopupMenuItem(
                value: count,
                child: Text('$count şarkı'),
              ))
          .toList(),
      child: Row(
        children: [
          Text(
            '$_songTarget Şarkı',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.expand_more,
            size: 20,
            color: Color(0xFF6C6FA4),
          ),
        ],
      ),
    );
  }

  void _showWordChangeSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kelime Değiştirme Hakkı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
            ),
            const SizedBox(height: 16),
            ...[0, 1, 2, 3, 5].map((count) => ListTile(
                  title: Text(count == 0 ? 'Kapalı' : '$count hak'),
                  trailing: _wordChangeCount == count
                      ? const Icon(Icons.check, color: Color(0xFFCAB7FF))
                      : null,
                  onTap: () {
                    setState(() => _wordChangeCount = count);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
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
              // TODO: Premium sayfasına git
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
      // TODO: Online matchmaking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Online mod yakında aktif olacak!'),
          backgroundColor: Color(0xFFCAB7FF),
        ),
      );
      return;
    }

    // Local oyun başlat
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

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C6FA4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6C6FA4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF394272),
          ),
        ),
      ),
    );
  }
}

class _GameTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _GameTypeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFCAB7FF).withValues(alpha:0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFCAB7FF) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected
                      ? const Color(0xFF394272)
                      : const Color(0xFF6C6FA4),
                ),
                if (isLocked)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB958),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF394272)
                    : const Color(0xFF6C6FA4),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isLocked
                    ? const Color(0xFFFFB958)
                    : const Color(0xFF6C6FA4).withValues(alpha:0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
