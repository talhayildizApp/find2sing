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

/// REAL CHALLENGE Mode - Online Challenge
///
/// Theme: Orange - Competitive & Intense
/// Rules:
/// - Turn-based with point system
/// - Correct: +1 point
/// - Wrong: -3 points (brutal penalty)
/// - Steal bonus: +2 when solving opponent's missed word
/// - Score: Total points (can go negative!)
/// - Winner: Highest score after all rounds
class OnlineRealChallengeScreen extends StatefulWidget {
  final String roomId;

  const OnlineRealChallengeScreen({super.key, required this.roomId});

  @override
  State<OnlineRealChallengeScreen> createState() => _OnlineRealChallengeScreenState();
}

class _OnlineRealChallengeScreenState extends State<OnlineRealChallengeScreen> {
  final _gameService = ChallengeOnlineService();

  StreamSubscription<GameRoomModel?>? _roomSubscription;
  GameRoomModel? _room;
  List<ChallengeSongModel> _songs = [];
  List<String> _artists = [];
  String? _selectedArtist;
  String? _selectedSongId;
  bool _isSubmitting = false;

  // Feedback state
  String? _feedbackMessage;
  bool _feedbackIsCorrect = false;
  bool _showFeedback = false;
  bool _showStealBonus = false;

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

      // Handle turn changes
      if (previousTurn != null && previousTurn != room.turnUid) {
        HapticService.turnChange();
      }

      // Check game end
      if (room.isFinished) {
        _showGameEndDialog();
      } else if (room.status == RoomStatus.abandoned) {
        _showAbandonedDialog();
      }
    });
  }

  Future<void> _submitSelection() async {
    if (_selectedSongId == null || _selectedArtist == null || !_isMyTurn || _myUid == null || _isSubmitting) return;

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

        // Check for steal bonus (+2)
        if (result.bonusApplied && result.points != null && result.points! == 2) {
          message = 'Çaldın! +2';
          setState(() => _showStealBonus = true);
          HapticService.bonus();
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showStealBonus = false);
          });
        }
        _showFeedbackBanner(message, true);
      } else {
        HapticService.wrong();
        _showFeedbackBanner('Yanlış! -3', false);
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
      accentColor: ChallengeColors.realChallenge,
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
      accentColor: ChallengeColors.realChallenge,
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
        mode: ModeVariant.real,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ChallengeColors.realChallenge),
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

    return OnlineGameScaffold(
      mode: ModeVariant.real,
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header
              OnlineHeaderBar(
                mode: ModeVariant.real,
                onClose: _handleExit,
                timerText: 'Tur ${_room!.roundIndex + 1}/8',
                isUrgent: false,
                isCritical: false,
              ),

              const SizedBox(height: 8),

              // Scoreboard with POINTS (can go negative)
              OnlineScoreboard(
                myName: myPlayer?.name ?? 'Sen',
                opponentName: opponentPlayer?.name ?? 'Rakip',
                myScore: myPlayer?.score ?? 0,
                opponentScore: opponentPlayer?.score ?? 0,
                isMyTurn: _isMyTurn,
                mode: ModeVariant.real,
                scoreLabel: 'Puan',
                currentRound: _room!.roundIndex + 1,
                totalRounds: 8,
              ),

              const SizedBox(height: 12),

              // Turn banner
              OnlineTurnBanner(
                isMyTurn: _isMyTurn,
                opponentName: opponentPlayer?.name,
                mode: ModeVariant.real,
              ),

              // Main game area
              Expanded(
                child: Center(
                  child: _isMyTurn
                      ? OnlineWordDisplay(
                          word: _room?.currentWord ?? '',
                          mode: ModeVariant.real,
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Rules reminder card (when my turn)
              if (_isMyTurn)
                const RulesReminderCard(),

              // Selection area (when my turn)
              if (_isMyTurn) ...[
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
                  mode: ModeVariant.real,
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),

          // Opponent turn overlay
          if (!_isMyTurn)
            Positioned.fill(
              child: OpponentTurnOverlay(
                opponentName: opponentPlayer?.name ?? 'Rakip',
                mode: ModeVariant.real,
              ),
            ),

          // Steal bonus toast
          if (_showStealBonus)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: StealBonusToast(
                message: 'Rakibin kaçırdığını çözdün! +2',
                isVisible: _showStealBonus,
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
