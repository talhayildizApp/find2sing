import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../services/challenge_service.dart';
import '../../services/access_control_service.dart';
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Color(0xFF394272),
              ),
            ),
          ),
          const Spacer(),
          // Başlık
          Text(
            widget.category.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const Spacer(),
          // Home butonu
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 20,
                color: Color(0xFF394272),
              ),
            ),
          ),
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
              : [const Color(0xFFE8E8E8), const Color(0xFFF5F5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji
          Text(
            widget.category.iconEmoji ?? '🎵',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          // Başlık
          Text(
            widget.category.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: access.hasAccess
                  ? const Color(0xFF394272)
                  : const Color(0xFF888888),
            ),
          ),
          if (widget.category.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.category.description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: access.hasAccess
                    ? const Color(0xFF6C6FA4)
                    : const Color(0xFF999999),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Durum badge'i
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: access.hasAccess
                  ? const Color(0xFF4CAF50).withValues(alpha:0.15)
                  : const Color(0xFFFFB958).withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  access.hasAccess ? Icons.lock_open : Icons.lock,
                  size: 16,
                  color: access.hasAccess
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFB958),
                ),
                const SizedBox(width: 6),
                Text(
                  access.hasAccess
                      ? '${widget.category.challengeCount} Challenge Açık'
                      : 'Kategori Kilitli',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: access.hasAccess
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFFB958),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFF57C00),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu kategori kilitli',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kategoriyi satın alarak tüm challenge\'lara erişebilirsin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFE65100).withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
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
              color: Colors.white.withValues(alpha:0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Bu kategoride henüz challenge yok',
                style: TextStyle(color: Color(0xFF6C6FA4)),
              ),
            ),
          );
        }

        final challenges = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Challenge\'lar (${challenges.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                ),
                if (!categoryAccess.hasAccess) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB958).withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Color(0xFFFFB958)),
                        SizedBox(width: 4),
                        Text(
                          'Önizleme',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFB958),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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

    // Kilitli kategoride içerikler görünür ama tıklanamaz
    final isClickable = hasAccess || categoryAccess.hasAccess;

    return GestureDetector(
      onTap: isClickable
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChallengeDetailScreen(challenge: challenge),
                ),
              );
            }
          : () {
              // Kilitli challenge'a tıklandığında bilgi göster
              _showLockedInfo(context);
            },
      child: Opacity(
        opacity: hasAccess ? 1.0 : 0.6,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
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
                      ? const Color(0xFFCAB7FF).withValues(alpha:0.2)
                      : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: hasAccess
                      ? Text(
                          challenge.type == ChallengeType.artist ? '🎤' : '🎵',
                          style: const TextStyle(fontSize: 20),
                        )
                      : const Icon(
                          Icons.lock,
                          size: 20,
                          color: Color(0xFF888888),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Challenge bilgisi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: hasAccess
                            ? const Color(0xFF394272)
                            : const Color(0xFF888888),
                      ),
                    ),
                    if (challenge.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        challenge.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasAccess
                              ? const Color(0xFF6C6FA4)
                              : const Color(0xFF999999),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMiniChip(
                          '${challenge.totalSongs} şarkı',
                          hasAccess,
                        ),
                        const SizedBox(width: 6),
                        _buildMiniChip(
                          challenge.difficultyLabel,
                          hasAccess,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Ok veya kilit
              Icon(
                hasAccess ? Icons.chevron_right : Icons.lock_outline,
                color: hasAccess
                    ? const Color(0xFF6C6FA4)
                    : const Color(0xFFCCCCCC),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String text, bool hasAccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasAccess ? const Color(0xFFF5F5FF) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: hasAccess ? const Color(0xFF6C6FA4) : const Color(0xFF999999),
        ),
      ),
    );
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Kolay';
      case 'medium':
        return 'Orta';
      case 'hard':
        return 'Zor';
      default:
        return 'Orta';
    }
  }

  void _showLockedInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('Bu challenge\'ı oynamak için kategoriyi satın al'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFB958),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
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
                        color: const Color(0xFF394272).withValues(alpha:0.7),
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
                        color: const Color(0xFF394272).withValues(alpha:0.7),
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
