import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Koleksiyon referansı
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  // Mevcut kullanıcı stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  // Mevcut kullanıcı ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Email/Şifre ile kayıt ol
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Firebase Auth'da kullanıcı oluştur
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Kullanıcı oluşturulamadı');
      }

      // Kullanıcı adını güncelle
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Firestore'da kullanıcı dokümanı oluştur
      final userModel = UserModel.newUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
      );

      await _usersCollection.doc(credential.user!.uid).set(userModel.toFirestore());

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Email/Şifre ile giriş yap
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Giriş başarısız');
      }

      // Firestore'dan kullanıcı bilgilerini al ve güncelle
      final userModel = await _getOrCreateUserDocument(credential.user!);
      
      // Son giriş zamanını güncelle
      await _updateLastLogin(credential.user!.uid);

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Beklenmeyen bir hata oluştu: $e');
    }
  }

  /// Google ile giriş yap
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Google Sign-In akışını başlat
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.failure('Google girişi iptal edildi');
      }

      // Google kimlik bilgilerini al
      final googleAuth = await googleUser.authentication;

      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return AuthResult.failure('Google ile giriş başarısız');
      }

      // Firestore'da kullanıcı dokümanını al veya oluştur
      final userModel = await _getOrCreateUserDocument(userCredential.user!);
      
      // Son giriş zamanını güncelle
      await _updateLastLogin(userCredential.user!.uid);

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Google girişi sırasında hata: $e');
    }
  }

  /// Apple ile giriş yap (iOS için)
  Future<AuthResult> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final userCredential = await _auth.signInWithProvider(appleProvider);

      if (userCredential.user == null) {
        return AuthResult.failure('Apple ile giriş başarısız');
      }

      final userModel = await _getOrCreateUserDocument(userCredential.user!);
      await _updateLastLogin(userCredential.user!.uid);

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Apple girişi sırasında hata: $e');
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Şifre sıfırlama emaili gönder
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null, message: 'Şifre sıfırlama emaili gönderildi');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Email gönderilemedi: $e');
    }
  }

  /// Mevcut kullanıcının Firestore verilerini al
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Kullanıcı verilerini stream olarak dinle
  Stream<UserModel?> userModelStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Kullanıcı profilini güncelle
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? preferredLanguage,
  }) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        updates['displayName'] = displayName;
        await currentUser?.updateDisplayName(displayName);
      }
      
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await currentUser?.updatePhotoURL(photoUrl);
      }
      
      if (preferredLanguage != null) {
        updates['preferredLanguage'] = preferredLanguage;
      }

      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Oyun istatistiklerini güncelle
  Future<void> updateGameStats({
    required int songsFound,
    required int timePlayed,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _usersCollection.doc(uid).update({
        'totalSongsFound': FieldValue.increment(songsFound),
        'totalGamesPlayed': FieldValue.increment(1),
        'totalTimePlayed': FieldValue.increment(timePlayed),
      });
    } catch (e) {
      // Hata sessizce geç
    }
  }

  /// Reklam izleyerek kelime değiştirme hakkı ekle
  Future<bool> addFreeWordChanges(int count) async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      await _usersCollection.doc(uid).update({
        'wordChangeCredits': FieldValue.increment(count),
        'lastAdWatched': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Kelime değiştirme hakkı kullan
  Future<bool> useFreeWordChange() async {
    final uid = currentUserId;
    if (uid == null) return false;

    try {
      final doc = await _usersCollection.doc(uid).get();
      final currentChanges = doc.data()?['wordChangeCredits'] ?? 0;
      
      if (currentChanges <= 0) return false;

      await _usersCollection.doc(uid).update({
        'wordChangeCredits': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ PRIVATE HELPERS ============

  /// Firestore'da kullanıcı dokümanını al veya oluştur
  Future<UserModel> _getOrCreateUserDocument(User firebaseUser) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // Yeni kullanıcı oluştur
    final userModel = UserModel.newUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
    );

    await docRef.set(userModel.toFirestore());
    return userModel;
  }

  /// Son giriş zamanını güncelle
  Future<void> _updateLastLogin(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Firebase Auth hata mesajlarını Türkçeleştir
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanılıyor';
      case 'invalid-email':
        return 'Geçersiz email adresi';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor';
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter olmalı)';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'user-not-found':
        return 'Bu email ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      case 'invalid-credential':
        return 'Email veya şifre hatalı';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}

/// Auth işlem sonucu
class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;
  final String? successMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  factory AuthResult.success(UserModel? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      successMessage: message,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
