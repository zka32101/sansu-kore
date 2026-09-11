import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/daily_challenge_model.dart';
import 'package:sansu_kore/models/quest_model.dart';
import 'package:sansu_kore/models/sound_model.dart';
import 'package:sansu_kore/providers/daily_challenge_provider.dart';
import 'package:sansu_kore/providers/sound_provider.dart';

/// デイリーチャレンジ画面
/// 毎日5問のチャレンジをプレイ
class DailyChallengeScreen extends ConsumerStatefulWidget {
  final String userId;

  const DailyChallengeScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentQuestionIndex = 0;
  int _selectedChoiceIndex = -1;
  bool _hasAnswered = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(dailyChallengeProvider);
    final challenge = challengeState.currentChallenge;

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('デイリーチャレンジ'),
          centerTitle: true,
          backgroundColor: Colors.blue.shade400,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!challenge.isValid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('デイリーチャレンジ'),
          centerTitle: true,
          backgroundColor: Colors.blue.shade400,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                '本日のチャレンジは\nまだ開始されていません',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Colors.blue.shade400,
                ),
                child: const Text(
                  'もどる',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('デイリーチャレンジ'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue.shade400,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_currentQuestionIndex + 1}/${challenge.questions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _buildGameBody(challenge),
      ),
    );
  }

  Widget _buildGameBody(DailyChallenge challenge) {
    if (_currentQuestionIndex >= challenge.questions.length) {
      return _buildCompletionScreen(challenge);
    }

    final currentQuestion = challenge.questions[_currentQuestionIndex];

    return Column(
      children: [
        // プログレスバー
        Container(
          color: Colors.blue.shade100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / challenge.questions.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '正答数: $_correctCount/${challenge.questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '正答率: ${_getCorrectRate()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getCorrectRate() >= 80 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // クイズコンテンツ
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      fontSize: 22,
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
                  _buildNextButton(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChoices(QuizQuestion question) {
    return question.choices.asMap().entries.map((entry) {
      final index = entry.key;
      final choice = entry.value;
      final isSelected = _selectedChoiceIndex == index;
      final isCorrect = index == question.correctIndex;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ElevatedButton(
          onPressed: _hasAnswered ? null : () => _selectChoice(index, question),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: isSelected
                ? (isCorrect && _hasAnswered
                    ? Colors.green.shade500
                    : (!isCorrect && _hasAnswered
                        ? Colors.red.shade500
                        : Colors.blue.shade400))
                : Colors.grey.shade100,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            disabledBackgroundColor: isSelected
                ? (isCorrect && _hasAnswered
                    ? Colors.green.shade500
                    : (!isCorrect && _hasAnswered
                        ? Colors.red.shade500
                        : Colors.blue.shade400))
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

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextQuestion,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue.shade400,
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

  Widget _buildCompletionScreen(DailyChallenge challenge) {
    final correctRate = _correctCount / challenge.questions.length;
    final isPerfect = _correctCount == challenge.questions.length;
    final isGood = correctRate >= 0.8;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isPerfect ? '🌟' : isGood ? '✨' : '👍',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),
              Text(
                'チャレンジ完了！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '正解数',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          '$_correctCount/${challenge.questions.length}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '正答率',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          '${_getCorrectRate()}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isGood ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitCompletion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  backgroundColor: Colors.blue.shade400,
                ),
                child: const Text(
                  '結果を送信',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectChoice(int index, QuizQuestion question) {
    final isCorrect = index == question.correctIndex;

    setState(() {
      _selectedChoiceIndex = index;
      _hasAnswered = true;

      if (isCorrect) {
        _correctCount++;
      }
    });

    // Play sound effect based on answer correctness
    final soundPlayback = ref.read(soundPlaybackProvider.notifier);
    final shouldPlaySound = ref.read(shouldPlaySoundProvider);

    if (shouldPlaySound) {
      if (isCorrect) {
        soundPlayback.playSound(SoundEffect.correct);
      } else {
        soundPlayback.playSound(SoundEffect.incorrect);
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedChoiceIndex = -1;
      _hasAnswered = false;
    });
  }

  void _submitCompletion() {
    final challenge = ref.read(dailyChallengeProvider).currentChallenge;
    if (challenge == null) return;

    // Record the completion
    ref.read(dailyChallengeProvider.notifier).completeDailyChallenge(
          userId: widget.userId,
          correctAnswers: _correctCount,
          totalQuestions: challenge.questions.length,
        );

    // Play celebration sound based on performance
    final correctRate = _correctCount / challenge.questions.length;
    final soundPlayback = ref.read(soundPlaybackProvider.notifier);
    final shouldPlaySound = ref.read(shouldPlaySoundProvider);

    if (shouldPlaySound) {
      if (correctRate == 1.0) {
        // Perfect score - play perfect sound
        soundPlayback.playSound(SoundEffect.perfect);
      } else if (correctRate >= 0.8) {
        // Good score - play achievement sound
        soundPlayback.playSound(SoundEffect.achievement);
      } else {
        // Completion sound
        soundPlayback.playSound(SoundEffect.notification);
      }
    }

    // Show congratulations and return
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('本日のチャレンジを完了しました！ $_correctCount問正解しました。'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チャレンジを終了しますか？'),
        content: const Text('現在の進捗は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('続ける'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  int _getCorrectRate() {
    if (_currentQuestionIndex == 0) return 0;
    return (_correctCount / _currentQuestionIndex * 100).toInt();
  }
}
