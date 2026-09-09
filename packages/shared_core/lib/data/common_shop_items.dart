import '../models/character_data.dart';

/// 全アプリ共通のショップアイテムカタログ（背景テーマ4種 + フレーム4種）。
///
/// 各アプリの `_myExchangeItems`（[CoinShopPage.exchangeItems]）に
/// `...kCommonShopItems` のように展開して混ぜ込んで使う想定。
/// 価格は各アプリのバッジ・キャラ育成のコスト感（30〜500コイン）に
/// 合わせて設定している。
const List<AppShopItem> kCommonShopItems = [
  // ── 背景テーマ ──────────────────────────────────────────────────────
  AppShopItem(
    id: 'theme_sunny',
    emoji: '☀️',
    name: 'サニーテーマ',
    description: '晴れた日の黄色い背景にきりかえるよ',
    category: '背景',
    coinCost: 60,
    kind: ShopItemKind.theme,
    assetPath: 'packages/shared_core/assets/shop/theme_sunny.svg',
    themeData: {
      'colors': ['#FFE082', '#FFB300'],
    },
  ),
  AppShopItem(
    id: 'theme_ocean',
    emoji: '🌊',
    name: 'オーシャンテーマ',
    description: '青い海をイメージした背景にきりかえるよ',
    category: '背景',
    coinCost: 60,
    kind: ShopItemKind.theme,
    assetPath: 'packages/shared_core/assets/shop/theme_ocean.svg',
    themeData: {
      'colors': ['#81D4FA', '#0277BD'],
    },
  ),
  AppShopItem(
    id: 'theme_forest',
    emoji: '🌲',
    name: 'フォレストテーマ',
    description: '緑あふれる森の背景にきりかえるよ',
    category: '背景',
    coinCost: 60,
    kind: ShopItemKind.theme,
    assetPath: 'packages/shared_core/assets/shop/theme_forest.svg',
    themeData: {
      'colors': ['#AED581', '#2E7D32'],
    },
  ),
  AppShopItem(
    id: 'theme_night',
    emoji: '🌙',
    name: 'ナイトテーマ',
    description: '星空がきれいな夜の背景にきりかえるよ',
    category: '背景',
    coinCost: 80,
    kind: ShopItemKind.theme,
    assetPath: 'packages/shared_core/assets/shop/theme_night.svg',
    themeData: {
      'colors': ['#4A148C', '#0D0630'],
    },
  ),

  // ── プロフィールフレーム ──────────────────────────────────────────────
  AppShopItem(
    id: 'frame_gold',
    emoji: '🥇',
    name: 'ゴールドフレーム',
    description: 'アイコンのまわりを金色のわくでかざるよ',
    category: 'フレーム',
    coinCost: 150,
    kind: ShopItemKind.frame,
    assetPath: 'packages/shared_core/assets/shop/frame_gold.svg',
  ),
  AppShopItem(
    id: 'frame_silver',
    emoji: '🥈',
    name: 'シルバーフレーム',
    description: 'アイコンのまわりを銀色のわくでかざるよ',
    category: 'フレーム',
    coinCost: 100,
    kind: ShopItemKind.frame,
    assetPath: 'packages/shared_core/assets/shop/frame_silver.svg',
  ),
  AppShopItem(
    id: 'frame_ribbon',
    emoji: '🎀',
    name: 'リボンフレーム',
    description: 'かわいいリボンつきのわくでかざるよ',
    category: 'フレーム',
    coinCost: 90,
    kind: ShopItemKind.frame,
    assetPath: 'packages/shared_core/assets/shop/frame_ribbon.svg',
  ),
  AppShopItem(
    id: 'frame_star',
    emoji: '⭐',
    name: 'スターフレーム',
    description: '星がきらめく特別なわくでかざるよ',
    category: 'フレーム',
    coinCost: 120,
    kind: ShopItemKind.frame,
    assetPath: 'packages/shared_core/assets/shop/frame_star.svg',
  ),
];
