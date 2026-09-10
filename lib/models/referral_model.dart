import 'package:cloud_firestore/cloud_firestore.dart';


/// 紹介コード情報
class ReferralCode {
  final String code;
  final String creatorId;
  final int creatorCoins; // 紹介した側が獲得したコイン
  final int usedCount; // このコードが使用された回数
  final int maxUses; // 最大使用回数（0 = 無制限）
  final DateTime createdAt;
  final DateTime? expiresAt; // 有効期限（null = 無制限）

  ReferralCode({
    required this.code,
    required this.creatorId,
    required this.creatorCoins,
    required this.usedCount,
    required this.maxUses,
    required this.createdAt,
    this.expiresAt,
  });

  /// コードが有効か判定
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// コードが使用可能か判定
  bool get isUsable {
    if (isExpired) return false;
    if (maxUses > 0 && usedCount >= maxUses) return false;
    return true;
  }

  /// Firestore ドキュメントから作成
  factory ReferralCode.fromMap(String codeId, Map<String, dynamic> data) {
    return ReferralCode(
      code: codeId,
      creatorId: data['creatorId'] as String? ?? '',
      creatorCoins: data['creatorCoins'] as int? ?? 0,
      usedCount: data['usedCount'] as int? ?? 0,
      maxUses: data['maxUses'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore ドキュメントに変換
  Map<String, dynamic> toMap() => {
    'creatorId': creatorId,
    'creatorCoins': creatorCoins,
    'usedCount': usedCount,
    'maxUses': maxUses,
    'createdAt': Timestamp.fromDate(createdAt),
    if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
  };

  /// コピー
  ReferralCode copyWith({
    String? code,
    String? creatorId,
    int? creatorCoins,
    int? usedCount,
    int? maxUses,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return ReferralCode(
      code: code ?? this.code,
      creatorId: creatorId ?? this.creatorId,
      creatorCoins: creatorCoins ?? this.creatorCoins,
      usedCount: usedCount ?? this.usedCount,
      maxUses: maxUses ?? this.maxUses,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// 紹介関連の報酬設定
class ReferralRewards {
  static const int coinsForReferrer = 100; // 紹介した側の報酬
  static const int coinsForReferee = 50; // 紹介された側の報酬
  static const int maxUsesPerCode = 5; // 1つのコードの最大使用回数
  static const int expirationDays = 90; // コード有効期限（日）
}

/// 紹介コード利用の記録
class ReferralRecord {
  final String referralCode;
  final String referrerId; // 紹介した人のID
  final String refereeId; // 紹介された人のID
  final DateTime usedAt;
  final int coinsAwardedToReferrer;
  final int coinsAwardedToReferee;

  ReferralRecord({
    required this.referralCode,
    required this.referrerId,
    required this.refereeId,
    required this.usedAt,
    required this.coinsAwardedToReferrer,
    required this.coinsAwardedToReferee,
  });

  factory ReferralRecord.fromMap(String docId, Map<String, dynamic> data) {
    return ReferralRecord(
      referralCode: data['referralCode'] as String? ?? '',
      referrerId: data['referrerId'] as String? ?? '',
      refereeId: data['refereeId'] as String? ?? '',
      usedAt: (data['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coinsAwardedToReferrer: data['coinsAwardedToReferrer'] as int? ?? 0,
      coinsAwardedToReferee: data['coinsAwardedToReferee'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'referralCode': referralCode,
    'referrerId': referrerId,
    'refereeId': refereeId,
    'usedAt': Timestamp.fromDate(usedAt),
    'coinsAwardedToReferrer': coinsAwardedToReferrer,
    'coinsAwardedToReferee': coinsAwardedToReferee,
  };
}
