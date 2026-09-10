import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../services/notification_service.dart';
class RetentionNotificationsState {
  final bool streakReminderSent;
  final bool challengeReminderSent;
  final bool reviewPromptShown;
  final DateTime? lastStreakReminderDate;
  final DateTime? lastChallengeReminderDate;
  final DateTime? lastReviewPromptDate;
  final int questsCompletedSinceReview;

  const RetentionNotificationsState({
    this.streakReminderSent = false,
    this.challengeReminderSent = false,
    this.reviewPromptShown = false,
    this.lastStreakReminderDate,
    this.lastChallengeReminderDate,
    this.lastReviewPromptDate,
    this.questsCompletedSinceReview = 0,
  });

  RetentionNotificationsState copyWith({
    bool? streakReminderSent,
    bool? challengeReminderSent,
    bool? reviewPromptShown,
    DateTime? lastStreakReminderDate,
    DateTime? lastChallengeReminderDate,
    DateTime? lastReviewPromptDate,
    int? questsCompletedSinceReview,
  }) {
    return RetentionNotificationsState(
      streakReminderSent: streakReminderSent ?? this.streakReminderSent,
      challengeReminderSent: challengeReminderSent ?? this.challengeReminderSent,
      reviewPromptShown: reviewPromptShown ?? this.reviewPromptShown,
      lastStreakReminderDate: lastStreakReminderDate ?? this.lastStreakReminderDate,
      lastChallengeReminderDate: lastChallengeReminderDate ?? this.lastChallengeReminderDate,
      lastReviewPromptDate: lastReviewPromptDate ?? this.lastReviewPromptDate,
      questsCompletedSinceReview: questsCompletedSinceReview ?? this.questsCompletedSinceReview,
    );
  }
}

/// リテンション通知管理
class RetentionNotificationsNotifier extends StateNotifier<RetentionNotificationsState> {
  RetentionNotificationsNotifier() : super(const RetentionNotificationsState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = RetentionNotificationsState(
      streakReminderSent: prefs.getBool('retention_streak_reminder_sent') ?? false,
      challengeReminderSent: prefs.getBool('retention_challenge_reminder_sent') ?? false,
      reviewPromptShown: prefs.getBool('retention_review_prompt_shown') ?? false,
      lastStreakReminderDate: prefs.getString('retention_last_streak_reminder_date') != null
          ? DateTime.parse(prefs.getString('retention_last_streak_reminder_date')!)
          : null,
      lastChallengeReminderDate: prefs.getString('retention_last_challenge_reminder_date') != null
          ? DateTime.parse(prefs.getString('retention_last_challenge_reminder_date')!)
          : null,
      lastReviewPromptDate: prefs.getString('retention_last_review_prompt_date') != null
          ? DateTime.parse(prefs.getString('retention_last_review_prompt_date')!)
          : null,
      questsCompletedSinceReview: prefs.getInt('retention_quests_since_review') ?? 0,
    );
    this.state = state;
  }

  /// デイリーストリーク維持リマインダーを送信
  Future<void> checkAndSendStreakReminder({
    required int currentStreak,
    required String childName,
  }) async {
    final now = DateTime.now();
    final lastReminder = state.lastStreakReminderDate;

    // 前回の送信から24時間以上経過していかつ、まだ今日送信していない場合
    if (lastReminder == null || now.difference(lastReminder).inHours >= 24) {
      if (currentStreak >= 3) {
        // 3日以上のストリーク時は維持のモチベーションを高める
        final message = currentStreak >= 7
            ? '🔥 $childNameさん！$currentStreak日連続、もう1日で最高記録！'
            : '🔥 $childNameさん！$currentStreak日連続達成！明日も一緒に頑張ろう！';

        await NotificationService.triggerParentPraise(
          childName: childName,
          achievement: message,
        );
      }

      await _updateStreakReminderDate();
    }
  }

  /// ウィークリーチャレンジリマインダーを送信
  Future<void> checkAndSendChallengeReminder({
    required String childName,
    required int challengesCompleted,
    required int totalChallenges,
  }) async {
    final now = DateTime.now();
    final lastReminder = state.lastChallengeReminderDate;

    // 前回の送信から24時間以上経過している場合
    if (lastReminder == null || now.difference(lastReminder).inHours >= 24) {
      final remaining = totalChallenges - challengesCompleted;
      if (remaining > 0) {
        final message = remaining <= 2
            ? '🏆 $childNameさん！ウィークリーチャレンジ残り$remaining問！今週中にクリアできる！'
            : '📋 $childNameさん！ウィークリーチャレンジに挑戦しましょう！$remaining問残っています。';

        await NotificationService.triggerParentPraise(
          childName: childName,
          achievement: message,
        );
      }

      await _updateChallengeReminderDate();
    }
  }

  /// アプリレビュープロンプトをチェック
  /// 10問以上解いた後に表示
  Future<bool> shouldShowReviewPrompt(int questsCompleted) async {
    final now = DateTime.now();
    final lastPrompt = state.lastReviewPromptDate;
    final daysSinceLastPrompt = lastPrompt != null
        ? now.difference(lastPrompt).inDays
        : 999;

    // 前回から30日以上、かつ10問以上解いた場合
    if (daysSinceLastPrompt >= 30 && questsCompleted >= 10 && !state.reviewPromptShown) {
      return true;
    }

    return false;
  }

  /// レビュープロンプトを表示済みにマーク
  Future<void> markReviewPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setString('retention_last_review_prompt_date', now.toIso8601String());
    await prefs.setInt('retention_quests_since_review', 0);

    state = state.copyWith(
      reviewPromptShown: true,
      lastReviewPromptDate: now,
      questsCompletedSinceReview: 0,
    );
  }

  /// クエスト完了時にカウント増加
  Future<void> incrementQuestsCompletedSinceReview() async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = state.questsCompletedSinceReview + 1;

    await prefs.setInt('retention_quests_since_review', newCount);

    state = state.copyWith(questsCompletedSinceReview: newCount);
  }

  /// ストリークリマインダー日時を更新
  Future<void> _updateStreakReminderDate() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setString('retention_last_streak_reminder_date', now.toIso8601String());
    await prefs.setBool('retention_streak_reminder_sent', true);

    state = state.copyWith(
      streakReminderSent: true,
      lastStreakReminderDate: now,
    );
  }

  /// チャレンジリマインダー日時を更新
  Future<void> _updateChallengeReminderDate() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setString('retention_last_challenge_reminder_date', now.toIso8601String());
    await prefs.setBool('retention_challenge_reminder_sent', true);

    state = state.copyWith(
      challengeReminderSent: true,
      lastChallengeReminderDate: now,
    );
  }

  /// 日付が変わったときにリセット
  Future<void> resetDailyState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('retention_streak_reminder_sent', false);
    await prefs.setBool('retention_challenge_reminder_sent', false);

    state = state.copyWith(
      streakReminderSent: false,
      challengeReminderSent: false,
    );
  }
}

/// リテンション通知 Provider
final retentionNotificationsProvider =
    StateNotifierProvider<RetentionNotificationsNotifier, RetentionNotificationsState>(
  (ref) {
    return RetentionNotificationsNotifier();
  },
);
