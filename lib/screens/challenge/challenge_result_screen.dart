import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';

class ChallengeResultScreen extends StatelessWidget {
  final ChallengeModel challenge;
  final List<ChallengeSongModel> foundSongs;
  final int totalSongs;
  final int totalElapsedSeconds;

  const ChallengeResultScreen({
    super.key,
    required this.challenge,
    required this.foundSongs,
    required this.totalSongs,
    required this.totalElapsedSeconds,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = foundSongs.length == totalSongs;
    final percentage = totalSongs > 0 ? (foundSongs.length / totalSongs * 100).toInt() : 0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg_music_clouds.png', fit: BoxFit.cover),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Başarı ikonu
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                          : const Color(0xFFFFB958).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.emoji_events : Icons.flag,
                      size: 50,
                      color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFFFB958),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Başlık
                  Text(
                    isCompleted ? '🎉 Tebrikler!' : 'İyi Gidiyorsun!',
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

                  // İstatistik kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // İlerleme çemberi
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
                                  value: foundSongs.length / totalSongs,
                                  strokeWidth: 10,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFCAB7FF),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF394272),
                                    ),
                                  ),
                                  Text(
                                    '${foundSongs.length}/$totalSongs',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6C6FA4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // İstatistikler
                        Row(
                          children: [
                            Expanded(child: _buildStat(Icons.music_note, '${foundSongs.length}', 'Bulunan')),
                            Expanded(child: _buildStat(Icons.timer, _formatTime(totalElapsedSeconds), 'Süre')),
                            Expanded(child: _buildStat(Icons.speed, '${(foundSongs.length / (totalElapsedSeconds / 60)).toStringAsFixed(1)}', 'Şarkı/dk')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bulunan şarkılar listesi
                  if (foundSongs.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                          ...foundSongs.take(10).map((song) => Padding(
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
                          if (foundSongs.length > 10)
                            Center(
                              child: Text(
                                '+ ${foundSongs.length - 10} şarkı daha',
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

                  // Butonlar
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
                              // Tekrar oyna
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB958),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Tekrar Oyna',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8C5A1F)),
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
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C6FA4), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF394272),
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
