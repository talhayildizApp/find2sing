import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/word_set_model.dart';
import '../../services/challenge_service.dart';
import 'challenge_result_screen.dart';

/// Challenge Game Screen - 3 Single-player mode destekli
/// - Time Race: 5dk toplam süre, yanlış = 3s freeze
/// - Relax: 30s/round, yanlış = 1s freeze (her 3 yanlışta +1s)
/// - Real: 30s/round, doğru +1, yanlış -3 (leaderboard'a gider)
class ChallengeGameScreen extends StatefulWidget {
  final ChallengeModel challenge;
  final ChallengePlayMode playMode;
  final ChallengeSingleMode singleMode;

  const ChallengeGameScreen({
    super.key,
    required this.challenge,
    this.playMode = ChallengePlayMode.solo,
    this.singleMode = ChallengeSingleMode.relax,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final Random _random = Random();

  // Game state
  List<ChallengeSongModel> _allSongs = [];
  List<ChallengeSongModel> _remainingSongs = [];
  final List<ChallengeSongModel> _solvedSongs = [];
  final Set<String> _solvedSongIds = {};

  String _currentWord = '';
  List<ChallengeSongModel> _validSongsForWord = [];

  // Selection state
  String? _selectedArtist;
  ChallengeSongModel? _selectedSong;
  List<String> _artistList = [];
  List<ChallengeSongModel> _songsForArtist = [];

  // Timing
  int _totalSeconds = 0;
  int _roundSeconds = 30;
  int _freezeSeconds = 0;
  Timer? _timer;

  // Scoring (Real mode)
  int _score = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  // Relax mode progressive freeze
  int _consecutiveWrong = 0;
  int _currentFreezeTime = 1;

  // UI state
  bool _isLoading = true;
  bool _isFinished = false;
  bool _isFrozen = false;
  String? _feedbackMessage;
  Color? _feedbackColor;

  // Mode settings
  int get _totalTimeLimit => 5 * 60; // 5 dakika (Time Race)
  int get _roundTimeLimit => 30;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _challengeService.getSongsForChallenge(widget.challenge.id);
      
      if (songs.isEmpty) {
        setState(() {
          _isLoading = false;
          _feedbackMessage = 'Bu challenge\'da şarkı bulunamadı.';
        });
        return;
      }

      final artists = songs.map((s) => s.artist).toSet().toList()..sort();

      setState(() {
        _allSongs = songs;
        _remainingSongs = List.from(songs)..shuffle();
        _artistList = artists;
        _isLoading = false;
      });

      _selectNextWord();
      _startTimer();
    } catch (e) {
      debugPrint('Error loading songs: $e');
      setState(() {
        _isLoading = false;
        _feedbackMessage = 'Şarkılar yüklenirken hata oluştu.';
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _roundSeconds = _roundTimeLimit;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished) {
        timer.cancel();
        return;
      }

      setState(() {
        _totalSeconds++;

        if (_isFrozen && _freezeSeconds > 0) {
          _freezeSeconds--;
          if (_freezeSeconds == 0) {
            _isFrozen = false;
            _feedbackMessage = null;
          }
          return;
        }

        if (widget.singleMode == ChallengeSingleMode.timeRace) {
          if (_totalSeconds >= _totalTimeLimit) {
            _finishGame(timedOut: true);
            return;
          }
        }

        if (widget.singleMode != ChallengeSingleMode.timeRace) {
          _roundSeconds--;
          if (_roundSeconds <= 0) {
            _handleTimeout();
          }
        }
      });
    });
  }

  void _handleTimeout() {
    _handleWrongAnswer(isTimeout: true);
  }

  void _selectNextWord() {
    if (_remainingSongs.isEmpty) {
      _finishGame();
      return;
    }

    final randomSong = _remainingSongs[_random.nextInt(_remainingSongs.length)];
    
    final keywords = randomSong.topKeywords.isNotEmpty 
        ? randomSong.topKeywords 
        : randomSong.keywords;
    
    if (keywords.isEmpty) {
      _remainingSongs.remove(randomSong);
      _selectNextWord();
      return;
    }

    final word = keywords[_random.nextInt(keywords.length)];
    final validSongs = _remainingSongs.where((s) => s.containsWord(word)).toList();

    setState(() {
      _currentWord = word;
      _validSongsForWord = validSongs;
      _selectedArtist = null;
      _selectedSong = null;
      _songsForArtist = [];
      _roundSeconds = _roundTimeLimit;
    });
  }

  void _onArtistSelected(String artist) {
    final songs = _allSongs.where((s) => s.artist == artist).toList();
    setState(() {
      _selectedArtist = artist;
      _songsForArtist = songs;
      _selectedSong = null;
    });
  }

  void _onSongSelected(ChallengeSongModel song) {
    setState(() => _selectedSong = song);
  }

  void _submitAnswer() {
    if (_selectedSong == null || _isFrozen) return;

    final isCorrect = _validSongsForWord.any((s) => s.id == _selectedSong!.id);

    if (isCorrect) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  void _handleCorrectAnswer() {
    final song = _selectedSong!;

    setState(() {
      _solvedSongs.add(song);
      _solvedSongIds.add(song.id);
      _remainingSongs.removeWhere((s) => s.id == song.id);
      _correctCount++;
      _consecutiveWrong = 0;

      if (widget.singleMode == ChallengeSingleMode.real) {
        _score += 1;
      }

      _feedbackMessage = '✓ Doğru!';
      _feedbackColor = Colors.green;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _feedbackMessage = null);

      if (_remainingSongs.isEmpty) {
        _finishGame();
      } else {
        _selectNextWord();
      }
    });
  }

  void _handleWrongAnswer({bool isTimeout = false}) {
    setState(() {
      _wrongCount++;
      _consecutiveWrong++;

      if (widget.singleMode == ChallengeSingleMode.real) {
        _score -= 3;
      }

      _feedbackMessage = isTimeout ? '⏱ Süre doldu!' : '✗ Yanlış!';
      _feedbackColor = Colors.red;
    });

    int freezeDuration = 0;
    
    switch (widget.singleMode) {
      case ChallengeSingleMode.timeRace:
        freezeDuration = 3;
        break;
      case ChallengeSingleMode.relax:
        if (_consecutiveWrong % 3 == 0 && _consecutiveWrong > 0) {
          _currentFreezeTime++;
        }
        freezeDuration = _currentFreezeTime;
        break;
      case ChallengeSingleMode.real:
        freezeDuration = 1;
        break;
    }

    setState(() {
      _isFrozen = true;
      _freezeSeconds = freezeDuration;
    });

    Future.delayed(Duration(seconds: freezeDuration + 1), () {
      if (!mounted || _isFinished) return;
      _selectNextWord();
    });
  }

  void _finishGame({bool timedOut = false}) {
    _timer?.cancel();
    setState(() => _isFinished = true);
    _saveGameRun(timedOut: timedOut);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeResultScreen(
          challenge: widget.challenge,
          mode: widget.singleMode,
          solvedSongs: _solvedSongs,
          totalSongs: _allSongs.length,
          score: _score,
          correctCount: _correctCount,
          wrongCount: _wrongCount,
          durationSeconds: _totalSeconds,
          timedOut: timedOut,
        ),
      ),
    );
  }

  Future<void> _saveGameRun({bool timedOut = false}) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.user?.uid ?? '';
      if (uid.isEmpty) return;

      await _challengeService.saveChallengeRun(
        ChallengeRunModel(
          id: '',
          uid: uid,
          challengeId: widget.challenge.id,
          mode: widget.singleMode.name,
          score: _score,
          correct: _correctCount,
          wrong: _wrongCount,
          durationMs: _totalSeconds * 1000,
          finished: !timedOut && _remainingSongs.isEmpty,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error saving game run: $e');
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8E0FF), Color(0xFFF5F3FF)],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8E0FF), Color(0xFFF5F3FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildWordCard(),
              if (_feedbackMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: (_feedbackColor ?? Colors.grey).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _feedbackColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: _isFrozen ? _buildFreezeOverlay() : _buildSelectionArea(),
              ),
              if (_selectedSong != null && !_isFrozen)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCAB7FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cevapla',
                        style: TextStyle(
                          fontSize: 18,
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
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(Icons.close, color: Color(0xFF394272)),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_solvedSongs.length} / ${_allSongs.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _allSongs.isEmpty ? 0 : _solvedSongs.length / _allSongs.length,
                  backgroundColor: Colors.white.withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFCAB7FF)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getTimerColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _getTimerText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (widget.singleMode == ChallengeSingleMode.real)
                  Text(
                    'Skor: $_score',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (widget.singleMode == ChallengeSingleMode.timeRace) {
      final remaining = _totalTimeLimit - _totalSeconds;
      if (remaining <= 30) return Colors.red;
      if (remaining <= 60) return Colors.orange;
      return const Color(0xFF394272);
    } else {
      if (_roundSeconds <= 5) return Colors.red;
      if (_roundSeconds <= 10) return Colors.orange;
      return const Color(0xFF394272);
    }
  }

  String _getTimerText() {
    if (widget.singleMode == ChallengeSingleMode.timeRace) {
      final remaining = _totalTimeLimit - _totalSeconds;
      return _formatTime(remaining.clamp(0, _totalTimeLimit));
    } else {
      return _formatTime(_roundSeconds);
    }
  }

  Widget _buildWordCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCAB7FF), Color(0xFFB8A4FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAB7FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'KELİME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentWord.toUpperCase(),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'FREEZE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_freezeSeconds saniye',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF394272),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sanatçı Seç',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6C6FA4),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _artistList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final artist = _artistList[index];
                      final isSelected = artist == _selectedArtist;
                      return GestureDetector(
                        onTap: () => _onArtistSelected(artist),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFCAB7FF) : const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Text(
                            artist,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF394272),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedArtist == null
                ? const Center(
                    child: Text(
                      'Önce sanatçı seç',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6C6FA4)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _songsForArtist.length,
                    itemBuilder: (context, index) {
                      final song = _songsForArtist[index];
                      final isSelected = song.id == _selectedSong?.id;
                      final isSolved = _solvedSongIds.contains(song.id);

                      return GestureDetector(
                        onTap: isSolved ? null : () => _onSongSelected(song),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSolved 
                                ? Colors.green.withOpacity(0.1)
                                : isSelected 
                                    ? const Color(0xFFCAB7FF).withOpacity(0.2)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSolved
                                  ? Colors.green
                                  : isSelected 
                                      ? const Color(0xFFCAB7FF)
                                      : const Color(0xFFE0E0E0),
                              width: isSelected || isSolved ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSolved)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                ),
                              if (isSelected && !isSolved)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.radio_button_checked, color: Color(0xFFCAB7FF), size: 20),
                                ),
                              if (!isSelected && !isSolved)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.radio_button_off, color: Color(0xFFCCCCCC), size: 20),
                                ),
                              Expanded(
                                child: Text(
                                  song.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSolved ? Colors.green.shade700 : const Color(0xFF394272),
                                    decoration: isSolved ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Oyundan Çık'),
        content: const Text('Oyundan çıkmak istediğine emin misin? İlerleme kaydedilmeyecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Devam Et'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Çık', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
