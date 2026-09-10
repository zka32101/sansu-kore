import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../data/badge_data.dart';
import '../providers/badge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/badge_display_widget.dart';
class BadgeCollectionScreen extends ConsumerWidget {
  const BadgeCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeState = ref.watch(badgeProvider);
    final earned = badgeState.earnedBadges;

    return Scaffold(
      appBar: AppBar(
        title: const Text('バッジコレクション'),
        backgroundColor: kPrimaryColor,
      ),
      body: Column(
        children: [
          // サマリー
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFF9C4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${earned.length} / ${allSansuBadges.length} バッジ獲得',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(earned.length / allSansuBadges.length * 100).toStringAsFixed(1)}% 達成！',
                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // バッジ一覧（カテゴリ別）
          Expanded(
            child: BadgeCollectionView(
              earnedBadges: earned,
              allAvailableBadges: allSansuBadges,
            ),
          ),
        ],
      ),
    );
  }
}
