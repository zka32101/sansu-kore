import 'package:flutter/material.dart';

import '../models/quest_model.dart';
class CalculationStepsWidget extends StatelessWidget {
  final QuizQuestion question;
  final bool showSteps;

  const CalculationStepsWidget({
    Key? key,
    required this.question,
    this.showSteps = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showSteps) return const SizedBox.shrink();

    String hint = '';
    if (question.question.contains('+')) {
      hint = '足し算：一の位から足します';
    } else if (question.question.contains('-')) {
      hint = '引き算：一の位から引きます';
    } else if (question.question.contains('×')) {
      hint = 'かけ算：一の位からかけます';
    } else if (question.question.contains('÷')) {
      hint = '割り算：割り切れるか確認しましょう';
    } else {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
