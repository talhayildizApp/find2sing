import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import 'challenge_game_screen.dart';

/// Challenge başlamadan önce mod seçim ekranı
class ChallengeModeSelectScreen extends StatelessWidget {
  final ChallengeModel challenge;

  const ChallengeModeSelectScreen({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8E0FF), Color(0xFFF5F3FF)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF394272)),
                      ),
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF394272),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Challenge info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${challenge.totalSongs} Şarkı',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF394272),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.subtitle ?? challenge.typeLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6C6FA4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Mode title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Oyun Modu Seç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF394272),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mode cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _ModeCard(
                        title: 'Time Race',
                        subtitle: '5 dakikada tüm şarkıları bul',
                        description: 'Yanlış cevap = 3 saniye freeze',
                        icon: Icons.timer,
                        color: const Color(0xFFFF6B6B),
                        onTap: () => _startGame(context, ChallengeSingleMode.timeRace),
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: 'Relax',
                        subtitle: 'Her soru için 30 saniye',
                        description: 'Rahat tempoda oyna, en hızlı süreyi yakala',
                        icon: Icons.spa,
                        color: const Color(0xFF4ECDC4),
                        onTap: () => _startGame(context, ChallengeSingleMode.relax),
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        title: 'Real Challenge',
                        subtitle: 'Doğru +1, Yanlış -3',
                        description: 'En yüksek skoru yap, liderlik tablosuna gir!',
                        icon: Icons.emoji_events,
                        color: const Color(0xFFFFB958),
                        isLeaderboard: true,
                        onTap: () => _startGame(context, ChallengeSingleMode.real),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context, ChallengeSingleMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeGameScreen(
          challenge: challenge,
          singleMode: mode,
          playMode: ChallengePlayMode.solo,
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLeaderboard;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.isLeaderboard = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (isLeaderboard) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LEADERBOARD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF394272),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF394272),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C6FA4),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
