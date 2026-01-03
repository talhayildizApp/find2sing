import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchMode {
  friendsWord,
  challengeOnline,
}

enum ModeVariant {
  timeRace,
  relax,
  real,
}

enum IntentStatus {
  waiting,
  paired,
  expired,
  canceled,
}

class MatchIntentModel {
  final String id;
  final String fromUid;
  final String fromPlayerId;
  final String toPlayerId;
  final MatchMode mode;
  final String? challengeId;
  final ModeVariant? modeVariant;
  final DateTime createdAt;
  final IntentStatus status;
  final String? roomId;

  MatchIntentModel({
    required this.id,
    required this.fromUid,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.mode,
    this.challengeId,
    this.modeVariant,
    required this.createdAt,
    required this.status,
    this.roomId,
  });

  factory MatchIntentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchIntentModel(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      fromPlayerId: data['fromPlayerId'] ?? '',
      toPlayerId: data['toPlayerId'] ?? '',
      mode: MatchMode.values.firstWhere(
        (e) => e.name == data['mode'],
        orElse: () => MatchMode.friendsWord,
      ),
      challengeId: data['challengeId'],
      modeVariant: data['modeVariant'] != null
          ? ModeVariant.values.firstWhere(
              (e) => e.name == data['modeVariant'],
              orElse: () => ModeVariant.timeRace,
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: IntentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => IntentStatus.waiting,
      ),
      roomId: data['roomId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUid': fromUid,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'mode': mode.name,
      'challengeId': challengeId,
      'modeVariant': modeVariant?.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'roomId': roomId,
    };
  }

  MatchIntentModel copyWith({
    IntentStatus? status,
    String? roomId,
  }) {
    return MatchIntentModel(
      id: id,
      fromUid: fromUid,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      mode: mode,
      challengeId: challengeId,
      modeVariant: modeVariant,
      createdAt: createdAt,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
    );
  }

  bool get isPaired => status == IntentStatus.paired && roomId != null;
  bool get isWaiting => status == IntentStatus.waiting;
  bool get isCanceled => status == IntentStatus.canceled;
  bool get isExpired => status == IntentStatus.expired;
}
