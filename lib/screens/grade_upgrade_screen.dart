import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/grade_upgrade_provider.dart';
class GradeUpgradeScreen extends ConsumerStatefulWidget {
  final int newGrade;
  final int previousGrade;
  final VoidCallback? onDismiss;

  const GradeUpgradeScreen({
    Key? key,
    required this.newGrade,
    required this.previousGrade,
    this.onDismiss,
  }) : super(key: key);

  @override
  ConsumerState<GradeUpgradeScreen> createState() =>
      _GradeUpgradeScreenState();
}

class _GradeUpgradeScreenState extends ConsumerState<GradeUpgradeScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _floatController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // スケールアニメーション（0.5 → 1.0）
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // 浮遊アニメーション
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 背景グラデーション
              AnimatedBuilder(
                animation: Listenable.merge([_scaleAnimation, _floatAnimation]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: _buildCelebrationCard(context, isMobile),
              ),
              const SizedBox(height: 32),
              // ボタン
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// お祝いカード
  Widget _buildCelebrationCard(BuildContext context, bool isMobile) {
    return Container(
      width: isMobile
          ? MediaQuery.of(context).size.width - 32
          : 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🎉 アイコン
          const Text(
            '🎉',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),

          // タイトル
          Text(
            '学年がアップしました！',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 学年表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.previousGrade}年生 → ${widget.newGrade}年生',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_getGradeMessage(widget.newGrade)}へようこそ！',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // メッセージ
          Text(
            '難しい問題がたくさん待っています。\n頑張って新しい学年を乗り切ろう！',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // パーティクル背景
          _buildParticles(),
        ],
      ),
    );
  }

  /// 学年別メッセージ
  String _getGradeMessage(int grade) {
    switch (grade) {
      case 1:
        return '1年生（初級）';
      case 2:
        return '2年生（基本）';
      case 3:
        return '3年生（中級）';
      case 4:
        return '4年生（応用）';
      case 5:
        return '5年生（高度）';
      case 6:
        return '6年生（最高難度）';
      default:
        return '新しい学年';
    }
  }

  /// パーティクル効果
  Widget _buildParticles() {
    return SizedBox(
      height: 60,
      child: Stack(
        children: List.generate(5, (index) {
          return Positioned(
            left: (index * 80.0) % 400,
            top: (index * 30.0) % 60,
            child: Text(
              _getParticleEmoji(index),
              style: const TextStyle(fontSize: 24),
            ),
          );
        }),
      ),
    );
  }

  /// パーティクル用絵文字
  String _getParticleEmoji(int index) {
    const emojis = ['⭐', '✨', '🌟', '💫', '🎊'];
    return emojis[index % emojis.length];
  }

  /// アクションボタン
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // メインボタン
        SizedBox(
          width: 200,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              widget.onDismiss?.call();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '新しいステージへ！',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // サブボタン
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            '後で見る',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 学年アップグレード通知ダイアログ
void showGradeUpgradeDialog(
  BuildContext context, {
  required int newGrade,
  required int previousGrade,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return GradeUpgradeScreen(
        newGrade: newGrade,
        previousGrade: previousGrade,
        onDismiss: onDismiss,
      );
    },
  );
}

/// 学年アップグレードチェック用ウィジェット
class GradeUpgradeChecker extends ConsumerStatefulWidget {
  final Widget child;

  const GradeUpgradeChecker({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<GradeUpgradeChecker> createState() =>
      _GradeUpgradeCheckerState();
}

class _GradeUpgradeCheckerState extends ConsumerState<GradeUpgradeChecker> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkGradeUpgrade();
  }

  Future<void> _checkGradeUpgrade() async {
    if (_checked) return;
    _checked = true;

    try {
      final gradeUpgradeService =
          ref.read(gradeUpgradeProvider);
      final currentGrade =
          await gradeUpgradeService.getCurrentGrade();

      // 4月チェック
      final upgraded = await gradeUpgradeService
          .checkAndUpgradeGradeIfNeeded();

      if (upgraded && mounted) {
        final newGrade = currentGrade + 1;
        showGradeUpgradeDialog(
          context,
          newGrade: newGrade,
          previousGrade: currentGrade,
        );
      }
    } catch (e) {
      print('Error checking grade upgrade: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
