import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/game_room_model.dart';
import '../../models/match_intent_model.dart';
import '../../models/challenge_model.dart';
import '../../services/ad_service.dart';
import '../../services/challenge_online_service.dart';
import '../../services/haptic_service.dart';
import '../../services/rewards_service.dart';
import '../../widgets/challenge_ui_components.dart';
import 'challenge_online_result_screen.dart';

/// Round history item for displaying solved words
class RoundHistoryItem {
  final String word;
  final String winnerName;
  final bool iWon;
  final int points;
  final String? songTitle;
  final String? songArtist;
  final String? songId;

  RoundHistoryItem({
    required this.word,
    required this.winnerName,
    required this.iWon,
    required this.points,
    this.songTitle,
    this.songArtist,
    this.songId,
  });
}

/// Challenge Online Game Screen - PARALLEL RACE MODE
///
/// Both players see the same word and race to answer first.
/// First correct answer wins the round.
///
/// Core Principle: "Your game is primary, opponent is context"
/// - 70% screen YOUR game (big, clear, comfortable)
/// - 30% screen opponent tracking (compact, glanceable)
class ChallengeOnlineScreen extends StatefulWidget {
  final String roomId;

  const ChallengeOnlineScreen({super.key, required this.roomId});

  @override
  State<ChallengeOnlineScreen> createState() => _ChallengeOnlineScreenState();
}

class _ChallengeOnlineScreenState extends State<ChallengeOnlineScreen>
    with TickerProviderStateMixin {
  final _gameService = ChallengeOnlineService();
  final _rewardsService = RewardsService();
  final _adService = AdService();

  StreamSubscription<GameRoomModel?>? _roomSubscription;
  GameRoomModel? _room;
  ChallengeModel? _challenge; // Store challenge for rematch
  List<ChallengeSongModel> _songs = [];
  String? _selectedArtist;
  String? _selectedSongId;
  bool _isSubmitting = false;
  bool _isFrozen = false;
  int _freezeSeconds = 0;
  Timer? _freezeTimer;
  Timer? _gameTimer;
  int _remainingSeconds = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _raceController;

  // Feedback state
  bool _showFeedback = false;
  bool _lastAnswerCorrect = false;
  int _bonusPoints = 0;
  bool _wonRound = false;

  // Round transition state
  bool _showRoundWinner = false;
  String? _roundWinnerName;
  bool _iWonThisRound = false;

  // Bonus toast state
  bool _showBonusToast = false;
  String? _bonusToastMessage;
  bool _bonusIsSteal = false;

  // Round history for display
  final List<RoundHistoryItem> _roundHistory = [];

  // Word/Round timer (Relax: 30s, Real: 15s)
  Timer? _wordTimer;
  int _wordTimerSeconds = 0;
  int _wordTimerMax = 30; // Will be set based on mode

  // Joker states (each can only be used once per game)
  // Now tied to user's challengeJokers from RewardsService
  bool _jokerArtistUsedThisGame = false;
  bool _jokerSongUsedThisGame = false;
  bool _jokerX2UsedThisGame = false;
  bool _x2Active = false; // x2 is active for current round
  bool _isWatchingAd = false; // Reklam izleniyor mu?

  String? get _myUid => context.read<AuthProvider>().user?.uid;

  // For parallel mode - can always answer if not frozen and round not won
  // No submission limit - can keep trying until someone wins the round
  bool get _canAnswer =>
      _room != null &&
      !_isFrozen &&
      !_room!.isRoundWon;

  // Check if all available songs are from the same artist (artist joker would be useless)
  bool get _isSingleArtist {
    final solved = _solvedSongIds;
    final availableSongs = _songs.where((s) => !solved.contains(s.id)).toList();
    final artists = availableSongs.map((s) => s.artist).toSet();
    return artists.length <= 1;
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _listenToRoom();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _raceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _freezeTimer?.cancel();
    _gameTimer?.cancel();
    _wordTimer?.cancel();
    _pulseController.dispose();
    _raceController.dispose();
    super.dispose();
  }

  void _listenToRoom() {
    int previousRoundIndex = -1;
    String? previousRoundWinner;

    _roomSubscription =
        _gameService.streamRoom(widget.roomId).listen((room) async {
      if (room == null) return;

      setState(() => _room = room);

      // Load songs and challenge if not loaded
      if (_songs.isEmpty && room.challengeId != null) {
        debugPrint('🎵 Loading songs for challenge: ${room.challengeId}');
        final songs = await _gameService.getChallengeSongs(room.challengeId!);
        final challenge = await _gameService.getChallenge(room.challengeId!);
        debugPrint('🎵 Loaded ${songs.length} songs');
        debugPrint('🎵 Found ${songs.map((s) => s.artist).toSet().length} artists');
        setState(() {
          _songs = songs;
          _challenge = challenge;
        });
      }

      // Start game timer for time race
      if (room.modeVariant == ModeVariant.timeRace && room.endsAt != null) {
        _startGameTimer(room.endsAt!);
      }

      // Set word timer max based on mode (Relax: 30s, Real: 15s)
      // TimeRace doesn't have per-word timer, only global timer
      if (room.modeVariant == ModeVariant.relax) {
        _wordTimerMax = 30;
      } else if (room.modeVariant == ModeVariant.real) {
        _wordTimerMax = 15;
      }

      // Detect round winner announcement
      if (room.roundWinner != null && previousRoundWinner != room.roundWinner) {
        _showRoundWinnerCelebration(room);
        // Stop word timer when round is won
        _wordTimer?.cancel();
      }
      previousRoundWinner = room.roundWinner;

      // Detect new round (round winner cleared, new word)
      final isNewRound = previousRoundIndex != -1 &&
          room.roundIndex != previousRoundIndex &&
          room.roundWinner == null;
      final isFirstRound = previousRoundIndex == -1 && room.roundWinner == null;

      if (isNewRound) {
        // New round started - reset selection and x2 joker
        setState(() {
          _selectedArtist = null;
          _selectedSongId = null;
          _showRoundWinner = false;
          _x2Active = false; // x2 joker expires at end of round
        });
        HapticFeedback.mediumImpact();
      }

      // Start word timer for first round or new round (Relax & Real modes only)
      if (isFirstRound || isNewRound) {
        if (room.modeVariant == ModeVariant.relax || room.modeVariant == ModeVariant.real) {
          _startWordTimer();
        }
      }

      previousRoundIndex = room.roundIndex;

      // Check game end
      if (room.isFinished) {
        _navigateToResult();
      } else if (room.status == RoomStatus.abandoned) {
        // Only show dialog if opponent abandoned (not if I abandoned)
        if (room.abandonedBy != _myUid) {
          _showAbandonedDialog();
        }
        // If I abandoned, I already navigated away in _handleExit
      }
    });
  }

  void _showRoundWinnerCelebration(GameRoomModel room) {
    final winnerId = room.roundWinner;
    final winnerPlayer = room.players[winnerId];
    final isMe = winnerId == _myUid;

    // Get song info from winner's submission
    final winnerSubmission = room.roundSubmissions[winnerId];
    final songId = winnerSubmission?['songId'] as String?;

    debugPrint('🏆 Round winner: $winnerId, songId: $songId');
    debugPrint('🏆 Submissions: ${room.roundSubmissions}');

    ChallengeSongModel? solvedSong;
    if (songId != null && _songs.isNotEmpty) {
      // Find the song by ID
      final matchingSongs = _songs.where((s) => s.id == songId).toList();
      if (matchingSongs.isNotEmpty) {
        solvedSong = matchingSongs.first;
      }
      debugPrint('🏆 Found song: ${solvedSong?.title} by ${solvedSong?.artist}');
    }

    // Add to history with song info
    _roundHistory.insert(0, RoundHistoryItem(
      word: room.currentWord,
      winnerName: winnerPlayer?.name ?? 'Oyuncu',
      iWon: isMe,
      points: 1,
      songTitle: solvedSong?.title,
      songArtist: solvedSong?.artist,
      songId: songId,
    ));

    debugPrint('🏆 History item added: word=${room.currentWord}, song=${solvedSong?.title}');

    setState(() {
      _showRoundWinner = true;
      _roundWinnerName = winnerPlayer?.name ?? 'Oyuncu';
      _iWonThisRound = isMe;
    });

    if (isMe) {
      HapticService.correct();
    } else {
      HapticFeedback.lightImpact();
    }

    // Auto-hide after delay (server will start new round)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _showRoundWinner = false);
      }
    });
  }

  void _startGameTimer(DateTime endsAt) {
    _gameTimer?.cancel();
    _remainingSeconds = endsAt.difference(DateTime.now()).inSeconds.clamp(0, 999);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);

        // Haptic warning in last 30 seconds
        if (_remainingSeconds <= 30 && _remainingSeconds % 10 == 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        timer.cancel();
        // Time's up - end the game
        _handleTimeUp();
      }
    });
  }

  Future<void> _handleTimeUp() async {
    // Notify user time is up
    HapticFeedback.heavyImpact();

    // End game in Firestore (will trigger navigation via stream listener)
    await _gameService.endGameTimeUp(widget.roomId);
  }

  void _startWordTimer() {
    _wordTimer?.cancel();
    setState(() {
      _wordTimerSeconds = _wordTimerMax;
    });

    _wordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_wordTimerSeconds > 0) {
        setState(() => _wordTimerSeconds--);

        // Haptic warning in last 5 seconds
        if (_wordTimerSeconds <= 5 && _wordTimerSeconds > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        timer.cancel();
        // Word timer expired - skip this round (both players lose the round)
        _handleWordTimerExpired();
      }
    });
  }

  void _handleWordTimerExpired() {
    // For now, just provide feedback - the round continues until someone answers
    // In future, could auto-skip to next word
    HapticFeedback.heavyImpact();
    debugPrint('⏰ Word timer expired!');
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
        HapticService.penaltyEnd();
        timer.cancel();
      }
    });
  }

  Future<void> _submitSelection() async {
    if (_selectedSongId == null ||
        _selectedArtist == null ||
        !_canAnswer ||
        _myUid == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    HapticService.selection();

    try {
      final result = await _gameService.submitSelection(
        roomId: widget.roomId,
        oderId: _myUid!,
        selectedSongId: _selectedSongId!,
        useX2Joker: _x2Active,
      );

      if (result.isCorrect == true) {
        if (result.wonRound) {
          // We won this round!
          final points = result.points ?? 1;

          // Show bonus messages
          if (_x2Active) {
            _showBonusToastMessage('x2 Joker! +$points puan!', false);
          } else if (result.bonusApplied && points > 1) {
            if (_room?.modeVariant == ModeVariant.real) {
              _showBonusToastMessage(
                  'Rakibin kacirdigi kelimeyi cozdun! +$points', true);
            } else if (_room?.modeVariant == ModeVariant.relax) {
              _showBonusToastMessage('Comeback Bonus! x$points', false);
            }
          }

          _showCelebration(true, points, true);

          // Reset x2 joker after use
          if (_x2Active) {
            setState(() => _x2Active = false);
          }
        } else {
          // Correct but opponent was faster
          _showCelebration(true, 0, false);
          // Reset x2 joker even if we didn't win (it's per-round)
          if (_x2Active) {
            setState(() => _x2Active = false);
          }
        }
      } else {
        HapticService.wrong();
        _showCelebration(false, 0, false);

        if (_room?.modeVariant == ModeVariant.timeRace) {
          _startFreeze(3);
        } else if (_room?.modeVariant == ModeVariant.relax) {
          _startFreeze(1);
        }
      }

      // Clear selection after submit
      setState(() {
        _selectedArtist = null;
        _selectedSongId = null;
      });
    } catch (e) {
      debugPrint('Error submitting selection: $e');
      _showCelebration(false, 0, false);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showCelebration(bool isCorrect, int points, bool wonRound) {
    setState(() {
      _showFeedback = true;
      _lastAnswerCorrect = isCorrect;
      _bonusPoints = points > 1 ? points : 0;
      _wonRound = wonRound;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showFeedback = false);
      }
    });
  }

  void _showBonusToastMessage(String message, bool isSteal) {
    setState(() {
      _bonusToastMessage = message;
      _bonusIsSteal = isSteal;
      _showBonusToast = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showBonusToast = false);
      }
    });
  }

  void _navigateToResult() {
    if (_room == null || _myUid == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeOnlineResultScreen(
          room: _room!,
          myUid: _myUid!,
          challenge: _challenge,
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
        title: const Text('Rakip Ayrildi'),
        content: const Text('Rakip oyundan ayrildi. Sen kazandin!'),
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

  Color _getModeColor() {
    switch (_room?.modeVariant) {
      case ModeVariant.timeRace:
        return ChallengeColors.timeRace;
      case ModeVariant.relax:
        return ChallengeColors.relax;
      case ModeVariant.real:
        return ChallengeColors.realChallenge;
      default:
        return ChallengeColors.primaryPurple;
    }
  }

  // Get list of solved song IDs from round history
  Set<String> get _solvedSongIds {
    final ids = _roundHistory
        .where((r) => r.songId != null)
        .map((r) => r.songId!)
        .toSet();
    debugPrint('🎯 Solved song IDs: $ids (from ${_roundHistory.length} history items)');
    return ids;
  }

  void _showArtistPicker() {
    // Use all songs, filter out solved ones
    final solved = _solvedSongIds;
    final availableSongs = _songs.where((s) => !solved.contains(s.id)).toList();
    final artists = availableSongs.map((s) => s.artist).toSet().toList()..sort();

    // Fallback to all artists if no available songs (shouldn't happen)
    final artistsToShow = artists.isNotEmpty ? artists : _songs.map((s) => s.artist).toSet().toList()..sort();
    if (artistsToShow.isEmpty) return;

    SearchableBottomSheetPicker.show<String>(
      context: context,
      title: 'Sanatci Sec',
      items: artistsToShow,
      itemLabel: (artist) => artist,
      selectedItem: _selectedArtist,
      searchHint: 'Sanatci ara...',
      accentColor: _getModeColor(),
      onSelect: (artist) {
        setState(() {
          _selectedArtist = artist;
          _selectedSongId = null;
        });
        HapticService.selection();
      },
    );
  }

  void _showSongPicker() {
    // Use all songs, filter out solved ones
    final solved = _solvedSongIds;
    final availableSongs = _songs.where((s) => !solved.contains(s.id)).toList();

    // Fallback to all songs if no available (shouldn't happen)
    final baseSongs = availableSongs.isNotEmpty ? availableSongs : _songs;
    if (baseSongs.isEmpty) return;

    // Show filtered songs if artist is selected, otherwise show all available songs
    final songsToShow = _selectedArtist != null
        ? baseSongs.where((s) => s.artist == _selectedArtist).toList()
        : baseSongs;

    if (songsToShow.isEmpty) return;

    SearchableBottomSheetPicker.show<ChallengeSongModel>(
      context: context,
      title: 'Sarki Sec',
      items: songsToShow,
      itemLabel: (song) => song.title,
      itemSubtitle: (song) => song.artist,
      selectedItem: _selectedSongId != null
          ? songsToShow.firstWhere((s) => s.id == _selectedSongId,
              orElse: () => songsToShow.first)
          : null,
      searchHint: 'Sarki ara...',
      accentColor: _getModeColor(),
      onSelect: (song) {
        setState(() {
          _selectedSongId = song.id;
          // Auto-select artist when song is selected
          _selectedArtist = song.artist;
        });
        HapticService.selection();
      },
    );
  }

  Future<void> _handleExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Oyundan Çık',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ChallengeColors.darkPurple,
          ),
        ),
        content: const Text(
          'Oyundan çıkarsan maçı kaybedersin. Emin misin?',
          style: TextStyle(color: ChallengeColors.darkPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Devam Et',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Çık',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      // Abandon the game - notify opponent
      if (_myUid != null) {
        await _gameService.leaveGame(widget.roomId, _myUid!);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_room == null) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildGradientBackground(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: ChallengeColors.primaryPurple),
                  const SizedBox(height: 16),
                  const Text(
                    'Oyun yukleniyor...',
                    style: TextStyle(
                      color: ChallengeColors.darkPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final myPlayer = _room!.players[_myUid];
    final opponentUid =
        _room!.players.keys.firstWhere((uid) => uid != _myUid, orElse: () => '');
    final opponentPlayer =
        opponentUid.isNotEmpty ? _room!.players[opponentUid] : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          _buildGradientBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // COMPACT HEADER - Centered timer
                _buildCompactHeader(),

                const SizedBox(height: 8),

                // RACE STATUS BAR - Shows both players' status
                _buildRaceStatusBar(myPlayer, opponentPlayer),

                const SizedBox(height: 12),

                // GAME CONTENT with Expanded Round History
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // SUNNY WORD CARD
                        _buildSunnyWordCard(),

                        const SizedBox(height: 16),

                        // SELECTION CARD with dropdowns
                        _buildSelectionCard(),

                        const SizedBox(height: 12),

                        // ROUND HISTORY - Expanded & Scrollable
                        _buildRoundHistoryCard(),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // JOKER BAR - Fixed at bottom
                _buildJokerBar(),
              ],
            ),
          ),

          // Freeze overlay
          if (_isFrozen)
            Positioned.fill(
              child: ChallengeFreezeOverlay(
                secondsLeft: _freezeSeconds,
                totalSeconds:
                    _room?.modeVariant == ModeVariant.timeRace ? 3 : 1,
              ),
            ),

          // Round winner celebration overlay
          if (_showRoundWinner) _buildRoundWinnerOverlay(),

          // Comeback bonus indicator
          if (_room?.comeback != null &&
              _room!.comeback!.activeForUid == _myUid &&
              _room!.comeback!.isActive)
            Positioned(
              top: 140,
              right: 16,
              child: _buildComebackIndicator(),
            ),

          // FEEDBACK OVERLAY - Quick answer feedback
          if (_showFeedback) _buildFeedbackOverlay(),

          // Bonus toast
          if (_showBonusToast)
            Positioned(
              top: 180,
              left: 20,
              right: 20,
              child: _buildBonusToast(),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // GRADIENT BACKGROUND - Colorful and lively
  // ════════════════════════════════════════════════
  Widget _buildGradientBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cloud background image
        Image.asset(
          'assets/images/bg_music_clouds.png',
          fit: BoxFit.cover,
        ),
        // Mode-colored gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.3),
                _getModeColor().withValues(alpha: 0.08),
                _getModeColor().withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════
  // SUNNY WORD CARD - Using WordHeroCard for consistency with single-player
  // ════════════════════════════════════════════════
  Widget _buildSunnyWordCard() {
    // Show timer for Relax and Real modes only (TimeRace has global timer)
    final showTimer = (_room?.modeVariant == ModeVariant.relax ||
        _room?.modeVariant == ModeVariant.real) &&
        !(_room?.isRoundWon ?? false);

    return Center(
      child: WordHeroCard(
        word: _room?.currentWord ?? '',
        timerSeconds: showTimer ? _wordTimerSeconds : null,
        totalSeconds: showTimer ? _wordTimerMax : null,
        animate: true,
      ),
    );
  }

  // ════════════════════════════════════════════════
  // SELECTION CARD - Dropdown style with gradient
  // ════════════════════════════════════════════════
  Widget _buildSelectionCard() {
    // Only show "submitted" state if round is won (waiting for next round)
    // After wrong answer, user can immediately try again
    final roundIsWon = _room?.isRoundWon ?? false;
    final hasSelection = _selectedArtist != null && _selectedSongId != null;
    final selectedSong = (_selectedSongId != null && _songs.isNotEmpty)
        ? _songs.firstWhere((s) => s.id == _selectedSongId,
            orElse: () => _songs.first)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Color.lerp(Colors.white, _getModeColor(), 0.05)!.withValues(alpha: 0.9),
            Color.lerp(Colors.white, _getModeColor(), 0.08)!.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: roundIsWon
          ? _buildSubmittedState()
          : Column(
              children: [
                // Dropdown row
                Row(
                  children: [
                    // Artist dropdown
                    Expanded(
                      child: _buildDropdownField(
                        icon: '🎤',
                        label: 'Sanatçı',
                        value: _selectedArtist,
                        onTap: _showArtistPicker,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Song dropdown - always enabled, shows all songs if no artist selected
                    Expanded(
                      child: _buildDropdownField(
                        icon: '🎵',
                        label: 'Şarkı',
                        value: selectedSong?.title,
                        onTap: _showSongPicker,
                      ),
                    ),
                  ],
                ),

                // Confirmation bar when both selected
                if (hasSelection) ...[
                  const SizedBox(height: 16),
                  _buildConfirmationBar(selectedSong?.title ?? ''),
                ],
              ],
            ),
    );
  }

  Widget _buildDropdownField({
    required String icon,
    required String label,
    String? value,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final hasValue = value != null;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? _getModeColor().withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? _getModeColor().withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Seç...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? ChallengeColors.darkPurple
                          : Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: enabled ? _getModeColor() : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationBar(String songTitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getModeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getModeColor().withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Selection summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedArtist ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ChallengeColors.darkPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  songTitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Submit button
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: !_isSubmitting ? _submitSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getModeColor(),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Onayla',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedState() {
    // This is shown when round is won - waiting for next round
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _getModeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getModeColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getModeColor()),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Yeni tur başlıyor...',
            style: TextStyle(
              color: _getModeColor(),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // ROUND HISTORY CARD - Who solved which word (Expandable & Scrollable)
  // ════════════════════════════════════════════════
  Widget _buildRoundHistoryCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 16, color: _getModeColor()),
                const SizedBox(width: 6),
                Text(
                  'Skor Tablosu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChallengeColors.darkPurple,
                  ),
                ),
                const Spacer(),
                if (_roundHistory.isNotEmpty)
                  Text(
                    '${_roundHistory.length} tur',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),

            if (_roundHistory.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 32,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'İlk kelimeyi çözen sen ol!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              // Scrollable history items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _roundHistory.length,
                  itemBuilder: (context, index) => _buildHistoryItem(_roundHistory[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(RoundHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Winner indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.iWon
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                item.iWon ? '✓' : item.winnerName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: item.iWon ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Word and song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Word
                Text(
                  item.word.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ChallengeColors.darkPurple,
                  ),
                ),
                // Song info
                if (item.songTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.songArtist ?? ''} - ${item.songTitle}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Winner name & points
          Text(
            item.iWon ? '+${item.points}' : '${item.winnerName.split(' ')[0]} +${item.points}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: item.iWon ? Colors.green.shade600 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // COMPACT HEADER - Centered timer with white background
  // ════════════════════════════════════════════════
  Widget _buildCompactHeader() {
    final isTimeRace = _room?.modeVariant == ModeVariant.timeRace;
    final isCritical = isTimeRace && _remainingSeconds <= 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: _handleExit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close,
                  size: 20, color: ChallengeColors.darkPurple),
            ),
          ),

          const Spacer(),

          // Centered Timer/Round with white background
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isCritical ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTimeRace ? Icons.timer_outlined : Icons.flag_rounded,
                        color: isCritical
                            ? ChallengeColors.timeRace
                            : _getModeColor(),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTimeRace
                            ? _formatTime(_remainingSeconds)
                            : 'Tur ${_room!.roundIndex + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isCritical
                              ? ChallengeColors.timeRace
                              : ChallengeColors.darkPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Balance - same width as close button
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // RACE STATUS BAR - Clean scoreboard design
  // ════════════════════════════════════════════════
  Widget _buildRaceStatusBar(RoomPlayer? myPlayer, RoomPlayer? opponentPlayer) {
    final mySubmitted = _room?.hasSubmitted(_myUid ?? '') ?? false;
    final opponentSubmitted =
        _room?.hasSubmitted(_room?.getOpponentUid(_myUid ?? '') ?? '') ?? false;
    final targetScore = _songs.isNotEmpty ? _songs.length : 10;
    final isRealMode = _room?.modeVariant == ModeVariant.real;

    final myScore = isRealMode ? myPlayer?.score ?? 0 : myPlayer?.solvedCount ?? 0;
    final opponentScore = isRealMode ? opponentPlayer?.score ?? 0 : opponentPlayer?.solvedCount ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // MY SCORE - Left side
          Expanded(
            child: _buildScoreSide(
              name: 'Sen',
              score: myScore,
              targetScore: targetScore,
              isRealMode: isRealMode,
              hasSubmitted: mySubmitted,
              isLeading: myScore > opponentScore,
              isLeft: true,
            ),
          ),

          // CENTER DIVIDER with VS
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getModeColor().withValues(alpha: 0.2),
                        _getModeColor().withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _getModeColor(),
                    ),
                  ),
                ),
                if (!isRealMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    '/ $targetScore',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // OPPONENT SCORE - Right side
          Expanded(
            child: _buildScoreSide(
              name: opponentPlayer?.name ?? 'Rakip',
              score: opponentScore,
              targetScore: targetScore,
              isRealMode: isRealMode,
              hasSubmitted: opponentSubmitted,
              isLeading: opponentScore > myScore,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSide({
    required String name,
    required int score,
    required int targetScore,
    required bool isRealMode,
    required bool hasSubmitted,
    required bool isLeading,
    required bool isLeft,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: isLeading
            ? LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  _getModeColor().withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              )
            : null,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(20) : Radius.zero,
          right: !isLeft ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Name row with submitted indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isLeft && hasSubmitted) ...[
                _buildSubmittedBadge(),
                const SizedBox(width: 6),
              ],
              Text(
                isLeft ? 'Sen' : name.split(' ')[0],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ChallengeColors.darkPurple.withValues(alpha: 0.7),
                ),
              ),
              if (isLeft && hasSubmitted) ...[
                const SizedBox(width: 6),
                _buildSubmittedBadge(),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // BIG SCORE with leading indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isLeft && isLeading) ...[
                Icon(
                  Icons.arrow_drop_up_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ],
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isLeading ? _getModeColor() : ChallengeColors.darkPurple,
                  height: 1,
                ),
              ),
              if (isLeft && isLeading) ...[
                Icon(
                  Icons.arrow_drop_up_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 10, color: Colors.green.shade600),
          const SizedBox(width: 2),
          Text(
            'Gönderildi',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }


  // ════════════════════════════════════════════════
  // ROUND WINNER OVERLAY - Celebration moment
  // ════════════════════════════════════════════════
  Widget _buildRoundWinnerOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _iWonThisRound
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (_iWonThisRound ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iWonThisRound ? Icons.emoji_events : Icons.speed,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _iWonThisRound ? 'TUR KAZANDIN!' : 'Rakip Daha Hizliydi',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _iWonThisRound
                        ? '+1 Puan'
                        : '$_roundWinnerName bu turu kazandi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // FEEDBACK OVERLAY - Quick answer feedback
  // ════════════════════════════════════════════════
  Widget _buildFeedbackOverlay() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, double scale, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: 0,
          right: 0,
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _lastAnswerCorrect
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_lastAnswerCorrect ? Colors.green : Colors.red)
                          .withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _lastAnswerCorrect
                          ? (_wonRound ? Icons.emoji_events : Icons.check_circle)
                          : Icons.cancel,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _lastAnswerCorrect
                          ? (_wonRound ? 'KAZANDIN!' : 'Dogru!')
                          : 'YANLIS',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (_bonusPoints > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$_bonusPoints',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusToast() {
    final color =
        _bonusIsSteal ? ChallengeColors.realChallenge : ChallengeColors.timeRace;
    final icon =
        _bonusIsSteal ? Icons.catching_pokemon : Icons.local_fire_department;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _bonusToastMessage ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // JOKER BAR - Compact single use jokers at bottom
  // ════════════════════════════════════════════════
  Widget _buildJokerBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Joker label
          Icon(Icons.auto_awesome, size: 14, color: _getModeColor()),
          const SizedBox(width: 8),

          // Find Artist Joker (disabled if all songs are from same artist)
          Expanded(
            child: _buildJokerButton(
              icon: '🎤',
              label: 'Şarkıcı',
              jokerIndex: 0,
              isUsedThisGame: _jokerArtistUsedThisGame,
              isDisabled: _isSingleArtist,
              onTap: () => _handleJokerTap(0, _useArtistJoker),
            ),
          ),
          const SizedBox(width: 8),

          // Find Song Joker
          Expanded(
            child: _buildJokerButton(
              icon: '🎵',
              label: 'Şarkı',
              jokerIndex: 1,
              isUsedThisGame: _jokerSongUsedThisGame,
              onTap: () => _handleJokerTap(1, _useSongJoker),
            ),
          ),
          const SizedBox(width: 8),

          // x2 Points Joker
          Expanded(
            child: _buildJokerButton(
              icon: '✨',
              label: 'x2',
              jokerIndex: 2,
              isUsedThisGame: _jokerX2UsedThisGame,
              isActive: _x2Active,
              onTap: () => _handleJokerTap(2, _useX2Joker),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJokerButton({
    required String icon,
    required String label,
    required int jokerIndex,
    required bool isUsedThisGame,
    bool isActive = false,
    bool isDisabled = false,
    required VoidCallback onTap,
  }) {
    final user = context.watch<AuthProvider>().user;
    final isPremium = user?.isActivePremium ?? false;
    final jokerState = _rewardsService.getChallengeJokerState(user);
    final hasJoker = isPremium || jokerState[jokerIndex];

    // Bu oyunda kullanıldıysa veya joker yoksa disabled
    final isUsed = isUsedThisGame;
    final needsAd = !isPremium && !hasJoker && !isUsedThisGame;
    final canUse = !isUsed && !isDisabled && _canAnswer && !_isWatchingAd;

    return GestureDetector(
      onTap: canUse ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          gradient: (isUsed || isDisabled)
              ? null
              : isActive
                  ? LinearGradient(
                      colors: [
                        _getModeColor(),
                        _getModeColor().withValues(alpha: 0.8),
                      ],
                    )
                  : needsAd
                      ? LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade400,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            _getModeColor().withValues(alpha: 0.1),
                            _getModeColor().withValues(alpha: 0.05),
                          ],
                        ),
          color: (isUsed || isDisabled) ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isUsed || isDisabled)
                ? Colors.grey.shade300
                : isActive
                    ? _getModeColor()
                    : needsAd
                        ? Colors.amber.shade600
                        : _getModeColor().withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _getModeColor().withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon - reklam gerekiyorsa play ikonu göster
            if (needsAd && !isUsed && !isDisabled)
              Icon(
                Icons.play_circle_fill,
                size: 14,
                color: Colors.amber.shade800,
              )
            else
              Text(
                isUsed ? '✗' : icon,
                style: TextStyle(
                  fontSize: 14,
                  color: (isUsed || isDisabled) ? Colors.grey.shade400 : null,
                ),
              ),
            const SizedBox(width: 4),
            // Label
            Flexible(
              child: Text(
                isActive ? 'AKTİF' : (needsAd && !isUsed ? 'Ad' : label),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: (isUsed || isDisabled)
                      ? Colors.grey.shade400
                      : isActive
                          ? Colors.white
                          : needsAd
                              ? Colors.amber.shade900
                              : ChallengeColors.darkPurple,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Joker'a tıklandığında - joker aktifse kullan, değilse reklam izlet
  Future<void> _handleJokerTap(int jokerIndex, Future<void> Function() useJoker) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final isPremium = user.isActivePremium;
    final jokerState = _rewardsService.getChallengeJokerState(user);
    final hasJoker = isPremium || jokerState[jokerIndex];

    if (hasJoker) {
      // Joker aktif, direkt kullan
      await useJoker();
    } else if (!user.isGuest) {
      // Joker yok, reklam izlet
      await _showAdForJoker(jokerIndex, useJoker);
    } else {
      // Misafir kullanıcı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joker kullanmak için giriş yapın'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Reklam izleyerek joker kazan ve kullan
  Future<void> _showAdForJoker(int jokerIndex, Future<void> Function() useJoker) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isWatchingAd = true);

    // Gerçek reklam göster
    final adShown = await _adService.showRewardedAd(user.tier);

    if (adShown <= 0) {
      setState(() => _isWatchingAd = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reklam yüklenemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await _rewardsService.watchAdForChallengeJoker(user, jokerIndex);

    setState(() => _isWatchingAd = false);

    if (result.success) {
      // Kullanıcı bilgisini güncelle
      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
      }

      // Joker kazanıldı, şimdi kullan
      await useJoker();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Joker kazanıldı!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _useArtistJoker() async {
    if (_jokerArtistUsedThisGame || _songs.isEmpty || _room == null) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Mark as used immediately to prevent double tap
    setState(() => _jokerArtistUsedThisGame = true);
    HapticService.selection();

    // Firestore'da jokeri kullanıldı olarak işaretle (premium değilse)
    if (!user.isActivePremium) {
      await _rewardsService.useChallengeJoker(user, 0);
      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
      }
    }

    // Find the correct song IDs for current word
    final correctSongIds = await _gameService.getCorrectSongIdsForWord(
      _room!.challengeId!,
      _room!.currentWord,
    );

    if (correctSongIds.isEmpty) return;

    // Find the first matching song from our songs list
    final correctSong = _songs.firstWhere(
      (s) => correctSongIds.contains(s.id),
      orElse: () => _songs.first,
    );

    setState(() {
      _selectedArtist = correctSong.artist;
      _selectedSongId = null; // Reset song selection
    });

    // Show toast
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎤 ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  'Şarkıcı: ${correctSong.artist}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: _getModeColor(),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _useSongJoker() async {
    if (_jokerSongUsedThisGame || _songs.isEmpty || _room == null) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Mark as used immediately to prevent double tap
    setState(() => _jokerSongUsedThisGame = true);
    HapticService.selection();

    // Firestore'da jokeri kullanıldı olarak işaretle (premium değilse)
    if (!user.isActivePremium) {
      await _rewardsService.useChallengeJoker(user, 1);
      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
      }
    }

    // Find the correct song IDs for current word
    final correctSongIds = await _gameService.getCorrectSongIdsForWord(
      _room!.challengeId!,
      _room!.currentWord,
    );

    if (correctSongIds.isEmpty) return;

    // Find the first matching song from our songs list
    final correctSong = _songs.firstWhere(
      (s) => correctSongIds.contains(s.id),
      orElse: () => _songs.first,
    );

    // Only set the song, NOT the artist - user still needs to select artist
    setState(() {
      _selectedSongId = correctSong.id;
    });

    // Show toast
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎵 ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  'Şarkı: ${correctSong.title}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: _getModeColor(),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _useX2Joker() async {
    if (_jokerX2UsedThisGame) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() {
      _jokerX2UsedThisGame = true;
      _x2Active = true;
    });

    HapticService.selection();

    // Firestore'da jokeri kullanıldı olarak işaretle (premium değilse)
    if (!user.isActivePremium) {
      await _rewardsService.useChallengeJoker(user, 2);
      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
      }
    }

    // Show toast
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('✨ ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'x2 Puan aktif! Bu turda kazanırsan çift puan!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _getModeColor(),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildComebackIndicator() {
    final multiplier = _room?.comeback?.multiplier ?? 1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ChallengeColors.timeRace, ChallengeColors.realChallenge],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ChallengeColors.timeRace.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'x$multiplier',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'BONUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
