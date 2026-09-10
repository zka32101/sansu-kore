import 'dart:math';

import '../models/quest_model.dart';
class InfiniteGenerator {
  static final _rng = Random();

  static QuizQuestion generate(MathTopicType type, int grade) {
    switch (type) {
      case MathTopicType.addition:
        return _addition(grade);
      case MathTopicType.subtraction:
        return _subtraction(grade);
      case MathTopicType.multiplication:
        return _multiplication(grade);
      case MathTopicType.division:
        return _division(grade);
      case MathTopicType.decimal:
        return _decimal(grade);
      case MathTopicType.fraction:
        return _fraction(grade);
      case MathTopicType.geometry:
        return _geometry(grade);
      case MathTopicType.word:
        return _word(grade);
    }
  }

  // ─── たし算 ───────────────────────────────────────────────
  static QuizQuestion _addition(int grade) {
    final range = _addSubRange(grade);
    final a = _rng.nextInt(range) + 1;
    final b = _rng.nextInt(range) + 1;
    final answer = a + b;
    final cs = _intChoices(answer, range * 2);
    return QuizQuestion(
      id: 'inf_add_${_rng.nextInt(99999)}',
      type: MathTopicType.addition,
      grade: grade,
      question: grade <= 2 ? '$a ＋ $b ＝ ？' : '$a + $b = ?',
      choices: cs.map((c) => '$c').toList(),
      correctIndex: cs.indexOf(answer),
      explanation: '$a + $b = $answer',
      wrongHints: {
        '${answer + 1}': 'くり上がりに注意しよう！',
        '${answer - 1}': 'もう１かぞえてみよう',
        '${(a - b).abs()}': 'ひき算と混ざったかな？',
      },
    );
  }

  // ─── ひき算 ───────────────────────────────────────────────
  static QuizQuestion _subtraction(int grade) {
    final range = _addSubRange(grade);
    final b = _rng.nextInt(range) + 1;
    final a = b + _rng.nextInt(range) + 1;
    final answer = a - b;
    final cs = _intChoices(answer, range * 2);
    return QuizQuestion(
      id: 'inf_sub_${_rng.nextInt(99999)}',
      type: MathTopicType.subtraction,
      grade: grade,
      question: grade <= 2 ? '$a ー $b ＝ ？' : '$a - $b = ?',
      choices: cs.map((c) => '$c').toList(),
      correctIndex: cs.indexOf(answer),
      explanation: '$a - $b = $answer',
      wrongHints: {
        '${answer + 1}': 'くり下がりを確認しよう',
        '${a + b}': 'たし算と混ざったかな？',
        '${b - a < 0 ? a - b + 1 : b - a}': '大きい数から引いてるかな？',
      },
    );
  }

  // ─── かけ算 ───────────────────────────────────────────────
  static QuizQuestion _multiplication(int grade) {
    final aMax = grade <= 2 ? 9 : grade <= 3 ? 19 : 99;
    final bMax = grade <= 2 ? 9 : grade <= 3 ? 9 : 99;
    final a = _rng.nextInt(aMax) + 1;
    final b = _rng.nextInt(bMax) + 1;
    final answer = a * b;
    final cs = _intChoices(answer, (answer * 1.5).ceil() + 20);
    return QuizQuestion(
      id: 'inf_mul_${_rng.nextInt(99999)}',
      type: MathTopicType.multiplication,
      grade: grade,
      question: '$a × $b = ?',
      choices: cs.map((c) => '$c').toList(),
      correctIndex: cs.indexOf(answer),
      explanation: '$a × $b = $answer',
      wrongHints: {
        '${a + b}': 'かけ算ではなく、たし算になっているよ',
        '${answer + a}': 'あと１段多く足したかな？',
        '${answer - b}': 'あと１段足りなかったかな？',
      },
    );
  }

  // ─── わり算 ───────────────────────────────────────────────
  static QuizQuestion _division(int grade) {
    final b = _rng.nextInt(8) + 2; // 2〜9
    final answerMax = grade <= 3 ? 9 : 49;
    final answer = _rng.nextInt(answerMax) + 1;
    final a = answer * b;
    final cs = _intChoices(answer, answerMax + 10);
    return QuizQuestion(
      id: 'inf_div_${_rng.nextInt(99999)}',
      type: MathTopicType.division,
      grade: grade,
      question: '$a ÷ $b = ?',
      choices: cs.map((c) => '$c').toList(),
      correctIndex: cs.indexOf(answer),
      explanation: '$a ÷ $b = $answer',
      wrongHints: {
        '${a * b}': 'かけ算と混ざったかな？',
        '${answer + 1}': '九九の表で確認してみよう',
        '${answer - 1}': '九九の表で確認してみよう',
      },
    );
  }

  // ─── 小数 ─────────────────────────────────────────────────
  static QuizQuestion _decimal(int grade) {
    final a10 = _rng.nextInt(90) + 1; // 0.1〜9.0 の10倍
    final b10 = _rng.nextInt(90) + 1;
    final ans10 = a10 + b10;
    final aStr = (a10 / 10.0).toStringAsFixed(1);
    final bStr = (b10 / 10.0).toStringAsFixed(1);
    final ansStr = (ans10 / 10.0).toStringAsFixed(1);

    final others = [
      ((ans10 + 1) / 10.0).toStringAsFixed(1),
      ((ans10 - 1) / 10.0).toStringAsFixed(1),
      ((ans10 + 10) / 10.0).toStringAsFixed(1),
    ].where((s) => s != ansStr && double.tryParse(s) != null && double.parse(s) > 0).toList();
    while (others.length < 3) {
      others.add(((ans10 + others.length * 3 + 2) / 10.0).toStringAsFixed(1));
    }

    final all = [ansStr, ...others.take(3)];
    all.shuffle(_rng);
    return QuizQuestion(
      id: 'inf_dec_${_rng.nextInt(99999)}',
      type: MathTopicType.decimal,
      grade: grade,
      question: '$aStr + $bStr = ?',
      choices: all,
      correctIndex: all.indexOf(ansStr),
      explanation: '$aStr + $bStr = $ansStr',
      wrongHints: {
        others.isNotEmpty ? others[0] : '0.0': '小数点の位置を確認しよう',
        ((ans10 + 10) / 10.0).toStringAsFixed(1): '小数点を無視しちゃったかな？',
      },
    );
  }

  // ─── 分数 ─────────────────────────────────────────────────
  static QuizQuestion _fraction(int grade) {
    final denom = _rng.nextInt(7) + 2; // 2〜8
    final a = _rng.nextInt(denom - 1) + 1;
    final maxB = denom - a;
    final b = maxB >= 2 ? (_rng.nextInt(maxB - 1) + 1) : 1;
    final numAns = a + b;
    final ansStr = '$numAns/$denom';

    final wrongNums = [numAns + 1, numAns - 1, numAns + 2]
        .where((n) => n > 0 && n != numAns)
        .toList();
    while (wrongNums.length < 3) wrongNums.add(numAns + wrongNums.length + 1);

    final all = [ansStr, ...wrongNums.take(3).map((n) => '$n/$denom')];
    all.shuffle(_rng);
    return QuizQuestion(
      id: 'inf_frac_${_rng.nextInt(99999)}',
      type: MathTopicType.fraction,
      grade: grade,
      question: '$a/$denom + $b/$denom = ?',
      choices: all,
      correctIndex: all.indexOf(ansStr),
      explanation: '$a/$denom + $b/$denom = $ansStr（分母はそのまま、分子だけ足す）',
      wrongHints: {
        '${a + b}/${denom + denom}': '分母は足さないよ。分子だけ足そう！',
        '${a + b + 1}/$denom': 'あと1少ないよ',
      },
    );
  }

  // ─── 図形（面積） ──────────────────────────────────────────
  static QuizQuestion _geometry(int grade) {
    final w = _rng.nextInt(9) + 2;
    final h = _rng.nextInt(9) + 2;
    final answer = w * h;
    final cs = _intChoices(answer, answer + 40);
    return QuizQuestion(
      id: 'inf_geo_${_rng.nextInt(99999)}',
      type: MathTopicType.geometry,
      grade: grade,
      question: '縦 $h cm、横 $w cm の長方形の面積は？',
      choices: cs.map((c) => '${c}cm²').toList(),
      correctIndex: cs.indexOf(answer),
      explanation: '$h × $w = ${answer}cm²',
      wrongHints: {
        '${(w + h) * 2}cm²': 'それは周りの長さ（周囲）だよ。面積は縦×横！',
        '${w + h}cm²': '縦×横で計算しよう',
      },
    );
  }

  // ─── 文章題（簡易） ────────────────────────────────────────
  static QuizQuestion _word(int grade) {
    final count = _rng.nextInt(6) + 2;
    final price = (_rng.nextInt(9) + 1) * 10;
    final answer = count * price;
    final cs = _intChoices(answer, answer + 100);
    return QuizQuestion(
      id: 'inf_word_${_rng.nextInt(99999)}',
      type: MathTopicType.word,
      grade: grade,
      question: '1こ ${price}円のリンゴを ${count}こ 買います。\nぜんぶで いくらですか？',
      choices: cs.map((c) => '${c}円').toList(),
      correctIndex: cs.indexOf(answer),
      explanation: '$price × $count = $answer円',
      wrongHints: {
        '${price + count}円': 'かけ算が必要だよ。${price}×${count}を計算しよう',
      },
    );
  }

  // ─── ユーティリティ ─────────────────────────────────────────
  static int _addSubRange(int grade) {
    switch (grade) {
      case 1: return 9;
      case 2: return 99;
      case 3: return 999;
      default: return 9999;
    }
  }

  /// 正解 + 近似値3つをシャッフルして返す
  static List<int> _intChoices(int correct, int maxHint) {
    final used = <int>{correct};
    final candidates = [1, -1, 10, -10, 2, -2, 11, -11, 5, -5, 20, -20];
    for (final d in candidates) {
      final c = correct + d;
      if (c > 0) used.add(c);
      if (used.length >= 4) break;
    }
    while (used.length < 4) {
      final c = _rng.nextInt(maxHint > correct ? maxHint : correct * 2) + 1;
      used.add(c);
    }
    final list = used.take(4).toList();
    list.shuffle(_rng);
    return list;
  }
}

/// 無限とっくんのセッション状態（画面内で管理）
class InfiniteSession {
  final MathTopicType topic;
  final int grade;
  int _total = 0;
  int _correct = 0;
  int _streak = 0; // 連続正解
  int _maxStreak = 0;

  InfiniteSession({required this.topic, required this.grade});

  QuizQuestion next() => InfiniteGenerator.generate(topic, grade);

  void recordAnswer(bool isCorrect) {
    _total++;
    if (isCorrect) {
      _correct++;
      _streak++;
      if (_streak > _maxStreak) _maxStreak = _streak;
    } else {
      _streak = 0;
    }
  }

  int get total => _total;
  int get correct => _correct;
  int get streak => _streak;
  int get maxStreak => _maxStreak;
  double get accuracy => _total == 0 ? 0 : _correct / _total;
}
