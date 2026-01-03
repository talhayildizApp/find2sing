import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../services/challenge_service.dart';
import '../../services/access_control_service.dart';
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

  String _selectedLanguage = 'tr'; // Varsayılan Türkçe

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isLoggedIn = authProvider.isAuthenticated;

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
                // Üst bar - Geri + Bayrak + Başlık + Profil
                _buildTopBar(context, user, isLoggedIn),

                // İçerik
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

  /// Üst bar - Geri, bayrak seçici, başlık, profil
  Widget _buildTopBar(BuildContext context, UserModel? user, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Geri / Home butonu
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Color(0xFF394272),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bayrak seçici
          _buildLanguageSelector(),

          // Başlık
          const Expanded(
            child: Text(
              'Challenge',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Profil butonu
          GestureDetector(
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
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: user?.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      isLoggedIn ? Icons.person : Icons.login,
                      size: 20,
                      color: const Color(0xFF6C6FA4),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dil seçici
  Widget _buildLanguageSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLanguageFlag('🇹🇷', 'tr'),
        const SizedBox(width: 8),
        _buildLanguageFlag('🇬🇧', 'en'),
      ],
    );
  }

  Widget _buildLanguageFlag(String flag, String langCode) {
    final isSelected = _selectedLanguage == langCode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = langCode;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFCAB7FF).withValues(alpha:0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFFCAB7FF), width: 2)
              : null,
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

  /// Giriş gerekli ekranı
  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFCAB7FF).withValues(alpha:0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 50,
                color: Color(0xFF6C6FA4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Challenge Modu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Challenge modunu görmek ve oynamak için giriş yapmalısın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6C6FA4),
              ),
            ),
            const SizedBox(height: 32),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Geri Dön',
                style: TextStyle(
                  color: Color(0xFF6C6FA4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Challenge içeriği
  Widget _buildChallengeContent(BuildContext context, UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Kategoriler
          const Text(
            'Kategoriler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryList(user),

          const SizedBox(height: 24),

          // Popüler challenge'lar
          const Text(
            'Popüler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 12),
          _buildPopularChallenges(user),

          const SizedBox(height: 24),

          // Tüm challenge'lar
          const Text(
            'Tümü',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 12),
          _buildAllChallenges(user),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Kategori listesi (yatay scroll)
  Widget _buildCategoryList(UserModel? user) {
    return StreamBuilder<List<CategoryModel>>(
      stream: _challengeService.getCategoriesByLanguage(_selectedLanguage),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = snapshot.data!;

        if (categories.isEmpty) {
          return _buildEmptyState('Kategori bulunamadı');
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == categories.length - 1 ? 0 : 8,
                ),
                child: _buildCategoryCard(categories[index], user),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category, UserModel? user) {
    final access = AccessControlService.checkCategoryAccess(user, category);
    final hasAccess = access.hasAccess;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasAccess
                ? [const Color(0xFFCAB7FF), const Color(0xFFE0D6FF)]
                : [const Color(0xFFE8E8E8), const Color(0xFFF5F5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İkon + Kilit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.iconEmoji ?? '🎵',
                  style: const TextStyle(fontSize: 28),
                ),
                if (!hasAccess)
                  const Icon(
                    Icons.lock,
                    size: 18,
                    color: Color(0xFF888888),
                  ),
              ],
            ),
            const Spacer(),
            // Başlık
            Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: hasAccess
                    ? const Color(0xFF394272)
                    : const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 4),
            // Challenge sayısı
            Text(
              '${category.challengeCount} challenge',
              style: TextStyle(
                fontSize: 12,
                color: hasAccess
                    ? const Color(0xFF6C6FA4)
                    : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Popüler challenge'lar
  Widget _buildPopularChallenges(UserModel? user) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getPopularChallenges(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data!
            .where((c) => c.language == _selectedLanguage)
            .toList();

        if (challenges.isEmpty) {
          return _buildEmptyState('Bu dilde popüler challenge yok');
        }

        return Column(
          children: challenges.map((c) => _buildChallengeCard(c, user)).toList(),
        );
      },
    );
  }

  /// Tüm challenge'lar
  Widget _buildAllChallenges(UserModel? user) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getChallengesByLanguage(_selectedLanguage),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('Challenge\'lar yükleniyor...');
        }

        final challenges = snapshot.data!;

        return Column(
          children: challenges.map((c) => _buildChallengeCard(c, user)).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF6C6FA4),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Challenge kartı
  Widget _buildChallengeCard(ChallengeModel challenge, UserModel? user) {
    final access = AccessControlService.checkChallengeAccess(user, challenge);
    final hasAccess = access.hasAccess;

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
            // Emoji / Durum
            Container(
              width: 50,
              height: 50,
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
                        style: const TextStyle(fontSize: 24),
                      )
                    : const Icon(
                        Icons.lock,
                        size: 24,
                        color: Color(0xFF888888),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: TextStyle(
                      fontSize: 16,
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
                        fontSize: 13,
                        color: hasAccess
                            ? const Color(0xFF6C6FA4)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildChip(
                        '${challenge.totalSongs} şarkı',
                        hasAccess,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        challenge.difficultyLabel,
                        hasAccess,
                      ),
                      if (challenge.isFree) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ücretsiz',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Ok ikonu
            Icon(
              Icons.chevron_right,
              color: hasAccess
                  ? const Color(0xFF6C6FA4)
                  : const Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, bool hasAccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: hasAccess
            ? const Color(0xFFF5F5FF)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: hasAccess
              ? const Color(0xFF6C6FA4)
              : const Color(0xFF999999),
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
}
