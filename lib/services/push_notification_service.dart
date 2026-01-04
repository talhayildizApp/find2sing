import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM Push Notification Service
/// Handles match invitations, game updates, friend requests
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _notificationController = StreamController<NotificationData>.broadcast();
  Stream<NotificationData> get onNotification => _notificationController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _setupFCM();
    }
  }

  Future<void> _setupFCM() async {
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
      // Update token in Firestore if user is logged in
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check for initial message (app opened from terminated state via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    
    final data = _parseMessage(message);
    if (data != null) {
      _notificationController.add(data);
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    debugPrint('Message tap: ${message.data}');
    
    final data = _parseMessage(message);
    if (data != null) {
      data.wasOpened = true;
      _notificationController.add(data);
    }
  }

  NotificationData? _parseMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'match_invite':
        return NotificationData(
          type: NotificationType.matchInvite,
          title: message.notification?.title ?? 'Maç Daveti',
          body: message.notification?.body ?? 'Biri seni oyuna davet etti!',
          oderId: data['oderId'],
          challengeId: data['challengeId'],
          mode: data['mode'],
        );

      case 'match_accepted':
        return NotificationData(
          type: NotificationType.matchAccepted,
          title: message.notification?.title ?? 'Davet Kabul Edildi',
          body: message.notification?.body ?? 'Rakibin hazır!',
          roomId: data['roomId'],
        );

      case 'your_turn':
        return NotificationData(
          type: NotificationType.yourTurn,
          title: message.notification?.title ?? 'Sıra Sende!',
          body: message.notification?.body ?? 'Rakibin oynadı, şimdi senin sıran.',
          roomId: data['roomId'],
        );

      case 'game_finished':
        return NotificationData(
          type: NotificationType.gameFinished,
          title: message.notification?.title ?? 'Oyun Bitti',
          body: message.notification?.body ?? 'Sonuçları gör!',
          roomId: data['roomId'],
        );

      case 'friend_request':
        return NotificationData(
          type: NotificationType.friendRequest,
          title: message.notification?.title ?? 'Arkadaşlık İsteği',
          body: message.notification?.body ?? 'Biri seninle arkadaş olmak istiyor.',
          oderId: data['oderId'],
        );

      default:
        return null;
    }
  }

  /// Save FCM token to user document
  Future<void> saveTokenForUser(String oderId) async {
    if (_fcmToken == null) return;

    await _db.collection('users').doc(oderId).update({
      'fcmTokens': FieldValue.arrayUnion([_fcmToken]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Remove FCM token from user document (on logout)
  Future<void> removeTokenForUser(String oderId) async {
    if (_fcmToken == null) return;

    await _db.collection('users').doc(oderId).update({
      'fcmTokens': FieldValue.arrayRemove([_fcmToken]),
    });
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  void dispose() {
    _notificationController.close();
  }
}

enum NotificationType {
  matchInvite,
  matchAccepted,
  yourTurn,
  gameFinished,
  friendRequest,
}

class NotificationData {
  final NotificationType type;
  final String title;
  final String body;
  final String? oderId;
  final String? challengeId;
  final String? mode;
  final String? roomId;
  bool wasOpened;

  NotificationData({
    required this.type,
    required this.title,
    required this.body,
    this.oderId,
    this.challengeId,
    this.mode,
    this.roomId,
    this.wasOpened = false,
  });

  @override
  String toString() {
    return 'NotificationData(type: $type, title: $title, roomId: $roomId)';
  }
}
