import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../services/access_control_service.dart';
import '../../services/challenge_service.dart';
import '../../services/purchase_service.dart';
import '../premium/premium_screen.dart';
import 'challenge_mode_select_screen.dart';
import 'challenge_online_mode_select_screen.dart';
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

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isPurchasing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ChallengeService _challengeService = ChallengeService();
  final PurchaseService _purchaseService = PurchaseService();
  List<ChallengeSongModel> _songs = [];
  bool _isLoadingSongs = true;
  CategoryModel? _category;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadSongs();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    if (widget.challenge.categoryId.isEmpty) return;
    try {
      final category = await _challengeService.getCategory(widget.challenge.categoryId);
      if (mounted && category != null) {
        setState(() => _category = category);
      }
    } catch (e) {
      debugPrint('Error loading category: $e');
    }
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _challengeService.getChallengeSongs(widget.challenge.id);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading songs: $e');
      if (mounted) {
        setState(() => _isLoadingSongs = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final access = AccessControlService.checkChallengeAccess(user, widget.challenge);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Section
                        _buildHeroCard(access),

                        const SizedBox(height: 18),

                        // Stats Row
                        _buildStatsRow(access),

                        const SizedBox(height: 18),

                        // Song List Preview
                        _buildSongListCard(access, user),

                        // Locked Content Card (if no access)
                        if (!access.hasAccess) ...[
                          const SizedBox(height: 14),
                          _buildLockedContentCard(),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomCTA(context, access, user),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF394272).withValues(alpha:0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF394272),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HERO CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(AccessResult access) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: access.hasAccess
                ? const Color(0xFFCAB7FF).withValues(alpha:0.35)
                : Colors.black.withValues(alpha:0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Gradient background with decorations
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: access.hasAccess
                      ? [const Color(0xFFD4C4FF), const Color(0xFFEDE7FF)]
                      : [const Color(0xFFE8E8E8), const Color(0xFFF8F8F8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Icon / Image placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF394272).withValues(alpha:0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.challenge.type == ChallengeType.artist ? '🎤' : '🎵',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.challenge.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: access.hasAccess
                          ? const Color(0xFF394272)
                          : const Color(0xFF666666),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Micro-copy motivation text
                  Text(
                    _getMicroCopy(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: access.hasAccess
                          ? const Color(0xFF6C6FA4)
                          : const Color(0xFF888888),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Access badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          access.hasAccess ? Icons.lock_open_rounded : Icons.lock_rounded,
                          size: 16,
                          color: access.hasAccess
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFB958),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          access.hasAccess
                              ? 'Erişim Var'
                              : widget.challenge.isFree
                                  ? 'Ücretsiz'
                                  : 'Kilitli',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
            ),

            // Decorative sparkles
            if (access.hasAccess) ...[
              Positioned(
                top: 20,
                left: 24,
                child: _buildSparkle(12),
              ),
              Positioned(
                top: 50,
                right: 30,
                child: _buildSparkle(8),
              ),
              Positioned(
                bottom: 60,
                left: 40,
                child: _buildSparkle(6),
              ),
              Positioned(
                bottom: 40,
                right: 50,
                child: _buildSparkle(10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSparkle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha:0.5),
            blurRadius: size,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }

  String _getMicroCopy() {
    final songCount = widget.challenge.totalSongs;
    if (songCount == 1) {
      return 'Bu kelimeyle 1 şarkı bulabilir misin?';
    } else if (songCount <= 5) {
      return 'Bu kelimeyle $songCount şarkı bulabilir misin?';
    } else if (songCount <= 10) {
      return '$songCount şarkılık bu meydan okumaya hazır mısın?';
    } else {
      return '$songCount şarkı seni bekliyor. Hepsini bulabilir misin?';
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STATS ROW
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(AccessResult access) {
    return Row(
      children: [
        // Song count
        Expanded(
          child: _buildStatCard(
            icon: Icons.music_note_rounded,
            value: '${widget.challenge.totalSongs}',
            label: 'Şarkı',
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 10),
        // Difficulty
        Expanded(
          child: _buildStatCard(
            icon: Icons.speed_rounded,
            value: widget.challenge.difficultyLabel,
            label: 'Zorluk',
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 10),
        // Leaderboard
        Expanded(
          child: GestureDetector(
            onTap: _openLeaderboard,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFFB958),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB958).withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFB958),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sıralama',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFB958),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tabloyu Gör',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394272).withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C6FA4), size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
            ),
          ),
        ],
      ),
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

  // ─────────────────────────────────────────────────────────────────
  // SONG LIST CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSongListCard(AccessResult access, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394272).withValues(alpha:0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: Color(0xFF6C6FA4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Şarkı Listesi (${_songs.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Song list
          if (_isLoadingSongs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFCAB7FF),
                ),
              ),
            )
          else if (_songs.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: const Color(0xFF6C6FA4).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Şarkılar yakında eklenecek',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6C6FA4).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                physics: _songs.length > 3
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  return _buildSongItem(_songs[index], index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSongItem(ChallengeSongModel song, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: index < _songs.length - 1 ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFCAB7FF).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C6FA4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Song info
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C6FA4).withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Year badge
          if (song.year > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFCAB7FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${song.year}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C6FA4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // LOCKED CONTENT CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildLockedContentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394272).withValues(alpha:0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFB958).withValues(alpha:0.2),
                  const Color(0xFFFFD68A).withValues(alpha:0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🔒', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.challenge.totalSongs} şarkı gizli',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.challenge.isFree
                      ? 'Ücretsiz başla ve aç'
                      : 'Challenge\'ı kazan ve aç',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // STICKY BOTTOM CTA
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStickyBottomCTA(BuildContext context, AccessResult access, UserModel? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha:0.0),
            Colors.white.withValues(alpha:0.95),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.5],
        ),
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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB49AFF), Color(0xFFCAB7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCAB7FF).withValues(alpha:0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showPlayModeSheet(context, user),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Oyna',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    // Challenge fiyatı > 0 ise onu kullan, değilse kategori fiyatını kullan
    double price = 0;
    if (!widget.challenge.isFree) {
      if (widget.challenge.priceUsd > 0) {
        price = widget.challenge.priceUsd;
      } else if (_category != null && _category!.packagePrice > 0) {
        price = _category!.packagePrice;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB958), Color(0xFFFFCE54)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB958).withValues(alpha:0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isPurchasing ? null : () => _handlePurchase(context),
              child: Center(
                child: _isPurchasing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.challenge.isFree
                            ? 'Ücretsiz Başla'
                            : 'Satın Al - \$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (!widget.challenge.isFree) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
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
      ],
    );
  }

  Future<void> _handlePurchase(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null || user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satın alma için giriş yapmanız gerekiyor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ücretsiz challenge ise direkt oyna
    if (widget.challenge.isFree) {
      _showPlayModeSheet(context, user);
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      final success = await _purchaseService.buyChallenge(
        widget.challenge.id,
        user.uid,
      );

      if (mounted) {
        if (success) {
          await context.read<AuthProvider>().refreshUser();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.challenge.title} satın alındı!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        } else if (_purchaseService.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_purchaseService.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// PLAY MODE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────
enum ChallengePlayMode { solo, friends }

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

class _PlayModeSheetState extends State<_PlayModeSheet>
    with SingleTickerProviderStateMixin {
  ChallengePlayMode _selectedMode = ChallengePlayMode.solo;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _buttonScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394272).withValues(alpha:0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(height: 20),

              // Title with game emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎮', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  const Text(
                    'Mod Seç',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF394272),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                widget.challenge.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                ),
              ),

              const SizedBox(height: 22),

              // Mode options - Game Cards
              Row(
                children: [
                  Expanded(
                    child: _buildGameModeCard(
                      mode: ChallengePlayMode.solo,
                      emoji: '🎯',
                      title: 'Solo',
                      tagline: 'Kendi rekorunu kır',
                      features: ['Süre bazlı', 'Skor kazan', 'Liderlik tablosu'],
                      accentColor: const Color(0xFF7C4DFF),
                      isSelected: _selectedMode == ChallengePlayMode.solo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGameModeCard(
                      mode: ChallengePlayMode.friends,
                      emoji: '⚔️',
                      title: 'VS',
                      tagline: 'Arkadaşını yen',
                      features: ['Online yarış', 'Sıralı tur', 'Anlık sonuç'],
                      accentColor: const Color(0xFFFF6B6B),
                      isSelected: _selectedMode == ChallengePlayMode.friends,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Action-oriented micro-copy
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(_selectedMode),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedMode == ChallengePlayMode.solo
                          ? [const Color(0xFFF3EFFF), const Color(0xFFEDE7FF)]
                          : [const Color(0xFFFFEFEF), const Color(0xFFFFE5E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedMode == ChallengePlayMode.solo ? '⏱️' : '🏆',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedMode == ChallengePlayMode.solo
                              ? 'Hızlı ol, yüksek skor kap!'
                              : 'Kim daha hızlı bulacak?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedMode == ChallengePlayMode.solo
                                ? const Color(0xFF5E35B1)
                                : const Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Start button with animation
              AnimatedBuilder(
                animation: _buttonScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _buttonScale.value,
                    child: child,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedMode == ChallengePlayMode.solo
                          ? [const Color(0xFF9C7CFF), const Color(0xFFB49AFF)]
                          : [const Color(0xFFFF7B7B), const Color(0xFFFF9B9B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedMode == ChallengePlayMode.solo
                                ? const Color(0xFFB49AFF)
                                : const Color(0xFFFF7B7B))
                            .withValues(alpha:0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _startGame(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Başla',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Cancel - more subtle
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Vazgeç',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C6FA4).withValues(alpha:0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required ChallengePlayMode mode,
    required String emoji,
    required String title,
    required String tagline,
    required List<String> features,
    required Color accentColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.0 : 0.96),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha:0.08) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha:0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Emoji with glow effect
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [accentColor.withValues(alpha:0.2), accentColor.withValues(alpha:0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF8F8FF),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha:0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : const Color(0xFF394272),
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 4),

            // Tagline
            Text(
              tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? accentColor.withValues(alpha:0.8)
                    : const Color(0xFF6C6FA4).withValues(alpha:0.7),
              ),
            ),

            const SizedBox(height: 10),

            // Feature chips
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha:0.12)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? accentColor
                        : const Color(0xFF6C6FA4).withValues(alpha:0.8),
                  ),
                ),
              )).toList(),
            ),

            // Selection indicator
            if (isSelected) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Seçili',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    // Haptic feedback would be triggered here
    // HapticService.mediumImpact();
    
    Navigator.pop(context);

    if (_selectedMode == ChallengePlayMode.solo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeModeSelectScreen(
            challenge: widget.challenge,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeOnlineModeSelectScreen(
            challenge: widget.challenge,
          ),
        ),
      );
    }
  }
}
