import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/game_room_model.dart';
import '../../services/friends_online_game_service.dart';

class FriendsWordGameScreen extends StatefulWidget {
  final String roomId;

  const FriendsWordGameScreen({super.key, required this.roomId});

  @override
  State<FriendsWordGameScreen> createState() => _FriendsWordGameScreenState();
}

class _FriendsWordGameScreenState extends State<FriendsWordGameScreen> {
  final _gameService = FriendsOnlineGameService();
  final _songController = TextEditingController();
  final _artistController = TextEditingController();

  StreamSubscription<GameRoomModel?>? _roomSubscription;
  GameRoomModel? _room;
  List<FriendsWordRound> _rounds = [];
  bool _isSubmitting = false;
  Timer? _reviewTimer;
  int _reviewSecondsLeft = 5;

  String? get _myUid => context.read<AuthProvider>().user?.uid;

  @override
  void initState() {
    super.initState();
    _listenToRoom();
    _listenToRounds();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _reviewTimer?.cancel();
    _songController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  void _listenToRoom() {
    _roomSubscription = _gameService.streamRoom(widget.roomId).listen((room) {
      if (room == null) return;

      setState(() => _room = room);

      if (room.isFinished) {
        _showGameEndDialog();
      } else if (room.status == RoomStatus.abandoned) {
        _showAbandonedDialog();
      }

      // Start review timer if in reviewing phase
      if (room.phase == GamePhase.reviewing && room.reviewDeadlineAt != null) {
        _startReviewTimer(room.reviewDeadlineAt!);
      }
    });
  }

  void _listenToRounds() {
    _gameService.streamRounds(widget.roomId).listen((rounds) {
      setState(() => _rounds = rounds);
    });
  }

  void _startReviewTimer(DateTime deadline) {
    _reviewTimer?.cancel();
    final remaining = deadline.difference(DateTime.now());
    _reviewSecondsLeft = remaining.inSeconds.clamp(0, 5);

    _reviewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_reviewSecondsLeft > 0) {
        setState(() => _reviewSecondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _submitAnswer() async {
    final song = _songController.text.trim();
    final artist = _artistController.text.trim();

    if (song.isEmpty || artist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şarkı ve sanatçı adını giriniz')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _gameService.submitAnswer(
        roomId: widget.roomId,
        oderId: _myUid!,
        song: song,
        artist: artist,
      );
      _songController.clear();
      _artistController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitReview(bool approved) async {
    try {
      await _gameService.submitReview(
        roomId: widget.roomId,
        reviewerUid: _myUid!,
        approved: approved,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
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
            Text('Sen: $myScore puan'),
            Text('${opponent?.name ?? "Rakip"}: $opponentScore puan'),
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
        title: const Text(
          'Arkadaşla Online',
          style: TextStyle(color: Color(0xFF394272), fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFCAB7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Tur ${_room!.roundIndex + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Score bar
          _buildScoreBar(myPlayer, opponent),

          // Word display
          _buildWordDisplay(),

          // Game area
          Expanded(
            child: _room!.phase == GamePhase.reviewing
                ? _buildReviewingPhase()
                : _buildAnsweringPhase(isMyTurn),
          ),

          // History
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildScoreBar(RoomPlayer? myPlayer, RoomPlayer? opponent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Sen',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${myPlayer?.score ?? 0}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF394272),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  opponent?.name ?? 'Rakip',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${opponent?.score ?? 0}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB958),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCAB7FF), Color(0xFF9B7EDE)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'KELİME',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            _room!.currentWord,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnsweringPhase(bool isMyTurn) {
    if (!isMyTurn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFCAB7FF)),
            const SizedBox(height: 16),
            Text(
              '${_room!.currentTurnPlayer?.name ?? "Rakip"} cevaplıyor...',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF394272),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Senin Sıran!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _songController,
            decoration: InputDecoration(
              labelText: 'Şarkı Adı',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _artistController,
            decoration: InputDecoration(
              labelText: 'Sanatçı',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF394272),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Gönder',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewingPhase() {
    final isReviewer = _room!.turnUid != _myUid;
    final currentRound = _rounds.isNotEmpty ? _rounds.first : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _reviewSecondsLeft <= 2 ? Colors.red.shade100 : Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$_reviewSecondsLeft',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _reviewSecondsLeft <= 2 ? Colors.red : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Answer display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Verilen Cevap:', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  currentRound?.answerSong ?? '-',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF394272),
                  ),
                ),
                Text(
                  currentRound?.answerArtist ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6C6FA4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (isReviewer) ...[
            const Text(
              'Bu cevap doğru mu?',
              style: TextStyle(fontSize: 16, color: Color(0xFF394272)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _submitReview(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reddet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _submitReview(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Rakip değerlendiriyor...',
              style: TextStyle(fontSize: 16, color: Color(0xFF6C6FA4)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_rounds.isEmpty) return const SizedBox.shrink();

    final resolvedRounds = _rounds.where((r) => r.resolved).take(5).toList();
    if (resolvedRounds.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: resolvedRounds.length,
        itemBuilder: (context, index) {
          final round = resolvedRounds[index];
          final isMyRound = round.turnUid == _myUid;
          final isAccepted = round.isAccepted ?? false;

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAccepted ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAccepted ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isAccepted ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: isAccepted ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMyRound ? 'Sen' : 'Rakip',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  round.word,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  round.answerSong ?? '-',
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
