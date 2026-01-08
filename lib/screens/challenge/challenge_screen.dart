import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../services/challenge_service.dart';
import '../../services/access_control_service.dart';
import '../../widgets/app_card_system.dart';
import '../auth/login_screen.dart';
import '../auth/profile_screen.dart';
import 'challenge_detail_screen.dart';
import 'category_detail_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final ChallengeService _challengeService = ChallengeService();
  String _selectedLanguage = 'tr';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background - always visible
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, user, isLoggedIn),
                Expanded(
                  child: !isLoggedIn
                      ? _buildLoginRequired(context)
                      : _buildChallengeContent(context, user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, UserModel? user, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          _buildCircleButton(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF394272),
            ),
          ),

          const SizedBox(width: 14),

          // Title
          const Expanded(
            child: Text(
              'Challenge',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Language segmented control
          _buildLanguageSegment(),

          const SizedBox(width: 12),

          // Profile button
          _buildCircleButton(
            onTap: () {
              if (isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: user?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user!.photoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    isLoggedIn ? Icons.person : Icons.login_rounded,
                    size: 20,
                    color: const Color(0xFF6C6FA4),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
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
        child: Center(child: child),
      ),
    );
  }

  Widget _buildLanguageSegment() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.85),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394272).withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('🇹🇷', 'tr'),
          const SizedBox(width: 2),
          _buildLanguageOption('🇬🇧', 'en'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String langCode) {
    final isSelected = _selectedLanguage == langCode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = langCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCAB7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            flag,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGIN REQUIRED
  // ─────────────────────────────────────────────────────────────────
  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.9),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF394272).withValues(alpha:0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCAB7FF), Color(0xFFE8DFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCAB7FF).withValues(alpha:0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Challenge Modu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF394272),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Challenge modunu görmek ve\noynamak için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6C6FA4),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCAB7FF),
                    foregroundColor: const Color(0xFF394272),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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

  // ─────────────────────────────────────────────────────────────────
  // MAIN CONTENT
  // ─────────────────────────────────────────────────────────────────
  Widget _buildChallengeContent(BuildContext context, UserModel? user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Categories
          _buildSectionHeader('Kategoriler', showSeeAll: false),
          const SizedBox(height: 14),
          _buildCategoryList(user),

          const SizedBox(height: 28),

          // Popular Challenges
          _buildSectionHeader(
            'Popüler',
            icon: '🔥',
            showSeeAll: true,
            onSeeAllTap: () {
              // TODO: Navigate to all popular challenges
            },
          ),
          const SizedBox(height: 14),
          _buildPopularChallenges(user),

          const SizedBox(height: 28),

          // All Challenges
          _buildSectionHeader(
            "Tüm Challenge'lar",
            icon: '🎵',
            showSeeAll: true,
            onSeeAllTap: () {
              // TODO: Navigate to all challenges
            },
          ),
          const SizedBox(height: 14),
          _buildAllChallenges(user),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? icon,
    bool showSeeAll = false,
    VoidCallback? onSeeAllTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        if (showSeeAll)
          GestureDetector(
            onTap: onSeeAllTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C6FA4),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFF6C6FA4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────
  Widget _buildCategoryList(UserModel? user) {
    return StreamBuilder<List<CategoryModel>>(
      stream: _challengeService.getCategoriesByLanguage(_selectedLanguage),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                child: _buildCategorySkeletonCard(),
              ),
            ),
          );
        }

        final categories = snapshot.data!;
        if (categories.isEmpty) {
          return _buildEmptyCard('Kategori bulunamadı');
        }

        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < categories.length - 1 ? 12 : 0),
                child: _buildCategoryCard(categories[index], user),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategorySkeletonCard() {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Spacer(),
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, UserModel? user) {
    final access = AccessControlService.checkCategoryAccess(user, category);
    final hasAccess = access.hasAccess;

    // Determine gradient based on category type
    List<Color> gradientColors;
    if (!hasAccess) {
      gradientColors = [const Color(0xFFE8E8E8), const Color(0xFFF5F5F5)];
    } else {
      // Assign different gradients based on category characteristics
      final title = category.title.toLowerCase();
      if (title.contains('pop') || title.contains('hit')) {
        gradientColors = AppCardColors.timeRaceGradient;
      } else if (title.contains('rock') || title.contains('metal')) {
        gradientColors = AppCardColors.realChallengeGradient;
      } else if (title.contains('slow') || title.contains('acoustic')) {
        gradientColors = AppCardColors.relaxGradient;
      } else {
        gradientColors = AppCardColors.defaultChallengeGradient;
      }
    }

    return CategoryCard(
      title: category.title,
      emoji: category.iconEmoji ?? '🎵',
      challengeCount: category.challengeCount,
      isLocked: !hasAccess,
      gradientColors: gradientColors,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: category),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // POPULAR CHALLENGES
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPopularChallenges(UserModel? user) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getPopularChallenges(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Column(
            children: List.generate(3, (_) => _buildChallengeSkeletonCard()),
          );
        }

        final challenges = snapshot.data!
            .where((c) => c.language == _selectedLanguage)
            .toList();

        if (challenges.isEmpty) {
          return _buildEmptyCard('Bu dilde popüler challenge yok');
        }

        return Column(
          children: challenges.map((c) => _buildChallengeCard(c, user)).toList(),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // ALL CHALLENGES
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAllChallenges(UserModel? user) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getChallengesByLanguage(_selectedLanguage),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Column(
            children: List.generate(4, (_) => _buildChallengeSkeletonCard()),
          );
        }

        final challenges = snapshot.data!;
        if (challenges.isEmpty) {
          return _buildEmptyCard("Challenge'lar yükleniyor...");
        }

        return Column(
          children: challenges.map((c) => _buildChallengeCard(c, user)).toList(),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CHALLENGE CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildChallengeSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, UserModel? user) {
    final access = AccessControlService.checkChallengeAccess(user, challenge);
    final hasAccess = access.hasAccess;

    // Determine challenge type for color coding based on difficulty enum
    ChallengeCardType cardType;
    final title = challenge.title.toLowerCase();
    final difficulty = challenge.difficulty;

    if (difficulty == ChallengeDifficulty.hard) {
      cardType = ChallengeCardType.realChallenge; // Purple/Blue - Hard challenges
    } else if (title.contains('hızlı') || title.contains('yarış')) {
      cardType = ChallengeCardType.timeRace; // Orange/Red - Time-based
    } else if (difficulty == ChallengeDifficulty.easy || title.contains('kolay') || title.contains('başlangıç')) {
      cardType = ChallengeCardType.relax; // Green/Teal - Easy/Relaxed
    } else {
      cardType = ChallengeCardType.standard; // Purple - Default
    }

    return ChallengeCard(
      title: challenge.title,
      emoji: challenge.type == ChallengeType.artist ? '🎤' : '🎵',
      type: hasAccess ? cardType : ChallengeCardType.standard,
      isLocked: !hasAccess,
      songCount: challenge.totalSongs,
      difficulty: challenge.difficultyLabel,
      subtitle: challenge.isFree ? 'Ücretsiz' : '',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF6C6FA4),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
