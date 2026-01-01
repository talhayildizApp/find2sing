import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:sarkiapp/screens/game/friends_result_screen.dart';
import 'game_config.dart'; // SongMode & EndCondition burada tanımlı

class FriendGameScreen extends StatefulWidget {
  final int countdownSeconds; // her kelime için süre
  final SongMode songMode;
  final EndCondition endCondition; // şarkı sayısı / süre
  final int songTarget;
  final int timeMinutes; // toplam oyun süresi (dakika)
  final int wordChangeCount; // kişi başı kelime değiştirme hakkı

  const FriendGameScreen({
    super.key,
    required this.countdownSeconds,
    required this.songMode,
    required this.endCondition,
    required this.songTarget,
    required this.timeMinutes,
    required this.wordChangeCount,
  });

  @override
  State<FriendGameScreen> createState() => _FriendGameScreenState();
}

/// Kelimeyi güneşin içine uygun hale getirir:
/// - Boşlukları satıra çevirir: "AYAĞA KALKMAK" -> "AYAĞA\nKALKMAK"
String _prepareWordForSun(String word) {
  final trimmed = word.trim().toUpperCase();
  final parts = trimmed.split(RegExp(r'\s+'));
  return parts.join('\n');
}

/// Kelime uzunluğuna göre dinamik font boyutu
double _fontSizeForSun(String word) {
  final len = word.replaceAll(' ', '').length;

  if (len <= 4) return 28;   // KALP, AŞK
  if (len <= 7) return 24;   // GECE, ÖLÜM
  if (len <= 10) return 20;  // YAĞMURLU, YALNIZLIK
  return 18;                 // AYAĞA KALKMAK gibi uzunlar
}

/// JSON’dan gelecek kelime modeli
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

class _FriendGameScreenState extends State<FriendGameScreen> {
  int _currentPlayer = 1; // 1 = Oyuncu 1, 2 = Oyuncu 2
  int _score1 = 0;
  int _score2 = 0;

  // Sayaçlar
  int _wordSecondsLeft = 0;
  int _gameSecondsLeft = 0;
  int _totalElapsedSeconds = 0;

  // Kelime değiştirme hakları
  late int _wordChanges1;
  late int _wordChanges2;

  Timer? _timer;
  bool _isFinished = false;

  // --------- Kelime havuzu (tekrarsız rastgele) ---------

  // Tüm kelimeler (JSON’dan yüklenen)
  List<WordEntry> _allWords = [];

  // Oyun sırasında henüz çıkmamış kelimeler
  List<WordEntry> _remainingWords = [];

  // Ekranda görünen kelime
  WordEntry? _currentEntry;
  String get _currentWord => _currentEntry?.word ?? '...';

  // (İstersen hangi kelimeler oynandı diye bakmak için)
  final Set<int> _usedWordIds = {};

  // ------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _initGame(); // kelimeleri yükle + ilk kelimeyi seç + sayaçları başlat
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Oyun başlangıç ayarları
  Future<void> _initGame() async {
    await _loadWords();

    setState(() {
      _currentPlayer = 1;
      _score1 = 0;
      _score2 = 0;
      _wordChanges1 = widget.wordChangeCount;
      _wordChanges2 = widget.wordChangeCount;
      _isFinished = false;

      _resetWordPool();
      _currentEntry = _drawWord();
    });

    _startTimers();
  }

  // JSON’dan kelime listesi yükle
  Future<void> _loadWords() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/words/word_list_tr.json');
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;

      _allWords = data
          .map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Şimdilik fallback: eski sabit liste
      _allWords = [
        WordEntry(id: 1, word: 'ölüm'),
        WordEntry(id: 2, word: 'gece'),
        WordEntry(id: 3, word: 'güneş'),
        WordEntry(id: 4, word: 'kalp'),
        WordEntry(id: 5, word: 'rüya'),
        WordEntry(id: 6, word: 'yağmur'),
        WordEntry(id: 7, word: 'yol'),
        WordEntry(id: 8, word: 'ateş'),
        WordEntry(id: 9, word: 'ışık'),
        WordEntry(id: 10, word: 'dans'),
      ];
    }
  }

  // Havuzu sıfırla ve karıştır
  void _resetWordPool() {
    _remainingWords = List<WordEntry>.from(_allWords);
    _remainingWords.shuffle(); // her oyunda farklı sıra
    _usedWordIds.clear();
  }

  // Havuzdan tekrarsız kelime çek
  WordEntry _drawWord() {
    if (_remainingWords.isEmpty) {
      // teoride 5000 kelimede zor ama yine de güvenli olsun
      _resetWordPool();
    }
    final entry = _remainingWords.removeLast();
    _usedWordIds.add(entry.id);
    return entry;
  }

  // ---------------- Sayaçlar ----------------

  void _startTimers() {
    _timer?.cancel();

    _wordSecondsLeft = widget.countdownSeconds;
    _gameSecondsLeft = widget.timeMinutes * 60;
    _totalElapsedSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished) return;

      setState(() {
        _totalElapsedSeconds++;

        // kelime sayacı
        if (_wordSecondsLeft > 1) {
          _wordSecondsLeft--;
        } else {
          _wordSecondsLeft = widget.countdownSeconds;
          _nextWord(); // süre bitti → yeni kelime ve oyuncu değişsin
        }

        // toplam oyun süresi (sadece süre modunda önemli)
        if (widget.endCondition == EndCondition.time) {
          if (_gameSecondsLeft > 1) {
            _gameSecondsLeft--;
          } else {
            _gameSecondsLeft = 0;
            _finishGame(); // artık result ekrana gidecek
            timer.cancel();
          }
        }
      });
    });
  }

  void _nextWord({bool switchPlayer = true}) {
    _currentEntry = _drawWord(); // tekrarsız rastgele kelime
    if (switchPlayer) {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    }
  }

  void _onFoundSong(int player) {
    if (_isFinished) return;
    if (player != _currentPlayer) return; // sadece sırası gelen oyuncu

    setState(() {
      if (player == 1) {
        _score1++;
      } else {
        _score2++;
      }
      _wordSecondsLeft = widget.countdownSeconds;
      _nextWord();
    });

    if (widget.endCondition == EndCondition.songCount) {
      if (_score1 >= widget.songTarget || _score2 >= widget.songTarget) {
        _finishGame();
      }
    }
  }

  void _onPass() {
    if (_isFinished) return;

    // sıradaki oyuncunun hakkına göre kontrol et
    if (_currentPlayer == 1) {
      if (_wordChanges1 <= 0) return;
      setState(() {
        _wordChanges1--;
        _wordSecondsLeft = widget.countdownSeconds;
        _nextWord(switchPlayer: false);
      });
    } else {
      if (_wordChanges2 <= 0) return;
      setState(() {
        _wordChanges2--;
        _wordSecondsLeft = widget.countdownSeconds;
        _nextWord(switchPlayer: false);
      });
    }
  }

  /// 🔹 Result ekranına geçiş
  void _endGame() {
    _timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FriendGameResultScreen(
          player1Score: _score1,
          player2Score: _score2,
          totalElapsedSeconds: _totalElapsedSeconds,
        ),
      ),
    );
  }

  /// 🔹 Artık popup yerine direkt result ekrana yönlendiriyor
  void _finishGame() {
    if (_isFinished) return;

    _timer?.cancel();

    setState(() {
      _isFinished = true;
    });

    _endGame();
  }

  String _formatGameTime() {
    final m = _gameSecondsLeft ~/ 60;
    final s = _gameSecondsLeft % 60;
    final ss = s.toString().padLeft(2, '0');
    return '$m:$ss';
  }

  String _formatWordTime() {
    final m = _wordSecondsLeft ~/ 60;
    final s = _wordSecondsLeft % 60;
    final ss = s.toString().padLeft(2, '0');
    return '$m:$ss';
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    const topColor = Color(0xFFE7ECFF);
    const middleColor = Color(0xFFDCD1FF);
    const bottomCream = Color(0xFFFBEEC7);

    final sunLabel = _currentWord.toUpperCase();
    final wordTimeText = _formatWordTime();
    final gameTimeText = _formatGameTime();
    final showGameTime = widget.endCondition == EndCondition.time;

    final currentWordChanges =
        _currentPlayer == 1 ? _wordChanges1 : _wordChanges2;
    final canChange = currentWordChanges > 0;

    return Scaffold(
      body: Column(
        children: [
          // Üst + orta: oyuncu alanları + güneş
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: topColor,
                        child: _buildPlayerRow(
                          playerIndex: 1,
                          score: _score1,
                          isCurrent: _currentPlayer == 1,
                          onFound: () => _onFoundSong(1),
                          wordChanges: _wordChanges1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: middleColor,
                        child: _buildPlayerRow(
                          playerIndex: 2,
                          score: _score2,
                          isCurrent: _currentPlayer == 2,
                          onFound: () => _onFoundSong(2),
                          wordChanges: _wordChanges2,
                        ),
                      ),
                    ),
                  ],
                ),

                // Ortadaki güneş + kelime + kelime sayacı + Değiştir
                _buildCenterSun(
                  sunLabel: sunLabel,
                  wordTimeText: wordTimeText,
                  canChange: canChange,
                ),

                // Toplam oyun süresi: sadece süre modunda görünür
                if (showGameTime)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
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
              ],
            ),
          ),

          // Alt krem bar – tam genişlik, radius yok, butonlar ortalı
          Container(
            color: bottomCream,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                              Navigator.of(context).popUntil(
                                (route) => route.isFirst,
                              );
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
    );
  }

  // Oyuncu satırı (üst ve orta)
  Widget _buildPlayerRow({
    required int playerIndex,
    required int score,
    required bool isCurrent,
    required VoidCallback onFound,
    required int wordChanges,
  }) {
    const baseColor = Color(0xFF394272);
    final muted = baseColor.withValues(alpha: isCurrent ? 1.0 : 0.4);

    final playerText = 'Oyuncu $playerIndex';
    final scoreText = '$score Şarkı';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // SOL BLOK: Oyuncu X
          SizedBox(
            width: 70,
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  playerText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ),
            ),
          ),

          // ORTA BLOK: 0 Şarkı (tam arada)
          Expanded(
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  scoreText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ),
            ),
          ),

          // SAĞ BLOK: BULDUM dikey + 3 Hak yatay
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BULDUM (her zaman dikey)
                RotatedBox(
                  quarterTurns: 3,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isCurrent ? onFound : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB958),
                        disabledBackgroundColor: const Color(0xFFFFD6A0),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: isCurrent ? 4 : 1,
                      ),
                      child: const Text(
                        'BULDUM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF394272),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // 3 Hak (yatay)
                RotatedBox( 
                  quarterTurns: 3, 
                  child: Text( 
                    '$wordChanges Hak', 
                    style: const TextStyle( 
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: Color(0xFF394272), ),
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ortadaki güneş + kelime + kelime sayacı + Değiştir
  Widget _buildCenterSun({
    required String sunLabel,
    required String wordTimeText,
    required bool canChange,
  }) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // PNG güneş
          Image.asset(
            'assets/images/friend_sun.png',
            width: 230,
            height: 230,
          ),

          // Kelime (Ortada dikey)
          // Kelime (Ortada dikey, çok uzunsa satırlara bölünmüş ve küçültülmüş)
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  _prepareWordForSun(sunLabel),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: _fontSizeForSun(sunLabel),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF394272),
                  ),
                ),
              ),


          // Kelime süresi — kelimenin SOL TARAFINDA YATAY
          Positioned(
            left: 60,
            child: RotatedBox(
              quarterTurns: 3,
            child: Text(
              wordTimeText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
            ),
          ),
          ),
          // Değiştir butonu — Sağda
          Positioned(
            right: 12,
            child: RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: canChange ? _onPass : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB958),
                    disabledBackgroundColor: const Color(0xFFFFD6A0),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
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
          ),
        ],
      ),
    );
  }
}
