import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/admin_content_service.dart';
import '../../services/lyrics_keyword_service.dart';

class DevAdminScreen extends StatefulWidget {
  const DevAdminScreen({super.key});

  @override
  State<DevAdminScreen> createState() => _DevAdminScreenState();
}

class _DevAdminScreenState extends State<DevAdminScreen> with SingleTickerProviderStateMixin {
  final AdminContentService _admin = AdminContentService();
  final LyricsKeywordService _kw = LyricsKeywordService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Set<String> _adminEmails = {'talhayildiz94@gmail.com'};

  bool get _isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
    return email != null && _adminEmails.contains(email);
  }

  late TabController _tabController;

  int _categoryCount = 0;
  int _challengeCount = 0;
  int _songCount = 0;
  int _wordIndexCount = 0;
  int _userCount = 0;
  bool _loadingStats = false;

  String? _selectedCategoryFilter;
  String? _selectedChallengeFilter;

  static const _bgDark = Color(0xFF0D1117);
  static const _bgCard = Color(0xFF161B22);
  static const _bgElevated = Color(0xFF21262D);
  static const _accent = Color(0xFFCAB7FF);
  static const _accentGreen = Color(0xFF3FB950);
  static const _accentRed = Color(0xFFF85149);
  static const _accentOrange = Color(0xFFD29922);
  static const _accentBlue = Color(0xFF58A6FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) _loadStats();
      setState(() {});
    });
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final cats = await _db.collection('categories').count().get();
      final chals = await _db.collection('challenges').count().get();
      final songs = await _db.collection('songs').count().get();
      final words = await _db.collection('challengeWordIndex').count().get();
      final users = await _db.collection('users').count().get();
      if (mounted) {
        setState(() {
          _categoryCount = cats.count ?? 0;
          _challengeCount = chals.count ?? 0;
          _songCount = songs.count ?? 0;
          _wordIndexCount = words.count ?? 0;
          _userCount = users.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Stats error: \$e');
    }
    if (mounted) setState(() => _loadingStats = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(title: const Text('Admin Panel'), backgroundColor: _bgCard, foregroundColor: _textPrimary),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _accentRed.withValues(alpha:0.5))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _accentRed.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.lock, size: 48, color: _accentRed)),
                const SizedBox(height: 24),
                const Text('Erişim Reddedildi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary)),
                const SizedBox(height: 8),
                Text('Email: \${FirebaseAuth.instance.currentUser?.email ?? "Giriş yapılmamış"}', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgCard,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha:0.6)]), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.admin_panel_settings, size: 20, color: _bgDark)),
          const SizedBox(width: 12),
          const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: _loadingStats ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)) : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: _bgCard, border: Border(bottom: BorderSide(color: _border))),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: _accent,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _accent,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Dashboard'),
                Tab(icon: Icon(Icons.category_rounded, size: 20), text: 'Kategoriler'),
                Tab(icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'Challenge'),
                Tab(icon: Icon(Icons.music_note_rounded, size: 20), text: 'Şarkılar'),
                Tab(icon: Icon(Icons.build_rounded, size: 20), text: 'Araçlar'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [_buildDashboard(), _buildCategories(), _buildChallenges(), _buildSongs(), _buildTools()]),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('İstatistikler', Icons.analytics),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _statCard('Kategoriler', _categoryCount, Icons.category, _accentBlue),
              _statCard('Challenge', _challengeCount, Icons.emoji_events, _accentOrange),
              _statCard('Şarkılar', _songCount, Icons.music_note, _accentGreen),
              _statCard('Word Index', _wordIndexCount, Icons.text_fields, _accent),
              _statCard('Kullanıcılar', _userCount, Icons.people, Colors.pink),
            ],
          ),
          const SizedBox(height: 32),
          _sectionHeader('Hızlı Başlangıç', Icons.rocket_launch),
          const SizedBox(height: 16),
          _quickStartCard(),
          const SizedBox(height: 32),
          _sectionHeader('Son Challenge\'lar', Icons.history),
          const SizedBox(height: 16),
          _recentChallenges(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String t, IconData i) => Row(children: [Icon(i, color: _accent, size: 20), const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary))]);

  Widget _statCard(String t, int v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)), child: Icon(i, color: c, size: 20)),
        const Spacer(),
        Text(v.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
        Text(t, style: const TextStyle(color: _textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _quickStartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_accent.withValues(alpha:0.15), _accentBlue.withValues(alpha:0.1)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: _accent.withValues(alpha:0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.lightbulb, color: _accentOrange), SizedBox(width: 12), Text('İçerik Ekleme Rehberi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary))]),
        const SizedBox(height: 16),
        _stepItem(1, 'Kategori oluştur', 'Türkçe Pop, Rock vb.'),
        _stepItem(2, 'Challenge ekle', 'Kategori altına sanatçı challenge\'ı'),
        _stepItem(3, 'Şarkıları gir', 'Lyrics yapıştır, keyword otomatik çıkar'),
        _stepItem(4, 'Word Index oluştur', 'Challenge tab\'ında Build butonu'),
      ]),
    );
  }

  Widget _stepItem(int s, String t, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: _accent.withValues(alpha:0.2), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(s.toString(), style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500)), Text(sub, style: const TextStyle(color: _textSecondary, fontSize: 12))])),
      ]),
    );
  }

  Widget _recentChallenges() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('challenges').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyState('Henüz challenge yok', Icons.emoji_events_outlined);
        return Container(
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(color: _border, height: 1),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final cnt = d['totalSongs'] ?? 0;
              final active = d['isActive'] ?? true;
              return ListTile(
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: active ? _accentGreen.withValues(alpha:0.15) : _textSecondary.withValues(alpha:0.15), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(cnt.toString(), style: TextStyle(color: active ? _accentGreen : _textSecondary, fontWeight: FontWeight.bold)))),
                title: Text(d['title'] ?? docs[i].id, style: const TextStyle(color: _textPrimary)),
                subtitle: Text('${d['categoryId'] ?? '-'} • $cnt şarkı', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                trailing: _statusBadge(active),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategories() {
    return Column(children: [
      _listHeader('Kategoriler', _categoryCount, () => _openCategoryDialog(null), 'Yeni Kategori'),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('categories').orderBy('sortOrder').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
            final docs = snap.data!.docs;
            if (docs.isEmpty) return _emptyState('Henüz kategori yok', Icons.category_outlined);
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) => _categoryCard(docs[i]));
          },
        ),
      ),
    ]);
  }

  Widget _categoryCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final active = d['isActive'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: _accent.withValues(alpha:0.15), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(d['iconEmoji'] ?? '🎵', style: const TextStyle(fontSize: 24)))),
        title: Text(d['title'] ?? doc.id, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Row(children: [_miniTag(d['language']?.toUpperCase() ?? 'TR', _accentBlue), const SizedBox(width: 8), _miniTag(d['type'] ?? 'playlist', _accent), const SizedBox(width: 8), _miniTag('Sıra: ${d['sortOrder'] ?? 0}', _textSecondary)]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          _statusBadge(active),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _textSecondary),
            color: _bgElevated,
            onSelected: (v) {
              if (v == 'edit') _openCategoryDialog(doc);
              if (v == 'delete') _deleteCategory(doc.id);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: _textSecondary), SizedBox(width: 8), Text('Düzenle', style: TextStyle(color: _textPrimary))])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: _accentRed), SizedBox(width: 8), Text('Sil', style: TextStyle(color: _accentRed))])),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildChallenges() {
    return Column(children: [
      _listHeader('Challenge\'lar', _challengeCount, () => _openChallengeDialog(null), 'Yeni Challenge', filterWidget: _categoryDropdown()),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _selectedCategoryFilter != null ? _db.collection('challenges').where('categoryId', isEqualTo: _selectedCategoryFilter).snapshots() : _db.collection('challenges').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
            final docs = snap.data!.docs;
            if (docs.isEmpty) return _emptyState('Henüz challenge yok', Icons.emoji_events_outlined);
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) => _challengeCard(docs[i]));
          },
        ),
      ),
    ]);
  }

  Widget _challengeCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final cnt = d['totalSongs'] ?? 0;
    final active = d['isActive'] ?? true;
    final free = d['isFree'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: active ? [_accentGreen.withValues(alpha:0.3), _accentGreen.withValues(alpha:0.1)] : [_textSecondary.withValues(alpha:0.3), _textSecondary.withValues(alpha:0.1)]), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(cnt.toString(), style: TextStyle(color: active ? _accentGreen : _textSecondary, fontWeight: FontWeight.bold, fontSize: 18)))),
          title: Text(d['title'] ?? doc.id, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
          subtitle: Row(children: [_miniTag(d['categoryId'] ?? '-', _accentBlue), const SizedBox(width: 8), if (free) _miniTag('ÜCRETSİZ', _accentGreen)]),
          trailing: _statusBadge(active),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
          child: Row(children: [
            _actionBtn(Icons.build, 'Index', _accentBlue, () => _buildWordIndex(doc.id)),
            const SizedBox(width: 8),
            _actionBtn(Icons.edit, 'Düzenle', _accent, () => _openChallengeDialog(doc)),
            const SizedBox(width: 8),
            _actionBtn(Icons.delete, 'Sil', _accentRed, () => _deleteChallenge(doc.id)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSongs() {
    return Column(children: [
      _listHeader('Şarkılar', _songCount, _selectedChallengeFilter != null ? () => _openSongDialog(null) : null, 'Yeni Şarkı', filterWidget: _challengeDropdown()),
      if (_selectedChallengeFilter == null)
        Expanded(child: _emptyState('Lütfen bir challenge seçin', Icons.filter_list))
      else
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('songs').where('challengeId', isEqualTo: _selectedChallengeFilter).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _accent));
              final docs = snap.data!.docs;
              if (docs.isEmpty) return _emptyState('Bu challenge\'da şarkı yok', Icons.music_note_outlined);
              return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (ctx, i) => _songCard(docs[i], i + 1));
            },
          ),
        ),
    ]);
  }

  Widget _songCard(DocumentSnapshot doc, int idx) {
    final d = doc.data() as Map<String, dynamic>;
    final kw = (d['keywords'] as List?)?.length ?? 0;
    final top = (d['topKeywords'] as List?)?.length ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: _accent.withValues(alpha:0.15), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(idx.toString(), style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)))),
        title: Text(d['title'] ?? doc.id, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d['artist'] ?? '-', style: const TextStyle(color: _textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Row(children: [_miniTag('$kw keyword', _accentBlue), const SizedBox(width: 8), _miniTag('$top top', _accentGreen)]),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
    );
  }

  Widget _buildTools() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Toplu İşlemler', Icons.flash_on),
        const SizedBox(height: 16),
        _toolCard('Tüm Word Index\'leri Yeniden Oluştur', 'Tüm challenge\'lar için word index\'i sıfırdan oluşturur', Icons.sync, _accentBlue, _rebuildAllWordIndexes),
        const SizedBox(height: 32),
        _sectionHeader('Tehlikeli Bölge', Icons.warning),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _accentRed.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accentRed.withValues(alpha:0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.warning, color: _accentRed), SizedBox(width: 8), Text('DİKKAT: Bu işlemler geri alınamaz!', style: TextStyle(color: _accentRed, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _dangerBtn('Kategorileri Sil', () => _deleteCollection('categories')),
              _dangerBtn('Challenge\'ları Sil', () => _deleteCollection('challenges')),
              _dangerBtn('Şarkıları Sil', () => _deleteCollection('songs')),
              _dangerBtn('Word Index Sil', () => _deleteCollection('challengeWordIndex')),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _deleteAllCollections, icon: const Icon(Icons.delete_forever), label: const Text('TÜM İÇERİĞİ SİL'), style: ElevatedButton.styleFrom(backgroundColor: _accentRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
          ]),
        ),
      ]),
    );
  }

  Widget _toolCard(String t, String d, IconData i, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withValues(alpha:0.15), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(d, style: const TextStyle(color: _textSecondary, fontSize: 13))])),
          const Icon(Icons.chevron_right, color: _textSecondary),
        ]),
      ),
    );
  }

  Widget _dangerBtn(String l, VoidCallback onTap) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: _accentRed, side: const BorderSide(color: _accentRed)), child: Text(l));

  Widget _listHeader(String t, int cnt, VoidCallback? onAdd, String addL, {Widget? filterWidget}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: _bgCard, border: Border(bottom: BorderSide(color: _border))),
      child: Column(children: [
        Row(children: [
          Text(t, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _accent.withValues(alpha:0.15), borderRadius: BorderRadius.circular(10)), child: Text(cnt.toString(), style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold))),
          const Spacer(),
          if (onAdd != null) ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: Text(addL), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
        ]),
        if (filterWidget != null) ...[const SizedBox(height: 12), filterWidget],
      ]),
    );
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
              items: [const DropdownMenuItem(value: null, child: Text('Tüm Kategoriler', style: TextStyle(color: _textPrimary))), ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text((c.data() as Map)['title'] ?? c.id, style: const TextStyle(color: _textPrimary))))],
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
              items: [const DropdownMenuItem(value: null, child: Text('Challenge Seç', style: TextStyle(color: _textPrimary))), ...chals.map((c) => DropdownMenuItem(value: c.id, child: Text((c.data() as Map)['title'] ?? c.id, style: const TextStyle(color: _textPrimary))))],
              onChanged: (v) => setState(() => _selectedChallengeFilter = v),
            ),
          ),
        );
      },
    );
  }

  Widget _miniTag(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha:0.15), borderRadius: BorderRadius.circular(4)), child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w500)));

  Widget _statusBadge(bool a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: a ? _accentGreen.withValues(alpha:0.15) : _textSecondary.withValues(alpha:0.15), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: a ? _accentGreen : _textSecondary, shape: BoxShape.circle)), const SizedBox(width: 4), Text(a ? 'Aktif' : 'Pasif', style: TextStyle(color: a ? _accentGreen : _textSecondary, fontSize: 11, fontWeight: FontWeight.w500))]),
    );
  }

  Widget _actionBtn(IconData i, String l, Color c, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: c.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 16, color: c), const SizedBox(width: 4), Text(l, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500))])),
      ),
    );
  }

  Widget _emptyState(String m, IconData i) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 64, color: _textSecondary.withValues(alpha:0.3)), const SizedBox(height: 16), Text(m, style: const TextStyle(color: _textSecondary))]));

  // DIALOGS
  Future<void> _openCategoryDialog(DocumentSnapshot? doc) async {
    final isNew = doc == null;
    final docId = doc?.id ?? '';
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final idC = TextEditingController(text: isNew ? '' : docId);
    final titleC = TextEditingController(text: d['title'] ?? '');
    final descC = TextEditingController(text: d['description'] ?? '');
    final emojiC = TextEditingController(text: d['iconEmoji'] ?? '🎵');
    final sortC = TextEditingController(text: (d['sortOrder'] ?? 0).toString());
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (isNew) _dialogTF(idC, 'ID', hint: 'turkce_pop'),
                _dialogTF(titleC, 'Başlık'),
                _dialogTF(descC, 'Açıklama', lines: 2),
                Row(children: [Expanded(child: _dialogTF(emojiC, 'Emoji')), const SizedBox(width: 12), Expanded(child: _dialogTF(sortC, 'Sıra', num: true))]),
                _dialogDD('Dil', lang, ['tr', 'en'], (v) => ss(() => lang = v!)),
                _dialogDD('Tip', type, ['playlist', 'artist'], (v) => ss(() => type = v!)),
                _dialogSW('Aktif', active, (v) => ss(() => active = v)),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet'))],
        ),
      ),
    );
    if (res == true) {
      final id = isNew ? idC.text.trim() : docId;
      if (id.isEmpty) return;
      await _admin.upsertCategory(id: id, title: titleC.text.trim(), description: descC.text.trim(), iconEmoji: emojiC.text.trim(), type: type, language: lang, priceUsd: 0, isActive: active, sortOrder: int.tryParse(sortC.text) ?? 0);
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
    String? catId = d['categoryId'];
    String lang = d['language'] ?? 'tr';
    bool active = d['isActive'] ?? true;
    bool free = d['isFree'] ?? true;

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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (isNew) _dialogTF(idC, 'ID', hint: 'duman_1999'),
                _dialogTF(titleC, 'Başlık'),
                _dialogTF(artistC, 'Sanatçı'),
                _dialogTF(yearC, 'Yıl', num: true),
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
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet'))],
        ),
      ),
    );
    if (res == true) {
      final id = isNew ? idC.text.trim() : docId;
      if (id.isEmpty || catId == null) return;
      await _admin.updateChallenge(id, {'title': titleC.text.trim(), 'artist': artistC.text.trim(), 'year': int.tryParse(yearC.text) ?? 0, 'categoryId': catId, 'language': lang, 'isActive': active, 'isFree': free, if (isNew) 'songIds': <String>[], if (isNew) 'totalSongs': 0, if (isNew) 'createdAt': FieldValue.serverTimestamp()});
      _loadStats();
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
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [if (isNew) _dialogTF(idC, 'ID', hint: 'her_seyi_yak'), _dialogTF(titleC, 'Şarkı Adı'), _dialogTF(artistC, 'Sanatçı'), _dialogTF(yearC, 'Yıl', num: true), _dialogTF(lyricsC, 'Lyrics', lines: 8, hint: 'Şarkı sözlerini yapıştırın...')]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet'))],
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
      await _admin.upsertSong(songId: id, categoryId: catId, challengeId: _selectedChallengeFilter!, languageCode: lang, artist: artistC.text.trim(), title: titleC.text.trim(), lyricsRaw: lyrics, keywords: ext.keywords, topKeywords: ext.topKeywords, year: int.tryParse(yearC.text) ?? 2000);
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
        content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [_dialogTF(kwC, 'Keywords (virgülle ayır)', lines: 5), _dialogTF(topC, 'Top Keywords (virgülle ayır)', lines: 3)])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: _accentGreen), child: const Text('Kaydet'))],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: num ? TextInputType.number : null,
        style: const TextStyle(color: _textPrimary),
        decoration: InputDecoration(labelText: l, hintText: hint, labelStyle: const TextStyle(color: _textSecondary), hintStyle: TextStyle(color: _textSecondary.withValues(alpha:0.5)), filled: true, fillColor: _bgElevated, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent))),
      ),
    );
  }

  Widget _dialogDD(String l, String? v, List<String> items, Function(String?) onChange, {Map<String, String>? labels}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(value: v, dropdownColor: _bgElevated, style: const TextStyle(color: _textPrimary), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: _textSecondary), filled: true, fillColor: _bgElevated, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border))), items: items.map((i) => DropdownMenuItem(value: i, child: Text(labels?[i] ?? i, style: const TextStyle(color: _textPrimary)))).toList(), onChanged: onChange),
    );
  }

  Widget _dialogSW(String l, bool v, Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(color: _textPrimary)), Switch(value: v, onChanged: onChange, activeColor: _accentGreen)])),
    );
  }

  // ACTIONS
  Future<void> _deleteCategory(String id) async {
    final c = await _confirmDialog('Kategori Sil', '\$id kategorisini silmek istediğinize emin misiniz?');
    if (c == true) {
      await _admin.deleteCategory(id);
      _loadStats();
    }
  }

  Future<void> _deleteChallenge(String id) async {
    final c = await _confirmDialog('Challenge Sil', '\$id ve tüm şarkılarını silmek istediğinize emin misiniz?');
    if (c == true) {
      await _admin.deleteChallenge(id, deleteSongsToo: true);
      _loadStats();
    }
  }

  Future<void> _deleteSong(String id) async {
    final c = await _confirmDialog('Şarkı Sil', '\$id şarkısını silmek istediğinize emin misiniz?');
    if (c == true) {
      await _admin.deleteSong(id);
      if (_selectedChallengeFilter != null) await _admin.rebuildChallengeSongIds(_selectedChallengeFilter!);
      _loadStats();
    }
  }

  Future<void> _buildWordIndex(String challengeId) async {
    _loadingDialog('Word index oluşturuluyor...');
    try {
      final cnt = await _admin.buildWordIndex(challengeId);
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('$cnt kelime indexlendi', success: true);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) _snack('Hata: \$e', error: true);
    }
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
      if (mounted) _snack('Hata: \$e', error: true);
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
      if (mounted) _snack('Hata: \$e', error: true);
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
      if (mounted) _snack('Hata: \$e', error: true);
    }
  }

  Future<bool?> _confirmDialog(String title, String content, {bool danger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.warning, color: danger ? _accentRed : _accentOrange), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(color: _textPrimary)))]),
        content: Text(content, style: const TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: _textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: danger ? _accentRed : _accentOrange), child: Text(danger ? 'Evet, Sil' : 'Tamam')),
        ],
      ),
    );
  }

  void _loadingDialog(String msg) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(backgroundColor: _bgCard, content: Row(children: [const CircularProgressIndicator(color: _accent), const SizedBox(width: 16), Text(msg, style: const TextStyle(color: _textPrimary))])));
  }

  void _snack(String msg, {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? _accentRed : (success ? _accentGreen : null), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }
}
