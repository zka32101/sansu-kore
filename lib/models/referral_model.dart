import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralCode {
  final String code;
  final String creatorId;
  final int creatorCoins;
  final int usedCount;
  final int maxUses;
  final DateTime createdAt;

  ReferralCode({
    required this.code,
    required this.creatorId,
    required this.creatorCoins,
    required this.usedCount,
    required this.maxUses,
    required this.createdAt,
  });

  bool get isAvailable => usedCount < maxUses;

  factory ReferralCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReferralCode(
      code: doc.id,
      creatorId: data['creatorId'] ?? '',
      creatorCoins: data['creatorCoins'] ?? 0,
      usedCount: data['usedCount'] ?? 0,
      maxUses: data['maxUses'] ?? 5,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'creatorId': creatorId,
    'creatorCoins': creatorCoins,
    'usedCount': usedCount,
    'maxUses': maxUses,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
