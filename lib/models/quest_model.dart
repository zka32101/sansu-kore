import 'dart:math';

import 'package:flutter/foundation.dart';
enum MathTopicType { addition, subtraction, multiplication, division, fraction, decimal, geometry, word }

class QuizQuestion {
  final String id;
  final MathTopicType type;
  final int grade;
  final String question;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  final String? hint;
  /// ④誤答パターン分類: 選択肢テキスト → エラーヒント文
  final Map<String, String>? wrongHints;
  /// 図形ビジュアル表示用: 'triangle', 'circle', 'square' など
  final String? shapeName;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.grade,
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
    this.hint,
    this.wrongHints,
    this.shapeName,
  });

  /// 選択肢をランダムに並べ替える
  /// 毎回異なる順序で表示されるため、ユーザーが正解位置を覚えるのを防ぐ
  ///
  /// 返り値: ランダム化された新しい QuizQuestion インスタンス
  QuizQuestion randomizeChoices() {
    // 選択肢の元の順序を保持（correctIndexの位置を追跡するため）
    final originalChoices = [...choices];
    final correctAnswer = originalChoices[correctIndex];

    // 選択肢をシャッフル
    final shuffledChoices = [...originalChoices];
    _shuffle(shuffledChoices);

    // 新しい correctIndex を計算
    final newCorrectIndex = shuffledChoices.indexOf(correctAnswer);

    // ⚠️ wrongHints マッピング修正: シャッフル後の新しいインデックスで再マップ
    Map<String, String>? remappedWrongHints;
    if (wrongHints != null) {
      remappedWrongHints = {};
      for (int i = 0; i < shuffledChoices.length; i++) {
        final choiceText = shuffledChoices[i];
        if (wrongHints!.containsKey(choiceText)) {
          remappedWrongHints[choiceText] = wrongHints![choiceText]!;
        }
      }
    }

    // 新しい QuizQuestion を返す
    return QuizQuestion(
      id: id,
      type: type,
      grade: grade,
      question: question,
      choices: shuffledChoices,
      correctIndex: newCorrectIndex,
      explanation: explanation,
      hint: hint,
      wrongHints: remappedWrongHints,
      shapeName: shapeName,
    );
  }

  /// リスト要素をシャッフル（Fisher-Yates アルゴリズム）
  /// 問題が多すぎる場合は、複数ユーザーで同じ順序になるのを防ぐため
  /// ソルトを追加することも検討
  static void _shuffle<T>(List<T> list) {
    final random = _getRandomInstance();
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      // swap
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  /// ランダム インスタンス取得（テスト時は seed 指定可能）
  static Random? _testRandom;
  static Random _getRandomInstance() => _testRandom ?? Random();

  /// テスト用：ランダムのシードを固定
  @visibleForTesting
  static void setTestRandom(Random? random) {
    _testRandom = random;
  }
}

class Stage {
  final int stageNumber;
  final String title;
  final int grade;
  final MathTopicType topicType;
  final List<QuizQuestion> questions;

  const Stage({
    required this.stageNumber,
    required this.title,
    required this.grade,
    required this.topicType,
    required this.questions,
  });

  int get totalQuestions => questions.length;
}

class QuestResult {
  final int correctCount;
  final int totalCount;
  final Duration elapsed;

  const QuestResult({
    required this.correctCount,
    required this.totalCount,
    required this.elapsed,
  });

  int get score => (correctCount / totalCount * 100).round();
  bool get isPerfect => correctCount == totalCount;
  bool get isPassed => correctCount >= (totalCount * 0.6).ceil();
}
