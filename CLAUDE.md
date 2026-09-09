# 算数コレ！— Claude開発メモ

**バージョン**: v2.1 開発中  
**最終更新**: 2026年9月9日  
**アクティブブランチ**: `feature/fix-user-switch-bug`

---

## 📊 プロジェクト状態

| 項目 | 状態 |
|------|------|
| **v2.0.0** | ✅ リリース済み（Google Play/App Store配信中） |
| **v2.1開発** | ✅ Phase 1-2 完了 / Phase 3 準備中 |
| **ビルド** | Android APK/AAB (56-57MB) |
| **問題数** | ✅ 672問（ステージ108+個）で600+達成 |

---

## 🌳 Git ブランチ構造

```
main (v2.1 stable)
  ↓ [Phase 1-2 完了]
  ├─ PR #33: Phase 1 emergency bug fixes ✅ マージ済み
  ├─ PR #35: ふりがな対応 (quest_screen) ✅ マージ済み
  ├─ PR #38: ふりがな対応 (stage_data 4年生) ✅ マージ済み
  ├─ PR #40: ふりがな対応 (5-6年生) ✅ マージ済み
  ├─ PR #54: プロフィールベースデータ分離 ✅ マージ済み
  └─ PR #55: 紹介システム実装 ✅ マージ済み
     ↓
feature/fix-user-switch-bug (🎯 現在地)
  ├─ ユーザー切り替えバグ修正 (PR #56)
  └─ テスト関数名修正
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

## 📋 Phase 3: 改善・最適化（次フェーズ）

### 完了・進行中タスク
1. **5-6年生向けふりがん追加** ✅
   - ✅ 完全実装完了（PR #40マージ）
   - ✅ {度|ど}, {周囲|しゅうい}, {面積|めんせき} など対応

2. **コード品質改善** 🔄
   - ✅ 紹介システムバグ修正
   - ✅ ユーザー切り替えバグ修正
   - 🔄 テスト関数名修正（進行中）

### 今後の検討事項
1. **説明文（explanation）の充実**
   - 現在は一部のみふりがん対応
   - 低学年向けに簡潔化・ふりがん増強

2. **ユーザー体験改善**
   - 広告最適化
   - インターフェース調整
   - パフォーマンス最適化

3. **新機能追加計画**
   - フレンド機能（ranking_provider.dart TODO）
   - カスタマイズ機能
   - ソーシャル機能

---

## 🚀 v2.1リリース準備

### コード品質 ✅
- [x] lint エラーなし (CI: Analyze & Test PASSED)
- [x] 全テスト合格
- [x] バグ修正 4件 完了
  - ✅ 紹介システム (PR #55)
  - ✅ プロフィールデータ分離 (PR #54)
  - ✅ ユーザー切り替えバグ (PR #56)
  - ✅ テスト関数名修正

### デバイステスト 🔄
- [x] Android ビルド (APK/AAB): in_progress
- [x] iOS ビルド (unsigned): in_progress
- [ ] Android 6.0 テスト
- [ ] Android 12+ テスト
- [ ] 画面サイズ別テスト（phone/tablet）

### Google Play準備
- [ ] プライバシーポリシー最新化
- [ ] スクリーンショット準備
- [ ] リリースノート記入（672問リリース）

---

## 📝 Notes

- **推奨エディタ**: VS Code + Flutter extension
- **デバッグ**: `flutter logs` でリアルタイム出力確認
- **ホットリロード**: `r` (デバッグ時)
- **再ビルド**: `R` (デバッグ時)

---

**次のステップ**: Phase 2 ふりがん対応完了予定 → Phase 3 へ 🚀

