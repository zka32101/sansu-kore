import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/providers/daily_challenge_provider.dart';
import 'package:sansu_kore/providers/daily_login_provider.dart';
import 'package:sansu_kore/screens/daily_challenge_screen.dart';

/// デイリーチャレンジカード - ホーム画面用
/// 本日のチャレンジ状況を表示し、タップでプレイ画面へ遷移
class DailyChallengeCard extends ConsumerWidget {
  final String userId;

  const DailyChallengeCard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeState = ref.watch(dailyChallengeProvider);
    final isAvailable = ref.watch(isChallengeAvailableProvider);
    final isCompleted = ref.watch(isChallengeCompletedProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _getGradient(isAvailable, isCompleted),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 左: 絵文字と状態
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isCompleted ? '✅' : isAvailable ? '🎯' : '⏰',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 中央: テキスト情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'デイリーチャレンジ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? '本日のチャレンジは完了しました！'
                          : isAvailable
                              ? '5問の問題に挑戦しよう'
                              : 'まもなく開始',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (isCompleted && challengeState.todayResult != null) ...[
                      const SizedBox(height: 8),
                      _buildCompletionBadge(challengeState.todayResult!),
                    ],
                  ],
                ),
              ),

              // 右: 実行ボタン
              if (isAvailable)
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: () => _navigateToDailyChallenge(context),
                )
              else
                Icon(
                  isCompleted ? Icons.check_circle : Icons.schedule,
                  color: Colors.white70,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionBadge(challengeResult) {
    final correctRate = (challengeResult.correctAnswers / challengeResult.totalQuestions * 100).toInt();
    final color = correctRate >= 80 ? Colors.yellow : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        '${challengeResult.correctAnswers}/${challengeResult.totalQuestions} 正解',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  LinearGradient _getGradient(bool isAvailable, bool isCompleted) {
    if (isCompleted) {
      return LinearGradient(
        colors: [Colors.green.shade400, Colors.green.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isAvailable) {
      return LinearGradient(
        colors: [Colors.blue.shade400, Colors.blue.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [Colors.grey.shade400, Colors.grey.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  void _navigateToDailyChallenge(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DailyChallengeScreen(userId: userId),
      ),
    );
  }
}

/// ログインボーナス表示ウィジェット - ホーム画面用
/// ログイン連続日数と報酬を表示
///
/// データは dailyLoginProvider（daily_login_provider.dart）から取得する。
/// これは SharedPreferences に永続化されており、実際に「受け取る」ボタン
/// （DailyBonusScreen）と連動している唯一のログインボーナス実装。
/// 旧 loginBonusProvider（daily_challenge_provider.dart、セッション内のみで
/// 永続化されず実際のコイン付与とも連動していなかった重複実装）は削除した。
class LoginBonusWidget extends ConsumerWidget {
  const LoginBonusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyLoginProvider);

    if (daily.loginStreak == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🔥 ログインボーナス',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStreakColor(daily.loginStreak).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStreakColor(daily.loginStreak),
                    ),
                  ),
                  child: Text(
                    '${daily.loginStreak}日連続',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStreakColor(daily.loginStreak),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ストリーク表示
            _buildStreakIndicator(daily.loginStreak),
            const SizedBox(height: 12),

            // 統計情報
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'コイン',
                    '${daily.todayReward.coins}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    '累計',
                    '${daily.totalLoginDays}日',
                    Colors.purple,
                  ),
                ),
              ],
            ),

            if (!daily.todayClaimed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ログインして報酬を受け取ろう！',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIndicator(int streak) {
    final days = List.generate(7, (i) => i + 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final isActive = day <= streak;
        final isToday = day == streak;

        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? Colors.orange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? '✓' : '・',
              style: TextStyle(
                color: isActive ? Colors.orange : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStreakColor(int streak) {
    if (streak >= 30) return Colors.purple;
    if (streak >= 14) return Colors.red;
    if (streak >= 7) return Colors.orange;
    if (streak >= 3) return Colors.amber;
    return Colors.grey;
  }
}

/// シンプルなログインボーナスバッジ（コンパクト版）
class LoginBonusBadge extends ConsumerWidget {
  const LoginBonusBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyLoginProvider);
    final streak = daily.loginStreak;
    final reward = daily.todayReward.coins;

    if (streak == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            '$streak日連続',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${reward}🪙',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
