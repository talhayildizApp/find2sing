import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../services/challenge_service.dart';
import 'challenge_result_screen.dart';

class ChallengeGameScreen extends StatefulWidget {
  final ChallengeModel challenge;

  const ChallengeGameScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final TextEditingController _songController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  List<ChallengeSongModel> _songs = [];
  List<ChallengeSongModel> _remainingSongs = [];
  final List<ChallengeSongModel> _foundSongs = [];
  ChallengeSongModel? _currentSong;
  
  int _currentIndex = 0;
  int _totalElapsedSeconds = 0;
  bool _isLoading = true;
  bool _isFinished = false;

  Timer? _timer;

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
      });
      _startTimer();
    } catch (e) {
      debugPrint('Şarkılar yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished) return;
      setState(() {
        _totalElapsedSeconds++;
      });
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
      setState(() {
        _foundSongs.add(_currentSong!);
        _remainingSongs.remove(_currentSong);
        _currentIndex++;
        _songController.clear();
        _artistController.clear();

        if (_remainingSongs.isEmpty) {
          _finishGame();
        } else {
          _currentSong = _remainingSongs.first;
        }
      });
      _showMessage('🎉 Doğru!', isSuccess: true);
    } else {
      _showMessage('Yanlış, tekrar dene!', isError: true);
    }
  }

  void _skipSong() {
    if (_remainingSongs.isEmpty || _remainingSongs.length <= 1) return;

    setState(() {
      final skipped = _remainingSongs.removeAt(0);
      _remainingSongs.add(skipped);
      _currentSong = _remainingSongs.first;
      _songController.clear();
      _artistController.clear();
    });
  }

  void _showHint() {
    if (_currentSong == null) return;

    final hint = _currentSong!.title.substring(0, (_currentSong!.title.length / 2).ceil());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💡 İpucu'),
        content: Text('Şarkı adı "$hint..." ile başlıyor\nSanatçı: ${_currentSong!.artist}'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCAB7FF)),
            child: const Text('Tamam', style: TextStyle(color: Color(0xFF394272))),
          ),
        ],
      ),
    );
  }

  void _finishGame() {
    _timer?.cancel();
    setState(() => _isFinished = true);
    _saveProgress();

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
        backgroundColor: isSuccess ? const Color(0xFF4CAF50) : isError ? const Color(0xFFF44336) : const Color(0xFF6C6FA4),
        duration: const Duration(seconds: 1),
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
            const Center(child: CircularProgressIndicator(color: Color(0xFFCAB7FF))),
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
                  const Icon(Icons.error_outline, size: 64, color: Color(0xFF6C6FA4)),
                  const SizedBox(height: 16),
                  const Text('Şarkılar yüklenemedi', style: TextStyle(fontSize: 18, color: Color(0xFF394272))),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Geri Dön')),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final progress = _foundSongs.length / _songs.length;

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
                _buildProgressBar(progress),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildCurrentSongCard(),
                        const SizedBox(height: 20),
                        _buildInputSection(),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 20),
                        _buildFoundSongsList(),
                        const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showExitDialog,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Color(0xFF394272), size: 20),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFF6C6FA4), size: 18),
                const SizedBox(width: 6),
                Text(_formatTime(_totalElapsedSeconds), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF394272))),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showFinishDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFFB958), borderRadius: BorderRadius.circular(20)),
              child: const Text('Bitir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF8C5A1F))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.challenge.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF394272))),
              Text('${_foundSongs.length} / ${_songs.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6C6FA4))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withValues(alpha: 0.5), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCAB7FF)), minHeight: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSongCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFCAB7FF), Color(0xFFE0D6FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          const Text('Bu şarkıyı bul:', style: TextStyle(fontSize: 14, color: Color(0xFF6C6FA4))),
          const SizedBox(height: 12),
          Text('#${_currentIndex + 1}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xFF394272))),
          const SizedBox(height: 8),
          Text('Kalan: ${_remainingSongs.length} şarkı', style: const TextStyle(fontSize: 14, color: Color(0xFF6C6FA4))),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          TextField(
            controller: _songController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(hintText: 'Şarkı adı', prefixIcon: const Icon(Icons.music_note, color: Color(0xFF6C6FA4)), filled: true, fillColor: const Color(0xFFF5F5FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _artistController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _checkAnswer(),
            decoration: InputDecoration(hintText: 'Sanatçı', prefixIcon: const Icon(Icons.person, color: Color(0xFF6C6FA4)), filled: true, fillColor: const Color(0xFFF5F5FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCAB7FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Kontrol Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF394272))),
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
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6C6FA4), side: const BorderSide(color: Color(0xFF6C6FA4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('İpucu'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFB958), side: const BorderSide(color: Color(0xFFFFB958)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFoundSongsList() {
    if (_foundSongs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bulunan Şarkılar (${_foundSongs.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF394272))),
          const SizedBox(height: 12),
          ...(_foundSongs.reversed.take(5).map((song) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('${song.title} - ${song.artist}', style: const TextStyle(fontSize: 13, color: Color(0xFF394272)), overflow: TextOverflow.ellipsis)),
            ]),
          ))),
          if (_foundSongs.length > 5) Text('+ ${_foundSongs.length - 5} şarkı daha...', style: const TextStyle(fontSize: 12, color: Color(0xFF6C6FA4))),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkmak istediğine emin misin?'),
        content: const Text('İlerleme kaydedilecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () { _saveProgress(); Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
            child: const Text('Çık', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Oyunu bitir?'),
        content: Text('${_foundSongs.length} / ${_songs.length} şarkı buldun.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Devam Et')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _finishGame(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB958)),
            child: const Text('Bitir', style: TextStyle(color: Color(0xFF8C5A1F))),
          ),
        ],
      ),
    );
  }
}
