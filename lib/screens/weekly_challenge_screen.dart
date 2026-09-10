import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quest_model.dart';
import '../providers/profile_provider.dart';
import '../providers/weekly_challenge_provider.dart';
import '../theme/app_theme.dart';
class WeeklyChallengeScreen extends ConsumerStatefulWidget {
  const WeeklyChallengeScreen({super.key});

  @override
  ConsumerState<WeeklyChallengeScreen> createState() =>
      _WeeklyChallengeScreenState();
}

class _WeeklyChallengeScreenState
    extends ConsumerState<WeeklyChallengeScreen> {
  int _current = 0; // 現在の問題インデックス
  int? _selectedIndex;
  bool _answered = false;
  bool _showSummary = false;
  int _correct = 0;
  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weeklyChallengeProvider.notifier).load().then((_) {
        setState(() {
          _questions = ref.read(weeklyChallengeProvider.notifier).weeklyQuestions;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final wcState = ref.watch(weeklyChallengeProvider);
    final profile = ref.watch(profileProvider);
    final childName = profile.currentProfile?.name ?? 'きみ';

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ウィークリーチャレンジ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_showSummary) {
      return _SummaryPage(
        correct: _correct,
        total: _questions.length,
        childName: childName,
        isAlreadyComplete: wcState.isAllDone,
        onRewardClaim: () {
          ref.read(weeklyChallengeProvider.notifier).claimReward();
          Navigator.of(context).pop();
        },
      );
    }

    final q = _questions[_current];
    final isAnswered = wcState.answeredIds.contains(q.id);

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text('ウィークリーチャレンジ'),
        backgroundColor: const Color(0xFF8E44AD), // 紫 for weekly
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${wcState.completed}/${wcState.total}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 進捗バー
          LinearProgressIndicator(
            value: wcState.progress,
            backgroundColor: Colors.purple.shade100,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF8E44AD)),
            minHeight: 6,
          ),
          // 問題番号
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '問題 ${_current + 1} / ${_questions.length}',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E44AD).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_gradeLabel(q.grade)} ${_topicLabel(q.type)}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E44AD)),
                  ),
                ),
              ],
            ),
          ),
          // 問題カード
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 問題文
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      q.question,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 選択肢
                  ...List.generate(q.choices.length, (i) {
                    Color? bgColor;
                    Color? borderColor;
                    if (_answered || isAnswered) {
                      if (i == q.correctIndex) {
                        bgColor = Colors.green.shade50;
                        borderColor = Colors.green;
                      } else if (i == _selectedIndex) {
                        bgColor = Colors.red.shade50;
                        borderColor = Colors.red;
                      }
                    } else if (i == _selectedIndex) {
                      bgColor = Colors.purple.shade50;
                      borderColor = const Color(0xFF8E44AD);
                    }
                    return GestureDetector(
                      onTap: (_answered || isAnswered)
                          ? null
                          : () => _onSelect(i, q),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: bgColor ?? Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? Colors.grey.shade200,
                            width: borderColor != null ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          q.choices[i],
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                  // 解説
                  if (_answered || isAnswered) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        '💡 ${q.explanation}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E44AD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _current < _questions.length - 1 ? '次の問題へ' : '結果を見る',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelect(int index, QuizQuestion q) {
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
    if (index == q.correctIndex) {
      _correct++;
      ref.read(weeklyChallengeProvider.notifier).recordCorrect(q.id);
    }
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _answered = false;
      });
    } else {
      setState(() {
        _showSummary = true;
      });
    }
  }

  String _gradeLabel(int g) => '小$g';
  String _topicLabel(MathTopicType t) {
    switch (t) {
      case MathTopicType.addition: return 'たし算';
      case MathTopicType.subtraction: return 'ひき算';
      case MathTopicType.multiplication: return 'かけ算';
      case MathTopicType.division: return 'わり算';
      case MathTopicType.fraction: return '分数';
      case MathTopicType.decimal: return '小数';
      case MathTopicType.geometry: return '図形';
      case MathTopicType.word: return '文章題';
    }
  }
}

class _SummaryPage extends StatelessWidget {
  final int correct;
  final int total;
  final String childName;
  final bool isAlreadyComplete;
  final VoidCallback onRewardClaim;

  const _SummaryPage({
    required this.correct,
    required this.total,
    required this.childName,
    required this.isAlreadyComplete,
    required this.onRewardClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isPerfect = correct == total;
    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isPerfect ? '🏆 かんぺき！' : correct >= total * 0.7 ? '⭐ よくできました！' : '💪 またちょうせん！',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '$childName の今週のチャレンジ',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12)
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$correct / $total',
                        style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E44AD)),
                      ),
                      Text(
                        '正解',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (isAlreadyComplete && !isAlreadyComplete) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🎖️ 全問正解ボーナス 50コイン！',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRewardClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E44AD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ホームに戻る',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
