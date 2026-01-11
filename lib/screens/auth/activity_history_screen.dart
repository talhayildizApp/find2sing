// lib/screens/auth/activity_history_screen.dart
//
// Kullanıcının detaylı aktivite geçmişi ve istatistikleri

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                  const Color(0xFFF5F0FF).withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: user == null
                      ? _buildEmptyState()
                      : _buildContent(context, user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF394272),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Aktivite Geçmişi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: const Color(0xFF394272).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz aktivite yok',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF394272).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet Kartı
          _buildSummaryCard(user),
          const SizedBox(height: 20),

          // Detaylı İstatistikler
          _buildSectionTitle('Detaylı İstatistikler'),
          const SizedBox(height: 12),
          _buildDetailedStats(user),
          const SizedBox(height: 20),

          // Üyelik Bilgileri
          _buildSectionTitle('Üyelik Bilgileri'),
          const SizedBox(height: 12),
          _buildMembershipInfo(user),
          const SizedBox(height: 20),

          // Satın Almalar
          if (user.purchasedCategories.isNotEmpty ||
              user.purchasedChallenges.isNotEmpty) ...[
            _buildSectionTitle('Satın Almalar'),
            const SizedBox(height: 12),
            _buildPurchasesInfo(user),
            const SizedBox(height: 20),
          ],

          // Joker Durumu
          _buildSectionTitle('Joker Durumu'),
          const SizedBox(height: 12),
          _buildJokerStatus(user),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF394272),
      ),
    );
  }

  Widget _buildSummaryCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCAB7FF), Color(0xFF9B8DFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAB7FF).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.games_rounded,
                value: '${user.totalGamesPlayed}',
                label: 'Toplam Oyun',
              ),
              _buildSummaryItem(
                icon: Icons.music_note_rounded,
                value: '${user.totalSongsFound}',
                label: 'Bulunan Şarkı',
              ),
              _buildSummaryItem(
                icon: Icons.timer_rounded,
                value: _formatPlayTime(user.totalTimePlayed),
                label: 'Oynama Süresi',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(UserModel user) {
    final avgScore = user.totalGamesPlayed > 0
        ? (user.totalSongsFound / user.totalGamesPlayed).toStringAsFixed(1)
        : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Ortalama Skor',
            '$avgScore şarkı/oyun',
            Icons.analytics_rounded,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'İzlenen Reklam',
            '${user.totalAdsWatched} adet',
            Icons.play_circle_rounded,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Kayıt Tarihi',
            _formatDate(user.createdAt),
            Icons.calendar_today_rounded,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Son Giriş',
            _formatDate(user.lastLoginAt),
            Icons.login_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFCAB7FF), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C6FA4),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF394272),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipInfo(UserModel user) {
    final tierConfig = user.tierConfig;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                tierConfig.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierConfig.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF394272),
                      ),
                    ),
                    if (user.isActivePremium && user.premiumExpiresAt != null)
                      Text(
                        'Bitiş: ${_formatDate(user.premiumExpiresAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C6FA4),
                        ),
                      ),
                  ],
                ),
              ),
              if (user.isActivePremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFB958),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _buildBenefitRow(
            'Reklamsız Oyun',
            !tierConfig.showEndGameAd,
          ),
          const SizedBox(height: 8),
          _buildBenefitRow(
            'Tüm Challenge\'lara Erişim',
            tierConfig.hasFullAccess,
          ),
          const SizedBox(height: 8),
          _buildBenefitRow(
            'Sınırsız Joker',
            user.isActivePremium,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String label, bool hasAccess) {
    return Row(
      children: [
        Icon(
          hasAccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: hasAccess ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: hasAccess
                ? const Color(0xFF394272)
                : const Color(0xFF6C6FA4).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasesInfo(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.purchasedCategories.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.folder_rounded,
                  color: Color(0xFFCAB7FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.purchasedCategories.length} Kategori',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF394272),
                  ),
                ),
              ],
            ),
            if (user.purchasedChallenges.isNotEmpty) const SizedBox(height: 12),
          ],
          if (user.purchasedChallenges.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFB958),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.purchasedChallenges.length} Challenge',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF394272),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildJokerStatus(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Kelime Değiştirme Hakları
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFFCAB7FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelime Değiştirme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF394272),
                      ),
                    ),
                    Text(
                      'Tek başına & Arkadaşla modu',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C6FA4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.isActivePremium
                      ? '∞'
                      : '${user.effectiveWordChangeCredits}/${UserModel.maxWordChangeCredits}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCAB7FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Challenge Jokerleri
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB958),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Challenge Jokerleri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF394272),
                      ),
                    ),
                    Text(
                      'Challenge modunda kullanılır',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C6FA4),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  UserModel.maxChallengeJokers,
                  (index) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: user.isActivePremium ||
                              user.isChallengeJokerActive(index)
                          ? const Color(0xFFFFB958)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPlayTime(int seconds) {
    if (seconds < 60) return '${seconds}sn';
    if (seconds < 3600) return '${(seconds / 60).floor()}dk';
    final hours = (seconds / 3600).floor();
    final mins = ((seconds % 3600) / 60).floor();
    return '${hours}sa ${mins}dk';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
