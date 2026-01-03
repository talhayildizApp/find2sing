import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/player_id_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _playerIdService = PlayerIdService();
  String? _playerId;
  bool _loadingPlayerId = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerId();
  }

  Future<void> _loadPlayerId() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid;
    if (uid == null) {
      setState(() => _loadingPlayerId = false);
      return;
    }

    final playerId = await _playerIdService.ensurePlayerId(uid);
    if (mounted) {
      setState(() {
        _playerId = playerId;
        _loadingPlayerId = false;
      });
    }
  }

  void _copyPlayerId() {
    if (_playerId == null) return;
    Clipboard.setData(ClipboardData(text: _playerId!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oyuncu ID kopyalandı!')),
    );
  }

  void _sharePlayerId() {
    if (_playerId == null) return;
    final link = 'find2sing://match?opponentId=$_playerId';
    Share.share(
      'Find2Sing\'de benimle oyna!\n\nOyuncu ID: $_playerId\n\nLink: $link',
      subject: 'Find2Sing Davet',
    );
  }

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
                // Üst bar - Geri + Home + Ayarlar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      // Geri butonu
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF394272),
                        ),
                        tooltip: 'Geri',
                      ),
                      
                      // Home butonu
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(
                          Icons.home_rounded,
                          color: Color(0xFF394272),
                        ),
                        tooltip: 'Ana Menü',
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
                        onPressed: () => _showSettingsSheet(context),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF394272),
                        ),
                        tooltip: 'Ayarlar',
                      ),
                      
                      // Denge için boşluk
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFCAB7FF),
                              backgroundImage: user?.photoUrl != null
                                  ? NetworkImage(user!.photoUrl!)
                                  : null,
                              child: user?.photoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showEditProfileDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF394272),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // İsim
                        Text(
                          user?.displayName ?? 'Oyuncu',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
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

                        const SizedBox(height: 20),

                        // Player ID Card
                        _buildPlayerIdCard(),

                        const SizedBox(height: 32),

                        // İstatistik kartları
                        _buildStatsCard(user),

                        const SizedBox(height: 24),

                        // Başarılar
                        _buildAchievementsSection(),

                        const SizedBox(height: 24),

                        // Çıkış yap butonu
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleLogout(context),
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Çıkış Yap',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

  Widget _buildPlayerIdCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCAB7FF), Color(0xFF9B7EDE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAB7FF).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.games, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'Oyuncu ID',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _loadingPlayerId
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  _playerId ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayerIdButton(Icons.copy, 'Kopyala', _copyPlayerId),
              const SizedBox(width: 12),
              _buildPlayerIdButton(Icons.share, 'Paylaş', _sharePlayerId),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu ID ile arkadaşlarınla online oynayabilirsin',
            style: TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIdButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                child: _buildStatItem(
                  icon: Icons.emoji_events,
                  label: 'En Yüksek Skor',
                  value: '${user?.highScore ?? 0}',
                  color: const Color(0xFFFFD700),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.games,
                  label: 'Toplam Oyun',
                  value: '${user?.gamesPlayed ?? 0}',
                  color: const Color(0xFFCAB7FF),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Doğru Tahmin',
                  value: '${user?.correctGuesses ?? 0}',
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF394272),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C6FA4),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Başarılar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementBadge('🎵', 'İlk Oyun', true),
              _buildAchievementBadge('🔥', '5 Seri', false),
              _buildAchievementBadge('⚡', '10 Seri', false),
              _buildAchievementBadge('🏆', '100 Puan', false),
              _buildAchievementBadge('🎯','Mükemmel', false),
              _buildAchievementBadge('👑', 'Şampiyon', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String emoji, String label, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFFCAB7FF).withValues(alpha:0.2)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? const Color(0xFFCAB7FF) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 20,
              color: unlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: unlocked ? const Color(0xFF394272) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await _showLogoutDialog(context);
    if (confirmed == true) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(color: Color(0xFF394272)),
        ),
        content: const Text(
          'Hesabından çıkış yapmak istediğine emin misin?',
          style: TextStyle(color: Color(0xFF6C6FA4)),
        ),
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
                _showPlaceholderDialog(context, 'Gizlilik Politikası');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF6C6FA4)),
              title: const Text('Kullanım Koşulları'),
              onTap: () {
                Navigator.pop(context);
                _showPlaceholderDialog(context, 'Kullanım Koşulları');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPlaceholderDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFF394272)),
        ),
        content: Text(
          '$title içeriği burada yer alacak.\n\n'
          'Bu içerik uygulama yayınlanmadan önce güncellenecektir.',
          style: const TextStyle(color: Color(0xFF6C6FA4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final controller = TextEditingController(text: user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Profili Düzenle',
          style: TextStyle(color: Color(0xFF394272)),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ad Soyad',
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
              if (controller.text.trim().isNotEmpty) {
                await context.read<AuthProvider>().updateProfile(
                      displayName: controller.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Dil Ayarları',
          style: TextStyle(color: Color(0xFF394272)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Türkçe'),
              trailing: const Icon(Icons.check, color: Color(0xFFCAB7FF)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              subtitle: const Text('Yakında'),
              enabled: false,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}
