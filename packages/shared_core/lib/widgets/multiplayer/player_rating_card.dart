import 'package:flutter/material.dart';

import '../../models/multiplayer_model.dart';

/// 対戦画面（マッチメイカー画面）冒頭に表示する「自分のレーティングカード」共通パーツ。
///
/// 参考: social_quiz_app の matchmaker_screen.dart `_buildPlayerCard`。
class PlayerRatingCard extends StatelessWidget {
  final PlayerRating rating;
  final Widget avatar;
  final Color gradientStart;
  final Color gradientEnd;

  const PlayerRatingCard({
    super.key,
    required this.rating,
    required this.avatar,
    this.gradientStart = Colors.blue,
    this.gradientEnd = const Color(0xFF1565C0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradientStart.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Center(child: avatar),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'レート: ${rating.rating.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatChip(label: '${rating.wins}勝', color: Colors.green.shade300),
              const SizedBox(height: 4),
              _StatChip(label: '${rating.losses}敗', color: Colors.red.shade300),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
