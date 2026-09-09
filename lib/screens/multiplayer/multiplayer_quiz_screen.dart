import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show MatchState, MatchStatus, currentMatchProvider, watchMatchProvider, FuriganaText;

import '../../data/multiplayer_quiz_generator.dart';
import '../../models/quest_model.dart';
import '../../providers/multiplayer_provider.dart';
import '../../theme/app_theme.dart';

/// 対戦本編（算数の問題形式に合わせた実装）。
///
/// [matchId] は両プレイヤー間で共有され、[MultiplayerQuizGenerator] が
/// matchId をシードに問題セットを決定するため、両者に同じ問題・同じ順序が出題される。
/// スコアは Firestore（[watchMatchProvider]）でリアルタイム同期する。
///
/// 参考: social_quiz_app の multiplayer_quiz_screen.dart。
class MultiplayerQuizScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String userId;
  final int grade;

  const MultiplayerQuizScreen({
    super.key,
    required this.matchId,
    required this.userId,
    required this.grade,
  });

  @override
  ConsumerState<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends ConsumerState<MultiplayerQuizScreen> {
  late final List<QuizQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _myScore = 0;
  bool _ratingUpdated = false;

  @override
  void initState() {
    super.initState();
    _questions = MultiplayerQuizGenerator.generate(grade: widget.grade, matchId: widget.matchId);
  }

  void _answerQuestion(int index, MatchState match) {
    if (_answered || _questions.isEmpty) return;

    final question = _questions[_currentIndex];
    final isCorrect = index == question.correctIndex;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (isCorrect) _myScore += 1;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _nextQuestion(match);
    });
  }

  Future<void> _nextQuestion(MatchState match) async {
    final isLastQuestion = _currentIndex >= _questions.length - 1;
    final scores = {...match.scores, widget.userId: _myScore};

    await ref.read(currentMatchProvider.notifier).updateMatchState(
          matchId: widget.matchId,
          scores: scores,
          shouldComplete: isLastQuestion,
        );

    if (isLastQuestion) {
      await _maybeUpdateRating(match.copyWith(scores: scores, status: MatchStatus.finished));
      return;
    }

    if (!mounted) return;
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  /// レーティング更新は両プレイヤーの二重実行を避けるため、
  /// playerIds の先頭（決定的に一意な代表者）の端末からのみ実行する。
  Future<void> _maybeUpdateRating(MatchState match) async {
    if (_ratingUpdated) return;
    if (match.playerIds.isEmpty || match.playerIds.first != widget.userId) return;
    final opponentId = match.opponentOf(widget.userId);
    if (opponentId == null) return;

    _ratingUpdated = true;
    final result = match.resultFor(widget.userId);
    final updateRating = ref.read(sansuMatchmakingUpdateRatingProvider);

    if (result == 'win') {
      await updateRating(winnerId: widget.userId, loserId: opponentId);
    } else if (result == 'lose') {
      await updateRating(winnerId: opponentId, loserId: widget.userId);
    } else if (result == 'draw') {
      await updateRating(winnerId: widget.userId, loserId: opponentId, isDraw: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(watchMatchProvider(widget.matchId));

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text('対戦クイズ'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
        data: (match) {
          if (match == null) {
            return const Center(child: Text('対戦が見つかりません'));
          }
          if (match.isFinished) {
            // 相手の端末が先に shouldComplete を送っていた場合もここでレーティング更新を試みる。
            _maybeUpdateRating(match);
            return _buildResultView(context, match);
          }
          return _buildQuizScreen(context, match);
        },
      ),
    );
  }

  Widget _buildQuizScreen(BuildContext context, MatchState match) {
    final opponentId = match.opponentOf(widget.userId);
    final opponentScore = opponentId == null ? 0 : match.scoreFor(opponentId);

    return Column(
      children: [
        _buildScoreBoard(myScore: _myScore, opponentScore: opponentScore),
        const SizedBox(height: 16),
        Expanded(child: _buildQuizView(match)),
      ],
    );
  }

  Widget _buildScoreBoard({required int myScore, required int opponentScore}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: kPrimaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreCard(label: 'あなた', score: myScore, total: _questions.length, color: Colors.blue.shade100),
          Column(
            children: [
              const Text('vs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                '$myScore - $opponentScore',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          _buildScoreCard(label: '相手', score: opponentScore, total: _questions.length, color: Colors.red.shade100),
        ],
      ),
    );
  }

  Widget _buildScoreCard({required String label, required int score, required int total, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$score/$total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuizView(MatchState match) {
    if (_questions.isEmpty) {
      return const Center(child: Text('問題が見つかりませんでした'));
    }

    final question = _questions[_currentIndex];
    final options = question.choices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('問題 ${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 4,
              color: kPrimaryColor,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 24),
          FuriganaText(question.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 24),
          ...List.generate(options.length, (index) => _buildChoice(index, question, match)),
          if (_answered)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  _selectedIndex == question.correctIndex ? '✓ 正解！' : '✗ 不正解',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedIndex == question.correctIndex ? kAccentGreen : Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChoice(int index, QuizQuestion question, MatchState match) {
    final isSelected = _selectedIndex == index;
    final isCorrect = index == question.correctIndex;
    final showResult = _answered;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = kAccentGreen.withValues(alpha: 0.15);
        borderColor = kAccentGreen;
      } else if (isSelected) {
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = kPrimaryColor.withValues(alpha: 0.12);
      borderColor = kPrimaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _answered ? null : () => _answerQuestion(index, match),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: FuriganaText(question.choices[index], style: const TextStyle(fontSize: 16))),
              if (showResult && isCorrect) const Icon(Icons.check_circle, color: kAccentGreen),
              if (showResult && isSelected && !isCorrect) const Icon(Icons.close, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context, MatchState match) {
    final result = match.resultFor(widget.userId);
    final myScore = match.scoreFor(widget.userId);
    final opponentId = match.opponentOf(widget.userId);
    final opponentScore = opponentId == null ? 0 : match.scoreFor(opponentId);

    final label = switch (result) {
      'win' => '🎉 勝利！',
      'draw' => '🤝 引き分け',
      _ => '🏁 終了',
    };
    final color = switch (result) {
      'win' => kAccentGreen,
      'draw' => kAccentOrange,
      _ => Colors.red.shade400,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 24),
          Text('$myScore - $opponentScore', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('対戦トップに戻る'),
          ),
        ],
      ),
    );
  }
}
