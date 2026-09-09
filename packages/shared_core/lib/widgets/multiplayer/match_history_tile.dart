import 'package:flutter/material.dart';

import '../../models/multiplayer_model.dart';

/// 対戦履歴1件分の表示行（勝敗・スコア・経過日数）。
///
/// 参考: social_quiz_app の matchmaker_screen.dart `_buildMatchCard`。
class MatchHistoryTile extends StatelessWidget {
  final MatchState match;
  final String userId;

  const MatchHistoryTile({super.key, required this.match, required this.userId});

  @override
  Widget build(BuildContext context) {
    final myScore = match.scoreFor(userId);
    final opponentId = match.opponentOf(userId);
    final opponentScore = opponentId == null ? 0 : match.scoreFor(opponentId);
    final result = match.resultFor(userId); // 'win' / 'lose' / 'draw' / null

    final resultColor = switch (result) {
      'draw' => Colors.orange,
      'win' => Colors.green,
      'lose' => Colors.red.shade400,
      _ => Colors.grey,
    };
    final resultLabel = switch (result) {
      'draw' => '引き分け',
      'win' => '勝利',
      'lose' => '敗北',
      _ => '対戦中',
    };

    final daysAgo = match.completedAt != null
        ? DateTime.now().difference(match.completedAt!).inDays
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 48,
              decoration: BoxDecoration(color: resultColor, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resultLabel,
                      style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('$myScore - $opponentScore',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Text(
              match.completedAt == null ? '' : (daysAgo == 0 ? '今日' : '$daysAgo日前'),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
