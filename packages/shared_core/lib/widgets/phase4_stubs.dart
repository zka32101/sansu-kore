// Phase 4.2-4.23: Stub implementations for v3.2.1 release
// These are placeholder implementations to enable compilation during the transition period.
// Full implementations will be added in Phase 4.5+

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Providers ==========
// Stub provider for missions
final missionProvider = StateNotifierProvider<_MissionNotifier, MissionState>((ref) {
  return _MissionNotifier();
});

class _MissionNotifier extends StateNotifier<MissionState> {
  _MissionNotifier() : super(MissionState(
    missions: [],
    totalCoinsToday: 0,
    error: null,
  ));

  Future<void> initializeMissions(String userId) async {
    state = MissionState(
      missions: [],
      totalCoinsToday: 0,
      error: null,
    );
  }

  Future<Map<String, dynamic>> awardMissionRewards({
    required String userId,
    required String missionId,
  }) async {
    return <String, dynamic>{'coins': 0};
  }

  Future<void> detectMissionProgress({
    required String userId,
    required String subject,
    required int questionsCorrect,
    required bool isPerfectStreak,
  }) async {
    // No-op stub
  }
}

// Stub provider for notifications
final notificationProvider = StateNotifierProvider<_NotificationNotifier, List<AppNotification>>((ref) {
  return _NotificationNotifier();
});

class _NotificationNotifier extends StateNotifier<List<AppNotification>> {
  _NotificationNotifier() : super([]);
}

// Stub provider for global ranking
final globalRankingProvider = StateNotifierProvider<_GlobalRankingNotifier, List<RankingEntry>>((ref) {
  return _GlobalRankingNotifier();
});

class _GlobalRankingNotifier extends StateNotifier<List<RankingEntry>> {
  _GlobalRankingNotifier() : super([]);

  Future<void> updateRanking({
    required String userId,
    required int score,
  }) async {}

  Future<void> fetchGlobalRanking() async {
    state = [];
  }
}

// Stub provider for weekly bonus
final weeklyBonusProvider = StateNotifierProvider<_WeeklyBonusNotifier, int>((ref) {
  return _WeeklyBonusNotifier();
});

class _WeeklyBonusNotifier extends StateNotifier<int> {
  _WeeklyBonusNotifier() : super(0);

  Future<void> recordDailyCompletion() async {}
}

// ========== Models ==========
class MissionState {
  final List<Mission> missions;
  final int totalCoinsToday;
  final String? error;

  MissionState({
    required this.missions,
    required this.totalCoinsToday,
    this.error,
  });

  bool get isLoading => false;
}

class MissionDetail {
  final String missionId;
  final String name;
  final String title;
  final String description;
  final String difficulty;
  final int targetValue;
  final List<MissionReward> rewards;

  MissionDetail({
    required this.missionId,
    required this.name,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.targetValue,
    required this.rewards,
  });
}

class MissionProgress {
  final int currentValue;
  final bool completed;

  MissionProgress({
    required this.currentValue,
    required this.completed,
  });
}

class Mission {
  final int id;
  final String subject;
  final bool enabled;
  final MissionDetail mission;
  final MissionProgress? progress;
  final double progressPercentage;

  Mission({
    required this.id,
    required this.subject,
    required this.enabled,
    required this.mission,
    this.progress,
    this.progressPercentage = 0.0,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String type;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.type,
    required this.createdAt,
  });
}

enum RewardType { coins, badges, characterExp }

class MissionReward {
  final RewardType type;
  final int amount;

  MissionReward({
    required this.type,
    required this.amount,
  });
}

class RankingEntry {
  final String userId;
  final String userName;
  final int score;
  final int rank;

  RankingEntry({
    required this.userId,
    required this.userName,
    required this.score,
    required this.rank,
  });

  static RankingEntry withRecalculatedRanks(List<RankingEntry> entries) {
    return entries.isNotEmpty ? entries.first : RankingEntry(
      userId: '',
      userName: '',
      score: 0,
      rank: 0,
    );
  }
}

// ========== Widgets ==========
class FriendsListPage extends StatelessWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('フレンド一覧')),
      body: const Center(
        child: Text('フレンド機能は準備中です (Phase 4.4)'),
      ),
    );
  }
}

class DailyMissionPage extends StatelessWidget {
  final Color primaryColor;
  final String appTitle;
  final String filterSubject;

  const DailyMissionPage({
    super.key,
    required this.primaryColor,
    required this.appTitle,
    required this.filterSubject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('デイリーミッション')),
      body: const Center(
        child: Text('ミッション機能は準備中です (Phase 4.5)'),
      ),
    );
  }
}

class NotificationBadge extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onPressed;

  const NotificationBadge({
    super.key,
    required this.notificationCount,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: onPressed,
        ),
        if (notificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
              child: Text(
                notificationCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

class WeeklyBonusWidget extends ConsumerWidget {
  final Function(int) onBonusClaimed;

  const WeeklyBonusWidget({
    super.key,
    required this.onBonusClaimed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '週次ボーナス',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('7日連続で学習してボーナスコインをゲットしよう！'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => onBonusClaimed(500),
              child: const Text('ボーナスを確認'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFriendDialog extends StatelessWidget {
  const AddFriendDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('フレンドを探す'),
      content: const Text('フレンド機能は準備中です (Phase 4.4)'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  final String userId;

  const NotificationSettingsPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: const Center(
        child: Text('通知設定は準備中です (Phase 4.23)'),
      ),
    );
  }
}

class RetentionDashboard extends StatelessWidget {
  const RetentionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('リテンション分析')),
      body: const Center(
        child: Text('分析ダッシュボードは準備中です (Phase 4.23)'),
      ),
    );
  }
}

class PremiumGateWidget extends StatelessWidget {
  final Widget child;

  const PremiumGateWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プレミアム機能')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('プレミアム機能は準備中です (Phase 4.2)'),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class CoachingDashboard extends StatelessWidget {
  const CoachingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI コーチング')),
      body: const Center(
        child: Text('AI コーチング機能は準備中です'),
      ),
    );
  }
}
