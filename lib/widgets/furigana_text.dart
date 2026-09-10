import 'package:flutter/material.dart';

/// ふりがな（ルビ）付きテキストウィジェット
/// 形式: {漢字|ふりがな} または Map<String, String> を使用
class FuriganaText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double rubyFontSizeRatio; // ふりがなのフォントサイズ比率（デフォルト: 0.55）
  final double rubyOffsetRatio; // ふりがなのオフセット比率（デフォルト: 0.8）

  const FuriganaText(
    this.text, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.rubyFontSizeRatio = 0.55,
    this.rubyOffsetRatio = 0.8,
    super.key,
  });

  /// マークアップテキストを解析してTextSpanを生成
  /// 形式: {漢字|ふりがな}
  /// 例: {算数|さんすう}、{漢字|かんじ}
  static List<TextSpan> parseMarkup(
    String text, {
    TextStyle? baseStyle,
    double rubyFontSizeRatio = 0.55,
    double rubyOffsetRatio = 0.8,
  }) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\{([^|]+)\|([^}]+)\}');
    int lastEnd = 0;

    final matches = regex.allMatches(text);

    for (final match in matches) {
      // マッチ前のテキスト
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // マッチした部分（漢字とふりがな）
      final kanji = match.group(1)!; // 漢字
      final furigana = match.group(2)!; // ふりがな

      final baseFontSize = baseStyle?.fontSize ?? 14;
      final rubyFontSize = baseFontSize * rubyFontSizeRatio;

      // ふりがな付き テキストスパン
      spans.add(
        TextSpan(
          children: [
            // ふりがな（上に配置）
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Transform.translate(
                offset: Offset(0, -rubyFontSize * rubyOffsetRatio),
                child: Text(
                  furigana,
                  style: (baseStyle ?? const TextStyle()).copyWith(
                    fontSize: rubyFontSize,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 漢字（基本テキスト）
            TextSpan(
              text: '\n$kanji',
              style: baseStyle,
            ),
          ],
        ),
      );

      lastEnd = match.end;
    }

    // 最後のテキスト
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    final spans = parseMarkup(
      text,
      baseStyle: style,
      rubyFontSizeRatio: rubyFontSizeRatio,
      rubyOffsetRatio: rubyOffsetRatio,
    );

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

/// ふりがなプリプロセッサー
/// マークアップなしにテキストを処理する場合
class FuriganaProcessor {
  /// テキストに{漢字|ふりがな}形式のマークアップを追加
  /// furiganaMap: {'漢字': 'ふりがな'} の辞書
  static String addFuriganaMarkup(
    String text,
    Map<String, String> furiganaMap,
  ) {
    String result = text;

    // 辞書の各エントリに対してマークアップを追加
    furiganaMap.forEach((kanji, furigana) {
      // 単語を逃がしてから置換（重複置換を避ける）
      result = result.replaceAll(kanji, '{$kanji|$furigana}');
    });

    return result;
  }

  /// マークアップを削除してプレーンテキストに変換
  static String removeMarkup(String text) {
    return text
        .replaceAll(RegExp(r'\{([^|]+)\|([^}]+)\}'), r'$1'); // {漢字|ふりがな} → 漢字
  }

  /// マークアップが含まれているか判定
  static bool hasMarkup(String text) {
    return RegExp(r'\{[^|]+\|[^}]+\}').hasMatch(text);
  }
}
