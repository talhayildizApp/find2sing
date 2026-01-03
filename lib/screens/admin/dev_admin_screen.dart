import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/admin_content_service.dart';

class DevAdminScreen extends StatefulWidget {
  const DevAdminScreen({super.key});

  @override
  State<DevAdminScreen> createState() => _DevAdminScreenState();
}

class _DevAdminScreenState extends State<DevAdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final AdminContentService _admin = AdminContentService();

  // Basit allowlist gate (sonra custom claims’e geçersin)
  static const Set<String> _adminEmails = {
    'your@email.com', // TODO: kendi email’in
  };

  bool get _isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase().trim();
    if (email == null) return false;
    return _adminEmails.contains(email);
  }

  // Import
  final TextEditingController _json = TextEditingController();
  bool _importing = false;
  String? _importStatus;

  // Filters
  String _songSearch = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _json.dispose();
    super.dispose();
  }

  Future<void> _importSeed() async {
    final text = _json.text.trim();
    if (text.isEmpty) {
      setState(() => _importStatus = 'Paste JSON first.');
      return;
    }

    setState(() {
      _importing = true;
      _importStatus = null;
    });

    try {
      await _admin.importSeedJson(text);
      setState(() => _importStatus = '✅ Import OK (challenges + songs + wordSets).');
    } catch (e) {
      setState(() => _importStatus = '❌ ERROR: $e');
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dev Admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Admin access denied.\n\nAdd your email to _adminEmails in DevAdminScreen.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Admin'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Import'),
            Tab(text: 'Categories'),
            Tab(text: 'Challenges'),
            Tab(text: 'Songs'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildImportTab(),
          _buildCategoriesTab(),
          _buildChallengesTab(),
          _buildSongsTab(),
        ],
      ),
    );
  }

  // -------------------------
  // Import
  // -------------------------
  Widget _buildImportTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text(
            'Paste seed JSON (4-challenge seed) to import.\nThis repo uses /songs (global) + challenge.songIds.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _json,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Paste JSON here...'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          if (_importStatus != null) Text(_importStatus!, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _importing ? null : _importSeed,
              icon: _importing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload),
              label: const Text('Import seed'),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // Categories
  // -------------------------
  Widget _buildCategoriesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('categories').orderBy('sortOrder').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;

        return Scaffold(
          body: ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final x = d.data();
              return ListTile(
                title: Text((x['title'] ?? d.id).toString()),
                subtitle: Text('id=${d.id} • type=${x['type'] ?? '-'} • lang=${x['language'] ?? '-'} • active=${x['isActive'] ?? false}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openCategoryEditor(d.id, x),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openCategoryEditor('', const {}),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _openCategoryEditor(String id, Map<String, dynamic> data) async {
    final idCtrl = TextEditingController(text: id);
    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());
    final descCtrl = TextEditingController(text: (data['description'] ?? '').toString());
    final emojiCtrl = TextEditingController(text: (data['iconEmoji'] ?? '🎵').toString());
    final typeCtrl = TextEditingController(text: (data['type'] ?? 'playlist').toString());
    final langCtrl = TextEditingController(text: (data['language'] ?? 'tr').toString());
    final priceCtrl = TextEditingController(text: (data['priceUsd'] ?? 0).toString());
    final sortCtrl = TextEditingController(text: (data['sortOrder'] ?? 0).toString());
    bool active = (data['isActive'] ?? true) as bool;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(id.isEmpty ? 'New Category' : 'Edit Category'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: idCtrl, enabled: id.isEmpty, decoration: const InputDecoration(labelText: 'id (doc id)')),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'title')),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'description')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'iconEmoji'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'type'))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: langCtrl, decoration: const InputDecoration(labelText: 'language'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'priceUsd'))),
                    ],
                  ),
                  TextField(controller: sortCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'sortOrder')),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setLocal(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (id.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _admin.deleteCategory(id);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newId = idCtrl.text.trim();
                if (newId.isEmpty) return;
                await _admin.upsertCategory(
                  id: newId,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  iconEmoji: emojiCtrl.text.trim(),
                  type: typeCtrl.text.trim(),
                  language: langCtrl.text.trim(),
                  priceUsd: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  isActive: active,
                  sortOrder: int.tryParse(sortCtrl.text.trim()) ?? 0,
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // Challenges
  // -------------------------
  Widget _buildChallengesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('challenges').orderBy('title').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = docs[i];
            final x = d.data();
            final totalSongs = (x['totalSongs'] ?? 0);
            return ListTile(
              title: Text((x['title'] ?? d.id).toString()),
              subtitle: Text('id=${d.id} • cat=${x['categoryId'] ?? '-'} • lang=${x['language'] ?? '-'} • songs=$totalSongs • active=${x['isActive'] ?? false}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await _openChallengeEditor(d.id, x);
                  } else if (v == 'rebuild') {
                    await _admin.rebuildChallengeSongIds(d.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rebuilt songIds.')));
                    }
                  } else if (v == 'delete') {
                    await _admin.deleteChallenge(d.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'rebuild', child: Text('Rebuild songIds')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openChallengeEditor(String id, Map<String, dynamic> data) async {
    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());
    final catCtrl = TextEditingController(text: (data['categoryId'] ?? '').toString());
    final typeCtrl = TextEditingController(text: (data['type'] ?? 'mixed').toString());
    final diffCtrl = TextEditingController(text: (data['difficulty'] ?? 'medium').toString());
    final langCtrl = TextEditingController(text: (data['language'] ?? 'tr').toString());
    final priceCtrl = TextEditingController(text: (data['priceUsd'] ?? 0).toString());
    bool active = (data['isActive'] ?? true) as bool;
    bool isFree = (data['isFree'] ?? true) as bool;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Edit Challenge: $id'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'title')),
                  TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'categoryId')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'type'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: diffCtrl, decoration: const InputDecoration(labelText: 'difficulty'))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: langCtrl, decoration: const InputDecoration(labelText: 'language'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'priceUsd'))),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setLocal(() => active = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('isFree'),
                    value: isFree,
                    onChanged: (v) => setLocal(() => isFree = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _admin.updateChallenge(id, {
                  'title': titleCtrl.text.trim(),
                  'categoryId': catCtrl.text.trim(),
                  'type': typeCtrl.text.trim(),
                  'difficulty': diffCtrl.text.trim(),
                  'language': langCtrl.text.trim(),
                  'priceUsd': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  'isActive': active,
                  'isFree': isFree,
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // Songs
  // -------------------------
  Widget _buildSongsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search songs (title/artist/challengeId)',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _songSearch = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('songs').orderBy('artist').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snap.data!.docs.where((d) {
                if (_songSearch.isEmpty) return true;
                final x = d.data();
                final hay = '${d.id} ${(x['title'] ?? '')} ${(x['artist'] ?? '')} ${(x['challengeId'] ?? '')}'.toLowerCase();
                return hay.contains(_songSearch);
              }).toList();

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final x = d.data();
                  final keywords = (x['keywords'] as List<dynamic>? ?? const <dynamic>[]).length;
                  return ListTile(
                    title: Text('${x['artist'] ?? ''} — ${x['title'] ?? ''}'),
                    subtitle: Text('id=${d.id} • challengeId=${x['challengeId'] ?? '-'} • year=${x['year'] ?? '-'} • keywords=$keywords'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openSongEditor(d.id, x),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton.icon(
            onPressed: () => _openSongEditor('', const {}),
            icon: const Icon(Icons.add),
            label: const Text('Add song'),
          ),
        ),
      ],
    );
  }

  Future<void> _openSongEditor(String songId, Map<String, dynamic> data) async {
    final idCtrl = TextEditingController(text: songId);
    final challengeIdCtrl = TextEditingController(text: (data['challengeId'] ?? '').toString());
    final artistCtrl = TextEditingController(text: (data['artist'] ?? '').toString());
    final titleCtrl = TextEditingController(text: (data['title'] ?? '').toString());
    final yearCtrl = TextEditingController(text: (data['year'] ?? 2000).toString());
    final albumCtrl = TextEditingController(text: (data['album'] ?? '').toString());
    final previewCtrl = TextEditingController(text: (data['previewUrl'] ?? '').toString());

    final List<String> keywords = (data['keywords'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final addCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(songId.isEmpty ? 'New Song' : 'Edit Song'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: idCtrl, enabled: songId.isEmpty, decoration: const InputDecoration(labelText: 'songId (doc id)')),
                  TextField(controller: challengeIdCtrl, decoration: const InputDecoration(labelText: 'challengeId')),
                  TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'artist')),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'title')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'year'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: albumCtrl, decoration: const InputDecoration(labelText: 'album (optional)'))),
                    ],
                  ),
                  TextField(controller: previewCtrl, decoration: const InputDecoration(labelText: 'previewUrl (optional)')),

                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Keywords', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: keywords
                        .map((w) => Chip(
                              label: Text(w),
                              onDeleted: () => setLocal(() => keywords.remove(w)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addCtrl,
                          decoration: const InputDecoration(labelText: 'Add keywords (comma/space separated)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final raw = addCtrl.text.trim();
                          if (raw.isEmpty) return;
                          final parts = raw
                              .split(RegExp(r'[,\s]+'))
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          setLocal(() {
                            keywords.addAll(parts);
                            final uniq = keywords.toSet().toList()..sort();
                            keywords
                              ..clear()
                              ..addAll(uniq);
                            addCtrl.clear();
                          });
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (songId.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _admin.deleteSong(songId);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newId = idCtrl.text.trim();
                if (newId.isEmpty) return;

                await _admin.upsertSong(
                  songId: newId,
                  challengeId: challengeIdCtrl.text.trim(),
                  title: titleCtrl.text.trim(),
                  artist: artistCtrl.text.trim(),
                  year: int.tryParse(yearCtrl.text.trim()) ?? 2000,
                  album: albumCtrl.text.trim().isEmpty ? null : albumCtrl.text.trim(),
                  previewUrl: previewCtrl.text.trim().isEmpty ? null : previewCtrl.text.trim(),
                  keywords: keywords,
                );

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
