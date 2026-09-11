import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ranking_filter_model.dart';
import '../providers/grade_upgrade_provider.dart';
import '../providers/ranking_provider.dart';
class CompactRankingFilter extends ConsumerWidget {
  final bool showGrades;
  final bool showMonths;

  const CompactRankingFilter({
    Key? key,
    this.showGrades = true,
    this.showMonths = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rankingFilterProvider);
    final availableGrades = ref.watch(availableGradesProvider);
    final availableMonths = ref.watch(availableStartMonthsProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // グループ化オプション
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: RankingGroupOption.values.map((option) {
                final isSelected = filter.groupOption == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getGroupOptionLabel(option)),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref
                          .read(rankingFilterProvider.notifier)
                          .setGroupOption(option);
                    },
                    selectedColor: Colors.blue.shade600,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 学年フィルタ
          if ((filter.groupOption == RankingGroupOption.grade ||
                  filter.groupOption == RankingGroupOption.combined) &&
              showGrades)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: availableGrades.map((grade) {
                    final isSelected = filter.selectedGrade == grade;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          '$grade年',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref
                              .read(rankingFilterProvider.notifier)
                              .selectGrade(grade);
                        },
                        selectedColor: Colors.amber.shade600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 開始月フィルタ
          if ((filter.groupOption == RankingGroupOption.startMonth ||
                  filter.groupOption == RankingGroupOption.combined) &&
              showMonths)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: availableMonths.map((month) {
                    final isSelected = filter.selectedMonth?.year == month.year &&
                        filter.selectedMonth?.month == month.month;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          '${month.month}月',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref
                              .read(rankingFilterProvider.notifier)
                              .selectStartMonth(month);
                        },
                        selectedColor: Colors.deepPurple.shade600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getGroupOptionLabel(RankingGroupOption option) {
    switch (option) {
      case RankingGroupOption.global:
        return '全体';
      case RankingGroupOption.grade:
        return '学年別';
      case RankingGroupOption.startMonth:
        return '開始月別';
      case RankingGroupOption.combined:
        return '複合';
    }
  }
}

/// ランキングフィルタステータス表示
class RankingFilterStatus extends ConsumerWidget {
  final TextStyle? textStyle;

  const RankingFilterStatus({
    Key? key,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rankingFilterProvider);
    final filteredRankings = ref.watch(filteredRankingProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          filter.getDisplayName(),
          style: textStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${filteredRankings.length}人',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

/// ランキング統計情報ウィジェット
class RankingStatsWidget extends ConsumerWidget {
  const RankingStatsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeUpgradeService = ref.watch(gradeUpgradeProvider);

    return FutureBuilder<Map<int, int>>(
      future: gradeUpgradeService.getGradeDistribution(),
      builder: (context, gradeSnapshot) {
        return FutureBuilder<Map<String, int>>(
          future: gradeUpgradeService.getStartMonthDistribution(),
          builder: (context, monthSnapshot) {
            if (!gradeSnapshot.hasData || !monthSnapshot.hasData) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final gradeDistribution = gradeSnapshot.data ?? {};
            final monthDistribution = monthSnapshot.data ?? {};

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 学年別統計
                  const Text(
                    '学年別ユーザー数',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildGradeStats(gradeDistribution),

                  const SizedBox(height: 16),

                  // 開始月別統計
                  const Text(
                    '開始月別ユーザー数',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMonthStats(monthDistribution),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGradeStats(Map<int, int> distribution) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(6, (index) {
        final grade = index + 1;
        final count = distribution[grade] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$grade年生: $count人',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthStats(Map<String, int> distribution) {
    final sorted = distribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sorted.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.key}: ${entry.value}人',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade700,
            ),
          ),
        );
      }).toList(),
    );
  }
}
