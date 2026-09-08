# 算数コレ！(Sansu Kore) 

**小学生向けの楽しい算数学習アプリ** 🎮📚

## 概要

「算数コレ!」は小学1年生から6年生を対象とした、ゲーム感覚で算数を学べるFlutterアプリです。ステージクリア、ガイド学習、キャラクター成長など、複合的な学習体験を提供します。

## ✨ 主な機能

### 📚 学習ガイド
- 8つの数学概念（足し算、引き算、かけ算、割り算、分数、小数、図形、文章問題）
- 学年別の段階的な説明
- ふりがな対応で読みやすい
- 進捗追跡と完了バッジ

### 🎮 ステージシステム
- **108ステージ** 学年別に展開
- **672問以上** の問題
- 各ステージ3～5問で短時間クリア可能
- 選択肢のランダム配置

### 🎨 学習体験
- ふりがな（ルビ）対応で低学年も安心
- VFX（ビジュアルエフェクト）で達成感UP
- サウンドエフェクト付き
- キャラクター育成システム

### 🏆 進捗管理
- バッジ・アチーブメントシステム
- ランキング機能
- 日替わりチャレンジ
- 紹介システムでコイン獲得

## 🏗️ アーキテクチャ

### 技術スタック
- **フレームワーク**: Flutter 3.11.5+
- **状態管理**: Riverpod (StateNotifier, FutureProvider)
- **永続化**: SharedPreferences + Firebase
- **認証**: Firebase Authentication
- **言語**: Dart

### 層構造
```
Presentation (Screens & Widgets)
         ↓
State Management (Providers)
         ↓
Data Layer (Models & Repositories)
```

## 📦 ビルド・デプロイ

### 🚀 自動ビルド（GitHub Actions）

このプロジェクトは GitHub Actions による自動ビルド・デプロイパイプラインに対応しています。

**詳細ガイド**: [`yourwish/docs/build-ci-cd-guide.md`](https://github.com/zka32101/yourwish/blob/master/docs/build-ci-cd-guide.md)

#### トリガー条件
- ✅ `claude/**` ブランチへの push
- ✅ Pull Request (main/develop)
- ✅ 手動実行 (workflow_dispatch)
- ✅ 週1回スケジュール実行

#### 自動実行内容
1. **コード分析・テスト** - `flutter analyze`, `flutter test`
2. **Android ビルド** - APK/AAB 生成
3. **iOS ビルド** - IPA 生成 (unsigned)
4. **ビルドサマリー** - 結果集計

#### ワークフローファイル
- `.github/workflows/build-apk.yml` - 基本ビルド
- テンプレート: [`yourwish/.github/workflows/build-template.yml`](https://github.com/zka32101/yourwish/blob/master/.github/workflows/build-template.yml)

---

### 💻 ローカルビルド

#### 前提条件
- Flutter 3.11.5以上
- Dart 3.1.0以上
- Android SDK (APIレベル21以上)
- Java 17

#### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/org-zka32101/sansu-kore.git
cd sansu-kore

# 依存パッケージをインストール
flutter pub get

# コード生成実行（Firebase等）
flutter pub run build_runner build
```

#### 実行

```bash
# デバッグモード
flutter run

# リリースビルド
flutter build apk --release
flutter build appbundle --release
```

---

### 📚 SessionStart Hook（自動初期化）

Claude Code セッション起動時に自動的に以下を実行：
- `flutter pub get` - 依存関係インストール
- `flutter analyze` - コード分析

設定ファイル: `.claude/hooks/session-start.sh`

---

### 🧪 build-and-test スキル（6観点テスト）

```bash
/build-and-test sansu-kore
```

**テスト観点**:
1. 起動テスト
2. 接続テスト
3. 課金画面
4. 認証フロー
5. 広告表示
6. クラッシュ検出

## 📊 プロジェクト構造

```
lib/
├── models/           # データモデル（MathGuide, Furigana等）
├── providers/        # Riverpod状態管理（27個以上）
├── screens/          # 画面UI（28画面）
├── widgets/          # 再利用ウィジェット（10個）
├── data/             # 定数データ（ステージ、ガイド、バッジ等）
├── theme/            # テーマ・スタイリング
└── main.dart         # アプリケーション起点
```

## 🎯 Priority 4-6実装内容

### Priority 4: ホーム画面ガイドセクション ✅
- `MathGuideCarousel` で学年別ガイド表示
- 進捗追跡とバッジ表示
- ステップバイステップナビゲーション

### Priority 5: ふりがな対応 ✅
- `FuriganaWidget` で漢字上に読み方表示
- `SimpleFuriganaParser` で自動解析（`kanji(かんじ)`形式）
- 43個の教育用語を辞書化
- ガイドとクイズに統合

### Priority 6: ステージ倍増 ✅
- 54 → 108ステージに拡張
- 312 → 672問以上に増加
- 各学年9→18ステージ
- 短時間クリア用に3～5問/ステージ

## 🧪 テスト

```bash
# ユニットテスト
flutter test

# テストカバレッジ
flutter test --coverage
```

テストファイル：
- `test/models/` - モデルテスト
- `test/providers/` - Riverpodプロバイダテスト

## 📱 デバイスサポート

| OS | 最小バージョン | 推奨バージョン |
|----|--------------|------------|
| Android | 5.1 (API 22) | 12.0+ (API 31+) |
| iOS | 11.0+ | 15.0+ |

## 🚀 リリース情報

- **バージョン**: 3.2.0
- **ビルド番号**: 18
- **ステータス**: 本番環境対応

### v3.2.0の変更点
- Priority 4-6実装完了
- ふりがな対応
- ステージ大幅拡張
- ガイドシステム実装

## 📄 ライセンス

© 2026 [org-zka32101]. All rights reserved.

## 👥 コントリビューション

バグ報告・フィーチャーリクエストはGitHub Issuesへ。

## 📞 サポート

問題が発生した場合：
1. [Issues](https://github.com/org-zka32101/sansu-kore/issues)を確認
2. デバッグログを `flutter logs` で確認
3. Issueを作成する場合は詳細な再現手順を記載
