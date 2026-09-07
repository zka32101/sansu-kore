# 算数コレ！— Claude開発メモ

**バージョン**: v2.1 開発中  
**最終更新**: 2026年9月7日  
**アクティブブランチ**: `feature/v2.1-phase2-furigana-stage-data`

---

## 📊 プロジェクト状態

| 項目 | 状態 |
|------|------|
| **v2.0.0** | ✅ リリース済み（Google Play/App Store配信中） |
| **v2.1開発** | 🔄 Phase 2 機能改善中 |
| **ビルド** | Android APK/AAB (56-57MB) |
| **問題数** | ✅ 672問（ステージ109個）で600+達成 |

---

## 🌳 Git ブランチ構造

```
main (v2.0.0 stable)
  ↓ [PR #33 merged - Phase 1 complete]
  ├─ PR #35: ふりがな対応 (quest_screen) ✅ マージ済み
  └─ PR #38: ふりがな対応 (stage_data) 🔄 審査中
     ↓
feature/v2.1-phase2-furigana-stage-data (🎯 現在地)
  ├─ ふりがな対応（4年生向け問題）
  └─ 次: 5-6年生向けふりがん追加予定
```

---

## ✅ Phase 1: 緊急バグ修正（Week 1-2）完了

### 完了したタスク

#### 1. 紹介機能バグ修正 ✅
**状態**: コード実装完了（Firebase依存関係待ち）  
**内容**: キー発行システムに変更

**新規ファイル**:
```
lib/models/referral_model.dart       (紹介コード管理)
lib/providers/referral_provider.dart (紹介ロジック)
```

**修正ファイル**:
```
lib/screens/invite_screen.dart       (UI更新)
```

**実装内容**:
```dart
// 1. 紹介キー生成
String referralKey = "SANSU" + DateTime.now().format("yyyymmdd") + randomString(5);
// 例: SANSU20260608ABCDE

// 2. Firestore に保存
CollectionReference referralCodes = FirebaseFirestore.instance.collection('referral_codes');
await referralCodes.doc(referralKey).set({
  'creatorId': currentUser.id,
  'creatorCoins': 0,
  'usedCount': 0,
  'maxUses': 5,
  'createdAt': Timestamp.now(),
});

// 3. 紹介されたユーザーが入力
await validateAndApplyReferralCode(referralKey);
// → 紹介した側 +100 coins
// → 紹介された側 +50 coins
```

**進捗**:
- [ ] `referral_model.dart` 作成
- [ ] `referral_provider.dart` 作成
- [ ] `invite_screen.dart` 修正
- [ ] テスト

---

#### 2. ユーザー切り替えバグ修正
**現状**: ログアウト後も前のユーザーデータが残存  
**対応**: 完全クリア処理を実装

**修正ファイル**:
```
lib/providers/profile_provider.dart
lib/providers/progress_provider.dart
lib/screens/login_screen.dart
```

**実装内容**:
```dart
Future<void> logout() async {
  // 1. SharedPreferences をクリア
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  // 2. Firebase ログアウト
  await FirebaseAuth.instance.signOut();

  // 3. Provider を全リセット
  ref.invalidate(profileProvider);
  ref.invalidate(progressProvider);
  ref.invalidate(coinProvider);
  ref.invalidate(badgeProvider);
  ref.invalidate(characterProvider);
  ref.invalidate(growthProvider);
}
```

**進捗**:
- [ ] logout() メソッド実装
- [ ] provider reset 処理
- [ ] テスト

---

#### 3. 選択肢ランダム配置
**現状**: 正解が2番目・3番目に偏っている  
**対応**: ビルド時にシャッフル

**修正ファイル**:
```
lib/models/quest_model.dart
lib/data/stage_data.dart
```

**実装内容**:
```dart
class QuizQuestion {
  final String id;
  final List<String> choices;
  final int correctIndex;
  
  // ランダム化メソッド
  QuizQuestion randomizeChoices() {
    final shuffled = [...choices];
    shuffled.shuffle();
    final newCorrectIndex = shuffled.indexOf(choices[correctIndex]);
    
    return QuizQuestion(
      id: id,
      choices: shuffled,
      correctIndex: newCorrectIndex,
      // ... other fields
    );
  }
}

// stage_data.dart で適用
List<QuizQuestion> questions = [...].map((q) => q.randomizeChoices()).toList();
```

**進捗**:
- [ ] randomizeChoices() メソッド追加
- [ ] stage_data で適用
- [ ] テスト

---

## ✨ Phase 2: 機能改善（Week 2-3）🔄 実装中

### 優先タスク完了状況

#### 1. ホーム画面にガイドセクション追加 ✅
**状態**: 完了  
**実装内容**: 
- math_guide_screen.dart / math_guide_widgets.dart 実装済み
- ホーム画面に算数ガイドセクション表示
- 学年別ガイド機能実装済み

**関連PR**: 既実装

---

#### 2. 漢字にふりがなを追加 🔄 進行中
**状態**: 段階的実装中（4年生完了）
**実装内容**:
- ✅ FuriganaText widget 実装済み (furigana_text.dart)
- ✅ quest_screen で問題文・選択肢に FuriganaText 適用（PR #35）
- ✅ stage_data 4年生向け問題に {kanji|furigana} マークアップ追加（PR #38）
- ⏳ 5-6年生向け問題に追加予定

**関連PR**: 
- #35: quest_screen FuriganaText 実装 ✅ マージ済み
- #38: stage_data 4年生向けふりがん追加 🔄 審査中

---

#### 3. ステージ倍増（54 → 108） ✅
**状態**: 完了  
**実装内容**:
- ✅ 109 ステージ実装済み（計画の 108 を上回る）
- ✅ 672 問題実装済み（計画の 600+ を達成）
- 各学年 9→18 ステージで大幅拡張完了

**関連PR**: 既実装

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

## 📋 次のステップ（Phase 3 計画）

### 優先タスク
1. **5-6年生向けふりがん追加**
   - 文章題に漢字が多く含まれるため優先度高
   - stage_data 拡張（度、周囲、{面積|めんせき}等）

2. **説明文（explanation）の充実**
   - 現在は一部のみふりがん対応
   - 低学年向けに簡潔化・ふりがん増強

3. **ユーザー体験改善**
   - 広告最適化
   - インターフェース調整

---

## 🚀 リリースチェックリスト（v2.1用）

### コード品質
- [ ] lint エラーなし (`flutter analyze`)
- [ ] 全テスト合格
- [ ] バグ修正3件 完了

### デバイステスト
- [ ] Android 6.0 テスト
- [ ] Android 12+ テスト
- [ ] 画面サイズ別テスト（phone/tablet）

### Google Play準備
- [ ] プライバシーポリシー最新化
- [ ] スクリーンショット準備
- [ ] リリースノート記入

---

## 📝 Notes

- **推奨エディタ**: VS Code + Flutter extension
- **デバッグ**: `flutter logs` でリアルタイム出力確認
- **ホットリロード**: `r` (デバッグ時)
- **再ビルド**: `R` (デバッグ時)

---

**次のステップ**: Phase 2 ふりがん対応完了予定 → Phase 3 へ 🚀

