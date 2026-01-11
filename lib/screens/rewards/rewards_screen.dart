// lib/screens/rewards/rewards_screen.dart
//
// Kullanıcı hakları ve ödülleri ekranı.
// İki ayrı joker sistemi:
// 1. Kelime Değiştirme Hakları (Tek Başına & Arkadaşla modu)
// 2. Challenge Jokerleri (3 adet, her biri ayrı reklam)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/rewards_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardsService _rewardsService = RewardsService();
  bool _isWatchingAd = false;
  int? _watchingJokerIndex; // Challenge joker için hangi index'e reklam izleniyor

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan - Bulut teması
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                  const Color(0xFFF5F0FF).withValues(alpha: 0.2),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      children: [
                        // Kelime Değiştirme Hakları (Tek Başına & Arkadaşla)
                        _buildWordChangeCard(user),
                        const SizedBox(height: 16),

                        // Challenge Jokerleri (3 adet)
                        _buildChallengeJokersCard(user),
                        const SizedBox(height: 16),

                        // Premium tanıtım
                        if (user != null && !user.isActivePremium)
                          _buildPremiumPromo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button - profil ekranı tarzında
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF394272),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Joker Hakları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const Spacer(),
          // Sağda boşluk için placeholder
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Kelime Değiştirme Hakları - Tek Başına & Arkadaşla modu için
  Widget _buildWordChangeCard(UserModel? user) {
    final currentCredits = _rewardsService.getCurrentJokerCount(user);
    final canWatch = _rewardsService.canWatchAd(user);
    final rewardAmount = _rewardsService.getAdRewardAmount(user);
    final isPremium = user?.isActivePremium ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCAB7FF), Color(0xFFB19CD9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🃏', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelime Değiştirme',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF394272),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tek Başına & Arkadaşla modu',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF394272).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Joker sayısı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🃏', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      isPremium ? '∞' : '$currentCredits/${UserModel.maxWordChangeCredits}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF394272),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isPremium) ...[
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: currentCredits / UserModel.maxWordChangeCredits,
                backgroundColor: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCAB7FF)),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 16),

            // Reklam izle butonu
            GestureDetector(
              onTap: canWatch && !_isWatchingAd ? () => _watchAdForCredits(user!) : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: canWatch
                      ? const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                        )
                      : null,
                  color: canWatch ? null : const Color(0xFF394272).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isWatchingAd && _watchingJokerIndex == null)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else ...[
                      Icon(
                        Icons.play_circle_filled,
                        color: canWatch ? Colors.white : const Color(0xFF394272).withValues(alpha: 0.4),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canWatch
                            ? 'Reklam İzle (+$rewardAmount Hak)'
                            : 'Maksimum Hakka Ulaştınız',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: canWatch ? Colors.white : const Color(0xFF394272).withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Premium ile sınırsız hak!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Joker bilgileri - isim, ikon ve açıklama
  static const List<Map<String, String>> _jokerInfo = [
    {
      'name': 'Şarkıcı',
      'icon': '🎤',
      'desc': 'Doğru şarkıcıyı gösterir',
    },
    {
      'name': 'Şarkı',
      'icon': '🎵',
      'desc': 'Doğru şarkıyı gösterir',
    },
    {
      'name': 'x2 Puan',
      'icon': '✨',
      'desc': 'Bu turda çift puan kazan',
    },
  ];

  /// Challenge Jokerleri - 3 adet, her biri ayrı reklam
  Widget _buildChallengeJokersCard(UserModel? user) {
    final isPremium = user?.isActivePremium ?? false;
    final jokerState = _rewardsService.getChallengeJokerState(user);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD891).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD891), Color(0xFFFFB958)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Challenge Jokerleri',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF394272),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Online Challenge modunda kullan',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF394272).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Aktif joker sayısı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD891).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      isPremium ? '∞' : '${jokerState.where((j) => j).length}/${UserModel.maxChallengeJokers}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF394272),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bilgi kutusu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD891).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD891).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: const Color(0xFFFFB958),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Her joker oyun başına 1 kez kullanılır. Reklam izleyerek aktifleştir, sonraki oyunda kullan!',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF394272).withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3 Joker gösterimi
          if (isPremium)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Premium ile reklamsız joker!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: List.generate(3, (index) {
                final isActive = jokerState[index];
                final isWatching = _watchingJokerIndex == index;
                final info = _jokerInfo[index];

                return Padding(
                  padding: EdgeInsets.only(bottom: index < 2 ? 10 : 0),
                  child: GestureDetector(
                    onTap: !isActive && !_isWatchingAd && user != null && !user.isGuest
                        ? () => _watchAdForChallengeJoker(user, index)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [Color(0xFFFFD891), Color(0xFFFFB958)],
                              )
                            : null,
                        color: isActive ? null : const Color(0xFF394272).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: isActive
                            ? null
                            : Border.all(
                                color: const Color(0xFFFFD891).withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                      ),
                      child: Row(
                        children: [
                          // İkon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : const Color(0xFFFFD891).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: isWatching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB958)),
                                      ),
                                    )
                                  : Text(
                                      info['icon']!,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // İsim ve açıklama
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info['name']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? Colors.white : const Color(0xFF394272),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  info['desc']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : const Color(0xFF394272).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Durum
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isActive && !isWatching)
                                  Icon(
                                    Icons.play_circle_fill,
                                    size: 14,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                if (!isActive && !isWatching)
                                  const SizedBox(width: 4),
                                Text(
                                  isActive ? 'Aktif' : (isWatching ? '...' : 'Kazan'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? Colors.white : const Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

          if (!isPremium && user != null && !user.isGuest) ...[
            const SizedBox(height: 12),
            Text(
              'Her joker için ayrı reklam izleyin',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF394272).withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (user?.isGuest == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Giriş yaparak joker kazanabilirsiniz',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumPromo() {
    return GestureDetector(
      onTap: () {
        // TODO: Premium satın alma ekranına git
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium satın alma yakında!'),
            backgroundColor: Color(0xFF667eea),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea).withValues(alpha: 0.9),
              const Color(0xFF764ba2).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium\'a Yükselt',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sınırsız joker, reklamsız oyna!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '\$4.99/ay',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF667eea),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kelime değiştirme hakkı için reklam izle
  Future<void> _watchAdForCredits(UserModel user) async {
    setState(() {
      _isWatchingAd = true;
      _watchingJokerIndex = null;
    });

    // TODO: Gerçek reklam SDK entegrasyonu
    await Future.delayed(const Duration(seconds: 2));

    final result = await _rewardsService.watchAdForCredits(user);

    setState(() => _isWatchingAd = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (result.success ? 'Başarılı!' : 'Hata!')),
          backgroundColor: result.success ? const Color(0xFF4CAF50) : Colors.red,
        ),
      );

      if (result.success) {
        await context.read<AuthProvider>().refreshUser();
      }
    }
  }

  /// Challenge jokeri için reklam izle
  Future<void> _watchAdForChallengeJoker(UserModel user, int jokerIndex) async {
    setState(() {
      _isWatchingAd = true;
      _watchingJokerIndex = jokerIndex;
    });

    // TODO: Gerçek reklam SDK entegrasyonu
    await Future.delayed(const Duration(seconds: 2));

    final result = await _rewardsService.watchAdForChallengeJoker(user, jokerIndex);

    setState(() {
      _isWatchingAd = false;
      _watchingJokerIndex = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (result.success ? 'Joker kazanıldı!' : 'Hata!')),
          backgroundColor: result.success ? const Color(0xFF4CAF50) : Colors.red,
        ),
      );

      if (result.success) {
        await context.read<AuthProvider>().refreshUser();
      }
    }
  }
}
