import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../rewards/rewards_screen.dart';

/// HOME SCREEN - Ana Menü
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final user = authProvider.user;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan
          Image.asset(
            'assets/images/home_bg.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Column(
              children: [
                // Üst bar - Profil butonu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sol taraf: Nasıl Oynanır + Joker Hakları
                      Row(
                        children: [
                          // How to Play butonu
                          GestureDetector(
                            onTap: () => _showHowToPlay(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.help_outline_rounded,
                                size: 20,
                                color: Color(0xFF394272),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Joker Hakları butonu
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RewardsScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🃏',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user?.effectiveJokerCredits ?? 0}/${UserModel.maxWordChangeCredits}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF394272),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Profil butonu
                      GestureDetector(
                        onTap: () {
                          if (isLoggedIn) {
                            Navigator.pushNamed(context, '/profile');
                          } else {
                            Navigator.pushNamed(context, '/login');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFCAB7FF),
                                backgroundImage: user?.photoUrl != null
                                    ? NetworkImage(user!.photoUrl!)
                                    : null,
                                child: user?.photoUrl == null
                                    ? Icon(
                                        isLoggedIn ? Icons.person : Icons.login,
                                        size: 16,
                                        color: const Color(0xFF394272),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isLoggedIn
                                    ? (user?.displayName ?? 'Profil')
                                    : 'Giriş Yap',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF394272),
                                ),
                              ),
                              if (user?.isActivePremium == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 16,
                                  color: Color(0xFFFFB958),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo alanı için boşluk
                SizedBox(height: size.height * 0.40),

                // Tek Başına
                ModeButton(
                  label: 'Tek Başına',
                  icon: Icons.music_note,
                  backgroundColor: const Color(0xFFCAB7FF),
                  textColor: const Color(0xFF4B4F72),
                  onTap: () {
                    Navigator.pushNamed(context, '/single-player');
                  },
                ),

                const SizedBox(height: 16),

                // Arkadaşınla
                ModeButton(
                  label: 'Arkadaşınla',
                  icon: Icons.people,
                  backgroundColor: const Color(0xFFFFD891),
                  textColor: const Color(0xFF8C5A1F),
                  onTap: () {
                    Navigator.pushNamed(context, '/friends');
                  },
                ),

                const SizedBox(height: 16),

                // Challenge modu
                ModeButton(
                  label: 'Challenge',
                  icon: Icons.emoji_events,
                  backgroundColor: const Color(0xFF394272),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushNamed(context, '/challenge');
                  },
                ),

                const Spacer(),

                // Alt boşluk
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HowToPlaySheet(),
    );
  }
}

class ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const ModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width * 0.65,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 8,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How to Play Modal Sheet
class HowToPlaySheet extends StatelessWidget {
  const HowToPlaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nasıl Oynanır?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF394272),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF394272)),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSection(
                      icon: Icons.music_note_rounded,
                      title: 'Oyun Mantığı',
                      content:
                          'Ekranda bir kelime görürsün. Bu kelimeyi içeren bir şarkı bul ve '
                          'şarkı adını + sanatçıyı yaz. Ne kadar hızlı bilirsen o kadar çok puan!',
                    ),
                    _buildSection(
                      icon: Icons.person_rounded,
                      title: 'Tek Başına',
                      content:
                          'Kendi başına pratik yap, high score\'unu kır. '
                          'Şarkı sayısı veya süre hedefi belirleyebilirsin.',
                    ),
                    _buildSection(
                      icon: Icons.people_rounded,
                      title: 'Arkadaşınla',
                      content:
                          'Aynı cihazda sırayla oynayın. Her oyuncu kendi sırasında '
                          'şarkı tahmin eder. En çok doğru bilen kazanır!',
                    ),
                    _buildSection(
                      icon: Icons.emoji_events_rounded,
                      title: 'Challenge Modu',
                      content:
                          'Hazır şarkı setlerinde kendini test et. Sanatçı diskografileri, '
                          'dönemler veya özel listelerden challenge\'lar oyna.',
                    ),
                    _buildSection(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Kelime Değiştirme',
                      content:
                          'Kelimeyi bilmiyorsan "Değiştir" butonuyla yeni kelime al. '
                          'Dikkat: Sınırlı hakkın var!',
                    ),
                    _buildSection(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Premium',
                      content:
                          'Tüm challenge\'lara erişim, online multiplayer, '
                          'sınırsız kelime değiştirme ve reklamsız deneyim.',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFCAB7FF).withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF394272), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C6FA4),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
