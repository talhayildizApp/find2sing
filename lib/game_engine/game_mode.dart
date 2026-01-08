// Game Mode definitions for Find2Sing
//
// Strict behavior rules:
// - Time Race: 5dk toplam süre, yanlış = 3s freeze
// - Relax: 30s/round, yanlış = 1s freeze (her 3 yanlışta +1s)
// - Real: 30s/round, doğru +1, yanlış -3 (leaderboard'a gider)

enum GameModeType {
  timeRace,
  relax,
  real,
}

class GameModeConfig {
  final GameModeType type;
  final String name;
  final String description;
  final int? totalTimeSeconds;
  final int? roundTimeSeconds;
  final int wrongFreezeDuration;
  final bool progressiveFreeze;
  final int correctPoints;
  final int wrongPoints;
  final bool contributesToLeaderboard;
  
  const GameModeConfig({
    required this.type,
    required this.name,
    required this.description,
    this.totalTimeSeconds,
    this.roundTimeSeconds,
    required this.wrongFreezeDuration,
    this.progressiveFreeze = false,
    required this.correctPoints,
    required this.wrongPoints,
    this.contributesToLeaderboard = false,
  });
  
  static const GameModeConfig timeRace = GameModeConfig(
    type: GameModeType.timeRace,
    name: 'Zaman Yarışı',
    description: '5 dakikada tüm şarkıları bul! Yanlışta 3 sn donarsın.',
    totalTimeSeconds: 5 * 60,
    wrongFreezeDuration: 3,
    correctPoints: 1,
    wrongPoints: 0,
  );
  
  static const GameModeConfig relax = GameModeConfig(
    type: GameModeType.relax,
    name: 'Rahat Mod',
    description: 'Her tur 30 sn. En hızlı bitirmeye çalış!',
    roundTimeSeconds: 30,
    wrongFreezeDuration: 1,
    progressiveFreeze: true,
    correctPoints: 1,
    wrongPoints: 0,
  );
  
  static const GameModeConfig real = GameModeConfig(
    type: GameModeType.real,
    name: 'Gerçek Challenge',
    description: 'Doğru +1, yanlış -3 puan. Sıralamaya girersin!',
    roundTimeSeconds: 30,
    wrongFreezeDuration: 1,
    correctPoints: 1,
    wrongPoints: -3,
    contributesToLeaderboard: true,
  );
  
  static GameModeConfig fromType(GameModeType type) {
    switch (type) {
      case GameModeType.timeRace:
        return timeRace;
      case GameModeType.relax:
        return relax;
      case GameModeType.real:
        return real;
    }
  }
}
