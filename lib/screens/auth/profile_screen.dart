import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF394272),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Profilim',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF394272),
                          ),
                        ),
                      ),
                      // Ayarlar butonu
                      IconButton(
                        onPressed: () {
                          _showSettingsSheet(context);
                        },
                        icon: const Icon(
                          Icons.settings,
                          color: Color(0xFF394272),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Profil kartı
                        _ProfileCard(user: user),

                        const SizedBox(height: 20),

                        // İstatistikler
                        _StatsCard(user: user),

                        const SizedBox(height: 20),

                        // Premium durumu
                        _PremiumCard(user: user),

                        const SizedBox(height: 20),

                        // Çıkış butonu
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await _showLogoutConfirmation(context);
                              if (confirm == true) {
                                await authProvider.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Çıkış Yap',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
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

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
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
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF6C6FA4)),
              title: const Text('Profili Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF6C6FA4)),
              title: const Text('Dil Ayarları'),
              onTap: () {
                Navigator.pop(context);
                _showLanguageDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Color(0xFF6C6FA4)),
              title: const Text('Gizlilik Politikası'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Gizlilik politikası sayfasına git
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF6C6FA4)),
              title: const Text('Kullanım Koşulları'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Kullanım koşulları sayfasına git
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final controller = TextEditingController(text: user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Profili Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Kullanıcı Adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await context.read<AuthProvider>().updateProfile(
                  displayName: newName,
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCAB7FF),
            ),
            child: const Text(
              'Kaydet',
              style: TextStyle(color: Color(0xFF394272)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final currentLang = user?.preferredLanguage ?? 'tr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Dil Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Türkçe'),
              trailing: currentLang == 'tr'
                  ? const Icon(Icons.check, color: Color(0xFFCAB7FF))
                  : null,
              onTap: () async {
                await context.read<AuthProvider>().updateProfile(
                  preferredLanguage: 'tr',
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: currentLang == 'en'
                  ? const Icon(Icons.check, color: Color(0xFFCAB7FF))
                  : null,
              onTap: () async {
                await context.read<AuthProvider>().updateProfile(
                  preferredLanguage: 'en',
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel? user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFCAB7FF),
            backgroundImage: user?.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null
                ? Text(
                    (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF394272),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // İsim
          Text(
            user?.displayName ?? 'Oyuncu',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            user?.email ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C6FA4),
            ),
          ),

          const SizedBox(height: 12),

          // Üyelik tarihi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Color(0xFF6C6FA4),
              ),
              const SizedBox(width: 4),
              Text(
                'Üyelik: ${_formatDate(user?.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C6FA4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _StatsCard extends StatelessWidget {
  final UserModel? user;

  const _StatsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.music_note,
                  value: '${user?.totalSongsFound ?? 0}',
                  label: 'Şarkı Bulundu',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.gamepad,
                  value: '${user?.totalGamesPlayed ?? 0}',
                  label: 'Oyun',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.timer,
                  value: _formatTime(user?.totalTimePlayed ?? 0),
                  label: 'Toplam Süre',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}dk';
    return '${seconds ~/ 3600}sa';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFCAB7FF).withValues(alpha:0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6C6FA4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF394272),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6C6FA4),
          ),
        ),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final UserModel? user;

  const _PremiumCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isPremium = user?.isActivePremium ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFFFFD891), Color(0xFFFFB958)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPremium ? null : Colors.white.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium : Icons.star_border,
                size: 32,
                color: isPremium ? const Color(0xFF8C5A1F) : const Color(0xFF6C6FA4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Premium Üye' : 'Ücretsiz Üyelik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isPremium
                            ? const Color(0xFF8C5A1F)
                            : const Color(0xFF394272),
                      ),
                    ),
                    if (isPremium && user?.premiumExpiresAt != null)
                      Text(
                        'Bitiş: ${_formatDate(user!.premiumExpiresAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C5A1F),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (!isPremium) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Premium satın alma ekranına git
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB958),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Premium\'a Geç',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8C5A1F),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Kalan kelime değiştirme hakkı (reklam ile kazanılan)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.swap_horiz,
                size: 18,
                color: Color(0xFF6C6FA4),
              ),
              const SizedBox(width: 6),
              Text(
                'Ekstra Değiştirme Hakkı: ${user?.wordChangeCredits ?? 0}',
                style: TextStyle(
                  fontSize: 13,
                  color: isPremium
                      ? const Color(0xFF8C5A1F)
                      : const Color(0xFF6C6FA4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
