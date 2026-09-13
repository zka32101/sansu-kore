import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_model.freezed.dart';
part 'analytics_model.g.dart';

@JsonSerializable()
@freezed
class DailyStats with _$DailyStats {
  const factory DailyStats({
    required String date, // YYYY-MM-DD
    required int questsCompleted,
    required int correctAnswers,
    required int totalAnswers,
    required int coinsEarned,
    required int studyMinutes,
    required Map<String, dynamic> categoryStats, // {categoryId: {correct, total}}
  }) = _DailyStats;

  factory DailyStats.fromJson(Map<String, dynamic> json) =>
      _$DailyStatsFromJson(json);
}

@JsonSerializable()
@freezed
class WeeklyStats with _$WeeklyStats {
  const factory WeeklyStats({
    required String weekStart, // YYYY-MM-DD (月曜日)
    required int totalStudyMinutes,
    required int totalQuestsCompleted,
    required double averageAccuracy,
    required Map<String, int> dailyCounts, // {YYYY-MM-DD: count}
  }) = _WeeklyStats;

  factory WeeklyStats.fromJson(Map<String, dynamic> json) =>
      _$WeeklyStatsFromJson(json);
}

@JsonSerializable()
@freezed
class MonthlyStats with _$MonthlyStats {
  const factory MonthlyStats({
    required String month, // YYYY-MM
    required int totalQuestsCompleted,
    required int totalCorrectAnswers,
    required int totalAnswers,
    required double accuracyRate, // 0.0 ~ 1.0
    required int totalStudyMinutes,
    required int totalCoinsEarned,
    required int studyDaysCount, // 学習した日数
    required Map<String, dynamic> categoryStats, // {categoryId: {correct, total, accuracy}}
  }) = _MonthlyStats;

  factory MonthlyStats.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatsFromJson(json);

  double get accuracyPercentage => accuracyRate * 100;
}

@JsonSerializable()
@freezed
class ProgressAnalytics with _$ProgressAnalytics {
  const factory ProgressAnalytics({
    required String userId,
    required List<DailyStats> dailyHistory,
    required List<WeeklyStats> weeklyHistory,
    required double overallAccuracy,
    required int totalQuestsCompleted,
    required int totalCoinsEarned,
    required Map<String, CategoryMastery> categoryMastery,
    required DateTime lastUpdated,
  }) = _ProgressAnalytics;

  factory ProgressAnalytics.fromJson(Map<String, dynamic> json) =>
      _$ProgressAnalyticsFromJson(json);
}

@JsonSerializable()
@freezed
class CategoryMastery with _$CategoryMastery {
  const factory CategoryMastery({
    required String categoryId,
    required String categoryName,
    required int correctCount,
    required int totalCount,
    required double masteryLevel, // 0.0 ~ 1.0
    required DateTime lastPracticedDate,
    required List<int> recentScores, // 直近10回のスコア
  }) = _CategoryMastery;

  factory CategoryMastery.fromJson(Map<String, dynamic> json) =>
      _$CategoryMasteryFromJson(json);
}

@JsonSerializable()
@freezed
class LearningPaceData with _$LearningPaceData {
  const factory LearningPaceData({
    required String userId,
    required int recommendedQuestsPerDay,
    required int averageQuestsPerDay,
    required int inconsistencyDays, // 学習しなかった日数（過去30日）
    required double studyConsistencyScore, // 0.0 ~ 1.0
    required DateTime nextCheckDate,
  }) = _LearningPaceData;

  factory LearningPaceData.fromJson(Map<String, dynamic> json) =>
      _$LearningPaceDataFromJson(json);
}
