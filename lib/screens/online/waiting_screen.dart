import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/match_intent_model.dart';
import '../../services/matchmaking_service.dart';
import '../../widgets/online_game_ui_components.dart';
import 'friends_word_game_screen.dart';
import '../challenge/challenge_online_screen.dart';

/// Waiting Screen with engaging UX
/// - Animated waiting state that feels alive
/// - "Davet" language instead of "ID"
/// - Confidence-building micro-copy
/// - Strong share action with feedback
/// - Soft cancel flow
/// - Smooth transition to match found
class WaitingScreen extends StatefulWidget {
  final String intentId;
  final String myPlayerId;
  final String opponentPlayerId;
  final MatchMode mode;
  final String? challengeName;

  const WaitingScreen({
    super.key,
    required this.intentId,
    required this.myPlayerId,
    required this.opponentPlayerId,
    required this.mode,
    this.challengeName,
  });

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with TickerProviderStateMixin {
  final _matchmakingService = MatchmakingService();
  StreamSubscription<MatchIntentModel?>? _intentSubscription;

  late AnimationController _matchFoundController;
  late Animation<double> _matchFoundAnimation;

  bool _isCanceling = false;
  bool _matchFound = false;
  bool _userInitiatedCancel = false; // Track if user manually canceled
  int _waitingSeconds = 0;
  Timer? _waitingTimer;
  int _currentTipIndex = 0;
  Timer? _tipTimer;

  // Match found countdown
  int _countdown = 3;
  Timer? _countdownTimer;
  String? _matchedRoomId;

  // Game settings from room (fetched after match)
  Map<String, dynamic>? _gameSettings;

  final List<String> _waitingTips = [
    '🎵 Arkadaşın kodunu girince eşleşeceksiniz',
    '📱 Davet linkini tekrar paylaşabilirsin',
    '⏱️ Eşleşme 5 dakika içinde gerçekleşmezse iptal olur',
    '🎮 Her iki taraf da hazır olunca oyun başlar',
    '💡 İpucu: WhatsApp ile link paylaş, en hızlısı!',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _listenToIntent();
    _startWaitingTimer();
    _startTipRotation();
  }

  void _initAnimations() {
    _matchFoundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _matchFoundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _matchFoundController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    _matchFoundController.dispose();
    _waitingTimer?.cancel();
    _tipTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startWaitingTimer() {
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _waitingSeconds++);
      }
    });
  }

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _waitingTips.length;
        });
      }
    });
  }

  void _listenToIntent() {
    _intentSubscription = _matchmakingService.streamIntent(widget.intentId).listen((intent) {
      if (intent == null) return;

      if (intent.isPaired && intent.roomId != null) {
        _onMatchFound(intent.roomId!);
      } else if (intent.isCanceled) {
        // If user manually canceled, just navigate back without showing dialog
        if (_userInitiatedCancel) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        _showStatusDialog(
          emoji: '❌',
          title: 'Davet İptal Edildi',
          message: 'Davet iptal edildi.',
          buttonText: 'Tamam',
        );
      } else if (intent.isExpired) {
        _showStatusDialog(
          emoji: '⏱️',
          title: 'Süre Doldu',
          message: 'Eşleşme süresi doldu. Tekrar dene!',
          buttonText: 'Tamam',
        );
      }
    });
  }

  void _onMatchFound(String roomId) async {
    _matchedRoomId = roomId;
    setState(() => _matchFound = true);
    _matchFoundController.forward();
    HapticFeedback.heavyImpact();

    // Fetch game settings from room
    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('gameRooms')
          .doc(roomId)
          .get();
      if (roomDoc.exists && mounted) {
        setState(() {
          _gameSettings = {
            'endCondition': roomDoc.data()?['endCondition'] ?? 'songCount',
            'targetRounds': roomDoc.data()?['targetRounds'] ?? 10,
            'timeMinutes': roomDoc.data()?['timeMinutes'] ?? 5,
            'wordTimerSeconds': roomDoc.data()?['wordTimerSeconds'] ?? 30,
            'skipCount': roomDoc.data()?['skipCount'] ?? 0,
          };
        });
      }
    } catch (e) {
      // Ignore errors, will use defaults
    }

    // Start countdown
    _startCountdown(roomId);
  }

  void _startCountdown(String roomId) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 1) {
        setState(() => _countdown--);
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
        _navigateToGame(roomId);
      }
    });
  }

  void _navigateToGame(String roomId) {
    Widget gameScreen;
    if (widget.mode == MatchMode.friendsWord) {
      gameScreen = FriendsWordGameScreen(roomId: roomId);
    } else {
      gameScreen = ChallengeOnlineScreen(roomId: roomId);
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => gameScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showStatusDialog({
    required String emoji,
    required String title,
    required String message,
    required String buttonText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF394272),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF394272),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Future<void> _cancelMatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('⏸️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text('Beklemekten Vazgeç'),
          ],
        ),
        content: const Text('Eşleşme beklemeyi iptal etmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Beklemeye Devam'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF85149)),
            child: const Text('Vazgeç'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCanceling = true;
      _userInitiatedCancel = true;
    });

    try {
      await _matchmakingService.cancelIntent(widget.intentId);
      // Navigation will be handled by the stream listener when intent is canceled
      // But if it doesn't fire quickly, navigate after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isCanceling) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCanceling = false;
          _userInitiatedCancel = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İptal edilemedi: $e'),
            backgroundColor: const Color(0xFFF85149),
          ),
        );
      }
    }
  }

  void _shareInvite() {
    HapticFeedback.lightImpact();
    
    final link = 'find2sing://match?opponentId=${widget.myPlayerId}';
    final modeText = widget.mode == MatchMode.challengeOnline
        ? (widget.challengeName ?? 'Challenge')
        : 'Arkadaşla Oyna';
    
    Share.share(
      '🎵 Find2Sing\'de $modeText modunda benimle oyna!\n\n'
      '📋 Davet Kodum: ${widget.myPlayerId}\n\n'
      '🔗 $link',
      subject: 'Find2Sing Davet',
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.myPlayerId));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Text('Davet kodu kopyalandı!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatWaitingTime() {
    final minutes = _waitingSeconds ~/ 60;
    final seconds = _waitingSeconds % 60;
    if (minutes > 0) {
      return '$minutes dk ${seconds.toString().padLeft(2, '0')} sn';
    }
    return '$seconds saniye';
  }

  @override
  Widget build(BuildContext context) {
    if (_matchFound) {
      return _buildMatchFoundScreen();
    }

    return OnlineGameScaffold(
      showBackButton: false,
      titleWidget: widget.mode == MatchMode.challengeOnline && widget.challengeName != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: OnlineGameColors.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    widget.challengeName!,
                    style: const TextStyle(
                      color: OnlineGameColors.accentOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Animated waiting indicator - using MusicBoxWaitingIndicator
            MusicBoxWaitingIndicator(
              message: 'Arkadaşın Bekleniyor',
              color: OnlineGameColors.primaryPurple,
            ),

            const SizedBox(height: 24),

            // Waiting time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: OnlineGameColors.primaryPurple, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _formatWaitingTime(),
                    style: const TextStyle(
                      color: OnlineGameColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // My code card
            _buildMyCodeCard(),

            const SizedBox(height: 20),

            // Rotating tips
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_currentTipIndex),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _waitingTips[_currentTipIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OnlineGameColors.darkPurple.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Share button
            OnlineGameCTAButton(
              label: 'Daveti Tekrar Paylaş',
              icon: Icons.share_rounded,
              onTap: _shareInvite,
              color: OnlineGameColors.primaryPurple,
            ),

            const SizedBox(height: 12),

            // Cancel button
            TextButton(
              onPressed: _isCanceling ? null : _cancelMatch,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: _isCanceling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: OnlineGameColors.darkPurple,
                      ),
                    )
                  : Text(
                      'Beklemekten Vazgeç',
                      style: TextStyle(
                        color: OnlineGameColors.darkPurple.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Senin Davet Kodun',
            style: TextStyle(
              color: const Color(0xFF6C6FA4).withValues(alpha:0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.myPlayerId,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF394272),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAB7FF).withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFFCAB7FF),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchFoundScreen() {
    return OnlineGameScaffold(
      showBackButton: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Match found header with vinyl-style animation
            AnimatedBuilder(
              animation: _matchFoundAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _matchFoundAnimation.value,
                  child: Opacity(
                    opacity: _matchFoundAnimation.value,
                    child: Column(
                      children: [
                        // Vinyl-style success indicator
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                OnlineGameColors.success,
                                Color(0xFF66BB6A),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: OnlineGameColors.success.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                              // Inner content
                              const Text('🎵', style: TextStyle(fontSize: 44)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: OnlineGameColors.success.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: OnlineGameColors.success,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Eşleşme Bulundu!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: OnlineGameColors.success,
                                ),
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

            const SizedBox(height: 40),

            // Large countdown number with vinyl-style design
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Container(
                key: ValueKey(_countdown),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      OnlineGameColors.primaryPurple,
                      OnlineGameColors.primaryPurple.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OnlineGameColors.primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer vinyl ring effect
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    // Inner ring
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    // Countdown number
                    Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: OnlineGameColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Oyun başlıyor...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OnlineGameColors.darkPurple.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Game settings display (only for friendsWord mode)
            if (widget.mode == MatchMode.friendsWord && _gameSettings != null)
              _buildGameSettingsCard(),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSettingsCard() {
    final endCondition = _gameSettings!['endCondition'] as String;
    final targetRounds = _gameSettings!['targetRounds'] as int;
    final timeMinutes = _gameSettings!['timeMinutes'] as int;
    final wordTimerSeconds = _gameSettings!['wordTimerSeconds'] as int;
    final skipCount = _gameSettings!['skipCount'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Oyun Ayarları',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: OnlineGameColors.darkPurple.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSettingItem(
                  icon: '⏱️',
                  label: 'Tahmin Süresi',
                  value: '$wordTimerSeconds sn',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE8E4F0),
              ),
              Expanded(
                child: _buildSettingItem(
                  icon: endCondition == 'songCount' ? '🎵' : '⏰',
                  label: 'Oyun Sonu',
                  value: endCondition == 'songCount'
                      ? '$targetRounds şarkı'
                      : '$timeMinutes dakika',
                ),
              ),
            ],
          ),
          if (skipCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OnlineGameColors.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Kelime değiştirme: $skipCount hak',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: OnlineGameColors.accentOrange,
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

  Widget _buildSettingItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: OnlineGameColors.darkPurple.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: OnlineGameColors.darkPurple,
          ),
        ),
      ],
    );
  }
}
