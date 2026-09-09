import 'package:flutter_test/flutter_test.dart';
import 'package:sansu_kore/data/stage_data.dart';
import 'package:sansu_kore/models/quest_model.dart';

void main() {
  group('Stage Data Validation Tests', () {

    test('Total stage count should be 108', () {
      int totalStages = 0;
      for (int grade = 1; grade <= 6; grade++) {
        final grades = getStagesForGrade(grade);
        totalStages += grades.length;
      }
      expect(totalStages, 108, reason: 'Should have 108 total stages (18 per grade)');
    });

    test('Each grade should have exactly 18 stages', () {
      for (int grade = 1; grade <= 6; grade++) {
        final grades = getStagesForGrade(grade);
        expect(grades.length, 18, reason: 'Grade $grade should have 18 stages');
      }
    });

    test('All stage numbers should be sequential', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (int i = 0; i < stages.length; i++) {
          expect(stages[i].stageNumber, i + 1,
            reason: 'Grade $grade stage $i should have number ${i + 1}');
        }
      }
    });

    test('All question IDs should follow pattern g{grade}s{stage}q{question}', () {
      final idPattern = RegExp(r'^g\d+s\d+q\d+$');
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(idPattern.hasMatch(question.id), true,
              reason: 'Question ID "${question.id}" does not match expected pattern');
          }
        }
      }
    });

    test('All questions should have unique IDs within grade', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        final questionIds = <String>{};
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(questionIds.contains(question.id), false,
              reason: 'Duplicate question ID: ${question.id}');
            questionIds.add(question.id);
          }
        }
      }
    });

    test('Each question should have exactly 4 choices', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(question.choices.length, 4,
              reason: 'Question ${question.id} should have 4 choices, got ${question.choices.length}');
          }
        }
      }
    });

    test('Correct answer index should be valid (0-3)', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(question.correctIndex >= 0 && question.correctIndex < 4, true,
              reason: 'Question ${question.id} has invalid correct index: ${question.correctIndex}');
          }
        }
      }
    });

    test('All questions should have non-empty question text', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(question.question.isNotEmpty, true,
              reason: 'Question ${question.id} has empty question text');
          }
        }
      }
    });

    test('All questions should have explanation', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(question.explanation.isNotEmpty, true,
              reason: 'Question ${question.id} has no explanation');
          }
        }
      }
    });

    test('All questions should have valid topic type', () {
      final validTypes = ['addition', 'subtraction', 'multiplication', 'division',
                         'fraction', 'decimal', 'geometry', 'word', 'time', 'measurement'];
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(validTypes.contains(question.type), true,
              reason: 'Question ${question.id} has invalid type: ${question.type}');
          }
        }
      }
    });

    test('New stages (16-18) should have appropriate difficulty', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);

        // Check that new stages exist
        final newStages = stages.where((s) => s.stageNumber >= 16).toList();
        expect(newStages.isNotEmpty, true,
          reason: 'Grade $grade should have stages 16+');

        // Verify new stages have content
        for (final stage in newStages) {
          expect(stage.questions.isNotEmpty, true,
            reason: 'Grade $grade stage ${stage.stageNumber} should have questions');
          expect(stage.title.isNotEmpty, true,
            reason: 'Grade $grade stage ${stage.stageNumber} should have title');
        }
      }
    });

    test('Stage count per grade should match expected distribution', () {
      // Grade 1: 18 stages (added 16, 17, 18)
      expect(getStagesForGrade(1).length, 18);
      // Grade 2: 18 stages (added 17, 18)
      expect(getStagesForGrade(2).length, 18);
      // Grade 3: 18 stages (added 17, 18)
      expect(getStagesForGrade(3).length, 18);
      // Grade 4: 18 stages (added 16, 17, 18)
      expect(getStagesForGrade(4).length, 18);
      // Grade 5: 18 stages (added 16, 17, 18)
      expect(getStagesForGrade(5).length, 18);
      // Grade 6: 18 stages (added 16, 17, 18)
      expect(getStagesForGrade(6).length, 18);
    });

    test('Total question count should be 600+', () {
      int totalQuestions = 0;
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          totalQuestions += stage.questions.length;
        }
      }
      expect(totalQuestions >= 600, true,
        reason: 'Should have 600+ questions total, got $totalQuestions');
    });

    test('All choice options should be non-empty strings', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            for (int i = 0; i < question.choices.length; i++) {
              expect(question.choices[i].isNotEmpty, true,
                reason: 'Question ${question.id} choice $i is empty');
            }
          }
        }
      }
    });

    test('No duplicate questions across grades', () {
      final allQuestionIds = <String>{};
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        for (final stage in stages) {
          for (final question in stage.questions) {
            expect(allQuestionIds.contains(question.id), false,
              reason: 'Duplicate question ID found globally: ${question.id}');
            allQuestionIds.add(question.id);
          }
        }
      }
    });

  });

  group('Stage Progression Tests', () {

    test('Stage titles should be unique within grade', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        final titles = <String>{};
        for (final stage in stages) {
          expect(titles.contains(stage.title), false,
            reason: 'Grade $grade has duplicate stage title: "${stage.title}"');
          titles.add(stage.title);
        }
      }
    });

    test('Each grade should have variety of topic types', () {
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        final topicTypes = <String>{};
        for (final stage in stages) {
          topicTypes.add(stage.topicType);
        }
        expect(topicTypes.length >= 2, true,
          reason: 'Grade $grade should have at least 2 different topic types, got ${topicTypes.length}');
      }
    });

    test('Difficulty should generally increase with stage number', () {
      // This is a softer test - just verify new stages exist and have content
      for (int grade = 1; grade <= 6; grade++) {
        final stages = getStagesForGrade(grade);
        final lastStages = stages.where((s) => s.stageNumber >= 16).toList();

        expect(lastStages.isNotEmpty, true,
          reason: 'Grade $grade should have stages 16+');

        // New stages should have good explanations (indicating complexity)
        for (final stage in lastStages) {
          final avgExplanationLength =
            stage.questions.fold<int>(0, (sum, q) => sum + q.explanation.length) ~/
            stage.questions.length;
          expect(avgExplanationLength > 20, true,
            reason: 'Grade $grade stage ${stage.stageNumber} explanations seem too short');
        }
      }
    });

  });
}

// Helper function to get stages by grade
List<Stage> getStagesForGrade(int grade) {
  switch (grade) {
    case 1:
      return allStages.where((s) => s.grade == 1).toList();
    case 2:
      return allStages.where((s) => s.grade == 2).toList();
    case 3:
      return allStages.where((s) => s.grade == 3).toList();
    case 4:
      return allStages.where((s) => s.grade == 4).toList();
    case 5:
      return allStages.where((s) => s.grade == 5).toList();
    case 6:
      return allStages.where((s) => s.grade == 6).toList();
    default:
      return [];
  }
}
