import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../services/challenge_service.dart';
import '../../services/access_control_service.dart';
import '../../services/pricing_service.dart';
import 'challenge_mode_select_screen.dart';
import 'challenge_game_screen.dart';
import 'leaderboard_screen.dart';

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
          // Challenge başlığı
          Text(
            widget.challenge.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 36), // Denge için
        ],
      ),
    );
  }

  Widget _buildChallengeCard(AccessResult access) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Emoji / İkon
          Text(
            widget.challenge.type == ChallengeType.artist ? '🎤' : '🎵',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          // Başlık
          Text(
            widget.challenge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: access.hasAccess
                  ? const Color(0xFF394272)
                  : const Color(0xFF888888),
            ),
          ),
          if (widget.challenge.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.challenge.subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: access.hasAccess
                    ? const Color(0xFF6C6FA4)
                    : const Color(0xFF999999),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Durum badge'i
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  size: 14,
                  color: access.hasAccess
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFB958),
                ),
                const SizedBox(width: 4),
                Text(
                  access.hasAccess
                      ? 'Erişim Var'
                      : widget.challenge.isFree
                          ? 'Ücretsiz'
                          : 'Kilitli',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.music_note,
            label: 'Şarkı',
            value: '${widget.challenge.totalSongs}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.speed,
            label: 'Zorluk',
            value: widget.challenge.difficultyLabel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _openLeaderboard(),
            child: _buildStatCard(
              icon: Icons.emoji_events,
              label: 'Sıralama',
              value: 'Gör',
              highlight: true,
            ),
          ),
        ),
      ],
    );
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(challenge: widget.challenge),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: highlight 
            ? const Color(0xFFFFB958).withOpacity(0.15)
            : Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(16),
        border: highlight 
            ? Border.all(color: const Color(0xFFFFB958), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: highlight ? const Color(0xFFFFB958) : const Color(0xFF6C6FA4), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: highlight ? const Color(0xFFFFB958) : const Color(0xFF394272),
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

  Widget _buildProgressSection(UserModel? user) {
    // TODO: Gerçek ilerleme verisi çekilecek
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İlerleme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.0, // TODO: Gerçek ilerleme
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFCAB7FF)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '0 / ${widget.challenge.totalSongs} şarkı bulundu',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6C6FA4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Açıklama',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.challenge.description!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C6FA4),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.queue_music, color: Color(0xFF6C6FA4)),
              const SizedBox(width: 8),
              const Text(
                'Şarkı Listesi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF394272),
                ),
              ),
              const Spacer(),
              Text(
                '${widget.challenge.totalSongs} şarkı',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6C6FA4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Şarkıları görmek için challenge\'ı oyna!',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
              fontStyle: FontStyle.italic,
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
            color: Colors.black.withValues(alpha:0.1),
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
        onPressed: () => _showPlayModeSheet(context, user),
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

  /// Oyun modu seçim bottom sheet
  void _showPlayModeSheet(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlayModeSheet(
        challenge: widget.challenge,
        user: user,
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
              color: const Color(0xFF394272).withValues(alpha:0.7),
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

/// Oyun modu seçim bottom sheet
class _PlayModeSheet extends StatefulWidget {
  final ChallengeModel challenge;
  final UserModel? user;

  const _PlayModeSheet({
    required this.challenge,
    required this.user,
  });

  @override
  State<_PlayModeSheet> createState() => _PlayModeSheetState();
}

class _PlayModeSheetState extends State<_PlayModeSheet> {
  ChallengePlayMode _selectedMode = ChallengePlayMode.solo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Başlık
              const Text(
                'Nasıl Oynamak İstersin?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF394272),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.challenge.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6FA4),
                ),
              ),

              const SizedBox(height: 24),

              // Mod seçenekleri
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      mode: ChallengePlayMode.solo,
                      icon: Icons.person,
                      title: 'Tek Kişilik',
                      subtitle: 'Kendi başına oyna',
                      isSelected: _selectedMode == ChallengePlayMode.solo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModeCard(
                      mode: ChallengePlayMode.friends,
                      icon: Icons.people,
                      title: 'Arkadaşla',
                      subtitle: 'Aynı cihazda yarış',
                      isSelected: _selectedMode == ChallengePlayMode.friends,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Açıklama
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedMode == ChallengePlayMode.solo
                          ? Icons.timer
                          : Icons.swap_horiz,
                      color: const Color(0xFF6C6FA4),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedMode == ChallengePlayMode.solo
                            ? 'Tüm şarkıları bulmaya çalış. Süre tutulacak!'
                            : 'Sırayla oynayın, en çok şarkıyı bulan kazanır!',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C6FA4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Başla butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _startGame(context),
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'Başla',
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
              ),

              const SizedBox(height: 12),

              // İptal
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'İptal',
                  style: TextStyle(
                    color: Color(0xFF6C6FA4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required ChallengePlayMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFCAB7FF).withValues(alpha:0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCAB7FF)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFCAB7FF).withValues(alpha:0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFCAB7FF)
                    : const Color(0xFFF5F5FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF6C6FA4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF394272)
                    : const Color(0xFF6C6FA4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    Navigator.pop(context); // Sheet'i kapat

    if (_selectedMode == ChallengePlayMode.solo) {
      // Tek kişilik - mod seçim ekranına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeModeSelectScreen(
            challenge: widget.challenge,
          ),
        ),
      );
    } else {
      // Arkadaşla oyun - direkt relax modunda başla
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeGameScreen(
            challenge: widget.challenge,
            playMode: ChallengePlayMode.friends,
            singleMode: ChallengeSingleMode.relax,
          ),
        ),
      );
    }
  }
}
