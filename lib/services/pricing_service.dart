/// Fiyatlandırma servisi
/// 
/// Fiyat yapısı:
/// - Tekil Challenge: $0.99
/// - Kategori: (Challenge sayısı × $0.99) × 0.60 (%40 indirim)
/// - Premium Aylık: $4.99/ay
/// - Premium Yıllık: $39.99/yıl
class PricingService {
  // Sabit fiyatlar (USD)
  static const double challengePrice = 0.99;
  static const double categoryDiscountPercent = 40.0;
  static const double premiumMonthlyPrice = 4.99;
  static const double premiumYearlyPrice = 39.99;

  // Store Product ID'leri
  static const String premiumMonthlyProductId = 'find2sing_premium_monthly';
  static const String premiumYearlyProductId = 'find2sing_premium_yearly';

  /// Tekil challenge fiyatı
  static double getChallengePrice() {
    return challengePrice;
  }

  /// Kategori fiyatını hesapla
  /// [challengeCount]: Kategorideki challenge sayısı
  static double calculateCategoryPrice(int challengeCount) {
    final originalPrice = challengeCount * challengePrice;
    final discountedPrice = originalPrice * (1 - categoryDiscountPercent / 100);
    return _roundToNine(discountedPrice);
  }

  /// Kategori normal fiyatı (indirim öncesi)
  static double getCategoryOriginalPrice(int challengeCount) {
    return challengeCount * challengePrice;
  }

  /// Tasarruf miktarı
  static double getCategorySavings(int challengeCount) {
    return getCategoryOriginalPrice(challengeCount) - 
           calculateCategoryPrice(challengeCount);
  }

  /// Premium aylık fiyat
  static double getPremiumMonthlyPrice() {
    return premiumMonthlyPrice;
  }

  /// Premium yıllık fiyat
  static double getPremiumYearlyPrice() {
    return premiumYearlyPrice;
  }

  /// Premium yıllık aylık karşılığı
  static double getPremiumYearlyMonthlyEquivalent() {
    return premiumYearlyPrice / 12;
  }

  /// Premium yıllık tasarruf yüzdesi
  static double getPremiumYearlySavingsPercent() {
    final monthlyTotal = premiumMonthlyPrice * 12;
    final savings = monthlyTotal - premiumYearlyPrice;
    return (savings / monthlyTotal) * 100;
  }

  /// Fiyatı .99 ile biten formata yuvarla
  static double _roundToNine(double price) {
    // Örn: 5.94 -> 5.99, 7.19 -> 6.99
    final rounded = price.floor();
    if (price - rounded > 0.5) {
      return rounded + 0.99;
    }
    return (rounded - 1) + 0.99;
  }

  /// Fiyatı formatlı string olarak döndür
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency${price.toStringAsFixed(2)}';
  }

  /// Kategori fiyat bilgisi
  static CategoryPriceInfo getCategoryPriceInfo(int challengeCount) {
    return CategoryPriceInfo(
      originalPrice: getCategoryOriginalPrice(challengeCount),
      discountedPrice: calculateCategoryPrice(challengeCount),
      savings: getCategorySavings(challengeCount),
      discountPercent: categoryDiscountPercent,
      challengeCount: challengeCount,
    );
  }

  /// Premium fiyat bilgisi
  static PremiumPriceInfo getPremiumPriceInfo() {
    return PremiumPriceInfo(
      monthlyPrice: premiumMonthlyPrice,
      yearlyPrice: premiumYearlyPrice,
      yearlyMonthlyEquivalent: getPremiumYearlyMonthlyEquivalent(),
      yearlySavingsPercent: getPremiumYearlySavingsPercent(),
    );
  }
}

/// Kategori fiyat bilgisi
class CategoryPriceInfo {
  final double originalPrice;
  final double discountedPrice;
  final double savings;
  final double discountPercent;
  final int challengeCount;

  CategoryPriceInfo({
    required this.originalPrice,
    required this.discountedPrice,
    required this.savings,
    required this.discountPercent,
    required this.challengeCount,
  });

  String get originalPriceFormatted => '\$${originalPrice.toStringAsFixed(2)}';
  String get discountedPriceFormatted => '\$${discountedPrice.toStringAsFixed(2)}';
  String get savingsFormatted => '\$${savings.toStringAsFixed(2)}';
  String get discountPercentFormatted => '%${discountPercent.toInt()}';
}

/// Premium fiyat bilgisi
class PremiumPriceInfo {
  final double monthlyPrice;
  final double yearlyPrice;
  final double yearlyMonthlyEquivalent;
  final double yearlySavingsPercent;

  PremiumPriceInfo({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlyMonthlyEquivalent,
    required this.yearlySavingsPercent,
  });

  String get monthlyPriceFormatted => '\$${monthlyPrice.toStringAsFixed(2)}/ay';
  String get yearlyPriceFormatted => '\$${yearlyPrice.toStringAsFixed(2)}/yıl';
  String get yearlyMonthlyEquivalentFormatted => '\$${yearlyMonthlyEquivalent.toStringAsFixed(2)}/ay';
  String get yearlySavingsPercentFormatted => '%${yearlySavingsPercent.toInt()}';
}
