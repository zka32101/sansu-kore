import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/game_mode_model.dart';
import 'package:sansu_kore/models/sound_model.dart';
import 'package:sansu_kore/models/vfx_model.dart';
import 'package:sansu_kore/providers/game_mode_provider.dart';
import 'package:sansu_kore/providers/sound_provider.dart';
import 'package:sansu_kore/providers/vfx_provider.dart';
import 'package:sansu_kore/widgets/vfx_widgets.dart';

/// チャレンジ結果画面
/// ゲーム完了後のスコア、コイン、バッジを表示
class ChallengeResultScreen extends ConsumerStatefulWidget {
  final GameResult result;

  const ChallengeResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  ConsumerState<ChallengeResultScreen> createState() =>
      _ChallengeResultScreenState();
}

class _ChallengeResultScreenState extends ConsumerState<ChallengeResultScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scoreAnimController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _scoreAnimController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // 成功時はパーティクル発動
    if (widget.result.correctRate >= 0.8) {
      _confettiController.play();
    }

    _scoreAnimController.forward();

    // Trigger VFX and sounds after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _triggerResultEffects();
      }
    });
  }

  /// 結果表示時のVFXと音声効果をトリガー
  void _triggerResultEffects() {
    // Play celebration sounds and effects based on score
    final soundPlayback = ref.read(soundPlaybackProvider.notifier);
    final vfxPlayback = ref.read(vfxPlaybackProvider.notifier);

    if (widget.result.correctRate >= 0.8) {
      // High score: play perfect sound and VFX
      soundPlayback.playSound(SoundEffect.perfect);
      vfxPlayback.playVFX(VFXPreset.perfect);
    } else if (widget.result.correctRate >= 0.6) {
      // Good score: play correct sound
      soundPlayback.playSound(SoundEffect.correct);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: VFXLayer(
        child: Scaffold(
          body: Stack(
            children: [
              // 背景グラデーション
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getModeColor(widget.result.gameMode),
                      _getModeColor(widget.result.gameMode).withOpacity(0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // コンテンツ
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      _buildResultHeader(),
                      const SizedBox(height: 32),
                      _buildScoreCard(),
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildRewardsSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // パーティクル効果
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 結果ヘッダー
  Widget _buildResultHeader() {
    final isGood = widget.result.correctRate >= 0.8;

    return Column(
      children: [
        Text(
          isGood ? '🎉' : '💪',
          style: const TextStyle(fontSize: 64),
        ),
        const SizedBox(height: 16),
        Text(
          isGood ? 'すばらしい！' : 'よくがんばった！',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getModeDisplayName(widget.result.gameMode),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// スコアカード
  Widget _buildScoreCard() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(_scoreAnimController),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'スコア',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.result.totalScore.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getModeColor(widget.result.gameMode),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreBreakdown(
                    'ベース',
                    widget.result.baseScore,
                  ),
                  _buildScoreBreakdown(
                    '速度ボーナス',
                    widget.result.speedBonus,
                  ),
                  _buildScoreBreakdown(
                    '連続ボーナス',
                    widget.result.streakBonus,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// スコア内訳
  Widget _buildScoreBreakdown(String label, int value) {
    return Column(
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
          '$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  /// 統計グリッド
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          '正答率',
          '${(widget.result.correctRate * 100).toStringAsFixed(1)}%',
          Colors.blue,
        ),
        _buildStatCard(
          '正解数',
          '${widget.result.correctAnswers}/${widget.result.totalQuestions}',
          Colors.green,
        ),
        _buildStatCard(
          '平均時間',
          '${widget.result.averageResponseTime.toStringAsFixed(1)}秒',
          Colors.purple,
        ),
        _buildStatCard(
          '連続正解',
          widget.result.maxStreak.toString(),
          Colors.orange,
        ),
      ],
    );
  }

  /// 統計カード
  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 報酬セクション
  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '獲得報酬',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // コイン獲得
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '🪙',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'コイン獲得',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${widget.result.coinsEarned} coins',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // バッジ獲得
        if (widget.result.badgesUnlocked.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'バッジ獲得',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.result.badgesUnlocked.map((badge) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          '✨ $badge',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// アクションボタン
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            ref.read(gameSessionProvider.notifier).resetSession();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _getModeColor(widget.result.gameMode),
          ),
          child: const Text(
            'モード選択に戻る',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          child: const Text(
            'ホームに戻る',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// モード別の色取得
  Color _getModeColor(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return Colors.blue.shade500;
      case GameMode.timeAttack:
        return Colors.orange.shade500;
      case GameMode.survival:
        return Colors.green.shade500;
      case GameMode.flash:
        return Colors.purple.shade500;
      case GameMode.marathon:
        return Colors.pink.shade500;
    }
  }

  /// モード別の表示名取得
  String _getModeDisplayName(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return 'ノーマルモード';
      case GameMode.timeAttack:
        return 'タイムアタック';
      case GameMode.survival:
        return 'サバイバル';
      case GameMode.flash:
        return 'フラッシュモード';
      case GameMode.marathon:
        return 'マラソン';
    }
  }
}
