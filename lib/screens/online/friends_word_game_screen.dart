import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/game_room_model.dart';
import '../../services/friends_online_game_service.dart';
import '../../widgets/online_game_ui_components.dart';

/// Friends Online Word Game with improved turn-based UX
/// - Dramatic reviewer countdown with auto-approve
/// - Tension-building waiting states
/// - Time pressure visualization
/// - Clear feedback after actions
class FriendsWordGameScreen extends StatefulWidget {
  final String roomId;

  const FriendsWordGameScreen({super.key, required this.roomId});

  @override
  State<FriendsWordGameScreen> createState() => _FriendsWordGameScreenState();
}

class _FriendsWordGameScreenState extends State<FriendsWordGameScreen>
    with TickerProviderStateMixin {
  final _gameService = FriendsOnlineGameService();
  final _songController = TextEditingController();
  final _artistController = TextEditingController();
  final _songFocus = FocusNode();
  final _artistFocus = FocusNode();

  StreamSubscription<GameRoomModel?>? _roomSubscription;
  GameRoomModel? _room;
  List<FriendsWordRound> _rounds = [];
  bool _isSubmitting = false;
  bool _hasSubmittedAnswer = false;
  bool _hasSubmittedReview = false;
  Timer? _reviewTimer;
  int _reviewSecondsLeft = 5;

  // Game timer for time-based mode
  Timer? _gameTimer;
  Duration _remainingTime = Duration.zero;
  bool _isTimeBased = false;

  // Word timer - countdown for each turn
  Timer? _wordTimer;
  int _wordSecondsLeft = 30;
  static const int _wordTotalSeconds = 30;

  // Track round index to detect round changes
  int? _lastRoundIndex;

  // Track which round we submitted review for (prevents cross-round issues)
  int? _reviewSubmittedForRound;

  // Track if I'm the one leaving (to prevent showing abandoned dialog to myself)
  bool _isLeaving = false;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  // Feedback state
  String? _feedbackMessage;
  Color? _feedbackColor;
  bool _showFeedback = false;

  String? get _myUid => context.read<AuthProvider>().user?.uid;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _listenToRoom();
    _listenToRounds();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _reviewTimer?.cancel();
    _gameTimer?.cancel();
    _wordTimer?.cancel();
    _songController.dispose();
    _artistController.dispose();
    _songFocus.dispose();
    _artistFocus.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _listenToRoom() {
    _roomSubscription = _gameService.streamRoom(widget.roomId).listen((room) {
      if (room == null) return;

      final previousPhase = _room?.phase;
      final previousRoundIndex = _lastRoundIndex;
      final isFirstLoad = _room == null;
      setState(() => _room = room);

      // Track round index
      _lastRoundIndex = room.roundIndex;

      // Initialize game timer for time-based mode (only once)
      if (_gameTimer == null && room.endCondition == 'time' && room.endsAt != null) {
        _isTimeBased = true;
        _startGameTimer(room.endsAt!);
      }

      // Start word timer on first load if in answering phase
      if (isFirstLoad && room.phase == GamePhase.answering) {
        _startWordTimer();
      }

      if (room.isFinished) {
        _gameTimer?.cancel();
        _showGameEndDialog();
      } else if (room.status == RoomStatus.abandoned && !_isLeaving) {
        // Only show abandoned dialog if I'm not the one who left
        _gameTimer?.cancel();
        _showAbandonedDialog();
      }

      // Detect round change (new round started)
      final roundChanged = previousRoundIndex != null && previousRoundIndex != room.roundIndex;

      // Reset submission states on phase change OR round change
      if (previousPhase != room.phase || roundChanged) {
        setState(() {
          _hasSubmittedAnswer = false;
          _hasSubmittedReview = false;
          _showFeedback = false;
          // Only reset round tracking when round actually changes
          if (roundChanged) {
            _reviewSubmittedForRound = null;
          }
        });

        // Handle word timer based on phase
        if (room.phase == GamePhase.answering) {
          // Start word timer when answering phase begins or round changes
          _startWordTimer();
        } else {
          // Stop word timer when not in answering phase
          _stopWordTimer();
        }
      }

      // Start review timer if in reviewing phase - only once per phase change
      if (room.phase == GamePhase.reviewing &&
          room.reviewDeadlineAt != null &&
          previousPhase != GamePhase.reviewing) {
        _startReviewTimer(room.reviewDeadlineAt!);
      }
    });
  }

  void _listenToRounds() {
    _gameService.streamRounds(widget.roomId).listen((rounds) {
      setState(() => _rounds = rounds);
    });
  }

  void _startGameTimer(DateTime endsAt) {
    _gameTimer?.cancel();
    _remainingTime = endsAt.difference(DateTime.now());
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
    }

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = endsAt.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        setState(() => _remainingTime = Duration.zero);
        timer.cancel();
        // Game will end via Firestore listener
      } else {
        setState(() => _remainingTime = remaining);

        // Haptic feedback on last 10 seconds
        if (remaining.inSeconds <= 10 && remaining.inSeconds > 0) {
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  void _startReviewTimer(DateTime deadline) {
    _reviewTimer?.cancel();
    final remaining = deadline.difference(DateTime.now());
    _reviewSecondsLeft = remaining.inSeconds.clamp(0, 5);

    // Capture the turnUid and roundIndex at timer start - this is who submitted the answer
    final answerSubmitterUid = _room?.turnUid;
    final currentRoundIndex = _room?.roundIndex;

    _reviewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_reviewSecondsLeft > 0) {
        setState(() => _reviewSecondsLeft--);

        // Haptic on last 3 seconds
        if (_reviewSecondsLeft <= 3) {
          HapticFeedback.lightImpact();
        }
      } else {
        timer.cancel();
        // Auto-approve when timer expires - ONLY if I am the REVIEWER (not answer submitter)
        // AND the round hasn't changed (prevents stale timer callbacks)
        // This prevents race conditions - only reviewer's client can auto-approve
        final isReviewer = answerSubmitterUid != _myUid;
        if (isReviewer && !_hasSubmittedReview && currentRoundIndex == _room?.roundIndex) {
          _autoApproveAsReviewer();
        }
      }
    });
  }

  /// Auto-approve as reviewer when timer expires (only called by reviewer's client)
  Future<void> _autoApproveAsReviewer() async {
    if (_room == null) return;

    final currentRoundIndex = _room!.roundIndex;

    // Double check we're still in reviewing phase
    if (_room!.phase != GamePhase.reviewing) return;

    // Double check I am NOT the answer submitter (I am the reviewer)
    if (_room!.turnUid == _myUid) return;

    // Check if we already submitted review for THIS round
    if (_reviewSubmittedForRound == currentRoundIndex) return;

    // Double check I haven't already submitted a review
    if (_hasSubmittedReview) return;

    // Set flags immediately to prevent double calls
    setState(() {
      _hasSubmittedReview = true;
      _reviewSubmittedForRound = currentRoundIndex;
    });

    try {
      final success = await _gameService.submitReview(
        roomId: widget.roomId,
        reviewerUid: _myUid!,
        approved: true, // Auto-approve
      );
      if (success) {
        _showFeedbackBanner('Otomatik onaylandı ✓', const Color(0xFF4CAF50));
      }
      // Don't reset flags even if success is false
      // because the round may have been resolved by manual review
    } catch (e) {
      // Only reset on actual errors (not transaction conflicts)
      // Keep flags to prevent retries
    }
  }

  void _startWordTimer() {
    _wordTimer?.cancel();
    setState(() => _wordSecondsLeft = _wordTotalSeconds);

    // Capture the turnUid and roundIndex at timer start
    final currentTurnUid = _room?.turnUid;
    final currentRoundIndex = _room?.roundIndex;
    final isMyTurnAtStart = currentTurnUid == _myUid;

    _wordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_wordSecondsLeft > 0) {
        setState(() => _wordSecondsLeft--);

        // Haptic warnings - only for the player whose turn it is
        if (isMyTurnAtStart) {
          if (_wordSecondsLeft <= 5) {
            HapticFeedback.lightImpact();
          } else if (_wordSecondsLeft <= 10 && _wordSecondsLeft % 2 == 0) {
            HapticFeedback.selectionClick();
          }
        }
      } else {
        timer.cancel();
        // Timer expired - skip turn ONLY if it was my turn when timer started
        // AND the round hasn't changed (prevents stale timer callbacks)
        if (isMyTurnAtStart && currentRoundIndex == _room?.roundIndex) {
          _handleWordTimerExpired(currentTurnUid!);
        }
      }
    });
  }

  /// Handle word timer expiration - skip turn
  Future<void> _handleWordTimerExpired(String turnUidAtStart) async {
    if (_room == null) return;

    // Verify the turn hasn't changed (phase change would have cancelled this timer anyway)
    if (_room!.turnUid != turnUidAtStart) return;

    // Only if still in answering phase
    if (_room!.phase != GamePhase.answering) return;

    // Only if answer not already submitted
    if (_hasSubmittedAnswer) return;

    try {
      await _gameService.skipTurn(
        roomId: widget.roomId,
        oderId: _myUid!,
      );
      _showFeedbackBanner('Süre doldu!', const Color(0xFFFFB958));
    } catch (e) {
      // Ignore errors - turn may have already changed
    }
  }

  void _stopWordTimer() {
    _wordTimer?.cancel();
    _wordTimer = null;
  }

  Future<void> _submitAnswer() async {
    final song = _songController.text.trim();
    final artist = _artistController.text.trim();

    if (song.isEmpty || artist.isEmpty) {
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      _showFeedbackBanner('Şarkı ve sanatçı adını gir!', const Color(0xFFFF6B6B));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _hasSubmittedAnswer = true;
    });

    HapticFeedback.mediumImpact();

    try {
      await _gameService.submitAnswer(
        roomId: widget.roomId,
        oderId: _myUid!,
        song: song,
        artist: artist,
      );
      
      _showFeedbackBanner('Cevap gönderildi! ✓', const Color(0xFF4CAF50));
      _songController.clear();
      _artistController.clear();
    } catch (e) {
      setState(() => _hasSubmittedAnswer = false);
      _showFeedbackBanner('Hata oluştu', const Color(0xFFF85149));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitReview(bool approved) async {
    final currentRoundIndex = _room?.roundIndex;

    // Check if we already submitted review for THIS round
    if (_reviewSubmittedForRound == currentRoundIndex) return;

    setState(() {
      _hasSubmittedReview = true;
      _reviewSubmittedForRound = currentRoundIndex;
    });
    HapticFeedback.mediumImpact();

    try {
      await _gameService.submitReview(
        roomId: widget.roomId,
        reviewerUid: _myUid!,
        approved: approved,
      );

      _showFeedbackBanner(
        approved ? 'Onaylandı! ✓' : 'Reddedildi ✗',
        approved ? const Color(0xFF4CAF50) : const Color(0xFFF85149),
      );
    } catch (e) {
      // Don't reset - keep flags to prevent double submission
      _showFeedbackBanner('Hata oluştu', const Color(0xFFF85149));
    }
  }

  void _showFeedbackBanner(String message, Color color) {
    setState(() {
      _feedbackMessage = message;
      _feedbackColor = color;
      _showFeedback = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFeedback = false);
      }
    });
  }

  void _showGameEndDialog() {
    if (_room == null) return;

    final myPlayer = _room!.getPlayer(_myUid!);
    // Get opponent based on MY uid, not turnUid
    final opponentUid = _room!.players.keys.firstWhere(
      (uid) => uid != _myUid,
      orElse: () => '',
    );
    final opponent = _room!.getPlayer(opponentUid);
    final myScore = myPlayer?.score ?? 0;
    final opponentScore = opponent?.score ?? 0;

    String emoji;
    String resultText;
    String subtitle;
    List<Color> headerGradient;

    if (myScore > opponentScore) {
      emoji = '🏆';
      resultText = 'Kazandın!';
      subtitle = 'Tebrikler, harika oynadın!';
      headerGradient = [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
    } else if (myScore < opponentScore) {
      emoji = '😔';
      resultText = 'Kaybettin';
      subtitle = 'Bir dahaki sefere!';
      headerGradient = [const Color(0xFFF85149), const Color(0xFFFF7B6B)];
    } else {
      emoji = '🤝';
      resultText = 'Berabere';
      subtitle = 'İkiniz de iyi oynadınız!';
      headerGradient = [const Color(0xFFFFB958), const Color(0xFFFFCE54)];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Cloudy gradient background like challenge result
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF0E6FF), // Light purple
                Color(0xFFFFF8E1), // Light cream
                Colors.white,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: headerGradient),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      resultText,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Score section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Score comparison
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreCard(
                            'Sen',
                            myScore,
                            myScore > opponentScore,
                            const Color(0xFFCAB7FF),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildScoreCard(
                            opponent?.name ?? 'Rakip',
                            opponentScore,
                            opponentScore > myScore,
                            const Color(0xFFFFB958),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF394272),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ana Menü',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String name, int score, bool isWinner, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isWinner
            ? accentColor.withValues(alpha: 0.15)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: isWinner
            ? Border.all(color: accentColor.withValues(alpha: 0.4), width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('🏆', style: TextStyle(fontSize: 20)),
            ),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isWinner ? accentColor : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isWinner ? accentColor : const Color(0xFF394272),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🚪', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            const Text('Rakip Ayrıldı'),
          ],
        ),
        content: const Text('Rakip oyundan ayrıldı. Maç sona erdi.'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🚪', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            const Text('Oyundan Çık'),
          ],
        ),
        content: const Text('Oyundan çıkarsan maçı kaybedersin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Devam Et'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF85149)),
            child: const Text('Çık'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _isLeaving = true;
      // Fire and forget - don't wait for completion
      _gameService.leaveGame(widget.roomId, _myUid!).catchError((_) {});
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_room == null) {
      return OnlineGameScaffold(
        showBackButton: false,
        child: Center(
          child: MusicBoxWaitingIndicator(
            message: 'Oyun yükleniyor...',
            color: OnlineGameColors.primaryPurple,
          ),
        ),
      );
    }

    final isMyTurn = _room!.turnUid == _myUid;
    final myPlayer = _room!.getPlayer(_myUid!);
    // Get opponent based on MY uid, not turnUid
    final opponentUid = _room!.players.keys.firstWhere(
      (uid) => uid != _myUid,
      orElse: () => '',
    );
    final opponent = _room!.getPlayer(opponentUid);

    // Calculate total score for progress display
    final totalScore = (myPlayer?.score ?? 0) + (opponent?.score ?? 0);
    final isSongCountMode = _room!.endCondition == 'songCount';
    final targetRounds = _room!.targetRounds ?? 10;

    return OnlineGameScaffold(
      showBackButton: true,
      onBack: _leaveGame,
      title: 'Arkadaşla Online',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer badge for time-based mode
          if (_isTimeBased) _buildCompactTimer(),
          if (_isTimeBased) const SizedBox(width: 8),
          // Progress/Round badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OnlineGameColors.primaryPurple, Color(0xFF9B7EDE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSongCountMode) ...[
                  const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$totalScore/$targetRounds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Tur ${_room!.roundIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildScoreBar(myPlayer, opponent),
          const SizedBox(height: 16),
          _buildWordDisplay(),

          // Feedback banner
          if (_showFeedback)
            InlineFeedbackBanner(
              message: _feedbackMessage ?? '',
              isSuccess: _feedbackColor == const Color(0xFF4CAF50),
            ),

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

  Widget _buildCompactTimer() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    final isLowTime = _remainingTime.inSeconds <= 60;
    final isCritical = _remainingTime.inSeconds <= 30;

    // Colors matching app theme - more visible
    final Color bgColor;
    final Color textColor;
    if (isCritical) {
      bgColor = const Color(0xFFF85149);
      textColor = Colors.white;
    } else if (isLowTime) {
      bgColor = const Color(0xFFFFB958);
      textColor = Colors.white;
    } else {
      bgColor = Colors.white;
      textColor = const Color(0xFF394272);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isCritical ? 1.08 : 1.0),
      duration: Duration(milliseconds: isCritical ? 400 : 200),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isCritical
                  ? bgColor.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: isCritical ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              color: textColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(RoomPlayer? myPlayer, RoomPlayer? opponent) {
    final isMyTurn = _room!.turnUid == _myUid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ConcertTicketScoreCard(
              playerName: 'Sen',
              score: myPlayer?.score ?? 0,
              isMe: true,
              isActive: isMyTurn,
              accentColor: OnlineGameColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          // VS badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: OnlineGameColors.darkPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConcertTicketScoreCard(
              playerName: opponent?.name ?? 'Rakip',
              score: opponent?.score ?? 0,
              isMe: false,
              isActive: !isMyTurn,
              accentColor: OnlineGameColors.accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplay() {
    final isMyTurn = _room!.turnUid == _myUid;
    final showWordTimer = _room!.phase == GamePhase.answering;

    return Center(
      child: VinylWordCard(
        word: _room!.currentWord,
        isMyTurn: isMyTurn && _room!.phase == GamePhase.answering,
        animate: true,
        accentColor: isMyTurn
            ? OnlineGameColors.primaryPurple
            : OnlineGameColors.accentOrange,
        wordSecondsLeft: showWordTimer ? _wordSecondsLeft : null,
        wordTotalSeconds: showWordTimer ? _wordTotalSeconds : null,
      ),
    );
  }

  Widget _buildAnsweringPhase(bool isMyTurn) {
    if (!isMyTurn) {
      return _buildWaitingForOpponent();
    }

    if (_hasSubmittedAnswer) {
      return _buildAnswerSubmitted();
    }

    return _buildAnswerInput();
  }

  Widget _buildWaitingForOpponent() {
    final opponentName = _room!.currentTurnPlayer?.name ?? 'Rakip';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated opponent indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse rings
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 120 * _pulseAnimation.value,
                      height: 120 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFB958).withValues(alpha:0.3),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB958), Color(0xFFFFCE54)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB958).withValues(alpha:0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎤', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              '$opponentName düşünüyor...',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cevabını bekle',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
              ),
            ),
            const SizedBox(height: 24),
            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value = (_pulseController.value + delay) % 1.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB958).withValues(alpha:0.3 + (value * 0.7)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSubmitted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha:0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 50,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cevap Gönderildi!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rakibin değerlendirmesi bekleniyor...',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * ((_shakeController.value * 10).toInt() % 2 == 0 ? 1 : -1), 0),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact turn indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCAB7FF), Color(0xFF9B7EDE)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎯', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    'Senin Sıran!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stacked inputs - more readable
            // Song input
            TextField(
              controller: _songController,
              focusNode: _songFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _artistFocus.requestFocus(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF394272),
              ),
              decoration: InputDecoration(
                hintText: 'Şarkı Adı',
                hintStyle: TextStyle(
                  color: const Color(0xFF6C6FA4).withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.music_note, color: Color(0xFFCAB7FF), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCAB7FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Artist input
            TextField(
              controller: _artistController,
              focusNode: _artistFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitAnswer(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF394272),
              ),
              decoration: InputDecoration(
                hintText: 'Sanatçı',
                hintStyle: TextStyle(
                  color: const Color(0xFF6C6FA4).withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.mic, color: Color(0xFFCAB7FF), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCAB7FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF394272),
                  disabledBackgroundColor: const Color(0xFF394272).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: const Color(0xFF394272).withValues(alpha: 0.3),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Gönder',
                            style: TextStyle(
                              fontSize: 16,
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
      ),
    );
  }

  Widget _buildReviewingPhase() {
    final isReviewer = _room!.turnUid != _myUid;
    final currentRound = _rounds.isNotEmpty ? _rounds.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Answer display with timer badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Timer badge at top
                _buildReviewTimer(),
                const SizedBox(height: 10),
                Text(
                  'Verilen Cevap',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentRound?.answerSong ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF394272),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  currentRound?.answerArtist ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C6FA4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (isReviewer && !_hasSubmittedReview) ...[
            // Question + Buttons inline
            const Text(
              'Bu cevap doğru mu?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF394272),
              ),
            ),
            const SizedBox(height: 10),
            // Compact buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _submitReview(false),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reddet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF85149),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _submitReview(true),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Onayla', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Info text
            Text(
              'Süre bitince otomatik onaylanır',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF6C6FA4).withValues(alpha: 0.6),
              ),
            ),
          ] else if (_hasSubmittedReview) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Değerlendirme gönderildi',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB958).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFB958),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Rakip değerlendiriyor...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFFB958),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTimer() {
    final isUrgent = _reviewSecondsLeft <= 2;
    final color = isUrgent ? const Color(0xFFF85149) : const Color(0xFFFFB958);

    // Compact circular timer badge
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$_reviewSecondsLeft',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_rounds.isEmpty) return const SizedBox.shrink();

    final resolvedRounds = _rounds.where((r) => r.resolved).take(5).toList();
    if (resolvedRounds.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                const Text(
                  '🎵',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  'Oyun Geçmişi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: OnlineGameColors.darkPurple.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90, // Adjusted height for compact cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: resolvedRounds.length,
              itemBuilder: (context, index) {
                final round = resolvedRounds[index];
                final isMyRound = round.turnUid == _myUid;
                final isAccepted = round.isAccepted ?? false;

                return Container(
                  width: 130, // Slightly narrower for compact design
                  margin: const EdgeInsets.only(right: 10),
                  child: PlaylistSongItem(
                    songTitle: round.answerSong ?? '-',
                    artistName: round.answerArtist ?? '-',
                    word: round.word,
                    isAccepted: isAccepted,
                    isMyRound: isMyRound,
                    index: index + 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
