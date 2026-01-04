import 'package:cloud_firestore/cloud_firestore.dart';

/// Word set for a song (eski yapı - uyumluluk için tutuyoruz)
class WordSetModel {
  final String id;
  final List<String> words;
  final DateTime createdAt;

  WordSetModel({
    required this.id,
    required this.words,
    required this.createdAt,
  });

  factory WordSetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordSetModel(
      id: doc.id,
      words: List<String>.from(data['words'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'words': words,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Word index mapping word to songIds for a challenge
/// Collection: challengeWordIndex/{challengeId}_{word}
class ChallengeWordIndexModel {
  final String id; // {challengeId}_{word}
  final String challengeId;
  final String word;
  final List<String> songIds;

  ChallengeWordIndexModel({
    required this.id,
    required this.challengeId,
    required this.word,
    required this.songIds,
  });

  factory ChallengeWordIndexModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeWordIndexModel(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      word: data['word'] ?? '',
      songIds: List<String>.from(data['songIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'word': word,
      'songIds': songIds,
    };
  }

  /// Check if word has unsolved songs
  bool hasUnsolvedSongs(List<String> solvedSongIds) {
    return songIds.any((id) => !solvedSongIds.contains(id));
  }

  /// Get unsolved song IDs
  List<String> getUnsolvedSongIds(List<String> solvedSongIds) {
    return songIds.where((id) => !solvedSongIds.contains(id)).toList();
  }
}

/// Challenge song with words (for online mode)
class ChallengeSongWithWords {
  final String id;
  final String artist;
  final String title;
  final String? wordSetId;
  final bool active;

  ChallengeSongWithWords({
    required this.id,
    required this.artist,
    required this.title,
    this.wordSetId,
    this.active = true,
  });

  factory ChallengeSongWithWords.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeSongWithWords(
      id: doc.id,
      artist: data['artist'] ?? '',
      title: data['title'] ?? '',
      wordSetId: data['wordSetId'],
      active: data['active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artist': artist,
      'title': title,
      'wordSetId': wordSetId,
      'active': active,
    };
  }
}

/// User's single-player challenge progress
class UserChallengeProgressModel {
  final String id; // {uid}_{challengeId}
  final String uid;
  final String challengeId;
  final List<String> solvedSongIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserChallengeProgressModel({
    required this.id,
    required this.uid,
    required this.challengeId,
    required this.solvedSongIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserChallengeProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserChallengeProgressModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      challengeId: data['challengeId'] ?? '',
      solvedSongIds: List<String>.from(data['solvedSongIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'challengeId': challengeId,
      'solvedSongIds': solvedSongIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  int get solvedCount => solvedSongIds.length;
}

/// Challenge run record
class ChallengeRunModel {
  final String id;
  final String uid;
  final String challengeId;
  final String mode; // "time_race", "relax", "real"
  final int score;
  final int correct;
  final int wrong;
  final int durationMs;
  final bool finished;
  final DateTime createdAt;

  ChallengeRunModel({
    required this.id,
    required this.uid,
    required this.challengeId,
    required this.mode,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.durationMs,
    required this.finished,
    required this.createdAt,
  });

  factory ChallengeRunModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeRunModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      challengeId: data['challengeId'] ?? '',
      mode: data['mode'] ?? 'relax',
      score: data['score'] ?? 0,
      correct: data['correct'] ?? 0,
      wrong: data['wrong'] ?? 0,
      durationMs: data['durationMs'] ?? 0,
      finished: data['finished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'challengeId': challengeId,
      'mode': mode,
      'score': score,
      'correct': correct,
      'wrong': wrong,
      'durationMs': durationMs,
      'finished': finished,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Leaderboard entry for Real Challenge mode
class LeaderboardEntryModel {
  final String oderId;
  final String displayName;
  final int bestScore;
  final int bestDurationMs;
  final DateTime updatedAt;

  LeaderboardEntryModel({
    required this.oderId,
    required this.displayName,
    required this.bestScore,
    required this.bestDurationMs,
    required this.updatedAt,
  });

  factory LeaderboardEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntryModel(
      oderId: doc.id,
      displayName: data['displayName'] ?? '',
      bestScore: data['bestScore'] ?? 0,
      bestDurationMs: data['bestDurationMs'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'bestScore': bestScore,
      'bestDurationMs': bestDurationMs,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Challenge Song with wordSetId
class ChallengeSongWithWords {
  final String id;
  final String artist;
  final String title;
  final String wordSetId;
  final bool active;

  ChallengeSongWithWords({
    required this.id,
    required this.artist,
    required this.title,
    required this.wordSetId,
    this.active = true,
  });

  factory ChallengeSongWithWords.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeSongWithWords(
      id: doc.id,
      artist: data['artist'] ?? '',
      title: data['title'] ?? '',
      wordSetId: data['wordSetId'] ?? '',
      active: data['active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artist': artist,
      'title': title,
      'wordSetId': wordSetId,
      'active': active,
    };
  }

  String get displayName => '$artist - $title';
}
