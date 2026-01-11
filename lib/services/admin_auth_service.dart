import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  AdminAuthService._();
  static final instance = AdminAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool? _cachedAdminStatus;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  // Admin whitelist - Cloud Functions olmadan da çalışır
  static const _adminEmails = ['talhayildiz94@gmail.com'];

  /// Check if current user is admin using Firebase Custom Claims
  Future<bool> isAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _cachedAdminStatus = false;
      return false;
    }

    final email = user.email?.toLowerCase().trim();
    final isWhitelisted = _adminEmails.contains(email);

    // Whitelist'te ise HER ZAMAN admin olarak kabul et - diğer kontrolleri atla
    if (isWhitelisted) {
      _cachedAdminStatus = true;
      _cacheTime = DateTime.now();
      return true;
    }

    // Check cache first (unless force refresh) - sadece whitelist dışındakiler için
    if (!forceRefresh &&
        _cachedAdminStatus != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedAdminStatus!;
    }

    try {
      // Get fresh token to check claims
      final idTokenResult = await user.getIdTokenResult(forceRefresh);
      final claims = idTokenResult.claims;

      if (claims != null && claims['admin'] == true) {
        _cachedAdminStatus = true;
        _cacheTime = DateTime.now();
        return true;
      }

      // Try cloud function if available
      try {
        final result = await _functions.httpsCallable('checkAdminStatus').call();
        final isAdminResult = result.data['isAdmin'] == true;

        if (result.data['reason'] == 'whitelisted_auto_granted') {
          await user.getIdTokenResult(true);
        }

        _cachedAdminStatus = isAdminResult;
        _cacheTime = DateTime.now();
        return isAdminResult;
      } catch (_) {
        // Cloud function not available
      }

      _cachedAdminStatus = false;
      _cacheTime = DateTime.now();
      return false;
    } catch (e) {
      _cachedAdminStatus = false;
      _cacheTime = DateTime.now();
      return false;
    }
  }

  /// Set admin claim for another user (requires admin privilege)
  Future<({bool success, String message})> setAdminClaim(String email) async {
    try {
      final result = await _functions.httpsCallable('setAdminClaim').call({
        'email': email,
      });
      final String msg = (result.data['message'] ?? 'Basarili').toString();
      return (
        success: result.data['success'] == true,
        message: msg,
      );
    } on FirebaseFunctionsException catch (e) {
      return (success: false, message: e.message ?? 'Hata olustu');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  /// Remove admin claim from another user (requires admin privilege)
  Future<({bool success, String message})> removeAdminClaim(String email) async {
    try {
      final result = await _functions.httpsCallable('removeAdminClaim').call({
        'email': email,
      });
      final String msg = (result.data['message'] ?? 'Basarili').toString();
      return (
        success: result.data['success'] == true,
        message: msg,
      );
    } on FirebaseFunctionsException catch (e) {
      return (success: false, message: e.message ?? 'Hata olustu');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  /// Get admin dashboard stats from Cloud Function
  Future<Map<String, dynamic>?> getAdminStats() async {
    try {
      final result = await _functions.httpsCallable('getAdminStats').call();
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return null;
    }
  }

  /// Clear cached admin status (call on logout)
  void clearCache() {
    _cachedAdminStatus = null;
    _cacheTime = null;
  }
}
