import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ranking_filter_model.dart';
import '../models/ranking_model.dart';
import '../providers/ranking_provider.dart';
class RankingFilterScreen extends ConsumerWidget {
  const RankingFilterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rankingFilterProvider);
    final filteredRankings = ref.watch(filteredRankingProvider);
    final availableGrades = ref.watch(availableGradesProvider);
    final availableMonths = ref.watch(availableStartMonthsProvider);
    final ranking = ref.watch(rankingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // フィルタセクション
            _buildFilterSection(
              context,
              ref,
              filter,
              availableGrades,
              availableMonths,
            ),

            // ランキング表示セクション
            _buildRankingSection(
              context,
              filter,
              filteredRankings,
              ranking.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  /// フィルタセクション
  Widget _buildFilterSection(
    BuildContext context,
    WidgetRef ref,
    RankingFilter filter,
    List<int> availableGrades,
    List<DateTime> availableMonths,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // グループ化オプション選択
          const Text(
            'グループ化方式を選択',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildGroupOptionButtons(ref, filter),

          const SizedBox(height: 20),

          // 追加フィルタ条件
          if (filter.groupOption == RankingGroupOption.grade ||
              filter.groupOption == RankingGroupOption.combined)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '学年を選択',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildGradeSelector(ref, availableGrades, filter),
                const SizedBox(height: 16),
              ],
            ),

          if (filter.groupOption == RankingGroupOption.startMonth ||
              filter.groupOption == RankingGroupOption.combined)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '開始月を選択',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMonthSelector(ref, availableMonths, filter),
                const SizedBox(height: 16),
              ],
            ),

          // リセットボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(rankingFilterProvider.notifier).resetFilter();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('フィルタをリセット'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// グループ化オプションボタン
  Widget _buildGroupOptionButtons(WidgetRef ref, RankingFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RankingGroupOption.values.map((option) {
          final isSelected = filter.groupOption == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _getGroupOptionLabel(option),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                ref
                    .read(rankingFilterProvider.notifier)
                    .setGroupOption(option);
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue.shade600,
              showCheckmark: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// グループ化オプションのラベル取得
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

  /// 学年セレクタ
  Widget _buildGradeSelector(
    WidgetRef ref,
    List<int> availableGrades,
    RankingFilter filter,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableGrades.map((grade) {
        final isSelected = filter.selectedGrade == grade;
        return ChoiceChip(
          label: Text('$grade年生'),
          selected: isSelected,
          onSelected: (selected) {
            ref.read(rankingFilterProvider.notifier).selectGrade(grade);
          },
          selectedColor: Colors.amber.shade600,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  /// 開始月セレクタ
  Widget _buildMonthSelector(
    WidgetRef ref,
    List<DateTime> availableMonths,
    RankingFilter filter,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableMonths.map((month) {
        final isSelected = filter.selectedMonth?.year == month.year &&
            filter.selectedMonth?.month == month.month;
        return ChoiceChip(
          label: Text('${month.year}年${month.month}月'),
          selected: isSelected,
          onSelected: (selected) {
            ref.read(rankingFilterProvider.notifier).selectStartMonth(month);
          },
          selectedColor: Colors.deepPurple.shade600,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  /// ランキング表示セクション
  Widget _buildRankingSection(
    BuildContext context,
    RankingFilter filter,
    List<UserRankingData> rankings,
    bool isLoading,
  ) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (rankings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '該当するユーザーがいません',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                filter.getDisplayName(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${rankings.length}人',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            return _buildRankingCard(rankings[index], index + 1);
          },
        ),
      ],
    );
  }

  /// ランキングカード
  Widget _buildRankingCard(UserRankingData ranking, int position) {
    final medalColor = _getMedalColor(position);
    final medalIcon = _getMedalIcon(position);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: medalColor.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: medalColor.withOpacity(0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ランク表示
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medalColor,
              ),
              child: Center(
                child: position <= 3
                    ? Icon(
                        medalIcon,
                        color: Colors.white,
                        size: 24,
                      )
                    : Text(
                        '$position',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // ユーザー名
                      Expanded(
                        child: Text(
                          ranking.getDisplayName(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 学年バッジ
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ranking.gradeLevel}年',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'スコア: ${ranking.score}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(ranking.correctRate * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // スコア表示
            Text(
              '${ranking.score}点',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: medalColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// メダル色を取得
  Color _getMedalColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade600;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade600;
    }
  }

  /// メダルアイコンを取得
  IconData _getMedalIcon(int position) {
    switch (position) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return Icons.numbers;
    }
  }
}
