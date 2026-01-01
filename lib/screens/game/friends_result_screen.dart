import 'package:flutter/material.dart';

import 'friends_settings_screen.dart'; // Tekrar oyna -> ayarlar ekranı

class FriendGameResultScreen extends StatelessWidget {
  final int player1Score;
  final int player2Score;

  /// Oyunun toplam süresi (saniye cinsinden)
  final int totalElapsedSeconds;

  const FriendGameResultScreen({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.totalElapsedSeconds,
  });

  String _formatTotalTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalTimeText = _formatTotalTime(totalElapsedSeconds);

    // Skor listesi: yüksek skordan düşüğe sıralı
    final results = [
      _PlayerResult(label: 'Player 1', score: player1Score),
      _PlayerResult(label: 'Player 2', score: player2Score),
    ]..sort((a, b) => b.score.compareTo(a.score));

    // Kazanan
    String winnerText;
    if (player1Score > player2Score) {
      winnerText = 'Player 1 Kazandı.';
    } else if (player2Score > player1Score) {
      winnerText = 'Player 2 Kazandı.';
    } else {
      winnerText = 'Berabere!';
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/images/logo_find2sing.png',
                      width: 120,
                    ),
                  ),
                ),

                // 🔹 Ortadaki blok: Başlık + süre + kart → tam ortada
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Oyun Tamamlandı',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF394272),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toplam Süre: $totalTimeText',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF394272),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Orta kart – biraz daha dar ve ortalı
                        Container(
                          width: size.width * 0.8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7FF),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Kazanan
                              Text(
                                winnerText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF394272),
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Sonuç Tablosu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF394272),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tablo
                              Column(
                                children: [
                                  for (int i = 0; i < results.length; i++) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${results[i].score} Şarkı',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF394272),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            results[i].label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF394272),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (i != results.length - 1)
                                      const Divider(
                                        thickness: 1,
                                        color: Color(0xFF394272),
                                      ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Alt bar – Ana Menü / Tekrar Oyna
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF343B73),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 6,
                            ),
                            child: const Text(
                              'Ana Menü',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Ayarlar ekranına dönüp yeni oyun başlatmak için
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const FriendsSettingsScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2AA3B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 6,
                            ),
                            child: const Text(
                              'Tekrar Oyna',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
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
}

class _PlayerResult {
  final String label;
  final int score;
  _PlayerResult({required this.label, required this.score});
}
