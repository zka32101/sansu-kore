import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_content_model.dart';
import '../providers/lesson_provider.dart';
import '../theme/app_theme_base.dart';
import 'furigana_text.dart';

/// 全教科共通の「解説メニュー」一覧ページ。カテゴリ別にグルーピングして表示する。
///
/// 使い方:
/// ```dart
/// class LessonScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return LessonMenuPage(lessons: kMyLessons);
///   }
/// }
/// ```
class LessonMenuPage extends ConsumerWidget {
  final List<LessonContent> lessons;

  const LessonMenuPage({super.key, required this.lessons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonState = ref.watch(lessonProvider);

    final categories = <String, List<LessonContent>>{};
    for (final lesson in lessons) {
      categories.putIfAbsent(lesson.category, () => []).add(lesson);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('学ぶ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${lessonState.readCount}/${lessons.length} よんだ',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: lessons.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in categories.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                  ),
                  ...entry.value.map((lesson) => _LessonCard(lesson: lesson)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('まだ解説記事がありません',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends ConsumerWidget {
  final LessonContent lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = ref.watch(lessonProvider).isRead(lesson.id);
    final isFavorite = ref.watch(lessonProvider).isFavorite(lesson.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isRead
                ? kAccentGreen.withAlpha(20)
                : Theme.of(context).colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(lesson.emoji, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(lesson.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${lesson.grade}年生 ・ 読了目安${lesson.estimatedReadMinutes}分',
            style: const TextStyle(fontSize: 11, color: kTextMuted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFavorite) const Icon(Icons.star, color: Colors.amber, size: 18),
            if (isRead) const Icon(Icons.check_circle, color: kAccentGreen, size: 18),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: kTextMuted),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LessonDetailPage(lesson: lesson)),
          );
        },
      ),
    );
  }
}

/// 解説記事の本文表示ページ。開くと自動的に既読を記録する。
class LessonDetailPage extends ConsumerStatefulWidget {
  final LessonContent lesson;

  const LessonDetailPage({super.key, required this.lesson});

  @override
  ConsumerState<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends ConsumerState<LessonDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lessonProvider.notifier).markAsRead(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isFavorite = ref.watch(lessonProvider).isFavorite(lesson.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: Colors.white),
            onPressed: () => ref.read(lessonProvider.notifier).toggleFavorite(lesson.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(lesson.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${lesson.category} ・ ${lesson.grade}年生 ・ 読了目安${lesson.estimatedReadMinutes}分',
                    style: const TextStyle(fontSize: 12, color: kTextMuted)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final section in lesson.sections) ...[
            if (section.heading != null) ...[
              Text(section.heading!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
              const SizedBox(height: 8),
            ],
            FuriganaText(
              section.body,
              style: const TextStyle(fontSize: 15, height: 2.0, color: kTextDark),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
