import 'package:flutter/material.dart';

import '../../models/multiplayer_model.dart';

/// ランキング（リーダーボード）画面の共通表示部品。
/// TOP3のメダル表示 + 4位以降のリストを [PlayerRating] のリストから描画する。
///
/// 参考: social_quiz_app の leaderboard_screen.dart。
class LeaderboardView extends StatelessWidget {
  final List<PlayerRating> ratings;
  final String? currentUserId;
  final Color accentColor;

  const LeaderboardView({
    super.key,
    required this.ratings,
    this.currentUserId,
    this.accentColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return const Center(child: Text('ランキングがまだありません'));
    }

    final myRank = currentUserId == null
        ? -1
        : ratings.indexWhere((r) => r.userId == currentUserId);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopThree()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        if (myRank > 2) SliverToBoxAdapter(child: _buildMyRank(myRank)),
        if (myRank > 2) const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final rank = index + 1;
              if (rank <= 3) return const SizedBox.shrink();
              return _buildRankCard(rank, ratings[index]);
            },
            childCount: ratings.length,
          ),
        ),
      ],
    );
  }

  Widget _buildTopThree() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          const Text('TOP 3', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (ratings.length > 1)
                _buildMedalCard(rating: ratings[1], medal: '🥈', height: 140),
              if (ratings.isNotEmpty)
                _buildMedalCard(rating: ratings[0], medal: '🥇', height: 180),
              if (ratings.length > 2)
                _buildMedalCard(rating: ratings[2], medal: '🥉', height: 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedalCard({required PlayerRating rating, required String medal, required double height}) {
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medal, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              children: [
                Text(
                  rating.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(rating.rating.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRank(int rankIndex) {
    final rating = ratings[rankIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Text('#${rankIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rating.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('あなたの順位', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Text(
              rating.rating.toStringAsFixed(0),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard(int rank, PlayerRating rating) {
    final winRateLabel = rating.matchCount == 0
        ? '勝率: -'
        : '勝率: ${(rating.winRate * 100).toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(winRateLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Text(
                rating.rating.toStringAsFixed(0),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
