// 小学コレシリーズ共通「解説メニュー」コンテンツモデル
//
// 問題を解くだけでなく、教科の仕組みを読んで学べる読み物コンテンツの型。
// コンテンツ本体（記事本文）は各アプリの lib/data/*.dart にハードコードし、
// LessonNotifier.setLessons() で注入する（badge_provider の setBadgeDefinitions と同じ方式）。

/// 1つの解説記事を構成するセクション（見出し＋本文の組）。
/// body には {漢字|ふりがな} 形式のマークアップを含められる（FuriganaText 参照）。
class LessonSection {
  final String? heading;
  final String body;

  const LessonSection({this.heading, required this.body});
}

/// 解説記事1本分。
class LessonContent {
  final String id;
  final String title;
  final String category; // 例: '国語文法', '図形', '生き物のふしぎ'
  final int grade; // 対象学年（1〜6）
  final String emoji;
  final int estimatedReadMinutes;
  final List<LessonSection> sections;
  final String? relatedStageId; // クイズのステージ等と紐づける場合に使用

  const LessonContent({
    required this.id,
    required this.title,
    required this.category,
    required this.grade,
    required this.emoji,
    required this.estimatedReadMinutes,
    required this.sections,
    this.relatedStageId,
  });
}
