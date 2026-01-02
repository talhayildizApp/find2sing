import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userSubscription;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _userSubscription?.cancel();
      notifyListeners();
    } else {
      // Kullanıcı verilerini dinlemeye başla
      _userSubscription?.cancel();
      _userSubscription = _authService.userModelStream(firebaseUser.uid).listen(
        (userModel) {
          _user = userModel;
          _status = AuthStatus.authenticated;
          notifyListeners();
        },
        onError: (e) {
          _status = AuthStatus.error;
          _errorMessage = 'Kullanıcı verileri yüklenemedi';
          notifyListeners();
        },
      );
    }
  }

  /// Email ile kayıt ol
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Email ile giriş yap
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Google ile giriş yap
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithGoogle();

    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Apple ile giriş yap
  Future<bool> signInWithApple() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithApple();

    if (result.isSuccess) {
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authService.signOut();

    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Şifre sıfırlama emaili gönder
  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;
    
    final result = await _authService.sendPasswordResetEmail(email);
    
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
    }
    
    return result.isSuccess;
  }

  /// Profil güncelle
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? preferredLanguage,
  }) async {
    final success = await _authService.updateUserProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      preferredLanguage: preferredLanguage,
    );

    if (success) {
      // Güncelleme stream üzerinden otomatik gelecek
      return true;
    }
    
    _errorMessage = 'Profil güncellenemedi';
    notifyListeners();
    return false;
  }

  /// Oyun istatistiklerini güncelle
  Future<void> updateGameStats({
    required int songsFound,
    required int timePlayed,
  }) async {
    await _authService.updateGameStats(
      songsFound: songsFound,
      timePlayed: timePlayed,
    );
  }

  /// Reklam izleyerek kelime değiştirme hakkı ekle
  Future<bool> addFreeWordChanges(int count) async {
    return await _authService.addFreeWordChanges(count);
  }

  /// Kelime değiştirme hakkı kullan
  Future<bool> useFreeWordChange() async {
    return await _authService.useFreeWordChange();
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Kullanıcı verilerini yenile
  Future<void> refreshUser() async {
    final userModel = await _authService.getCurrentUserModel();
    if (userModel != null) {
      _user = userModel;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
