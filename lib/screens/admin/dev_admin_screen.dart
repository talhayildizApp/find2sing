import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_content_service.dart';
import '../../services/admin_auth_service.dart';
import '../../services/lyrics_keyword_service.dart';

class DevAdminScreen extends StatefulWidget {
  const DevAdminScreen({super.key});

  @override
  State<DevAdminScreen> createState() => _DevAdminScreenState();
}

class _DevAdminScreenState extends State<DevAdminScreen> with SingleTickerProviderStateMixin {
  final AdminContentService _admin = AdminContentService();
  final AdminAuthService _adminAuth = AdminAuthService.instance;
  final LyricsKeywordService _kw = LyricsKeywordService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late TabController _tabController;

  // Stats
  int _categoryCount = 0;
  int _challengeCount = 0;
  int _songCount = 0;
  int _wordIndexCount = 0;
  int _userCount = 0;
  int _premiumUsers = 0;
  int _dauUsers = 0;
  int _wauUsers = 0;
  int _todayRegistrations = 0;
  int _totalGamesPlayed = 0;
  int _totalSongsFound = 0;
  int _avgGameTime = 0;
  bool _loadingStats = false;
  bool _isAdmin = false;
  bool _checkingAdmin = true;

  // Filters
  String? _selectedCategoryFilter;
  String? _selectedChallengeFilter;
  String _searchQuery = '';
  String _activeFilter = 'all'; // all, active, inactive
  String _sortBy = 'name'; // name, date, count

  // Modern Color Palette - Premium Dark Theme
  static const _bgDark = Color(0xFF0A0A0F);
  static const _bgCard = Color(0xFF12121A);
  static const _bgElevated = Color(0xFF1A1A24);
  static const _bgGlass = Color(0xFF1E1E2A);
  static const _accent = Color(0xFF8B5CF6);
  static const _accentLight = Color(0xFFA78BFA);
  static const _accentGreen = Color(0xFF10B981);
  static const _accentRed = Color(0xFFEF4444);
  static const _accentOrange = Color(0xFFF59E0B);
  static const _accentBlue = Color(0xFF3B82F6);
  static const _accentPink = Color(0xFFEC4899);
  static const _accentCyan = Color(0xFF06B6D4);
  static const _textPrimary = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFF71717A);
  static const _textMuted = Color(0xFF52525B);
  static const _border = Color(0xFF27272A);
  static const _borderLight = Color(0xFF3F3F46);

  // Bulk selection states
  Set<String> _selectedChallenges = {};
  bool _bulkSelectMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) _loadStats();
      setState(() {});
    });
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    final isAdmin = await _adminAuth.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _checkingAdmin = false;
      });
      if (isAdmin) {
        _loadStats();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      // Basic counts
      final cats = await _db.collection('categories').count().get();
      final chals = await _db.collection('challenges').count().get();
      final songs = await _db.collection('songs').count().get();
      final words = await _db.collection('challengeWordIndex').count().get();

      // User metrics
      final usersSnapshot = await _db.collection('users').get();
      final users = usersSnapshot.docs.map((d) => d.data()).toList();

      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final todayStart = DateTime(now.year, now.month, now.day);

      int premiumCount = 0;
      int dauCount = 0;
      int wauCount = 0;
      int todayReg = 0;
      int totalGames = 0;
      int totalSongs = 0;
      int totalTime = 0;

      for (final user in users) {
        if (user['isPremium'] == true) premiumCount++;

        final lastLogin = (user['lastLoginAt'] as Timestamp?)?.toDate();
        if (lastLogin != null) {
          if (lastLogin.isAfter(oneDayAgo)) dauCount++;
          if (lastLogin.isAfter(oneWeekAgo)) wauCount++;
        }

        final createdAt = (user['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && createdAt.isAfter(todayStart)) {
          todayReg++;
        }

        totalGames += (user['gamesPlayed'] as int?) ?? 0;
        totalSongs += (user['totalSongsFound'] as int?) ?? 0;
        totalTime += (user['totalTimePlayed'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _categoryCount = cats.count ?? 0;
          _challengeCount = chals.count ?? 0;
          _songCount = songs.count ?? 0;
          _wordIndexCount = words.count ?? 0;
          _userCount = users.length;
          _premiumUsers = premiumCount;
          _dauUsers = dauCount;
          _wauUsers = wauCount;
          _todayRegistrations = todayReg;
          _totalGamesPlayed = totalGames;
          _totalSongsFound = totalSongs;
          _avgGameTime = totalGames > 0 ? (totalTime ~/ totalGames) : 0;
        });
      }
    } catch (e) {
      debugPrint('Stats error: $e');
    }
    if (mounted) setState(() => _loadingStats = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin) {
      return Scaffold(
        backgroundColor: _bgDark,
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: _bgCard,
          foregroundColor: _textPrimary,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentRed.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _accentRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 48, color: _accentRed),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erişim Reddedildi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${FirebaseAuth.instance.currentUser?.email ?? "Giriş yapılmamış"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgDark,
      body: Column(
        children: [
          // Premium Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgCard, _bgElevated],
              ),
              boxShadow: [
                BoxShadow(color: _accent.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // Logo with glow
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_accent, _accentPink],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.admin_panel_settings, size: 22, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Admin Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary, letterSpacing: -0.5)),
                            Text('Find2Sing Yönetim', style: TextStyle(fontSize: 12, color: _textSecondary)),
                          ],
                        ),
                        const Spacer(),
                        // Refresh button with animation
                        _buildHeaderButton(
                          icon: _loadingStats ? null : Icons.refresh_rounded,
                          isLoading: _loadingStats,
                          onTap: _loadStats,
                        ),
                      ],
                    ),
                  ),
                  // Modern Tab Bar
                  Container(
                    height: 52,
                    margin: const EdgeInsets.only(bottom: 2),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: _textPrimary,
                      unselectedLabelColor: _textMuted,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.2), _accentPink.withValues(alpha: 0.1)]),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tabs: [
                        _buildTab(Icons.dashboard_rounded, 'Dashboard', 0),
                        _buildTab(Icons.category_rounded, 'Kategoriler', 1),
                        _buildTab(Icons.emoji_events_rounded, 'Challenge', 2),
                        _buildTab(Icons.music_note_rounded, 'Şarkılar', 3),
                        _buildTab(Icons.people_rounded, 'Kullanıcılar', 4),
                        _buildTab(Icons.notifications_rounded, 'Bildirim', 5),
                        _buildTab(Icons.swap_vert_rounded, 'Sıralama', 6),
                        _buildTab(Icons.add_circle_rounded, 'Ekle', 7),
                        _buildTab(Icons.upload_file_rounded, 'Import', 8),
                        _buildTab(Icons.build_rounded, 'Araçlar', 9),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                _buildCategories(),
                _buildChallenges(),
                _buildSongs(),
                _buildUsers(),
                _buildNotifications(),
                _buildSorting(),
                _buildSongBuilder(),
                _buildImport(),
                _buildTools(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HEADER HELPERS ====================
  Widget _buildHeaderButton({IconData? icon, bool isLoading = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _bgGlass,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderLight.withValues(alpha: 0.3)),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
            : Icon(icon, size: 20, color: _textSecondary),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    final isSelected = _tabController.index == index;
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? _accentLight : _textMuted),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.15),
            _accentPink.withValues(alpha: 0.1),
            _accentBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş Geldin, Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find2Sing içeriklerini buradan yönetebilirsin.',
                  style: TextStyle(fontSize: 14, color: _textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent, _accentPink]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        _buildQuickStatCard('Kategoriler', _categoryCount, Icons.category_rounded, _accentBlue),
        const SizedBox(width: 12),
        _buildQuickStatCard('Challenge', _challengeCount, Icons.emoji_events_rounded, _accentOrange),
        const SizedBox(width: 12),
        _buildQuickStatCard('Şarkılar', _songCount, Icons.music_note_rounded, _accentGreen),
        const SizedBox(width: 12),
        _buildQuickStatCard('Word Index', _wordIndexCount, Icons.text_fields_rounded, _accentPink),
      ],
    );
  }

  Widget _buildQuickStatCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary),
                  ),
                  Text(label, style: const TextStyle(fontSize: 11, color: _textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricItem('Toplam Kullanıcı', _userCount, Icons.people_alt_rounded, _accentBlue),
              const SizedBox(width: 16),
              _buildMetricItem('DAU', _dauUsers, Icons.today_rounded, _accentGreen),
              const SizedBox(width: 16),
              _buildMetricItem('WAU', _wauUsers, Icons.date_range_rounded, _accent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricItem('Premium', _premiumUsers, Icons.star_rounded, _accentOrange),
              const SizedBox(width: 16),
              _buildMetricItem('Bugün Kayıt', _todayRegistrations, Icons.person_add_rounded, _accentPink),
              const SizedBox(width: 16),
              Expanded(child: Container()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
                Text(label, style: const TextStyle(fontSize: 11, color: _textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DASHBOARD ====================
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          _buildWelcomeBanner(),
          const SizedBox(height: 24),

          // Quick Stats Row
          _buildQuickStatsRow(),
          const SizedBox(height: 24),

          // User Metrics Section
          _sectionHeader('Kullanıcı Metrikleri', Icons.people_alt_rounded),
          const SizedBox(height: 16),
          _buildUserMetricsGrid(),

          const SizedBox(height: 28),

          // Game Metrics Section
          _sectionHeader('Oyun Metrikleri', Icons.sports_esports_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgCard, _bgElevated.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _metricTile('Toplam Oyun', _totalGamesPlayed.toString(), Icons.sports_esports, _accentBlue)),
                    const SizedBox(width: 16),
                    Expanded(child: _metricTile('Bulunan Şarkı', _totalSongsFound.toString(), Icons.music_note, _accentGreen)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _metricTile('Ort. Süre', _formatDuration(_avgGameTime), Icons.timer, _accent)),
                    const SizedBox(width: 16),
                    Expanded(child: _metricTile('Ort. Şarkı/Oyun', _totalGamesPlayed > 0 ? (_totalSongsFound / _totalGamesPlayed).toStringAsFixed(1) : '0', Icons.leaderboard, _accentOrange)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Content Stats & Category Distribution
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content Overview Chart
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('İçerik Dağılımı', Icons.pie_chart_rounded),
                    const SizedBox(height: 16),
                    _buildContentChart(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Top Categories
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Popüler Kategoriler', Icons.trending_up_rounded),
                    const SizedBox(height: 16),
                    _buildTopCategories(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Two Column Layout: Quick Start + Recent Challenges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Start Guide
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Hızlı Başlangıç', Icons.rocket_launch_rounded),
                    const SizedBox(height: 16),
                    _quickStartCard(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Recent Challenges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Son Challenge\'lar', Icons.history_rounded),
                    const SizedBox(height: 16),
                    _recentChallenges(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}sn';
    if (seconds < 3600) return '${seconds ~/ 60}dk ${seconds % 60}sn';
    return '${seconds ~/ 3600}sa ${(seconds % 3600) ~/ 60}dk';
  }

  Widget _sectionHeader(String t, IconData i) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.2), _accentPink.withValues(alpha: 0.1)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(i, color: _accentLight, size: 18),
          ),
          const SizedBox(width: 12),
          Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: -0.3)),
        ],
      );

  Widget _buildContentChart() {
    final total = _categoryCount + _challengeCount + _songCount;
    if (total == 0) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
        child: const Center(child: Text('Veri yok', style: TextStyle(color: _textSecondary))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Bar chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChartBar('Kategori', _categoryCount, total, _accentBlue),
              _buildChartBar('Challenge', _challengeCount, total, _accentGreen),
              _buildChartBar('Şarkı', _songCount, total, _accentOrange),
              _buildChartBar('Index', _wordIndexCount, total > 0 ? total : 1, _accentPink),
            ],
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend('Kategori', _accentBlue),
              const SizedBox(width: 16),
              _chartLegend('Challenge', _accentGreen),
              const SizedBox(width: 16),
              _chartLegend('Şarkı', _accentOrange),
              const SizedBox(width: 16),
              _chartLegend('Index', _accentPink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, int value, int total, Color color) {
    final maxHeight = 100.0;
    final percentage = total > 0 ? (value / total).clamp(0.05, 1.0) : 0.05;
    final height = maxHeight * percentage;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
        ),
      ],
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildTopCategories() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('categories').orderBy('sortOrder').limit(5).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)));
          }
          final cats = snap.data!.docs;
          if (cats.isEmpty) {
            return const SizedBox(height: 150, child: Center(child: Text('Kategori yok', style: TextStyle(color: _textSecondary))));
          }

          return Column(
            children: cats.asMap().entries.map((e) {
              final i = e.key;
              final d = e.value.data() as Map<String, dynamic>;
              return _topCategoryItem(i + 1, d['title'] ?? e.value.id, d['iconEmoji'] ?? '🎵', _getCategoryColor(i));
            }).toList(),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [_accentGreen, _accentBlue, _accentOrange, _accentPink, _accent];
    return colors[index % colors.length];
  }

  Widget _topCategoryItem(int rank, String title, String emoji, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('#$rank', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _quickStartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accentOrange, _accentOrange.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('İçerik Ekleme Rehberi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          _stepItem(1, 'Kategori oluştur', 'Türkçe Pop, Rock vb.', _accentBlue),
          _stepItem(2, 'Challenge ekle', 'Sanatçı challenge\'ı', _accentGreen),
          _stepItem(3, 'Şarkıları gir', 'Import tab kullan', _accentOrange),
          _stepItem(4, 'Word Index oluştur', 'Build butonu', _accentPink),
        ],
      ),
    );
  }

  Widget _stepItem(int s, String t, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(s.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                Text(sub, style: const TextStyle(color: _textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentChallenges() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('challenges').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return Container(
            height: 200,
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
            child: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
            child: _emptyState('Henüz challenge yok', Icons.emoji_events_outlined),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(color: _border.withValues(alpha: 0.5), height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final cnt = d['totalSongs'] ?? 0;
              final active = d['isActive'] ?? true;
              final featured = d['isFeatured'] ?? false;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: active
                        ? [_accentGreen.withValues(alpha: 0.2), _accentGreen.withValues(alpha: 0.1)]
                        : [_textSecondary.withValues(alpha: 0.2), _textSecondary.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      cnt.toString(),
                      style: TextStyle(color: active ? _accentGreen : _textSecondary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(d['title'] ?? docs[i].id, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis)),
                    if (featured) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.star_rounded, size: 12, color: _accentOrange),
                      ),
                    ],
                  ],
                ),
                subtitle: Text('${d['categoryId'] ?? '-'} • $cnt şarkı', style: const TextStyle(color: _textSecondary, fontSize: 11)),
                trailing: _statusBadge(active),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== CATEGORIES ====================
  Widget _buildCategories() {
    return Column(
      children: [
        _listHeader('Kategoriler', _categoryCount, () => _openCategoryDialog(null), 'Yeni Kategori'),
        _buildSearchAndFilterBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('categories').orderBy('sortOrder').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
              var docs = snap.data!.docs;

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              // Apply active filter
              if (_activeFilter != 'all') {
                final isActive = _activeFilter == 'active';
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['isActive'] ?? true) == isActive;
                }).toList();
              }

              // Sort
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                switch (_sortBy) {
                  case 'count':
                    return ((bData['sortOrder'] ?? 0) as int).compareTo((aData['sortOrder'] ?? 0) as int);
                  case 'date':
                    final aDate = aData['createdAt'] as Timestamp?;
                    final bDate = bData['createdAt'] as Timestamp?;
                    return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(aDate?.millisecondsSinceEpoch ?? 0);
                  default:
                    return (aData['title'] ?? '').toString().compareTo((bData['title'] ?? '').toString());
                }
              });

              if (docs.isEmpty) return _emptyState('Kategori bulunamadı', Icons.category_outlined);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) => _categoryCard(docs[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search_rounded, color: _textSecondary.withValues(alpha: 0.7), size: 20),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort Button
          _buildFilterButton(
            icon: Icons.swap_vert_rounded,
            label: _sortLabel,
            isActive: _sortBy != 'name',
            onTap: () => _showSortMenu(),
          ),
          const SizedBox(width: 8),
          // Filter Button
          _buildFilterButton(
            icon: Icons.filter_list_rounded,
            label: _activeFilter == 'all' ? 'Filtre' : (_activeFilter == 'active' ? 'Aktif' : 'Pasif'),
            isActive: _activeFilter != 'all',
            activeColor: _activeFilter == 'active' ? _accentGreen : (_activeFilter == 'inactive' ? _accentRed : null),
            onTap: () => _showFilterMenu(),
          ),
          const SizedBox(width: 8),
          // Bulk Select Button
          _buildFilterButton(
            icon: _bulkSelectMode ? Icons.close_rounded : Icons.checklist_rounded,
            label: _bulkSelectMode ? 'İptal' : 'Seç',
            isActive: _bulkSelectMode,
            onTap: () => setState(() {
              _bulkSelectMode = !_bulkSelectMode;
              if (!_bulkSelectMode) _selectedChallenges.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({required IconData icon, required String label, bool isActive = false, Color? activeColor, required VoidCallback onTap}) {
    final color = activeColor ?? _accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : _bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color.withValues(alpha: 0.3) : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : _textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isActive ? color : _textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Sıralama', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSortOption('name', 'Ada Göre', Icons.sort_by_alpha_rounded),
            _buildSortOption('date', 'Tarihe Göre', Icons.calendar_today_rounded),
            _buildSortOption('count', 'Sayıya Göre', Icons.numbers_rounded),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withValues(alpha: 0.15) : _bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _accent.withValues(alpha: 0.3) : _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _accent : _textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isSelected ? _accent : _textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_rounded, color: _accent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Filtrele', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFilterOption('all', 'Tümü', Icons.apps_rounded, _textSecondary),
            _buildFilterOption('active', 'Aktif', Icons.check_circle_rounded, _accentGreen),
            _buildFilterOption('inactive', 'Pasif', Icons.cancel_rounded, _accentRed),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String value, String label, IconData icon, Color color) {
    final isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _activeFilter = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : _bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.3) : _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : _textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isSelected ? color : _textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'date':
        return 'Tarih';
      case 'count':
        return 'Sayı';
      default:
        return 'Ad';
    }
  }

  Widget _categoryCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final active = d['isActive'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? _border : _border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCategoryDialog(doc),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_accent.withValues(alpha: 0.2), _accentPink.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withValues(alpha: 0.2)),
                  ),
                  child: Center(child: Text(d['iconEmoji'] ?? '🎵', style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d['title'] ?? doc.id,
                              style: TextStyle(
                                color: active ? _textPrimary : _textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _statusBadge(active),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _modernTag(d['language']?.toUpperCase() ?? 'TR', _accentBlue),
                          _modernTag(d['type'] ?? 'playlist', _accent),
                          _modernTag('Sıra: ${d['sortOrder'] ?? 0}', _textSecondary),
                          _modernTag('%${(d['discountPercent'] ?? 40.0).toStringAsFixed(0)} İnd.', _accentCyan),
                          if ((d['priceUsd'] ?? 0.0) > 0)
                            _modernTag('Manuel: \$${(d['priceUsd'] as num).toStringAsFixed(2)}', _accentOrange)
                          else
                            _modernTag('Otomatik Fiyat', _accentGreen),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions
                _buildCardActions([
                  _CardAction(Icons.edit_rounded, 'Düzenle', _accent, () => _openCategoryDialog(doc)),
                  _CardAction(Icons.delete_rounded, 'Sil', _accentRed, () => _deleteCategory(doc.id)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildCardActions(List<_CardAction> actions) {
    return PopupMenuButton<int>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: const Icon(Icons.more_horiz_rounded, color: _textSecondary, size: 18),
      ),
      color: _bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 40),
      onSelected: (i) => actions[i].onTap(),
      itemBuilder: (_) => actions.asMap().entries.map((e) => PopupMenuItem(
        value: e.key,
        child: Row(
          children: [
            Icon(e.value.icon, size: 18, color: e.value.color),
            const SizedBox(width: 12),
            Text(e.value.label, style: TextStyle(color: e.value.color, fontWeight: FontWeight.w500)),
          ],
        ),
      )).toList(),
    );
  }

  // ==================== CHALLENGES ====================
  Widget _buildChallenges() {
    return Column(
      children: [
        _listHeader('Challenge\'lar', _challengeCount, () => _openChallengeDialog(null), 'Yeni Challenge', filterWidget: _categoryDropdown()),
        _buildSearchAndFilterBar(),
        // Bulk action bar
        if (_bulkSelectMode && _selectedChallenges.isNotEmpty) _buildBulkActionBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedCategoryFilter != null
                ? _db.collection('challenges').where('categoryId', isEqualTo: _selectedCategoryFilter).snapshots()
                : _db.collection('challenges').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
              var docs = snap.data!.docs;

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final artist = (data['artist'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery.toLowerCase()) || artist.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              // Apply active filter
              if (_activeFilter != 'all') {
                final isActive = _activeFilter == 'active';
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['isActive'] ?? true) == isActive;
                }).toList();
              }

              // Sort
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                switch (_sortBy) {
                  case 'count':
                    return ((bData['totalSongs'] ?? 0) as int).compareTo((aData['totalSongs'] ?? 0) as int);
                  case 'date':
                    final aDate = aData['createdAt'] as Timestamp?;
                    final bDate = bData['createdAt'] as Timestamp?;
                    return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(aDate?.millisecondsSinceEpoch ?? 0);
                  default:
                    return (aData['title'] ?? '').toString().compareTo((bData['title'] ?? '').toString());
                }
              });

              if (docs.isEmpty) return _emptyState('Challenge bulunamadı', Icons.emoji_events_outlined);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) => _challengeCard(docs[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.15), _accentPink.withValues(alpha: 0.1)]),
        border: Border(bottom: BorderSide(color: _accent.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text('${_selectedChallenges.length} seçili', style: const TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const Spacer(),
          _bulkActionBtn(Icons.check_circle_rounded, 'Aktif Yap', _accentGreen, () => _bulkUpdateChallenges(true)),
          const SizedBox(width: 8),
          _bulkActionBtn(Icons.cancel_rounded, 'Pasif Yap', _accentOrange, () => _bulkUpdateChallenges(false)),
          const SizedBox(width: 8),
          _bulkActionBtn(Icons.delete_rounded, 'Sil', _accentRed, _bulkDeleteChallenges),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() {
              _bulkSelectMode = false;
              _selectedChallenges.clear();
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
              child: const Icon(Icons.close_rounded, color: _textSecondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulkActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkUpdateChallenges(bool isActive) async {
    if (_selectedChallenges.isEmpty) return;
    _loadingDialog('Güncelleniyor...');
    try {
      final batch = _db.batch();
      for (final id in _selectedChallenges) {
        batch.update(_db.collection('challenges').doc(id), {'isActive': isActive});
      }
      await batch.commit();
      if (mounted) Navigator.pop(context);
      _snack('${_selectedChallenges.length} challenge ${isActive ? 'aktif' : 'pasif'} yapıldı', success: true);
      setState(() {
        _selectedChallenges.clear();
        _bulkSelectMode = false;
      });
      _loadStats();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _snack('Hata: $e', error: true);
    }
  }

  Future<void> _bulkDeleteChallenges() async {
    if (_selectedChallenges.isEmpty) return;
    final c = await _confirmDialog('Toplu Sil', '${_selectedChallenges.length} challenge silinecek. Devam?', danger: true);
    if (c != true) return;
    _loadingDialog('Siliniyor...');
    try {
      for (final id in _selectedChallenges) {
        await _admin.deleteChallenge(id, deleteSongsToo: true);
      }
      if (mounted) Navigator.pop(context);
      _snack('${_selectedChallenges.length} challenge silindi', success: true);
      setState(() {
        _selectedChallenges.clear();
        _bulkSelectMode = false;
      });
      _loadStats();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _snack('Hata: $e', error: true);
    }
  }

  Widget _challengeCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final cnt = d['totalSongs'] ?? 0;
    final active = d['isActive'] ?? true;
    final free = d['isFree'] ?? false;
    final featured = d['isFeatured'] ?? false;
    final isSelected = _selectedChallenges.contains(doc.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSelected ? _accent : (featured ? _accentOrange.withValues(alpha: 0.3) : _border)),
        boxShadow: featured ? [BoxShadow(color: _accentOrange.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Bulk select checkbox
                if (_bulkSelectMode)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedChallenges.remove(doc.id);
                        } else {
                          _selectedChallenges.add(doc.id);
                        }
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : _bgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? _accent : _border),
                      ),
                      child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                    ),
                  ),
                // Song Count Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: active
                        ? [_accentGreen.withValues(alpha: 0.25), _accentGreen.withValues(alpha: 0.1)]
                        : [_textSecondary.withValues(alpha: 0.2), _textSecondary.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? _accentGreen.withValues(alpha: 0.3) : _border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cnt.toString(), style: TextStyle(color: active ? _accentGreen : _textSecondary, fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('şarkı', style: TextStyle(color: active ? _accentGreen.withValues(alpha: 0.7) : _textMuted, fontSize: 9)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d['title'] ?? doc.id,
                              style: TextStyle(
                                color: active ? _textPrimary : _textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (featured) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_accentOrange, _accentOrange.withValues(alpha: 0.8)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _modernTag(d['categoryId'] ?? '-', _accentBlue),
                          if (free)
                            _modernTag('ÜCRETSİZ', _accentGreen)
                          else if ((d['priceUsd'] ?? 0.0) > 0)
                            _modernTag('\$${(d['priceUsd'] as num).toStringAsFixed(2)}', _accentOrange),
                          _statusBadge(active),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _bgElevated.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: _border.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                _modernActionBtn(Icons.add_rounded, 'Şarkı', _accentGreen, () => _quickAddSongToChallenge(doc.id, d['categoryId'] ?? '')),
                const SizedBox(width: 8),
                _modernActionBtn(Icons.sync_rounded, 'Index', _accentBlue, () => _buildWordIndex(doc.id)),
                const SizedBox(width: 8),
                _modernActionBtn(Icons.edit_rounded, 'Düzenle', _accent, () => _openChallengeDialog(doc)),
                const SizedBox(width: 8),
                _modernActionBtn(Icons.delete_rounded, 'Sil', _accentRed, () => _deleteChallenge(doc.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SONGS ====================
  Widget _buildSongs() {
    return Column(
      children: [
        _listHeader('Şarkılar', _songCount, _selectedChallengeFilter != null ? () => _openSongDialog(null) : null, 'Yeni Şarkı', filterWidget: _challengeDropdown()),
        if (_selectedChallengeFilter != null) _buildSearchAndFilterBar(),
        if (_selectedChallengeFilter == null)
          Expanded(child: _emptyState('Lütfen bir challenge seçin', Icons.filter_list))
        else
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('songs').where('challengeId', isEqualTo: _selectedChallengeFilter).snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
                var docs = snap.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    final artist = (data['artist'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery.toLowerCase()) || artist.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) return _emptyState('Şarkı bulunamadı', Icons.music_note_outlined);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) => _songCard(docs[i], i + 1),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _songCard(DocumentSnapshot doc, int idx) {
    final d = doc.data() as Map<String, dynamic>;
    final kw = (d['keywords'] as List?)?.length ?? 0;
    final top = (d['topKeywords'] as List?)?.length ?? 0;
    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDialog('Şarkı Sil', '${d['title']} şarkısını silmek istediğinize emin misiniz?'),
      onDismissed: (_) => _deleteSong(doc.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: _accentRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: _accentRed),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(idx.toString(), style: const TextStyle(color: _accent, fontWeight: FontWeight.bold))),
          ),
          title: Text(d['title'] ?? doc.id, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d['artist'] ?? '-', style: const TextStyle(color: _textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Row(children: [_miniTag('$kw keyword', _accentBlue), const SizedBox(width: 8), _miniTag('$top top', _accentGreen)]),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_note, color: _accentBlue, size: 22), onPressed: () => _openKeywordEditor(doc)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: _textSecondary),
                color: _bgElevated,
                onSelected: (v) {
                  if (v == 'edit') _openSongDialog(doc);
                  if (v == 'delete') _deleteSong(doc.id);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: _textSecondary), SizedBox(width: 8), Text('Düzenle', style: TextStyle(color: _textPrimary))])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: _accentRed), SizedBox(width: 8), Text('Sil', style: TextStyle(color: _accentRed))])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SONG BUILDER ====================
  Widget _buildSongBuilder() {
    return _SongBuilderTab(
      admin: _admin,
      kw: _kw,
      db: _db,
      onSongAdded: _loadStats,
    );
  }

  // ==================== IMPORT ====================
  Widget _buildImport() {
    return _ImportTab(
      admin: _admin,
      kw: _kw,
      db: _db,
      onImportComplete: _loadStats,
    );
  }

  // ==================== USERS ====================
  Widget _buildUsers() {
    return Column(
      children: [
        _listHeader('Kullanıcılar', _userCount, null, ''),
        _buildUserSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').orderBy('createdAt', descending: true).limit(100).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
              var docs = snap.data!.docs;

              // Apply search
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  return email.contains(_searchQuery.toLowerCase()) || name.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              if (docs.isEmpty) return _emptyState('Kullanıcı bulunamadı', Icons.people_outline);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (ctx, i) => _userCard(docs[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.5))),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Email veya isim ara...',
            hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.7)),
            prefixIcon: Icon(Icons.search_rounded, color: _textSecondary.withValues(alpha: 0.7), size: 20),
            filled: false,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _userCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final isPremium = d['isPremium'] ?? false;
    final email = d['email'] ?? '-';
    final name = d['displayName'] ?? 'İsimsiz';
    final photoUrl = d['photoUrl'];
    final gamesPlayed = d['gamesPlayed'] ?? 0;
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPremium ? _accentOrange.withValues(alpha: 0.3) : _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetail(doc),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPremium
                          ? [_accentOrange.withValues(alpha: 0.3), _accentOrange.withValues(alpha: 0.1)]
                          : [_accent.withValues(alpha: 0.2), _accentPink.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildUserAvatar(name)),
                        )
                      : _buildUserAvatar(name),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                          ),
                          if (isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_accentOrange, _accentOrange.withValues(alpha: 0.8)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Premium', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: _textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _miniTag('$gamesPlayed oyun', _accentBlue),
                          const SizedBox(width: 8),
                          if (createdAt != null) _miniTag(_formatDate(createdAt), _textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                    child: const Icon(Icons.more_horiz_rounded, color: _textSecondary, size: 18),
                  ),
                  color: _bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'premium') _togglePremium(doc.id, !isPremium);
                    if (v == 'detail') _showUserDetail(doc);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.info_outline, size: 18, color: _accentBlue), const SizedBox(width: 12), const Text('Detay', style: TextStyle(color: _textPrimary))])),
                    PopupMenuItem(value: 'premium', child: Row(children: [Icon(isPremium ? Icons.star_outline : Icons.star, size: 18, color: _accentOrange), const SizedBox(width: 12), Text(isPremium ? 'Premium Kaldır' : 'Premium Yap', style: const TextStyle(color: _textPrimary))])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(child: Text(initial, style: const TextStyle(color: _accentLight, fontSize: 20, fontWeight: FontWeight.bold)));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _togglePremium(String oderId, bool isPremium) async {
    try {
      await _db.collection('users').doc(oderId).update({
        'isPremium': isPremium,
        'premiumUpdatedAt': FieldValue.serverTimestamp(),
      });
      _snack(isPremium ? 'Premium aktif edildi' : 'Premium kaldırıldı', success: true);
      _loadStats();
    } catch (e) {
      _snack('Hata: $e', error: true);
    }
  }

  void _showUserDetail(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: _accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text((d['displayName'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: _accent, fontSize: 24, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['displayName'] ?? 'İsimsiz', style: const TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(d['email'] ?? '-', style: const TextStyle(color: _textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (d['isPremium'] == true)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.star_rounded, color: _accentOrange, size: 24),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: _border),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _userDetailSection('Oyun İstatistikleri', [
                      _userDetailRow('Toplam Oyun', '${d['gamesPlayed'] ?? 0}'),
                      _userDetailRow('Bulunan Şarkı', '${d['totalSongsFound'] ?? 0}'),
                      _userDetailRow('Toplam Süre', _formatDuration(d['totalTimePlayed'] ?? 0)),
                    ]),
                    const SizedBox(height: 20),
                    _userDetailSection('Hesap Bilgileri', [
                      _userDetailRow('UID', doc.id),
                      _userDetailRow('Kayıt Tarihi', _formatDateTime(d['createdAt'])),
                      _userDetailRow('Son Giriş', _formatDateTime(d['lastLoginAt'])),
                      _userDetailRow('Premium', d['isPremium'] == true ? 'Evet' : 'Hayır'),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _userDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textSecondary, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(color: _textPrimary, fontSize: 13), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '-';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ==================== NOTIFICATIONS ====================
  Widget _buildNotifications() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accentPink.withValues(alpha: 0.2), _accent.withValues(alpha: 0.1)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: _accentPink, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Push Bildirim Gönder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary)),
                    Text('Tüm kullanıcılara veya belirli gruplara bildirim gönderin', style: TextStyle(color: _textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Send Notification Form
          _buildNotificationForm(),

          const SizedBox(height: 32),

          // Notification Templates
          _sectionHeader('Hızlı Şablonlar', Icons.flash_on_rounded),
          const SizedBox(height: 16),
          _notificationTemplate('Yeni Challenge', 'Yeni bir challenge eklendi! Hemen oyna ve puan kazan.', Icons.emoji_events_rounded, _accentOrange),
          const SizedBox(height: 12),
          _notificationTemplate('Güncelleme', 'Yeni özellikler ve iyileştirmeler ile güncelledik!', Icons.system_update_rounded, _accentBlue),
          const SizedBox(height: 12),
          _notificationTemplate('Özel Fırsat', 'Sınırlı süre! Premium üyelikte %50 indirim.', Icons.local_offer_rounded, _accentGreen),

          const SizedBox(height: 32),

          // Recent Notifications
          _sectionHeader('Son Gönderilen Bildirimler', Icons.history_rounded),
          const SizedBox(height: 16),
          _buildNotificationHistory(),
        ],
      ),
    );
  }

  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();
  String _notifTarget = 'all';

  Widget _buildNotificationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yeni Bildirim', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),

          // Target Selection
          const Text('Hedef Kitle', style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _targetChip('all', 'Tüm Kullanıcılar', Icons.people_rounded),
              const SizedBox(width: 10),
              _targetChip('premium', 'Premium', Icons.star_rounded),
              const SizedBox(width: 10),
              _targetChip('free', 'Ücretsiz', Icons.person_outline_rounded),
            ],
          ),

          const SizedBox(height: 20),

          // Title
          _dialogTF(_notifTitleController, 'Başlık', hint: 'Bildirim başlığı...'),

          // Body
          _dialogTF(_notifBodyController, 'Mesaj', hint: 'Bildirim içeriği...', lines: 3),

          const SizedBox(height: 8),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendNotification,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Bildirim Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetChip(String value, String label, IconData icon) {
    final isSelected = _notifTarget == value;
    return GestureDetector(
      onTap: () => setState(() => _notifTarget = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accentPink.withValues(alpha: 0.15) : _bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? _accentPink.withValues(alpha: 0.3) : _border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? _accentPink : _textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? _accentPink : _textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _snack('Başlık ve mesaj gerekli', error: true);
      return;
    }

    _loadingDialog('Bildirim gönderiliyor...');

    try {
      await _db.collection('notifications').add({
        'title': title,
        'body': body,
        'target': _notifTarget,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.email,
      });

      if (mounted) Navigator.pop(context);
      _snack('Bildirim kuyruğa eklendi!', success: true);

      _notifTitleController.clear();
      _notifBodyController.clear();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _snack('Hata: $e', error: true);
    }
  }

  Widget _notificationTemplate(String title, String body, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        _notifTitleController.text = title;
        _notifBodyController.text = body;
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: _textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('notifications').orderBy('createdAt', descending: true).limit(10).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return Container(
            height: 100,
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: const Center(child: Text('Henüz bildirim gönderilmemiş', style: TextStyle(color: _textSecondary))),
          );
        }
        return Container(
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(color: _border.withValues(alpha: 0.5), height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final status = d['status'] ?? 'pending';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: status == 'sent' ? _accentGreen.withValues(alpha: 0.15) : _accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    status == 'sent' ? Icons.check_circle : Icons.schedule,
                    color: status == 'sent' ? _accentGreen : _accentOrange,
                    size: 18,
                  ),
                ),
                title: Text(d['title'] ?? '-', style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text('${d['target'] ?? 'all'} • ${_formatDateTime(d['createdAt'])}', style: const TextStyle(color: _textSecondary, fontSize: 11)),
              );
            },
          ),
        );
      },
    );
  }

  // ==================== SORTING ====================
  Widget _buildSorting() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accentCyan.withValues(alpha: 0.2), _accentBlue.withValues(alpha: 0.1)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.swap_vert_rounded, color: _accentCyan, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sıralama Yönetimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary)),
                    Text('Kategori ve challenge sıralamasını düzenleyin', style: TextStyle(color: _textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Category Sorting
          _sectionHeader('Kategori Sıralaması', Icons.category_rounded),
          const SizedBox(height: 16),
          _buildCategorySortList(),

          const SizedBox(height: 32),

          // Featured Challenge Sorting
          _sectionHeader('Öne Çıkan Challenge Sıralaması', Icons.star_rounded),
          const SizedBox(height: 16),
          _buildFeaturedSortList(),
        ],
      ),
    );
  }

  Widget _buildCategorySortList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('categories').orderBy('sortOrder').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return Container(
            height: 200,
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyState('Kategori bulunamadı', Icons.category_outlined);

        return Container(
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            onReorder: (oldIndex, newIndex) => _reorderCategories(docs, oldIndex, newIndex),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                key: ValueKey(docs[i].id),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('${i + 1}', style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Text(d['iconEmoji'] ?? '🎵', style: const TextStyle(fontSize: 24)),
                  ],
                ),
                title: Text(d['title'] ?? docs[i].id, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500)),
                subtitle: Text('Sıra: ${d['sortOrder'] ?? 0}', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.drag_handle, color: _textSecondary),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _reorderCategories(List<DocumentSnapshot> docs, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final batch = _db.batch();
    final movedDoc = docs.removeAt(oldIndex);
    docs.insert(newIndex, movedDoc);

    for (int i = 0; i < docs.length; i++) {
      batch.update(_db.collection('categories').doc(docs[i].id), {'sortOrder': i});
    }

    await batch.commit();
    _snack('Sıralama güncellendi', success: true);
  }

  Widget _buildFeaturedSortList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('challenges').where('isFeatured', isEqualTo: true).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return Container(
            height: 200,
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: const Center(child: Text('Öne çıkan challenge yok', style: TextStyle(color: _textSecondary))),
          );
        }

        return Container(
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            onReorder: (oldIndex, newIndex) => _reorderFeatured(docs, oldIndex, newIndex),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                key: ValueKey(docs[i].id),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('${i + 1}', style: const TextStyle(color: _accentOrange, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star_rounded, color: _accentOrange, size: 20),
                  ],
                ),
                title: Text(d['title'] ?? docs[i].id, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500)),
                subtitle: Text('${d['totalSongs'] ?? 0} şarkı • ${d['categoryId'] ?? '-'}', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.drag_handle, color: _textSecondary),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _reorderFeatured(List<DocumentSnapshot> docs, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final batch = _db.batch();
    final movedDoc = docs.removeAt(oldIndex);
    docs.insert(newIndex, movedDoc);

    for (int i = 0; i < docs.length; i++) {
      batch.update(_db.collection('challenges').doc(docs[i].id), {'featuredOrder': i});
    }

    await batch.commit();
    _snack('Sıralama güncellendi', success: true);
  }

  // ==================== TOOLS ====================
  Widget _buildTools() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export Section
          _sectionHeader('Export', Icons.download),
          const SizedBox(height: 16),
          _toolCard('Kategorileri Export Et', 'Tüm kategorileri JSON formatında dışa aktar', Icons.category, _accentGreen, () => _exportCollection('categories')),
          const SizedBox(height: 12),
          _toolCard('Challenge\'ları Export Et', 'Tüm challenge\'ları JSON formatında dışa aktar', Icons.emoji_events, _accentOrange, () => _exportCollection('challenges')),
          const SizedBox(height: 12),
          _toolCard('Şarkıları Export Et', 'Tüm şarkıları JSON formatında dışa aktar', Icons.music_note, _accent, () => _exportCollection('songs')),
          const SizedBox(height: 12),
          _toolCard('Tümünü Export Et', 'Kategoriler, challenge\'lar ve şarkıları tek JSON dosyasında dışa aktar', Icons.archive, _accentBlue, _exportAll),
          const SizedBox(height: 32),

          // Toplu İşlemler Section
          _sectionHeader('Toplu İşlemler', Icons.flash_on),
          const SizedBox(height: 16),
          _toolCard('Tüm Word Index\'leri Yeniden Oluştur', 'Tüm challenge\'lar için word index\'i sıfırdan oluşturur', Icons.sync, _accentBlue, _rebuildAllWordIndexes),
          const SizedBox(height: 32),
          _sectionHeader('Tehlikeli Bölge', Icons.warning),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accentRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accentRed.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.warning, color: _accentRed), SizedBox(width: 8), Text('DİKKAT: Bu işlemler geri alınamaz!', style: TextStyle(color: _accentRed, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dangerBtn('Kategorileri Sil', () => _deleteCollection('categories')),
                    _dangerBtn('Challenge\'ları Sil', () => _deleteCollection('challenges')),
                    _dangerBtn('Şarkıları Sil', () => _deleteCollection('songs')),
                    _dangerBtn('Word Index Sil', () => _deleteCollection('challengeWordIndex')),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deleteAllCollections,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('TÜM İÇERİĞİ SİL'),
                    style: ElevatedButton.styleFrom(backgroundColor: _accentRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolCard(String t, String d, IconData i, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(d, style: const TextStyle(color: _textSecondary, fontSize: 13))]),
            ),
            const Icon(Icons.chevron_right, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _dangerBtn(String l, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: _accentRed, side: const BorderSide(color: _accentRed)),
        child: Text(l),
      );

  // ==================== HELPER WIDGETS ====================
  Widget _listHeader(String t, int cnt, VoidCallback? onAdd, String addL, {Widget? filterWidget}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgCard, _bgElevated.withValues(alpha: 0.5)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.2), _accentPink.withValues(alpha: 0.1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIconForTitle(t), size: 20, color: _accentLight),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$cnt kayıt', style: const TextStyle(color: _accentLight, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (onAdd != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_accentGreen, _accentGreen.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _accentGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(addL, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (filterWidget != null) ...[const SizedBox(height: 14), filterWidget],
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Kategori')) return Icons.category_rounded;
    if (title.contains('Challenge')) return Icons.emoji_events_rounded;
    if (title.contains('Şarkı')) return Icons.music_note_rounded;
    return Icons.folder_rounded;
  }

  Widget _categoryDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('categories').orderBy('sortOrder').snapshots(),
      builder: (ctx, snap) {
        final cats = snap.data?.docs ?? [];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedCategoryFilter,
              hint: const Text('Tüm Kategoriler', style: TextStyle(color: _textSecondary)),
              isExpanded: true,
              dropdownColor: _bgElevated,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tüm Kategoriler', style: TextStyle(color: _textPrimary))),
                ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text((c.data() as Map)['title'] ?? c.id, style: const TextStyle(color: _textPrimary)))),
              ],
              onChanged: (v) => setState(() => _selectedCategoryFilter = v),
            ),
          ),
        );
      },
    );
  }

  Widget _challengeDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('challenges').snapshots(),
      builder: (ctx, snap) {
        final chals = snap.data?.docs ?? [];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedChallengeFilter,
              hint: const Text('Challenge Seç', style: TextStyle(color: _textSecondary)),
              isExpanded: true,
              dropdownColor: _bgElevated,
              items: [
                const DropdownMenuItem(value: null, child: Text('Challenge Seç', style: TextStyle(color: _textPrimary))),
                ...chals.map((c) => DropdownMenuItem(value: c.id, child: Text((c.data() as Map)['title'] ?? c.id, style: const TextStyle(color: _textPrimary)))),
              ],
              onChanged: (v) => setState(() => _selectedChallengeFilter = v),
            ),
          ),
        );
      },
    );
  }

  Widget _miniTag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
        child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w500)),
      );

  Widget _statusBadge(bool a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: a ? _accentGreen.withValues(alpha: 0.12) : _textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: a ? _accentGreen.withValues(alpha: 0.2) : _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: a ? _accentGreen : _textSecondary,
              shape: BoxShape.circle,
              boxShadow: a ? [BoxShadow(color: _accentGreen.withValues(alpha: 0.5), blurRadius: 4)] : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(a ? 'Aktif' : 'Pasif', style: TextStyle(color: a ? _accentGreen : _textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyState(String m, IconData i) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: Icon(i, size: 48, color: _textSecondary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(m, style: const TextStyle(color: _textSecondary, fontSize: 15)),
          ],
        ),
      );

  // ==================== DIALOGS ====================
  Future<void> _openCategoryDialog(DocumentSnapshot? doc) async {
    final isNew = doc == null;
    final docId = doc?.id ?? '';
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final idC = TextEditingController(text: isNew ? '' : docId);
    final titleC = TextEditingController(text: d['title'] ?? '');
    final descC = TextEditingController(text: d['description'] ?? '');
    final emojiC = TextEditingController(text: d['iconEmoji'] ?? '🎵');
    final sortC = TextEditingController(text: (d['sortOrder'] ?? 0).toString());
    final priceC = TextEditingController(text: (d['priceUsd'] ?? 0.0).toString());
    final discountC = TextEditingController(text: (d['discountPercent'] ?? 40.0).toString());
    String lang = d['language'] ?? 'tr';
    String type = d['type'] ?? 'playlist';
    bool active = d['isActive'] ?? true;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: _bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isNew ? 'Yeni Kategori' : 'Kategori Düzenle', style: const TextStyle(color: _textPrimary)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNew) _dialogTF(idC, 'ID', hint: 'turkce_pop'),
                  _dialogTF(titleC, 'Başlık'),
                  _dialogTF(descC, 'Açıklama', lines: 2),
                  Row(children: [Expanded(child: _dialogTF(emojiC, 'Emoji')), const SizedBox(width: 12), Expanded(child: _dialogTF(sortC, 'Sıra', num: true))]),
                  Row(children: [
                    Expanded(child: _dialogTF(priceC, 'Manuel Fiyat', hint: '0 = otomatik', num: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _dialogTF(discountC, 'İndirim %', hint: '40', num: true)),
                  ]),
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: _bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      'Fiyat = 0 ise: challenge_sayısı × \$0.99 × (1 - indirim%/100)\nÖrnek: 5 challenge, %40 indirim = \$2.97',
                      style: TextStyle(color: _textSecondary, fontSize: 11),
                    ),
                  ),
                  _dialogDD('Dil', lang, ['tr', 'en'], (v) => ss(() => lang = v!)),
                  _dialogDD('Tip', type, ['playlist', 'artist'], (v) => ss(() => type = v!)),
                  _dialogSW('Aktif', active, (v) => ss(() => active = v)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (res == true) {
      final id = isNew ? idC.text.trim() : docId;
      if (id.isEmpty) return;
      await _admin.upsertCategory(
        id: id,
        title: titleC.text.trim(),
        description: descC.text.trim(),
        iconEmoji: emojiC.text.trim(),
        type: type,
        language: lang,
        priceUsd: double.tryParse(priceC.text) ?? 0.0,
        discountPercent: double.tryParse(discountC.text) ?? 40.0,
        isActive: active,
        sortOrder: int.tryParse(sortC.text) ?? 0,
      );
      _loadStats();
    }
  }

  Future<void> _openChallengeDialog(DocumentSnapshot? doc) async {
    final isNew = doc == null;
    final docId = doc?.id ?? '';
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final idC = TextEditingController(text: isNew ? '' : docId);
    final titleC = TextEditingController(text: d['title'] ?? '');
    final artistC = TextEditingController(text: d['artist'] ?? '');
    final yearC = TextEditingController(text: (d['year'] ?? '').toString());
    final priceC = TextEditingController(text: (d['priceUsd'] ?? 0.0).toString());
    String? catId = d['categoryId'];
    String lang = d['language'] ?? 'tr';
    bool active = d['isActive'] ?? true;
    bool free = d['isFree'] ?? true;
    bool featured = d['isFeatured'] ?? false;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: _bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isNew ? 'Yeni Challenge' : 'Challenge Düzenle', style: const TextStyle(color: _textPrimary)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNew) _dialogTF(idC, 'ID', hint: 'duman_1999'),
                  _dialogTF(titleC, 'Başlık'),
                  _dialogTF(artistC, 'Sanatçı'),
                  Row(children: [
                    Expanded(child: _dialogTF(yearC, 'Yıl', num: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _dialogTF(priceC, 'Fiyat (USD)', hint: '0.99', num: true)),
                  ]),
                  StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('categories').snapshots(),
                    builder: (ctx, snap) {
                      final cats = snap.data?.docs ?? [];
                      return _dialogDD('Kategori', catId, cats.map((c) => c.id).toList(), (v) => ss(() => catId = v), labels: {for (var c in cats) c.id: (c.data() as Map)['title'] ?? c.id});
                    },
                  ),
                  _dialogDD('Dil', lang, ['tr', 'en'], (v) => ss(() => lang = v!)),
                  _dialogSW('Aktif', active, (v) => ss(() => active = v)),
                  _dialogSW('Ücretsiz', free, (v) => ss(() => free = v)),
                  _dialogSW('Öne Çıkan', featured, (v) => ss(() => featured = v)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (res == true) {
      final id = isNew ? idC.text.trim() : docId;
      if (id.isEmpty || catId == null) return;
      await _admin.updateChallenge(id, {
        'title': titleC.text.trim(),
        'artist': artistC.text.trim(),
        'year': int.tryParse(yearC.text) ?? 0,
        'priceUsd': double.tryParse(priceC.text) ?? 0.0,
        'categoryId': catId,
        'language': lang,
        'isActive': active,
        'isFree': free,
        'isFeatured': featured,
        if (isNew) 'songIds': <String>[],
        if (isNew) 'totalSongs': 0,
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      });
      _loadStats();
    }
  }

  Future<void> _quickAddSongToChallenge(String challengeId, String categoryId) async {
    final idC = TextEditingController();
    final titleC = TextEditingController();
    final artistC = TextEditingController();
    final yearC = TextEditingController(text: DateTime.now().year.toString());
    final lyricsC = TextEditingController();

    // Get challenge info for language
    final chalSnap = await _db.collection('challenges').doc(challengeId).get();
    final chalD = chalSnap.data() ?? {};
    final lang = chalD['language'] ?? 'tr';
    final chalTitle = chalD['title'] ?? challengeId;

    if (!mounted) return;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hızlı Şarkı Ekle', style: TextStyle(color: _textPrimary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(chalTitle, style: const TextStyle(color: _accentGreen, fontSize: 12)),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogTF(artistC, 'Sanatçı'),
                _dialogTF(titleC, 'Şarkı Adı'),
                _dialogTF(yearC, 'Yıl', num: true),
                _dialogTF(idC, 'ID (Opsiyonel)', hint: 'Boş bırakırsan otomatik oluşturulur'),
                _dialogTF(lyricsC, 'Lyrics', lines: 6, hint: 'Şarkı sözlerini yapıştırın...'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _accentGreen),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (res == true && mounted) {
      final artist = artistC.text.trim();
      final title = titleC.text.trim();
      final lyrics = lyricsC.text.trim();

      if (artist.isEmpty || title.isEmpty || lyrics.isEmpty) {
        _snack('Sanatçı, şarkı adı ve sözler zorunludur', error: true);
        return;
      }

      // Generate ID if not provided
      String songId = idC.text.trim();
      if (songId.isEmpty) {
        songId = '${artist.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      }

      _loadingDialog('Şarkı ekleniyor...');
      try {
        final ext = _kw.extract(lyricsRaw: lyrics, languageCode: lang);
        await _admin.upsertSong(
          songId: songId,
          categoryId: categoryId,
          challengeId: challengeId,
          languageCode: lang,
          artist: artist,
          title: title,
          lyricsRaw: lyrics,
          keywords: ext.keywords,
          topKeywords: ext.topKeywords,
          year: int.tryParse(yearC.text) ?? DateTime.now().year,
        );
        await _admin.rebuildChallengeSongIds(challengeId);
        if (mounted) Navigator.pop(context);
        if (mounted) _snack('$title eklendi!', success: true);
        _loadStats();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) _snack('Hata: $e', error: true);
      }
    }
  }

  Future<void> _openSongDialog(DocumentSnapshot? doc) async {
    final isNew = doc == null;
    final docId = doc?.id ?? '';
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final idC = TextEditingController(text: isNew ? '' : docId);
    final titleC = TextEditingController(text: d['title'] ?? '');
    final artistC = TextEditingController(text: d['artist'] ?? '');
    final yearC = TextEditingController(text: (d['year'] ?? '').toString());
    final lyricsC = TextEditingController(text: d['lyricsRaw'] ?? '');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isNew ? 'Yeni Şarkı' : 'Şarkı Düzenle', style: const TextStyle(color: _textPrimary)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNew) _dialogTF(idC, 'ID', hint: 'her_seyi_yak'),
                _dialogTF(titleC, 'Şarkı Adı'),
                _dialogTF(artistC, 'Sanatçı'),
                _dialogTF(yearC, 'Yıl', num: true),
                _dialogTF(lyricsC, 'Lyrics', lines: 8, hint: 'Şarkı sözlerini yapıştırın...'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet')),
        ],
      ),
    );
    if (res == true) {
      final id = isNew ? idC.text.trim() : docId;
      if (id.isEmpty || _selectedChallengeFilter == null) return;
      final chalSnap = await _db.collection('challenges').doc(_selectedChallengeFilter!).get();
      final chalD = chalSnap.data() ?? {};
      final catId = chalD['categoryId'] ?? '';
      final lang = chalD['language'] ?? 'tr';
      final lyrics = lyricsC.text.trim();
      final ext = _kw.extract(lyricsRaw: lyrics, languageCode: lang);
      await _admin.upsertSong(
        songId: id,
        categoryId: catId,
        challengeId: _selectedChallengeFilter!,
        languageCode: lang,
        artist: artistC.text.trim(),
        title: titleC.text.trim(),
        lyricsRaw: lyrics,
        keywords: ext.keywords,
        topKeywords: ext.topKeywords,
        year: int.tryParse(yearC.text) ?? 2000,
      );
      await _admin.rebuildChallengeSongIds(_selectedChallengeFilter!);
      _loadStats();
    }
  }

  Future<void> _openKeywordEditor(DocumentSnapshot doc) async {
    final d = doc.data() as Map<String, dynamic>;
    final kw = (d['keywords'] as List?)?.cast<String>() ?? [];
    final top = (d['topKeywords'] as List?)?.cast<String>() ?? [];
    final kwC = TextEditingController(text: kw.join(', '));
    final topC = TextEditingController(text: top.join(', '));

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keyword: ${d['title']}', style: const TextStyle(color: _textPrimary)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogTF(kwC, 'Keywords (virgülle ayır)', lines: 5),
              _dialogTF(topC, 'Top Keywords (virgülle ayır)', lines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet')),
        ],
      ),
    );
    if (res == true) {
      final newKw = _kw.parseManualTokens(kwC.text);
      final newTop = _kw.parseManualTokens(topC.text);
      await _db.collection('songs').doc(doc.id).update({'keywords': newKw, 'topKeywords': newTop, 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  Widget _dialogTF(TextEditingController c, String l, {String? hint, int lines = 1, bool num = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            maxLines: lines,
            keyboardType: num ? TextInputType.number : null,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint ?? 'Girin...',
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.4)),
              filled: true,
              fillColor: _bgElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogDD(String l, String? v, List<String> items, Function(String?) onChange, {Map<String, String>? labels}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonFormField<String>(
              value: v,
              dropdownColor: _bgCard,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(labels?[i] ?? i, style: const TextStyle(color: _textPrimary)))).toList(),
              onChanged: onChange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogSW(String l, bool v, Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: v ? _accentGreen.withValues(alpha: 0.1) : _bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: v ? _accentGreen.withValues(alpha: 0.3) : _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  v ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: v ? _accentGreen : _textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(l, style: TextStyle(color: v ? _textPrimary : _textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
            Switch(
              value: v,
              onChanged: onChange,
              activeColor: _accentGreen,
              activeTrackColor: _accentGreen.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================
  Future<void> _deleteCategory(String id) async {
    final c = await _confirmDialog('Kategori Sil', '$id kategorisini silmek istediğinize emin misiniz?');
    if (c == true) {
      await _admin.deleteCategory(id);
      _loadStats();
    }
  }

  Future<void> _deleteChallenge(String id) async {
    final c = await _confirmDialog('Challenge Sil', '$id ve tüm şarkılarını silmek istediğinize emin misiniz?');
    if (c == true) {
      await _admin.deleteChallenge(id, deleteSongsToo: true);
      _loadStats();
    }
  }

  Future<void> _deleteSong(String id) async {
    await _admin.deleteSong(id);
    if (_selectedChallengeFilter != null) await _admin.rebuildChallengeSongIds(_selectedChallengeFilter!);
    _loadStats();
  }

  Future<void> _buildWordIndex(String challengeId) async {
    _loadingDialog('Word index oluşturuluyor...');
    try {
      final cnt = await _admin.buildWordIndex(challengeId);
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('$cnt kelime indexlendi', success: true);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Hata: $e', error: true);
    }
  }

  Future<void> _exportCollection(String collection) async {
    _loadingDialog('$collection export ediliyor...');
    try {
      final snap = await _db.collection(collection).get();
      final data = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      final json = const JsonEncoder.withIndent('  ').convert({
        'collection': collection,
        'exportedAt': DateTime.now().toIso8601String(),
        'count': data.length,
        'data': data,
      });
      if (mounted) Navigator.pop(context);
      _showExportResult(collection, json);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Export hatası: $e', error: true);
    }
  }

  Future<void> _exportAll() async {
    _loadingDialog('Tüm veriler export ediliyor...');
    try {
      final categories = await _db.collection('categories').get();
      final challenges = await _db.collection('challenges').get();
      final songs = await _db.collection('songs').get();

      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'categories': {
          'count': categories.docs.length,
          'data': categories.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        },
        'challenges': {
          'count': challenges.docs.length,
          'data': challenges.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        },
        'songs': {
          'count': songs.docs.length,
          'data': songs.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        },
      };

      final json = const JsonEncoder.withIndent('  ').convert(exportData);
      if (mounted) Navigator.pop(context);
      _showExportResult('all_content', json);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Export hatası: $e', error: true);
    }
  }

  void _showExportResult(String name, String json) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _accentGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Başarılı', style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('$name.json', style: const TextStyle(color: _textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: json));
                      _snack('JSON kopyalandı!', success: true);
                    },
                    icon: Icon(Icons.copy, color: _accent),
                    tooltip: 'Kopyala',
                  ),
                ],
              ),
            ),
            const Divider(color: _border),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: SelectableText(
                    json,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: _textSecondary),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: json));
                      Navigator.pop(ctx);
                      _snack('JSON panoya kopyalandı!', success: true);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Kopyala ve Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rebuildAllWordIndexes() async {
    final c = await _confirmDialog('Tüm Index\'leri Yeniden Oluştur', 'Tüm challenge\'lar için word index yeniden oluşturulacak. Devam?');
    if (c != true) return;
    _loadingDialog('Tüm indexler oluşturuluyor...');
    try {
      final res = await _admin.buildAllWordIndexes();
      final total = res.values.fold<int>(0, (s, c) => s + c);
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('${res.length} challenge için $total kelime indexlendi', success: true);
      _loadStats();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Hata: $e', error: true);
    }
  }

  Future<void> _deleteCollection(String col) async {
    final c = await _confirmDialog('$col Sil', '$col koleksiyonundaki tüm verileri silmek istediğinize emin misiniz?');
    if (c != true) return;
    _loadingDialog('Siliniyor...');
    try {
      final snap = await _db.collection(col).get();
      final batch = _db.batch();
      for (var doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('$col silindi (${snap.docs.length} belge)', success: true);
      _loadStats();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Hata: $e', error: true);
    }
  }

  Future<void> _deleteAllCollections() async {
    final c = await _confirmDialog('TÜM İÇERİK SİL', 'categories, challenges, songs, challengeWordIndex koleksiyonlarındaki TÜM VERİLER silinecek!\n\nBu işlem geri alınamaz!', danger: true);
    if (c != true) return;
    _loadingDialog('Tüm veriler siliniyor...');
    try {
      final cols = ['categories', 'challenges', 'songs', 'challengeWordIndex'];
      int total = 0;
      for (final col in cols) {
        final snap = await _db.collection(col).get();
        final batch = _db.batch();
        for (var doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        total += snap.docs.length;
      }
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Tüm içerik silindi ($total belge)', success: true);
      _loadStats();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Hata: $e', error: true);
    }
  }

  Future<bool?> _confirmDialog(String title, String content, {bool danger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: danger ? _accentRed : _accentOrange),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: _textPrimary))),
          ],
        ),
        content: Text(content, style: const TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: danger ? _accentRed : _accentOrange),
            child: Text(danger ? 'Evet, Sil' : 'Tamam'),
          ),
        ],
      ),
    );
  }

  void _loadingDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _bgCard,
        content: Row(children: [const CircularProgressIndicator(color: _accent), const SizedBox(width: 16), Text(msg, style: const TextStyle(color: _textPrimary))]),
      ),
    );
  }

  void _snack(String msg, {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _accentRed : (success ? _accentGreen : null),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ==================== IMPORT TAB WIDGET ====================
class _ImportTab extends StatefulWidget {
  final AdminContentService admin;
  final LyricsKeywordService kw;
  final FirebaseFirestore db;
  final VoidCallback onImportComplete;

  const _ImportTab({
    required this.admin,
    required this.kw,
    required this.db,
    required this.onImportComplete,
  });

  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab> {
  final _jsonController = TextEditingController();
  Map<String, dynamic>? _parsedData;
  String? _parseError;
  bool _importing = false;
  List<String> _importResults = [];

  static const _bgDark = Color(0xFF0D1117);
  static const _bgCard = Color(0xFF161B22);
  static const _bgElevated = Color(0xFF21262D);
  static const _accent = Color(0xFFCAB7FF);
  static const _accentGreen = Color(0xFF3FB950);
  static const _accentRed = Color(0xFFF85149);
  static const _accentBlue = Color(0xFF58A6FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _parseJson() {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedData = null;
        _parseError = null;
      });
      return;
    }

    try {
      final data = json.decode(text) as Map<String, dynamic>;

      // Validate required fields
      if (!data.containsKey('categoryId')) {
        throw FormatException('categoryId alanı gerekli');
      }
      if (!data.containsKey('challengeId')) {
        throw FormatException('challengeId alanı gerekli');
      }
      if (!data.containsKey('songs') || data['songs'] is! List) {
        throw FormatException('songs dizisi gerekli');
      }

      final songs = data['songs'] as List;
      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        if (song is! Map) throw FormatException('songs[$i] geçersiz format');
        if (!song.containsKey('title')) throw FormatException('songs[$i].title gerekli');
        if (!song.containsKey('artist')) throw FormatException('songs[$i].artist gerekli');
        if (!song.containsKey('lyrics')) throw FormatException('songs[$i].lyrics gerekli');
      }

      setState(() {
        _parsedData = data;
        _parseError = null;
      });
    } catch (e) {
      setState(() {
        _parsedData = null;
        _parseError = e.toString();
      });
    }
  }

  Future<void> _import() async {
    if (_parsedData == null) return;

    setState(() {
      _importing = true;
      _importResults = [];
    });

    try {
      final categoryId = _parsedData!['categoryId'] as String;
      final challengeId = _parsedData!['challengeId'] as String;
      final songs = _parsedData!['songs'] as List;
      final language = (_parsedData!['language'] as String?) ?? 'tr';

      // Check if challenge exists, create if not
      final challengeDoc = await widget.db.collection('challenges').doc(challengeId).get();
      if (!challengeDoc.exists) {
        await widget.admin.updateChallenge(challengeId, {
          'title': challengeId,
          'categoryId': categoryId,
          'language': language,
          'isActive': true,
          'isFree': true,
          'songIds': <String>[],
          'totalSongs': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _importResults.add('Challenge oluşturuldu: $challengeId');
      }

      int successCount = 0;
      int errorCount = 0;

      for (final song in songs) {
        try {
          final songMap = song as Map<String, dynamic>;
          final title = songMap['title'] as String;
          final artist = songMap['artist'] as String;
          final lyrics = songMap['lyrics'] as String;
          final year = (songMap['year'] as int?) ?? 2000;
          final songId = songMap['id'] as String? ?? _buildSongId(challengeId, artist, title);

          final ext = widget.kw.extract(lyricsRaw: lyrics, languageCode: language);

          await widget.admin.upsertSong(
            songId: songId,
            categoryId: categoryId,
            challengeId: challengeId,
            languageCode: language,
            artist: artist,
            title: title,
            lyricsRaw: lyrics,
            keywords: ext.keywords,
            topKeywords: ext.topKeywords,
            year: year,
          );

          successCount++;
          _importResults.add('✓ $title - $artist');
        } catch (e) {
          errorCount++;
          _importResults.add('✗ ${song['title'] ?? 'Bilinmeyen'}: $e');
        }
      }

      // Rebuild challenge song IDs
      await widget.admin.rebuildChallengeSongIds(challengeId);

      _importResults.add('');
      _importResults.add('Sonuç: $successCount başarılı, $errorCount hatalı');

      widget.onImportComplete();
    } catch (e) {
      _importResults.add('Import hatası: $e');
    }

    setState(() => _importing = false);
  }

  String _buildSongId(String challengeId, String artist, String title) {
    String slug(String s) {
      final cleaned = s.trim().toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_');
      return cleaned.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    }
    return '${slug(challengeId)}_${slug(artist)}_${slug(title)}';
  }

  void _loadSampleJson() {
    const sample = '''{
  "categoryId": "turkce_pop",
  "challengeId": "tarkan_hits",
  "language": "tr",
  "songs": [
    {
      "title": "Şımarık",
      "artist": "Tarkan",
      "year": 1997,
      "lyrics": "Şımarık şımarık\\nSana benden bu kadar..."
    },
    {
      "title": "Kuzu Kuzu",
      "artist": "Tarkan",
      "year": 1999,
      "lyrics": "Kuzu kuzu gel yanıma..."
    }
  ]
}''';
    _jsonController.text = sample;
    _parseJson();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _jsonController.text = data!.text!;
      _parseJson();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.upload_file, color: _accent, size: 24),
              const SizedBox(width: 12),
              const Text('JSON Bulk Import', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary)),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadSampleJson,
                icon: const Icon(Icons.code, size: 18),
                label: const Text('Örnek JSON'),
                style: TextButton.styleFrom(foregroundColor: _accentBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Birden fazla şarkıyı tek seferde içe aktarın. JSON formatında categoryId, challengeId ve songs dizisi gereklidir.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 20),

          // JSON Input
          Container(
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border)),
                  ),
                  child: Row(
                    children: [
                      const Text('JSON Verisi', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.paste, size: 16),
                        label: const Text('Yapıştır'),
                        style: TextButton.styleFrom(foregroundColor: _textSecondary),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _jsonController.clear();
                          setState(() {
                            _parsedData = null;
                            _parseError = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Temizle'),
                        style: TextButton.styleFrom(foregroundColor: _textSecondary),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: _jsonController,
                  maxLines: 12,
                  onChanged: (_) => _parseJson(),
                  style: const TextStyle(color: _textPrimary, fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'JSON verisini buraya yapıştırın...',
                    hintStyle: TextStyle(color: _textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Parse Status
          if (_parseError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accentRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: _accentRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_parseError!, style: const TextStyle(color: _accentRed, fontSize: 13))),
                ],
              ),
            ),

          if (_parsedData != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accentGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: _accentGreen, size: 20),
                      const SizedBox(width: 8),
                      const Text('JSON Geçerli', style: TextStyle(color: _accentGreen, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _previewRow('Kategori', _parsedData!['categoryId']),
                  _previewRow('Challenge', _parsedData!['challengeId']),
                  _previewRow('Dil', _parsedData!['language'] ?? 'tr'),
                  _previewRow('Şarkı Sayısı', '${(_parsedData!['songs'] as List).length}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Import Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _importing ? null : _import,
                icon: _importing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload),
                label: Text(_importing ? 'İçe aktarılıyor...' : 'İçe Aktar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          // Import Results
          if (_importResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İçe Aktarma Sonuçları', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...(_importResults.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          r,
                          style: TextStyle(
                            color: r.startsWith('✓')
                                ? _accentGreen
                                : r.startsWith('✗')
                                    ? _accentRed
                                    : _textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // JSON Format Reference
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: _accentBlue, size: 20),
                    SizedBox(width: 8),
                    Text('JSON Format', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Zorunlu Alanlar:', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _formatItem('categoryId', 'Kategori ID (ör: "turkce_pop")'),
                _formatItem('challengeId', 'Challenge ID (ör: "tarkan_hits")'),
                _formatItem('songs', 'Şarkı dizisi'),
                _formatItem('songs[].title', 'Şarkı adı'),
                _formatItem('songs[].artist', 'Sanatçı'),
                _formatItem('songs[].lyrics', 'Şarkı sözleri'),
                const SizedBox(height: 12),
                const Text('Opsiyonel Alanlar:', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _formatItem('language', 'Dil kodu (varsayılan: "tr")'),
                _formatItem('songs[].id', 'Özel şarkı ID'),
                _formatItem('songs[].year', 'Yıl (varsayılan: 2000)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: _textSecondary, fontSize: 13))),
          Text(value, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _formatItem(String field, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(4)),
            child: Text(field, style: const TextStyle(color: _accent, fontSize: 11, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: const TextStyle(color: _textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}

// ==================== SONG BUILDER TAB WIDGET ====================
class _SongBuilderTab extends StatefulWidget {
  final AdminContentService admin;
  final LyricsKeywordService kw;
  final FirebaseFirestore db;
  final VoidCallback onSongAdded;

  const _SongBuilderTab({
    required this.admin,
    required this.kw,
    required this.db,
    required this.onSongAdded,
  });

  @override
  State<_SongBuilderTab> createState() => _SongBuilderTabState();
}

class _SongBuilderTabState extends State<_SongBuilderTab> {
  String? _selectedCategoryId;
  String? _selectedChallengeId;
  String _language = 'tr';

  final _artistController = TextEditingController();
  final _titleController = TextEditingController();
  final _yearController = TextEditingController(text: '2020');
  final _lyricsController = TextEditingController();
  final _songIdController = TextEditingController();

  List<String> _keywords = [];
  List<String> _topKeywords = [];
  bool _saving = false;
  String? _lastSavedSong;

  static const _bgCard = Color(0xFF161B22);
  static const _bgElevated = Color(0xFF21262D);
  static const _accent = Color(0xFFCAB7FF);
  static const _accentGreen = Color(0xFF3FB950);
  static const _accentRed = Color(0xFFF85149);
  static const _accentBlue = Color(0xFF58A6FF);
  static const _accentOrange = Color(0xFFD29922);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);

  @override
  void dispose() {
    _artistController.dispose();
    _titleController.dispose();
    _yearController.dispose();
    _lyricsController.dispose();
    _songIdController.dispose();
    super.dispose();
  }

  void _generateKeywords() {
    final lyrics = _lyricsController.text.trim();
    if (lyrics.isEmpty) return;

    final result = widget.kw.extract(
      lyricsRaw: lyrics,
      languageCode: _language,
      removeStopwords: true,
      minTokenLength: 2,
      maxTopKeywords: 180,
    );

    setState(() {
      _keywords = result.keywords;
      _topKeywords = result.topKeywords;
    });
  }

  String _buildSongId() {
    if (_songIdController.text.trim().isNotEmpty) {
      return _songIdController.text.trim();
    }

    String slug(String s) {
      final cleaned = s.trim().toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_');
      return cleaned.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    }

    final challenge = _selectedChallengeId ?? 'unknown';
    final artist = _artistController.text.trim();
    final title = _titleController.text.trim();

    return '${slug(challenge)}_${slug(artist)}_${slug(title)}';
  }

  Future<void> _saveSong() async {
    if (_selectedCategoryId == null || _selectedChallengeId == null) {
      _showSnack('Kategori ve Challenge seçin', error: true);
      return;
    }

    final artist = _artistController.text.trim();
    final title = _titleController.text.trim();
    final lyrics = _lyricsController.text.trim();

    if (artist.isEmpty || title.isEmpty || lyrics.isEmpty) {
      _showSnack('Sanatçı, şarkı adı ve sözler gerekli', error: true);
      return;
    }

    // Generate keywords if not done
    if (_keywords.isEmpty) {
      _generateKeywords();
    }

    setState(() => _saving = true);

    try {
      final songId = _buildSongId();

      await widget.admin.upsertSong(
        songId: songId,
        categoryId: _selectedCategoryId!,
        challengeId: _selectedChallengeId!,
        languageCode: _language,
        artist: artist,
        title: title,
        lyricsRaw: lyrics,
        keywords: _keywords,
        topKeywords: _topKeywords.isNotEmpty ? _topKeywords : _keywords.take(180).toList(),
        year: int.tryParse(_yearController.text) ?? 2020,
      );

      await widget.admin.rebuildChallengeSongIds(_selectedChallengeId!);
      widget.onSongAdded();

      setState(() {
        _lastSavedSong = '$title - $artist';
      });

      _showSnack('Şarkı eklendi: $title', success: true);

      // Clear form for next song (keep category/challenge selection)
      _artistController.clear();
      _titleController.clear();
      _lyricsController.clear();
      _songIdController.clear();
      _yearController.text = '2020';
      setState(() {
        _keywords = [];
        _topKeywords = [];
      });
    } catch (e) {
      _showSnack('Hata: $e', error: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _accentRed : (success ? _accentGreen : null),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_circle, color: _accentGreen, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tek Tek Şarkı Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary)),
                    Text('Şarkıları tek tek ekleyin, sözleri yapıştırın', style: TextStyle(color: _textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          if (_lastSavedSong != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accentGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _accentGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Son eklenen: $_lastSavedSong', style: const TextStyle(color: _accentGreen, fontSize: 13))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: _accentGreen),
                    onPressed: () => setState(() => _lastSavedSong = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Step 1: Category & Challenge Selection
          _buildStepHeader(1, 'Kategori & Challenge Seç'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: widget.db.collection('categories').orderBy('sortOrder').snapshots(),
                        builder: (ctx, snap) {
                          final cats = snap.data?.docs ?? [];
                          return _buildDropdown(
                            'Kategori',
                            _selectedCategoryId,
                            cats.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text((c.data() as Map)['title'] ?? c.id, style: const TextStyle(color: _textPrimary)),
                            )).toList(),
                            (v) => setState(() {
                              _selectedCategoryId = v;
                              _selectedChallengeId = null;
                            }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _selectedCategoryId != null
                            ? widget.db.collection('challenges').where('categoryId', isEqualTo: _selectedCategoryId).snapshots()
                            : widget.db.collection('challenges').snapshots(),
                        builder: (ctx, snap) {
                          final chals = snap.data?.docs ?? [];
                          return _buildDropdown(
                            'Challenge',
                            _selectedChallengeId,
                            chals.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text((c.data() as Map)['title'] ?? c.id, style: const TextStyle(color: _textPrimary)),
                            )).toList(),
                            (v) => setState(() => _selectedChallengeId = v),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  'Dil',
                  _language,
                  const [
                    DropdownMenuItem(value: 'tr', child: Text('Türkçe', style: TextStyle(color: _textPrimary))),
                    DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: _textPrimary))),
                  ],
                  (v) => setState(() => _language = v ?? 'tr'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Step 2: Song Info
          _buildStepHeader(2, 'Şarkı Bilgileri'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTextField(_artistController, 'Sanatçı', icon: Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_titleController, 'Şarkı Adı', icon: Icons.music_note)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_yearController, 'Yıl', icon: Icons.calendar_today, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_songIdController, 'Özel ID (opsiyonel)', icon: Icons.tag, hint: 'Boş bırakılırsa otomatik')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Step 3: Lyrics
          _buildStepHeader(3, 'Şarkı Sözleri'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _lyricsController,
                  maxLines: 10,
                  style: const TextStyle(color: _textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Şarkı sözlerini buraya yapıştırın...',
                    hintStyle: const TextStyle(color: _textSecondary),
                    filled: true,
                    fillColor: _bgElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generateKeywords,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Keyword Oluştur'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentBlue,
                          side: const BorderSide(color: _accentBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            _lyricsController.text = data!.text!;
                          }
                        },
                        icon: const Icon(Icons.paste, size: 18),
                        label: const Text('Yapıştır'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Keywords Preview
          if (_keywords.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildStepHeader(4, 'Keyword Önizleme (${_keywords.length} kelime)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildKeywordBadge('Top Keywords', _topKeywords.length, _accentOrange),
                      const SizedBox(width: 12),
                      _buildKeywordBadge('Tüm Keywords', _keywords.length, _accentBlue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _topKeywords.take(30).map((w) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(w, style: const TextStyle(color: _accentOrange, fontSize: 12)),
                    )).toList(),
                  ),
                  if (_topKeywords.length > 30) ...[
                    const SizedBox(height: 8),
                    Text('... ve ${_topKeywords.length - 30} kelime daha', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveSong,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Kaydediliyor...' : 'Şarkıyı Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: _accent, size: 18),
                    SizedBox(width: 8),
                    Text('İpuçları', style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTip('Kayıt sonrası form temizlenir, aynı challenge\'a devam edebilirsiniz'),
                _buildTip('Keyword oluştur butonuna basmadan da kaydedebilirsiniz'),
                _buildTip('Toplu ekleme için Import tab\'ını kullanın'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(int step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text('$step', style: const TextStyle(color: _accent, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: _bgElevated,
      style: const TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSecondary),
        filled: true,
        fillColor: _bgElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {IconData? icon, String? hint, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : null,
      style: const TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _textSecondary),
        hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
        prefixIcon: icon != null ? Icon(icon, color: _textSecondary, size: 20) : null,
        filled: true,
        fillColor: _bgElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildKeywordBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: _textSecondary)),
          Expanded(child: Text(text, style: const TextStyle(color: _textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}

// Helper class for card actions
class _CardAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _CardAction(this.icon, this.label, this.color, this.onTap);
}
