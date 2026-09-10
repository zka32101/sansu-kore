import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../providers/coin_provider.dart';
import '../providers/daily_login_provider.dart';
import '../theme/app_theme.dart';
class DailyBonusScreen extends ConsumerStatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  ConsumerState<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends ConsumerState<DailyBonusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    final coins = await ref.read(dailyLoginProvider.notifier).claimBonus();
    await ref.read(coinProvider.notifier).addCoins(coins);
    setState(() => _claimed = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyLoginProvider);
    final reward = daily.todayReward;
    final streak = daily.loginStreak;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF9F9), Color(0xFFFFE8E8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '今日のプレゼント 📦',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark),
              ),
              const SizedBox(height: 20),
              // 7日間カレンダー
              _DayCalendar(currentDay: streak),
              const SizedBox(height: 20),
              if (!_claimed) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPrimaryColor.withAlpha(60)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        reward.isSpecial ? '🎁 特別ボーナス！' : '🪙 コイン獲得！',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: reward.isSpecial ? kAccentOrange : kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 連続ログイン特典メッセージ
                if (streak >= 7)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🏆 7日連続達成！\nバッジ「1週間皆勤」をゲットしよう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kTextDark),
                    ),
                  ),
                if (streak >= 14)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4EDDA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⭐ 14日連続！\n限定キャラ「ニチニチ」獲得まであと少し！',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kTextDark),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: daily.todayClaimed ? null : _claim,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: kPrimaryColor,
                  ),
                  child: const Text('受け取る！ 🎁', style: TextStyle(fontSize: 16)),
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Icon(Icons.check_circle, color: kAccentGreen, size: 64),
                const SizedBox(height: 8),
                const Text(
                  'もらったよ！\n今日もがんばろう！',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.read(dailyLoginProvider.notifier).dismissPopup();
                  Navigator.of(context).pop();
                },
                child: const Text('閉じる', style: TextStyle(color: kTextMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCalendar extends StatelessWidget {
  final int currentDay;
  const _DayCalendar({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    final todayIdx = ((currentDay - 1) % 7).clamp(0, 6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final reward = kDailyRewards[i];
        final isPast = i < todayIdx;
        final isToday = i == todayIdx;
        return Column(
          children: [
            Text('${i + 1}日', style: TextStyle(fontSize: 10, color: isToday ? kPrimaryColor : kTextMuted)),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPast
                    ? kAccentGreen.withAlpha(40)
                    : isToday
                        ? kPrimaryColor
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: isToday ? Border.all(color: kPrimaryColor, width: 2) : null,
              ),
              child: Center(
                child: Text(
                  reward.isSpecial ? '🎁' : '🪙',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (isPast)
              const Icon(Icons.check, color: kAccentGreen, size: 12),
          ],
        );
      }),
    );
  }
}
