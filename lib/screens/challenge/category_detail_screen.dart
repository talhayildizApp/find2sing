import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../services/challenge_service.dart';
import '../../services/access_control_service.dart';
import '../../services/pricing_service.dart';
import 'challenge_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ChallengeService _challengeService = ChallengeService();
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final access = AccessControlService.checkCategoryAccess(user, widget.category);

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
                // Üst bar
                _buildTopBar(context),

                // İçerik
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Kategori kartı
                        _buildCategoryCard(access),

                        const SizedBox(height: 20),

                        // Fiyat bilgisi (kilitliyse)
                        if (!access.hasAccess) ...[
                          _buildPriceInfo(),
                          const SizedBox(height: 20),
                        ],

                        // Challenge listesi
                        _buildChallengeList(user, access),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Alt buton (kilitliyse satın al)
                if (!access.hasAccess) _buildBottomButton(context, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF394272),
                size: 18,
              ),
            ),
          ),

          const Expanded(
            child: Text(
              'Kategori',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(AccessResult access) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: access.hasAccess
              ? [const Color(0xFFCAB7FF), const Color(0xFFE0D6FF)]
              : [const Color(0xFFFFD891), const Color(0xFFFFE4B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji/İkon
          Text(
            widget.category.iconEmoji ?? '🎵',
            style: const TextStyle(fontSize: 48),
          ),

          const SizedBox(height: 16),

          // Başlık
          Text(
            widget.category.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF394272),
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.category.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.category.subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF394272).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          // İstatistikler
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat(
                Icons.emoji_events,
                '${widget.category.challengeCount}',
                'Challenge',
              ),
              const SizedBox(width: 24),
              _buildMiniStat(
                Icons.language,
                widget.category.language.toUpperCase(),
                'Dil',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Durum
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: access.hasAccess
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                  : const Color(0xFFFF9800).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  access.hasAccess ? Icons.lock_open : Icons.lock,
                  size: 18,
                  color: access.hasAccess
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 8),
                Text(
                  access.hasAccess ? 'Erişim Açık' : 'Kilitli',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: access.hasAccess
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C6FA4), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF394272),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6C6FA4),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    final priceInfo = PricingService.getCategoryPriceInfo(widget.category.challengeCount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tekil fiyat',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6FA4),
                ),
              ),
              Text(
                priceInfo.originalPriceFormatted,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6FA4),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Paket fiyatı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF394272),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '%${priceInfo.discountPercent.toInt()} İNDİRİM',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                priceInfo.discountedPriceFormatted,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${priceInfo.savingsFormatted} tasarruf',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeList(UserModel? user, AccessResult categoryAccess) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getChallengesByCategory(widget.category.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Bu kategoride henüz challenge yok',
                style: TextStyle(
                  color: Color(0xFF6C6FA4),
                ),
              ),
            ),
          );
        }

        final challenges = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge\'lar (${challenges.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
            ),
            const SizedBox(height: 12),
            ...challenges.map((c) => _buildChallengeItem(c, user, categoryAccess)),
          ],
        );
      },
    );
  }

  Widget _buildChallengeItem(
    ChallengeModel challenge,
    UserModel? user,
    AccessResult categoryAccess,
  ) {
    // Kategori açıksa veya challenge'ın kendisi açıksa erişim var
    final hasAccess = categoryAccess.hasAccess ||
        (user?.hasChallengeAccess(challenge.id) ?? false);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Durum ikonu
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasAccess
                    ? const Color(0xFFCAB7FF).withValues(alpha: 0.2)
                    : const Color(0xFFFF9800).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  hasAccess ? Icons.play_arrow : Icons.lock,
                  color: hasAccess
                      ? const Color(0xFF6C6FA4)
                      : const Color(0xFFFF9800),
                  size: 24,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF394272),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${challenge.totalSongs} şarkı',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C6FA4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCCCCCC),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        challenge.difficultyLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getDifficultyColor(challenge.difficulty),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ok
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFCCCCCC),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFF4CAF50);
      case ChallengeDifficulty.medium:
        return const Color(0xFFFF9800);
      case ChallengeDifficulty.hard:
        return const Color(0xFFF44336);
    }
  }

  Widget _buildBottomButton(BuildContext context, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : () => _handlePurchase(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB958),
                  foregroundColor: const Color(0xFF8C5A1F),
                  disabledBackgroundColor: const Color(0xFFFFD6A0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8C5A1F),
                        ),
                      )
                    : Text(
                        'Kategoriyi Satın Al - \$${widget.category.priceUsd.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // TODO: Premium ekranına git
              },
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'veya ',
                      style: TextStyle(
                        color: const Color(0xFF394272).withValues(alpha: 0.7),
                      ),
                    ),
                    const TextSpan(
                      text: 'Premium',
                      style: TextStyle(
                        color: Color(0xFFCAB7FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' ile tümüne eriş',
                      style: TextStyle(
                        color: const Color(0xFF394272).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context) async {
    setState(() => _isPurchasing = true);

    try {
      // TODO: Gerçek satın alma işlemi
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Satın alma işlemi yapılacak (In-App Purchase)'),
            backgroundColor: Color(0xFFFFB958),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }
}
