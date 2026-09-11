import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/providers/premium_provider.dart';
import 'package:shared_core/widgets/premium_gate_widget.dart';

import '../data/infinite_generator.dart';
import '../models/quest_model.dart';
import '../providers/adaptive_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/furigana_text.dart';
class InfinitePracticeScreen extends ConsumerStatefulWidget {
  /// 初期トピック（ホームから渡す）。null の場合は最弱トピックを自動選択
  final MathTopicType? initialTopic;
  const InfinitePracticeScreen({super.key, this.initialTopic});

  @override
  ConsumerState<InfinitePracticeScreen> createState() =>
      _InfinitePracticeScreenState();
}

class _InfinitePracticeScreenState
    extends ConsumerState<InfinitePracticeScreen>
    with SingleTickerProviderStateMixin {
  // ─── 状態 ─────────────────────────────────────────────────────
  late MathTopicType _selectedTopic;
  late int _grade;
  late InfiniteSession _session;
  late QuizQuestion _current;

  int? _selectedAnswer;
  bool _answered = false;
  bool _showExplanation = false;

  // アニメーション
  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;

  // トピック絵文字マップ
  static const _topicEmoji = {
    MathTopicType.addition: '➕',
    MathTopicType.subtraction: '➖',
    MathTopicType.multiplication: '✖️',
    MathTopicType.division: '➗',
    MathTopicType.fraction: '½',
    MathTopicType.decimal: '.5',
    MathTopicType.geometry: '📐',
    MathTopicType.word: '📝',
  };

  static const _topicLabel = {
    MathTopicType.addition: 'たし算',
    MathTopicType.subtraction: 'ひき算',
    MathTopicType.multiplication: 'かけ算',
    MathTopicType.division: 'わり算',
    MathTopicType.fraction: '分数',
    MathTopicType.decimal: '小数',
    MathTopicType.geometry: '図形',
    MathTopicType.word: '文章題',
  };

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _feedbackAnim = CurvedAnimation(
        parent: _feedbackCtrl, curve: Curves.elasticOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final adaptive = ref.read(adaptiveProvider);
    final profile = ref.read(profileProvider).currentProfile;
    _grade = profile?.grade ?? 1;

    // トピック：引数 > 最弱トピック > デフォルト(たし算)
    _selectedTopic = widget.initialTopic ??
        adaptive.weakestTopic ??
        MathTopicType.addition;

    _session = InfiniteSession(topic: _selectedTopic, grade: _grade);
    _current = _session.next();
    setState(() {});
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ─── トピック変更 ──────────────────────────────────────────────
  void _changeTopic(MathTopicType topic) {
    setState(() {
      _selectedTopic = topic;
      _session = InfiniteSession(topic: topic, grade: _grade);
      _current = _session.next();
      _selectedAnswer = null;
      _answered = false;
      _showExplanation = false;
    });
    _feedbackCtrl.reset();
  }

  // ─── 回答 ──────────────────────────────────────────────────────
  void _onChoiceTap(int index) {
    if (_answered) return;
    final isCorrect = index == _current.correctIndex;
    _session.recordAnswer(isCorrect);

    // アダプティブ記録（1問ずつ更新）
    ref.read(adaptiveProvider.notifier).recordAnswers(
          topic: _selectedTopic,
          correct: isCorrect ? 1 : 0,
          total: 1,
        );

    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });
    _feedbackCtrl.forward(from: 0);
  }

  // ─── 次の問題 ─────────────────────────────────────────────────
  void _nextQuestion() {
    setState(() {
      _current = _session.next();
      _selectedAnswer = null;
      _answered = false;
      _showExplanation = false;
    });
    _feedbackCtrl.reset();
  }

  bool get _isCorrect => _selectedAnswer == _current.correctIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumProvider);

    // プレミアムゲーティング
    if (!premiumState.isSubscribed) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text('∞ 無限とっくん'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: PremiumGateWidget(
          featureName: '無限とっくん',
          onPremiumAccess: () {
            // TODO: RevenueCat 購入フロー
          },
          child: Container(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text('∞ 無限とっくん'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showQuitDialog(),
        ),
      ),
      body: _current.choices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── トピック選択バー ──────────────────────────────
                _TopicBar(
                  selected: _selectedTopic,
                  onSelect: _changeTopic,
                  emojiMap: _topicEmoji,
                  labelMap: _topicLabel,
                ),

                // ─── 統計バー ──────────────────────────────────────
                _StatsBar(session: _session),

                // ─── 問題 + 選択肢 ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 問題カード
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withAlpha(12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Text(
                            _current.question,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 選択肢
                        ...List.generate(_current.choices.length, (i) {
                          final isSelected = _selectedAnswer == i;
                          final isCorrect = i == _current.correctIndex;
                          Color bg = Colors.white;
                          Color border = Colors.grey.shade300;
                          Color text = kTextDark;

                          if (_answered) {
                            if (isSelected && isCorrect) {
                              bg = const Color(0xFF2ECC71);
                              border = const Color(0xFF27AE60);
                              text = Colors.white;
                            } else if (isSelected && !isCorrect) {
                              bg = kPrimaryColor;
                              border = kPrimaryDark;
                              text = Colors.white;
                            } else if (!isSelected && isCorrect) {
                              bg = const Color(0xFFD5F5E3);
                              border = const Color(0xFF27AE60);
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ScaleTransition(
                              scale: isSelected && _answered
                                  ? _feedbackAnim
                                  : const AlwaysStoppedAnimation(1.0),
                              child: GestureDetector(
                                onTap: () => _onChoiceTap(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: border, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withAlpha(8),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Text(
                                    _current.choices[i],
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: text),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // ─── フィードバック ────────────────────────
                        if (_answered) ...[
                          const SizedBox(height: 4),

                          // 誤答パターンヒント
                          if (!_isCorrect && _selectedAnswer != null)
                            _buildErrorHint(),

                          AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _isCorrect
                                    ? const Color(0xFFD5F5E3)
                                    : const Color(0xFFFAD7D7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _isCorrect
                                            ? '✅ 正解！'
                                            : '❌ 不正解...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _isCorrect
                                              ? kAccentGreen
                                              : kPrimaryColor,
                                        ),
                                      ),
                                      if (_isCorrect &&
                                          _session.streak >= 3)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8),
                                          child: _StreakBadge(
                                              streak: _session.streak),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  FuriganaText(
                                    _current.explanation,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: kTextDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                            ),
                            child: const Text('つぎの問題 →',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorHint() {
    final hint = _current.wrongHints?[_current.choices[_selectedAnswer!]];
    if (hint == null || hint.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Row(
        children: [
          const Text('🔍 ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('まちがいパターン',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF795548),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF5D4037))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('とっくん終了'),
        content: Text(
          '${_session.total}問中 ${_session.correct}問 正解しました！\n'
          '最大ストリーク: ${_session.maxStreak}問連続🔥',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('続ける')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }
}

// ─── トピック選択バー ──────────────────────────────────────────────
class _TopicBar extends StatelessWidget {
  final MathTopicType selected;
  final void Function(MathTopicType) onSelect;
  final Map<MathTopicType, String> emojiMap;
  final Map<MathTopicType, String> labelMap;

  const _TopicBar({
    required this.selected,
    required this.onSelect,
    required this.emojiMap,
    required this.labelMap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: MathTopicType.values.map((t) {
          final isSelected = t == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emojiMap[t] ?? '', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      labelMap[t] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── 統計バー ─────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final InfiniteSession session;
  const _StatsBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final pct = session.total == 0
        ? '-%'
        : '${(session.accuracy * 100).toStringAsFixed(0)}%';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: '問題数', value: '${session.total}問'),
          _StatItem(label: '正解数', value: '${session.correct}問', color: kAccentGreen),
          _StatItem(label: '正解率', value: pct),
          _StatItem(
            label: 'ストリーク',
            value: '${session.streak}🔥',
            color: session.streak >= 3 ? const Color(0xFFE74C3C) : kTextDark,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? kTextDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: kTextMuted)),
      ],
    );
  }
}

// ─── ストリークバッジ ─────────────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFE74C3C)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '🔥 $streak連続!',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
