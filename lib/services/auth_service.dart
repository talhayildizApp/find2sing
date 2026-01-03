import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        return AuthResult.failure('Kullanıcı oluşturulamadı');
      }
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
      }
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
      final userModel = await _getOrCreateUserDocument(credential.user!);
      await _updateLastLogin(credential.user!.uid);
      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure('Giriş sırasında bir hata oluştu');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google girişi iptal edildi');
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return AuthResult.failure('Google kimlik bilgileri alınamadı');
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        return AuthResult.failure('Google ile giriş başarısız');
      }
      final userModel = await _getOrCreateUserDocument(userCredential.user!);
      await _updateLastLogin(userCredential.user!.uid);
      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
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
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel')) {
        return AuthResult.failure('Apple girişi iptal edildi');
      }
      if (errorStr.contains('network') || errorStr.contains('internet')) {
        return AuthResult.failure('İnternet bağlantınızı kontrol edin');
      }
      return AuthResult.failure('Apple ile giriş yapılamadı. Tekrar deneyin.');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

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

  Stream<UserModel?> userModelStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? preferredLanguage,
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
      if (preferredLanguage != null) {
        updates['preferredLanguage'] = preferredLanguage;
      }
      await _usersCollection.doc(user.uid).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateGameStats({
    required int songsFound,
    required int timePlayed,
  }) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _usersCollection.doc(user.uid).update({
        'totalSongsFound': FieldValue.increment(songsFound),
        'totalGamesPlayed': FieldValue.increment(1),
        'totalTimePlayed': FieldValue.increment(timePlayed),
      });
    } catch (e) {}
  }

  Future<bool> addFreeWordChanges(int count) async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) return false;
      final currentCredits = doc.data()?['wordChangeCredits'] ?? 0;
      final newCredits = (currentCredits + count).clamp(0, 5);
      await _usersCollection.doc(user.uid).update({
        'wordChangeCredits': newCredits,
        'lastAdWatched': FieldValue.serverTimestamp(),
        'totalAdsWatched': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> useFreeWordChange() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) return false;
      final currentCredits = doc.data()?['wordChangeCredits'] ?? 0;
      if (currentCredits <= 0) return false;
      await _usersCollection.doc(user.uid).update({
        'wordChangeCredits': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel> _getOrCreateUserDocument(User firebaseUser) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    final userModel = UserModel.newUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
    );
    await docRef.set(userModel.toFirestore());
    return userModel;
  }

  Future<void> _updateLastLogin(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

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
