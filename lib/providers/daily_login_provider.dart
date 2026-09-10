import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
const _lastLoginKey = 'daily_last_login';
const _loginStreakKey = 'daily_login_streak';
const _totalLoginDaysKey = 'daily_total_login_days';
const _todayClaimedKey = 'daily_today_claimed';

// デイリーボーナス報酬定義（7日サイクル）
// 国語コレ（shared_core の calcDailyBonus）と同じ報酬額に統一
const List<DailyReward> kDailyRewards = [
  DailyReward(day: 1, coins: 5, label: 'コイン5枚'),
  DailyReward(day: 2, coins: 10, label: 'コイン10枚'),
  DailyReward(day: 3, coins: 15, label: 'コイン15枚'),
  DailyReward(day: 4, coins: 15, label: 'コイン15枚'),
  DailyReward(day: 5, coins: 20, label: 'コイン20枚'),
  DailyReward(day: 6, coins: 20, label: 'コイン20枚'),
  DailyReward(day: 7, coins: 50, label: 'ウィークリーボックス！', isSpecial: true),
];

class DailyReward {
  final int day;
  final int coins;
  final String label;
  final bool isSpecial;

  const DailyReward({
    required this.day,
    required this.coins,
    required this.label,
    this.isSpecial = false,
  });
}

class DailyLoginState {
  final int loginStreak;        // 連続ログイン日数（1〜7でサイクル）
  final int totalLoginDays;     // 累計ログイン日数
  final bool todayClaimed;      // 今日受け取り済みか
  final bool showBonusPopup;    // ポップアップ表示フラグ
  final DateTime? lastLoginDate;

  const DailyLoginState({
    this.loginStreak = 0,
    this.totalLoginDays = 0,
    this.todayClaimed = false,
    this.showBonusPopup = false,
    this.lastLoginDate,
  });

  // 今日の報酬（1〜7 のサイクル位置）
  DailyReward get todayReward {
    final idx = ((loginStreak - 1) % 7).clamp(0, 6);
    return kDailyRewards[idx];
  }

  DailyLoginState copyWith({
    int? loginStreak,
    int? totalLoginDays,
    bool? todayClaimed,
    bool? showBonusPopup,
    DateTime? lastLoginDate,
  }) {
    return DailyLoginState(
      loginStreak: loginStreak ?? this.loginStreak,
      totalLoginDays: totalLoginDays ?? this.totalLoginDays,
      todayClaimed: todayClaimed ?? this.todayClaimed,
      showBonusPopup: showBonusPopup ?? this.showBonusPopup,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
}

class DailyLoginNotifier extends Notifier<DailyLoginState> {
  @override
  DailyLoginState build() => const DailyLoginState();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastLoginKey);
    final streak = prefs.getInt(_loginStreakKey) ?? 0;
    final total = prefs.getInt(_totalLoginDaysKey) ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool todayClaimed = false;
    bool showPopup = false;
    int newStreak = streak;
    int newTotal = total;

    if (lastStr != null) {
      final lastLogin = DateTime.tryParse(lastStr);
      if (lastLogin != null) {
        final lastDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
        final diff = today.difference(lastDay).inDays;

        if (diff == 0) {
          // 今日はすでにログイン済み
          todayClaimed = prefs.getBool(_todayClaimedKey) ?? false;
        } else if (diff == 1) {
          // 昨日からの継続 → ポップアップ表示
          newStreak = streak + 1;
          newTotal = total + 1;
          showPopup = true;
          await _saveStreak(prefs, newStreak, newTotal, today);
        } else {
          // ストリーク切れ → リセット
          newStreak = 1;
          newTotal = total + 1;
          showPopup = true;
          await _saveStreak(prefs, newStreak, newTotal, today);
        }
      }
    } else {
      // 初回ログイン
      newStreak = 1;
      newTotal = 1;
      showPopup = true;
      await _saveStreak(prefs, newStreak, newTotal, today);
    }

    state = DailyLoginState(
      loginStreak: newStreak,
      totalLoginDays: newTotal,
      todayClaimed: todayClaimed,
      showBonusPopup: showPopup,
      lastLoginDate: today,
    );
  }

  Future<void> _saveStreak(SharedPreferences prefs, int streak, int total, DateTime today) async {
    await prefs.setInt(_loginStreakKey, streak);
    await prefs.setInt(_totalLoginDaysKey, total);
    await prefs.setString(_lastLoginKey, today.toIso8601String());
    await prefs.setBool(_todayClaimedKey, false);
  }

  Future<int> claimBonus() async {
    if (state.todayClaimed) return 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_todayClaimedKey, true);
    state = state.copyWith(todayClaimed: true, showBonusPopup: false);
    return state.todayReward.coins;
  }

  void dismissPopup() {
    state = state.copyWith(showBonusPopup: false);
  }
}

final dailyLoginProvider =
    NotifierProvider<DailyLoginNotifier, DailyLoginState>(DailyLoginNotifier.new);
