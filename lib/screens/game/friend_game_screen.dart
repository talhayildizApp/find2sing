import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:provider/provider.dart';

import 'package:sarkiapp/screens/game/friends_result_screen.dart';
import 'package:sarkiapp/widgets/local_game_ui_components.dart';
import '../../providers/auth_provider.dart';
import '../../services/rewards_service.dart';
import 'game_config.dart';

class FriendGameScreen extends StatefulWidget {
  final int countdownSeconds;
  final SongMode songMode;
  final EndCondition endCondition;
  final int songTarget;
  final int timeMinutes;
  final int wordChangeCount;

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

/// Kelime modeli
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

class _FriendGameScreenState extends State<FriendGameScreen>
    with TickerProviderStateMixin {
  int _currentPlayer = 1;
  int _score1 = 0;
  int _score2 = 0;

  int _wordSecondsLeft = 0;
  int _gameSecondsLeft = 0;
  int _totalElapsedSeconds = 0;

  late int _wordChanges1;
  late int _wordChanges2;

  Timer? _timer;
  bool _isFinished = false;

  List<WordEntry> _allWords = [];
  List<WordEntry> _remainingWords = [];
  WordEntry? _currentEntry;
  String get _currentWord => _currentEntry?.word ?? '...';
  final Set<int> _usedWordIds = {};

  // Animation controllers
  late AnimationController _turnTransitionController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initGame();
  }

  void _initAnimations() {
    _turnTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _turnTransitionController.dispose();
    super.dispose();
  }

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

  Future<void> _loadWords() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/words/word_list_tr.json');
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;

      _allWords = data
          .map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
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

  void _resetWordPool() {
    _remainingWords = List<WordEntry>.from(_allWords);
    _remainingWords.shuffle();
    _usedWordIds.clear();
  }

  WordEntry _drawWord() {
    if (_remainingWords.isEmpty) {
      _resetWordPool();
    }
    final entry = _remainingWords.removeLast();
    _usedWordIds.add(entry.id);
    return entry;
  }

  void _startTimers() {
    _timer?.cancel();

    _wordSecondsLeft = widget.countdownSeconds;
    _gameSecondsLeft = widget.timeMinutes * 60;
    _totalElapsedSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished) return;

      setState(() {
        _totalElapsedSeconds++;

        if (_wordSecondsLeft > 1) {
          _wordSecondsLeft--;
        } else {
          _wordSecondsLeft = widget.countdownSeconds;
          _nextWord();
        }

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

  void _nextWord({bool switchPlayer = true}) {
    _currentEntry = _drawWord();
    if (switchPlayer) {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      _animateTurnTransition();
    }
  }

  void _animateTurnTransition() {
    _turnTransitionController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _onFoundSong(int player) {
    if (_isFinished) return;
    if (player != _currentPlayer) return;

    HapticFeedback.heavyImpact();

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

  Future<void> _onPass() async {
    if (_isFinished) return;

    if (_currentPlayer == 1) {
      if (_wordChanges1 <= 0) return;
      HapticFeedback.lightImpact();

      // Firestore'da kelime değiştirme hakkını düşür
      final user = context.read<AuthProvider>().user;
      if (user != null && !user.isActivePremium) {
        await RewardsService().useJoker(user);
        if (mounted) {
          await context.read<AuthProvider>().refreshUser();
        }
      }

      setState(() {
        _wordChanges1--;
        _wordSecondsLeft = widget.countdownSeconds;
        _nextWord(switchPlayer: false);
      });
    } else {
      if (_wordChanges2 <= 0) return;
      HapticFeedback.lightImpact();

      // Firestore'da kelime değiştirme hakkını düşür
      final user = context.read<AuthProvider>().user;
      if (user != null && !user.isActivePremium) {
        await RewardsService().useJoker(user);
        if (mounted) {
          await context.read<AuthProvider>().refreshUser();
        }
      }

      setState(() {
        _wordChanges2--;
        _wordSecondsLeft = widget.countdownSeconds;
        _nextWord(switchPlayer: false);
      });
    }
  }

  void _endGame() {
    _timer?.cancel();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FriendGameResultScreen(
          player1Score: _score1,
          player2Score: _score2,
          totalElapsedSeconds: _totalElapsedSeconds,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _finishGame() {
    if (_isFinished) return;

    _timer?.cancel();

    setState(() {
      _isFinished = true;
    });

    _endGame();
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LocalGameColors.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: LocalGameColors.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Oyundan Çık',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: LocalGameColors.darkPurple,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Oyundan çıkmak istediğine emin misin? Mevcut ilerleme kaybolacak.',
          style: TextStyle(
            color: LocalGameColors.darkPurple,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Devam Et',
              style: TextStyle(
                color: LocalGameColors.darkPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LocalGameColors.accentOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Çık',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWordChanges =
        _currentPlayer == 1 ? _wordChanges1 : _wordChanges2;
    final canChange = currentWordChanges > 0;
    final showGameTimer = widget.endCondition == EndCondition.time;

    return LocalGameScaffold(
      child: Column(
        children: [
          // Player 2 section (rotated - top)
          Expanded(
            child: PlayerCard(
              playerNumber: 2,
              score: _score2,
              wordChanges: _wordChanges2,
              isActive: _currentPlayer == 2,
              onFound: () => _onFoundSong(2),
              rotated: true,
            ),
          ),

          // Center word display (now includes game timer)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CenterWordDisplay(
              word: _currentWord,
              secondsLeft: _wordSecondsLeft,
              maxSeconds: widget.countdownSeconds,
              currentPlayer: _currentPlayer,
              canChange: canChange,
              onChangeWord: _onPass,
              gameSecondsLeft: _gameSecondsLeft,
              showGameTimer: showGameTimer,
            ),
          ),

          // Player 1 section (normal - bottom)
          Expanded(
            child: PlayerCard(
              playerNumber: 1,
              score: _score1,
              wordChanges: _wordChanges1,
              isActive: _currentPlayer == 1,
              onFound: () => _onFoundSong(1),
              rotated: false,
            ),
          ),

          // Bottom action bar
          BottomActionBar(
            onMenu: _showExitConfirmation,
            onFinish: _finishGame,
          ),
        ],
      ),
    );
  }
}
