import 'package:shared_core/shared_core.dart';


/// 算数コレ固有の利用時間制限（スクリーンタイム管理）ノティファイア。
///
/// 端末・アプリ単位の制限として設計しており、プロフィールごとの分離は
/// 行わない（ログアウト・プロフィール切り替えを跨いで共通の制限を適用する）。
/// main.dart で screenTimeProvider をこれで上書きする:
/// ```dart
/// screenTimeProvider.overrideWith(ScreenTimeNotifier.new)
/// ```
class ScreenTimeNotifier extends BaseScreenTimeNotifier {
  @override
  String get storageKey => 'sansu_screen_time';
}
