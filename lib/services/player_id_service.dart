import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerIdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Words for playerId generation
  static const List<String> _words = [
    'MOON', 'STAR', 'BEAT', 'ROCK', 'JAZZ', 'BASS', 'DRUM', 'SONG',
    'TUNE', 'VIBE', 'SOUL', 'FUNK', 'WAVE', 'ECHO', 'FLOW', 'FIRE',
    'COOL', 'PLAY', 'LIVE', 'LOUD', 'GOLD', 'BLUE', 'PINK', 'NEON',
    'WILD', 'FREE', 'FAST', 'SLOW', 'HIGH', 'DEEP', 'PURE', 'EPIC',
  ];

  /// Generate a unique playerId (e.g., "MOON-4921")
  Future<String> generateUniquePlayerId() async {
    String playerId;
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      playerId = _generatePlayerId();
      isUnique = await _isPlayerIdUnique(playerId);
      attempts++;
    } while (!isUnique && attempts < maxAttempts);

    if (!isUnique) {
      // Fallback: add timestamp suffix
      playerId = '${_words[_random.nextInt(_words.length)]}-${DateTime.now().millisecondsSinceEpoch % 100000}';
    }

    return playerId;
  }

  /// Generate playerId format: WORD-XXXX
  String _generatePlayerId() {
    final word = _words[_random.nextInt(_words.length)];
    final number = _random.nextInt(9000) + 1000; // 1000-9999
    return '$word-$number';
  }

  /// Check if playerId is unique
  Future<bool> _isPlayerIdUnique(String playerId) async {
    final query = await _db
        .collection('users')
        .where('playerId', isEqualTo: playerId)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  /// Ensure user has playerId, create if missing
  Future<String?> ensurePlayerId(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final existingPlayerId = userDoc.data()?['playerId'];
    if (existingPlayerId != null && existingPlayerId.isNotEmpty) {
      return existingPlayerId;
    }

    // Generate and save new playerId
    final newPlayerId = await generateUniquePlayerId();
    await _db.collection('users').doc(uid).update({
      'playerId': newPlayerId,
    });

    return newPlayerId;
  }

  /// Get uid by playerId
  Future<String?> getUidByPlayerId(String playerId) async {
    final query = await _db
        .collection('users')
        .where('playerId', isEqualTo: playerId.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  /// Validate playerId format
  bool isValidPlayerIdFormat(String playerId) {
    final regex = RegExp(r'^[A-Z]{4}-\d{4}$');
    return regex.hasMatch(playerId.toUpperCase());
  }

  /// Get user info by playerId
  Future<Map<String, dynamic>?> getUserByPlayerId(String playerId) async {
    final query = await _db
        .collection('users')
        .where('playerId', isEqualTo: playerId.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return {
      'uid': query.docs.first.id,
      ...query.docs.first.data(),
    };
  }
}
