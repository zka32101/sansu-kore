import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show requireParentalGate;


import '../data/stage_data.dart';
import '../models/quest_model.dart';
import '../providers/premium_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
class StageSelectScreen extends ConsumerStatefulWidget {
  const StageSelectScreen({super.key});

  @override
  ConsumerState<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends ConsumerState<StageSelectScreen> {
  int _gradeFilter = 0; // 0=全て

  List<Stage> _stagesForGrade(int grade) => getStagesForGrade(grade);

  Future<void> _onTapStage(BuildContext context, Stage stage, bool isPremiumLocked, bool isLocked) async {
    if (isPremiumLocked) {
      final passedGate = await requireParentalGate(context);
      if (!passedGate || !context.mounted) return;
      Navigator.of(context).pushNamed('/upgrade');
    } else if (!isLocked) {
      Navigator.of(context).pushNamed('/quest', arguments: stage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final premium = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ステージ選択'),
        backgroundColor: kPrimaryColor,
        actions: [
          if (!premium.isPremium)
            TextButton.icon(
              onPressed: () async {
                final passedGate = await requireParentalGate(context);
                if (!passedGate || !context.mounted) return;
                Navigator.of(context).pushNamed('/upgrade');
              },
              icon: const Icon(Icons.star, color: Colors.white, size: 16),
              label: premium.isTrialActive
                  ? Text('トライアル${premium.trialDaysLeft}日',
                      style: const TextStyle(color: Colors.white, fontSize: 12))
                  : const Text('PRO', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          _GradeFilterBar(
            selected: _gradeFilter,
            onSelected: (g) => setState(() => _gradeFilter = g),
          ),
          Expanded(
            child: _gradeFilter == 0
                ? _AllGradesView(progress: progress, premium: premium, onTap: _onTapStage)
                : _SingleGradeGrid(
                    grade: _gradeFilter,
                    stages: _stagesForGrade(_gradeFilter),
                    progress: progress,
                    premium: premium,
                    onTap: _onTapStage,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 全学年ビュー（学年ごとのセクション） ──────────────────────────
class _AllGradesView extends StatelessWidget {
  final LearningProgress progress;
  final PremiumState premium;
  final void Function(BuildContext, Stage, bool, bool) onTap;

  const _AllGradesView({required this.progress, required this.premium, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: 6,
      itemBuilder: (context, index) {
        final grade = index + 1;
        final stages = getStagesForGrade(grade);
        final cleared = stages.where((s) => progress.isCleared(s.grade, s.stageNumber)).length;
        return _GradeSection(
          grade: grade,
          stages: stages,
          cleared: cleared,
          progress: progress,
          premium: premium,
          onTap: onTap,
        );
      },
    );
  }
}

class _GradeSection extends StatelessWidget {
  final int grade;
  final List<Stage> stages;
  final int cleared;
  final LearningProgress progress;
  final PremiumState premium;
  final void Function(BuildContext, Stage, bool, bool) onTap;

  const _GradeSection({
    required this.grade,
    required this.stages,
    required this.cleared,
    required this.progress,
    required this.premium,
    required this.onTap,
  });

  static const _gradeColors = [
    Color(0xFFE74C3C), Color(0xFFE67E22), Color(0xFF2ECC71),
    Color(0xFF3498DB), Color(0xFF9B59B6), Color(0xFF1ABC9C),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _gradeColors[grade - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 学年ヘッダー
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '小学${grade}年生',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$cleared / ${stages.length} クリア',
                style: const TextStyle(color: kTextMuted, fontSize: 13),
              ),
              const Spacer(),
              // 進捗バー
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stages.isEmpty ? 0 : cleared / stages.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ステージグリッド
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: stages.length,
            itemBuilder: (context, i) {
              final stage = stages[i];
              final isCleared = progress.isCleared(stage.grade, stage.stageNumber);
              final isLocked = i > 0 && !progress.isCleared(stages[i - 1].grade, stages[i - 1].stageNumber);
              final isPremiumLocked = !premium.isPremium && !premium.isTrialActive &&
                  stage.stageNumber > kFreeStageLimit;
              return _StageGridCell(
                stage: stage,
                isCleared: isCleared,
                isLocked: isLocked,
                isPremiumLocked: isPremiumLocked,
                gradeColor: color,
                onTap: () => onTap(context, stage, isPremiumLocked, isLocked),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: Colors.grey.shade200, height: 1),
      ],
    );
  }
}

// ── 単一学年グリッド（3列） ───────────────────────────────────────
class _SingleGradeGrid extends StatelessWidget {
  final int grade;
  final List<Stage> stages;
  final LearningProgress progress;
  final PremiumState premium;
  final void Function(BuildContext, Stage, bool, bool) onTap;

  const _SingleGradeGrid({
    required this.grade,
    required this.stages,
    required this.progress,
    required this.premium,
    required this.onTap,
  });

  static const _gradeColors = [
    Color(0xFFE74C3C), Color(0xFFE67E22), Color(0xFF2ECC71),
    Color(0xFF3498DB), Color(0xFF9B59B6), Color(0xFF1ABC9C),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _gradeColors[grade - 1];
    final cleared = stages.where((s) => progress.isCleared(s.grade, s.stageNumber)).length;

    return Column(
      children: [
        // 進捗ヘッダー
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                '小学${grade}年生 — $cleared / ${stages.length} クリア',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stages.isEmpty ? 0 : cleared / stages.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: stages.length,
            itemBuilder: (context, i) {
              final stage = stages[i];
              final isCleared = progress.isCleared(stage.grade, stage.stageNumber);
              final isLocked = i > 0 && !progress.isCleared(stages[i - 1].grade, stages[i - 1].stageNumber);
              final isPremiumLocked = !premium.isPremium && !premium.isTrialActive &&
                  stage.stageNumber > kFreeStageLimit;
              return _StageGridCell(
                stage: stage,
                isCleared: isCleared,
                isLocked: isLocked,
                isPremiumLocked: isPremiumLocked,
                gradeColor: color,
                onTap: () => onTap(context, stage, isPremiumLocked, isLocked),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── グリッドセル ─────────────────────────────────────────────────
class _StageGridCell extends StatelessWidget {
  final Stage stage;
  final bool isCleared;
  final bool isLocked;
  final bool isPremiumLocked;
  final Color gradeColor;
  final VoidCallback onTap;

  const _StageGridCell({
    required this.stage,
    required this.isCleared,
    required this.isLocked,
    required this.isPremiumLocked,
    required this.gradeColor,
    required this.onTap,
  });

  String _topicEmoji(MathTopicType t) {
    switch (t) {
      case MathTopicType.addition:       return '➕';
      case MathTopicType.subtraction:    return '➖';
      case MathTopicType.multiplication: return '✖️';
      case MathTopicType.division:       return '➗';
      case MathTopicType.fraction:       return '½';
      case MathTopicType.decimal:        return '0.5';
      case MathTopicType.geometry:       return '📐';
      case MathTopicType.word:           return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = isLocked || isPremiumLocked;
    final bg = isCleared
        ? kAccentGreen.withAlpha(18)
        : locked
            ? Colors.grey.shade100
            : Colors.white;
    final borderColor = isCleared
        ? kAccentGreen
        : locked
            ? Colors.grey.shade300
            : gradeColor.withAlpha(60);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: (isLocked && !isPremiumLocked) ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isCleared ? 2 : 1),
            boxShadow: locked
                ? null
                : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Stack(
            children: [
              // クリア済みチェック
              if (isCleared)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.check_circle, color: kAccentGreen, size: 16),
                ),
              // PRO星マーク
              if (isPremiumLocked)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.star, color: kAccentOrange, size: 16),
                ),
              // コンテンツ
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      locked ? '🔒' : _topicEmoji(stage.topicType),
                      style: const TextStyle(fontSize: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stage.stageNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: locked ? kTextMuted : gradeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.title,
                      style: TextStyle(
                        fontSize: 10,
                        color: locked ? kTextMuted : kTextDark,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── フィルターバー ───────────────────────────────────────────────
class _GradeFilterBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _GradeFilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _FilterChip(label: '全て', selected: selected == 0, onTap: () => onSelected(0)),
          ...List.generate(6, (i) => _FilterChip(
            label: '小${i + 1}',
            selected: selected == i + 1,
            onTap: () => onSelected(i + 1),
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? kPrimaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : kTextMuted,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
