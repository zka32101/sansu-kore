import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/quest_model.dart';
import '../data/stage_data.dart';
import 'coin_provider.dart';

// 全問正解ボーナス
const int kWeeklyChallengeRewardCoins = 50;

// ウィークリーチャレンジ — 毎週月曜リセット、10問
const _wcStateKey = 'weekly_challenge_state';
const _wcStreakKey = 'weekly_challenge_streak'; // 連続完走週数
const _wcLastWeekKey = 'weekly_challenge_last_week'; // 最後に完走した週キー

class WeeklyChallengeState {
  final int weekKey; // yyyyWww で表す週番号
  final List<String> questionIds; // 今週の10問のID
  final Set<String> answeredIds; // 正解済みID
  final bool rewardClaimed;

  const WeeklyChallengeState({
    required this.weekKey,
    required this.questionIds,
    required this.answeredIds,
    this.rewardClaimed = false,
  });

  int get completed => answeredIds.length;
  int get total => questionIds.length;
  bool get isAllDone => total > 0 && completed >= total;
  double get progress => total == 0 ? 0 : completed / total;

  WeeklyChallengeState copyWith({
    int? weekKey,
    List<String>? questionIds,
    Set<String>? answeredIds,
    bool? rewardClaimed,
  }) {
    return WeeklyChallengeState(
      weekKey: weekKey ?? this.weekKey,
      questionIds: questionIds ?? this.questionIds,
      answeredIds: answeredIds ?? this.answeredIds,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekKey': weekKey,
    'questionIds': questionIds,
    'answeredIds': answeredIds.toList(),
    'rewardClaimed': rewardClaimed,
  };

  factory WeeklyChallengeState.fromJson(Map<String, dynamic> json) =>
      WeeklyChallengeState(
        weekKey: json['weekKey'] as int,
        questionIds: (json['questionIds'] as List).cast<String>(),
        answeredIds: (json['answeredIds'] as List).cast<String>().toSet(),
        rewardClaimed: json['rewardClaimed'] as bool? ?? false,
      );
}

// 今週の週キー（例: 2026年24週 → 202624）
int _currentWeekKey() {
  final now = DateTime.now();
  // ISO week number
  final startOfYear = DateTime(now.year, 1, 1);
  final diff = now.difference(startOfYear).inDays;
  final weekNum = (diff / 7).floor() + 1;
  return now.year * 100 + weekNum;
}

// 週キーをシードとして10問を選ぶ
List<QuizQuestion> _selectWeeklyQuestions(int weekKey) {
  final all = getAllStages().expand((s) => s.questions).toList();
  if (all.isEmpty) return [];

  // シードベースの疑似ランダム選択（週ごとに違う問題）
  final seed = weekKey;
  final indices = <int>[];
  var r = seed;
  while (indices.length < 10 && indices.length < all.length) {
    r = (r * 1664525 + 1013904223) & 0xFFFFFFFF;
    final idx = r % all.length;
    if (!indices.contains(idx)) indices.add(idx);
  }
  return indices.map((i) => all[i]).toList();
}

class WeeklyChallengeNotifier extends Notifier<WeeklyChallengeState> {
  @override
  WeeklyChallengeState build() => WeeklyChallengeState(
    weekKey: _currentWeekKey(),
    questionIds: [],
    answeredIds: {},
  );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_wcStateKey);
    final currentWeek = _currentWeekKey();

    if (json != null) {
      final saved = WeeklyChallengeState.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
      if (saved.weekKey == currentWeek) {
        // 同じ週 → 復元
        state = saved;
        return;
      }
    }

    // 新しい週 → リセット
    final questions = _selectWeeklyQuestions(currentWeek);
    final newState = WeeklyChallengeState(
      weekKey: currentWeek,
      questionIds: questions.map((q) => q.id).toList(),
      answeredIds: {},
    );
    state = newState;
    await _save(newState);
  }

  Future<void> recordCorrect(String questionId) async {
    if (state.answeredIds.contains(questionId)) return;
    final newSet = {...state.answeredIds, questionId};
    final newState = state.copyWith(answeredIds: newSet);
    state = newState;
    await _save(newState);
  }

  Future<void> claimReward() async {
    // 二重付与防止: 全問正解していない、または既に受け取り済みなら何もしない
    if (!state.isAllDone || state.rewardClaimed) return;

    final newState = state.copyWith(rewardClaimed: true);
    state = newState;
    await _save(newState);

    // コインを実際に付与
    await ref.read(coinProvider.notifier).addCoins(kWeeklyChallengeRewardCoins);

    // ウィークリーチャレンジ完走時に連続カウント更新
    if (state.isAllDone) {
      final prefs = await SharedPreferences.getInstance();
      final lastWeek = prefs.getInt(_wcLastWeekKey) ?? 0;
      final currentStreak = prefs.getInt(_wcStreakKey) ?? 0;

      // 前週から連続していてるかチェック（隔週で完走した場合はリセット）
      final newStreak = lastWeek + 1 == state.weekKey ? currentStreak + 1 : 1;
      await prefs.setInt(_wcStreakKey, newStreak);
      await prefs.setInt(_wcLastWeekKey, state.weekKey);
    }
  }

  Future<void> _save(WeeklyChallengeState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wcStateKey, jsonEncode(s.toJson()));
  }

  // 今週の問題リストを返す
  List<QuizQuestion> get weeklyQuestions {
    final all = getAllStages().expand((s) => s.questions).toList();
    return all.where((q) => state.questionIds.contains(q.id)).toList();
  }
}

final weeklyChallengeProvider =
    NotifierProvider<WeeklyChallengeNotifier, WeeklyChallengeState>(
        WeeklyChallengeNotifier.new);
