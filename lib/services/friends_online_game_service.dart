import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room_model.dart';

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
  /// Note: Auto-approve timer is NOT started here - it's started by the reviewer's client
  /// to prevent race conditions from multiple timers
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

    // NOTE: Auto-approve timer is started by the reviewer's client (in submitReview flow)
    // This prevents race conditions from multiple clients starting timers

    return true;
  }

  /// Submit review (approve/reject)
  /// All validation and resolution happens inside a single transaction
  Future<bool> submitReview({
    required String roomId,
    required String reviewerUid,
    required bool approved,
  }) async {
    final decision = approved ? 'approved' : 'rejected';
    final isApproved = approved;
    final points = isApproved ? 1 : 0;

    // Everything in a single transaction to prevent race conditions
    return await _db.runTransaction((transaction) async {
      // Get fresh room data
      final roomRef = _roomsRef.doc(roomId);
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) return false;
      final freshRoom = GameRoomModel.fromFirestore(roomDoc);

      // Verify reviewer is not the turn player
      if (freshRoom.turnUid == reviewerUid) return false;

      // Check if room is still in reviewing phase
      if (freshRoom.phase != GamePhase.reviewing) {
        // Phase already changed (round was resolved), skip
        return false;
      }

      final expectedRoundIndex = freshRoom.roundIndex;

      // Check round document
      final roundDocId = 'round_$expectedRoundIndex';
      final roundRef = _roomsRef.doc(roomId).collection('rounds').doc(roundDocId);
      final roundDoc = await transaction.get(roundRef);

      if (!roundDoc.exists) return false;
      final roundData = roundDoc.data();

      // CRITICAL: If already resolved, exit immediately
      if (roundData?['resolved'] == true) {
        return false;
      }

      // CRITICAL: Check if reviewByOther already exists (prevents double scoring)
      if (roundData?['reviewByOther'] != null) {
        return false;
      }

      final now = DateTime.now();

      // Update round with review result - mark resolved FIRST
      transaction.update(roundRef, {
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

      // Calculate new score for current player
      final currentPlayer = freshRoom.players[freshRoom.turnUid];
      int newScore = currentPlayer?.score ?? 0;
      if (isApproved) {
        newScore += points;
      }

      // Calculate updated total score for end check
      int updatedTotalScore = 0;
      for (final player in freshRoom.players.values) {
        if (player.oderId == freshRoom.turnUid) {
          updatedTotalScore += newScore; // Use calculated new score
        } else {
          updatedTotalScore += player.score;
        }
      }

      // Check if game should end
      final shouldEndGame = _checkGameEnd(freshRoom, updatedTotalScore);

      if (shouldEndGame) {
        // End the game with score update
        final Map<String, dynamic> endUpdate = {
          'status': 'finished',
          'phase': 'answering',
          'reviewDeadlineAt': null,
          'lastActionAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        };
        if (isApproved) {
          endUpdate['players.${freshRoom.turnUid}.score'] = newScore;
        }
        transaction.update(roomRef, endUpdate);
        return true;
      }

      // Generate new word and swap turn
      final newWord = _generateRandomWordSync();
      final newTurnUid = freshRoom.opponentUid;
      final newRoundIndex = freshRoom.roundIndex + 1;

      // Update room for next round (including score if approved)
      final Map<String, dynamic> roomUpdate = {
        'phase': 'answering',
        'turnUid': newTurnUid,
        'roundIndex': newRoundIndex,
        'currentWord': newWord,
        'reviewDeadlineAt': null,
        'lastActionAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      if (isApproved) {
        roomUpdate['players.${freshRoom.turnUid}.score'] = newScore;
      }
      transaction.update(roomRef, roomUpdate);

      // Create new round document
      final newRoundRef = _roomsRef.doc(roomId).collection('rounds').doc('round_$newRoundIndex');
      transaction.set(newRoundRef, {
        'index': newRoundIndex,
        'word': newWord,
        'turnUid': newTurnUid,
        'createdAt': Timestamp.fromDate(now),
      });

      return true;
    });
  }

  /// Check if game should end based on end condition
  bool _checkGameEnd(GameRoomModel room, int updatedTotalScore) {
    // Check time-based end condition
    if (room.endCondition == 'time' && room.endsAt != null) {
      if (DateTime.now().isAfter(room.endsAt!)) {
        return true;
      }
    }

    // Check round/song count based end condition
    if (room.endCondition == 'songCount' && room.targetRounds != null) {
      if (updatedTotalScore >= room.targetRounds!) {
        return true;
      }
    }

    // Default: check if total rounds reached (fallback for rooms without explicit end condition)
    // Default to 10 rounds if no end condition specified
    if (room.endCondition == null) {
      final totalRounds = room.roundIndex + 1;
      if (totalRounds >= 10) {
        return true;
      }
    }

    return false;
  }

  /// Skip turn when word timer expires (no answer submitted)
  /// Only the current turn player's client should call this
  Future<bool> skipTurn({
    required String roomId,
    required String oderId,
  }) async {
    // Use transaction to prevent race conditions
    return await _db.runTransaction((transaction) async {
      final roomRef = _roomsRef.doc(roomId);
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) return false;

      final room = GameRoomModel.fromFirestore(roomDoc);

      // Verify it's this user's turn
      if (room.turnUid != oderId) return false;

      // Verify phase is answering (not reviewing)
      if (room.phase != GamePhase.answering) return false;

      // Verify game is still active
      if (room.isFinished || room.status == RoomStatus.abandoned) return false;

      final now = DateTime.now();
      final expectedRoundIndex = room.roundIndex;

      // Check round document
      final roundDocId = 'round_$expectedRoundIndex';
      final roundRef = _roomsRef.doc(roomId).collection('rounds').doc(roundDocId);
      final roundDoc = await transaction.get(roundRef);

      if (!roundDoc.exists) return false;
      final roundData = roundDoc.data();

      // If round already has an answer or is resolved, skip
      if (roundData?['answer'] != null || roundData?['resolved'] == true) {
        return false;
      }

      // Mark current round as skipped (no points)
      transaction.update(roundRef, {
        'skipped': true,
        'resolved': true,
        'result': {
          'isAccepted': false,
          'points': 0,
        },
      });

      // Generate new word and swap turn
      final newWord = _generateRandomWordSync();
      final newTurnUid = room.opponentUid;
      final newRoundIndex = room.roundIndex + 1;

      // Update room for next round
      transaction.update(roomRef, {
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
      transaction.set(newRoundRef, {
        'index': newRoundIndex,
        'word': newWord,
        'turnUid': newTurnUid,
        'createdAt': Timestamp.fromDate(now),
      });

      return true;
    });
  }

  /// Generate random word (sync version for use in transactions)
  String _generateRandomWordSync() {
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
