# 算数コレ！— Claude開発メモ

**バージョン**: v2.1 開発完了  
**最終更新**: 2026年9月9日  
**アクティブブランチ**: `main`

---

## 📊 プロジェクト状態

| 項目 | 状態 |
|------|------|
| **v2.0.0** | ✅ リリース済み（Google Play/App Store配信中） |
| **v2.1開発** | ✅ Phase 1-3 完了 / リリース準備中 |
| **ビルド** | Android APK/AAB (56-57MB) |
| **問題数** | ✅ 672問（ステージ108+個）で600+達成 |

---

## 🌳 Git ブランチ構造

```
main (v2.1 stable) 🎯 現在地
  ↓ [Phase 1-2 完了]
  ├─ PR #33: Phase 1 emergency bug fixes ✅ マージ済み
  ├─ PR #35: ふりがな対応 (quest_screen) ✅ マージ済み
  ├─ PR #38: ふりがな対応 (stage_data 4年生) ✅ マージ済み
  ├─ PR #40: ふりがな対応 (5-6年生) ✅ マージ済み
  ├─ PR #54: プロフィールベースデータ分離 ✅ マージ済み
  └─ PR #55: 紹介システム実装 ✅ マージ済み
     ↓ [Phase 3 完了]
  ├─ PR #60: Google Mobile Ads 統合 ✅ マージ済み
  ├─ PR #61: ホーム画面バナー広告 ✅ マージ済み
  ├─ PR #62: フレンド機能 UI ✅ マージ済み
  └─ PR #63: 算数の学ぶ機能（LessonContent） ✅ マージ済み
```

---

## ✅ Phase 1: 緊急バグ修正（Week 1-2）完了

### 完了したタスク

#### 1. 紹介機能バグ修正 ✅
**状態**: PR #55 マージ完了  
**内容**: Firestoreベースの紹介コードシステム実装

**実装ファイル**:
```
lib/models/referral_model.dart       (紹介コード管理) ✅
lib/providers/referral_provider.dart (紹介ロジック) ✅
lib/screens/invite_screen.dart       (UI更新) ✅
```

**実装内容**:
- ✅ ReferralCode モデル (有効期限、使用回数制限)
- ✅ generateCode(): 時限付きコード生成
- ✅ redeemCode(): Firestoreトランザクション対応
- ✅ 紹介者: +100 coins、紹介された側: +50 coins
- ✅ 最大5回使用可能、90日有効期限

**進捗**:
- [x] `referral_model.dart` 作成
- [x] `referral_provider.dart` 作成
- [x] `invite_screen.dart` 修正
- [x] テスト・リリース完了（PR #55）

---

#### 2. ユーザー切り替えバグ修正 ✅
**現状**: ログアウト後も前のユーザーデータが残存  
**対応**: プレフィックスベースの選別クリア実装

**修正ファイル**:
```
lib/providers/logout_provider.dart   (完全リセット実装) ✅
lib/providers/profile_provider.dart  (プロフィールベース対応) ✅
```

**実装内容**:
- ✅ `prefs.clear()` → 選別削除に変更
- ✅ 削除対象: stage_cleared_*, badge_earned_*, character_* など14種類
- ✅ 保持対象: user_profiles, current_profile_id
- ✅ profileProvider.notifier.clearUserData() 呼び出し
- ✅ 全provider invalidate で完全リセット

**進捗**:
- [x] logout() メソッド実装
- [x] provider reset 処理
- [x] テスト修正 (getStagesByGrade → getStagesForGrade)
- [x] PR #56 作成（審査中）

---

#### 3. 選択肢ランダム配置 ✅
**現状**: 正解が2番目・3番目に偏っている  
**対応**: ビルド時にシャッフル

**実装ファイル**:
```
lib/models/quest_model.dart  (randomizeChoices メソッド) ✅
lib/data/stage_data.dart     (全ステージで適用) ✅
```

**実装内容**:
- ✅ `randomizeChoices()`: Fisher-Yates シャッフルアルゴリズム
- ✅ wrongHints マッピングの自動再調整
- ✅ getStagesForGrade() で自動適用
- ✅ テスト時の seed 固定対応

**進捗**:
- [x] randomizeChoices() メソッド追加
- [x] stage_data で適用（すべてのステージ）
- [x] テスト実装・検証完了

---

## ✨ Phase 2: 機能改善 ✅ 完了

### 完了したタスク

#### 1. ホーム画面にガイドセクション追加 ✅
**状態**: 完了  
**実装内容**: 
- math_guide_screen.dart / math_guide_widgets.dart 実装済み
- ホーム画面に算数ガイドセクション表示
- 学年別ガイド機能実装済み

**関連PR**: PR #32-33 (既マージ)

---

#### 2. 漢字にふりがなを追加 ✅
**状態**: 完全実装完了（全学年対応）
**実装内容**:
- ✅ FuriganaText widget 実装済み (furigana_text.dart)
- ✅ quest_screen で問題文・選択肢に FuriganaText 適用（PR #35）
- ✅ stage_data 1-4年生向け問題に {kanji|furigana} マークアップ追加（PR #38）
- ✅ 5-6年生向け問題にも {kanji|furigana} マークアップ追加（PR #40）

**関連PR**: 
- #35: quest_screen FuriganaText 実装 ✅ マージ済み
- #38: stage_data 1-4年生向けふりがん追加 ✅ マージ済み
- #40: stage_data 5-6年生向けふりがん追加 ✅ マージ済み

---

#### 3. ステージ倍増（54 → 108） ✅
**状態**: 完了  
**実装内容**:
- ✅ 108 ステージ実装完了（各学年18ステージ）
- ✅ 672+ 問題実装完了（計画の 600+ 達成）
- ✅ 各学年 9→18 ステージで大幅拡張

**関連PR**: 既マージ

---

## 🔧 セットアップ・ビルド手順

### 前提
- Flutter 3.11.5以上
- Android SDK (NDK含む)
- Java 17

### クリーンビルド
```bash
cd H:/マイドライブ/apps/sansu-kore
flutter clean
flutter pub get
flutter build apk --release  # Android
```

### デバッグビルド
```bash
flutter run --debug
```

---

## 📦 バージョン管理

**pubspec.yaml**:
```yaml
version: 2.0.0+2  # v2.0.0リリース版
# v2.1開発時に 2.1.0+3 に更新
```

**Git Tag**:
```bash
git tag v2.0.0     # リリース版
git tag v2.1-beta1 # 開発版
```

---

## ✨ Phase 3: UI/UX 改善・機能拡張 ✅ 完了

### 完了したタスク

#### 1. Google Mobile Ads 統合 ✅
**状態**: PR #60 マージ完了  
**内容**: AdMob 統合とバナー広告・インタースティシャル広告・リワード広告の実装

**実装ファイル**:
```
lib/providers/ads_provider.dart      (AdsNotifier, 広告管理ロジック) ✅
lib/utils/constants.dart             (adsEnabled フラグ) ✅
```

**実装内容**:
- ✅ AdsNotifier: 広告初期化・読み込み・表示を管理
- ✅ banner_ad, interstitial_ad, rewarded_ad の複数形式対応
- ✅ テスト用 Ad Unit IDs（各形式・プラットフォーム別）
- ✅ kDebugMode に応じた自動切り替え
- ✅ 広告読み込み完了時の自動リロード機構

**進捗**:
- [x] ads_provider.dart 実装
- [x] FeatureFlags に adsEnabled を追加
- [x] テスト・検証完了（PR #60）

---

#### 2. ホーム画面バナー広告表示 ✅
**状態**: PR #61 マージ完了  
**内容**: ホーム画面下部にバナー広告を表示

**実装ファイル**:
```
lib/screens/home_screen.dart         (バナー広告表示ウィジェット) ✅
```

**実装内容**:
- ✅ CustomScrollView 構造を保持しつつバナー広告を統合
- ✅ _BannerAdWidget で adsProvider を監視
- ✅ 広告未初期化時は SizedBox.shrink() で非表示
- ✅ ホーム画面下部に固定表示

**進捗**:
- [x] ホーム画面レイアウト修正
- [x] バナー広告ウィジェット実装
- [x] テスト・検証完了（PR #61）

---

#### 3. フレンド機能 UI ✅
**状態**: PR #62 マージ完了  
**内容**: フレンド管理とフレンドリクエスト機能の UI 実装

**実装ファイル**:
```
lib/screens/friends_list_screen.dart      (フレンドリスト表示) ✅
lib/screens/add_friend_screen.dart        (フレンド追加) ✅
lib/screens/friend_requests_screen.dart   (リクエスト管理) ✅
lib/main.dart                             (ルート登録) ✅
```

**実装内容**:
- ✅ FriendsListScreen: フレンド一覧表示・削除機能
- ✅ AddFriendScreen: ユーザー ID 入力・リクエスト送信
- ✅ FriendRequestsScreen: 受け取ったリクエスト確認・受諾/拒否
- ✅ main.dart に 3 つのルート登録

**進捗**:
- [x] 3 つのフレンド画面実装
- [x] routes に登録
- [x] テスト・検証完了（PR #62）

---

#### 4. 算数の学ぶ機能（LessonContent） ✅
**状態**: PR #63 マージ完了  
**内容**: 学年別の解説記事と「学ぶ」メニュー機能

**実装ファイル**:
```
packages/shared_core/lib/models/lesson_content_model.dart   (モデル) ✅
packages/shared_core/lib/providers/lesson_provider.dart      (プロバイダー) ✅
packages/shared_core/lib/widgets/lesson_menu_page.dart       (UI) ✅
lib/data/lesson_data.dart                                   (記事データ) ✅
lib/screens/lesson_screen.dart                              (画面) ✅
```

**実装内容**:
- ✅ 8 つの解説記事（計算・分数・時間・図形・小数・割合・速さ）
- ✅ 学年別フィルタリング機能
- ✅ ふりがな対応テキスト表示
- ✅ ホーム画面に「学ぶ」導線カード追加

**進捗**:
- [x] lesson_content_model 実装
- [x] lesson_data に 8 つの記事を追加
- [x] LessonMenuPage UI 実装
- [x] ホーム画面統合
- [x] テスト・検証完了（PR #63）

### Phase 4: 将来の検討事項
1. **説明文（explanation）の充実**
   - 現在は一部のみふりがん対応
   - 低学年向けに簡潔化・ふりがん増強

2. **広告最適化**
   - リワード広告の段階的導入
   - インタースティシャル広告の配置最適化
   - 実制作 Ad Unit IDs への切り替え

3. **ソーシャル機能拡張**
   - フレンドランキング統合
   - メッセージング機能
   - シェアボード機能

---

## 🚀 v2.1 リリース準備

### コード品質 ✅
- [x] lint エラーなし (CI: Analyze & Test ALL PASSED)
- [x] 全テスト合格
- [x] バグ修正・機能実装 7件 完了
  - ✅ 紹介システム (PR #55)
  - ✅ プロフィールデータ分離 (PR #54)
  - ✅ ユーザー切り替えバグ (PR #56)
  - ✅ Google Mobile Ads 統合 (PR #60)
  - ✅ ホーム画面バナー広告 (PR #61)
  - ✅ フレンド機能 UI (PR #62)
  - ✅ 算数の学ぶ機能 (PR #63)

### 機能リリース情報
| 項目 | v2.0 | v2.1 |
|------|------|------|
| **ステージ数** | 54 | 108 (+100%) |
| **問題数** | 300+ | 672+ (+120%) |
| **ふりがな対応** | なし | ✅ 全問題対応 |
| **フレンド機能** | なし | ✅ 追加 |
| **学ぶ機能** | なし | ✅ 8つの記事 |
| **広告システム** | なし | ✅ 統合 |

### デバイステスト 🔄
- [x] Android ビルド (APK/AAB): ✅ 完了
- [ ] iOS ビルド (unsigned): ⏳ 準備中
- [ ] Android 6.0 テスト
- [ ] Android 12+ テスト
- [ ] 画面サイズ別テスト（phone/tablet）

### Google Play準備

**コード側（v2.1 dev完了）**:
- [x] AdMob SDK 統合完了
  - Android & iOS 広告 ID 設定済み（テスト環境用）
  - iOS Info.plist に GADApplicationIdentifier 追加
- [x] iOS ビルド対応確認完了
  - iOS Podfile 設定済み
  - Info.plist AdMob 設定追加
  - 実機ビルド・署名はユーザー実作業
- [x] リリースノート（CHANGELOG.md）作成済み

**本番化手順（AdMob Ad Unit IDs 設定）**:
1. AdMob コンソール（admob.google.com）でアプリを登録
2. 広告ユニットを作成（バナー・インタースティシャル・リワード各形式）
3. `lib/providers/ads_provider.dart` の `AdUnitIds` クラスを更新:
   ```dart
   // テスト環境用（開発時のままでOK）
   static const String androidBannerId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
   // 本番環境用（AdMob コンソールから取得したIDに置き換え）
   ```
4. `pubspec.yaml` の google_mobile_ads を有効化
5. `flutter build apk/aab --release` で本番ビルド

**ユーザー実作業** ⬇️:
- [ ] プライバシーポリシー最新化・確定
- [ ] スクリーンショット準備（7-8枚）
- [ ] AdMob アカウント登録・アプリ申請
- [ ] AdMob 広告ユニット作成（ID取得）
- [ ] 実機テスト（Android 6.0/12+、デバイス複数）
- [ ] Google Play ストアアカウント準備
- [ ] Google Play に v2.1 を申請・公開

---

## 📝 Notes

- **推奨エディタ**: VS Code + Flutter extension
- **デバッグ**: `flutter logs` でリアルタイム出力確認
- **ホットリロード**: `r` (デバッグ時)
- **再ビルド**: `R` (デバッグ時)

---

**次のステップ**: Phase 3 完了 → v2.1 リリース準備（Google Play / App Store） 🚀

---

## 📊 v2.1 リリース進捗

**現在**: コード実装 100% 完了、テスト・検証進行中  
**次フェーズ**: Google Play ストアプレビュー・リリース準備  
**目標**: 2026年9月中に v2.1 リリース予定

