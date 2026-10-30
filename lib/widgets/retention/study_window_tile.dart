import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show StudyWindow, notificationPlanProvider, requireParentalGate;

/// 保護者が「勉強してほしい時間帯」を決める設定。
/// 学習のおしらせ（通知）が、この時間帯の中で一番学習しやすい時刻に届く。
/// 「指定しない」なら、お子さまが実際に学習している時間帯から自動で決める。
class StudyWindowTile extends ConsumerWidget {
  const StudyWindowTile({super.key});

  static const _options = <(String, StudyWindow?)>[
    ('指定しない（学習している時間帯に合わせる）', null),
    ('朝（7〜8時）', StudyWindow.morning),
    ('帰宅後（16〜18時）', StudyWindow.afterSchool),
    ('夜（18〜20時）', StudyWindow.evening),
  ];

  static String _label(StudyWindow? w) {
    for (final o in _options) {
      if (o.$2?.startHour == w?.startHour && o.$2?.endHour == w?.endHour) {
        return o.$1;
      }
    }
    return w == null ? _options.first.$1 : '${w.startHour}〜${w.endHour}時';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(notificationPlanProvider).studyWindow;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.teal),
        title: const Text('勉強の時間帯'),
        subtitle: Text(_label(window)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(context, ref, window),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    StudyWindow? current,
  ) async {
    final passed = await requireParentalGate(
      context,
      title: '保護者の方へ確認',
      description: 'これは勉強の時間帯を決める操作です。\n下の計算の答えを入力してください。',
    );
    if (!passed || !context.mounted) return;

    final notifier = ref.read(notificationPlanProvider.notifier);
    final picked = await showDialog<_Pick>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('勉強の時間帯'),
        children: [
          for (final o in _options)
            ListTile(
              title: Text(o.$1),
              trailing:
                  o.$2?.startHour == current?.startHour &&
                      o.$2?.endHour == current?.endHour
                  ? const Icon(Icons.check, color: Colors.teal)
                  : null,
              onTap: () => Navigator.pop(ctx, _Pick(o.$2)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await notifier.setStudyWindow(picked.window);
  }
}

/// 「指定しない（null）」と「ダイアログを閉じた（null）」を区別するための入れ物。
class _Pick {
  final StudyWindow? window;
  const _Pick(this.window);
}
