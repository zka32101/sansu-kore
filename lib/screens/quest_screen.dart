import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show characterStateProvider;


import '../models/quest_model.dart';
import '../providers/adaptive_provider.dart';
import '../providers/character_level_provider.dart';
import '../providers/ghost_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/sansu_profile_provider.dart';
import '../providers/tts_provider.dart';
import '../providers/tts_provider.dart' as tts_enums show TtsSource;
import '../theme/app_theme.dart';
import '../widgets/calculation_steps_widget.dart';
import '../widgets/furigana_text.dart';
import '../widgets/geometry_visual_widget.dart';
class QuestScreen extends ConsumerStatefulWidget {
  final Stage stage;
  const QuestScreen({super.key, required this.stage});

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen>
    with SingleTickerProviderStateMixin {
  // ─── 基本状態 ────────────────────────────────────────────────
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _showHint = false;
  late DateTime _startTime;

  // ─── アニメーション ──────────────────────────────────────────
  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;

  // ─── ①ゴーストバトル ─────────────────────────────────────────
  GhostRecord? _ghostRecord;
  late DateTime _questionStartTime;
  final List<int> _questionTimingsMs = [];
  Timer? _ghostTimer;
  int _ghostElapsedMs = 0;

  // ─── ②主人公文章題 ──────────────────────────────────────────
  String _playerName = '';
  String _favoriteItem = 'りんご';

  // ─── キャラクター表示 ────────────────────────────────────────
  String _displayCharacterId = 'ichiko'; // デフォルトキャラ

  QuizQuestion get _current => widget.stage.questions[_currentIndex];
  bool get _isCorrect => _selectedAnswer == _current.correctIndex;

  int get _stageId => widget.stage.grade * 100 + widget.stage.stageNumber;

  // ゴーストの現在進捗 (0.0〜1.0)
  double get _ghostProgress {
    if (_ghostRecord == null) return 0;
    return _ghostRecord!.progressAt(_ghostElapsedMs);
  }

  // プレースホルダー置換（②主人公文章題）
  String _applyPlaceholders(String text) {
    final name = _playerName.isEmpty ? 'きみ' : _playerName;
    final item = _favoriteItem.isEmpty ? 'りんご' : _favoriteItem;
    return text
        .replaceAll('{name}', name)
        .replaceAll('{item}', item);
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _questionStartTime = DateTime.now();

    _feedbackCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _feedbackAnim =
        CurvedAnimation(parent: _feedbackCtrl, curve: Curves.elasticOut);

    // ゴーストレコード読み込み + タイマー開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGhost();
      _loadProfile();
    });
  }

  void _initGhost() {
    final record = ref.read(ghostProvider.notifier).getRecord(_stageId);
    if (record != null) {
      setState(() => _ghostRecord = record);
      // 100ms ごとにゴーストの位置を更新
      _ghostTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) {
          _ghostTimer?.cancel();
          return;
        }
        setState(() {
          _ghostElapsedMs =
              DateTime.now().difference(_startTime).inMilliseconds;
        });
      });
    }
  }

  void _loadProfile() {
    final profile = ref.read(profileProvider).currentProfile;
    final sansu = ref.read(sansuProfileProvider);
    setState(() {
      _playerName = profile?.name ?? 'きみ';
      _favoriteItem = sansu.favoriteItem;
      // ステージから対応するキャラクターを選択
      _displayCharacterId = _getCharacterByStage(widget.stage);
    });
  }

  /// ステージの進度に応じてキャラクターを選択
  String _getCharacterByStage(Stage stage) {
    // ステージID計算
    final stageId = stage.grade * 100 + stage.stageNumber;

    // 各キャラクターのアンロック条件（ステージID）
    // Tier 1: イチコ(0)、ニニコ(3)、トライ(5)、フォーク(8)
    // Tier 2: ゴーゴ(12)、その他
    // 進度に応じてキャラを選択
    if (stageId >= 48) return 'plus_minus'; // 最終ボス
    if (stageId >= 40) return 'calcuku';
    if (stageId >= 32) return 'geome';
    if (stageId >= 24) return 'divido';
    if (stageId >= 18) return 'multiko';
    if (stageId >= 12) return 'gogo';
    if (stageId >= 8) return 'fouku';
    if (stageId >= 5) return 'trai';
    if (stageId >= 3) return 'niniko';
    return 'ichiko'; // デフォルト
  }

  /// キャラクター画像表示ウィジェット（Lv対応）
  Widget _buildCharacterImage({
    required String characterId,
    required int level,
  }) {
    final imagePath = getCharacterImagePath(characterId, level);

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withAlpha(30),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // キャラクター画像
          Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      '画像が見つかりません',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Lvバッジ（右下）
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Lv. $level',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ref.read(ttsProvider.notifier).stop();
    _feedbackCtrl.dispose();
    _ghostTimer?.cancel();
    super.dispose();
  }

  void _onChoiceTap(int index) {
    if (_answered) return;
    ref.read(ttsProvider.notifier).stop();
    final ms = DateTime.now().difference(_questionStartTime).inMilliseconds;
    _questionTimingsMs.add(ms);
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (_isCorrect) _correctCount++;
    });
    _feedbackCtrl.forward(from: 0);

    // アダプティブラーニングに記録（1問ずつ更新）
    ref.read(adaptiveProvider.notifier).recordAnswers(
          topic: widget.stage.topicType,
          correct: _isCorrect ? 1 : 0,
          total: 1,
        );
  }

  void _onNext() {
    ref.read(ttsProvider.notifier).stop();
    if (_currentIndex < widget.stage.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
        _showHint = false;
        _questionStartTime = DateTime.now();
      });
      _feedbackCtrl.reset();
    } else {
      _finishQuest();
    }
  }

  void _finishQuest() {
    _ghostTimer?.cancel();
    final elapsed = DateTime.now().difference(_startTime);
    final result = QuestResult(
      correctCount: _correctCount,
      totalCount: widget.stage.questions.length,
      elapsed: elapsed,
    );

    // ゴーストレコード保存（非同期・await不要）
    if (_questionTimingsMs.length == widget.stage.questions.length) {
      ref.read(ghostProvider.notifier).saveRecord(GhostRecord(
            stageId: _stageId,
            questionMs: List.from(_questionTimingsMs),
            playedAt: DateTime.now(),
          ));
    }

    Navigator.of(context).pushReplacementNamed(
      '/result',
      arguments: {'result': result, 'stage': widget.stage},
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.stage.questions.length;
    final progress = (_currentIndex + (_answered ? 1 : 0)) / total;
    final adaptive = ref.watch(adaptiveProvider);
    final shouldShowHint = adaptive.shouldShowHint(widget.stage.topicType);
    final tts = ref.watch(ttsProvider);

    // キャラクターレベルを取得（ショップでのレベルアップと同じソース）
    final characterStates = ref.watch(characterStateProvider);
    final characterLevel =
        characterStates[_displayCharacterId]?.level ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('ステージ ${widget.stage.stageNumber}'),
        backgroundColor: kPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('やめますか？'),
              content: const Text('今の進捗は保存されません。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('続ける')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('やめる',
                      style: TextStyle(color: kPrimaryColor)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
        children: [
          // ─── 進捗バー（ゴーストバトル対応） ──────────────────────
          _ProgressSection(
            progress: progress,
            ghostProgress: _ghostProgress,
            hasGhost: _ghostRecord != null,
          ),

          // ─── 問題番号 + ヒントボタン ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '問題 ${_currentIndex + 1} / $total',
                  style:
                      const TextStyle(color: kTextMuted, fontSize: 14),
                ),
                if (_ghostRecord != null)
                  _GhostBadge(
                    ghostMs: _ghostRecord!.totalMs,
                    currentMs: _ghostElapsedMs,
                  ),
                if (!_answered &&
                    _current.hint != null &&
                    shouldShowHint)
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showHint = !_showHint),
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label:
                        const Text('ヒント', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: kAccentOrange),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── キャラクター画像（Lv対応） ────────────────
                  _buildCharacterImage(
                    characterId: _displayCharacterId,
                    level: characterLevel,
                  ),
                  const SizedBox(height: 16),

                  // ─── ヒント ────────────────────────────────────
                  if (_showHint && _current.hint != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFFFCC02)),
                      ),
                      child: Row(
                        children: [
                          const Text('💡 ',
                              style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: FuriganaText(
                              _current.hint!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: kTextDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ─── 問題カード（②プレースホルダー対応） ─────────────
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
                    child: Column(
                      children: [
                        FuriganaText(
                          _applyPlaceholders(_current.question),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: kTextDark,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            if (tts.isSpeaking && tts.currentSource == TtsSource.question) {
                              ref.read(ttsProvider.notifier).stop();
                            } else {
                              ref.read(ttsProvider.notifier).speak(
                                    _applyPlaceholders(_current.question),
                                    source: TtsSource.question,
                                  );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: tts.isSpeaking
                                  ? kPrimaryColor.withAlpha(30)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: tts.isSpeaking
                                    ? kPrimaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tts.isSpeaking
                                      ? Icons.volume_up
                                      : Icons.volume_up_outlined,
                                  size: 18,
                                  color: tts.isSpeaking
                                      ? kPrimaryColor
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tts.isSpeaking ? '再生中...' : '読み上げ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tts.isSpeaking
                                        ? kPrimaryColor
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── 図形ビジュアル（回答後に表示） ──────────────────
                  if (_answered && _current.shapeName != null)
                    GeometryVisualWidget(shapeName: _current.shapeName!),

                  // ─── 計算過程（ヒント） ───────────────────────────
                  CalculationStepsWidget(
                    question: _current,
                    showSteps: _answered,
                  ),
                  const SizedBox(height: 24),

                  // ─── 選択肢 ────────────────────────────────────
                  ...List.generate(_current.choices.length, (i) {
                    final isSelected = _selectedAnswer == i;
                    final isCorrect = i == _current.correctIndex;

                    Color bg = Colors.white;
                    Color borderColor = Colors.grey.shade300;
                    Color textColor = kTextDark;

                    if (_answered) {
                      if (isSelected && isCorrect) {
                        bg = const Color(0xFF2ECC71);
                        borderColor = const Color(0xFF27AE60);
                        textColor = Colors.white;
                      } else if (isSelected && !isCorrect) {
                        bg = kPrimaryColor;
                        borderColor = kPrimaryDark;
                        textColor = Colors.white;
                      } else if (!isSelected && isCorrect) {
                        bg = const Color(0xFFD5F5E3);
                        borderColor = const Color(0xFF27AE60);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ScaleTransition(
                        scale: isSelected && _answered
                            ? _feedbackAnim
                            : const AlwaysStoppedAnimation(1.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _onChoiceTap(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: borderColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(8),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: FuriganaText(
                                    _current.choices[i],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ─── 選択肢読み上げボタン ─────────────────
                            GestureDetector(
                              onTap: () {
                                if (tts.isSpeaking && tts.currentSource == TtsSource.choice) {
                                  ref.read(ttsProvider.notifier).stop();
                                } else {
                                  ref.read(ttsProvider.notifier).speak(
                                        _current.choices[i],
                                        source: TtsSource.choice,
                                      );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: tts.isSpeaking
                                      ? kPrimaryColor.withAlpha(30)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tts.isSpeaking
                                        ? kPrimaryColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Icon(
                                  tts.isSpeaking
                                      ? Icons.volume_up
                                      : Icons.volume_up_outlined,
                                  size: 20,
                                  color: tts.isSpeaking
                                      ? kPrimaryColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // ─── 解説 + ④誤答パターンヒント ──────────────────
                  if (_answered) ...[
                    const SizedBox(height: 4),

                    // ④誤答パターン: 間違えた場合にエラー分析ヒントを表示
                    if (!_isCorrect && _selectedAnswer != null)
                      _ErrorPatternHint(
                        selectedText: _current.choices[_selectedAnswer!],
                        wrongHints: _current.wrongHints,
                      ),

                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _answered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? const Color(0xFFD5F5E3)
                              : const Color(0xFFFAD7D7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCorrect ? '✅ 正解！' : '❌ 不正解...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isCorrect
                                    ? kAccentGreen
                                    : kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text(
                        _currentIndex <
                                widget.stage.questions.length - 1
                            ? 'つぎの問題 →'
                            : '結果を見る！',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ─── ProgressSection（通常 + ゴースト2本バー） ──────────────────
class _ProgressSection extends StatelessWidget {
  final double progress;
  final double ghostProgress;
  final bool hasGhost;

  const _ProgressSection({
    required this.progress,
    required this.ghostProgress,
    required this.hasGhost,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasGhost) {
      return LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
        minHeight: 6,
      );
    }
    return Column(
      children: [
        // 自分の進捗バー
        Stack(
          children: [
            // バックグラウンド
            Container(
              height: 8,
              color: Colors.grey.shade200,
            ),
            // ゴーストバー（半透明オレンジ）
            FractionallySizedBox(
              widthFactor: ghostProgress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFAA44),
                ),
              ),
            ),
            // 自分のバー（青）
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              const Text('あなた', style: TextStyle(fontSize: 10, color: kTextMuted)),
              const SizedBox(width: 12),
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFAA44),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              const Text('ゴースト', style: TextStyle(fontSize: 10, color: kTextMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── ゴーストバッジ（タイム差表示） ─────────────────────────────
class _GhostBadge extends StatelessWidget {
  final int ghostMs;
  final int currentMs;

  const _GhostBadge({required this.ghostMs, required this.currentMs});

  @override
  Widget build(BuildContext context) {
    final diff = ghostMs - currentMs;
    final ahead = diff > 0;
    final absSec = (diff.abs() / 1000).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ahead
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ahead ? kAccentGreen : kAccentOrange,
          width: 1.2,
        ),
      ),
      child: Text(
        ahead ? '👻 +${absSec}秒リード' : '👻 -${absSec}秒',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: ahead ? kAccentGreen : kAccentOrange,
        ),
      ),
    );
  }
}

// ─── ④誤答パターンヒント ──────────────────────────────────────────
class _ErrorPatternHint extends StatelessWidget {
  final String selectedText;
  final Map<String, String>? wrongHints;

  const _ErrorPatternHint({
    required this.selectedText,
    required this.wrongHints,
  });

  @override
  Widget build(BuildContext context) {
    final hint = wrongHints?[selectedText];
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
                const Text(
                  'まちがいパターン',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF795548),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF5D4037)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
