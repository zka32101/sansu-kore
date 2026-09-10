import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/quest_model.dart';

// アダプティブラーニング：トピックごとの正答率を追記
// 設計書の「ZPD（最近接発達領域）」実装
const _accuracyKey = 'topic_accuracy';
const _wrongCountKey = 'topic_wrong_streak';

class TopicAccuracy {
  final MathTopicType topic;
  final int correctCount;
  final int totalCount;
  final int consecutiveWrong; // 連続失敗数（セーフティネット用）

  const TopicAccuracy({
    required this.topic,
    required this.correctCount,
    required this.totalCount,
    this.consecutiveWrong = 0,
  });

  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;

  // アダプティブ難易度判定
  DifficultyLevel get difficulty {
    if (accuracy >= 0.85) return DifficultyLevel.advanced;
    if (accuracy >= 0.6) return DifficultyLevel.normal;
    return DifficultyLevel.review;
  }

  TopicAccuracy copyWith({int? correctCount, int? totalCount, int? consecutiveWrong}) {
    return TopicAccuracy(
      topic: topic,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
    );
  }

  Map<String, dynamic> toJson() => {
    'topic': topic.index,
    'correct': correctCount,
    'total': totalCount,
    'wrongStreak': consecutiveWrong,
  };

  factory TopicAccuracy.fromJson(Map<String, dynamic> json) => TopicAccuracy(
    topic: MathTopicType.values[json['topic'] as int],
    correctCount: json['correct'] as int,
    totalCount: json['total'] as int,
    consecutiveWrong: json['wrongStreak'] as int? ?? 0,
  );
}

enum DifficultyLevel { review, normal, advanced }

class AdaptiveState {
  final Map<MathTopicType, TopicAccuracy> topicAccuracies;
  final bool parentAlertNeeded; // つまずき検出フラグ

  const AdaptiveState({
    required this.topicAccuracies,
    this.parentAlertNeeded = false,
  });

  TopicAccuracy? getAccuracy(MathTopicType topic) => topicAccuracies[topic];

  // 最も苦手なトピック（復習推奨）
  MathTopicType? get weakestTopic {
    if (topicAccuracies.isEmpty) return null;
    final studied = topicAccuracies.entries
        .where((e) => e.value.totalCount >= 5)
        .toList();
    if (studied.isEmpty) return null;
    studied.sort((a, b) => a.value.accuracy.compareTo(b.value.accuracy));
    return studied.first.key;
  }

  // 今週のおすすめ（苦手 → 強み → 新しい分野）
  String get weeklyRecommendation {
    final weak = weakestTopic;
    if (weak != null) {
      return '${_topicName(weak)}が少し苦手みたい。復習してみよう！';
    }
    return '新しいステージに挑戦してみよう！';
  }

  // ヒント表示するべきか（正答率60%未満）- AdaptiveStateのメソッドとして定義
  bool shouldShowHint(MathTopicType topic) {
    final acc = topicAccuracies[topic];
    if (acc == null || acc.totalCount < 3) return false;
    return acc.accuracy < 0.6;
  }

  AdaptiveState copyWith({
    Map<MathTopicType, TopicAccuracy>? topicAccuracies,
    bool? parentAlertNeeded,
  }) {
    return AdaptiveState(
      topicAccuracies: topicAccuracies ?? this.topicAccuracies,
      parentAlertNeeded: parentAlertNeeded ?? this.parentAlertNeeded,
    );
  }

  static String _topicName(MathTopicType t) {
    const topicNames = {
      MathTopicType.addition: 'たし算',
      MathTopicType.subtraction: 'ひき算',
      MathTopicType.multiplication: 'かけ算',
      MathTopicType.division: 'わり算',
      MathTopicType.fraction: '分数',
      MathTopicType.decimal: '小数',
      MathTopicType.geometry: '図形',
      MathTopicType.word: '文章問題',
    };
    return topicNames[t] ?? '不明';
  }
}

class AdaptiveNotifier extends Notifier<AdaptiveState> {
  @override
  AdaptiveState build() {
    // 初期化時に非同期で load() を実行
    load();
    return const AdaptiveState(topicAccuracies: {});
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_accuracyKey);
    if (json == null) return;

    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final accuracies = <MathTopicType, TopicAccuracy>{};
    for (final entry in decoded.entries) {
      final acc = TopicAccuracy.fromJson(entry.value as Map<String, dynamic>);
      accuracies[acc.topic] = acc;
    }
    state = AdaptiveState(topicAccuracies: accuracies);
  }

  Future<void> recordAnswers({
    required MathTopicType topic,
    required int correct,
    required int total,
  }) async {
    final existing = state.topicAccuracies[topic] ??
        TopicAccuracy(topic: topic, correctCount: 0, totalCount: 0);

    final newCorrect = existing.correctCount + correct;
    final newTotal = existing.totalCount + total;
    final newWrongStreak = correct == 0
        ? existing.consecutiveWrong + 1
        : 0;

    final updated = existing.copyWith(
      correctCount: newCorrect,
      totalCount: newTotal,
      consecutiveWrong: newWrongStreak,
    );

    final newMap = Map<MathTopicType, TopicAccuracy>.from(state.topicAccuracies);
    newMap[topic] = updated;

    // セーフティネット：3回連続失敗で親向けアラート
    final needsAlert = newWrongStreak >= 3;

    final prefs = await SharedPreferences.getInstance();
    final toSave = <String, dynamic>{};
    for (final entry in newMap.entries) {
      toSave[entry.key.index.toString()] = entry.value.toJson();
    }
    await prefs.setString(_accuracyKey, jsonEncode(toSave));

    state = state.copyWith(
      topicAccuracies: newMap,
      parentAlertNeeded: needsAlert,
    );
  }

  void clearParentAlert() {
    state = state.copyWith(parentAlertNeeded: false);
  }

  // ヒント表示するべきか（正答率60%未満）
  bool shouldShowHint(MathTopicType topic) {
    final acc = state.topicAccuracies[topic];
    if (acc == null || acc.totalCount < 3) return false;
    return acc.accuracy < 0.6;
  }
}

final adaptiveProvider =
    NotifierProvider<AdaptiveNotifier, AdaptiveState>(AdaptiveNotifier.new);
