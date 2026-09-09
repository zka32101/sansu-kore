import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/screen_time_provider.dart';
import '../theme/app_theme_base.dart';
import '../utils/parental_gate_helper.dart';

/// 1日の利用時間上限に達した際に表示する全画面オーバーレイ。
///
/// [ScreenTimeState.isLimitReached] が true になったタイミングで、呼び出し側が
/// `Navigator.push`（フルスクリーンダイアログ推奨）などで表示する想定。
/// 保護者ゲートを通せば「もう少しだけ」ボタンから一時的に解除できる。
///
/// ```dart
/// if (ref.watch(screenTimeProvider.select((s) => notifier.isLimitReached))) {
///   return ScreenTimeLimitReachedWidget(primaryColor: kAccentBlue);
/// }
/// ```
class ScreenTimeLimitReachedWidget extends ConsumerWidget {
  final Color primaryColor;

  /// 一時解除で追加される分数（保護者ゲート通過後に加算）。
  final int extraMinutesOnOverride;

  /// 一時解除ボタンを表示するか。子ども向け端末では非表示にしたい場合は false に。
  final bool allowParentalOverride;

  const ScreenTimeLimitReachedWidget({
    super.key,
    required this.primaryColor,
    this.extraMinutesOnOverride = 15,
    this.allowParentalOverride = true,
  });

  Future<void> _handleOverride(BuildContext context, WidgetRef ref) async {
    final passedGate = await requireParentalGate(
      context,
      title: '保護者の方へ確認',
      description: 'これは大人の方が行う操作です。\n下の計算の答えを入力してください。',
    );
    if (!passedGate || !context.mounted) return;

    final notifier = ref.read(screenTimeProvider.notifier);
    final current = ref.read(screenTimeProvider).settings.dailyLimitMinutes;
    if (current != null) {
      await notifier.setDailyLimit(current + extraMinutesOnOverride);
    }
    if (context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: primaryColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⏰', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 20),
                  const Text(
                    '今日はここまで！',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'また明日遊ぼうね😊\nたくさん頑張ったね！',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (allowParentalOverride) ...[
                    const SizedBox(height: 36),
                    TextButton(
                      onPressed: () => _handleOverride(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: const Text(
                        '保護者の方はこちら（もう少しだけ）',
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 保護者向け設定画面に組み込むための、利用時間制限の設定ウィジェット。
///
/// ON/OFF切り替えと、上限時間のスライダーを提供する。呼び出し側の画面は
/// 通常 `requireParentalGate()` を通した後にこのウィジェットへ遷移する想定
/// （このウィジェット自体はゲート処理を行わない）。
///
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     final passed = await requireParentalGate(context);
///     if (!passed || !context.mounted) return;
///     Navigator.push(context, MaterialPageRoute(
///       builder: (_) => Scaffold(
///         appBar: AppBar(title: const Text('利用時間の設定')),
///         body: ScreenTimeSettingsWidget(primaryColor: kAccentBlue),
///       ),
///     ));
///   },
///   child: const Text('利用時間を設定する'),
/// )
/// ```
class ScreenTimeSettingsWidget extends ConsumerWidget {
  final Color primaryColor;

  /// スライダーの下限（分）。
  final int minMinutes;

  /// スライダーの上限（分）。
  final int maxMinutes;

  /// スライダーの刻み幅（分）。
  final int stepMinutes;

  const ScreenTimeSettingsWidget({
    super.key,
    required this.primaryColor,
    this.minMinutes = 15,
    this.maxMinutes = 180,
    this.stepMinutes = 15,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenTimeProvider);
    final notifier = ref.read(screenTimeProvider.notifier);
    final settings = state.settings;
    final currentLimit = settings.dailyLimitMinutes ?? minMinutes;
    final divisions = ((maxMinutes - minMinutes) / stepMinutes).round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: SwitchListTile(
            title: const Text(
              '利用時間を制限する',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('1日の利用時間に上限を設定できます'),
            value: settings.enabled,
            activeColor: primaryColor,
            onChanged: (value) => notifier.setEnabled(value),
          ),
        ),
        if (settings.enabled) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1日の利用上限',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentLimit 分',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Slider(
                    value: currentLimit.toDouble().clamp(
                        minMinutes.toDouble(), maxMinutes.toDouble()),
                    min: minMinutes.toDouble(),
                    max: maxMinutes.toDouble(),
                    divisions: divisions > 0 ? divisions : null,
                    activeColor: primaryColor,
                    label: '$currentLimit 分',
                    onChanged: (value) =>
                        notifier.setDailyLimit(value.round()),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$minMinutes分',
                          style: const TextStyle(
                              fontSize: 12, color: kTextMuted)),
                      Text('$maxMinutes分',
                          style: const TextStyle(
                              fontSize: 12, color: kTextMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.today, color: kTextMuted),
              title: const Text('今日の利用時間'),
              trailing: Text(
                '${state.usage.usedMinutes} 分',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
