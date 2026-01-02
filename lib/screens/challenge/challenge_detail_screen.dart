import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../services/challenge_service.dart';
import '../../services/access_control_service.dart';
import '../../services/pricing_service.dart';
import 'challenge_game_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final ChallengeModel challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final ChallengeService _challengeService = ChallengeService();
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final access = AccessControlService.checkChallengeAccess(user, widget.challenge);

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
                        // Challenge kartı
                        _buildChallengeCard(access),

                        const SizedBox(height: 20),

                        // İstatistikler
                        _buildStatsRow(),

                        const SizedBox(height: 20),

                        // İlerleme (erişim varsa)
                        if (access.hasAccess) ...[
                          _buildProgressSection(user),
                          const SizedBox(height: 20),
                        ],

                        // Açıklama
                        if (widget.challenge.description != null) ...[
                          _buildDescription(),
                          const SizedBox(height: 20),
                        ],

                        // Şarkı listesi önizleme
                        _buildSongPreview(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Alt buton
                _buildBottomButton(context, access, user),
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
              'Challenge Detay',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Boşluk için
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(AccessResult access) {
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
          // Durum ikonu
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: access.hasAccess
                  ? const Icon(
                      Icons.play_circle_fill,
                      size: 40,
                      color: Color(0xFF394272),
                    )
                  : const Icon(
                      Icons.lock,
                      size: 36,
                      color: Color(0xFF8C5A1F),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Başlık
          Text(
            widget.challenge.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF394272),
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.challenge.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.challenge.subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF394272).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          // Zorluk ve tür
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag(
                widget.challenge.difficultyLabel,
                _getDifficultyColor(widget.challenge.difficulty),
              ),
              const SizedBox(width: 8),
              _buildTag(
                widget.challenge.typeLabel,
                const Color(0xFF6C6FA4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.music_note,
            value: '${widget.challenge.totalSongs}',
            label: 'Şarkı',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.play_arrow,
            value: '${widget.challenge.playCount}',
            label: 'Oynama',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.language,
            value: widget.challenge.language.toUpperCase(),
            label: 'Dil',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C6FA4), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildProgressSection(UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<ChallengeProgressModel?>(
      stream: _challengeService.getChallengeProgress(user.uid, widget.challenge.id),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final percent = progress?.progressPercent ?? 0;
        final found = progress?.foundSongs ?? 0;
        final total = widget.challenge.totalSongs;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'İlerleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF394272),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: const Color(0xFFE0E0E0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFCAB7FF),
                        ),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${percent.toInt()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF394272),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$found / $total şarkı bulundu',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6FA4),
                ),
              ),
              if (progress?.isCompleted == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tamamlandı!',
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
      },
    );
  }

  Widget _buildDescription() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Açıklama',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.challenge.description!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C6FA4),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongPreview() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Şarkılar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF394272),
                ),
              ),
              const Spacer(),
              Text(
                '${widget.challenge.totalSongs} şarkı',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6FA4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Önizleme - ilk 3 şarkı (bulanık)
          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCAB7FF).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C6FA4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 10,
                          width: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.visibility_off,
                    color: Color(0xFFCCCCCC),
                    size: 18,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+ ${widget.challenge.totalSongs - 3} şarkı daha...',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6C6FA4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    AccessResult access,
    UserModel? user,
  ) {
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
        child: access.hasAccess
            ? _buildPlayButton(context, user)
            : _buildPurchaseButton(context, user),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, UserModel? user) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeGameScreen(challenge: widget.challenge),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow, size: 28),
        label: const Text(
          'Oyna',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCAB7FF),
          foregroundColor: const Color(0xFF394272),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context, UserModel? user) {
    final price = widget.challenge.isFree ? 0 : widget.challenge.priceUsd;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.challenge.isFree) ...[
          Text(
            'Bu challenge\'ı açmak için satın al',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF394272).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
                    widget.challenge.isFree
                        ? 'Ücretsiz Başla'
                        : 'Satın Al - \$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Premium önerisi
        if (!widget.challenge.isFree)
          GestureDetector(
            onTap: () {
              // Premium ekranına git
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
    );
  }

  Future<void> _handlePurchase(BuildContext context) async {
    setState(() => _isPurchasing = true);

    try {
      // Gerçek satın alma işlemi
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
