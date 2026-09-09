import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show globalRankingProvider, GlobalRankingEntry;
import '../models/ranking_model.dart';
import '../providers/ranking_provider.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 初期化時に全ランキングを取得
    Future.microtask(() async {
      final globalRanking = ref.read(globalRankingProvider.notifier);
      final ranking = ref.read(rankingProvider.notifier);

      // グローバルランキング（全7アプリ合計）
      await globalRanking.fetchGlobalRanking();

      // 教科別ランキング（算数）
      await globalRanking.fetchSubjectRanking('math');

      // ローカルフレンドランキング
      await ranking.fetchFriendsRanking();
      await ranking.fetchCurrentUserRanking();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankingState = ref.watch(rankingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'グローバル'),
            Tab(text: '教科別'),
            Tab(text: 'フレンド'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ユーザーランキング統計セクション
          if (rankingState.currentUserRanking != null)
            _UserStatsCard(userRanking: rankingState.currentUserRanking!),
          // タブ別ランキング表示
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: グローバルランキング（全7アプリ合計）
                _GlobalRankingTabView(onRefresh: () async {
                  await ref.read(globalRankingProvider.notifier).fetchGlobalRanking();
                }),
                // Tab 1: 教科別ランキング（算数）
                _SubjectRankingTabView(onRefresh: () async {
                  await ref.read(globalRankingProvider.notifier).fetchSubjectRanking('math');
                }),
                // Tab 2: フレンドランキング
                _RankingListView(
                  ranking: rankingState.friendsRanking,
                  currentUserRanking: rankingState.currentUserRanking,
                  isLoading: rankingState.isLoading,
                  error: rankingState.error,
                  onRefresh: () async {
                    await ref.read(rankingProvider.notifier).fetchFriendsRanking();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ユーザー統計カード
class _UserStatsCard extends StatelessWidget {
  final UserRankingData userRanking;

  const _UserStatsCard({required this.userRanking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade600.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'あなたの成績',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${userRanking.rank}位',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                icon: '🎯',
                label: '正答率',
                value: '${(userRanking.correctRate * 100).toStringAsFixed(1)}%',
              ),
              _StatItem(
                icon: '💯',
                label: 'スコア',
                value: '${userRanking.score}',
              ),
              _StatItem(
                icon: '⚡',
                label: '速度',
                value: '${userRanking.averageSpeed.toStringAsFixed(1)}s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 統計アイテム
class _StatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// ランキングリスト表示ウィジェット
class _RankingListView extends StatelessWidget {
  final List<UserRankingData> ranking;
  final UserRankingData? currentUserRanking;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;

  const _RankingListView({
    required this.ranking,
    required this.currentUserRanking,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && ranking.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && ranking.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('エラーが発生しました\n$error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('再度読み込む'),
            ),
          ],
        ),
      );
    }

    if (ranking.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('ランキングデータがありません'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('読み込む'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          // 現在のユーザーのランク表示
          if (currentUserRanking != null)
            _CurrentUserCard(userRanking: currentUserRanking!),

          // ランキングリスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: ranking.length,
              itemBuilder: (context, index) {
                final user = ranking[index];
                return _RankingTile(userRanking: user, index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 現在のユーザーのランク表示カード
class _CurrentUserCard extends StatelessWidget {
  final UserRankingData userRanking;

  const _CurrentUserCard({required this.userRanking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade700.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // ランク表示
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${userRanking.rank}位',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ユーザー情報
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userRanking.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '正答率: ${(userRanking.correctRate * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // スコア表示
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${userRanking.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ポイント',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ランキング一行のタイル
class _RankingTile extends StatelessWidget {
  final UserRankingData userRanking;
  final int index;

  const _RankingTile({
    required this.userRanking,
    required this.index,
  });

  /// ランクに応じたアイコン/色を返す
  ({Color color, String medal}) _getRankIcon() {
    return switch (index) {
      0 => (color: Colors.amber, medal: '🥇'),
      1 => (color: Colors.grey, medal: '🥈'),
      2 => (color: Colors.orange, medal: '🥉'),
      _ => (color: Colors.grey.shade400, medal: ''),
    };
  }

  @override
  Widget build(BuildContext context) {
    final rankIcon = _getRankIcon();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: index < 3 ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: index < 3
            ? BorderSide(color: rankIcon.color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ランク番号
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: rankIcon.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: index < 3
                    ? Text(
                        rankIcon.medal,
                        style: const TextStyle(fontSize: 20),
                      )
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: rankIcon.color,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userRanking.getDisplayName(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '正答率: ${(userRanking.correctRate * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⏱ ${userRanking.averageSpeed.toStringAsFixed(1)}s',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // スコア
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${userRanking.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'pts',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// グローバルランキング表示（全7アプリ合計）
class _GlobalRankingTabView extends ConsumerWidget {
  final Future<void> Function() onRefresh;

  const _GlobalRankingTabView({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalRankingState = ref.watch(globalRankingProvider);

    if (globalRankingState.isLoading && globalRankingState.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (globalRankingState.error != null && globalRankingState.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('エラーが発生しました\n${globalRankingState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('再度読み込む'),
            ),
          ],
        ),
      );
    }

    if (globalRankingState.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('ランキングデータがありません'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('読み込む'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: globalRankingState.entries.length,
        itemBuilder: (context, index) {
          final entry = globalRankingState.entries[index];
          return _GlobalRankingEntryTile(entry: entry, rank: index + 1);
        },
      ),
    );
  }
}

/// 教科別ランキング表示（算数）
class _SubjectRankingTabView extends ConsumerWidget {
  final Future<void> Function() onRefresh;

  const _SubjectRankingTabView({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalRankingState = ref.watch(globalRankingProvider);

    if (globalRankingState.isLoading && globalRankingState.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (globalRankingState.error != null && globalRankingState.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('エラーが発生しました\n${globalRankingState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('再度読み込む'),
            ),
          ],
        ),
      );
    }

    if (globalRankingState.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('ランキングデータがありません'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('読み込む'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: globalRankingState.entries.length,
        itemBuilder: (context, index) {
          final entry = globalRankingState.entries[index];
          return _SubjectRankingEntryTile(entry: entry, rank: index + 1);
        },
      ),
    );
  }
}

/// グローバルランキングエントリータイル
class _GlobalRankingEntryTile extends StatelessWidget {
  final GlobalRankingEntry entry;
  final int rank;

  const _GlobalRankingEntryTile({
    required this.entry,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getRankColor(rank),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      title: Text(
        entry.userName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('総スコア: ${entry.globalRank ?? 0}'),
      trailing: Text(
        '${entry.totalScore ?? 0} pts',
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[600]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange[600]!;
      default:
        return Colors.blue;
    }
  }
}

/// 教科別ランキングエントリータイル
class _SubjectRankingEntryTile extends StatelessWidget {
  final GlobalRankingEntry entry;
  final int rank;

  const _SubjectRankingEntryTile({
    required this.entry,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getRankColor(rank),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      title: Text(
        entry.userName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('算数スコア: ${entry.subjectRank ?? 0}'),
      trailing: Text(
        '${entry.subjectScore ?? 0} pts',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[600]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange[600]!;
      default:
        return Colors.green;
    }
  }
}
