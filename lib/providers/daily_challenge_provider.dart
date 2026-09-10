// Daily Challenge Provider - Riverpod state management for daily challenges and login bonuses
// Manages challenge state, login tracking, and reward calculations

import 'dart:convert';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/data/stage_data.dart';
import 'package:sansu_kore/models/daily_challenge_model.dart';
import 'package:sansu_kore/models/quest_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'coin_provider.dart';
const _dcChallengeKey = 'daily_challenge_current';
const _dcResultKey = 'daily_challenge_today_result';

/// Daily Challenge state management
///
/// アプリ再起動をまたいでも「今日のチャレンジ内容」「今日すでに完了したか」を
/// 保持するため、SharedPreferences に永続化する（daily_login_provider.dart と同様のパターン）。
class DailyChallengeNotifier extends Notifier<DailyChallengeState> {
  @override
  DailyChallengeState build() => DailyChallengeState();

  /// Initialize or load today's challenge
  Future<void> loadDailyChallenge() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DailyChallenge.getTodayDateOnly();

      // 保存済みの今日のチャレンジがあれば復元する
      final savedChallengeJson = prefs.getString(_dcChallengeKey);
      if (savedChallengeJson != null) {
        final saved = jsonDecode(savedChallengeJson) as Map<String, dynamic>;
        final savedDateIssued = DateTime.parse(saved['dateIssued'] as String);
        final savedIssueDateOnly = DateTime(
          savedDateIssued.year,
          savedDateIssued.month,
          savedDateIssued.day,
        );

        if (savedIssueDateOnly.isAtSameMomentAs(today)) {
          final questionIds = (saved['questionIds'] as List).cast<String>();
          final questions = _questionsByIds(questionIds);

          final challenge = DailyChallenge(
            id: saved['id'] as String,
            dateIssued: savedDateIssued,
            questions: questions,
            expiresAt: DateTime.parse(saved['expiresAt'] as String),
            baseCoinsReward: saved['baseCoinsReward'] as int? ?? 50,
            streakBonusCoins: saved['streakBonusCoins'] as int? ?? 10,
          );

          // 今日すでに完了済みなら結果も復元する
          DailyChallengeResult? todayResult;
          final resultJson = prefs.getString(_dcResultKey);
          if (resultJson != null) {
            final r = jsonDecode(resultJson) as Map<String, dynamic>;
            if (r['challengeId'] == challenge.id) {
              todayResult = DailyChallengeResult(
                challengeId: r['challengeId'] as String,
                userId: r['userId'] as String,
                completedAt: DateTime.parse(r['completedAt'] as String),
                correctAnswers: r['correctAnswers'] as int,
                totalQuestions: r['totalQuestions'] as int,
                coinsEarned: r['coinsEarned'] as int,
                badgesUnlocked: (r['badgesUnlocked'] as List).cast<String>(),
                isPerfect: r['isPerfect'] as bool? ?? false,
              );
            }
          }

          state = state.copyWith(
            currentChallenge: challenge,
            todayResult: todayResult,
            isLoading: false,
          );
          return;
        }
      }

      // 新しい日 → 新規に5問を選んで発行し、保存する
      final expiresAt = today.add(const Duration(days: 1));
      final allStages = getAllStages();
      final allQuestions = <QuizQuestion>[];
      for (final stage in allStages) {
        allQuestions.addAll(stage.questions);
      }
      allQuestions.shuffle();
      final selectedQuestions = allQuestions.take(5).toList();

      final challenge = DailyChallenge(
        dateIssued: today,
        questions: selectedQuestions,
        expiresAt: expiresAt,
      );

      await prefs.setString(
        _dcChallengeKey,
        jsonEncode({
          'id': challenge.id,
          'dateIssued': challenge.dateIssued.toIso8601String(),
          'expiresAt': challenge.expiresAt.toIso8601String(),
          'baseCoinsReward': challenge.baseCoinsReward,
          'streakBonusCoins': challenge.streakBonusCoins,
          'questionIds': challenge.questions.map((q) => q.id).toList(),
        }),
      );
      await prefs.remove(_dcResultKey);

      state = state.copyWith(
        currentChallenge: challenge,
        todayResult: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<QuizQuestion> _questionsByIds(List<String> ids) {
    final all = getAllStages().expand((s) => s.questions).toList();
    final byId = {for (final q in all) q.id: q};
    return ids.map((id) => byId[id]).whereType<QuizQuestion>().toList();
  }

  /// Record completion of today's challenge
  Future<void> completeDailyChallenge({
    required String userId,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    if (state.currentChallenge == null) return;
    if (state.todayResult != null) return; // 二重付与防止（本日すでに完了済み）

    final challenge = state.currentChallenge!;
    final isPerfect = correctAnswers == totalQuestions;

    // Calculate coins earned
    final baseReward = challenge.baseCoinsReward;
    final coinsEarned = DailyChallengeResult.calculateCoins(
      correctAnswers,
      totalQuestions,
      baseReward,
    );

    // Determine badges
    final badges = <String>[];
    if (isPerfect) {
      badges.add('完璧な挑戦');
    }
    if (totalQuestions > 0 && (correctAnswers / totalQuestions) >= 0.8) {
      badges.add('デイリーマスター');
    }

    final result = DailyChallengeResult(
      challengeId: challenge.id,
      userId: userId,
      completedAt: DateTime.now(),
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      coinsEarned: coinsEarned,
      badgesUnlocked: badges,
      isPerfect: isPerfect,
    );

    state = state.copyWith(todayResult: result);

    // 結果を永続化（アプリ再起動しても「今日は完了済み」を維持する）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _dcResultKey,
      jsonEncode({
        'challengeId': result.challengeId,
        'userId': result.userId,
        'completedAt': result.completedAt.toIso8601String(),
        'correctAnswers': result.correctAnswers,
        'totalQuestions': result.totalQuestions,
        'coinsEarned': result.coinsEarned,
        'badgesUnlocked': result.badgesUnlocked,
        'isPerfect': result.isPerfect,
      }),
    );

    // コインを実際に付与する
    await ref.read(coinProvider.notifier).addCoins(coinsEarned);
  }

  /// Reset challenge for next day (called at midnight)
  Future<void> resetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dcChallengeKey);
    await prefs.remove(_dcResultKey);
    state = state.copyWith(
      currentChallenge: null,
      todayResult: null,
    );
    await loadDailyChallenge();
  }
}

/// Providers

/// Daily challenge state provider
final dailyChallengeProvider =
    NotifierProvider<DailyChallengeNotifier, DailyChallengeState>(
        DailyChallengeNotifier.new);

/// Get today's challenge (if available)
final todaysChallengeProvider = Provider<DailyChallenge?>((ref) {
  final state = ref.watch(dailyChallengeProvider);
  if (state.currentChallenge?.isToday ?? false) {
    return state.currentChallenge;
  }
  return null;
});

/// Check if challenge is available to play today
final isChallengeAvailableProvider = Provider<bool>((ref) {
  final challengeState = ref.watch(dailyChallengeProvider);
  return challengeState.isChallengeAvailable;
});

/// Check if challenge is already completed today
final isChallengeCompletedProvider = Provider<bool>((ref) {
  final challengeState = ref.watch(dailyChallengeProvider);
  return challengeState.isChallengeCompleted;
});

/// Get total daily challenge rewards (base + streak bonus)
///
/// ログインストリークのボーナスは daily_login_provider.dart の
/// dailyLoginProvider（実際に画面から呼ばれ、SharedPreferencesで永続化されている方）
/// を参照する。旧 loginBonusProvider（未永続化・重複実装）は削除済み。
final dailyChallengeRewardsProvider = Provider<int>((ref) {
  final challengeState = ref.watch(dailyChallengeProvider);
  if (challengeState.todayResult == null) {
    return 0; // Challenge not completed
  }
  return challengeState.todayResult!.coinsEarned;
});
