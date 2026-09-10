import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
const _analyticsPrefKey = 'analytics_v1';

/// トピック別の正答率統計
class TopicStats {
  final String topic;
  final int totalAttempts;
  final int correctCount;

  const TopicStats({
    required this.topic,
    required this.totalAttempts,
    required this.correctCount,
  });

  double get correctRate => totalAttempts == 0 ? 0 : correctCount / totalAttempts;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'totalAttempts': totalAttempts,
        'correctCount': correctCount,
      };

  factory TopicStats.fromJson(Map<String, dynamic> json) => TopicStats(
        topic: json['topic'] as String,
        totalAttempts: json['totalAttempts'] as int,
        correctCount: json['correctCount'] as int,
      );
}

class AnalyticsState {
  final Map<String, TopicStats> topicStats;
  final int totalWrongAnswers;

  const AnalyticsState({
    this.topicStats = const {},
    this.totalWrongAnswers = 0,
  });

  AnalyticsState copyWith({
    Map<String, TopicStats>? topicStats,
    int? totalWrongAnswers,
  }) =>
      AnalyticsState(
        topicStats: topicStats ?? this.topicStats,
        totalWrongAnswers: totalWrongAnswers ?? this.totalWrongAnswers,
      );

  /// 正答率の低いトピックTOP3を返す（苦手トピック）
  List<TopicStats> getWeakTopics() {
    final sorted = topicStats.values.toList()
      ..sort((a, b) => a.correctRate.compareTo(b.correctRate));
    return sorted.take(3).toList();
  }

  /// 全体の正答率（全トピック合計）
  double get overallCorrectRate {
    final total = topicStats.values.fold<int>(0, (s, t) => s + t.totalAttempts);
    final correct = topicStats.values.fold<int>(0, (s, t) => s + t.correctCount);
    return total == 0 ? 0 : correct / total;
  }
}

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  @override
  AnalyticsState build() {
    _init();
    return const AnalyticsState();
  }

  Future<void> _init() async {
    await _loadLocal();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _syncFromFirestore(userId);
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_analyticsPrefKey);
    if (raw == null) return;

    try {
      final map = (raw.split('|')).map((entry) {
        final parts = entry.split(':');
        return TopicStats.fromJson({
          'topic': parts[0],
          'totalAttempts': int.parse(parts[1]),
          'correctCount': int.parse(parts[2]),
        });
      });

      final statsMap = <String, TopicStats>{
        for (final stat in map) stat.topic: stat,
      };
      state = state.copyWith(topicStats: statsMap);
    } catch (_) {}
  }

  Future<void> _syncFromFirestore(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snap = await firestore
          .collection('users')
          .doc(userId)
          .collection('wrongAnswers')
          .get();

      final statsMap = <String, TopicStats>{};
      for (final doc in snap.docs) {
        final topic = doc['topic'] as String? ?? 'Unknown';
        if (!statsMap.containsKey(topic)) {
          statsMap[topic] = TopicStats(
            topic: topic,
            totalAttempts: 0,
            correctCount: 0,
          );
        }
      }

      // ここでローカルとマージ
      final merged = Map<String, TopicStats>.from(state.topicStats);
      statsMap.forEach((k, v) {
        if (!merged.containsKey(k)) {
          merged[k] = v;
        }
      });

      state = state.copyWith(topicStats: merged);
    } catch (_) {}
  }

  /// 間違い回答を記録
  Future<void> recordWrongAnswer({
    required String topic,
    required bool isCorrect,
  }) async {
    final current = state.topicStats[topic] ?? TopicStats(topic: topic, totalAttempts: 0, correctCount: 0);
    final updated = TopicStats(
      topic: topic,
      totalAttempts: current.totalAttempts + 1,
      correctCount: isCorrect ? current.correctCount + 1 : current.correctCount,
    );

    final newMap = Map<String, TopicStats>.from(state.topicStats);
    newMap[topic] = updated;
    state = state.copyWith(topicStats: newMap);

    // ローカル保存
    await _saveLocal(newMap);

    // Firestore保存
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('analytics')
          .add({
        'topic': topic,
        'isCorrect': isCorrect,
        'recordedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _saveLocal(Map<String, TopicStats> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = stats.values
        .map((s) => '${s.topic}:${s.totalAttempts}:${s.correctCount}')
        .join('|');
    await prefs.setString(_analyticsPrefKey, encoded);
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(
  AnalyticsNotifier.new,
);
