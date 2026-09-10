import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ユーザーのランキングスコア情報
@immutable
class UserRankingData {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int score; // 総合スコア (0-100 × 問題数)
  final int rank; // 現在のランク
  final int totalQuestionsAnswered; // 回答済み問題数
  final double correctRate; // 正答率 (0.0-1.0)
  final double averageSpeed; // 平均回答時間 (秒)
  final DateTime lastUpdatedAt;
  final int weeklyScore; // 週間スコア
  final int monthlyScore; // 月間スコア
  final bool isNamePublic; // ランキングに名前を公開するか (デフォルト: false)
  final int gradeLevel; // 学年 (1-6)
  final DateTime startDate; // ユーザー登録日 (開始月別グループ化用)

  const UserRankingData({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.score,
    required this.rank,
    required this.totalQuestionsAnswered,
    required this.correctRate,
    required this.averageSpeed,
    required this.lastUpdatedAt,
    this.weeklyScore = 0,
    this.monthlyScore = 0,
    this.isNamePublic = false,
    this.gradeLevel = 1,
    required this.startDate,
  });

  /// Firestore ドキュメントから UserRankingData を生成
  factory UserRankingData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UserRankingData(
      userId: doc.id,
      userName: data['userName'] as String? ?? 'ユーザー',
      avatarUrl: data['avatarUrl'] as String?,
      score: data['score'] as int? ?? 0,
      rank: data['rank'] as int? ?? 0,
      totalQuestionsAnswered: data['totalQuestionsAnswered'] as int? ?? 0,
      correctRate: (data['correctRate'] as num?)?.toDouble() ?? 0.0,
      averageSpeed: (data['averageSpeed'] as num?)?.toDouble() ?? 0.0,
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? (data['lastUpdatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      weeklyScore: data['weeklyScore'] as int? ?? 0,
      monthlyScore: data['monthlyScore'] as int? ?? 0,
      isNamePublic: data['isNamePublic'] as bool? ?? false,
      gradeLevel: data['gradeLevel'] as int? ?? 1,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Firestore に保存するための Map に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'avatarUrl': avatarUrl,
      'score': score,
      'rank': rank,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'correctRate': correctRate,
      'averageSpeed': averageSpeed,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'weeklyScore': weeklyScore,
      'monthlyScore': monthlyScore,
      'isNamePublic': isNamePublic,
      'gradeLevel': gradeLevel,
      'startDate': Timestamp.fromDate(startDate),
    };
  }

  /// スコア情報をコピーして新しいインスタンスを作成
  UserRankingData copyWith({
    String? userId,
    String? userName,
    String? avatarUrl,
    int? score,
    int? rank,
    int? totalQuestionsAnswered,
    double? correctRate,
    double? averageSpeed,
    DateTime? lastUpdatedAt,
    int? weeklyScore,
    int? monthlyScore,
    bool? isNamePublic,
    int? gradeLevel,
    DateTime? startDate,
  }) {
    return UserRankingData(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      correctRate: correctRate ?? this.correctRate,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      monthlyScore: monthlyScore ?? this.monthlyScore,
      isNamePublic: isNamePublic ?? this.isNamePublic,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      startDate: startDate ?? this.startDate,
    );
  }

  /// ランキング表示用の名前を取得
  /// isNamePublic が false の場合、ランク番号に基づいた匿名名を返す
  /// isNamePublic が true の場合、実際のユーザー名を返す
  String getDisplayName({int? anonymousIndex}) {
    if (isNamePublic) {
      return userName;
    }
    // 匿名表示: ランク番号を使用
    return 'ユーザー ${rank > 0 ? rank : (anonymousIndex ?? 1)}';
  }

  /// 複数のランキングエントリから匿名表示用の表示名を生成
  /// プライバシー設定を考慮したマッピング関数
  static String generateDisplayName(UserRankingData ranking) {
    return ranking.getDisplayName();
  }

  @override
  String toString() =>
      'UserRankingData(userId: $userId, userName: $userName, score: $score, rank: $rank, correctRate: ${(correctRate * 100).toStringAsFixed(1)}%)';
}

/// ランキング表示用のグループ分け
enum RankingCategory {
  global, // グローバルランキング
  weekly, // 週間ランキング
  monthly, // 月間ランキング
  friends, // フレンドランキング
}

/// 各学年別のランキング
enum GradeRanking {
  grade1, // 1年生
  grade2, // 2年生
  grade3, // 3年生
  grade4, // 4年生
  grade5, // 5年生
  grade6, // 6年生
}

/// 問題クリア時のスコア計算情報
@immutable
class QuestionScoreData {
  final String questionId;
  final bool isCorrect;
  final double responseTimeSeconds;
  final int baseScore; // 基本スコア (100)
  final int correctBonus; // 正解ボーナス (正解時のみ)
  final int speedBonus; // 速度ボーナス (1.5秒以下)
  final int totalScore; // 合計スコア

  const QuestionScoreData({
    required this.questionId,
    required this.isCorrect,
    required this.responseTimeSeconds,
    this.baseScore = 100,
    this.correctBonus = 0,
    this.speedBonus = 0,
    this.totalScore = 0,
  });

  /// スコア計算ロジック
  ///
  /// 計算式:
  /// - 基本スコア: 100
  /// - 正解ボーナス: 正解 → +50点
  /// - 速度ボーナス: 回答時間 1.5秒以下 → +30点
  /// - 合計: 基本 + 正解ボーナス + 速度ボーナス
  factory QuestionScoreData.calculate({
    required String questionId,
    required bool isCorrect,
    required double responseTimeSeconds,
  }) {
    const baseScore = 100;
    final correctBonus = isCorrect ? 50 : 0;
    final speedBonus = responseTimeSeconds <= 1.5 ? 30 : 0;
    final totalScore = baseScore + correctBonus + speedBonus;

    return QuestionScoreData(
      questionId: questionId,
      isCorrect: isCorrect,
      responseTimeSeconds: responseTimeSeconds,
      baseScore: baseScore,
      correctBonus: correctBonus,
      speedBonus: speedBonus,
      totalScore: totalScore,
    );
  }

  /// スコア詳細の説明文
  String getScoreBreakdown() {
    final parts = [
      '基本: $baseScore点',
      if (correctBonus > 0) '正解ボーナス: +$correctBonus点',
      if (speedBonus > 0) '速度ボーナス: +$speedBonus点',
    ];
    return parts.join(' | ');
  }

  @override
  String toString() =>
      'QuestionScoreData(questionId: $questionId, isCorrect: $isCorrect, responseTime: ${responseTimeSeconds}s, score: $totalScore)';
}

/// ランキング集計の進捗情報
@immutable
class RankingStats {
  final int totalUsers; // 集計対象ユーザー数
  final DateTime lastCalculatedAt; // 最後に集計した時刻
  final Map<int, int> scoreDistribution; // スコア分布 (スコア → ユーザー数)

  const RankingStats({
    required this.totalUsers,
    required this.lastCalculatedAt,
    this.scoreDistribution = const {},
  });

  factory RankingStats.empty() {
    return RankingStats(
      totalUsers: 0,
      lastCalculatedAt: DateTime.now(),
    );
  }
}
