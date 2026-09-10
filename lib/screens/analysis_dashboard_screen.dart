import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../providers/analytics_provider.dart';
class AnalysisDashboardScreen extends ConsumerWidget {
  const AnalysisDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('誤答分析'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: analytics.topicStats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('分析データがまだありません'),
                  Text('問題を解いて履歴を溜めましょう'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 全体成績
                    _OverallScoreCard(analytics: analytics),
                    const SizedBox(height: 24),

                    // レーダーチャート
                    _RadarChartSection(analytics: analytics),
                    const SizedBox(height: 24),

                    // 苦手トピック
                    _WeakTopicsSection(analytics: analytics),
                  ],
                ),
              ),
            ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  final AnalyticsState analytics;

  const _OverallScoreCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final rate = analytics.overallCorrectRate;
    final percentage = (rate * 100).toStringAsFixed(1);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '全体正答率',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: rate,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 8,
                    ),
                  ),
                  Text(
                    '${(rate * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarChartSection extends StatelessWidget {
  final AnalyticsState analytics;

  const _RadarChartSection({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final topics = analytics.topicStats.values.toList()
      ..sort((a, b) => b.correctRate.compareTo(a.correctRate));
    if (topics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'トピック別正答率',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...topics.map((topic) {
          final rate = topic.correctRate;
          final percentage = (rate * 100).toInt();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(topic.topic, style: const TextStyle(fontSize: 14)),
                    Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(_rateColor(rate)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class _WeakTopicsSection extends StatelessWidget {
  final AnalyticsState analytics;

  const _WeakTopicsSection({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final weakTopics = analytics.getWeakTopics();
    if (weakTopics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '苦手トピック TOP 3',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...weakTopics.asMap().entries.map((e) {
          final index = e.key + 1;
          final topic = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _WeakTopicTile(
              rank: index,
              topic: topic,
            ),
          );
        }),
      ],
    );
  }
}

class _WeakTopicTile extends StatelessWidget {
  final int rank;
  final TopicStats topic;

  const _WeakTopicTile({
    required this.rank,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final rate = topic.correctRate;
    final percentage = (rate * 100).toStringAsFixed(1);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _rankColor(rank),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(topic.topic),
        subtitle: Text('${topic.correctCount}/${topic.totalAttempts} 正解'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _rateColor(rate),
              ),
            ),
            Text(
              '正答率',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.red.shade500;
      case 2:
        return Colors.orange.shade500;
      case 3:
        return Colors.amber.shade600;
      default:
        return Colors.grey;
    }
  }

  Color _rateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
