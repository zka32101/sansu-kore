import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/furigana_text.dart';

class MathGuideScreen extends StatelessWidget {
  const MathGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('？ 算数ガイド'),
        backgroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // グレード別ガイド
            _GradeSection(
              grade: 1,
              title: '1年生',
              emoji: '🔢',
              guides: [
                _GuideItem(
                  title: '{足|た}し{算|ざん}（{足|た}し{算|ざん}）のやり{方|かた}',
                  description: '2つの{数|かず}をあわせる{計算|けいさん}です',
                  example: '2 + 3 = 5\n（2と3をあわせると5になります）',
                  tips: ['{指|ゆび}を使って{数|かず}えてみよう', '「いち、に、さん...」と{声|こえ}に出そう'],
                ),
                _GuideItem(
                  title: 'ひき{算|ざん}（{引|ひ}き{算|ざん}）のやり{方|かた}',
                  description: 'ある{数|かず}から{別|べつ}の{数|かず}を取り{除|のぞ}く{計算|けいさん}です',
                  example: '5 - 2 = 3\n（5から2を取ると3が{残|のこ}ります）',
                  tips: ['{指|ゆび}で5を出して、2{本|ほん}{折|お}ってみよう'],
                ),
                _GuideItem(
                  title: '{数|かず}{字|じ}の{読|よ}み{方|かた}・{書|か}き{方|かた}',
                  description: '1～10の{数|かず}{字|じ}を{正|ただ}しく{読|よ}み{書|か}きしよう',
                  example: '「1」は「いち」、「5」は「ご」と{読|よ}みます',
                  tips: ['{毎日|まいにち}{書|か}いて{練習|れんしゅう}しよう', 'ブロックで{数|かず}を作ってみよう'],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GradeSection(
              grade: 2,
              title: '2年生',
              emoji: '🎯',
              guides: [
                _GuideItem(
                  title: 'かけ算（乗法）の仕組み',
                  description: '同じ数を何回も足す計算です',
                  example: '3 × 4 = 12\n（3を4回足すと12になります：3+3+3+3）',
                  tips: ['「3かける4」と読みます', 'おはじきを使って作ってみよう'],
                ),
                _GuideItem(
                  title: 'わり算（除法）とは？',
                  description: 'ある数を等しく分ける計算です',
                  example: '12 ÷ 3 = 4\n（12を3つに分けると、それぞれ4ずつ）',
                  tips: ['お菓子を友達に分けるイメージで', '「12わる3」と読みます'],
                ),
                _GuideItem(
                  title: '10より大きい数',
                  description: '10を超える数の考え方',
                  example: '15は「10と5」、23は「20と3」と考えます',
                  tips: ['十の位と一の位を分けて考えよう'],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GradeSection(
              grade: 3,
              title: '3年生',
              emoji: '📐',
              guides: [
                _GuideItem(
                  title: '分数（ぶんすう）とは',
                  description: 'ケーキやピザを切り分けた部分を表します',
                  example: '1/2（2分の1）= 全体の半分\n1/4（4分の1）= 全体の1/4',
                  tips: ['ピザを切り分ける様子を想像してみて', 'おりがみで実際に折ってみよう'],
                ),
                _GuideItem(
                  title: '時間の読み方',
                  description: '時計を読めるようになろう',
                  example: '短い針が3、長い針が12なら「3時」\n長い針が6なら「30分」',
                  tips: ['毎日、家の時計を読んでみよう', '砂時計で1分を数えてみよう'],
                ),
                _GuideItem(
                  title: '図形の基本',
                  description: 'いろいろな形を勉強します',
                  example: '三角形：3つの辺と3つの角\n四角形：4つの辺と4つの角',
                  tips: ['身の回りの形を探してみよう', 'ブロックで作ってみよう'],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GradeSection(
              grade: 4,
              title: '4年生',
              emoji: '📊',
              guides: [
                _GuideItem(
                  title: '小数（しょうすう）の計算',
                  description: '1より小さい数を表す方法です',
                  example: '0.5 = 1/2（半分）\n0.25 = 1/4（1/4）',
                  tips: ['小数点の位置が大事', 'お金（円）で練習してみよう'],
                ),
                _GuideItem(
                  title: '面積（めんせき）と体積',
                  description: 'どのくらい広いか、どのくらい入るか',
                  example: '面積：1cm × 5cm = 5cm²\n体積：1cm × 1cm × 2cm = 2cm³',
                  tips: ['教室の床の面積を計算してみよう'],
                ),
                _GuideItem(
                  title: 'グラフと統計',
                  description: 'データを表やグラフで表す方法',
                  example: 'クラスの身長を棒グラフで表す\n好きな食べ物を円グラフで表す',
                  tips: ['自分で棒グラフを作ってみよう'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeSection extends StatelessWidget {
  final int grade;
  final String title;
  final String emoji;
  final List<_GuideItem> guides;

  const _GradeSection({
    required this.grade,
    required this.title,
    required this.emoji,
    required this.guides,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // グレードヘッダー
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryColor, width: 2),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ガイドアイテム
        ...guides.map((guide) => _GuideItemWidget(item: guide)),
      ],
    );
  }
}

class _GuideItemWidget extends StatefulWidget {
  final _GuideItem item;
  const _GuideItemWidget({required this.item});

  @override
  State<_GuideItemWidget> createState() => _GuideItemWidgetState();
}

class _GuideItemWidgetState extends State<_GuideItemWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル行
            Row(
              children: [
                Expanded(
                  child: FuriganaText(
                    widget.item.title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: kPrimaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 説明
            FuriganaText(
              widget.item.description,
              fontSize: 14,
              color: Colors.grey,
            ),
            // 展開時の詳細
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '例）',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.example,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ヒント
              const Text(
                '💡 コツ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              ...widget.item.tips.map((tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: FuriganaText(
                          tip,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuideItem {
  final String title;
  final String description;
  final String example;
  final List<String> tips;

  _GuideItem({
    required this.title,
    required this.description,
    required this.example,
    required this.tips,
  });
}
