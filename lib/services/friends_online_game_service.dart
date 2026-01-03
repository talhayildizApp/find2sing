import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room_model.dart';
import '../models/match_intent_model.dart';

class FriendsOnlineGameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _db.collection('gameRooms');

  /// Stream game room
  Stream<GameRoomModel?> streamRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameRoomModel.fromFirestore(doc);
    });
  }

  /// Stream rounds for a room
  Stream<List<FriendsWordRound>> streamRounds(String roomId) {
    return _roomsRef
        .doc(roomId)
        .collection('rounds')
        .orderBy('index', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FriendsWordRound.fromFirestore(doc))
          .toList();
    });
  }

  /// Submit answer (only turnUid can call)
  Future<bool> submitAnswer({
    required String roomId,
    required String oderId,
    required String song,
    required String artist,
  }) async {
    final roomDoc = await _roomsRef.doc(roomId).get();
    if (!roomDoc.exists) return false;

    final room = GameRoomModel.fromFirestore(roomDoc);

    // Verify it's this user's turn
    if (room.turnUid != oderId) return false;

    // Verify phase is answering
    if (room.phase != GamePhase.answering) return false;

    final now = DateTime.now();
    final reviewDeadline = now.add(const Duration(seconds: 5));

    // Update room and current round
    final batch = _db.batch();

    // Update room phase
    batch.update(_roomsRef.doc(roomId), {
      'phase': 'reviewing',
      'reviewDeadlineAt': Timestamp.fromDate(reviewDeadline),
      'lastActionAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    // Update round with answer
    final roundRef = _roomsRef.doc(roomId).collection('rounds').doc('round_${room.roundIndex}');
    batch.update(roundRef, {
      'answer': {
        'song': song,
        'artist': artist,
        'submittedAt': Timestamp.fromDate(now),
      },
    });

    await batch.commit();

    // Start auto-approve timer
    _startAutoApproveTimer(roomId, room.roundIndex, reviewDeadline);

    return true;
  }

  /// Submit review (approve/reject)
  Future<bool> submitReview({
    required String roomId,
    required String reviewerUid,
    required bool approved,
  }) async {
    final roomDoc = await _roomsRef.doc(roomId).get();
    if (!roomDoc.exists) return false;

    final room = GameRoomModel.fromFirestore(roomDoc);

    // Verify reviewer is not the turn player
    if (room.turnUid == reviewerUid) return false;

    // Verify phase is reviewing
    if (room.phase != GamePhase.reviewing) return false;

    // Process review
    await _resolveRound(roomId, room, approved ? 'approved' : 'rejected');

    return true;
  }

  /// Resolve round after review (or auto-approve)
  Future<void> _resolveRound(String roomId, GameRoomModel room, String decision) async {
    final now = DateTime.now();
    final isApproved = decision == 'approved';
    final points = isApproved ? 1 : -1;

    final batch = _db.batch();

    // Update round with review result
    final roundRef = _roomsRef.doc(roomId).collection('rounds').doc('round_${room.roundIndex}');
    batch.update(roundRef, {
      'reviewByOther': {
        'decision': decision,
        'decidedAt': Timestamp.fromDate(now),
      },
      'resolved': true,
      'result': {
        'isAccepted': isApproved,
        'points': points,
      },
    });

    // Update player score
    final currentPlayer = room.players[room.turnUid];
    if (currentPlayer != null) {
      final newScore = currentPlayer.score + points;
      batch.update(_roomsRef.doc(roomId), {
        'players.${room.turnUid}.score': newScore,
      });
    }

    // Generate new word and swap turn
    final newWord = await _generateRandomWord();
    final newTurnUid = room.opponentUid;
    final newRoundIndex = room.roundIndex + 1;

    // Update room for next round
    batch.update(_roomsRef.doc(roomId), {
      'phase': 'answering',
      'turnUid': newTurnUid,
      'roundIndex': newRoundIndex,
      'currentWord': newWord,
      'reviewDeadlineAt': null,
      'lastActionAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    // Create new round document
    final newRoundRef = _roomsRef.doc(roomId).collection('rounds').doc('round_$newRoundIndex');
    batch.set(newRoundRef, {
      'index': newRoundIndex,
      'word': newWord,
      'turnUid': newTurnUid,
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Start auto-approve timer
  void _startAutoApproveTimer(String roomId, int roundIndex, DateTime deadline) {
    final delay = deadline.difference(DateTime.now());
    if (delay.isNegative) return;

    Timer(delay + const Duration(milliseconds: 500), () async {
      // Check if still needs auto-approve
      final roomDoc = await _roomsRef.doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = GameRoomModel.fromFirestore(roomDoc);
      if (room.phase != GamePhase.reviewing) return;
      if (room.roundIndex != roundIndex) return;

      // Check round hasn't been resolved
      final roundDoc = await _roomsRef
          .doc(roomId)
          .collection('rounds')
          .doc('round_$roundIndex')
          .get();

      if (!roundDoc.exists) return;
      final roundData = roundDoc.data();
      if (roundData?['resolved'] == true) return;

      // Auto-approve
      await _resolveRound(roomId, room, 'approved');
    });
  }

  /// Generate random word
  Future<String> _generateRandomWord() async {
    const words = [
      'AŞK', 'GEL', 'GİT', 'SEN', 'BEN', 'GECE', 'GÜNEŞ', 'YAĞMUR',
      'RÜYA', 'KALP', 'YALAN', 'SEVER', 'ÖZLEM', 'UNUTMA', 'HATIRA',
      'YALNIZ', 'MUTLU', 'ÜZGÜN', 'DANS', 'MÜZİK', 'ŞARKI', 'SES',
      'DENIZ', 'DAĞ', 'YOL', 'ZAMAN', 'HAYAT', 'ÖLÜM', 'UMUT', 'KORKU',
    ];
    return words[DateTime.now().millisecondsSinceEpoch % words.length];
  }

  /// Leave/abandon game
  Future<void> leaveGame(String roomId, String oderId) async {
    await _roomsRef.doc(roomId).update({
      'status': 'abandoned',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// End game (both players agree or time limit)
  Future<void> endGame(String roomId) async {
    await _roomsRef.doc(roomId).update({
      'status': 'finished',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get room by ID
  Future<GameRoomModel?> getRoom(String roomId) async {
    final doc = await _roomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return GameRoomModel.fromFirestore(doc);
  }

  /// Get all rounds for a room
  Future<List<FriendsWordRound>> getRounds(String roomId) async {
    final snapshot = await _roomsRef
        .doc(roomId)
        .collection('rounds')
        .orderBy('index')
        .get();

    return snapshot.docs
        .map((doc) => FriendsWordRound.fromFirestore(doc))
        .toList();
  }
}
