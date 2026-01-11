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
import '../premium/premium_screen.dart';
import 'challenge_detail_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final ChallengeService _challengeService = ChallengeService();
  String _selectedLanguage = 'tr';
  String? _selectedCategoryId;
  String? _selectedCategoryTitle;
  CategoryModel? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isLoggedIn = authProvider.isAuthenticated;

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
            child: Column(
              children: [
                _buildHeader(context, user, isLoggedIn),
                Expanded(
                  child: !isLoggedIn
                      ? _buildLoginRequired(context)
                      : _buildMainContent(context, user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HEADER - Kompakt tasarım
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, UserModel? user, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back button
          _buildCircleButton(
            onTap: () {
              if (_selectedCategoryId != null) {
                setState(() {
                  _selectedCategoryId = null;
                  _selectedCategoryTitle = null;
                  _selectedCategory = null;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Color(0xFF394272),
            ),
          ),

          const Spacer(),

          // Language selector - compact chip style
          if (_selectedCategoryId == null) _buildCompactLanguageSelector(),

          const SizedBox(width: 10),

          // Profile button
          _buildCircleButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isLoggedIn ? const ProfileScreen() : const LoginScreen(),
                ),
              );
            },
            child: user?.photoUrl != null
                ? ClipOval(
                    child: Image.network(user!.photoUrl!, width: 38, height: 38, fit: BoxFit.cover),
                  )
                : Icon(
                    isLoggedIn ? Icons.person : Icons.login_rounded,
                    size: 18,
                    color: const Color(0xFF6C6FA4),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _selectedLanguage = 'tr';
              _selectedCategoryId = null;
              _selectedCategoryTitle = null;
              _selectedCategory = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedLanguage == 'tr'
                    ? const Color(0xFFCAB7FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🇹🇷', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() {
              _selectedLanguage = 'en';
              _selectedCategoryId = null;
              _selectedCategoryTitle = null;
              _selectedCategory = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedLanguage == 'en'
                    ? const Color(0xFFCAB7FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🇬🇧', style: TextStyle(fontSize: 16)),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF394272).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
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
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF394272).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFCAB7FF), Color(0xFFE8DFFF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Challenge Modu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF394272)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Oynamak için giriş yap',
                style: TextStyle(fontSize: 14, color: Color(0xFF6C6FA4)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCAB7FF),
                    foregroundColor: const Color(0xFF394272),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
  Widget _buildMainContent(BuildContext context, UserModel? user) {
    if (_selectedCategoryId != null) {
      return _buildChallengeList(user);
    }
    return _buildCategoryView(user);
  }

  // ─────────────────────────────────────────────────────────────────
  // KATEGORİ GÖRÜNÜMÜ - Kompakt Liste Tasarımı
  // ─────────────────────────────────────────────────────────────────
  Widget _buildCategoryView(UserModel? user) {
    return StreamBuilder<List<CategoryModel>>(
      stream: _challengeService.getCategoriesByLanguage(_selectedLanguage),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          debugPrint('Category load error: ${snapshot.error}');
          return _buildErrorState('Hata: ${snapshot.error}');
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return _buildEmptyCategoryState();
        }

        return Column(
          children: [
            // Öne Çıkanlar - Hero Section (scroll edilmez, üstte sabit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSectionHeader('Öne Çıkanlar', icon: '🔥'),
                  const SizedBox(height: 12),
                  _buildFeaturedChallenges(user),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Kategoriler - Gradient arka planlı, alt kısma kadar uzanan alan
            _buildCategoriesSection(categories, user),
          ],
        );
      },
    );
  }

  // Kategoriler bölümü - Gradient arka planlı scroll edilebilir alan
  Widget _buildCategoriesSection(List<CategoryModel> categories, UserModel? user) {
    final isPremium = user?.isPremium ?? false;

    // Kilitli kategorilerin toplam fiyatını hesapla (paket fiyatı ile)
    final lockedCategories = categories.where((cat) {
      final access = AccessControlService.checkCategoryAccess(user, cat);
      return !access.hasAccess;
    }).toList();
    final totalPrice = lockedCategories.fold<double>(
      0,
      (sum, cat) => sum + cat.packagePrice,
    );

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.75),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('📂', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tüm Kategoriler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF394272),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categories.length} kategori',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C6FA4),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scroll edilebilir kategori listesi
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryListItem(categories[index], user);
                },
              ),
            ),

            // Premium Al butonu - sadece premium değilse ve kilitli kategori varsa göster
            if (!isPremium && lockedCategories.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PremiumScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCAB7FF), Color(0xFFB19CD9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCAB7FF).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              totalPrice > 0
                                  ? 'Tümüne Eriş - \$${totalPrice.toStringAsFixed(2)}'
                                  : 'Premium\'a Yükselt',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Kategori gradient renkleri
  List<Color> _getCategoryGradient(String title) {
    final t = title.toLowerCase();
    if (t.contains('pop') || t.contains('hit')) {
      return [const Color(0xFFFF6B8A), const Color(0xFFFF8E9E)];
    } else if (t.contains('rock') || t.contains('metal')) {
      return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    } else if (t.contains('slow') || t.contains('acoustic') || t.contains('arabesk')) {
      return [const Color(0xFF11998e), const Color(0xFF38ef7d)];
    } else if (t.contains('90') || t.contains('80') || t.contains('nostalji')) {
      return [const Color(0xFFf093fb), const Color(0xFFf5576c)];
    } else if (t.contains('rap') || t.contains('hip')) {
      return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
    } else {
      return [const Color(0xFFCAB7FF), const Color(0xFFE8DFFF)];
    }
  }

  Widget _buildCategoryListItem(CategoryModel category, UserModel? user) {
    final access = AccessControlService.checkCategoryAccess(user, category);
    final hasAccess = access.hasAccess;
    final gradient = _getCategoryGradient(category.title);

    // Challenge sayısını real-time olarak al (categoryId bazlı)
    return StreamBuilder<int>(
      stream: _challengeService.getChallengeCountByCategory(category.id),
      builder: (context, snapshot) {
        final challengeCount = snapshot.data ?? category.challengeCount;
        final hasChallenge = challengeCount > 0;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategoryId = category.id;
              _selectedCategoryTitle = category.title;
              _selectedCategory = category;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                    _selectedCategoryTitle = category.title;
                    _selectedCategory = category;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Gradient Icon Container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: hasAccess ? gradient : [const Color(0xFFBDBDBD), const Color(0xFFE0E0E0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (hasAccess ? gradient[0] : const Color(0xFFBDBDBD)).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            category.iconEmoji ?? '🎵',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: hasAccess ? const Color(0xFF2D3142) : const Color(0xFF9E9E9E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (hasChallenge)
                                  _buildInfoChip(
                                    '$challengeCount challenge',
                                    gradient[0],
                                    Icons.music_note_rounded,
                                  )
                                else
                                  _buildInfoChip(
                                    'Yakında',
                                    const Color(0xFFFF9800),
                                    Icons.schedule_rounded,
                                  ),
                                if (!hasAccess) ...[
                                  const SizedBox(width: 8),
                                  if (category.packagePrice > 0)
                                    _buildPriceChip(category.packagePrice)
                                  else
                                    _buildInfoChip(
                                      'Premium',
                                      const Color(0xFFFFB300),
                                      Icons.workspace_premium_rounded,
                                    ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (hasAccess ? gradient[0] : const Color(0xFFBDBDBD)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          hasAccess ? Icons.arrow_forward_ios_rounded : Icons.lock_rounded,
                          color: hasAccess ? gradient[0] : const Color(0xFFBDBDBD),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(double priceUsd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '\$${priceUsd.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFeaturedChallenges(UserModel? user) {
    return StreamBuilder<List<CategoryModel>>(
      stream: _challengeService.getCategoriesByLanguage(_selectedLanguage),
      builder: (context, categorySnapshot) {
        // Kategorileri map olarak tut
        final categoryMap = <String, CategoryModel>{};
        if (categorySnapshot.hasData) {
          for (final cat in categorySnapshot.data!) {
            categoryMap[cat.id] = cat;
          }
        }

        return StreamBuilder<List<ChallengeModel>>(
          stream: _challengeService.getFeaturedChallenges(limit: 10),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildHeroLoadingState();
            }

            final challenges = snapshot.data!
                .where((c) => c.language == _selectedLanguage)
                .take(5)
                .toList();

            if (challenges.isEmpty) {
              return _buildEmptyHeroState();
            }

            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  final category = categoryMap[challenge.categoryId];
                  debugPrint('🔍 Hero Challenge: ${challenge.title}');
                  debugPrint('   categoryId: ${challenge.categoryId}');
                  debugPrint('   category found: ${category != null}');
                  debugPrint('   category title: ${category?.title}');
                  debugPrint('   category priceUsd: ${category?.priceUsd}');
                  debugPrint('   category packagePrice: ${category?.packagePrice}');
                  debugPrint('   challenge priceUsd: ${challenge.priceUsd}');
                  debugPrint('   categoryMap keys: ${categoryMap.keys.toList()}');
                  return _buildHeroChallengeCard(challenge, user, index, category);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroChallengeCard(ChallengeModel challenge, UserModel? user, int index, CategoryModel? category) {
    final access = AccessControlService.checkChallengeAccess(user, challenge);
    final hasAccess = access.hasAccess;

    // Gradient renkleri - her kart için farklı
    final gradients = [
      [const Color(0xFFFF6B8A), const Color(0xFFFF8E53)],
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFFFFB347), const Color(0xFFFFCC33)],
    ];
    final gradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChallengeDetailScreen(challenge: challenge)),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasAccess ? gradient : [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (hasAccess ? gradient[0] : const Color(0xFF9E9E9E)).withValues(alpha: 0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Pattern overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: _PatternPainter(),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji büyük
                  Text(
                    challenge.type == ChallengeType.artist ? '🎤' : '🎵',
                    style: const TextStyle(fontSize: 36),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Info row
                  Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.totalSongs} şarkı',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          challenge.difficultyLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Kategori bilgisi
                  if (category != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          category.iconEmoji ?? '📁',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            category.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Lock overlay with price
            if (!hasAccess)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          // Challenge fiyatı varsa onu göster, yoksa kategori fiyatını göster
                          if (challenge.priceUsd > 0)
                            Text(
                              '\$${challenge.priceUsd.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          else if (category != null && category.packagePrice > 0)
                            Text(
                              '\$${category.packagePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroLoadingState() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyHeroState() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCAB7FF), Color(0xFFE8DFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAB7FF).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(painter: _PatternPainter()),
            ),
          ),
          // Content
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rocket_launch_rounded, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Popüler Challenge\'lar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Yakında burada olacak! 🚀',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
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
  // CHALLENGE LİSTESİ
  // ─────────────────────────────────────────────────────────────────
  Widget _buildChallengeList(UserModel? user) {
    return StreamBuilder<List<ChallengeModel>>(
      stream: _challengeService.getChallengesByCategory(_selectedCategoryId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Challenge\'lar yüklenemedi');
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return _buildEmptyChallengeState();
        }

        final category = _selectedCategory;
        final hasAccess = category == null ||
            AccessControlService.checkCategoryAccess(user, category).hasAccess;

        return Column(
          children: [
            // Üst kısım - Breadcrumb ve Kategori Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildBreadcrumb(),
                  const SizedBox(height: 16),
                  if (category != null) _buildCategoryHeader(category, hasAccess),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Challenge'lar bölümü - Beyaz arka planlı, aşağıya kadar uzanan
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.75),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('🎵', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Challenge'lar",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF394272),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${challenges.length} challenge',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C6FA4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Challenge listesi
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: challenges.length,
                        itemBuilder: (context, index) {
                          return _buildChallengeCard(challenges[index], user);
                        },
                      ),
                    ),

                    // Alt buton - Kategori fiyatını göster
                    if (!hasAccess && category != null)
                      Builder(
                        builder: (context) {
                          // Gerçek challenge sayısından fiyat hesapla
                          // Firestore'daki discountPercent değerini kullan
                          final challengeCount = challenges.length;
                          final discount = category.discountPercent / 100.0;
                          final calculatedPrice = challengeCount *
                              CategoryModel.defaultChallengePrice *
                              (1 - discount);
                          // Eğer kategori fiyatı varsa onu kullan, yoksa hesaplanmış fiyatı kullan
                          final displayPrice = category.priceUsd > 0
                              ? category.priceUsd
                              : calculatedPrice;

                          return Container(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kategori satın alma yakında!'),
                                      backgroundColor: Color(0xFFFFB300),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.lock_open_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Kategoriyi Aç - \$${displayPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(CategoryModel category, bool hasAccess) {
    final gradient = _getCategoryGradient(category.title);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAccess
              ? [gradient[0].withValues(alpha: 0.15), gradient[1].withValues(alpha: 0.1)]
              : [const Color(0xFFE0E0E0), const Color(0xFFF5F5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAccess
              ? gradient[0].withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji/Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasAccess ? gradient : [const Color(0xFFBDBDBD), const Color(0xFFE0E0E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (hasAccess ? gradient[0] : Colors.grey).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.iconEmoji ?? '🎵',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: hasAccess ? const Color(0xFF2D3142) : const Color(0xFF757575),
                      ),
                    ),
                    if (category.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasAccess ? const Color(0xFF6C6FA4) : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Kilitli bilgisi + Premium butonu (erişim yoksa)
          if (!hasAccess) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
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
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Premium ile tüm içeriklere eriş',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF6C6FA4).withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Premium butonu
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PremiumScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Premium\'a Yükselt',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildBreadcrumb() {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategoryId = null;
        _selectedCategoryTitle = null;
        _selectedCategory = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_ios_rounded, size: 14, color: Color(0xFF6C6FA4)),
            const SizedBox(width: 6),
            const Text(
              'Kategoriler',
              style: TextStyle(fontSize: 13, color: Color(0xFF6C6FA4), fontWeight: FontWeight.w500),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('/', style: TextStyle(color: Color(0xFF6C6FA4))),
            ),
            Text(
              _selectedCategoryTitle ?? '',
              style: const TextStyle(fontSize: 13, color: Color(0xFF394272), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, UserModel? user) {
    final access = AccessControlService.checkChallengeAccess(user, challenge);
    final hasAccess = access.hasAccess;

    ChallengeCardType cardType;
    final difficulty = challenge.difficulty;

    if (difficulty == ChallengeDifficulty.hard) {
      cardType = ChallengeCardType.realChallenge;
    } else if (difficulty == ChallengeDifficulty.easy) {
      cardType = ChallengeCardType.relax;
    } else {
      cardType = ChallengeCardType.standard;
    }

    // Fiyat belirleme: challenge fiyatı > 0 ise onu, değilse kategori fiyatını kullan
    double? displayPrice;
    if (!hasAccess && !challenge.isFree) {
      if (challenge.priceUsd > 0) {
        displayPrice = challenge.priceUsd;
      } else if (_selectedCategory != null && _selectedCategory!.packagePrice > 0) {
        displayPrice = _selectedCategory!.packagePrice;
      }
    }

    return ChallengeCard(
      title: challenge.title,
      emoji: challenge.type == ChallengeType.artist ? '🎤' : '🎵',
      type: hasAccess ? cardType : ChallengeCardType.standard,
      isLocked: !hasAccess,
      priceUsd: displayPrice,
      songCount: challenge.totalSongs,
      difficulty: challenge.difficultyLabel,
      subtitle: challenge.isFree ? 'Ücretsiz' : '',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChallengeDetailScreen(challenge: challenge)),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // YARDIMCI WİDGETLAR
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {int? count, String? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF394272),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6C6FA4),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFCAB7FF), strokeWidth: 3),
    );
  }


  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFFF6B6B)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF394272)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {}),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.95),
                const Color(0xFFF8F5FF).withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCAB7FF).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated emoji stack
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCAB7FF), Color(0xFFE8DFFF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCAB7FF).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🎵', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _selectedLanguage == 'tr' ? 'Çok Yakında!' : 'Coming Soon!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLanguage == 'tr'
                    ? 'Yeni kategoriler ekleniyor...\nHeyecanla bekliyoruz! 🚀'
                    : 'New categories are being added...\nStay tuned! 🚀',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6FA4),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChallengeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.95),
                const Color(0xFFFFF5F5).withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B8A).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B8A), Color(0xFFFF8E9E)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B8A).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎤', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'İlk Challenge Senin Olsun!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu kategoride henüz challenge yok.\nYakında eklenecek! ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C6FA4),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pattern painter for hero cards
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Subtle circles pattern
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.2 + i * 0.2), size.height * 0.3),
        20 + i * 10.0,
        paint,
      );
    }

    // Music note shapes
    final notePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 30, notePaint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.7), 25, notePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
