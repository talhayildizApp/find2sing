import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/player_id_service.dart';
import '../../widgets/profile_ui_components.dart';

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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Oyuncu ID kopyalandı!'),
          ],
        ),
        backgroundColor: ProfileColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
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

  List<HeroStatData> _buildHeroStats(UserModel? user) {
    if (user == null) return [];

    final stats = <HeroStatData>[];

    // High score - always show
    stats.add(HeroStatData(
      label: 'En Yüksek Skor',
      value: '${user.highScore}',
      emoji: '🏆',
      color: ProfileColors.accentGold,
      subtitle: user.highScore > 50 ? 'Harika performans!' : null,
    ));

    // Total songs found
    if (user.totalSongsFound > 0) {
      stats.add(HeroStatData(
        label: 'Toplam Şarkı',
        value: '${user.totalSongsFound}',
        emoji: '🎵',
        color: ProfileColors.primaryPurple,
        subtitle: user.totalSongsFound > 100 ? 'Müzik uzmanı!' : null,
      ));
    }

    // Games played
    if (user.gamesPlayed > 0) {
      stats.add(HeroStatData(
        label: 'Oyun Sayısı',
        value: '${user.gamesPlayed}',
        emoji: '🎮',
        color: ProfileColors.success,
        subtitle: user.gamesPlayed > 20 ? 'Deneyimli oyuncu!' : null,
      ));
    }

    return stats;
  }

  List<QuickStatItem> _buildQuickStats(UserModel? user) {
    return [
      QuickStatItem(
        label: 'Toplam Oyun',
        value: '${user?.gamesPlayed ?? 0}',
        icon: Icons.videogame_asset_rounded,
        color: ProfileColors.primaryPurple,
      ),
      QuickStatItem(
        label: 'Bulunan Şarkı',
        value: '${user?.totalSongsFound ?? 0}',
        icon: Icons.music_note_rounded,
        color: ProfileColors.accentOrange,
      ),
      QuickStatItem(
        label: 'Toplam Süre',
        value: _formatPlayTime(user?.totalTimePlayed ?? 0),
        icon: Icons.timer_rounded,
        color: ProfileColors.success,
      ),
      QuickStatItem(
        label: 'Kelime Hakkı',
        value: '${user?.effectiveWordChangeCredits ?? 0}',
        icon: Icons.refresh_rounded,
        color: ProfileColors.accentGold,
      ),
    ];
  }

  String _formatPlayTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}dk';
    return '${seconds ~/ 3600}sa';
  }

  List<AchievementData> _buildAchievements(UserModel? user) {
    final gamesPlayed = user?.gamesPlayed ?? 0;
    final totalSongs = user?.totalSongsFound ?? 0;
    final highScore = user?.highScore ?? 0;

    return [
      AchievementData(
        emoji: '🎵',
        title: 'İlk Adım',
        description: 'İlk oyununu tamamla',
        progress: gamesPlayed > 0 ? 1.0 : 0.0,
        isUnlocked: gamesPlayed > 0,
        color: ProfileColors.primaryPurple,
      ),
      AchievementData(
        emoji: '🔥',
        title: 'Ateşli Başlangıç',
        description: '5 oyun tamamla',
        progress: (gamesPlayed / 5).clamp(0.0, 1.0),
        isUnlocked: gamesPlayed >= 5,
        color: ProfileColors.accentOrange,
      ),
      AchievementData(
        emoji: '⚡',
        title: 'Hız Ustası',
        description: '10 şarkı bul',
        progress: (totalSongs / 10).clamp(0.0, 1.0),
        isUnlocked: totalSongs >= 10,
        color: const Color(0xFF00BCD4),
      ),
      AchievementData(
        emoji: '🏆',
        title: 'Yüzlük Kulüp',
        description: '100 şarkı bul',
        progress: (totalSongs / 100).clamp(0.0, 1.0),
        isUnlocked: totalSongs >= 100,
        color: ProfileColors.accentGold,
      ),
      AchievementData(
        emoji: '🎯',
        title: 'Keskin Nişancı',
        description: 'Tek oyunda 20+ puan',
        progress: (highScore / 20).clamp(0.0, 1.0),
        isUnlocked: highScore >= 20,
        color: ProfileColors.success,
      ),
      AchievementData(
        emoji: '👑',
        title: 'Şampiyon',
        description: 'Tek oyunda 50+ puan',
        progress: (highScore / 50).clamp(0.0, 1.0),
        isUnlocked: highScore >= 50,
        color: const Color(0xFF9C27B0),
      ),
    ];
  }

  // Placeholder recent activities (in real app, fetch from Firestore)
  List<RecentActivityItem> _buildRecentActivities(UserModel? user) {
    // If no games played, return empty
    if (user == null || user.gamesPlayed == 0) return [];

    // Generate sample activities based on user stats
    // In a real implementation, these would come from a Firestore collection
    final activities = <RecentActivityItem>[];

    if (user.gamesPlayed >= 1) {
      activities.add(RecentActivityItem(
        gameType: 'Tekli Oyun',
        result: '${user.highScore} şarkı bulundu',
        score: user.highScore,
        date: user.lastLoginAt,
        isWin: user.highScore > 0,
      ));
    }

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return ProfileScaffold(
      onSettings: () => _showSettingsSheet(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Compact Profile Header
            StaggeredEntrance(
              index: 0,
              child: CompactProfileHeader(
                photoUrl: user?.photoUrl,
                displayName: user?.displayName ?? 'Oyuncu',
                email: user?.email ?? '',
                isPremium: user?.isActivePremium ?? false,
                onEditTap: () => _showEditProfileDialog(context),
              ),
            ),

            const SizedBox(height: 16),

            // Compact Player ID
            StaggeredEntrance(
              index: 1,
              child: CompactPlayerIdCard(
                playerId: _playerId,
                isLoading: _loadingPlayerId,
                onCopy: _copyPlayerId,
                onShare: _sharePlayerId,
              ),
            ),

            const SizedBox(height: 24),

            // Hero Stat (cycling)
            StaggeredEntrance(
              index: 2,
              child: HeroStatCard(
                stats: _buildHeroStats(user),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Stats Grid
            StaggeredEntrance(
              index: 3,
              child: QuickStatsGrid(
                stats: _buildQuickStats(user),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Activity
            StaggeredEntrance(
              index: 4,
              child: RecentActivitySection(
                activities: _buildRecentActivities(user),
                onSeeAll: user != null && user.gamesPlayed > 0
                    ? () {
                        // TODO: Navigate to full activity history
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Aktivite geçmişi yakında!'),
                          ),
                        );
                      }
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // Achievements
            StaggeredEntrance(
              index: 5,
              child: AchievementsSection(
                achievements: _buildAchievements(user),
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            StaggeredEntrance(
              index: 6,
              child: ProfileActionButton(
                label: 'Çıkış Yap',
                icon: Icons.logout_rounded,
                isDestructive: true,
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final confirmed = await _showLogoutDialog(context);
    if (confirmed == true && mounted) {
      await authProvider.signOut();
      if (mounted) {
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProfileColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: ProfileColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Çıkış Yap',
              style: TextStyle(
                color: ProfileColors.darkPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Hesabından çıkış yapmak istediğine emin misin?',
          style: TextStyle(color: ProfileColors.subtleText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'İptal',
              style: TextStyle(color: ProfileColors.subtleText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
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
                'Ayarlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ProfileColors.darkPurple,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                icon: Icons.edit_rounded,
                label: 'Profili Düzenle',
                onTap: () {
                  Navigator.pop(context);
                  _showEditProfileDialog(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.language_rounded,
                label: 'Dil Ayarları',
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageDialog(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.privacy_tip_rounded,
                label: 'Gizlilik Politikası',
                onTap: () {
                  Navigator.pop(context);
                  _showPlaceholderDialog(context, 'Gizlilik Politikası');
                },
              ),
              _buildSettingsItem(
                icon: Icons.description_rounded,
                label: 'Kullanım Koşulları',
                onTap: () {
                  Navigator.pop(context);
                  _showPlaceholderDialog(context, 'Kullanım Koşulları');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ProfileColors.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: ProfileColors.primaryPurple, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: ProfileColors.darkPurple,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: ProfileColors.subtleText,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  void _showPlaceholderDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: ProfileColors.darkPurple,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '$title içeriği burada yer alacak.\n\n'
          'Bu içerik uygulama yayınlanmadan önce güncellenecektir.',
          style: const TextStyle(color: ProfileColors.subtleText),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProfileColors.primaryPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: ProfileColors.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Profili Düzenle',
              style: TextStyle(
                color: ProfileColors.darkPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Ad Soyad',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ProfileColors.primaryPurple,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: ProfileColors.subtleText),
            ),
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
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Profil güncellendi'),
                        ],
                      ),
                      backgroundColor: ProfileColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Kaydet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProfileColors.primaryPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: ProfileColors.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dil Ayarları',
              style: TextStyle(
                color: ProfileColors.darkPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              flag: '🇹🇷',
              name: 'Türkçe',
              isSelected: true,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              flag: '🇬🇧',
              name: 'English',
              isSelected: false,
              isDisabled: true,
              subtitle: 'Yakında',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? ProfileColors.primaryPurple.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ProfileColors.primaryPurple.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? Colors.grey
                          : ProfileColors.darkPurple,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: ProfileColors.primaryPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
