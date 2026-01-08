import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/game_room_model.dart';
import '../models/match_intent_model.dart';
import '../models/word_set_model.dart';
import '../models/challenge_model.dart';

class ChallengeOnlineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _db.collection('gameRooms');

  CollectionReference<Map<String, dynamic>> get _wordIndexRef =>
      _db.collection('challengeWordIndex');

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _db.collection('challenges');

  CollectionReference<Map<String, dynamic>> get _songsRef =>
      _db.collection('songs');

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

  /// Get challenge info
  Future<ChallengeModel?> getChallenge(String challengeId) async {
    final doc = await _challengesRef.doc(challengeId).get();
    if (!doc.exists) return null;
    return ChallengeModel.fromFirestore(doc);
  }

  /// Get challenge songs - Same as single player (from songs collection)
  Future<List<ChallengeSongModel>> getChallengeSongs(String challengeId) async {
    debugPrint('🎵 [Online] Getting challenge: $challengeId');

    final challenge = await getChallenge(challengeId);
    if (challenge == null) {
      debugPrint('🎵 [Online] Challenge not found!');
      return [];
    }

    debugPrint('🎵 [Online] Challenge has ${challenge.songIds.length} songIds');

    final songs = <ChallengeSongModel>[];
    for (final songId in challenge.songIds) {
      final doc = await _songsRef.doc(songId).get();
      if (doc.exists) {
        songs.add(ChallengeSongModel.fromFirestore(doc));
      }
    }

    debugPrint('🎵 [Online] Loaded ${songs.length} songs');
    return songs;
  }

  /// Submit selection - PARALLEL RACE MODE
  /// Both players can submit at the same time, first correct answer wins the round
  /// Uses Firestore transaction to prevent race conditions
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

    // Check if round is already won - no more submissions allowed
    if (room.roundWinner != null) {
      return SubmitResult(success: false, message: 'Bu tur bitti');
    }

    // Check time limit for time race mode
    if (room.modeVariant == ModeVariant.timeRace && room.endsAt != null) {
      if (DateTime.now().isAfter(room.endsAt!)) {
        await _endGame(roomId, 'time_up');
        return SubmitResult(success: false, message: 'Süre doldu');
      }
    }

    final now = DateTime.now();

    // Validate selection
    final isCorrect = await _validateSelection(
      room.challengeId!,
      room.currentWord,
      selectedSongId,
    );

    // Use transaction to handle race condition
    int points = 0;
    bool bonusApplied = false;
    bool wonRound = false;

    try {
      await _db.runTransaction((transaction) async {
        // Get fresh room data inside transaction
        final freshDoc = await transaction.get(_roomsRef.doc(roomId));
        if (!freshDoc.exists) return;
        final freshRoom = GameRoomModel.fromFirestore(freshDoc);

        // Double check - round already won?
        if (freshRoom.roundWinner != null) {
          return;
        }

        final opponentUid = freshRoom.getOpponentUid(oderId);
        final opponentSubmission = freshRoom.roundSubmissions[opponentUid];
        final opponentCorrect = opponentSubmission?['isCorrect'] == true;
        final opponentWrongCount = opponentSubmission?['wrongCount'] as int? ?? 0;

        // Get my current wrong count for this round
        final mySubmission = freshRoom.roundSubmissions[oderId];
        final myWrongCount = mySubmission?['wrongCount'] as int? ?? 0;

        // Record our submission
        // If wrong, increment wrongCount; if correct, keep current wrongCount
        final newWrongCount = isCorrect ? myWrongCount : myWrongCount + 1;

        transaction.update(_roomsRef.doc(roomId), {
          'roundSubmissions.$oderId': {
            'songId': selectedSongId,
            'isCorrect': isCorrect,
            'wrongCount': newWrongCount,
            'submittedAt': Timestamp.fromDate(now),
          },
        });

        if (isCorrect && !opponentCorrect) {
          // We won this round!
          wonRound = true;
          points = 1;

          // Check for Real mode streak steal bonus:
          // If opponent made 2+ wrong attempts AND I won on first try → +2 points
          if (freshRoom.modeVariant == ModeVariant.real) {
            final iWonOnFirstTry = myWrongCount == 0; // No previous wrong attempts
            if (opponentWrongCount >= 2 && iWonOnFirstTry) {
              points = 2;
              bonusApplied = true;
              debugPrint('🔥 STEAL BONUS! Opponent had $opponentWrongCount wrong, I won first try!');
            }
          }

          // Check for comeback multiplier (Relax online)
          if (freshRoom.comeback != null &&
              freshRoom.comeback!.activeForUid == oderId &&
              freshRoom.comeback!.isActive) {
            points *= freshRoom.comeback!.multiplier;
            bonusApplied = true;
          }

          // Mark round winner
          transaction.update(_roomsRef.doc(roomId), {
            'roundWinner': oderId,
          });
        } else if (!isCorrect) {
          // Wrong answer penalties by mode
          switch (freshRoom.modeVariant) {
            case ModeVariant.real:
              // Real mode: -3 points for wrong answer
              points = -3;
              final currentPlayer = freshRoom.players[oderId];
              if (currentPlayer != null) {
                transaction.update(_roomsRef.doc(roomId), {
                  'players.$oderId.score': currentPlayer.score + points,
                });
              }
              break;
            case ModeVariant.timeRace:
            case ModeVariant.relax:
            default:
              points = 0;
              break;
          }
          // wrongCount is already tracked in roundSubmissions for steal bonus
        }
      });
    } catch (e) {
      debugPrint('❌ Transaction error: $e');
      return SubmitResult(success: false, message: 'Bir hata oluştu');
    }

    // Handle post-transaction actions (outside transaction)
    if (wonRound) {
      // Update score and save round
      await _processRoundWinAfterTransaction(
        roomId: roomId,
        challengeId: room.challengeId!,
        winnerUid: oderId,
        selectedSongId: selectedSongId,
        points: points,
        currentWord: room.currentWord,
        roundIndex: room.roundIndex,
        modeVariant: room.modeVariant,
      );
    }
    // No "bothWrong" handling - players can keep trying until someone gets it right

    return SubmitResult(
      success: true,
      isCorrect: isCorrect,
      points: points,
      bonusApplied: bonusApplied,
      wonRound: wonRound,
    );
  }

  /// Process round win after transaction completed
  Future<void> _processRoundWinAfterTransaction({
    required String roomId,
    required String challengeId,
    required String winnerUid,
    required String selectedSongId,
    required int points,
    required String currentWord,
    required int roundIndex,
    required ModeVariant? modeVariant,
  }) async {
    final now = DateTime.now();

    // Get fresh room to get current player scores
    final roomDoc = await _roomsRef.doc(roomId).get();
    if (!roomDoc.exists) return;
    final room = GameRoomModel.fromFirestore(roomDoc);
    final winnerPlayer = room.players[winnerUid];

    // Update score and solved count
    if (winnerPlayer != null) {
      await _roomsRef.doc(roomId).update({
        'players.$winnerUid.score': winnerPlayer.score + points,
        'players.$winnerUid.solvedCount': winnerPlayer.solvedCount + 1,
      });
    }

    // Save round record
    await _roomsRef.doc(roomId).collection('rounds').doc('round_$roundIndex').set({
      'index': roundIndex,
      'word': currentWord,
      'winnerUid': winnerUid,
      'selectedSongId': selectedSongId,
      'points': points,
      'createdAt': Timestamp.fromDate(now),
    });

    // Check comeback bonus (Relax mode)
    if (modeVariant == ModeVariant.relax) {
      await _checkComebackBonus(roomId, room, points);
    }

    // Start next round after celebration delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      _startNextRoundOrEnd(roomId, challengeId, selectedSongId);
    });
  }

  /// Start next round or end game
  Future<void> _startNextRoundOrEnd(String roomId, String challengeId, String lastSongId) async {
    try {
      final now = DateTime.now();

      // Get fresh room data to have accurate solved counts
      final roomDoc = await _roomsRef.doc(roomId).get();
      if (!roomDoc.exists) return;
      final room = GameRoomModel.fromFirestore(roomDoc);

      // Check for game end conditions
      final totalSongs = await _getTotalSongsCount(challengeId);
      final player1 = room.players.values.first;
      final player2 = room.players.values.last;
      final totalSolved = player1.solvedCount + player2.solvedCount;

      debugPrint('🎮 Round check: totalSolved=$totalSolved, totalSongs=$totalSongs');

      if (totalSolved >= totalSongs) {
        // All songs solved
        await _roomsRef.doc(roomId).update({
          'status': 'finished',
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        // Continue game - get new word and reset round state
        final existingSolved = await _getSolvedSongIds(roomId);
        final allSolvedIds = [...existingSolved, lastSongId];

        final newWord = await _getNextWord(challengeId, allSolvedIds);
        final newRoundIndex = room.roundIndex + 1;

        debugPrint('🎮 Starting new round: $newRoundIndex with word: $newWord');

        await _roomsRef.doc(roomId).update({
          'roundIndex': newRoundIndex,
          'currentWord': newWord,
          'roundSubmissions': {}, // Clear submissions for new round
          'roundWinner': null, // Clear winner for new round
          'lastActionAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _startNextRoundOrEnd: $e');
    }
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

  /// Get correct song IDs for a word (for joker functionality)
  Future<List<String>> getCorrectSongIdsForWord(String challengeId, String word) async {
    final indexDoc = await _wordIndexRef.doc('${challengeId}_$word').get();
    if (!indexDoc.exists) return [];
    return List<String>.from(indexDoc.data()?['songIds'] ?? []);
  }

  /// Get total songs count for challenge
  Future<int> _getTotalSongsCount(String challengeId) async {
    final challenge = await getChallenge(challengeId);
    if (challenge == null) return 0;
    return challenge.songIds.length;
  }

  /// Get solved song IDs from room rounds
  Future<List<String>> _getSolvedSongIds(String roomId) async {
    // Get all rounds - each round represents a correctly solved song
    // (rounds are only created when someone wins with correct answer)
    final roundsSnapshot = await _roomsRef
        .doc(roomId)
        .collection('rounds')
        .get();

    debugPrint('🔍 _getSolvedSongIds: Found ${roundsSnapshot.docs.length} rounds');
    for (final doc in roundsSnapshot.docs) {
      debugPrint('🔍 Round ${doc.id}: ${doc.data()}');
    }

    final solvedIds = roundsSnapshot.docs
        .map((doc) => doc.data()['selectedSongId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    debugPrint('🔍 Solved song IDs from rounds: $solvedIds');
    return solvedIds;
  }

  /// Get next word that has unsolved songs
  Future<String> _getNextWord(String challengeId, List<String> solvedSongIds) async {
    debugPrint('🔍 _getNextWord called with solvedSongIds: $solvedSongIds');

    final wordIndexDocs = await _wordIndexRef
        .where('challengeId', isEqualTo: challengeId)
        .get();

    debugPrint('🔍 Found ${wordIndexDocs.docs.length} word index documents');

    final eligibleWords = <String>[];

    for (final doc in wordIndexDocs.docs) {
      final wordIndex = ChallengeWordIndexModel.fromFirestore(doc);
      final hasUnsolved = wordIndex.hasUnsolvedSongs(solvedSongIds);
      debugPrint('🔍 Word "${wordIndex.word}" songIds: ${wordIndex.songIds}, hasUnsolved: $hasUnsolved');
      if (hasUnsolved) {
        eligibleWords.add(wordIndex.word);
      }
    }

    debugPrint('🔍 Eligible words: $eligibleWords');

    if (eligibleWords.isEmpty) {
      return 'ŞARKI'; // Fallback
    }

    final selectedWord = eligibleWords[_random.nextInt(eligibleWords.length)];
    debugPrint('🔍 Selected word: $selectedWord');
    return selectedWord;
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

  /// End game (internal)
  Future<void> _endGame(String roomId, String reason) async {
    await _roomsRef.doc(roomId).update({
      'status': 'finished',
      'endReason': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// End game due to time up (public - called from client when timer expires)
  Future<void> endGameTimeUp(String roomId) async {
    // Check if game is still in progress before ending
    final roomDoc = await _roomsRef.doc(roomId).get();
    if (!roomDoc.exists) return;

    final room = GameRoomModel.fromFirestore(roomDoc);
    if (room.status != RoomStatus.inProgress) return;

    await _endGame(roomId, 'time_up');
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
  final bool wonRound;
  final String? message;

  SubmitResult({
    required this.success,
    this.isCorrect,
    this.points,
    this.bonusApplied = false,
    this.wonRound = false,
    this.message,
  });
}
