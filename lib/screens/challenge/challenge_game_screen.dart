import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../services/challenge_service.dart';
import 'challenge_detail_screen.dart';
import 'challenge_result_screen.dart';

class ChallengeGameScreen extends StatefulWidget {
  final ChallengeModel challenge;
  final ChallengePlayMode playMode;

  const ChallengeGameScreen({
    super.key,
    required this.challenge,
    this.playMode = ChallengePlayMode.solo,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final TextEditingController _songController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  // Şarkı listesi
  List<ChallengeSongModel> _songs = [];
  List<ChallengeSongModel> _remainingSongs = [];
  
  // Solo mod için
  final List<ChallengeSongModel> _foundSongs = [];
  
  // Friends mod için
  final List<ChallengeSongModel> _player1FoundSongs = [];
  final List<ChallengeSongModel> _player2FoundSongs = [];
  int _currentPlayer = 1; // 1 veya 2
  
  ChallengeSongModel? _currentSong;
  
  int _currentIndex = 0;
  int _totalElapsedSeconds = 0;
  int _wordSecondsLeft = 15; // Her şarkı için süre
  bool _isLoading = true;
  bool _isFinished = false;
  bool _isPaused = false;

  Timer? _timer;

  bool get isFriendsMode => widget.playMode == ChallengePlayMode.friends;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _songController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _challengeService.getChallengeSongs(widget.challenge.id);
      setState(() {
        _songs = songs;
        _remainingSongs = List.from(songs);
        _remainingSongs.shuffle();
        _isLoading = false;
        if (_remainingSongs.isNotEmpty) {
          _currentSong = _remainingSongs.first;
        }
        _wordSecondsLeft = 15;
      });
      
      if (isFriendsMode) {
        _showPlayerTurnDialog(1);
      } else {
        _startTimer();
      }
    } catch (e) {
      debugPrint('Şarkılar yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished || _isPaused) return;
      
      setState(() {
        _totalElapsedSeconds++;
        _wordSecondsLeft--;
        
        if (_wordSecondsLeft <= 0) {
          // Süre doldu
          if (isFriendsMode) {
            _switchPlayer();
          } else {
            _skipSong();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    setState(() => _isPaused = false);
  }

  void _showPlayerTurnDialog(int player) {
    _pauseTimer();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              player == 1 ? Icons.person : Icons.person_outline,
              color: player == 1 ? const Color(0xFFCAB7FF) : const Color(0xFFFFB958),
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'Oyuncu $player',
              style: TextStyle(
                color: player == 1 ? const Color(0xFFCAB7FF) : const Color(0xFFFFB958),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sıra sende!',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF394272),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cihazı Oyuncu $player\'e ver',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6C6FA4),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resumeTimer();
                if (_timer == null || !_timer!.isActive) {
                  _startTimer();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: player == 1 
                    ? const Color(0xFFCAB7FF) 
                    : const Color(0xFFFFB958),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hazırım!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _switchPlayer() {
    _timer?.cancel();
    _songController.clear();
    _artistController.clear();
    
    final nextPlayer = _currentPlayer == 1 ? 2 : 1;
    
    // Her iki oyuncu da oynadıysa sonraki şarkıya geç
    if (nextPlayer == 1 && _currentPlayer == 2) {
      _moveToNextSong();
    }
    
    setState(() {
      _currentPlayer = nextPlayer;
      _wordSecondsLeft = 15;
    });
    
    if (_remainingSongs.isNotEmpty) {
      _showPlayerTurnDialog(nextPlayer);
    }
  }

  void _moveToNextSong() {
    if (_remainingSongs.isEmpty) {
      _finishGame();
      return;
    }
    
    setState(() {
      _remainingSongs.removeAt(0);
      if (_remainingSongs.isNotEmpty) {
        _currentSong = _remainingSongs.first;
        _currentIndex++;
      } else {
        _finishGame();
      }
    });
  }

  void _checkAnswer() {
    if (_currentSong == null) return;

    final songInput = _songController.text.trim().toLowerCase();
    final artistInput = _artistController.text.trim().toLowerCase();

    if (songInput.isEmpty || artistInput.isEmpty) {
      _showMessage('Şarkı ve sanatçı adını gir!');
      return;
    }

    final songMatch = _currentSong!.title.toLowerCase().contains(songInput) ||
        songInput.contains(_currentSong!.title.toLowerCase()) ||
        _currentSong!.keywords.any((k) => k.toLowerCase().contains(songInput));

    final artistMatch = _currentSong!.artist.toLowerCase().contains(artistInput) ||
        artistInput.contains(_currentSong!.artist.toLowerCase());

    if (songMatch && artistMatch) {
      // Doğru cevap
      if (isFriendsMode) {
        if (_currentPlayer == 1) {
          _player1FoundSongs.add(_currentSong!);
        } else {
          _player2FoundSongs.add(_currentSong!);
        }
        _showMessage('🎉 Doğru! +1 puan', isSuccess: true);
        _moveToNextSong();
        
        if (_remainingSongs.isNotEmpty) {
          _songController.clear();
          _artistController.clear();
          setState(() => _wordSecondsLeft = 15);
          _showPlayerTurnDialog(_currentPlayer == 1 ? 2 : 1);
          setState(() => _currentPlayer = _currentPlayer == 1 ? 2 : 1);
        }
      } else {
        // Solo mod
        setState(() {
          _foundSongs.add(_currentSong!);
          _remainingSongs.remove(_currentSong);
          _currentIndex++;
          _songController.clear();
          _artistController.clear();
          _wordSecondsLeft = 15;

          if (_remainingSongs.isEmpty) {
            _finishGame();
          } else {
            _currentSong = _remainingSongs.first;
          }
        });
        _showMessage('🎉 Doğru!', isSuccess: true);
      }
    } else {
      _showMessage('Yanlış, tekrar dene!', isError: true);
    }
  }

  void _skipSong() {
    if (_remainingSongs.isEmpty || _remainingSongs.length <= 1) {
      _finishGame();
      return;
    }

    setState(() {
      final skipped = _remainingSongs.removeAt(0);
      _remainingSongs.add(skipped);
      _currentSong = _remainingSongs.first;
      _songController.clear();
      _artistController.clear();
      _wordSecondsLeft = 15;
    });
  }

  void _showHint() {
    if (_currentSong == null) return;

    final hint = _currentSong!.title.substring(
      0, 
      (_currentSong!.title.length / 2).ceil(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💡 İpucu'),
        content: Text(
          'Şarkı adı "$hint..." ile başlıyor\nSanatçı: ${_currentSong!.artist}',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCAB7FF),
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(color: Color(0xFF394272)),
            ),
          ),
        ],
      ),
    );
  }

  void _finishGame() {
    _timer?.cancel();
    setState(() => _isFinished = true);
    
    if (!isFriendsMode) {
      _saveProgress();
    }

    if (isFriendsMode) {
      // Friends mod sonuç ekranı
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeFriendsResultScreen(
            challenge: widget.challenge,
            player1Songs: _player1FoundSongs,
            player2Songs: _player2FoundSongs,
            totalSongs: _songs.length,
            totalElapsedSeconds: _totalElapsedSeconds,
          ),
        ),
      );
    } else {
      // Solo mod sonuç ekranı
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeResultScreen(
            challenge: widget.challenge,
            foundSongs: _foundSongs,
            totalSongs: _songs.length,
            totalElapsedSeconds: _totalElapsedSeconds,
          ),
        ),
      );
    }
  }

  Future<void> _saveProgress() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final progress = ChallengeProgressModel(
      id: '${user.uid}_${widget.challenge.id}',
      oderId: user.uid,
      challengeId: widget.challenge.id,
      foundSongs: _foundSongs.length,
      totalSongs: _songs.length,
      foundSongIds: _foundSongs.map((s) => s.id).toList(),
      bestTime: _totalElapsedSeconds,
      isCompleted: _foundSongs.length == _songs.length,
      completedAt: _foundSongs.length == _songs.length ? DateTime.now() : null,
      startedAt: DateTime.now(),
      lastPlayedAt: DateTime.now(),
      playCount: 1,
    );

    await _challengeService.saveProgress(user.uid, progress);
  }

  void _showMessage(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess 
            ? const Color(0xFF4CAF50) 
            : isError 
                ? const Color(0xFFF44336) 
                : const Color(0xFF6C6FA4),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Oyundan Çık'),
        content: Text(
          isFriendsMode
              ? '${_player1FoundSongs.length + _player2FoundSongs.length} / ${_songs.length} şarkı buldunuz.'
              : '${_foundSongs.length} / ${_songs.length} şarkı buldun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Devam Et'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB958),
            ),
            child: const Text(
              'Bitir',
              style: TextStyle(color: Color(0xFF8C5A1F)),
            ),
          ),
        ],
      ),
    );
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/bg_music_clouds.png', fit: BoxFit.cover),
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFCAB7FF)),
            ),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/bg_music_clouds.png', fit: BoxFit.cover),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFF6C6FA4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Şarkılar yüklenemedi',
                    style: TextStyle(fontSize: 18, color: Color(0xFF394272)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final totalFound = isFriendsMode 
        ? _player1FoundSongs.length + _player2FoundSongs.length
        : _foundSongs.length;
    final progress = totalFound / _songs.length;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_music_clouds.png', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                if (isFriendsMode) _buildPlayerIndicator(),
                _buildProgressBar(progress),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSongHint(),
                        const SizedBox(height: 20),
                        _buildInputSection(),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Çıkış butonu
          GestureDetector(
            onTap: _confirmExit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF394272),
              ),
            ),
          ),
          const Spacer(),
          // Süre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _wordSecondsLeft <= 5
                  ? Colors.red.withValues(alpha:0.9)
                  : Colors.white.withValues(alpha:0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 18,
                  color: _wordSecondsLeft <= 5
                      ? Colors.white
                      : const Color(0xFF6C6FA4),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_wordSecondsLeft',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _wordSecondsLeft <= 5
                        ? Colors.white
                        : const Color(0xFF394272),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Toplam süre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatTime(_totalElapsedSeconds),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C6FA4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _currentPlayer == 1
            ? const Color(0xFFCAB7FF).withValues(alpha:0.2)
            : const Color(0xFFFFB958).withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _currentPlayer == 1
              ? const Color(0xFFCAB7FF)
              : const Color(0xFFFFB958),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player 1
          _buildPlayerScore(
            player: 1,
            score: _player1FoundSongs.length,
            isActive: _currentPlayer == 1,
          ),
          // VS
          const Text(
            'VS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF394272),
            ),
          ),
          // Player 2
          _buildPlayerScore(
            player: 2,
            score: _player2FoundSongs.length,
            isActive: _currentPlayer == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore({
    required int player,
    required int score,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? (player == 1 ? const Color(0xFFCAB7FF) : const Color(0xFFFFB958))
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            size: 18,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oyuncu $player',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFF394272) : Colors.grey,
              ),
            ),
            Text(
              '$score puan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF394272) : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    final totalFound = isFriendsMode 
        ? _player1FoundSongs.length + _player2FoundSongs.length
        : _foundSongs.length;
        
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.challenge.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF394272),
                ),
              ),
              Text(
                '$totalFound / ${_songs.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C6FA4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCAB7FF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongHint() {
    if (_currentSong == null) return const SizedBox.shrink();

    // Şarkının bir kelimesini ipucu olarak göster
    final hintWord = _currentSong!.keywords.isNotEmpty
        ? _currentSong!.keywords.first.toUpperCase()
        : _currentSong!.title.split(' ').first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCA28).withValues(alpha:0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        hintWord,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Color(0xFF8C5A1F),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _songController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Şarkı adı',
              prefixIcon: const Icon(Icons.music_note, color: Color(0xFF6C6FA4)),
              filled: true,
              fillColor: const Color(0xFFF5F5FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _artistController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _checkAnswer(),
            decoration: InputDecoration(
              hintText: 'Sanatçı',
              prefixIcon: const Icon(Icons.person, color: Color(0xFF6C6FA4)),
              filled: true,
              fillColor: const Color(0xFFF5F5FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCAB7FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Kontrol Et',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF394272),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _skipSong,
            icon: const Icon(Icons.skip_next),
            label: const Text('Atla'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C6FA4),
              side: const BorderSide(color: Color(0xFF6C6FA4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('İpucu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFB958),
              side: const BorderSide(color: Color(0xFFFFB958)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Challenge Friends Mode Sonuç Ekranı
class ChallengeFriendsResultScreen extends StatelessWidget {
  final ChallengeModel challenge;
  final List<ChallengeSongModel> player1Songs;
  final List<ChallengeSongModel> player2Songs;
  final int totalSongs;
  final int totalElapsedSeconds;

  const ChallengeFriendsResultScreen({
    super.key,
    required this.challenge,
    required this.player1Songs,
    required this.player2Songs,
    required this.totalSongs,
    required this.totalElapsedSeconds,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player1Score = player1Songs.length;
    final player2Score = player2Songs.length;
    
    String winnerText;
    Color winnerColor;
    
    if (player1Score > player2Score) {
      winnerText = 'Oyuncu 1 Kazandı! 🎉';
      winnerColor = const Color(0xFFCAB7FF);
    } else if (player2Score > player1Score) {
      winnerText = 'Oyuncu 2 Kazandı! 🎉';
      winnerColor = const Color(0xFFFFB958);
    } else {
      winnerText = 'Berabere! 🤝';
      winnerColor = const Color(0xFF6C6FA4);
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_music_clouds.png', fit: BoxFit.cover),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Kazanan
                  Text(
                    winnerText,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: winnerColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C6FA4),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Skor kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlayerCard(
                          player: 1,
                          score: player1Score,
                          isWinner: player1Score > player2Score,
                          color: const Color(0xFFCAB7FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPlayerCard(
                          player: 2,
                          score: player2Score,
                          isWinner: player2Score > player1Score,
                          color: const Color(0xFFFFB958),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // İstatistikler
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(Icons.music_note, '${player1Score + player2Score}/$totalSongs', 'Toplam'),
                        _buildStat(Icons.timer, _formatTime(totalElapsedSeconds), 'Süre'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF394272),
                            side: const BorderSide(color: Color(0xFF394272)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Ana Menü'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChallengeGameScreen(
                                  challenge: challenge,
                                  playMode: ChallengePlayMode.friends,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCAB7FF),
                            foregroundColor: const Color(0xFF394272),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Tekrar Oyna'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required int player,
    required int score,
    required bool isWinner,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWinner ? color.withValues(alpha:0.2) : Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(20),
        border: isWinner ? Border.all(color: color, width: 3) : null,
      ),
      child: Column(
        children: [
          if (isWinner)
            const Text('👑', style: TextStyle(fontSize: 32)),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'Oyuncu $player',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Text(
            'şarkı',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6C6FA4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C6FA4), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF394272),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C6FA4),
          ),
        ),
      ],
    );
  }
}
