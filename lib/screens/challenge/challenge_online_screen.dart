import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/game_room_model.dart';
import '../../models/match_intent_model.dart';
import '../../models/word_set_model.dart';
import '../../services/challenge_online_service.dart';

class ChallengeOnlineScreen extends StatefulWidget {
  final String roomId;

  const ChallengeOnlineScreen({super.key, required this.roomId});

  @override
  State<ChallengeOnlineScreen> createState() => _ChallengeOnlineScreenState();
}

class _ChallengeOnlineScreenState extends State<ChallengeOnlineScreen> {
  final _gameService = ChallengeOnlineService();

  StreamSubscription<GameRoomModel?>? _roomSubscription;
  GameRoomModel? _room;
  List<ChallengeSongWithWords> _songs = [];
  String? _selectedSongId;
  bool _isSubmitting = false;
  bool _isFrozen = false;
  int _freezeSeconds = 0;
  Timer? _freezeTimer;
  Timer? _gameTimer;
  int _remainingSeconds = 0;

  String? get _myUid => context.read<AuthProvider>().user?.uid;

  @override
  void initState() {
    super.initState();
    _listenToRoom();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _freezeTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _listenToRoom() {
    _roomSubscription = _gameService.streamRoom(widget.roomId).listen((room) async {
      if (room == null) return;

      final oldRoom = _room;
      setState(() => _room = room);

      // Load songs if not loaded
      if (_songs.isEmpty && room.challengeId != null) {
        final songs = await _gameService.getChallengeSongs(room.challengeId!);
        setState(() => _songs = songs);
      }

      // Start game timer for time race
      if (room.modeVariant == ModeVariant.timeRace && room.endsAt != null) {
        _startGameTimer(room.endsAt!);
      }

      // Check game end
      if (room.isFinished) {
        _showGameEndDialog();
      } else if (room.status == RoomStatus.abandoned) {
        _showAbandonedDialog();
      }
    });
  }

  void _startGameTimer(DateTime endsAt) {
    _gameTimer?.cancel();
    _remainingSeconds = endsAt.difference(DateTime.now()).inSeconds.clamp(0, 999);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startFreeze(int seconds) {
    setState(() {
      _isFrozen = true;
      _freezeSeconds = seconds;
    });

    _freezeTimer?.cancel();
    _freezeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_freezeSeconds > 0) {
        setState(() => _freezeSeconds--);
      } else {
        setState(() => _isFrozen = false);
        timer.cancel();
      }
    });
  }

  Future<void> _submitSelection() async {
    if (_selectedSongId == null || _isFrozen) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _gameService.submitSelection(
        roomId: widget.roomId,
        oderId: _myUid!,
        selectedSongId: _selectedSongId!,
      );

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Hata oluştu')),
        );
      } else if (result.isCorrect == false) {
        // Apply freeze for wrong answer
        final freezeDuration = _room?.modeVariant == ModeVariant.timeRace ? 3 : 1;
        _startFreeze(freezeDuration);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yanlış! ${result.points} puan'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (result.isCorrect == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.bonusApplied
                  ? 'Doğru! +${result.points} puan (BONUS!)'
                  : 'Doğru! +${result.points} puan',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() => _selectedSongId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showGameEndDialog() {
    if (_room == null) return;

    final myPlayer = _room!.getPlayer(_myUid!);
    final opponent = _room!.otherPlayer;
    final myScore = myPlayer?.score ?? 0;
    final opponentScore = opponent?.score ?? 0;

    String resultText;
    Color resultColor;

    if (myScore > opponentScore) {
      resultText = 'Kazandın!';
      resultColor = Colors.green;
    } else if (myScore < opponentScore) {
      resultText = 'Kaybettin';
      resultColor = Colors.red;
    } else {
      resultText = 'Berabere';
      resultColor = Colors.orange;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(resultText, style: TextStyle(color: resultColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sen: $myScore puan (${myPlayer?.solvedCount ?? 0} şarkı)'),
            Text('${opponent?.name ?? "Rakip"}: $opponentScore puan (${opponent?.solvedCount ?? 0} şarkı)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  void _showAbandonedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oyun Bitti'),
        content: const Text('Rakip oyundan ayrıldı.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyundan Çık'),
        content: const Text('Oyundan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çık', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _gameService.leaveGame(widget.roomId, _myUid!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  String _getModeLabel() {
    switch (_room?.modeVariant) {
      case ModeVariant.timeRace:
        return 'Zaman Yarışı';
      case ModeVariant.relax:
        return 'Rahat Mod';
      case ModeVariant.real:
        return 'Gerçek Challenge';
      default:
        return 'Challenge';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_room == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMyTurn = _room!.turnUid == _myUid;
    final myPlayer = _room!.getPlayer(_myUid!);
    final opponent = _room!.otherPlayer;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF394272)),
          onPressed: _leaveGame,
        ),
        title: Text(
          _getModeLabel(),
          style: const TextStyle(color: Color(0xFF394272), fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_room!.modeVariant == ModeVariant.timeRace)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 30 ? Colors.red : const Color(0xFFCAB7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Score bar
          _buildScoreBar(myPlayer, opponent),

          // Word display
          _buildWordDisplay(),

          // Comeback bonus indicator
          if (_room!.comeback != null && _room!.comeback!.activeForUid == _myUid)
            _buildComebackIndicator(),

          // Freeze overlay or selection
          Expanded(
            child: _isFrozen
                ? _buildFreezeOverlay()
                : isMyTurn
                    ? _buildSongSelection()
                    : _buildWaitingForOpponent(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(RoomPlayer? myPlayer, RoomPlayer? opponent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Sen', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(
                  '${myPlayer?.score ?? 0}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF394272)),
                ),
                Text(
                  '${myPlayer?.solvedCount ?? 0} şarkı',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                Text(opponent?.name ?? 'Rakip', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(
                  '${opponent?.score ?? 0}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFB958)),
                ),
                Text(
                  '${opponent?.solvedCount ?? 0} şarkı',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFCAB7FF), Color(0xFF9B7EDE)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('KELİME', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            _room!.currentWord,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildComebackIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            'BONUS AKTIF! x${_room!.comeback!.multiplier} puan',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.ac_unit, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Donduruldu: $_freezeSeconds sn',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForOpponent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFCAB7FF)),
          const SizedBox(height: 16),
          Text(
            '${_room!.currentTurnPlayer?.name ?? "Rakip"} seçiyor...',
            style: const TextStyle(fontSize: 18, color: Color(0xFF394272)),
          ),
        ],
      ),
    );
  }

  Widget _buildSongSelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Senin Sıran! Doğru şarkıyı seç:',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              final isSelected = _selectedSongId == song.id;

              return GestureDetector(
                onTap: () => setState(() => _selectedSongId = song.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFCAB7FF).withOpacity(0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFCAB7FF) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFFCAB7FF))
                      else
                        Icon(Icons.radio_button_off, color: Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF394272)),
                            ),
                            Text(
                              song.artist,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSongId == null || _isSubmitting ? null : _submitSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF394272),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Seç', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
