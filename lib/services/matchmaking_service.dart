import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_intent_model.dart';
import '../models/game_room_model.dart';
import 'player_id_service.dart';

class MatchmakingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PlayerIdService _playerIdService = PlayerIdService();

  CollectionReference<Map<String, dynamic>> get _intentsRef =>
      _db.collection('matchIntents');

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _db.collection('gameRooms');

  /// Create a match intent
  Future<MatchIntentModel?> createIntent({
    required String fromUid,
    required String fromPlayerId,
    required String toPlayerId,
    required MatchMode mode,
    String? challengeId,
    ModeVariant? modeVariant,
  }) async {
    // Validate toPlayerId exists
    final targetUser = await _playerIdService.getUserByPlayerId(toPlayerId);
    if (targetUser == null) {
      throw Exception('Oyuncu bulunamadı: $toPlayerId');
    }

    // Check if user is trying to match with themselves
    if (fromPlayerId.toUpperCase() == toPlayerId.toUpperCase()) {
      throw Exception('Kendinizle eşleşemezsiniz');
    }

    // Cancel any existing waiting intents from this user
    await _cancelExistingIntents(fromUid);

    // Create new intent
    final intentDoc = _intentsRef.doc();
    final intent = MatchIntentModel(
      id: intentDoc.id,
      fromUid: fromUid,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId.toUpperCase(),
      mode: mode,
      challengeId: challengeId,
      modeVariant: modeVariant,
      createdAt: DateTime.now(),
      status: IntentStatus.waiting,
    );

    await intentDoc.set(intent.toFirestore());

    // Check for reciprocal intent and pair if found
    await _checkAndPairIntents(intent);

    // Return the intent (might be updated with roomId if paired)
    final updatedDoc = await intentDoc.get();
    return MatchIntentModel.fromFirestore(updatedDoc);
  }

  /// Cancel existing waiting intents
  Future<void> _cancelExistingIntents(String uid) async {
    final existingIntents = await _intentsRef
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'waiting')
        .get();

    final batch = _db.batch();
    for (final doc in existingIntents.docs) {
      batch.update(doc.reference, {'status': 'canceled'});
    }
    await batch.commit();
  }

  /// Check for reciprocal intent and create room if found
  Future<void> _checkAndPairIntents(MatchIntentModel newIntent) async {
    // Find reciprocal: other user wants to match with me
    final reciprocalQuery = await _intentsRef
        .where('fromPlayerId', isEqualTo: newIntent.toPlayerId)
        .where('toPlayerId', isEqualTo: newIntent.fromPlayerId)
        .where('mode', isEqualTo: newIntent.mode.name)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (reciprocalQuery.docs.isEmpty) return;

    final reciprocalIntent = MatchIntentModel.fromFirestore(reciprocalQuery.docs.first);

    // Additional checks for challenge mode
    if (newIntent.mode == MatchMode.challengeOnline) {
      if (newIntent.challengeId != reciprocalIntent.challengeId ||
          newIntent.modeVariant != reciprocalIntent.modeVariant) {
        return; // Challenge or mode variant mismatch
      }
    }

    // Create room
    final roomId = await _createGameRoom(newIntent, reciprocalIntent);

    // Update both intents
    final batch = _db.batch();
    batch.update(_intentsRef.doc(newIntent.id), {
      'status': 'paired',
      'roomId': roomId,
    });
    batch.update(_intentsRef.doc(reciprocalIntent.id), {
      'status': 'paired',
      'roomId': roomId,
    });
    await batch.commit();
  }

  /// Create game room based on mode
  Future<String> _createGameRoom(
    MatchIntentModel intent1,
    MatchIntentModel intent2,
  ) async {
    final roomDoc = _roomsRef.doc();
    final now = DateTime.now();

    // Get user info for both players
    final user1 = await _playerIdService.getUserByPlayerId(intent1.fromPlayerId);
    final user2 = await _playerIdService.getUserByPlayerId(intent2.fromPlayerId);

    final players = <String, dynamic>{
      intent1.fromUid: {
        'playerId': intent1.fromPlayerId,
        'name': user1?['displayName'] ?? 'Oyuncu 1',
        'score': 0,
        'solvedCount': 0,
      },
      intent2.fromUid: {
        'playerId': intent2.fromPlayerId,
        'name': user2?['displayName'] ?? 'Oyuncu 2',
        'score': 0,
        'solvedCount': 0,
      },
    };

    // Random turn selection
    final playerUids = [intent1.fromUid, intent2.fromUid];
    final firstTurnUid = playerUids[DateTime.now().millisecond % 2];

    // Generate initial word
    final initialWord = await _generateInitialWord(intent1);

    final roomData = <String, dynamic>{
      'mode': intent1.mode.name,
      'status': 'inProgress',
      'players': players,
      'turnUid': firstTurnUid,
      'roundIndex': 0,
      'phase': intent1.mode == MatchMode.friendsWord ? 'answering' : 'choosing',
      'currentWord': initialWord,
      'lastActionAt': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'startedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    // Add challenge-specific fields
    if (intent1.mode == MatchMode.challengeOnline) {
      roomData['challengeId'] = intent1.challengeId;
      roomData['modeVariant'] = intent1.modeVariant?.name;
      roomData['missedWordByUid'] = {
        intent1.fromUid: <String>[],
        intent2.fromUid: <String>[],
      };

      // Set timer for time race mode
      if (intent1.modeVariant == ModeVariant.timeRace) {
        roomData['endsAt'] = Timestamp.fromDate(now.add(const Duration(minutes: 5)));
      }
    }

    await roomDoc.set(roomData);

    // Create first round document
    await _roomsRef.doc(roomDoc.id).collection('rounds').doc('round_0').set({
      'index': 0,
      'word': initialWord,
      'turnUid': firstTurnUid,
      'createdAt': Timestamp.fromDate(now),
    });

    return roomDoc.id;
  }

  /// Generate initial word for the game
  Future<String> _generateInitialWord(MatchIntentModel intent) async {
    if (intent.mode == MatchMode.challengeOnline && intent.challengeId != null) {
      // Get random word from challenge word index
      final wordIndexQuery = await _db
          .collection('challengeWordIndex')
          .where('challengeId', isEqualTo: intent.challengeId)
          .limit(50)
          .get();

      if (wordIndexQuery.docs.isNotEmpty) {
        final randomIndex = DateTime.now().millisecond % wordIndexQuery.docs.length;
        return wordIndexQuery.docs[randomIndex].data()['word'] ?? 'ŞARKI';
      }
    }

    // Default random word for friends word mode
    const defaultWords = [
      'AŞK', 'GEL', 'GİT', 'SEN', 'BEN', 'GECE', 'GÜNEŞ', 'YAĞMUR',
      'RÜYA', 'KALP', 'YALAN', 'SEVER', 'ÖZLEM', 'UNUTMA', 'HATIRA',
    ];
    return defaultWords[DateTime.now().millisecond % defaultWords.length];
  }

  /// Stream intent status
  Stream<MatchIntentModel?> streamIntent(String intentId) {
    return _intentsRef.doc(intentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MatchIntentModel.fromFirestore(doc);
    });
  }

  /// Stream user's active intent
  Stream<MatchIntentModel?> streamActiveIntent(String uid) {
    return _intentsRef
        .where('fromUid', isEqualTo: uid)
        .where('status', whereIn: ['waiting', 'paired'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return MatchIntentModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Cancel intent
  Future<void> cancelIntent(String intentId) async {
    await _intentsRef.doc(intentId).update({
      'status': 'canceled',
    });
  }

  /// Get intent by ID
  Future<MatchIntentModel?> getIntent(String intentId) async {
    final doc = await _intentsRef.doc(intentId).get();
    if (!doc.exists) return null;
    return MatchIntentModel.fromFirestore(doc);
  }

  /// Clean up expired intents (call periodically)
  Future<void> cleanupExpiredIntents() async {
    final expireTime = DateTime.now().subtract(const Duration(minutes: 10));
    final expiredIntents = await _intentsRef
        .where('status', isEqualTo: 'waiting')
        .where('createdAt', isLessThan: Timestamp.fromDate(expireTime))
        .get();

    final batch = _db.batch();
    for (final doc in expiredIntents.docs) {
      batch.update(doc.reference, {'status': 'expired'});
    }
    await batch.commit();
  }
}
