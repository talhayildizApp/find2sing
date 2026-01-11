// Challenge Engine - Core game logic for Find2Sing Challenge mode
//
// Handles:
// - Word selection from song pool
// - Answer validation
// - Score calculation
// - Game state management

import 'dart:math';
import '../models/challenge_model.dart';
import 'game_mode.dart';

/// Game state for a challenge session
class ChallengeGameState {
  final String challengeId;
  final GameModeConfig mode;
  final List<ChallengeSongModel> allSongs;
  final List<ChallengeSongModel> remainingSongs;
  final List<ChallengeSongModel> solvedSongs;
  final Set<String> solvedSongIds;
  
  final String currentWord;
  final List<ChallengeSongModel> validSongsForWord;
  
  final int score;
  final int correctCount;
  final int wrongCount;
  final int consecutiveWrong;
  final int currentFreezeTime;
  
  final int totalSeconds;
  final int roundSeconds;
  final int freezeSeconds;
  
  final bool isFinished;
  final bool isFrozen;
  final String? finishReason; // 'completed', 'time_up', 'abandoned'
  
  const ChallengeGameState({
    required this.challengeId,
    required this.mode,
    required this.allSongs,
    required this.remainingSongs,
    required this.solvedSongs,
    required this.solvedSongIds,
    required this.currentWord,
    required this.validSongsForWord,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.consecutiveWrong = 0,
    this.currentFreezeTime = 1,
    this.totalSeconds = 0,
    this.roundSeconds = 30,
    this.freezeSeconds = 0,
    this.isFinished = false,
    this.isFrozen = false,
    this.finishReason,
  });
  
  ChallengeGameState copyWith({
    List<ChallengeSongModel>? remainingSongs,
    List<ChallengeSongModel>? solvedSongs,
    Set<String>? solvedSongIds,
    String? currentWord,
    List<ChallengeSongModel>? validSongsForWord,
    int? score,
    int? correctCount,
    int? wrongCount,
    int? consecutiveWrong,
    int? currentFreezeTime,
    int? totalSeconds,
    int? roundSeconds,
    int? freezeSeconds,
    bool? isFinished,
    bool? isFrozen,
    String? finishReason,
  }) {
    return ChallengeGameState(
      challengeId: challengeId,
      mode: mode,
      allSongs: allSongs,
      remainingSongs: remainingSongs ?? this.remainingSongs,
      solvedSongs: solvedSongs ?? this.solvedSongs,
      solvedSongIds: solvedSongIds ?? this.solvedSongIds,
      currentWord: currentWord ?? this.currentWord,
      validSongsForWord: validSongsForWord ?? this.validSongsForWord,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
      currentFreezeTime: currentFreezeTime ?? this.currentFreezeTime,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      roundSeconds: roundSeconds ?? this.roundSeconds,
      freezeSeconds: freezeSeconds ?? this.freezeSeconds,
      isFinished: isFinished ?? this.isFinished,
      isFrozen: isFrozen ?? this.isFrozen,
      finishReason: finishReason ?? this.finishReason,
    );
  }
  
  /// Progress as a value between 0 and 1
  double get progress {
    if (allSongs.isEmpty) return 0;
    return solvedSongs.length / allSongs.length;
  }
  
  /// Remaining time for time race mode
  int get remainingTotalTime {
    if (mode.totalTimeSeconds == null) return 0;
    return (mode.totalTimeSeconds! - totalSeconds).clamp(0, mode.totalTimeSeconds!);
  }
  
  /// Check if time is up for time race
  bool get isTimeUp {
    if (mode.totalTimeSeconds == null) return false;
    return totalSeconds >= mode.totalTimeSeconds!;
  }
  
  /// Check if all songs are solved
  bool get isCompleted => remainingSongs.isEmpty;
}

/// Result of submitting an answer
class AnswerResult {
  final bool isCorrect;
  final int pointsEarned;
  final int freezeDuration;
  final String? message;
  final ChallengeSongModel? solvedSong;
  
  const AnswerResult({
    required this.isCorrect,
    required this.pointsEarned,
    this.freezeDuration = 0,
    this.message,
    this.solvedSong,
  });
}

/// Core challenge game engine
class ChallengeEngine {
  static final Random _random = Random();

  /// Türkçe lowercase dönüşümü - İ->i, I->ı özel durumları
  static String _turkishLowerCase(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }
  
  /// Initialize a new game state
  static ChallengeGameState initializeGame({
    required String challengeId,
    required GameModeConfig mode,
    required List<ChallengeSongModel> songs,
  }) {
    if (songs.isEmpty) {
      return ChallengeGameState(
        challengeId: challengeId,
        mode: mode,
        allSongs: [],
        remainingSongs: [],
        solvedSongs: [],
        solvedSongIds: {},
        currentWord: '',
        validSongsForWord: [],
        isFinished: true,
        finishReason: 'no_songs',
      );
    }
    
    final shuffledSongs = List<ChallengeSongModel>.from(songs)..shuffle();
    final (word, validSongs) = _selectNextWord(shuffledSongs);
    
    return ChallengeGameState(
      challengeId: challengeId,
      mode: mode,
      allSongs: songs,
      remainingSongs: shuffledSongs,
      solvedSongs: [],
      solvedSongIds: {},
      currentWord: word,
      validSongsForWord: validSongs,
      roundSeconds: mode.roundTimeSeconds ?? 30,
      currentFreezeTime: mode.type == GameModeType.relax ? 1 : mode.wrongFreezeDuration,
    );
  }
  
  /// Select next word from available songs
  static (String, List<ChallengeSongModel>) _selectNextWord(List<ChallengeSongModel> songs) {
    if (songs.isEmpty) return ('', []);

    // Collect all available keywords
    final availableWords = <String>{};
    for (final song in songs) {
      // Prefer topKeywords (ranked by frequency), fall back to all keywords
      final keywords = song.topKeywords.isNotEmpty ? song.topKeywords : song.keywords;
      availableWords.addAll(keywords);
    }

    if (availableWords.isEmpty) return ('', []);

    // Select random word
    final wordList = availableWords.toList()..shuffle(_random);
    final selectedWord = wordList.first;

    // Türkçe karakterler için normalize edilmiş karşılaştırma
    final normalizedSelectedWord = _turkishLowerCase(selectedWord);

    // Find songs containing this word
    final validSongs = songs.where((song) {
      final keywords = song.topKeywords.isNotEmpty ? song.topKeywords : song.keywords;
      return keywords.any((k) => _turkishLowerCase(k) == normalizedSelectedWord);
    }).toList();

    return (selectedWord, validSongs);
  }
  
  /// Process a tick (1 second) of game time
  static ChallengeGameState processTick(ChallengeGameState state) {
    if (state.isFinished) return state;
    
    var newState = state.copyWith(
      totalSeconds: state.totalSeconds + 1,
    );
    
    // Handle freeze countdown
    if (state.isFrozen && state.freezeSeconds > 0) {
      final newFreezeSeconds = state.freezeSeconds - 1;
      return newState.copyWith(
        freezeSeconds: newFreezeSeconds,
        isFrozen: newFreezeSeconds > 0,
      );
    }
    
    // Check time race total time limit
    if (state.mode.type == GameModeType.timeRace) {
      if (newState.isTimeUp) {
        return newState.copyWith(
          isFinished: true,
          finishReason: 'time_up',
        );
      }
    }
    
    // Handle per-round time limit (Relax and Real modes)
    if (state.mode.roundTimeSeconds != null && !state.isFrozen) {
      final newRoundSeconds = state.roundSeconds - 1;
      if (newRoundSeconds <= 0) {
        // Round timeout - treat as wrong answer
        return _processTimeout(newState);
      }
      newState = newState.copyWith(roundSeconds: newRoundSeconds);
    }
    
    return newState;
  }
  
  /// Process round timeout
  static ChallengeGameState _processTimeout(ChallengeGameState state) {
    var newState = state.copyWith(
      wrongCount: state.wrongCount + 1,
      consecutiveWrong: state.consecutiveWrong + 1,
    );
    
    // Apply score penalty for Real mode
    if (state.mode.type == GameModeType.real) {
      newState = newState.copyWith(
        score: state.score + state.mode.wrongPoints,
      );
    }
    
    // Apply freeze and get next word
    return _applyWrongAnswer(newState);
  }
  
  /// Submit an answer
  static (ChallengeGameState, AnswerResult) submitAnswer({
    required ChallengeGameState state,
    required String selectedSongId,
  }) {
    if (state.isFinished || state.isFrozen) {
      return (state, const AnswerResult(
        isCorrect: false,
        pointsEarned: 0,
        message: 'Oyun aktif değil',
      ));
    }
    
    // Check if selected song is valid for current word
    final isCorrect = state.validSongsForWord.any((s) => s.id == selectedSongId);
    
    if (isCorrect) {
      return _processCorrectAnswer(state, selectedSongId);
    } else {
      return _processWrongAnswer(state);
    }
  }
  
  /// Process correct answer
  static (ChallengeGameState, AnswerResult) _processCorrectAnswer(
    ChallengeGameState state,
    String selectedSongId,
  ) {
    final solvedSong = state.allSongs.firstWhere((s) => s.id == selectedSongId);
    
    // Update solved lists
    final newSolvedSongs = [...state.solvedSongs, solvedSong];
    final newSolvedIds = {...state.solvedSongIds, selectedSongId};
    final newRemaining = state.remainingSongs.where((s) => s.id != selectedSongId).toList();
    
    // Calculate score
    final points = state.mode.correctPoints;
    final newScore = state.score + points;
    
    // Check completion
    if (newRemaining.isEmpty) {
      return (
        state.copyWith(
          solvedSongs: newSolvedSongs,
          solvedSongIds: newSolvedIds,
          remainingSongs: [],
          score: newScore,
          correctCount: state.correctCount + 1,
          consecutiveWrong: 0,
          isFinished: true,
          finishReason: 'completed',
        ),
        AnswerResult(
          isCorrect: true,
          pointsEarned: points,
          message: 'Tamamlandı!',
          solvedSong: solvedSong,
        ),
      );
    }
    
    // Get next word
    final (nextWord, validSongs) = _selectNextWord(newRemaining);
    
    return (
      state.copyWith(
        solvedSongs: newSolvedSongs,
        solvedSongIds: newSolvedIds,
        remainingSongs: newRemaining,
        currentWord: nextWord,
        validSongsForWord: validSongs,
        score: newScore,
        correctCount: state.correctCount + 1,
        consecutiveWrong: 0,
        roundSeconds: state.mode.roundTimeSeconds ?? 30,
      ),
      AnswerResult(
        isCorrect: true,
        pointsEarned: points,
        message: 'Doğru! 🎉',
        solvedSong: solvedSong,
      ),
    );
  }
  
  /// Process wrong answer
  static (ChallengeGameState, AnswerResult) _processWrongAnswer(ChallengeGameState state) {
    final newWrongCount = state.wrongCount + 1;
    final newConsecutiveWrong = state.consecutiveWrong + 1;
    
    // Calculate score penalty
    final points = state.mode.wrongPoints;
    final newScore = state.score + points;
    
    // Calculate freeze duration
    int freezeDuration = state.mode.wrongFreezeDuration;
    int newFreezeTime = state.currentFreezeTime;
    
    if (state.mode.progressiveFreeze) {
      // Relax mode: increase freeze after every 3 wrong answers
      if (newConsecutiveWrong >= 3) {
        newFreezeTime = state.currentFreezeTime + 1;
      }
      freezeDuration = newFreezeTime;
    }
    
    var newState = state.copyWith(
      score: newScore,
      wrongCount: newWrongCount,
      consecutiveWrong: state.mode.progressiveFreeze && newConsecutiveWrong >= 3 ? 0 : newConsecutiveWrong,
      currentFreezeTime: newFreezeTime,
    );
    
    // Apply freeze if applicable
    if (freezeDuration > 0) {
      newState = newState.copyWith(
        isFrozen: true,
        freezeSeconds: freezeDuration,
      );
    }
    
    return (
      newState,
      AnswerResult(
        isCorrect: false,
        pointsEarned: points,
        freezeDuration: freezeDuration,
        message: freezeDuration > 0 ? '🎤 Mikrofon Bozuldu!' : 'Yanlış! ❌',
      ),
    );
  }
  
  /// Apply freeze after wrong answer and potentially get new word
  static ChallengeGameState _applyWrongAnswer(ChallengeGameState state) {
    int freezeDuration = state.mode.wrongFreezeDuration;
    int newFreezeTime = state.currentFreezeTime;
    
    if (state.mode.progressiveFreeze) {
      if (state.consecutiveWrong >= 3) {
        newFreezeTime = state.currentFreezeTime + 1;
      }
      freezeDuration = newFreezeTime;
    }
    
    // Get next word
    final (nextWord, validSongs) = _selectNextWord(state.remainingSongs);
    
    return state.copyWith(
      currentWord: nextWord,
      validSongsForWord: validSongs,
      currentFreezeTime: newFreezeTime,
      isFrozen: freezeDuration > 0,
      freezeSeconds: freezeDuration,
      roundSeconds: state.mode.roundTimeSeconds ?? 30,
      consecutiveWrong: state.mode.progressiveFreeze && state.consecutiveWrong >= 3 ? 0 : state.consecutiveWrong,
    );
  }
  
  /// Skip current word (if allowed)
  static ChallengeGameState skipWord(ChallengeGameState state) {
    if (state.isFinished || state.isFrozen) return state;
    if (state.remainingSongs.isEmpty) return state;
    
    final (nextWord, validSongs) = _selectNextWord(state.remainingSongs);
    
    return state.copyWith(
      currentWord: nextWord,
      validSongsForWord: validSongs,
      roundSeconds: state.mode.roundTimeSeconds ?? 30,
    );
  }
  
  /// Abandon game
  static ChallengeGameState abandonGame(ChallengeGameState state) {
    return state.copyWith(
      isFinished: true,
      finishReason: 'abandoned',
    );
  }
}
