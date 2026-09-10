import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/game_mode_model.dart';
import 'package:sansu_kore/providers/game_mode_provider.dart';
import 'package:sansu_kore/screens/game_play_screen.dart';

/// チャレンジモード選択画面
/// ユーザーが5つのゲームモードから選んで開始できる
class ChallengeSelectScreen extends ConsumerWidget {
  final int gradeLevel;
  final String? topicType;

  const ChallengeSelectScreen({
    Key? key,
    required this.gradeLevel,
    this.topicType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャレンジモード'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade400,
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            _buildHeader(),
            const SizedBox(height: 24),

            // ゲームモード一覧
            _buildGameModesList(context, ref),

            const SizedBox(height: 24),

            // ヒント・説明
            _buildTips(),
          ],
        ),
      ),
    );
  }

  /// ヘッダーセクション
  Widget _buildHeader() {
    final gradeLabel = '${gradeLevel}年生';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ゲームモード選択',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$gradeLabel${topicType != null ? ' - $topicType' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '5つのモードから選んで、新しい学習体験を始めよう！',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// ゲームモード一覧
  Widget _buildGameModesList(BuildContext context, WidgetRef ref) {
    return Column(
      children: GameModeConfig.allModes.map((config) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGameModeCard(
            context,
            ref,
            config,
          ),
        );
      }).toList(),
    );
  }

  /// ゲームモードカード
  Widget _buildGameModeCard(
    BuildContext context,
    WidgetRef ref,
    GameModeConfig config,
  ) {
    return GestureDetector(
      onTap: () => _startGameMode(context, ref, config),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getGradientForMode(config.mode),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左: 絵文字
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      config.emoji ?? '🎮',
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
                        config.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildModeBadges(config),
                    ],
                  ),
                ),

                // 右: 矢印
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// モード別のバッジ表示
  Widget _buildModeBadges(GameModeConfig config) {
    final badges = <String>[];

    if (config.timeLimit != null) {
      badges.add('⏱️ ${config.timeLimit}秒/問');
    }
    if (config.maxMisses != null) {
      badges.add('❌ ${config.maxMisses}ミスまで');
    }
    if (config.targetQuestionsCount != null) {
      badges.add('🎯 ${config.targetQuestionsCount}問');
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      children: badges.map((badge) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// モード別のグラデーション
  LinearGradient _getGradientForMode(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GameMode.timeAttack:
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GameMode.survival:
        return LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GameMode.flash:
        return LinearGradient(
          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GameMode.marathon:
        return LinearGradient(
          colors: [Colors.pink.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// ゲームモード開始処理
  void _startGameMode(
    BuildContext context,
    WidgetRef ref,
    GameModeConfig config,
  ) {
    // セッション開始
    ref.read(gameSessionProvider.notifier).startSession(
          gameMode: config.mode,
          gradeLevel: gradeLevel,
          topicType: topicType,
        );

    // ゲーム画面へナビゲート
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamePlayScreen(
          gameMode: config.mode,
          gradeLevel: gradeLevel,
          topicType: topicType,
        ),
      ),
    );
  }

  /// ヒント・説明セクション
  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'モード選択のコツ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• ノーマル: 基本的な学習に最適。初心者向け。\n'
            '• タイムアタック: 速度と正確性を同時に鍛える。\n'
            '• サバイバル: 連続正解を目指す。持続力テスト。\n'
            '• フラッシュ: 反応速度と判断力を高める。\n'
            '• マラソン: 最長100問。持久力と集中力の最終試験。',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
