import 'package:flutter/material.dart';


import '../models/furigana_model.dart';
class FuriganaText extends StatelessWidget {
  /// 表示するテキスト
  final String text;

  /// ふりがなマップ
  final Map<String, String> furiganaMap;

  /// ベーステキストスタイル
  final TextStyle? style;

  /// ふりがなスタイル
  final TextStyle? rubyStyle;

  /// 学年（自動的にふりがなを選択）
  final int? grade;

  /// テキスト配置
  final TextAlign textAlign;

  /// 最大行数
  final int? maxLines;

  /// オーバーフロー処理
  final TextOverflow overflow;

  const FuriganaText(
    this.text, {
    Key? key,
    this.furiganaMap = const {},
    this.style,
    this.rubyStyle,
    this.grade,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseFontSize = style?.fontSize ?? 16;
    final rubyFontSize = (baseFontSize ?? 16) * 0.5;

    final displayFuriganaMap = grade != null
        ? FuriganaText.getGradeFurigana(text, grade!)
        : furiganaMap;

    final textSpans = _buildTextSpans(
      text,
      displayFuriganaMap,
      style,
      rubyStyle?.copyWith(fontSize: rubyFontSize) ??
          TextStyle(
            fontSize: rubyFontSize,
            color: (style?.color ?? Colors.black87).withOpacity(0.7),
            fontWeight: FontWeight.normal,
          ),
    );

    return RichText(
      text: TextSpan(children: textSpans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// テキストスパンをビルド
  List<InlineSpan> _buildTextSpans(
    String text,
    Map<String, String> furiganaMap,
    TextStyle? baseStyle,
    TextStyle rubyStyle,
  ) {
    final spans = <InlineSpan>[];
    var i = 0;

    while (i < text.length) {
      final char = text[i];

      if (furiganaMap.containsKey(char)) {
        // ふりがながある場合
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  furiganaMap[char]!,
                  style: rubyStyle,
                  textAlign: TextAlign.center,
                ),
                Text(
                  char,
                  style: baseStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      } else {
        // ふりがながない場合
        spans.add(
          TextSpan(
            text: char,
            style: baseStyle,
          ),
        );
      }

      i++;
    }

    return spans;
  }

  /// 学年に応じたふりがなマップを取得
  static Map<String, String> getGradeFurigana(String text, int grade) {
    final allMap = FuriganaText.allFuriganaMap();

    if (grade <= 1) {
      // 1年生: 基本漢字のみ
      return {
        for (final entry in allMap.entries)
          if (['数', '字', '年', '生'].contains(entry.key)) entry.key: entry.value
      };
    } else if (grade <= 3) {
      // 2-3年生: 中程度の難度
      return allMap;
    } else {
      // 4年生以上: 難しい漢字のみ
      return {
        for (final entry in allMap.entries)
          if (['難', '複', '確', '率', '標', '習'].contains(entry.key))
            entry.key: entry.value
      };
    }
  }

  /// 全ふりがなマップ
  static Map<String, String> allFuriganaMap() {
    return {
      '数': 'かず', '字': 'じ', '式': 'しき', '計': 'けい', '算': 'さん',
      '足': 'たし', '引': 'ひ', '掛': 'か', '割': 'わ', '分': 'ぶん',
      '年': 'ねん', '生': 'せい', '級': 'きゅう', '段': 'だん',
      '問': 'もん', '題': 'だい', '答': 'こたえ', '例': 'れい', '図': 'ず',
      '形': 'かたち', '角': 'かく', '辺': 'へん', '面': 'めん', '積': 'せき',
      '率': 'りつ', '確': 'かく', '複': 'ふく', '応': 'おう', '用': 'よう',
      '時': 'とき', '間': 'かん', '得': 'とく', '点': 'てん', '目': 'もく',
      '標': 'ひょう', '記': 'き', '録': 'ろく', '難': 'なん', '度': 'ど',
      '易': 'い', '学': 'がく', '習': 'しゅう',
    };
  }
}

/// ふりがな対応タイトルウィジェット
class FuriganaTitle extends StatelessWidget {
  /// 表示するテキスト
  final String text;

  /// テキストスタイル
  final TextStyle? style;

  /// ふりがなのスケール（相対サイズ）
  final double furiganaScale;

  /// 学年
  final int? grade;

  const FuriganaTitle({
    Key? key,
    required this.text,
    this.style,
    this.furiganaScale = 0.5,
    this.grade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final furiganaMap = grade != null
        ? FuriganaText.getGradeFurigana(text, grade!)
        : FuriganaText.allFuriganaMap();

    final baseFontSize = style?.fontSize ?? 16;
    final rubyFontSize = baseFontSize * furiganaScale;

    return FuriganaText(
      text,
      furiganaMap: furiganaMap,
      style: style,
      rubyStyle: TextStyle(
        fontSize: rubyFontSize,
        color: (style?.color ?? Colors.black87).withOpacity(0.7),
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
