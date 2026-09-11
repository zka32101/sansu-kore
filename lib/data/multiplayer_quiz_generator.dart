import 'dart:math';

import '../models/quest_model.dart';
import 'stage_data.dart';
class MultiplayerQuizGenerator {
  const MultiplayerQuizGenerator._();

  /// [matchId] をシードに使うことで、対戦する両プレイヤーの端末で
  /// 同一の問題セット・同一の出題順・同一の選択肢配置を再現する
  /// （matchId を共有しないと片方だけ違う問題が出てしまい対戦が成立しない）。
  static List<QuizQuestion> generate({
    required int grade,
    required String matchId,
    int count = 10,
  }) {
    final pool = <QuizQuestion>[
      for (final stage in getStagesForGrade(grade)) ...stage.questions,
    ];

    if (pool.isEmpty) return const [];

    final random = Random(matchId.hashCode);
    final shuffled = [...pool]..shuffle(random);
    final picked = shuffled.take(count).toList();

    return picked.map((q) => _randomizeChoicesWith(q, random)).toList();
  }

  /// [QuizQuestion.randomizeChoices] と同じロジックだが、対戦の両プレイヤー間で
  /// 同一の乱数列を共有できるよう外部から [random] を渡せるようにしたもの
  /// （QuizQuestion.randomizeChoices は @visibleForTesting 経由でしかシード指定できないため）。
  static QuizQuestion _randomizeChoicesWith(QuizQuestion q, Random random) {
    final originalChoices = [...q.choices];
    final correctAnswer = originalChoices[q.correctIndex];

    final shuffledChoices = [...originalChoices];
    for (var i = shuffledChoices.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = shuffledChoices[i];
      shuffledChoices[i] = shuffledChoices[j];
      shuffledChoices[j] = tmp;
    }

    final newCorrectIndex = shuffledChoices.indexOf(correctAnswer);

    Map<String, String>? remappedWrongHints;
    if (q.wrongHints != null) {
      remappedWrongHints = {
        for (final choice in shuffledChoices)
          if (q.wrongHints!.containsKey(choice)) choice: q.wrongHints![choice]!,
      };
    }

    return QuizQuestion(
      id: q.id,
      type: q.type,
      grade: q.grade,
      question: q.question,
      choices: shuffledChoices,
      correctIndex: newCorrectIndex,
      explanation: q.explanation,
      hint: q.hint,
      wrongHints: remappedWrongHints,
      shapeName: q.shapeName,
    );
  }
}
