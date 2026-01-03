import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/match_intent_model.dart';
import '../../services/matchmaking_service.dart';
import 'friends_word_game_screen.dart';
import '../challenge/challenge_online_screen.dart';

class WaitingScreen extends StatefulWidget {
  final String intentId;
  final String opponentPlayerId;
  final MatchMode mode;

  const WaitingScreen({
    super.key,
    required this.intentId,
    required this.opponentPlayerId,
    required this.mode,
  });

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> with SingleTickerProviderStateMixin {
  final _matchmakingService = MatchmakingService();
  StreamSubscription<MatchIntentModel?>? _intentSubscription;
  late AnimationController _pulseController;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _listenToIntent();
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _listenToIntent() {
    _intentSubscription = _matchmakingService.streamIntent(widget.intentId).listen((intent) {
      if (intent == null) return;

      if (intent.isPaired && intent.roomId != null) {
        _navigateToGame(intent.roomId!);
      } else if (intent.isCanceled || intent.isExpired) {
        _showCanceledDialog();
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
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }

  void _showCanceledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Eşleşme İptal'),
        content: const Text('Eşleşme iptal edildi veya süresi doldu.'),
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

  Future<void> _cancelMatch() async {
    setState(() => _isCanceling = true);

    try {
      await _matchmakingService.cancelIntent(widget.intentId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCanceling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İptal edilemedi: $e')),
        );
      }
    }
  }

  void _shareInvite() {
    final link = 'find2sing://match?opponentId=${widget.opponentPlayerId}';
    Share.share(
      'Find2Sing\'de seninle eşleşmeyi bekliyorum!\n\nBenim ID\'m: ${widget.opponentPlayerId}\n\nLink: $link',
      subject: 'Find2Sing Davet',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Animated waiting indicator
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_pulseController.value * 0.1),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFCAB7FF).withOpacity(0.3),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCAB7FF),
                          ),
                          child: const Icon(
                            Icons.people_outline,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              const Text(
                'Rakip Bekleniyor...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF394272),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Aranan Oyuncu',
                      style: TextStyle(color: Color(0xFF6C6FA4), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.opponentPlayerId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF394272),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Arkadaşınız da sizin ID\'nizi\ngirdiğinde oyun başlayacak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              // Share button
              OutlinedButton.icon(
                onPressed: _shareInvite,
                icon: const Icon(Icons.share),
                label: const Text('Daveti Paylaş'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF394272),
                  side: const BorderSide(color: Color(0xFFCAB7FF)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: _isCanceling ? null : _cancelMatch,
                child: _isCanceling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'İptal Et',
                        style: TextStyle(color: Colors.red),
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
