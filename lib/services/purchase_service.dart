import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';
import 'pricing_service.dart';

// Platform-specific imports
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// Satın alma türleri
enum PurchaseType {
  challenge,
  category,
  premiumMonthly,
  premiumYearly,
}

/// Satın alma UI durumu (in_app_purchase'ın PurchaseStatus'undan farklı)
enum PurchaseUIStatus {
  idle,
  loading,
  purchasing,
  success,
  failed,
  restored,
}

/// In-App Purchase Servisi
/// 
/// Ürünler:
/// - Tekil Challenge: $0.99 (consumable değil)
/// - Kategori: Dinamik fiyat (consumable değil)
/// - Premium Aylık: $4.99/ay (subscription)
/// - Premium Yıllık: $39.99/yıl (subscription)
class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isAvailable = false;
  bool _isInitialized = false;
  PurchaseUIStatus _status = PurchaseUIStatus.idle;
  String? _errorMessage;
  
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];

  // ==================== PRODUCT IDS ====================
  
  // Premium Subscription IDs
  static const String premiumMonthlyId = 'find2sing_premium_monthly';
  static const String premiumYearlyId = 'find2sing_premium_yearly';
  
  // Challenge/Category prefix (dinamik ID'ler için)
  static const String challengePrefix = 'find2sing_challenge_';
  static const String categoryPrefix = 'find2sing_category_';

  // Tüm subscription ID'leri
  static const Set<String> _subscriptionIds = {
    premiumMonthlyId,
    premiumYearlyId,
  };

  // ==================== GETTERS ====================

  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  PurchaseUIStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isLoading => _status == PurchaseUIStatus.loading || _status == PurchaseUIStatus.purchasing;

  // ==================== INITIALIZATION ====================

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isAvailable = await _iap.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('In-app purchases not available');
        return;
      }

      // Platform-specific configuration for iOS
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(_PaymentQueueDelegate());
      }

      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseDone,
        onError: _onPurchaseError,
      );

      _isInitialized = true;
      notifyListeners();

      debugPrint('PurchaseService initialized successfully');
    } catch (e) {
      debugPrint('PurchaseService initialize error: $e');
    }
  }

  /// Ürünleri yükle
  Future<void> loadProducts(Set<String> productIds) async {
    if (!_isAvailable) return;

    _status = PurchaseUIStatus.loading;
    notifyListeners();

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      _status = PurchaseUIStatus.idle;
      notifyListeners();

      debugPrint('Loaded ${_products.length} products');
    } catch (e) {
      _status = PurchaseUIStatus.failed;
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint('Load products error: $e');
    }
  }

  /// Premium ürünlerini yükle
  Future<void> loadPremiumProducts() async {
    await loadProducts(_subscriptionIds);
  }

  /// Challenge ürünü yükle
  Future<ProductDetails?> loadChallengeProduct(String challengeId) async {
    final productId = '$challengePrefix$challengeId';
    await loadProducts({productId});
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      debugPrint('Product not found: $productId');
      return null;
    }
  }

  /// Kategori ürünü yükle
  Future<ProductDetails?> loadCategoryProduct(String categoryId) async {
    final productId = '$categoryPrefix$categoryId';
    await loadProducts({productId});
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      debugPrint('Product not found: $productId');
      return null;
    }
  }

  // ==================== PURCHASE METHODS ====================

  /// Satın alma başlat
  Future<bool> buyProduct(ProductDetails product, {String? userId}) async {
    if (!_isAvailable) {
      _errorMessage = 'In-app purchases not available';
      return false;
    }

    _status = PurchaseUIStatus.purchasing;
    _errorMessage = null;
    notifyListeners();

    // Analytics
    _analytics.logPurchaseStart(
      itemId: product.id,
      itemType: _getProductType(product.id),
      price: double.tryParse(product.rawPrice.toString()) ?? 0,
    );

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      );

      // Subscription vs non-subscription
      if (_subscriptionIds.contains(product.id)) {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _status = PurchaseUIStatus.failed;
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint('Buy product error: $e');
      return false;
    }
  }

  /// Premium aylık satın al
  Future<bool> buyPremiumMonthly(String userId) async {
    await loadPremiumProducts();
    try {
      final product = _products.firstWhere((p) => p.id == premiumMonthlyId);
      return buyProduct(product, userId: userId);
    } catch (e) {
      debugPrint('Premium monthly product not found');
      return false;
    }
  }

  /// Premium yıllık satın al
  Future<bool> buyPremiumYearly(String userId) async {
    await loadPremiumProducts();
    try {
      final product = _products.firstWhere((p) => p.id == premiumYearlyId);
      return buyProduct(product, userId: userId);
    } catch (e) {
      debugPrint('Premium yearly product not found');
      return false;
    }
  }

  /// Challenge satın al
  Future<bool> buyChallenge(String challengeId, String userId) async {
    final product = await loadChallengeProduct(challengeId);
    if (product == null) return false;
    return buyProduct(product, userId: userId);
  }

  /// Kategori satın al
  Future<bool> buyCategory(String categoryId, String userId) async {
    final product = await loadCategoryProduct(categoryId);
    if (product == null) return false;
    return buyProduct(product, userId: userId);
  }

  /// Satın almaları geri yükle
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    _status = PurchaseUIStatus.loading;
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      _status = PurchaseUIStatus.failed;
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint('Restore purchases error: $e');
    }
  }

  // ==================== PURCHASE HANDLERS ====================

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}');

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        _status = PurchaseUIStatus.purchasing;
        notifyListeners();
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Verify and deliver
        final valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await _deliverProduct(purchaseDetails);
          _status = purchaseDetails.status == PurchaseStatus.restored
              ? PurchaseUIStatus.restored
              : PurchaseUIStatus.success;
        } else {
          _status = PurchaseUIStatus.failed;
          _errorMessage = 'Purchase verification failed';
        }
        notifyListeners();
        break;

      case PurchaseStatus.error:
        _status = PurchaseUIStatus.failed;
        _errorMessage = purchaseDetails.error?.message ?? 'Unknown error';
        notifyListeners();
        
        _analytics.logPurchaseFailed(
          itemId: purchaseDetails.productID,
          reason: _errorMessage!,
        );
        break;

      case PurchaseStatus.canceled:
        _status = PurchaseUIStatus.idle;
        notifyListeners();
        break;
    }

    // Complete purchase
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  void _onPurchaseDone() {
    _subscription?.cancel();
  }

  void _onPurchaseError(dynamic error) {
    _status = PurchaseUIStatus.failed;
    _errorMessage = error.toString();
    notifyListeners();
    debugPrint('Purchase stream error: $error');
  }

  // ==================== VERIFICATION & DELIVERY ====================

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Server-side verification with Firebase Functions
    // For now, basic client-side check
    return purchaseDetails.verificationData.localVerificationData.isNotEmpty;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final productId = purchaseDetails.productID;
    final userId = purchaseDetails.purchaseID; // applicationUserName

    debugPrint('Delivering product: $productId');

    try {
      if (productId == premiumMonthlyId) {
        await _activatePremium(userId, const Duration(days: 30));
      } else if (productId == premiumYearlyId) {
        await _activatePremium(userId, const Duration(days: 365));
      } else if (productId.startsWith(challengePrefix)) {
        final challengeId = productId.replaceFirst(challengePrefix, '');
        await _unlockChallenge(userId, challengeId);
      } else if (productId.startsWith(categoryPrefix)) {
        final categoryId = productId.replaceFirst(categoryPrefix, '');
        await _unlockCategory(userId, categoryId);
      }

      // Analytics
      try {
        final product = _products.firstWhere((p) => p.id == productId);
        _analytics.logPurchaseComplete(
          itemId: productId,
          itemType: _getProductType(productId),
          price: double.tryParse(product.rawPrice.toString()) ?? 0,
          currency: product.currencyCode,
        );
      } catch (e) {
        debugPrint('Product not found for analytics: $productId');
      }

      _purchases.add(purchaseDetails);
    } catch (e) {
      debugPrint('Deliver product error: $e');
    }
  }

  Future<void> _activatePremium(String? userId, Duration duration) async {
    if (userId == null) return;

    final expiresAt = DateTime.now().add(duration);
    
    await _firestore.collection('users').doc(userId).update({
      'isPremium': true,
      'premiumExpiresAt': Timestamp.fromDate(expiresAt),
      'tier': UserTier.premium.name,
    });

    debugPrint('Premium activated until: $expiresAt');
  }

  Future<void> _unlockChallenge(String? userId, String challengeId) async {
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'purchasedChallenges': FieldValue.arrayUnion([challengeId]),
      'tier': UserTier.purchased.name,
    });

    debugPrint('Challenge unlocked: $challengeId');
  }

  Future<void> _unlockCategory(String? userId, String categoryId) async {
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'purchasedCategories': FieldValue.arrayUnion([categoryId]),
      'tier': UserTier.purchased.name,
    });

    debugPrint('Category unlocked: $categoryId');
  }

  // ==================== HELPER METHODS ====================

  String _getProductType(String productId) {
    if (productId.startsWith(challengePrefix)) return 'challenge';
    if (productId.startsWith(categoryPrefix)) return 'category';
    if (productId == premiumMonthlyId) return 'premium_monthly';
    if (productId == premiumYearlyId) return 'premium_yearly';
    return 'unknown';
  }

  /// Ürün fiyatını al
  String? getProductPrice(String productId) {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (e) {
      return null;
    }
  }

  /// Premium fiyat bilgisi
  PremiumPriceInfo getPremiumPriceInfo() {
    return PricingService.getPremiumPriceInfo();
  }

  /// Kullanıcının aktif subscription'ı var mı kontrol et
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isPremium = data['isPremium'] ?? false;
      final expiresAt = (data['premiumExpiresAt'] as Timestamp?)?.toDate();

      if (!isPremium) return false;
      if (expiresAt == null) return true;
      return expiresAt.isAfter(DateTime.now());
    } catch (e) {
      debugPrint('Check subscription error: $e');
      return false;
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    _status = PurchaseUIStatus.idle;
    notifyListeners();
  }

  // ==================== DISPOSE ====================

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// iOS Payment Queue Delegate
class _PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}

/// Satın alma sonucu
class PurchaseResult {
  final bool success;
  final String? productId;
  final String? errorMessage;

  PurchaseResult({
    required this.success,
    this.productId,
    this.errorMessage,
  });

  factory PurchaseResult.success(String productId) {
    return PurchaseResult(success: true, productId: productId);
  }

  factory PurchaseResult.failure(String message) {
    return PurchaseResult(success: false, errorMessage: message);
  }
}
