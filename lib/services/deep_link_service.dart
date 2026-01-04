import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

/// Deep Link Service
/// Handles: find2sing://match?oderId=xxx&challengeId=yyy
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  final _pendingLinkController = StreamController<DeepLinkData>.broadcast();
  Stream<DeepLinkData> get onLink => _pendingLinkController.stream;

  DeepLinkData? _pendingLink;
  DeepLinkData? get pendingLink => _pendingLink;

  /// Initialize deep link handling
  Future<void> initialize() async {
    // Handle initial link (app opened via link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleUri(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => debugPrint('Deep link error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('Deep link received: $uri');

    final data = _parseUri(uri);
    if (data != null) {
      _pendingLink = data;
      _pendingLinkController.add(data);
    }
  }

  DeepLinkData? _parseUri(Uri uri) {
    // Scheme: find2sing://
    // Host: match, challenge, invite
    
    switch (uri.host) {
      case 'match':
        // find2sing://match?oderId=xxx&challengeId=yyy&mode=real
        final oderId = uri.queryParameters['oderId'];
        final challengeId = uri.queryParameters['challengeId'];
        final mode = uri.queryParameters['mode'] ?? 'relax';
        
        if (oderId != null && challengeId != null) {
          return DeepLinkData(
            type: DeepLinkType.matchInvite,
            oderId: oderId,
            challengeId: challengeId,
            mode: mode,
          );
        }
        break;

      case 'challenge':
        // find2sing://challenge?id=xxx
        final challengeId = uri.queryParameters['id'];
        if (challengeId != null) {
          return DeepLinkData(
            type: DeepLinkType.openChallenge,
            challengeId: challengeId,
          );
        }
        break;

      case 'invite':
        // find2sing://invite?oderId=xxx
        final oderId = uri.queryParameters['oderId'];
        if (oderId != null) {
          return DeepLinkData(
            type: DeepLinkType.friendInvite,
            oderId: oderId,
          );
        }
        break;

      case 'room':
        // find2sing://room?id=xxx
        final roomId = uri.queryParameters['id'];
        if (roomId != null) {
          return DeepLinkData(
            type: DeepLinkType.joinRoom,
            roomId: roomId,
          );
        }
        break;
    }

    return null;
  }

  /// Clear pending link after handling
  void clearPendingLink() {
    _pendingLink = null;
  }

  /// Generate share link for match invite
  static String generateMatchInviteLink({
    required String oderId,
    required String challengeId,
    String mode = 'relax',
  }) {
    return 'https://find2sing.app/match?oderId=$oderId&challengeId=$challengeId&mode=$mode';
  }

  /// Generate share link for challenge
  static String generateChallengeLink(String challengeId) {
    return 'https://find2sing.app/challenge?id=$challengeId';
  }

  /// Generate share link for room join
  static String generateRoomLink(String roomId) {
    return 'https://find2sing.app/room?id=$roomId';
  }

  void dispose() {
    _linkSubscription?.cancel();
    _pendingLinkController.close();
  }
}

enum DeepLinkType {
  matchInvite,   // Someone inviting to play
  openChallenge, // Direct link to challenge
  friendInvite,  // Friend request
  joinRoom,      // Join existing game room
}

class DeepLinkData {
  final DeepLinkType type;
  final String? oderId;
  final String? challengeId;
  final String? mode;
  final String? roomId;

  DeepLinkData({
    required this.type,
    this.oderId,
    this.challengeId,
    this.mode,
    this.roomId,
  });

  @override
  String toString() {
    return 'DeepLinkData(type: $type, oderId: $oderId, challengeId: $challengeId, mode: $mode, roomId: $roomId)';
  }
}
