import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'game_config.dart';
import 'single_result_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/rewards_service.dart';
import '../../widgets/game_feedback_widgets.dart';

/// JSON'daki kelime modeli
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

/// Polished Basic Mode Single Player Game Screen
/// - Playful, warm feel
/// - Micro-victory moments
/// - Living time indicators
/// - Clear feedback on all actions
class SingleGameScreen extends StatefulWidget {
  final int countdownSeconds;
  final SongMode songMode;
  final EndCondition endCondition;
  final int songTarget;
  final int timeMinutes;
  final int wordChangeCount;

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

class _SingleGameScreenState extends State<SingleGameScreen>
    with TickerProviderStateMixin {
  // State
  int _wordSecondsLeft = 0;
  int _gameSecondsLeft = 0;
  int _totalElapsedSeconds = 0;
  int _remainingChangeCount = 0;
  bool _hasAnsweredCurrentWord = false;
  bool _isFinished = false;

  Timer? _timer;

  final TextEditingController _songCtrl = TextEditingController();
  final TextEditingController _artistCtrl = TextEditingController();
  final FocusNode _songFocus = FocusNode();
  final FocusNode _artistFocus = FocusNode();

  List<WordEntry> _allWords = [];
  List<WordEntry> _remainingWords = [];
  final Set<int> _usedWordIds = {};
  WordEntry? _currentEntry;

  String get _currentWord => _currentEntry?.word ?? '...';
  final List<SingleSongResult> _foundSongs = [];
  bool get _isLoaded => _currentEntry != null;

  // Animations
  late AnimationController _wordPulseController;
  late AnimationController _addSuccessController;
  late Animation<double> _wordPulseAnimation;

  // Feedback state
  bool _showAddSuccess = false;
  bool _showChangeUsed = false;

  @override
  void initState() {
    super.initState();
    _remainingChangeCount = widget.wordChangeCount;
    _initAnimations();
    _loadWordsAndStart();
  }

  void _initAnimations() {
    _wordPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _wordPulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _wordPulseController, curve: Curves.easeInOut),
    );

    _addSuccessController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _songCtrl.dispose();
    _artistCtrl.dispose();
    _songFocus.dispose();
    _artistFocus.dispose();
    _wordPulseController.dispose();
    _addSuccessController.dispose();
    super.dispose();
  }

  Future<void> _loadWordsAndStart() async {
    try {
      final raw = await rootBundle.loadString('assets/words/word_list_tr.json');
      final data = jsonDecode(raw) as List<dynamic>;
      _allWords = data.map((e) => WordEntry.fromJson(e)).toList();
      _remainingWords = List.of(_allWords);

      _selectNextWord();
      _startTimers();
      HapticService.gameStart();
    } catch (e) {
      debugPrint('Kelime yükleme hatası: $e');
    }
  }

  void _selectNextWord() {
    if (_remainingWords.isEmpty) return;

    final idx = Random().nextInt(_remainingWords.length);
    final entry = _remainingWords.removeAt(idx);
    _usedWordIds.add(entry.id);

    setState(() {
      _currentEntry = entry;
      _hasAnsweredCurrentWord = false;
    });
  }

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

        // Word timer
        if (_wordSecondsLeft > 1) {
          _wordSecondsLeft--;
          
          // Haptic warnings
          if (_wordSecondsLeft <= 5) {
            HapticService.timeCritical();
          } else if (_wordSecondsLeft <= 10 && _wordSecondsLeft % 2 == 0) {
            HapticService.timeWarning();
          }
        } else {
          _wordSecondsLeft = widget.countdownSeconds;
          _selectNextWord();
        }

        // Game timer
        if (widget.endCondition == EndCondition.time) {
          if (_gameSecondsLeft > 1) {
            _gameSecondsLeft--;
            
            // Final minute warnings
            if (_gameSecondsLeft <= 60 && _gameSecondsLeft % 10 == 0) {
              HapticService.timeWarning();
            }
          } else {
            _gameSecondsLeft = 0;
            HapticService.timeExpired();
            _finishGame();
            timer.cancel();
          }
        }
      });
    });
  }

  Future<void> _onChangePressed() async {
    if (_isFinished || !_isLoaded) return;
    if (_remainingWords.isEmpty) return;

    bool freeChange = false;

    // Multi mode: free change if already answered
    if (widget.songMode == SongMode.multiple && _hasAnsweredCurrentWord) {
      freeChange = true;
    }

    if (!freeChange) {
      if (_remainingChangeCount <= 0) return;
      _remainingChangeCount--;

      // Firestore'da kelime değiştirme hakkını düşür
      final user = context.read<AuthProvider>().user;
      if (user != null && !user.isActivePremium) {
        await RewardsService().useJoker(user);
        if (mounted) {
          await context.read<AuthProvider>().refreshUser();
        }
      }

      // Show change used feedback
      setState(() => _showChangeUsed = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showChangeUsed = false);
      });
    }

    HapticService.wordChanged();

    setState(() {
      _selectNextWord();
      _wordSecondsLeft = widget.countdownSeconds;
    });
  }

  void _onAddSong() {
    if (_isFinished || !_isLoaded) return;

    final song = _songCtrl.text.trim();
    final artist = _artistCtrl.text.trim();
    if (song.isEmpty || artist.isEmpty) {
      HapticService.wrong();
      return;
    }

    HapticService.songAdded();

    setState(() {
      _foundSongs.add(
        SingleSongResult(word: _currentWord, song: song, artist: artist),
      );
      _hasAnsweredCurrentWord = true;
      _showAddSuccess = true;
      _songCtrl.clear();
      _artistCtrl.clear();
    });

    // Hide success feedback
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showAddSuccess = false);
    });

    // Single mode: auto-advance
    if (widget.songMode == SongMode.single) {
      setState(() {
        _selectNextWord();
        _wordSecondsLeft = widget.countdownSeconds;
      });
    }

    // Check song count target
    if (widget.endCondition == EndCondition.songCount &&
        _foundSongs.length >= widget.songTarget) {
      HapticService.challengeComplete();
      _finishGame();
    }
  }

  void _finishGame() {
    if (_isFinished) return;

    _timer?.cancel();
    setState(() => _isFinished = true);

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

  @override
  Widget build(BuildContext context) {
    final canChange = !_isFinished &&
        _isLoaded &&
        _remainingWords.isNotEmpty &&
        ((widget.songMode == SongMode.single && _remainingChangeCount > 0) ||
            (widget.songMode == SongMode.multiple &&
                (_remainingChangeCount > 0 || _hasAnsweredCurrentWord)));

    final isFreeChange = widget.songMode == SongMode.multiple && _hasAnsweredCurrentWord;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),

                // Word area with sun
                _buildWordArea(canChange, isFreeChange),

                // Change right indicator
                _buildChangeRightIndicator(isFreeChange),

                const SizedBox(height: 8),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInputSection(),
                        const SizedBox(height: 20),
                        _buildFoundSongsSection(),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                _buildBottomButtons(),
              ],
            ),
          ),

          // Song added success overlay
          if (_showAddSuccess)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SongAddedEffect(
                    onComplete: () {},
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_find2sing.png',
            width: 100,
          ),
          const Spacer(),

          // Game timer (time mode) - centered with color changing based on time
          if (widget.endCondition == EndCondition.time)
            _buildGameTimeIndicator(),

          // Song progress (song count mode)
          if (widget.endCondition == EndCondition.songCount)
            ChallengeProgressIndicator(
              solved: _foundSongs.length,
              total: widget.songTarget,
              color: const Color(0xFFFFB958),
            ),
        ],
      ),
    );
  }

  Widget _buildGameTimeIndicator() {
    final totalSeconds = widget.timeMinutes * 60;
    final ratio = _gameSecondsLeft / totalSeconds;

    // Color based on remaining time
    Color timerColor;
    if (ratio <= 0.1) {
      // Less than 10% - critical red
      timerColor = const Color(0xFFF85149);
    } else if (ratio <= 0.25) {
      // Less than 25% - warning orange
      timerColor = const Color(0xFFFF9800);
    } else {
      // Normal - nice blue
      timerColor = const Color(0xFF394272);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 4,
                  backgroundColor: timerColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(
                Icons.hourglass_top_rounded,
                size: 16,
                color: timerColor,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatGameTime(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: timerColor,
                ),
              ),
              Text(
                'kalan süre',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF6C6FA4).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordArea(bool canChange, bool isFreeChange) {
    final wordTimeRatio = _wordSecondsLeft / widget.countdownSeconds;
    final isUrgent = _wordSecondsLeft <= 10;
    final isCritical = _wordSecondsLeft <= 5;

    Color timerColor;
    if (isCritical) {
      timerColor = const Color(0xFFF85149);
    } else if (isUrgent) {
      timerColor = const Color(0xFFFF9800);
    } else {
      timerColor = const Color(0xFF394272);
    }

    return SizedBox(
      height: 220,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sun
            AnimatedBuilder(
              animation: _wordPulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _wordPulseAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/friend_sun.png',
                width: 200,
                height: 200,
              ),
            ),

            // Word
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                key: ValueKey(_currentWord),
                _currentWord.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF394272),
                  letterSpacing: 1,
                ),
              ),
            ),

            // Word timer (top)
            Positioned(
              top: 50,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isCritical ? 1.15 : 1.0),
                duration: Duration(milliseconds: isCritical ? 300 : 150),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: timerColor.withValues(alpha: isCritical ? 1 : 0.15),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isCritical ? [
                          BoxShadow(
                            color: timerColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 16,
                            color: isCritical ? Colors.white : timerColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatWordTime(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isCritical ? Colors.white : timerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Word timer progress arc (around sun)
            Positioned.fill(
              child: CustomPaint(
                painter: _TimerArcPainter(
                  progress: wordTimeRatio,
                  color: timerColor,
                  strokeWidth: 4,
                ),
              ),
            ),

            // Change button (bottom)
            Positioned(
              bottom: 20,
              child: _buildChangeButton(canChange, isFreeChange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeButton(bool canChange, bool isFreeChange) {
    return ElevatedButton(
      onPressed: canChange ? _onChangePressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isFreeChange
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFFB958),
        disabledBackgroundColor: const Color(0xFFE0E0E0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: canChange ? 4 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFreeChange ? Icons.swap_horiz_rounded : Icons.refresh_rounded,
            size: 18,
            color: canChange ? Colors.white : const Color(0xFF9E9E9E),
          ),
          const SizedBox(width: 6),
          Text(
            isFreeChange ? 'Değiştir (Ücretsiz)' : 'Değiştir',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: canChange ? Colors.white : const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRightIndicator(bool isFreeChange) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _showChangeUsed
              ? Container(
                  key: const ValueKey('used'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB958).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFB958).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFFFFB958)),
                      SizedBox(width: 6),
                      Text(
                        'Hak kullanıldı',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFB958),
                        ),
                      ),
                    ],
                  ),
                )
              : ChangeRightIndicator(
                  key: const ValueKey('indicator'),
                  remaining: _remainingChangeCount,
                  total: widget.wordChangeCount,
                  isFree: isFreeChange,
                ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Song input
          GameInputField(
            controller: _songCtrl,
            hint: 'Şarkı adı',
            prefixEmoji: '🎵',
            focusNode: _songFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: () => _artistFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          
          // Artist input
          GameInputField(
            controller: _artistCtrl,
            hint: 'Sanatçı',
            prefixEmoji: '🎤',
            focusNode: _artistFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: _onAddSong,
          ),
          const SizedBox(height: 16),
          
          // Add button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _onAddSong,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCAB7FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFCAB7FF).withValues(alpha:0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundSongsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FF).withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note_rounded, color: Color(0xFFCAB7FF), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Bulduğun Şarkılar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                ),
              ),
              if (_foundSongs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_foundSongs.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _foundSongs.isEmpty
                ? const EmptyStateWidget(
                    message: 'Henüz şarkı eklemedin',
                    hint: 'Yukarıdan şarkı ve sanatçı girerek başla!',
                    icon: Icons.music_off_rounded,
                  )
                : ListView.separated(
                    itemCount: _foundSongs.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 16,
                      thickness: 1,
                      color: Color(0xFFE8E0FF),
                    ),
                    itemBuilder: (context, index) {
                      final song = _foundSongs[_foundSongs.length - 1 - index];
                      return _buildSongItem(song, index == 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(SingleSongResult song, bool isNew) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: isNew ? 0.0 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.song,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF394272),
                  ),
                ),
                Text(
                  song.artist,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFCAB7FF).withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              song.word,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFCAB7FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF394272),
                  side: const BorderSide(color: Color(0xFF394272)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Ana Menü',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _finishGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB958),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Bitir',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWordTime() {
    if (_wordSecondsLeft <= 0) return '0:00';
    final m = _wordSecondsLeft ~/ 60;
    final s = _wordSecondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatGameTime() {
    if (_gameSecondsLeft <= 0) return '0:00';
    final m = _gameSecondsLeft ~/ 60;
    final s = _gameSecondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for timer arc around the sun
class _TimerArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _TimerArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha:0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 / 2,
      2 * 3.14,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 / 2,
      2 * 3.14 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
