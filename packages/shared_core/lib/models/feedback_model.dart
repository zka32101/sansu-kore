// 小学コレシリーズ共通「バグ報告・改善要望」フォーム機能の型。
//
// shared_core は cloud_firestore に依存していないため、Firestoreへの実際の書き込みは
// 行わない（コンテンツ本体をアプリ側が注入する lesson/badge と同じ設計思想）。
// 各アプリ側が FeedbackNotifier.setSubmitHandler() で実際の送信処理（Firestore書き込み等）
// を注入する。

/// 報告の種別。
enum FeedbackType {
  bug, // 不具合報告
  feature, // 改善要望
  other, // その他
}

extension FeedbackTypeLabel on FeedbackType {
  String get label => switch (this) {
        FeedbackType.bug => '不具合報告',
        FeedbackType.feature => '改善要望',
        FeedbackType.other => 'その他',
      };
}

/// 1件のバグ報告・改善要望。
class FeedbackReport {
  final String id;
  final FeedbackType type;
  final String title;
  final String description;
  final String appName; // どのアプリからの報告か（例: 'kokugo-kore'）
  final String appVersion;
  final String platform; // 'iOS' / 'Android' 等
  final DateTime createdAt;
  final String? userId; // 匿名認証のUID
  final String status; // 'open' / 'reviewing' / 'resolved' など。初期値'open'

  const FeedbackReport({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.appName,
    required this.appVersion,
    required this.platform,
    required this.createdAt,
    required this.userId,
    this.status = 'open',
  });

  FeedbackReport copyWith({
    String? id,
    FeedbackType? type,
    String? title,
    String? description,
    String? appName,
    String? appVersion,
    String? platform,
    DateTime? createdAt,
    String? userId,
    String? status,
  }) =>
      FeedbackReport(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        appName: appName ?? this.appName,
        appVersion: appVersion ?? this.appVersion,
        platform: platform ?? this.platform,
        createdAt: createdAt ?? this.createdAt,
        userId: userId ?? this.userId,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'appName': appName,
        'appVersion': appVersion,
        'platform': platform,
        'createdAt': createdAt.toIso8601String(),
        'userId': userId,
        'status': status,
      };

  factory FeedbackReport.fromJson(Map<String, dynamic> json) => FeedbackReport(
        id: json['id'] as String,
        type: FeedbackType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => FeedbackType.other,
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        appName: json['appName'] as String,
        appVersion: json['appVersion'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        userId: json['userId'] as String?,
        status: json['status'] as String? ?? 'open',
      );
}
