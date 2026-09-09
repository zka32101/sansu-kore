import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/screen_time_model.dart';

/// [BaseScreenTimeNotifier] の状態。
class ScreenTimeState {
  final ScreenTimeSettings settings;
  final ScreenTimeUsage usage;

  const ScreenTimeState({
    this.settings = const ScreenTimeSettings(),
    this.usage = const ScreenTimeUsage(date: ''),
  });

  ScreenTimeState copyWith({
    ScreenTimeSettings? settings,
    ScreenTimeUsage? usage,
  }) =>
      ScreenTimeState(
        settings: settings ?? this.settings,
        usage: usage ?? this.usage,
      );
}

String _todayKey() {
  final now = DateTime.now();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '${now.year}-$m-$d';
}

/// 利用時間制限（スクリーンタイム管理）の抽象基底 Notifier。
///
/// 各アプリは以下のように継承し、`storageKey` をアプリ固有の値で
/// オーバーライドする（`BaseCharacterNotifier` と同じパターン）。
///
/// ```dart
/// class ScreenTimeNotifier extends BaseScreenTimeNotifier {
///   @override
///   String get storageKey => 'myapp_screen_time';
/// }
///
/// final screenTimeProvider =
///     NotifierProvider<BaseScreenTimeNotifier, ScreenTimeState>(
///   ScreenTimeNotifier.new,
/// );
/// ```
///
/// アプリがフォアグラウンドにある間、1分ごとに [ScreenTimeUsage.usedMinutes]
/// を加算する。バックグラウンドに回っている間はカウントを止める
/// （[WidgetsBindingObserver] でライフサイクルを監視）。日付が変わった場合は
/// 次回のチェック時に自動的に利用時間がリセットされる。
///
/// 保護者ゲート（`ParentalGateDialog` / `requireParentalGate`）を通すかどうかは
/// 呼び出し元の責務。このクラス自体はゲートの存在を知らない。
abstract class BaseScreenTimeNotifier extends Notifier<ScreenTimeState>
    with WidgetsBindingObserver {
  /// SharedPreferences のキーに使うプレフィックス。アプリごとに一意な値を返すこと。
  String get storageKey;

  String get _settingsKey => '${storageKey}_settings';
  String get _usageKey => '${storageKey}_usage';

  Timer? _ticker;
  bool _loaded = false;

  @override
  ScreenTimeState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _ticker?.cancel();
      _ticker = null;
    });
    Future.microtask(() async {
      await _load();
      // 初回ロード時点でアプリがフォアグラウンドならタイマーを開始する。
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        _startTicker();
      }
    });
    return const ScreenTimeState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      if (_loaded) _checkDateRollover();
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final settingsRaw = prefs.getString(_settingsKey);
    final settings = settingsRaw != null
        ? ScreenTimeSettings.fromJson(
            jsonDecode(settingsRaw) as Map<String, dynamic>)
        : const ScreenTimeSettings();

    final usageRaw = prefs.getString(_usageKey);
    var usage = usageRaw != null
        ? ScreenTimeUsage.fromJson(jsonDecode(usageRaw) as Map<String, dynamic>)
        : ScreenTimeUsage(date: _todayKey());

    if (usage.date != _todayKey()) {
      usage = ScreenTimeUsage(date: _todayKey());
      await _persistUsage(usage);
    }

    state = state.copyWith(settings: settings, usage: usage);
    _loaded = true;
  }

  void _checkDateRollover() {
    final today = _todayKey();
    if (state.usage.date != today) {
      final usage = ScreenTimeUsage(date: today);
      state = state.copyWith(usage: usage);
      unawaited(_persistUsage(usage));
    }
  }

  void _startTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _tick() async {
    if (!_loaded) return;
    _checkDateRollover();
    final usage = state.usage.copyWith(usedMinutes: state.usage.usedMinutes + 1);
    state = state.copyWith(usage: usage);
    await _persistUsage(usage);
  }

  Future<void> _persistSettings(ScreenTimeSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> _persistUsage(ScreenTimeUsage usage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usageKey, jsonEncode(usage.toJson()));
  }

  /// 1日の利用上限を設定する（分単位、null で無制限）。
  ///
  /// 保護者確認（`requireParentalGate` 等）は呼び出し元で完了させてから
  /// 呼ぶこと。このメソッド自体はゲート処理を行わない。
  Future<void> setDailyLimit(int? minutes) async {
    if (!_loaded) await _load();
    final settings = state.settings.copyWith(
      dailyLimitMinutes: minutes,
      clearDailyLimitMinutes: minutes == null,
    );
    state = state.copyWith(settings: settings);
    await _persistSettings(settings);
  }

  /// 機能そのもののON/OFFを切り替える。
  Future<void> setEnabled(bool enabled) async {
    if (!_loaded) await _load();
    final settings = state.settings.copyWith(enabled: enabled);
    state = state.copyWith(settings: settings);
    await _persistSettings(settings);
  }

  /// 今日の利用時間をリセットする（保護者による一時解除等に使用）。
  Future<void> resetTodayUsage() async {
    if (!_loaded) await _load();
    final usage = ScreenTimeUsage(date: _todayKey());
    state = state.copyWith(usage: usage);
    await _persistUsage(usage);
  }

  /// 現在の利用時間が1日の上限を超えているかどうか。
  /// 機能がOFF、または上限未設定（無制限）の場合は常に false。
  bool get isLimitReached {
    final limit = state.settings.dailyLimitMinutes;
    if (!state.settings.enabled || limit == null) return false;
    return state.usage.usedMinutes >= limit;
  }

  /// 残り利用可能時間（分）。無制限またはOFFの場合は null。
  int? get remainingMinutes {
    final limit = state.settings.dailyLimitMinutes;
    if (!state.settings.enabled || limit == null) return null;
    final remaining = limit - state.usage.usedMinutes;
    return remaining > 0 ? remaining : 0;
  }
}

/// 共通のプレースホルダー Provider — 各アプリの `ProviderScope` で
/// 必ずオーバーライドすること。
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     screenTimeProvider.overrideWith(ScreenTimeNotifier.new),
///   ],
///   child: MyApp(),
/// )
/// ```
final screenTimeProvider =
    NotifierProvider<BaseScreenTimeNotifier, ScreenTimeState>(
  () => throw UnimplementedError(
    'screenTimeProvider must be overridden in each app\'s ProviderScope',
  ),
);
