// lib/screens/admin/admin_content_builder_screen.dart
//
// Admin "Content Builder":
// - Choose Language (tr/en/de/es)
// - Choose Category + Challenge (or type challenge id)
// - Paste Artist + Song Title + Lyrics
// - Auto-generate keywords (preserving native characters)
// - Review: add/remove keywords (chips)
// - Save to Firestore (songs/{songId})
//
// Requires:
// - lib/services/admin_content_service.dart
// - lib/services/lyrics_keyword_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_content_service.dart';
import '../../services/lyrics_keyword_service.dart';

class AdminContentBuilderScreen extends StatefulWidget {
  const AdminContentBuilderScreen({super.key});

  @override
  State<AdminContentBuilderScreen> createState() => _AdminContentBuilderScreenState();
}

class _AdminContentBuilderScreenState extends State<AdminContentBuilderScreen> {
  final _admin = AdminContentService();
  final _extractor = LyricsKeywordService();

  String _language = 'tr';
  bool _removeStopwords = true;

  String? _categoryId;
  String? _challengeId;

  final _artistCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();
  final _songIdCtrl = TextEditingController();

  final _manualAddCtrl = TextEditingController();

  List<String> _keywords = [];
  List<String> _top = [];

  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _artistCtrl.dispose();
    _titleCtrl.dispose();
    _lyricsCtrl.dispose();
    _songIdCtrl.dispose();
    _manualAddCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final lyrics = _lyricsCtrl.text;
    if (lyrics.trim().isEmpty) {
      setState(() => _status = 'Paste lyrics first.');
      return;
    }

    final res = _extractor.extract(
      lyricsRaw: lyrics,
      languageCode: _language,
      removeStopwords: _removeStopwords,
      minTokenLength: 2,
      maxTopKeywords: 180,
    );

    setState(() {
      _keywords = res.keywords;
      _top = res.topKeywords;
      _status = 'Generated ${_keywords.length} keywords (top ${_top.length}).';
    });
  }

  void _addManual() {
    final raw = _manualAddCtrl.text.trim();
    if (raw.isEmpty) return;
    final parts = _extractor
        .parseManualTokens(raw)
        .map((e) => e.toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    setState(() {
      final set = {..._keywords, ...parts};
      _keywords = set.toList()..sort();

      final topSet = <String>{...parts, ..._top};
      _top = topSet.toList().take(220).toList();

      _manualAddCtrl.clear();
    });
  }

  Future<void> _save() async {
    final categoryId = _categoryId;
    final challengeId = _challengeId;

    if (categoryId == null || categoryId.isEmpty) {
      setState(() => _status = 'Select a category.');
      return;
    }
    if (challengeId == null || challengeId.isEmpty) {
      setState(() => _status = 'Select a challenge.');
      return;
    }

    final artist = _artistCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final lyrics = _lyricsCtrl.text.trim();

    if (artist.isEmpty || title.isEmpty || lyrics.isEmpty) {
      setState(() => _status = 'Artist, Title and Lyrics are required.');
      return;
    }

    final providedId = _songIdCtrl.text.trim();
    final songId = providedId.isNotEmpty ? providedId : _buildSongId(challengeId, artist, title);

    if (_keywords.isEmpty) {
      final res = _extractor.extract(
        lyricsRaw: lyrics,
        languageCode: _language,
        removeStopwords: _removeStopwords,
        minTokenLength: 2,
        maxTopKeywords: 180,
      );
      _keywords = res.keywords;
      _top = res.topKeywords;
    }

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      await _admin.upsertSong(
        songId: songId,
        categoryId: categoryId,
        challengeId: challengeId,
        languageCode: _language,
        artist: artist,
        title: title,
        lyricsRaw: lyrics,
        keywords: _keywords,
        topKeywords: _top.isNotEmpty ? _top : _keywords.take(180).toList(),
        year: 2000,
      );

      if (!mounted) return;
      setState(() => _status = '✅ Saved song: $songId');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $songId')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '❌ ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $e')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _buildSongId(String challengeId, String artist, String title) {
    String slug(String s) {
      final cleaned = s.trim().toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_');
      return cleaned.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    }

    return '${slug(challengeId)}_${slug(artist)}_${slug(title)}';
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: const [
                    DropdownMenuItem(value: 'tr', child: Text('Türkçe (tr)')),
                    DropdownMenuItem(value: 'en', child: Text('English (en)')),
                    DropdownMenuItem(value: 'de', child: Text('Deutsch (de)')),
                    DropdownMenuItem(value: 'es', child: Text('Español (es)')),
                  ],
                  onChanged: (v) => setState(() => _language = v ?? 'tr'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remove stopwords'),
                  value: _removeStopwords,
                  onChanged: (v) => setState(() => _removeStopwords = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CategoryAndChallengePickers(
            selectedCategoryId: _categoryId,
            selectedChallengeId: _challengeId,
            onCategoryChanged: (v) => setState(() => _categoryId = v),
            onChallengeChanged: (v) => setState(() => _challengeId = v),
            languageFilter: _language,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _artistCtrl,
            decoration: const InputDecoration(labelText: 'Artist'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Song title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _songIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Song ID (optional)',
              helperText: 'Leave empty to auto-generate.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lyricsCtrl,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Lyrics (raw)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate keywords'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save song'),
                ),
              ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Text(_status!, style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 16),
          const Text('Keywords (editable)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _keywords
                .map((w) => Chip(
                      label: Text(w),
                      onDeleted: () => setState(() {
                        _keywords.remove(w);
                        _top.remove(w);
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualAddCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add keywords (space/comma/newline separated)',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _addManual, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Top keywords (game pool)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _top
                .map((w) => Chip(
                      label: Text(w),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => setState(() => _top.remove(w)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryAndChallengePickers extends StatelessWidget {
  const _CategoryAndChallengePickers({
    required this.selectedCategoryId,
    required this.selectedChallengeId,
    required this.onCategoryChanged,
    required this.onChallengeChanged,
    required this.languageFilter,
  });

  final String? selectedCategoryId;
  final String? selectedChallengeId;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onChallengeChanged;
  final String languageFilter;

  @override
  Widget build(BuildContext context) {
    final categoriesStream = FirebaseFirestore.instance.collection('categories').orderBy('sortOrder').snapshots();
    final challengesStream = FirebaseFirestore.instance.collection('challenges').orderBy('title').snapshots();

    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: categoriesStream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
              }
              final docs = snap.data!.docs;

              return DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: docs
                    .map((d) => DropdownMenuItem<String>(
                          value: d.id,
                          child: Text((d.data()['title'] ?? d.id).toString()),
                        ))
                    .toList(),
                onChanged: onCategoryChanged,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: challengesStream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
              }
              final docs = snap.data!.docs.where((d) {
                final lang = (d.data()['language'] ?? '').toString();
                return lang.isEmpty || lang == languageFilter;
              }).toList();

              return DropdownButtonFormField<String>(
                value: selectedChallengeId,
                decoration: const InputDecoration(labelText: 'Challenge'),
                items: docs
                    .map((d) => DropdownMenuItem<String>(
                          value: d.id,
                          child: Text((d.data()['title'] ?? d.id).toString()),
                        ))
                    .toList(),
                onChanged: onChallengeChanged,
              );
            },
          ),
        ),
      ],
    );
  }
}
