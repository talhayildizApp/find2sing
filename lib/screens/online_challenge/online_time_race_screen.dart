import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/game_room_model.dart';
import '../../models/match_intent_model.dart';
import '../../models/challenge_model.dart';
import '../../services/challenge_online_service.dart';
import '../../services/haptic_service.dart';
import '../../widgets/challenge_ui_components.dart';
import '../challenge/challenge_online_result_screen.dart';
import 'online_challenge_components.dart';

/// TIME RACE Mode - Online Challenge
///
/// Theme: Orange/Red - Fast & Intense
/// Rules:
/// - 5 minutes total game time
/// - Turn-based: alternating between players
/// - Wrong answer: 3 second freeze penalty
/// - Score: Total songs found
/// - Winner: Most songs when time runs out
class OnlineTimeRaceScreen extends StatefulWidget {
  final String roomId;

  const OnlineTimeRaceScreen({super.key, required this.roomId});

  @override
  State<OnlineTimeRaceScreen> createState() => _OnlineTimeRaceScreenState();
}

class _OnlineTimeRaceScreenState extends State<OnlineTimeRaceScreen> {
  final _gameService = ChallengeOnlineService();

  StreamSubscription<GameRoomModel?>? _roomSubscription;
  GameRoomModel? _room;
  List<ChallengeSongModel> _songs = [];
  List<String> _artists = [];
  String? _selectedArtist;
  String? _selectedSongId;
  bool _isSubmitting = false;
  bool _isFrozen = false;
  int _freezeSeconds = 0;
  Timer? _freezeTimer;
  Timer? _gameTimer;
  int _remainingSeconds = 300; // 5 minutes

  // Feedback state
  String? _feedbackMessage;
  bool _feedbackIsCorrect = false;
  bool _showFeedback = false;

  String? get _myUid => context.read<AuthProvider>().user?.uid;
  bool get _isMyTurn => _room?.turnUid == _myUid;

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

      final previousTurn = _room?.turnUid;

      setState(() => _room = room);

      // Load songs if not loaded
      if (_songs.isEmpty && room.challengeId != null) {
        final songs = await _gameService.getChallengeSongs(room.challengeId!);
        final artistSet = songs.map((s) => s.artist).toSet().toList()..sort();
        setState(() {
          _songs = songs;
          _artists = artistSet;
        });
      }

      // Start game timer
      if (room.endsAt != null) {
        _startGameTimer(room.endsAt!);
      }

      // Detect turn change
      if (previousTurn != null && previousTurn != room.turnUid) {
        HapticFeedback.mediumImpact();
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

        // Haptic warning in last 60 seconds
        if (_remainingSeconds <= 60 && _remainingSeconds % 15 == 0) {
          HapticFeedback.lightImpact();
        }
        // More urgent in last 10 seconds
        if (_remainingSeconds <= 10) {
          HapticFeedback.lightImpact();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _startFreeze() {
    setState(() {
      _isFrozen = true;
      _freezeSeconds = 3;
    });

    HapticService.freezeStart();

    _freezeTimer?.cancel();
    _freezeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_freezeSeconds > 0) {
        setState(() => _freezeSeconds--);
      } else {
        setState(() => _isFrozen = false);
        HapticService.penaltyEnd();
        timer.cancel();
      }
    });
  }

  Future<void> _submitSelection() async {
    if (_selectedSongId == null || _selectedArtist == null || !_isMyTurn || _isFrozen || _myUid == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticService.selection();

    try {
      final result = await _gameService.submitSelection(
        roomId: widget.roomId,
        oderId: _myUid!,
        selectedSongId: _selectedSongId!,
      );

      if (result.isCorrect == true) {
        HapticService.correct();
        _showFeedbackBanner('Doğru! +1', true);
      } else {
        HapticService.wrong();
        _showFeedbackBanner('Yanlış! 3sn ceza', false);
        _startFreeze();
      }

      setState(() {
        _selectedArtist = null;
        _selectedSongId = null;
      });
    } catch (e) {
      debugPrint('Error submitting selection: $e');
      _showFeedbackBanner('Hata oluştu', false);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showFeedbackBanner(String message, bool isCorrect) {
    setState(() {
      _feedbackMessage = message;
      _feedbackIsCorrect = isCorrect;
      _showFeedback = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFeedback = false);
      }
    });
  }

  void _showGameEndDialog() {
    if (_room == null || _myUid == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeOnlineResultScreen(
          room: _room!,
          myUid: _myUid!,
        ),
      ),
    );
  }

  void _showAbandonedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ChallengeColors.wrong.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: ChallengeColors.wrong),
            ),
            const SizedBox(width: 12),
            const Text('Rakip Ayrıldı'),
          ],
        ),
        content: const Text('Rakip oyundan ayrıldı. Sen kazandın!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Tamam'),
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

  Future<void> _handleExit() async {
    final shouldExit = await showOnlineExitConfirmation(context);
    if (shouldExit && mounted) {
      Navigator.pop(context);
    }
  }

  void _showArtistPicker() {
    SearchableBottomSheetPicker.show<String>(
      context: context,
      title: 'Sanatçı Seç',
      items: _artists,
      itemLabel: (artist) => artist,
      selectedItem: _selectedArtist,
      searchHint: 'Sanatçı ara...',
      accentColor: ChallengeColors.timeRace,
      onSelect: (artist) {
        setState(() {
          _selectedArtist = artist;
          _selectedSongId = null;
        });
      },
    );
  }

  void _showSongPicker() {
    if (_selectedArtist == null) return;

    final artistSongs = _songs.where((s) => s.artist == _selectedArtist).toList();

    SearchableBottomSheetPicker.show<ChallengeSongModel>(
      context: context,
      title: 'Şarkı Seç',
      items: artistSongs,
      itemLabel: (song) => song.title,
      itemSubtitle: (song) => song.artist,
      selectedItem: _selectedSongId != null
          ? artistSongs.firstWhere((s) => s.id == _selectedSongId, orElse: () => artistSongs.first)
          : null,
      searchHint: 'Şarkı ara...',
      accentColor: ChallengeColors.timeRace,
      onSelect: (song) {
        setState(() => _selectedSongId = song.id);
      },
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedArtist = null;
      _selectedSongId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_room == null) {
      return OnlineGameScaffold(
        mode: ModeVariant.timeRace,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ChallengeColors.timeRace),
              SizedBox(height: 16),
              Text(
                'Oyun yükleniyor...',
                style: TextStyle(
                  color: ChallengeColors.darkPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final myPlayer = _room!.players[_myUid];
    final opponentUid = _room!.players.keys.firstWhere((uid) => uid != _myUid, orElse: () => '');
    final opponentPlayer = opponentUid.isNotEmpty ? _room!.players[opponentUid] : null;
    final isUrgent = _remainingSeconds <= 60;
    final isCritical = _remainingSeconds <= 10;

    return OnlineGameScaffold(
      mode: ModeVariant.timeRace,
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header
              OnlineHeaderBar(
                mode: ModeVariant.timeRace,
                onClose: _handleExit,
                timerText: _formatTime(_remainingSeconds),
                isUrgent: isUrgent,
                isCritical: isCritical,
              ),

              const SizedBox(height: 8),

              // Scoreboard
              OnlineScoreboard(
                myName: myPlayer?.name ?? 'Sen',
                opponentName: opponentPlayer?.name ?? 'Rakip',
                myScore: myPlayer?.solvedCount ?? 0,
                opponentScore: opponentPlayer?.solvedCount ?? 0,
                isMyTurn: _isMyTurn,
                mode: ModeVariant.timeRace,
                scoreLabel: 'Çözülen',
                currentRound: _room!.roundIndex + 1,
                totalRounds: 10,
              ),

              const SizedBox(height: 12),

              // Turn banner
              OnlineTurnBanner(
                isMyTurn: _isMyTurn,
                opponentName: opponentPlayer?.name,
                mode: ModeVariant.timeRace,
              ),

              // Main game area
              Expanded(
                child: Center(
                  child: _isMyTurn && !_isFrozen
                      ? OnlineWordDisplay(
                          word: _room?.currentWord ?? '',
                          mode: ModeVariant.timeRace,
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Selection area (when my turn and not frozen)
              if (_isMyTurn && !_isFrozen) ...[
                OnlineSelectionCard(
                  selectedArtist: _selectedArtist,
                  selectedSong: _selectedSongId != null
                      ? _songs.firstWhere(
                          (s) => s.id == _selectedSongId,
                          orElse: () => _songs.first,
                        ).title
                      : null,
                  enabled: true,
                  onArtistTap: _showArtistPicker,
                  onSongTap: _selectedArtist != null ? _showSongPicker : null,
                  onSubmit: _submitSelection,
                  onClear: _clearSelection,
                  isSubmitting: _isSubmitting,
                  mode: ModeVariant.timeRace,
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),

          // Freeze overlay
          if (_isFrozen)
            Positioned.fill(
              child: OnlineFreezeOverlay(
                secondsRemaining: _freezeSeconds,
                totalSeconds: 3,
              ),
            ),

          // Opponent turn overlay
          if (!_isMyTurn && !_isFrozen)
            Positioned.fill(
              child: OpponentTurnOverlay(
                opponentName: opponentPlayer?.name ?? 'Rakip',
                mode: ModeVariant.timeRace,
              ),
            ),

          // Feedback toast
          if (_showFeedback)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Center(
                child: OnlineFeedbackToast(
                  message: _feedbackMessage ?? '',
                  isCorrect: _feedbackIsCorrect,
                  isVisible: _showFeedback,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
