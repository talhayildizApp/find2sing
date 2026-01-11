// lib/screens/premium/premium_screen.dart
//
// Premium üyelik satın alma ekranı.
// Aylık ve yıllık abonelik seçenekleri sunar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _isYearlySelected = true; // Varsayılan olarak yıllık seçili
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    await _purchaseService.loadPremiumProducts();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isPremium = user?.isActivePremium ?? false;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFF8E54E9),
                ],
              ),
            ),
          ),

          // İçerik
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      children: [
                        // Zaten premium ise
                        if (isPremium) ...[
                          _buildAlreadyPremium(),
                        ] else ...[
                          // Premium özellikleri
                          _buildFeatures(),
                          const SizedBox(height: 24),

                          // Plan seçimi
                          _buildPlanSelection(),
                          const SizedBox(height: 24),

                          // Satın al butonu
                          _buildPurchaseButton(),
                          const SizedBox(height: 16),

                          // Restore butonu
                          _buildRestoreButton(),
                          const SizedBox(height: 24),

                          // Yasal bilgiler
                          _buildLegalInfo(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Premium',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAlreadyPremium() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('👑', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Premium Üyesiniz!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tüm premium özelliklerden yararlanabilirsiniz.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFeatureRow('Sınırsız joker hakkı', true),
                _buildFeatureRow('Reklamsız deneyim', true),
                _buildFeatureRow('Tüm challenge\'lara erişim', true),
                _buildFeatureRow('Öncelikli destek', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Crown icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Premium\'a Yükselt',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sınırsız eğlence, reklamsız deneyim!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),

          // Özellikler listesi
          _buildFeatureRow('Sınırsız kelime değiştirme jokeri', true),
          _buildFeatureRow('Sınırsız challenge jokeri', true),
          _buildFeatureRow('Reklamsız oyun deneyimi', true),
          _buildFeatureRow('Oyun sonu reklam yok', true),
          _buildFeatureRow('Öncelikli destek', true),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: included
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              included ? Icons.check : Icons.close,
              size: 14,
              color: included ? const Color(0xFF4CAF50) : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection() {
    final priceInfo = _purchaseService.getPremiumPriceInfo();
    final monthlyPrice = _purchaseService.getProductPrice(PurchaseService.premiumMonthlyId);
    final yearlyPrice = _purchaseService.getProductPrice(PurchaseService.premiumYearlyId);

    return Column(
      children: [
        // Yıllık plan
        GestureDetector(
          onTap: () => setState(() => _isYearlySelected = true),
          child: _buildPlanCard(
            title: 'Yıllık Plan',
            price: yearlyPrice ?? '\$${priceInfo.yearlyPrice.toStringAsFixed(2)}',
            period: '/yıl',
            savings: '2 Ay Bedava!',
            isSelected: _isYearlySelected,
            isPopular: true,
          ),
        ),
        const SizedBox(height: 12),

        // Aylık plan
        GestureDetector(
          onTap: () => setState(() => _isYearlySelected = false),
          child: _buildPlanCard(
            title: 'Aylık Plan',
            price: monthlyPrice ?? '\$${priceInfo.monthlyPrice.toStringAsFixed(2)}',
            period: '/ay',
            savings: null,
            isSelected: !_isYearlySelected,
            isPopular: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    String? savings,
    required bool isSelected,
    required bool isPopular,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Radio indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF667eea) : Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Plan info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF394272) : Colors.white,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EN POPÜLER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF394272),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (savings != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    savings,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF394272) : Colors.white,
                ),
              ),
              Text(
                period,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? const Color(0xFF394272).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handlePurchase,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(
              _isYearlySelected ? 'Yıllık Premium Başlat' : 'Aylık Premium Başlat',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRestore,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Satın Alımları Geri Yükle',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildLegalInfo() {
    return Column(
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Abonelik, onayladığınızda iTunes hesabınızdan tahsil edilir. '
          'Abonelik, mevcut dönemin bitiminden en az 24 saat önce iptal edilmedikçe otomatik olarak yenilenir. '
          'Yenileme ücreti, dönemin bitiminden 24 saat önce hesabınızdan tahsil edilir.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // TODO: Gizlilik politikası sayfası
              },
              child: Text(
                'Gizlilik Politikası',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                // TODO: Kullanım şartları sayfası
              },
              child: Text(
                'Kullanım Şartları',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handlePurchase() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _errorMessage = 'Lütfen önce giriş yapın.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success;
    if (_isYearlySelected) {
      success = await _purchaseService.buyPremiumYearly(user.uid);
    } else {
      success = await _purchaseService.buyPremiumMonthly(user.uid);
    }

    setState(() => _isLoading = false);

    if (!success && mounted) {
      setState(() => _errorMessage = _purchaseService.errorMessage ?? 'Satın alma başarısız oldu.');
    } else if (success && mounted) {
      // Başarılı satın alma
      await context.read<AuthProvider>().refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium üyeliğiniz aktifleştirildi! 🎉'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _purchaseService.restorePurchases();

    setState(() => _isLoading = false);

    if (_purchaseService.status == PurchaseUIStatus.restored && mounted) {
      await context.read<AuthProvider>().refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satın alımlarınız geri yüklendi!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } else if (_purchaseService.status == PurchaseUIStatus.failed && mounted) {
      setState(() => _errorMessage = _purchaseService.errorMessage ?? 'Geri yükleme başarısız oldu.');
    }
  }
}
