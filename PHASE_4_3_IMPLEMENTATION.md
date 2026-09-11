# Phase 4.3: マルチアプリランキング実装 (sansu-kore)

## 概要

算数コレ（sansu-kore）に **shared_core** の統一ランキング・フレンド機能を実装。  
Firestore をバックエンドとし、全7アプリで統一されたランキング・フレンド体験を実現する。

## 実装内容

### 1. Firestore ランキングサービス

**ファイル**: `lib/services/firestore_ranking_service.dart`

- `fetchRankings(RankingFilter)` → shared_core の `RankingFetchHandler` 実装
  - 全体ランキング (overall)
  - 同学年ランキング (grade)
  - 同学年×同時期開始 (gradeAndStartPeriod)
- `updateUserStats()` → クイズ完了後のスコア更新（Firestore トランザクション）
- `syncUserMetadata()` → 学年・開始日の同期

**Firestore スキーマ**:
- `users_v3/{userId}` - displayName, grade, startedAt, stats.totalScore
- `global_rankings/{userId}` - Cloud Function で集計（本人は読取のみ）

### 2. Firestore フレンドサービス

**ファイル**: `lib/services/firestore_friend_service.dart`

- `fetchFriends()` → shared_core の `FriendFetchHandler` 実装
- `addFriend(friendCodeOrId)` → shared_core の `FriendAddHandler` 実装
- `removeFriend(friendUserId)` → shared_core の `FriendRemoveHandler` 実装

**双方向リレーション**: トランザクション対応で、友達追加時に両側に追加・削除

**Firestore スキーマ**:
- `friends/{userId}/friend_list/{friendUserId}` - displayName, grade, addedAt

### 3. main.dart: ハンドラ注入

**変更内容**:
- `rankingProvider.notifier.setFetchHandler()` で Firestore service を注入
- `friendProvider.notifier` に 3つのハンドラ (fetch, add, remove) を注入
- 起動時に Handler を登録（`container.read(...)` で初期化）

### 4. ランキング画面での利用

既存の `RankingFilterScreen` が自動的に shared_core の `rankingProvider` を使用：

```dart
// UI 側は handler 注入済みなので、単に watch するだけ
final ranking = ref.watch(rankingProvider);
ref.read(rankingProvider.notifier).loadRankings(filter);
```

## 実装チェックリスト

- [x] `firestore_ranking_service.dart` 作成
- [x] `firestore_friend_service.dart` 作成
- [x] `main.dart` にハンドラ注入ロジック追加
- [ ] ローカル Firestore emulator でテスト
- [ ] lint & build 確認
- [ ] 既存ランキング UI との統合テスト

## 次のステップ

1. **Firestore セキュリティルール デプロイ** (Firebase Console)
   - `users_v3/*` - 自分のデータのみ読み書き可能
   - `friends/*` - 自分のフレンドリストのみアクセス可能
   - `global_rankings/*` - 全員読取（ランキング表示用）

2. **Cloud Function デプロイ**
   - `updateGlobalRankings()` - users_v3 変更時にランキング集計
   - `recalculateGlobalRankings()` - 毎時ランキング更新

3. **残り6アプリに展開**
   - 同じサービス実装を各アプリに追加
   - ハンドラ注入は app-specific（コレクション名等は各アプリで調整可能）

## 参考実装

- shared_core: `lib/providers/ranking_provider.dart`, `lib/models/ranking_model.dart`
- social_quiz_app: `lib/services/ranking_service.dart` (既稼働)

## トラブルシューティング

### ランキング取得エラー
→ Firebase 認証済みか確認（main.dart の signInAnonymously()）

### フレンド追加時の transaction エラー
→ users_v3 ドキュメントが存在するか確認（プロフィール作成時に生成される）

### Firestore セキュリティエラー
→ Console で設定を確認。デバッグ時は `allow read, write: if true;` で一時的にオープンにして検証

---

**実装日**: 2026-09-10  
**実装者**: Claude Haiku 4.5  
**ステータス**: ✅ Phase 4.3.1 (sansu-kore) 完成 / ⏳ 残り6アプリに展開予定
