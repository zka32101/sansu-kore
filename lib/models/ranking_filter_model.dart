import 'package:flutter/foundation.dart';

import 'ranking_model.dart';
enum RankingGroupOption {
  global, // 全体ランキング
  grade, // 学年別ランキング
  startMonth, // 開始月別ランキング
  combined, // 複合グループ化（学年 + 開始月）
}

/// ランキングフィルタ条件
@immutable
class RankingFilter {
  final RankingGroupOption groupOption;
  final int? selectedGrade; // グループ化が grade/combined の場合
  final DateTime? selectedMonth; // グループ化が startMonth/combined の場合

  const RankingFilter({
    this.groupOption = RankingGroupOption.global,
    this.selectedGrade,
    this.selectedMonth,
  });

  /// フィルタをコピーして新しいインスタンスを作成
  RankingFilter copyWith({
    RankingGroupOption? groupOption,
    int? selectedGrade,
    DateTime? selectedMonth,
  }) {
    return RankingFilter(
      groupOption: groupOption ?? this.groupOption,
      selectedGrade: selectedGrade ?? this.selectedGrade,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  /// グループ化オプションの表示名
  String getDisplayName() {
    switch (groupOption) {
      case RankingGroupOption.global:
        return '全体ランキング';
      case RankingGroupOption.grade:
        return '$selectedGrade年生のランキング';
      case RankingGroupOption.startMonth:
        if (selectedMonth != null) {
          return '${selectedMonth!.year}年${selectedMonth!.month}月開始のランキング';
        }
        return '開始月別ランキング';
      case RankingGroupOption.combined:
        if (selectedGrade != null && selectedMonth != null) {
          return '$selectedGrade年生（${selectedMonth!.year}年${selectedMonth!.month}月開始）';
        }
        return '複合グループ化';
    }
  }

  @override
  String toString() => 'RankingFilter(group: $groupOption, grade: $selectedGrade, month: $selectedMonth)';
}

/// ランキングフィルタリング処理
class RankingFilterService {
  /// ランキングリストをフィルタリング
  static List<UserRankingData> filterRankings(
    List<UserRankingData> rankings,
    RankingFilter filter,
  ) {
    switch (filter.groupOption) {
      case RankingGroupOption.global:
        return rankings; // フィルタなし

      case RankingGroupOption.grade:
        if (filter.selectedGrade == null) return rankings;
        return rankings
            .where((r) => r.gradeLevel == filter.selectedGrade)
            .toList();

      case RankingGroupOption.startMonth:
        if (filter.selectedMonth == null) return rankings;
        return rankings.where((r) {
          return r.startDate.year == filter.selectedMonth!.year &&
              r.startDate.month == filter.selectedMonth!.month;
        }).toList();

      case RankingGroupOption.combined:
        final filtered = rankings;
        if (filter.selectedGrade != null) {
          return filtered
              .where((r) => r.gradeLevel == filter.selectedGrade)
              .where((r) {
            if (filter.selectedMonth == null) return true;
            return r.startDate.year == filter.selectedMonth!.year &&
                r.startDate.month == filter.selectedMonth!.month;
          }).toList();
        }
        return filtered;
    }
  }

  /// 利用可能な学年リストを取得
  static List<int> getAvailableGrades(List<UserRankingData> rankings) {
    final grades = <int>{};
    for (final ranking in rankings) {
      grades.add(ranking.gradeLevel);
    }
    return grades.toList()..sort();
  }

  /// 利用可能な開始月リストを取得
  static List<DateTime> getAvailableStartMonths(List<UserRankingData> rankings) {
    final months = <DateTime>{};
    for (final ranking in rankings) {
      months.add(
        DateTime(ranking.startDate.year, ranking.startDate.month),
      );
    }
    return months.toList()
      ..sort((a, b) => a.compareTo(b));
  }

  /// ランキングをランクで再計算（フィルタ後）
  static List<UserRankingData> recalculateRanks(
    List<UserRankingData> rankings,
  ) {
    final sorted = [...rankings]
      ..sort((a, b) => b.score.compareTo(a.score));

    return sorted
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(rank: entry.key + 1))
        .toList();
  }
}
