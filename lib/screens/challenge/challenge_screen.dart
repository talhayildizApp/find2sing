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
                // Üst bar - Bayrak seçici + Başlık + Profil
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

  /// Üst bar - Bayrak seçici, başlık, profil
  Widget _buildTopBar(BuildContext context, UserModel? user, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Bayrak seçici
          _buildLanguageSelector(),

          const SizedBox(width: 12),

          // Başlık
          const Expanded(
            child: Text(
              'Challenge',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

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
              child: user?.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      isLoggedIn ? Icons.person : Icons.login,
                      color: const Color(0xFF394272),
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bayrak seçici
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFlagButton('🇹🇷', 'tr'),
          const SizedBox(width: 4),
          _buildFlagButton('🇬🇧', 'en'),
        ],
      ),
    );
  }

  Widget _buildFlagButton(String flag, String langCode) {
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
              ? const Color(0xFFCAB7FF).withValues(alpha: 0.3)
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
                color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
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
          _buildCategoriesSection(user),

          const SizedBox(height: 24),

          // Ücretsiz Challenge'lar
          _buildSectionTitle('🎁 Ücretsiz Challenge\'lar'),
          const SizedBox(height: 12),
          _buildFreeChallenges(user),

          const SizedBox(height: 24),

          // Popüler Challenge'lar
          _buildSectionTitle('🔥 Popüler'),
          const SizedBox(height: 12),
          _buildPopularChallenges(user),

          const SizedBox(height: 24),

          // Tüm Challenge'lar
          _buildSectionTitle('📋 Tüm Challenge\'lar'),
          const SizedBox(height: 12),
          _buildAllChallenges(user),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF394272),
      ),
    );
  }

  /// Kategoriler yatay scroll
  Widget _buildCategoriesSection(UserModel? user) {
    return StreamBuilder<List<CategoryModel>>(
      stream: _challengeService.getCategories(language: _selectedLanguage),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyCategories();
        }

        final categories = snapshot.data!;

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildCategoryCard(categories[index], user);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyCategories() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'Henüz kategori yok\nYakında eklenecek!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6C6FA4),
            fontSize: 14,
          ),
        ),
      ),
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İkon veya emoji
            Text(
              category.iconEmoji ?? '🎵',
              style: const TextStyle(fontSize: 28),
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
                    : const Color(0xFFAAAAAA),
              ),
            ),
            const SizedBox(height: 8),
            // Fiyat veya durum
            if (hasAccess)
              const Text(
                '✓ Açık',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              )
            else
              Text(
                '\$${category.priceUsd.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF9800),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Ücretsiz challenge'lar
  Widget _buildFreeChallenges(UserModel? user) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getFreeChallenges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final challenges = snapshot.data!
            .where((c) => c.language == _selectedLanguage)
            .toList();

        if (challenges.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: challenges
              .map((c) => _buildChallengeCard(c, user, isFree: true))
              .toList(),
        );
      },
    );
  }

  /// Popüler challenge'lar
  Widget _buildPopularChallenges(UserModel? user) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getPopularChallenges(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('Popüler challenge\'lar yükleniyor...');
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
        color: Colors.white.withValues(alpha: 0.8),
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
  Widget _buildChallengeCard(
    ChallengeModel challenge,
    UserModel? user, {
    bool isFree = false,
  }) {
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
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol ikon/durum
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(hasAccess, isFree).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _getStatusIcon(hasAccess, isFree),
              ),
            ),
            const SizedBox(width: 14),
            // Orta - Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF394272),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${challenge.totalSongs} şarkı',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C6FA4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(challenge.difficulty),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          challenge.difficultyLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // İlerleme çubuğu (eğer başlanmışsa)
                  if (hasAccess) ...[
                    const SizedBox(height: 8),
                    _buildProgressIndicator(user, challenge),
                  ],
                ],
              ),
            ),
            // Sağ - Fiyat veya durum
            _buildPriceOrStatus(hasAccess, isFree, challenge.priceUsd),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(bool hasAccess, bool isFree) {
    if (isFree) return const Color(0xFF4CAF50);
    if (hasAccess) return const Color(0xFFCAB7FF);
    return const Color(0xFFFF9800);
  }

  Widget _getStatusIcon(bool hasAccess, bool isFree) {
    if (isFree) {
      return const Text('🎁', style: TextStyle(fontSize: 24));
    }
    if (hasAccess) {
      return const Icon(Icons.play_arrow, color: Color(0xFF6C6FA4), size: 28);
    }
    return const Icon(Icons.lock, color: Color(0xFFFF9800), size: 24);
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

  Widget _buildPriceOrStatus(bool hasAccess, bool isFree, double price) {
    if (isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'ÜCRETSİZ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    if (hasAccess) {
      return const Icon(
        Icons.chevron_right,
        color: Color(0xFF6C6FA4),
        size: 28,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB958),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '\$${price.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8C5A1F),
        ),
      ),
    );
  }

  /// İlerleme göstergesi
  Widget _buildProgressIndicator(UserModel? user, ChallengeModel challenge) {
    // TODO: Gerçek ilerleme verisini çek
    // Şimdilik placeholder
    return StreamBuilder<ChallengeProgressModel?>(
      stream: user != null
          ? _challengeService.getChallengeProgress(user.uid, challenge.id)
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;
        final percent = progress.progressPercent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFCAB7FF),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percent.toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C6FA4),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
