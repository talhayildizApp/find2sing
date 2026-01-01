import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔸 Firestore'a yeni kayıt ekler
  Future<void> addSubmission({
    required String word,
    required String song,
    required String artist,
    required int score,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _db.collection('submissions').add({
      'userId': uid,
      'word': word,
      'songTitle': song,
      'artist': artist,
      'score': score,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔸 Mevcut kullanıcının kayıtlarını dinamik olarak getirir
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserSubmissions(String uid) {
    return _db
        .collection('submissions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🔹 Tüm kayıtları (global liste) getirir
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllSubmissions() {
    return _db
        .collection('submissions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
