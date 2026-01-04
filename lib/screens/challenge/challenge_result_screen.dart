import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import 'challenge_mode_select_screen.dart';
import 'leaderboard_screen.dart';

class ChallengeResultScreen extends StatelessWidget {
  final ChallengeModel challenge;
  final ChallengeSingleMode mode;
  final List<ChallengeSongModel> solvedSongs;
  final int totalSongs;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int durationSeconds;
  final bool timedOut;

  const ChallengeResultScreen({
    super.key,
    required this.challenge,
    required this.mode,
    required this.solvedSongs,
    required this.totalSongs,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    required this.durationSeconds,
    this.timedOut = false,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _modeLabel {
    switch (mode) {
      case ChallengeSingleMode.timeRace:
        return 'Time Race';
      case ChallengeSingleMode.relax:
        return 'Relax';
      case ChallengeSingleMode.real:
        return 'Real Challenge';
    }
  }

  Color get _modeColor {
    switch (mode) {
      case ChallengeSingleMode.timeRace:
        return const Color(0xFFFF6B6B);
      case ChallengeSingleMode.relax:
        return const Color(0xFF4ECDC4);
      case ChallengeSingleMode.real:
        return const Color(0xFFFFB958);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = solvedSongs.length == totalSongs && !timedOut;
    final percentage = totalSongs > 0 ? (solvedSongs.length / totalSongs * 100).toInt() : 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8E0FF), Color(0xFFF5F3FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Mode badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _modeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _modeLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _modeColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Result icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                        : timedOut
                            ? Colors.red.withOpacity(0.15)
                            : const Color(0xFFFFB958).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted 
                        ? Icons.emoji_events 
                        : timedOut 
                            ? Icons.timer_off 
                            : Icons.flag,
                    size: 50,
                    color: isCompleted 
                        ? const Color(0xFF4CAF50) 
                        : timedOut 
                            ? Colors.red 
                            : const Color(0xFFFFB958),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  isCompleted 
                      ? '🎉 Tebrikler!' 
                      : timedOut 
                          ? '⏱ Süre Doldu!' 
                          : 'İyi Gidiyorsun!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF394272),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6C6FA4),
                  ),
                ),

                const SizedBox(height: 32),

                // Stats card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Progress circle
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: totalSongs > 0 ? solvedSongs.length / totalSongs : 0,
                                strokeWidth: 10,
                                backgroundColor: const Color(0xFFE0E0E0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted ? const Color(0xFF4CAF50) : _modeColor,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (mode == ChallengeSingleMode.real) ...[
                                  Text(
                                    '$score',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: score >= 0 ? const Color(0xFF394272) : Colors.red,
                                    ),
                                  ),
                                  const Text(
                                    'SKOR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6C6FA4),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF394272),
                                    ),
                                  ),
                                  Text(
                                    '${solvedSongs.length}/$totalSongs',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6C6FA4),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stats row
                      Row(
                        children: [
                          Expanded(child: _buildStat(Icons.check_circle, '$correctCount', 'Doğru', Colors.green)),
                          Expanded(child: _buildStat(Icons.cancel, '$wrongCount', 'Yanlış', Colors.red)),
                          Expanded(child: _buildStat(Icons.timer, _formatTime(durationSeconds), 'Süre', const Color(0xFF6C6FA4))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Solved songs list
                if (solvedSongs.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bulduğun Şarkılar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF394272),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...solvedSongs.take(10).map((song) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF394272),
                                      ),
                                    ),
                                    Text(
                                      song.artist,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6C6FA4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (solvedSongs.length > 10)
                          Center(
                            child: Text(
                              '+ ${solvedSongs.length - 10} şarkı daha',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6C6FA4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Leaderboard button (only for Real mode)
                if (mode == ChallengeSingleMode.real)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeaderboardScreen(challenge: challenge),
                            ),
                          );
                        },
                        icon: const Icon(Icons.emoji_events, color: Color(0xFFFFB958)),
                        label: const Text(
                          'Liderlik Tablosu',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFFB958)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFB958)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF394272),
                            side: const BorderSide(color: Color(0xFF394272)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Ana Menü', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChallengeModeSelectScreen(challenge: challenge),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _modeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Tekrar Oyna',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C6FA4),
          ),
        ),
      ],
    );
  }
}
