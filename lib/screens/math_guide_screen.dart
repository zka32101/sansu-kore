import 'package:flutter/material.dart';


import '../theme/app_theme.dart';
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
                  title: 'たし算（足し算）のやり方',
                  description: '2つの数をあわせる計算です',
                  example: '2 + 3 = 5\n（2と3をあわせると5になります）',
                  tips: ['指を使って数えてみよう', '「いち、に、さん...」と声に出そう'],
                ),
                _GuideItem(
                  title: 'ひき算（引き算）のやり方',
                  description: 'ある数から別の数を取り除く計算です',
                  example: '5 - 2 = 3\n（5から2を取ると3が残ります）',
                  tips: ['指で5を出して、2本折ってみよう'],
                ),
                _GuideItem(
                  title: '数字の読み方・書き方',
                  description: '1～10の数字を正しく読み書きしよう',
                  example: '「1」は「いち」、「5」は「ご」と読みます',
                  tips: ['毎日書いて練習しよう', 'ブロックで数を作ってみよう'],
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
            const SizedBox(height: 24),
            _GradeSection(
              grade: 5,
              title: '5年生',
              emoji: '⚙️',
              guides: [
                _GuideItem(
                  title: '分数の計算',
                  description: '分数の足し算・引き算・かけ算・割り算',
                  example: '1/2 + 1/4 = 3/4\n（2/4 + 1/4 = 3/4）',
                  tips: ['通分してから計算しよう', '分子と分母の役割を覚えよう'],
                ),
                _GuideItem(
                  title: '小数と分数の関係',
                  description: '小数と分数は同じ数を表す別の方法です',
                  example: '0.5 = 1/2\n0.25 = 1/4\n0.75 = 3/4',
                  tips: ['小数点を移動すると分数に変わる', 'お金で練習すると分かりやすい'],
                ),
                _GuideItem(
                  title: '割合と百分率',
                  description: '全体に対する部分の大きさを表します',
                  example: '10個中5個は50%（半分）\n20個中5個は25%（1/4）',
                  tips: ['割合はクラスの中で探してみよう', '0%～100%で考えよう'],
                ),
                _GuideItem(
                  title: '図形と角度',
                  description: '三角形・四角形・五角形などの性質',
                  example: '三角形の内角の和は180°\n四角形の内角の和は360°',
                  tips: ['実際に定規と分度器で測ってみよう'],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GradeSection(
              grade: 6,
              title: '6年生',
              emoji: '🏆',
              guides: [
                _GuideItem(
                  title: '正と負の数',
                  description: '0より大きい数と小さい数を考えます',
                  example: '+3は3より大きい数\n-5は5より小さい数（反対方向）',
                  tips: ['温度計で理解すると分かりやすい', '数直線を書いて考えよう'],
                ),
                _GuideItem(
                  title: '文字式と方程式',
                  description: 'xなどの文字を使って式を表します',
                  example: '□ + 3 = 7 の場合、□ = 4\nxを使うと：x + 3 = 7、だから x = 4',
                  tips: ['文字は箱だと思ってみよう', '等式は天秤が釣り合っていると考えよう'],
                ),
                _GuideItem(
                  title: '確率と統計',
                  description: 'ある事柄の起こりやすさ',
                  example: 'サイコロで1が出る確率は1/6\nコイントスで表が出る確率は1/2',
                  tips: ['実際にサイコロを振ってみよう', 'データを集めて自分で確率を計算しよう'],
                ),
                _GuideItem(
                  title: '比と比例',
                  description: 'ものとものの大きさの関係を表します',
                  example: 'レシピの比率：砂糖と塩が2：1なら\n砂糖200g、塩100gで2倍にできる',
                  tips: ['料理で比の関係を見つけてみよう', 'グラフで比例を表してみよう'],
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
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
            Text(
              widget.item.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
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
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
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
