import 'package:flutter/material.dart';

/// {漢字|かんじ} 形式のテキストをルビ付きで表示する全教科共通ウィジェット。
///
/// これまで国語・理科など各アプリが個別に重複実装していたものを統合。
///
/// 使い方:
/// ```dart
/// FuriganaText('{昆虫|こんちゅう}は{体|からだ}が3つに分かれます')
/// ```
class FuriganaText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const FuriganaText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ??
        DefaultTextStyle.of(context).style.copyWith(
              fontSize: 14,
              height: 2.0, // ふりがな分の行間を確保
            );
    return Text.rich(
      TextSpan(children: _parse(text, base)),
      textAlign: textAlign,
    );
  }

  static List<InlineSpan> _parse(String text, TextStyle base) {
    final result = <InlineSpan>[];
    final pattern = RegExp(r'\{([^|{}]+)\|([^}]+)\}');
    int cursor = 0;

    for (final m in pattern.allMatches(text)) {
      if (m.start > cursor) {
        result.add(TextSpan(text: text.substring(cursor, m.start), style: base));
      }
      result.add(WidgetSpan(
        alignment: PlaceholderAlignment.bottom,
        child: _RubySegment(kanji: m.group(1)!, reading: m.group(2)!, baseStyle: base),
      ));
      cursor = m.end;
    }

    if (cursor < text.length) {
      result.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return result;
  }

  /// マークアップを取り除いた素のテキストを返す（一覧のサブタイトル等で使用）。
  static String plainText(String text) {
    return text.replaceAllMapped(
      RegExp(r'\{([^|{}]+)\|([^}]+)\}'),
      (m) => m.group(1)!,
    );
  }
}

class _RubySegment extends StatelessWidget {
  final String kanji;
  final String reading;
  final TextStyle baseStyle;

  const _RubySegment({required this.kanji, required this.reading, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final kanjiSize = baseStyle.fontSize ?? 14.0;
    final rubySize = kanjiSize * 0.52;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          reading,
          style: baseStyle.copyWith(fontSize: rubySize, height: 1.0, letterSpacing: 0),
          textAlign: TextAlign.center,
        ),
        Text(kanji, style: baseStyle.copyWith(height: 1.0), textAlign: TextAlign.center),
      ],
    );
  }
}
