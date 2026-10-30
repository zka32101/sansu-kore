import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_core/shared_core.dart'
    show
        NotificationContext,
        NotificationPlanNotifier,
        NotificationTone,
        SmartReminderScheduler;
import 'package:shared_preferences/shared_preferences.dart';

/// 学習リマインダー（ローカル通知）。shared_core の `SmartNotificationPlanner`
/// が決めた時刻・文面を、端末のローカル通知として予約する。
///
/// 学習するたびに予約し直す（毎回 cancel → 再予約）。予約するのは次の3件だけ:
/// - 翌日: 連続記録・復習の声かけ
/// - 3日後 / 7日後: 来なかったときの「おかえり」
/// 学習すれば全部置き換わるので、毎日来ている子には通知が溜まらない。
class StudyReminderService {
  StudyReminderService._();
  static final StudyReminderService instance = StudyReminderService._();

  static const _enabledKey = 'app_reminder_enabled';
  static const _idNextDay = 7001;
  static const _idAfter3Days = 7002;
  static const _idAfter7Days = 7003;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionAsked = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // 権限は初回の予約時に自分で聞く（起動直後には聞かない）
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// 保護者が通知を ON/OFF する。OFF にすると予約済みの通知も消す。
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      await _init();
      await _requestPermission();
    } else {
      await cancelAll();
    }
  }

  Future<void> cancelAll() async {
    try {
      await _init();
      for (final id in [_idNextDay, _idAfter3Days, _idAfter7Days]) {
        await _plugin.cancel(id);
      }
    } catch (e) {
      debugPrint('[Reminder] 取消をスキップ: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
  }

  /// 学習した直後に呼ぶ。[plan] は shared_core の通知計画（時刻・文面の元）。
  /// [streak] は今日までの連続日数、[dueReviewTomorrow] は明日時点の復習件数。
  Future<void> reschedule({
    required NotificationPlanNotifier plan,
    required int streak,
    required int dueReviewTomorrow,
    NotificationTone tone = NotificationTone.standard,
    DateTime? now,
  }) async {
    try {
      if (!await isEnabled()) return;
      await _init();
      await _requestPermission();

      final base = now ?? DateTime.now();
      final scheduler = SmartReminderScheduler(_plugin);

      // 今日はもう学習済みなので、どれも「明日以降」から数える。
      Future<void> schedule(int id, int daysAway, NotificationContext ctx) =>
          scheduler.schedule(
            plan.planFor(ctx, tone: tone),
            notificationId: id,
            channelId: 'study_reminder_channel',
            channelName: '学習リマインダー',
            // startTomorrow=true なので base+(daysAway-1)日の「翌日」= daysAway日後
            now: base.add(Duration(days: daysAway - 1)),
          );

      await schedule(
        _idNextDay,
        1,
        NotificationContext(
          currentStreak: streak,
          doneToday: true,
          dueReviewCount: dueReviewTomorrow,
        ),
      );
      await schedule(
        _idAfter3Days,
        3,
        const NotificationContext(daysAway: 3, doneToday: true),
      );
      await schedule(
        _idAfter7Days,
        7,
        const NotificationContext(daysAway: 7, doneToday: true),
      );
    } catch (e) {
      debugPrint('[Reminder] 予約をスキップ: $e');
    }
  }
}
