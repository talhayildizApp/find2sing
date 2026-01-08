import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Leaderboard service for challenge scores
class LeaderboardService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Submit score to leaderboard
  /// Returns the rank if in top 100, null otherwise
  Future<int?> submitScore({
    required String challengeId,
    required int score,
    required int timeSeconds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docRef = _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('leaderboard')
        .doc(user.uid);

    // Get existing entry to check if new score is better
    final existing = await docRef.get();
    if (existing.exists) {
      final existingScore = existing.data()?['score'] ?? 0;
      if (score <= existingScore) {
        // Not a better score, just return current rank
        return await _getRank(challengeId, user.uid);
      }
    }

    // Submit new score
    await docRef.set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'Anonim',
      'photoUrl': user.photoURL,
      'score': score,
      'timeSeconds': timeSeconds,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    return await _getRank(challengeId, user.uid);
  }

  /// Get user's rank in leaderboard
  Future<int?> _getRank(String challengeId, String uid) async {
    final snapshot = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .orderBy('timeSeconds', descending: false)
        .limit(100)
        .get();

    for (int i = 0; i < snapshot.docs.length; i++) {
      if (snapshot.docs[i].id == uid) {
        return i + 1;
      }
    }

    return null;
  }

  /// Get top entries for a challenge
  Future<List<LeaderboardEntry>> getTopEntries(String challengeId, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .orderBy('timeSeconds', descending: false)
        .limit(limit)
        .get();

    return snapshot.docs.asMap().entries.map((entry) {
      return LeaderboardEntry.fromFirestore(entry.value, entry.key + 1);
    }).toList();
  }

  /// Get current user's entry
  Future<LeaderboardEntry?> getCurrentUserEntry(String challengeId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('leaderboard')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    final rank = await _getRank(challengeId, user.uid);
    return LeaderboardEntry.fromFirestore(doc, rank ?? 0);
  }
}

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int score;
  final int timeSeconds;
  final int rank;
  final DateTime? submittedAt;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.score,
    required this.timeSeconds,
    required this.rank,
    this.submittedAt,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Anonim',
      photoUrl: data['photoUrl'],
      score: data['score'] ?? 0,
      timeSeconds: data['timeSeconds'] ?? 0,
      rank: rank,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }
}
