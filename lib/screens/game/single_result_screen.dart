import 'dart:math';
import 'package:flutter/material.dart';
import 'single_game_screen.dart'; // SingleSongResult modelini kullanmak için
import 'package:share_plus/share_plus.dart';

class SingleGameResultScreen extends StatefulWidget {
  final List<SingleSongResult> songs;
  final int totalElapsedSeconds;

  const SingleGameResultScreen({
    super.key,
    required this.songs,
    required this.totalElapsedSeconds,
  });

  @override
  State<SingleGameResultScreen> createState() =>
      _SingleGameResultScreenState();
}

class _SingleGameResultScreenState extends State<SingleGameResultScreen> {
  static const int _pageSize = 5;
  int _currentPage = 0;

  int get _pageCount =>
      widget.songs.isEmpty ? 1 : (widget.songs.length / _pageSize).ceil();

  List<SingleSongResult> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = min(start + _pageSize, widget.songs.length);
    if (start >= end) return [];
    return widget.songs.sublist(start, end);
  }

  String _formatTotalTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  void _shareResults() {
    final timeText = _formatTotalTime(widget.totalElapsedSeconds);

    final buffer = StringBuffer();
    buffer.writeln('Find2Sing oyun sonucum:');
    buffer.writeln('Toplam süre: $timeText');
    buffer.writeln('Toplam şarkı: ${widget.songs.length}');
    buffer.writeln('');

    for (final s in widget.songs) {
      buffer.writeln('- ${s.song} — ${s.artist} (kelime: ${s.word})');
    }

    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final totalSongs = widget.songs.length;
    final timeText = _formatTotalTime(widget.totalElapsedSeconds);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_music_clouds.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // LOGO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/logo_find2sing.png',
                    width: 120,
                  ),
                ),
              ),

              // -------- ORTA BLOK --------
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Oyun Tamamlandı',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF394272),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalSongs şarkı buldun!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF394272),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toplam Süre: $timeText',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF394272),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // KART
                      SizedBox(
                        width: size.width * 0.8,
                        height: size.height * 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FF),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sayfa ${_currentPage + 1} / $_pageCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF394272),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Başlık + paylaş ikonu
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Bulduğun Şarkılar',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF394272),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _shareResults,
                                    icon: const Icon(Icons.ios_share),
                                    color: const Color(0xFF394272),
                                    tooltip: 'Sonucu paylaş',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Expanded(
                                child: Row(
                                  children: [
                                    // Sol ok
                                    IconButton(
                                      iconSize: 26,
                                      onPressed: _currentPage > 0
                                          ? () => setState(() {
                                                _currentPage--;
                                              })
                                          : null,
                                      icon: const Icon(Icons.chevron_left),
                                      color: const Color(0xFF394272),
                                    ),
                                    // Liste
                                    Expanded(
                                      child: _currentPageItems.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'Henüz şarkı yok',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF888888),
                                                ),
                                              ),
                                            )
                                          : ListView.separated(
                                              itemCount:
                                                  _currentPageItems.length,
                                              separatorBuilder: (_, __) =>
                                                  const Divider(
                                                height: 20,
                                                thickness: 1,
                                                color: Color(0xFFCBD2F0),
                                              ),
                                              itemBuilder: (context, index) {
                                                final row =
                                                    _currentPageItems[index];
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      flex: 2,
                                                      child: Text(
                                                        row.song,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                              0xFF394272),
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Flexible(
                                                      flex: 2,
                                                      child: Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Text(
                                                          row.artist,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Color(
                                                                0xFF394272),
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                    ),
                                    // Sağ ok
                                    IconButton(
                                      iconSize: 26,
                                      onPressed:
                                          _currentPage < _pageCount - 1
                                              ? () => setState(() {
                                                    _currentPage++;
                                                  })
                                              : null,
                                      icon: const Icon(Icons.chevron_right),
                                      color: const Color(0xFF394272),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------- ALT BUTONLAR --------
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF394272),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Ana Menü',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // oyuna geri dön
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB958),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Tekrar Oyna',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFFFFF),
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
        ),
      ),
    );
  }
}
