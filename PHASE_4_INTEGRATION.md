# Phase 4 統合完了 - 算数コレ！

## 実装内容

### Phase 4.15: A/B テストフレームワーク
- Paywall デザイン A/B テスト対応
- ユーザーセグメント統計
- トラフィック割り当て・粘性割り当て（Sticky Assignment）

### Phase 4.16: Analytics・レポート強化
- 週次学習レポート（学習時間・正答率・バッジ・コイン）
- 月次成長トレンド分析
- ユーザーセグメント分析（エンゲージメント・リテンション・チャーン予測）
- 学習ゴール・チャレンジ管理

### Phase 4.17: Cloud Functions・自動実行
- 週次・月次レポート自動生成
- ユーザーセグメント自動更新（毎日）
- チャーン予測・リアルタイム通知
- Firebase Cloud Functions による自動処理

## Firebase RemoteConfig 設定

以下のパラメータを Firebase Console で設定してください：

1. **ab_tests_config** (JSON)
2. **analytics_config** (JSON)
3. **cloud_functions_config** (JSON)

詳細は `../../shared_core/PHASE_4_INTEGRATION_GUIDE.md` を参照。

## UI 統合例

```dart
// lib/screens/progress_screen.dart
import 'package:shared_core/widgets/analytics_dashboard.dart';

// プログレス画面に Analytics ダッシュボード追加
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AnalyticsDashboard(userId: userId),
  ),
);
```

## メトリクス記録

各クイズ完了時にメトリクスを記録：

```dart
import 'package:shared_core/providers/analytics_notifier.dart';

// クイズ完了時
await ref.read(analyticsNotifierProvider.notifier).recordMetric(
  userId: userId,
  type: LearningMetricType.quizCompleted,
  value: 1,
  appId: 'sansu',
);
```

---

**最終更新**: 2026-09-11
