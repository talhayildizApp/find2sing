import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/deep_link_service.dart';
import '../services/push_notification_service.dart';
import '../services/challenge_service.dart';
import '../services/matchmaking_service.dart';
import '../screens/challenge/challenge_detail_screen.dart';
import '../screens/challenge/challenge_online_screen.dart';
import '../screens/online/online_match_screen.dart';

/// Wrapper widget that handles deep links and push notifications
class AppLinkHandler extends StatefulWidget {
  final Widget child;

  const AppLinkHandler({super.key, required this.child});

  @override
  State<AppLinkHandler> createState() => _AppLinkHandlerState();
}

class _AppLinkHandlerState extends State<AppLinkHandler> {
  final DeepLinkService _deepLinkService = DeepLinkService();
  final PushNotificationService _pushService = PushNotificationService();
  final ChallengeService _challengeService = ChallengeService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  StreamSubscription<DeepLinkData>? _linkSubscription;
  StreamSubscription<NotificationData>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _deepLinkService.initialize();
    await _pushService.initialize();

    // Listen for deep links
    _linkSubscription = _deepLinkService.onLink.listen(_handleDeepLink);

    // Listen for notifications
    _notificationSubscription = _pushService.onNotification.listen(_handleNotification);

    // Check for pending link
    if (_deepLinkService.pendingLink != null) {
      _handleDeepLink(_deepLinkService.pendingLink!);
    }
  }

  void _handleDeepLink(DeepLinkData data) {
    debugPrint('Handling deep link: $data');

    // Wait for context to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (data.type) {
        case DeepLinkType.matchInvite:
          _handleMatchInvite(data);
          break;
        case DeepLinkType.openChallenge:
          _handleOpenChallenge(data);
          break;
        case DeepLinkType.friendInvite:
          _handleFriendInvite(data);
          break;
        case DeepLinkType.joinRoom:
          _handleJoinRoom(data);
          break;
      }

      _deepLinkService.clearPendingLink();
    });
  }

  void _handleNotification(NotificationData data) {
    debugPrint('Handling notification: $data');

    if (data.wasOpened) {
      // User tapped the notification - navigate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navigateFromNotification(data);
      });
    } else {
      // Foreground notification - show in-app alert
      _showInAppNotification(data);
    }
  }

  Future<void> _handleMatchInvite(DeepLinkData data) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    // Show invite dialog
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Maç Daveti'),
        content: Text(
          'Oyuncu ${data.oderId?.substring(0, 8)}... seni ${data.challengeId} challenge\'ına davet ediyor.\n\nMod: ${data.mode}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Reddet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );

    if (accept == true && data.oderId != null && data.challengeId != null) {
      // Accept the match
      final myUid = authProvider.user!.uid;
      
      try {
        final roomId = await _matchmakingService.acceptMatch(
          oderId: myUid,
          opponentId: data.oderId!,
          challengeId: data.challengeId!,
        );

        if (roomId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeOnlineScreen(roomId: roomId),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleOpenChallenge(DeepLinkData data) async {
    if (data.challengeId == null) return;

    try {
      final challenge = await _challengeService.getChallenge(data.challengeId!);
      if (challenge != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening challenge: $e');
    }
  }

  void _handleFriendInvite(DeepLinkData data) {
    // Navigate to friend add screen with pre-filled ID
    if (data.oderId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineMatchScreen(prefilledOpponentId: data.oderId),
        ),
      );
    }
  }

  Future<void> _handleJoinRoom(DeepLinkData data) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    if (data.roomId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeOnlineScreen(roomId: data.roomId!),
        ),
      );
    }
  }

  void _navigateFromNotification(NotificationData data) {
    switch (data.type) {
      case NotificationType.matchInvite:
        if (data.challengeId != null && data.oderId != null) {
          _handleMatchInvite(DeepLinkData(
            type: DeepLinkType.matchInvite,
            oderId: data.oderId,
            challengeId: data.challengeId,
            mode: data.mode,
          ));
        }
        break;

      case NotificationType.matchAccepted:
      case NotificationType.yourTurn:
      case NotificationType.gameFinished:
        if (data.roomId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeOnlineScreen(roomId: data.roomId!),
            ),
          );
        }
        break;

      case NotificationType.friendRequest:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineMatchScreen(prefilledOpponentId: data.oderId),
          ),
        );
        break;
    }
  }

  void _showInAppNotification(NotificationData data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(data.body),
          ],
        ),
        action: SnackBarAction(
          label: 'Aç',
          onPressed: () => _navigateFromNotification(data..wasOpened = true),
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giriş Gerekli'),
        content: const Text('Bu özelliği kullanmak için giriş yapmalısın.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
