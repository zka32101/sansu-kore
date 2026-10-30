import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show
        answerStreakProvider,
        notificationPlanProvider,
        onboardingProvider,
        retentionTrackerProvider,
        reviewQueueProvider,
        weeklyChallengeProvider;

import '../providers/daily_login_provider.dart';
import 'study_reminder_service.dart';

/// 定着率施策（shared_core の retention）の保存データを起動時に読み込む。
/// 失敗しても起動は止めない。
Future<void> initRetention(ProviderContainer container) async {
  try {
    await Future.wait([
      container.read(onboardingProvider.notifier).load(),
      container.read(reviewQueueProvider.notifier).load(),
      container.read(weeklyChallengeProvider.notifier).load(),
      container.read(notificationPlanProvider.notifier).load(),
      container.read(retentionTrackerProvider.notifier).load(),
    ]);
  } catch (e) {
    debugPrint('[Retention] 初期化スキップ: $e');
  }
}

/// クイズ 1 問に回答したときに呼ぶ。連続正解ボーナス・週次チャレンジ・
/// 間違い復習キュー・学習時間帯の記録をまとめて行う。
///
/// ref の read はすべて await より前に行う（画面が閉じた後でも安全）。
/// ボーナスコインが付いたら [context] にスナックバーで知らせる。
Future<void> onQuizAnswered(
  WidgetRef ref, {
  required String quizId,
  required bool correct,
  BuildContext? context,
  bool recordReview = true,
}) async {
  try {
    final streak = ref.read(answerStreakProvider.notifier);
    final weekly = ref.read(weeklyChallengeProvider.notifier);
    final review = ref.read(reviewQueueProvider.notifier);
    final tracker = ref.read(retentionTrackerProvider.notifier);
    final plan = ref.read(notificationPlanProvider.notifier);
    final messenger = context == null
        ? null
        : ScaffoldMessenger.maybeOf(context);
    final streakDays = ref.read(dailyLoginProvider).loginStreak;

    final bonus = await streak.recordAnswer(correct);
    final weeklyReward = correct ? await weekly.recordCorrectAnswer() : 0;
    // 無限とっくんの問題IDは毎回ランダムで再出題できないため、復習キューには入れない
    if (recordReview) {
      await review.recordAnswer(quizId, correct, subject: 'math');
    }
    await tracker.markActiveToday();
    await plan.recordActivity();

    // 学習リマインダーを予約し直す（明日の時点で期限の復習件数を数える）
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await StudyReminderService.instance.reschedule(
      plan: plan,
      streak: streakDays,
      dueReviewTomorrow: review.dueIds(now: tomorrow).length,
    );

    if (messenger != null && (bonus > 0 || weeklyReward > 0)) {
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            weeklyReward > 0
                ? '🎉 今週のチャレンジ達成！ +$weeklyReward コイン'
                : '🔥 連続正解ボーナス +$bonus コイン',
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('[Retention] 回答記録をスキップ: $e');
  }
}
