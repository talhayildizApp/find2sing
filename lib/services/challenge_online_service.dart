import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room_model.dart';
import '../models/match_intent_model.dart';
import '../models/word_set_model.dart';

class ChallengeOnlineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _db.collection('gameRooms');

  CollectionReference<Map<String, dynamic>> get _wordIndexRef =>
      _db.collection('challengeWordIndex');

  /// Stream game room
  Stream<GameRoomModel?> streamRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameRoomModel.fromFirestore(doc);
    });
  }

  /// Stream rounds
  Stream<List<ChallengeOnlineRound>> streamRounds(String roomId) {
    return _roomsRef
        .doc(roomId)
        .collection('rounds')
        .orderBy('index', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeOnlineRound.fromFirestore(doc))
          .toList();
    });
  }

  /// Get challenge songs
  Future<List<ChallengeSongWithWords>> getChallengeSongs(String challengeId) async {
    final snapshot = await _db
        .collection('challenges')
        .doc(challengeId)
        .collection('songs')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ChallengeSongWithWords.fromFirestore(doc))
        .toList();
  }

  /// Submit selection (only turnUid can call)
  Future<SubmitResult> submitSelection({
    required String roomId,
    required String oderId,
    required String selectedSongId,
  }) async {
    final roomDoc = await _roomsRef.doc(roomId).get();
    if (!roomDoc.exists) {
      return SubmitResult(success: false, message: 'Oda bulunamadı');
    }

    final room = GameRoomModel.fromFirestore(roomDoc);

    // Verify it's this user's turn
    if (room.turnUid != oderId) {
      return SubmitResult(success: false, message: 'Sıra sizde değil');
    }

    // Check time limit for time race mode
    if (room.modeVariant == ModeVariant.timeRace && room.endsAt != null) {
      if (DateTime.now().isAfter(room.endsAt!)) {
        await _endGame(roomId, 'time_up');
        return SubmitResult(success: false, message: 'Süre doldu');
      }
    }

    // Validate selection
    final isCorrect = await _validateSelection(
      room.challengeId!,
      room.currentWord,
      selectedSongId,
    );

    // Calculate points
    int points = 0;
    bool bonusApplied = false;

    if (isCorrect) {
      points = 1;

      // Check for Real mode +2 bonus
      if (room.modeVariant == ModeVariant.real) {
        final opponentMissed = room.missedWordByUid?[room.opponentUid] ?? [];
        if (opponentMissed.contains(room.currentWord)) {
          points = 2;
          bonusApplied = true;
        }
      }

      // Check for comeback multiplier (Relax online)
      if (room.comeback != null &&
          room.comeback!.activeForUid == oderId &&
          room.comeback!.isActive) {
        points *= room.comeback!.multiplier;
        bonusApplied = true;
      }
    } else {
      // Wrong answer penalties by mode
      switch (room.modeVariant) {
        case ModeVariant.real:
          points = -3;
          break;
        case ModeVariant.timeRace:
        case ModeVariant.relax:
        default:
          points = 0; // No negative score, but freeze applies client-side
          break;
      }

      // Track missed word for Real mode
      if (room.modeVariant == ModeVariant.real) {
        await _roomsRef.doc(roomId).update({
          'missedWordByUid.$oderId': FieldValue.arrayUnion([room.currentWord]),
        });
      }
    }

    // Update score and prepare next round
    await _processRoundResult(
      roomId: roomId,
      room: room,
      oderId: oderId,
      selectedSongId: selectedSongId,
      isCorrect: isCorrect,
      points: points,
    );

    return SubmitResult(
      success: true,
      isCorrect: isCorrect,
      points: points,
      bonusApplied: bonusApplied,
    );
  }

  /// Validate if selected song contains the word
  Future<bool> _validateSelection(
    String challengeId,
    String word,
    String songId,
  ) async {
    final indexDoc = await _wordIndexRef.doc('${challengeId}_$word').get();
    if (!indexDoc.exists) return false;

    final songIds = List<String>.from(indexDoc.data()?['songIds'] ?? []);
    return songIds.contains(songId);
  }

  /// Process round result
  Future<void> _processRoundResult({
    required String roomId,
    required GameRoomModel room,
    required String oderId,
    required String selectedSongId,
    required bool isCorrect,
    required int points,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();

    // Save round
    final roundRef = _roomsRef.doc(roomId).collection('rounds').doc('round_${room.roundIndex}');
    batch.set(roundRef, {
      'index': room.roundIndex,
      'word': room.currentWord,
      'turnUid': oderId,
      'selectedSongId': selectedSongId,
      'isCorrect': isCorrect,
      'points': points,
      'createdAt': Timestamp.fromDate(now),
    });

    // Update player score and solved count
    final currentPlayer = room.players[oderId];
    if (currentPlayer != null) {
      final newScore = currentPlayer.score + points;
      final newSolvedCount = isCorrect
          ? currentPlayer.solvedCount + 1
          : currentPlayer.solvedCount;

      batch.update(_roomsRef.doc(roomId), {
        'players.$oderId.score': newScore,
        'players.$oderId.solvedCount': newSolvedCount,
      });
    }

    // Check for game end conditions
    final totalSongs = await _getTotalSongsCount(room.challengeId!);
    final player1 = room.players.values.first;
    final player2 = room.players.values.last;
    final totalSolved = player1.solvedCount + player2.solvedCount + (isCorrect ? 1 : 0);

    if (totalSolved >= totalSongs) {
      // All songs solved
      batch.update(_roomsRef.doc(roomId), {
        'status': 'finished',
        'updatedAt': Timestamp.fromDate(now),
      });
    } else {
      // Continue game - swap turn and get new word
      final newWord = await _getNextWord(room.challengeId!, _getSolvedSongIds(room, isCorrect ? selectedSongId : null));
      final newTurnUid = room.opponentUid;
      final newRoundIndex = room.roundIndex + 1;

      batch.update(_roomsRef.doc(roomId), {
        'turnUid': newTurnUid,
        'roundIndex': newRoundIndex,
        'currentWord': newWord,
        'lastActionAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Check and maybe apply comeback bonus (Relax online)
      if (room.modeVariant == ModeVariant.relax) {
        await _checkComebackBonus(roomId, room, points);
      }
    }

    await batch.commit();
  }

  /// Get total songs count for challenge
  Future<int> _getTotalSongsCount(String challengeId) async {
    final snapshot = await _db
        .collection('challenges')
        .doc(challengeId)
        .collection('songs')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get solved song IDs from room
  List<String> _getSolvedSongIds(GameRoomModel room, String? newSolvedId) {
    // This would need to track solved songs per room
    // For simplicity, we track in rounds
    final solved = <String>[];
    if (newSolvedId != null) solved.add(newSolvedId);
    return solved;
  }

  /// Get next word that has unsolved songs
  Future<String> _getNextWord(String challengeId, List<String> solvedSongIds) async {
    final wordIndexDocs = await _wordIndexRef
        .where('challengeId', isEqualTo: challengeId)
        .get();

    final eligibleWords = <String>[];

    for (final doc in wordIndexDocs.docs) {
      final wordIndex = ChallengeWordIndexModel.fromFirestore(doc);
      if (wordIndex.hasUnsolvedSongs(solvedSongIds)) {
        eligibleWords.add(wordIndex.word);
      }
    }

    if (eligibleWords.isEmpty) {
      return 'ŞARKI'; // Fallback
    }

    return eligibleWords[_random.nextInt(eligibleWords.length)];
  }

  /// Check and apply comeback bonus
  Future<void> _checkComebackBonus(String roomId, GameRoomModel room, int lastPoints) async {
    final players = room.players.values.toList();
    if (players.length != 2) return;

    final scoreDiff = (players[0].score - players[1].score).abs();
    if (scoreDiff < 5) return;

    // Determine trailing player
    final trailingUid = players[0].score < players[1].score
        ? players[0].oderId
        : players[1].oderId;

    // 20% chance to grant comeback
    if (_random.nextDouble() > 0.2) return;

    final multiplier = scoreDiff >= 10 ? 3 : 2;
    final expiresAt = DateTime.now().add(const Duration(seconds: 30));

    await _roomsRef.doc(roomId).update({
      'comeback': {
        'activeForUid': trailingUid,
        'multiplier': multiplier,
        'expiresAt': Timestamp.fromDate(expiresAt),
      },
    });
  }

  /// End game
  Future<void> _endGame(String roomId, String reason) async {
    await _roomsRef.doc(roomId).update({
      'status': 'finished',
      'endReason': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Leave game
  Future<void> leaveGame(String roomId, String oderId) async {
    await _roomsRef.doc(roomId).update({
      'status': 'abandoned',
      'abandonedBy': oderId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get room
  Future<GameRoomModel?> getRoom(String roomId) async {
    final doc = await _roomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return GameRoomModel.fromFirestore(doc);
  }
}

class SubmitResult {
  final bool success;
  final bool? isCorrect;
  final int? points;
  final bool bonusApplied;
  final String? message;

  SubmitResult({
    required this.success,
    this.isCorrect,
    this.points,
    this.bonusApplied = false,
    this.message,
  });
}
