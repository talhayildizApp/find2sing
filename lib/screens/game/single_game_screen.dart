import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'game_config.dart'; // SongMode & EndCondition
import 'single_result_screen.dart';

/// JSON’daki kelime modeli
class WordEntry {
  final int id;
  final String word;

  WordEntry({required this.id, required this.word});

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      id: json['id'] as int,
      word: json['word'] as String,
    );
  }
}

/// Result ekranına göndereceğimiz şarkı modeli
class SingleSongResult {
  final String word;
  final String song;
  final String artist;

  SingleSongResult({
    required this.word,
    required this.song,
    required this.artist,
  });
}

class SingleGameScreen extends StatefulWidget {
  final int countdownSeconds; // her kelime için süre
  final SongMode songMode; // Tek / Çoklu
  final EndCondition endCondition; // şarkı sayısı / süre
  final int songTarget; // şarkı hedefi
  final int timeMinutes; // toplam süre (dakika)
  final int wordChangeCount; // kelime değiştirme hakkı

  const SingleGameScreen({
    super.key,
    required this.countdownSeconds,
    required this.songMode,
    required this.endCondition,
    required this.songTarget,
    required this.timeMinutes,
    required this.wordChangeCount,
  });

  @override
  State<SingleGameScreen> createState() => _SingleGameScreenState();
}

class _SingleGameScreenState extends State<SingleGameScreen> {
  // ---------- STATE ----------
  int _wordSecondsLeft = 0; // kelime sayacı
  int _gameSecondsLeft = 0; // toplam oyun süresi (sadece time modunda)
  int _totalElapsedSeconds = 0; // result için toplam geçen süre

  int _remainingChangeCount = 0; // kalan değiştirme hakkı
  bool _hasAnsweredCurrentWord = false; // bu kelimeye şarkı yazıldı mı?

  bool _isFinished = false;

  Timer? _timer;

  final TextEditingController _songCtrl = TextEditingController();
  final TextEditingController _artistCtrl = TextEditingController();

  // JSON’dan gelen kelimeler
  List<WordEntry> _allWords = [];
  List<WordEntry> _remainingWords = [];
  final Set<int> _usedWordIds = {};

  WordEntry? _currentEntry;

  String get _currentWord => _currentEntry?.word ?? '...';

  final List<SingleSongResult> _foundSongs = [];

  bool get _isLoaded => _currentEntry != null;

  @override
  void initState() {
    super.initState();
    _remainingChangeCount = widget.wordChangeCount;
    _loadWordsAndStart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _songCtrl.dispose();
    _artistCtrl.dispose();
    super.dispose();
  }

  // ---------- WORD LOADING & RANDOM ----------

  Future<void> _loadWordsAndStart() async {
    try {
      final raw = await rootBundle.loadString('assets/words/word_list_tr.json');
      final data = jsonDecode(raw) as List<dynamic>;
      _allWords = data.map((e) => WordEntry.fromJson(e)).toList();
      _remainingWords = List.of(_allWords);

      _selectNextWord(); // ilk kelime
      _startTimers();
    } catch (e) {
      debugPrint('Kelime yükleme hatası: $e');
    }
  }

  /// Remaining list’ten rastgele bir sonraki kelimeyi seçer.
  /// Hiç kelime kalmadıysa mevcut kelimeyi korur.
  void _selectNextWord() {
    if (_remainingWords.isEmpty) return;

    final idx = Random().nextInt(_remainingWords.length);
    final entry = _remainingWords.removeAt(idx);
    _usedWordIds.add(entry.id);

    _currentEntry = entry;
    _hasAnsweredCurrentWord = false; // yeni kelime için henüz cevap yok
  }

  // ---------- TIMERS ----------

  void _startTimers() {
    _timer?.cancel();

    _wordSecondsLeft = widget.countdownSeconds;
    _gameSecondsLeft = widget.timeMinutes * 60;
    _totalElapsedSeconds = 0;
    _isFinished = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished) return;

      setState(() {
        _totalElapsedSeconds++;

        // kelime süresi
        if (_wordSecondsLeft > 1) {
          _wordSecondsLeft--;
        } else {
          _wordSecondsLeft = widget.countdownSeconds;
          // Süre bittiğinde yeni kelime, hak tüketmeden
          _selectNextWord();
        }

        // oyun toplam süresi, sadece süre modunda önemli
        if (widget.endCondition == EndCondition.time) {
          if (_gameSecondsLeft > 1) {
            _gameSecondsLeft--;
          } else {
            _gameSecondsLeft = 0;
            _finishGame();
            timer.cancel();
          }
        }
      });
    });
  }

  // ---------- GAME ACTIONS ----------

  /// Değiştir butonu
  void _onChangePressed() {
    if (_isFinished || !_isLoaded) return;
    if (_remainingWords.isEmpty) return;

    bool freeChange = false;

    // Çoklu modda, bu kelimeye en az bir şarkı yazıldıysa değiştir ücretsiz
    if (widget.songMode == SongMode.multiple && _hasAnsweredCurrentWord) {
      freeChange = true;
    }

    // Ücretsiz değilse hak düşür
    if (!freeChange) {
      if (_remainingChangeCount <= 0) {
        return; // hiç hakkı yok, hiçbir şey yapma
      }
      _remainingChangeCount--;
    }

    setState(() {
      _selectNextWord();
      _wordSecondsLeft = widget.countdownSeconds;
    });
  }

  /// + Ekle
  void _onAddSong() {
    if (_isFinished || !_isLoaded) return;

    final song = _songCtrl.text.trim();
    final artist = _artistCtrl.text.trim();
    if (song.isEmpty || artist.isEmpty) return;

    setState(() {
      _foundSongs.add(
        SingleSongResult(word: _currentWord, song: song, artist: artist),
      );
      _hasAnsweredCurrentWord = true; // bu kelime için en az bir cevap var
      _songCtrl.clear();
      _artistCtrl.clear();
    });

    // Tekli modda şarkı eklendiğinde kelime otomatik değişsin (hak yemeden)
    if (widget.songMode == SongMode.single) {
      setState(() {
        _selectNextWord();
        _wordSecondsLeft = widget.countdownSeconds;
      });
    }

    // Şarkı sayısı modunda bitiş kontrolü
    if (widget.endCondition == EndCondition.songCount &&
        _foundSongs.length >= widget.songTarget) {
      _finishGame();
    }
  }

  void _finishGame() {
    if (_isFinished) return;

    _timer?.cancel();
    setState(() {
      _isFinished = true;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SingleGameResultScreen(
          songs: _foundSongs,
          totalElapsedSeconds: _totalElapsedSeconds,
        ),
      ),
    );
  }

  String _formatWordTime() {
    if (_wordSecondsLeft <= 0) return '0:00';
    final m = _wordSecondsLeft ~/ 60;
    final s = _wordSecondsLeft % 60;
    final ss = s.toString().padLeft(2, '0');
    return '$m:$ss';
  }

  String _formatGameTime() {
    if (_gameSecondsLeft <= 0) return '0:00';
    final m = _gameSecondsLeft ~/ 60;
    final s = _gameSecondsLeft % 60;
    final ss = s.toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final wordTime = _formatWordTime();
    final gameTimeText = _formatGameTime();
    final showGameTime = widget.endCondition == EndCondition.time;

    // Bu kelime için gerçekten değiştirilebilir mi?
    final bool canChange = !_isFinished &&
        _isLoaded &&
        _remainingWords.isNotEmpty &&
        (
          // Tekli mod → sadece hakkı varsa
          (widget.songMode == SongMode.single && _remainingChangeCount > 0) ||
          // Çoklu mod → ya hakkı varsa, ya da bu kelimeye şarkı yazıldığı için ücretsiz değişim
          (widget.songMode == SongMode.multiple &&
              (_remainingChangeCount > 0 || _hasAnsweredCurrentWord))
        );

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Logo
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
                const SizedBox(height: 12),

                // Güneş + Değiştir + (varsa) genel sayaç
                SizedBox(
                  height: 210,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Genel süre (yalnızca süre modunda)
                        if (showGameTime)
                          Positioned(
                            top: 0,
                            bottom: 170,
                            child: Center(
                              child: RotatedBox(
                                quarterTurns: 4,
                                child: Text(
                                  gameTimeText,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF394272),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Güneş
                        Image.asset(
                          'assets/images/friend_sun.png',
                          width: 220,
                          height: 220,
                        ),

                        // Kelime
                        Text(
                          _currentWord.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF394272),
                          ),
                        ),

                        // Kelime süresi
                        Positioned(
                          top: 60,
                          child: Text(
                            wordTime,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF394272),
                            ),
                          ),
                        ),

                        // Değiştir butonu
                        Positioned(
                          bottom: 30,
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: canChange ? _onChangePressed : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB958),
                                disabledBackgroundColor:
                                    const Color(0xFFFFD6A0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Değiştir',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF394272),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Değiştirme hakkın: $_remainingChangeCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF394272),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ORTA KISIM: Scroll + klavye padding
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      16 + (bottomInset > 0 ? bottomInset : 0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Şarkı / Şarkıcı inputları
                        _buildTextField(
                          controller: _songCtrl,
                          hint: 'Şarkı',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _artistCtrl,
                          hint: 'Şarkıcı',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _onAddSong,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCAB7FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              '+ Ekle',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF394272),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bulduğun şarkılar kartı
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7FF),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bulduğun Şarkılar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF394272),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 250,
                                child: _foundSongs.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Henüz şarkı eklemedin',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFAAAAAA),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _foundSongs.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                          height: 18,
                                          thickness: 1,
                                          color: Color(0xFFCBD2F0),
                                        ),
                                        itemBuilder: (context, index) {
                                          final row = _foundSongs[index];
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Flexible(
                                                flex: 2,
                                                child: Text(
                                                  row.song,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Color(0xFF394272),
                                                  ),
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Color(0xFF394272),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Alt butonlar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _finishGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB958),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Bitir',
                              style: TextStyle(
                                fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
