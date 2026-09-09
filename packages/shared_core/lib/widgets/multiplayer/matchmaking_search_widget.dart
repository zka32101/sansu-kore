import 'dart:async';

import 'package:flutter/material.dart';

/// マッチング待機画面の共通パーツ（相手探索中のパルスアニメーション＋状態表示）。
///
/// 教科固有の内容（アバター絵柄・キャラクター等）は [avatar] スロットとして
/// 呼び出し側が自由に差し込める。参考: social_quiz_app の matching_waiting_screen.dart。
class MatchmakingSearchWidget extends StatefulWidget {
  /// 中央に表示するプレイヤーのアバター（絵文字テキストや画像など、教科ごとに自由）。
  final Widget avatar;
  final String displayName;
  final double rating;
  final double ratingRange;
  final String searchingLabel;
  final VoidCallback onCancel;
  final Color accentColor;

  const MatchmakingSearchWidget({
    super.key,
    required this.avatar,
    required this.displayName,
    required this.rating,
    required this.onCancel,
    this.ratingRange = 300.0,
    this.searchingLabel = '対戦相手を探しています...',
    this.accentColor = Colors.white,
  });

  @override
  State<MatchmakingSearchWidget> createState() => _MatchmakingSearchWidgetState();
}

class _MatchmakingSearchWidgetState extends State<MatchmakingSearchWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withOpacity(0.1),
                    border: Border.all(color: widget.accentColor.withOpacity(0.24), width: 2),
                  ),
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Center(child: widget.avatar),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          widget.displayName,
          style: TextStyle(color: widget.accentColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          widget.searchingLabel,
          style: TextStyle(color: widget.accentColor.withOpacity(0.7), fontSize: 16),
        ),
        const SizedBox(height: 8),
        _DotsAnimation(color: widget.accentColor.withOpacity(0.4)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text(
                'レート: ${widget.rating.toStringAsFixed(0)}'
                '  (±${widget.ratingRange.toStringAsFixed(0)}範囲で検索中)',
                style: TextStyle(color: widget.accentColor.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            'キャンセル',
            style: TextStyle(color: widget.accentColor.withOpacity(0.6), fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _DotsAnimation extends StatefulWidget {
  final Color color;
  const _DotsAnimation({required this.color});

  @override
  State<_DotsAnimation> createState() => _DotsAnimationState();
}

class _DotsAnimationState extends State<_DotsAnimation> {
  int _dotCount = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _dotCount = (_dotCount % 3) + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '●' * _dotCount + '○' * (3 - _dotCount),
      style: TextStyle(color: widget.color, fontSize: 14),
    );
  }
}
