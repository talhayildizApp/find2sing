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
      return AuthResult.failure('Kayıt sırasında bir hata oluştu');
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
      return AuthResult.failure('Giriş sırasında bir hata oluştu');
    }
  }

  /// Google ile giriş yap
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Önceki oturumu temizle (app dışına çıkma bug fix)
      await _googleSignIn.signOut();
      
      // Google Sign-In akışını başlat
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Google girişi iptal edildi');
      }

      // Google kimlik bilgilerini al
      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return AuthResult.failure('Google kimlik bilgileri alınamadı');
      }

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
      // Daha kullanıcı dostu hata mesajı
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') || errorStr.contains('internet')) {
        return AuthResult.failure('İnternet bağlantınızı kontrol edin');
      }
      if (errorStr.contains('cancel')) {
        return AuthResult.failure('Google girişi iptal edildi');
      }
      return AuthResult.failure('Google ile giriş yapılamadı. Tekrar deneyin.');
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
      // Apple Sign-In spesifik hata mesajları
      switch (e.code) {
        case 'canceled':
        case 'user-canceled':
          return AuthResult.failure('Apple girişi iptal edildi');
        case 'invalid-credential':
          return AuthResult.failure('Apple kimlik bilgileri geçersiz');
        case 'operation-not-allowed':
          return AuthResult.failure('Apple ile giriş aktif değil');
        case 'network-request-failed':
          return AuthResult.failure('İnternet bağlantınızı kontrol edin');
        default:
          return AuthResult.failure(_getAuthErrorMessage(e.code));
      }
    } catch (e) {
      // Daha kullanıcı dostu hata mesajı
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel')) {
        return AuthResult.failure('Apple girişi iptal edildi');
      }
      if (errorStr.contains('network') || errorStr.contains('internet')) {
        return AuthResult.failure('İnternet bağlantınızı kontrol edin');
      }
      if (errorStr.contains('unknown')) {
        return AuthResult.failure(
          'Apple ile giriş yapılamadı. Ayarlar > Apple Kimliği > Şifre ve Güvenlik bölümünden kontrol edin.',
        );
      }
      return AuthResult.failure('Apple ile giriş yapılamadı. Tekrar deneyin.');
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
      return AuthResult.failure('Email gönderilemedi. Tekrar deneyin.');
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
    String? favoriteArtist,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
        await user.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await user.updatePhotoURL(photoUrl);
      }

      if (favoriteArtist != null) {
        updates['favoriteArtist'] = favoriteArtist;
      }

      await _usersCollection.doc(user.uid).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Firestore'dan kullanıcı dokümanını al veya oluştur
  Future<UserModel> _getOrCreateUserDocument(User firebaseUser) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // Yeni kullanıcı dokümanı oluştur
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
      case 'account-exists-with-different-credential':
        return 'Bu email farklı bir giriş yöntemiyle kayıtlı';
      default:
        return 'Bir hata oluştu. Tekrar deneyin.';
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
