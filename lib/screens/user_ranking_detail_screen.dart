import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ranking_model.dart';

/// ユーザーランキング詳細画面
class UserRankingDetailScreen extends ConsumerWidget {
  final UserRankingData userRanking;

  const UserRankingDetailScreen({
    Key? key,
    required this.userRanking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userRanking.getDisplayName()),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // プロフィールセクション
            _ProfileSection(userRanking: userRanking),
            const SizedBox(height: 24),

            // ランキング統計セクション
            _RankingStatsSection(userRanking: userRanking),
            const SizedBox(height: 24),

            // スコア詳細セクション
            _ScoreDetailsSection(userRanking: userRanking),
            const SizedBox(height: 24),

            // ユーザー情報セクション
            _UserInfoSection(userRanking: userRanking),
          ],
        ),
      ),
    );
  }
}

/// プロフィールセクション
class _ProfileSection extends StatelessWidget {
  final UserRankingData userRanking;

  const _ProfileSection({required this.userRanking});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // アバター
            if (userRanking.avatarUrl != null && userRanking.avatarUrl!.isNotEmpty)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userRanking.avatarUrl!),
              )
            else
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 16),

            // ユーザー名
            Text(
              userRanking.getDisplayName(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // ランク表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${userRanking.rank}位',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ランキング統計セクション
class _RankingStatsSection extends StatelessWidget {
  final UserRankingData userRanking;

  const _RankingStatsSection({required this.userRanking});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ランキング統計',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  icon: '🏆',
                  label: 'グローバル順位',
                  value: '${userRanking.rank}位',
                ),
                _StatCard(
                  icon: '💯',
                  label: '総合スコア',
                  value: '${userRanking.score}',
                ),
                _StatCard(
                  icon: '📊',
                  label: '正答率',
                  value: '${(userRanking.correctRate * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  icon: '⚡',
                  label: '平均速度',
                  value: '${userRanking.averageSpeed.toStringAsFixed(1)}s',
                ),
                _StatCard(
                  icon: '📝',
                  label: '問題数',
                  value: '${userRanking.totalQuestionsAnswered}',
                ),
                _StatCard(
                  icon: '📅',
                  label: 'グレード',
                  value: '${userRanking.gradeLevel}年生',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// スコア詳細セクション
class _ScoreDetailsSection extends StatelessWidget {
  final UserRankingData userRanking;

  const _ScoreDetailsSection({required this.userRanking});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'スコア詳細',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _ScoreRow(
              label: 'グローバルスコア',
              value: '${userRanking.score}',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _ScoreRow(
              label: '週間スコア',
              value: '${userRanking.weeklyScore}',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _ScoreRow(
              label: '月間スコア',
              value: '${userRanking.monthlyScore}',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _ScoreRow(
              label: '最終更新',
              value: _formatDateTime(userRanking.lastUpdatedAt),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// スコア行
class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// ユーザー情報セクション
class _UserInfoSection extends StatelessWidget {
  final UserRankingData userRanking;

  const _UserInfoSection({required this.userRanking});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ユーザー情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'ユーザーID',
              value: userRanking.userId,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'プライバシー設定',
              value: userRanking.isNamePublic ? '公開' : 'プライベート',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: '登録日',
              value: _formatDate(userRanking.startDate),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: '学年',
              value: '${userRanking.gradeLevel}年生',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

/// 情報行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
