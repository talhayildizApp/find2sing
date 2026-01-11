import 'dart:async';
import 'package:flutter/material.dart';
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

/// RELAX Mode - Online Challenge
///
/// Theme: Green - Calm & Strategic
/// Rules:
/// - 30 seconds per turn
/// - Turn-based: alternating between players
/// - Wrong answer: 1 second micro-freeze
/// - Comeback bonus: x2/x3 multiplier for trailing player
/// - Score: Total songs found (with multipliers)
/// - Winner: Most songs after all rounds
class OnlineRelaxScreen extends StatefulWidget {
  final String roomId;

  const OnlineRelaxScreen({super.key, required this.roomId});

  @override
  State<OnlineRelaxScreen> createState() => _OnlineRelaxScreenState();
}

class _OnlineRelaxScreenState extends State<OnlineRelaxScreen> {
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
  Timer? _turnTimer;
  int _turnRemainingSeconds = 30;

  // Feedback state
  String? _feedbackMessage;
  bool _feedbackIsCorrect = false;
  bool _showFeedback = false;
  bool _showBonusIndicator = false;
  int _currentMultiplier = 1;

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
    _turnTimer?.cancel();
    super.dispose();
  }

  void _listenToRoom() {
    _roomSubscription = _gameService.streamRoom(widget.roomId).listen((room) async {
      if (room == null) return;

      final previousTurn = _room?.turnUid;
      final previousRoom = _room;

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

      // Handle turn changes
      if (previousTurn != null && previousTurn != room.turnUid) {
        HapticService.turnChange();
        _resetTurnTimer();
      }

      // Check comeback bonus
      if (room.comeback != null &&
          room.comeback!.activeForUid == _myUid &&
          room.comeback!.isActive) {
        setState(() {
          _showBonusIndicator = true;
          _currentMultiplier = room.comeback!.multiplier;
        });
      } else {
        setState(() {
          _showBonusIndicator = false;
          _currentMultiplier = 1;
        });
      }

      // Score change detection for animation
      if (previousRoom != null && _myUid != null) {
        final myPlayer = room.players[_myUid];
        final prevMyPlayer = previousRoom.players[_myUid];
        if (myPlayer != null && prevMyPlayer != null &&
            myPlayer.solvedCount != prevMyPlayer.solvedCount) {
          // Score changed - animation would trigger here
        }
      }

      // Check game end
      if (room.isFinished) {
        _showGameEndDialog();
      } else if (room.status == RoomStatus.abandoned) {
        _showAbandonedDialog();
      }
    });
  }

  void _resetTurnTimer() {
    _turnTimer?.cancel();
    setState(() => _turnRemainingSeconds = 30);

    if (_isMyTurn) {
      _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_turnRemainingSeconds > 0) {
          setState(() => _turnRemainingSeconds--);

          // Warning haptics
          if (_turnRemainingSeconds <= 10 && _turnRemainingSeconds > 0) {
            HapticService.timeWarning();
          }
        } else {
          timer.cancel();
          // Auto-skip turn handled by server
        }
      });
    }
  }

  void _startFreeze() {
    setState(() {
      _isFrozen = true;
      _freezeSeconds = 1;
    });

    HapticService.freezeStart();

    _freezeTimer?.cancel();
    _freezeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_freezeSeconds > 0) {
        setState(() => _freezeSeconds--);
      } else {
        setState(() => _isFrozen = false);
        HapticService.freezeEnd();
        timer.cancel();
      }
    });
  }

  Future<void> _submitSelection() async {
    if (_selectedSongId == null || _selectedArtist == null || !_isMyTurn || _isFrozen || _myUid == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticService.submit();

    try {
      final result = await _gameService.submitSelection(
        roomId: widget.roomId,
        oderId: _myUid!,
        selectedSongId: _selectedSongId!,
      );

      if (result.isCorrect == true) {
        HapticService.correct();
        String message = 'Doğru! +1';

        // Check for comeback bonus
        if (result.bonusApplied && result.points != null && result.points! >= 2) {
          message = 'Comeback! +${result.points}';
          HapticService.bonus();
        }
        _showFeedbackBanner(message, true);
      } else {
        HapticService.wrong();
        _showFeedbackBanner('Yanlış!', false);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🚪', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text('Rakip Ayrıldı'),
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
      accentColor: ChallengeColors.relax,
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
      accentColor: ChallengeColors.relax,
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
        mode: ModeVariant.relax,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ChallengeColors.relax),
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
    final isUrgent = _turnRemainingSeconds <= 10;
    final isCritical = _turnRemainingSeconds <= 5;

    return OnlineGameScaffold(
      mode: ModeVariant.relax,
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header
              OnlineHeaderBar(
                mode: ModeVariant.relax,
                onClose: _handleExit,
                timerText: '${_turnRemainingSeconds}s',
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
                mode: ModeVariant.relax,
                scoreLabel: 'Çözülen',
                currentRound: _room!.roundIndex + 1,
                totalRounds: 10,
              ),

              const SizedBox(height: 12),

              // Turn banner
              OnlineTurnBanner(
                isMyTurn: _isMyTurn,
                opponentName: opponentPlayer?.name,
                mode: ModeVariant.relax,
              ),

              // Main game area
              Expanded(
                child: Center(
                  child: _isMyTurn && !_isFrozen
                      ? OnlineWordDisplay(
                          word: _room?.currentWord ?? '',
                          mode: ModeVariant.relax,
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
                  mode: ModeVariant.relax,
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
                totalSeconds: 1,
              ),
            ),

          // Opponent turn overlay
          if (!_isMyTurn && !_isFrozen)
            Positioned.fill(
              child: OpponentTurnOverlay(
                opponentName: opponentPlayer?.name ?? 'Rakip',
                mode: ModeVariant.relax,
              ),
            ),

          // Comeback bonus indicator
          if (_showBonusIndicator && _isMyTurn)
            Positioned(
              top: 100,
              right: 16,
              child: ComebackBonusIndicator(
                multiplier: _currentMultiplier,
                isVisible: _showBonusIndicator,
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
