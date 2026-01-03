import 'package:cloud_firestore/cloud_firestore.dart';
import 'match_intent_model.dart';

enum RoomStatus {
  lobby,
  inProgress,
  finished,
  abandoned,
}

enum GamePhase {
  answering,
  reviewing,
  choosing,
}

/// Player info in a game room
class RoomPlayer {
  final String oderId;
  final String playerId;
  final String name;
  final int score;
  final int solvedCount;

  RoomPlayer({
    required this.oderId,
    required this.playerId,
    required this.name,
    this.score = 0,
    this.solvedCount = 0,
  });

  factory RoomPlayer.fromMap(String oderId, Map<String, dynamic> data) {
    return RoomPlayer(
      oderId: oderId,
      playerId: data['playerId'] ?? '',
      name: data['name'] ?? '',
      score: data['score'] ?? 0,
      solvedCount: data['solvedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'name': name,
      'score': score,
      'solvedCount': solvedCount,
    };
  }

  RoomPlayer copyWith({int? score, int? solvedCount}) {
    return RoomPlayer(
      oderId: oderId,
      playerId: playerId,
      name: name,
      score: score ?? this.score,
      solvedCount: solvedCount ?? this.solvedCount,
    );
  }
}

/// Comeback bonus for trailing player
class ComebackBonus {
  final String activeForUid;
  final int multiplier;
  final DateTime expiresAt;

  ComebackBonus({
    required this.activeForUid,
    required this.multiplier,
    required this.expiresAt,
  });

  factory ComebackBonus.fromMap(Map<String, dynamic> data) {
    return ComebackBonus(
      activeForUid: data['activeForUid'] ?? '',
      multiplier: data['multiplier'] ?? 2,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activeForUid': activeForUid,
      'multiplier': multiplier,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  bool get isActive => DateTime.now().isBefore(expiresAt);
}

/// Base Game Room Model
class GameRoomModel {
  final String id;
  final MatchMode mode;
  final RoomStatus status;
  final Map<String, RoomPlayer> players;
  final String turnUid;
  final int roundIndex;
  final GamePhase phase;
  final String currentWord;
  final DateTime? reviewDeadlineAt;
  final DateTime lastActionAt;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime updatedAt;

  // Challenge online specific
  final String? challengeId;
  final ModeVariant? modeVariant;
  final DateTime? endsAt;
  final ComebackBonus? comeback;
  final Map<String, List<String>>? missedWordByUid;

  GameRoomModel({
    required this.id,
    required this.mode,
    required this.status,
    required this.players,
    required this.turnUid,
    required this.roundIndex,
    required this.phase,
    required this.currentWord,
    this.reviewDeadlineAt,
    required this.lastActionAt,
    required this.createdAt,
    this.startedAt,
    required this.updatedAt,
    this.challengeId,
    this.modeVariant,
    this.endsAt,
    this.comeback,
    this.missedWordByUid,
  });

  factory GameRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse players map
    final playersData = data['players'] as Map<String, dynamic>? ?? {};
    final players = <String, RoomPlayer>{};
    playersData.forEach((uid, playerData) {
      players[uid] = RoomPlayer.fromMap(uid, playerData as Map<String, dynamic>);
    });

    // Parse missedWordByUid
    Map<String, List<String>>? missedWords;
    if (data['missedWordByUid'] != null) {
      missedWords = {};
      (data['missedWordByUid'] as Map<String, dynamic>).forEach((uid, words) {
        missedWords![uid] = List<String>.from(words ?? []);
      });
    }

    return GameRoomModel(
      id: doc.id,
      mode: MatchMode.values.firstWhere(
        (e) => e.name == data['mode'],
        orElse: () => MatchMode.friendsWord,
      ),
      status: RoomStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RoomStatus.lobby,
      ),
      players: players,
      turnUid: data['turnUid'] ?? '',
      roundIndex: data['roundIndex'] ?? 0,
      phase: GamePhase.values.firstWhere(
        (e) => e.name == data['phase'],
        orElse: () => GamePhase.answering,
      ),
      currentWord: data['currentWord'] ?? '',
      reviewDeadlineAt: (data['reviewDeadlineAt'] as Timestamp?)?.toDate(),
      lastActionAt: (data['lastActionAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      challengeId: data['challengeId'],
      modeVariant: data['modeVariant'] != null
          ? ModeVariant.values.firstWhere(
              (e) => e.name == data['modeVariant'],
              orElse: () => ModeVariant.timeRace,
            )
          : null,
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
      comeback: data['comeback'] != null
          ? ComebackBonus.fromMap(data['comeback'] as Map<String, dynamic>)
          : null,
      missedWordByUid: missedWords,
    );
  }

  Map<String, dynamic> toFirestore() {
    final playersMap = <String, dynamic>{};
    players.forEach((uid, player) {
      playersMap[uid] = player.toMap();
    });

    return {
      'mode': mode.name,
      'status': status.name,
      'players': playersMap,
      'turnUid': turnUid,
      'roundIndex': roundIndex,
      'phase': phase.name,
      'currentWord': currentWord,
      'reviewDeadlineAt': reviewDeadlineAt != null ? Timestamp.fromDate(reviewDeadlineAt!) : null,
      'lastActionAt': Timestamp.fromDate(lastActionAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'challengeId': challengeId,
      'modeVariant': modeVariant?.name,
      'endsAt': endsAt != null ? Timestamp.fromDate(endsAt!) : null,
      'comeback': comeback?.toMap(),
      'missedWordByUid': missedWordByUid,
    };
  }

  bool get isFriendsWord => mode == MatchMode.friendsWord;
  bool get isChallengeOnline => mode == MatchMode.challengeOnline;
  bool get isInProgress => status == RoomStatus.inProgress;
  bool get isFinished => status == RoomStatus.finished;

  String get opponentUid {
    return players.keys.firstWhere((uid) => uid != turnUid, orElse: () => '');
  }

  RoomPlayer? getPlayer(String uid) => players[uid];
  RoomPlayer? get currentTurnPlayer => players[turnUid];
  RoomPlayer? get otherPlayer => players[opponentUid];

  List<String> get playerUids => players.keys.toList();
}

/// Round data for Friends Word mode
class FriendsWordRound {
  final String id;
  final int index;
  final String word;
  final String turnUid;
  final String? answerSong;
  final String? answerArtist;
  final DateTime? submittedAt;
  final String? reviewDecision; // "approved" or "rejected"
  final DateTime? decidedAt;
  final bool resolved;
  final bool? isAccepted;
  final int? points;

  FriendsWordRound({
    required this.id,
    required this.index,
    required this.word,
    required this.turnUid,
    this.answerSong,
    this.answerArtist,
    this.submittedAt,
    this.reviewDecision,
    this.decidedAt,
    this.resolved = false,
    this.isAccepted,
    this.points,
  });

  factory FriendsWordRound.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final answer = data['answer'] as Map<String, dynamic>?;
    final review = data['reviewByOther'] as Map<String, dynamic>?;
    final result = data['result'] as Map<String, dynamic>?;

    return FriendsWordRound(
      id: doc.id,
      index: data['index'] ?? 0,
      word: data['word'] ?? '',
      turnUid: data['turnUid'] ?? '',
      answerSong: answer?['song'],
      answerArtist: answer?['artist'],
      submittedAt: (answer?['submittedAt'] as Timestamp?)?.toDate(),
      reviewDecision: review?['decision'],
      decidedAt: (review?['decidedAt'] as Timestamp?)?.toDate(),
      resolved: data['resolved'] ?? false,
      isAccepted: result?['isAccepted'],
      points: result?['points'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'index': index,
      'word': word,
      'turnUid': turnUid,
      'answer': answerSong != null
          ? {
              'song': answerSong,
              'artist': answerArtist,
              'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
            }
          : null,
      'reviewByOther': {
        'decision': reviewDecision,
        'decidedAt': decidedAt != null ? Timestamp.fromDate(decidedAt!) : null,
      },
      'resolved': resolved,
      'result': resolved
          ? {
              'isAccepted': isAccepted,
              'points': points,
            }
          : null,
    };
  }

  bool get hasAnswer => answerSong != null && answerArtist != null;
  bool get hasReview => reviewDecision != null;
  bool get isApproved => reviewDecision == 'approved';
  bool get isRejected => reviewDecision == 'rejected';
}

/// Round data for Challenge Online mode
class ChallengeOnlineRound {
  final String id;
  final int index;
  final String word;
  final String turnUid;
  final String? selectedSongId;
  final bool? isCorrect;
  final int? points;
  final DateTime createdAt;

  ChallengeOnlineRound({
    required this.id,
    required this.index,
    required this.word,
    required this.turnUid,
    this.selectedSongId,
    this.isCorrect,
    this.points,
    required this.createdAt,
  });

  factory ChallengeOnlineRound.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeOnlineRound(
      id: doc.id,
      index: data['index'] ?? 0,
      word: data['word'] ?? '',
      turnUid: data['turnUid'] ?? '',
      selectedSongId: data['selectedSongId'],
      isCorrect: data['isCorrect'],
      points: data['points'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'index': index,
      'word': word,
      'turnUid': turnUid,
      'selectedSongId': selectedSongId,
      'isCorrect': isCorrect,
      'points': points,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
