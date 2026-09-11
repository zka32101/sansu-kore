import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/data/stage_data.dart';
import 'package:sansu_kore/models/game_mode_model.dart';
import 'package:sansu_kore/models/quest_model.dart';
import 'package:sansu_kore/models/sound_model.dart';
import 'package:sansu_kore/providers/game_mode_provider.dart';
import 'package:sansu_kore/providers/sound_provider.dart';
import 'package:sansu_kore/screens/challenge_result_screen.dart';

/// ゲーム進行画面
/// モード別の異なるゲーム機構を実装
class GamePlayScreen extends ConsumerStatefulWidget {
  final GameMode gameMode;
  final int gradeLevel;
  final String? topicType;

  const GamePlayScreen({
    Key? key,
    required this.gameMode,
    required this.gradeLevel,
    this.topicType,
  }) : super(key: key);

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  int _questionStartTime = 0;
  int _selectedChoiceIndex = -1;
  bool _hasAnswered = false;
  late List<QuizQuestion> _questions;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
    _startTimer();
  }

  void _initializeQuestions() {
    // Get all stages for the grade level
    final stages = getStagesForGrade(widget.gradeLevel);

    // Filter by topicType if specified
    List<QuizQuestion> allQuestions = [];
    if (widget.topicType != null) {
      for (final stage in stages) {
        if (stage.topicType == _getTopicType(widget.topicType)) {
          allQuestions.addAll(stage.questions);
        }
      }
    } else {
      // If no topic type specified, get all questions from all stages
      for (final stage in stages) {
        allQuestions.addAll(stage.questions);
      }
    }

    // Take appropriate number of questions based on game mode
    final config = GameModeConfig.getConfig(widget.gameMode);
    final questionCount = config?.targetQuestionsCount ?? 10;
    _questions = allQuestions.take(questionCount).toList();
  }

  MathTopicType _getTopicType(String? type) {
    if (type == null) return MathTopicType.addition;
    switch (type.toLowerCase()) {
      case 'addition':
        return MathTopicType.addition;
      case 'subtraction':
        return MathTopicType.subtraction;
      case 'multiplication':
        return MathTopicType.multiplication;
      case 'division':
        return MathTopicType.division;
      case 'fraction':
        return MathTopicType.fraction;
      case 'decimal':
        return MathTopicType.decimal;
      case 'geometry':
        return MathTopicType.geometry;
      case 'word':
        return MathTopicType.word;
      default:
        return MathTopicType.addition;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _questionStartTime = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        _questionStartTime++;
      });

      // タイムアタックモード: 制限時間に達したら自動判定
      final config = GameModeConfig.getConfig(widget.gameMode);
      if (config?.timeLimit != null && _questionStartTime >= config!.timeLimit!) {
        if (!_hasAnswered) {
          _recordAnswer('timeout', -1, false); // タイムアップ = 不正解
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider).currentSession;

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('セッションが見つかりません')),
      );
    }

    // Check if game is complete
    if (_currentQuestionIndex >= _questions.length ||
        (_hasAnswered && _currentQuestionIndex == _questions.length)) {
      // Complete the session and show results
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeGame(ref, session);
      });
    }

    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation(context);
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(session),
        body: _buildGameBody(context, session),
      ),
    );
  }

  /// アプリバー
  PreferredSizeWidget _buildAppBar(GameSession session) {
    final config = GameModeConfig.getConfig(widget.gameMode)!;

    return AppBar(
      title: Text(config.displayName),
      centerTitle: true,
      elevation: 0,
      backgroundColor: _getModeColor(widget.gameMode),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showExitConfirmation(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              '${session.correctAnswers}/${session.totalQuestions}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ゲーム本体
  Widget _buildGameBody(BuildContext context, GameSession session) {
    return Column(
      children: [
        // プログレスバー & ステータス
        _buildStatusBar(session),

        // クイズ領域
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildQuizContent(context, session),
            ),
          ),
        ),
      ],
    );
  }

  /// ステータスバー（プログレス & 情報）
  Widget _buildStatusBar(GameSession session) {
    final config = GameModeConfig.getConfig(widget.gameMode)!;

    return Container(
      color: _getModeColor(widget.gameMode).withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: session.totalQuestions > 0
                  ? session.correctAnswers / session.totalQuestions
                  : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                _getModeColor(widget.gameMode),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 情報行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左: 正答率
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '正答率',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${(session.correctRate * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // 中央: モード固有情報
              if (widget.gameMode == GameMode.timeAttack)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'タイム',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _elapsedSeconds > (config.timeLimit ?? 60)
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                )
              else if (widget.gameMode == GameMode.survival)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ミス',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${session.totalMisses}/${config.maxMisses ?? 3}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: session.totalMisses >= (config.maxMisses ?? 3)
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '連続',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${session.currentStreak}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

              // 右: 平均応答時間
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '平均時間',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${session.averageResponseTime.toStringAsFixed(1)}秒',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// クイズコンテンツ
  Widget _buildQuizContent(BuildContext context, GameSession session) {
    if (_currentQuestionIndex >= _questions.length) {
      return const Center(
        child: Text('クイズ完了！'),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 問題番号
        Center(
          child: Text(
            '問題 ${_currentQuestionIndex + 1}/${_questions.length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 問題文
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            currentQuestion.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // 選択肢
        ..._buildChoices(currentQuestion),

        if (_hasAnswered) ...[
          const SizedBox(height: 24),
          _buildAnswerFeedback(currentQuestion),
          const SizedBox(height: 16),
          _buildNextButton(context),
        ],
      ],
    );
  }

  /// 選択肢ボタン
  List<Widget> _buildChoices(QuizQuestion question) {
    return question.choices.asMap().entries.map((entry) {
      final index = entry.key;
      final choice = entry.value;
      final isSelected = _selectedChoiceIndex == index;
      final isCorrect = index == question.correctIndex;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ElevatedButton(
          onPressed: _hasAnswered ? null : () => _selectChoice(context, index, question),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: isSelected
                ? (isCorrect && _hasAnswered
                    ? Colors.green.shade500
                    : (!isCorrect && _hasAnswered
                        ? Colors.red.shade500
                        : _getModeColor(widget.gameMode)))
                : Colors.grey.shade100,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            disabledBackgroundColor: isSelected
                ? (isCorrect && _hasAnswered
                    ? Colors.green.shade500
                    : (!isCorrect && _hasAnswered
                        ? Colors.red.shade500
                        : _getModeColor(widget.gameMode)))
                : Colors.grey.shade100,
          ),
          child: Text(
            choice,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 回答フィードバック
  Widget _buildAnswerFeedback(QuizQuestion question) {
    final isCorrect = _selectedChoiceIndex == question.correctIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        children: [
          Text(
            isCorrect ? '🎉 正解！' : '❌ 不正解',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: TextStyle(
              fontSize: 14,
              color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 次へボタン
  Widget _buildNextButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _nextQuestion(context),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: _getModeColor(widget.gameMode),
      ),
      child: const Text(
        '次へ',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 選択肢タップ
  void _selectChoice(BuildContext context, int index, QuizQuestion question) {
    final isCorrect = index == question.correctIndex;

    setState(() {
      _selectedChoiceIndex = index;
      _hasAnswered = true;
    });

    // Play sound effect based on answer correctness
    _playAnswerSound(ref, isCorrect);

    _recordAnswer(question.id, index, isCorrect);
  }

  /// 回答を記録
  void _recordAnswer(String questionId, int selectedIndex, bool isCorrect) {
    ref.read(gameSessionProvider.notifier).recordAnswer(
          questionId: questionId,
          selectedIndex: selectedIndex,
          isCorrect: isCorrect,
          responseTimeMs: _questionStartTime * 1000,
        );
  }

  /// 次問へ
  void _nextQuestion(BuildContext context) {
    if (_currentQuestionIndex + 1 >= _questions.length) {
      // Game complete
      _completeGame(ref, ref.read(gameSessionProvider).currentSession!);
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedChoiceIndex = -1;
        _hasAnswered = false;
        _questionStartTime = 0;
      });
    }
  }

  /// ゲーム完了
  void _completeGame(WidgetRef ref, GameSession session) {
    // Complete the session
    ref.read(gameSessionProvider.notifier).completeSession();

    // Calculate results
    final session = ref.read(gameSessionProvider).currentSession!;
    final result = GameResult.calculateResult(
      session: session,
      elapsedSeconds: _elapsedSeconds,
      gradeLevel: widget.gradeLevel,
      topicType: widget.topicType ?? 'general',
    );

    // Add result to history
    ref.read(gameResultsProvider.notifier).addResult(result);

    // Navigate to result screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChallengeResultScreen(result: result),
      ),
    );
  }

  /// 終了確認
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームを終了しますか？'),
        content: const Text('現在の進捗は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('続ける'),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameSessionProvider.notifier).resetSession();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  /// 時間をmm:ss形式でフォーマット
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
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

  /// 回答に基づいて音声効果を再生
  void _playAnswerSound(WidgetRef ref, bool isCorrect) {
    final soundPlayback = ref.read(soundPlaybackProvider.notifier);
    final shouldPlaySound = ref.read(shouldPlaySoundProvider);

    if (!shouldPlaySound) return;

    // Play appropriate sound
    if (isCorrect) {
      soundPlayback.playSound(SoundEffect.correct);
    } else {
      soundPlayback.playSound(SoundEffect.incorrect);
    }
  }
}
