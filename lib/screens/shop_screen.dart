import 'package:shared_core/shared_core.dart';
import '../data/sansu_characters.dart';

// ── 算数コレ 交換所アイテム ──────────────────────────────────────────────
// 2026-07: 交換所・期間限定タブはいったん非表示（ラインナップ見直し中）。
// 復活する際は _exchangeItems / _seasonalItems をそのまま CoinShopPage に渡す。

// ignore: unused_element
const _exchangeItemsArchive = [
  AppShopItem(id: 'hat_number',    emoji: '🔢', name: '数字帽子',
      description: 'キャラに数字の帽子をかぶせる', category: '帽子', coinCost: 80),
  AppShopItem(id: 'hat_abacus',    emoji: '🧮', name: 'そろばん帽',
      description: '計算名人のそろばん帽子', category: '帽子', coinCost: 100),
  AppShopItem(id: 'hat_graduate',  emoji: '🎓', name: '算数博士帽',
      description: '算数マスターの証の博士帽', category: '帽子', coinCost: 120),
  AppShopItem(id: 'bg_chalkboard', emoji: '📋', name: '黒板の背景',
      description: '計算式が書かれた黒板背景', category: '背景', coinCost: 200),
  AppShopItem(id: 'bg_space_math', emoji: '🌌', name: '数式宇宙',
      description: '数式が浮かぶ宇宙の背景', category: '背景', coinCost: 200),
  AppShopItem(id: 'bg_geometry',   emoji: '📐', name: '幾何学模様',
      description: '美しい図形が並ぶ背景', category: '背景', coinCost: 200),
  AppShopItem(id: 'bgm_focus',     emoji: '🎵', name: '集中BGM',
      description: '計算に集中できる静かなBGM', category: 'BGM', coinCost: 150),
  AppShopItem(id: 'bgm_exciting',  emoji: '🎶', name: 'わくわくBGM',
      description: '算数がたのしくなるBGM', category: 'BGM', coinCost: 150),
  AppShopItem(id: 'frame_calc',    emoji: '✖️', name: '計算記号フレーム',
      description: '+−×÷が並ぶフレーム', category: 'フレーム', coinCost: 200),
  AppShopItem(id: 'frame_gold',    emoji: '🏆', name: 'ゴールドフレーム',
      description: '算数王者の金色フレーム', category: 'フレーム', coinCost: 250),
  AppShopItem(id: 'stamp_coupon_sansu', emoji: '🎁',
      name: 'LINEスタンプ無料引換券',
      description: '算数コレキャラのスタンプ1セットが無料！',
      category: 'スペシャル', coinCost: 1000),
];

// ── 算数コレ 期間限定アイテム ─────────────────────────────────────────────

// ignore: unused_element
const _seasonalItemsArchive = <String, List<AppShopItem>>{
  'spring': [
    AppShopItem(id: 'bg_spring_math', emoji: '🌸', name: '春の数式背景',
        description: '桜と数式が舞う春の背景', category: '期間限定', coinCost: 300),
    AppShopItem(id: 'frame_entrance_sansu', emoji: '🎒', name: '新学期フレーム',
        description: '新年度の算数スタートを飾る', category: '期間限定', coinCost: 200),
    AppShopItem(id: 'hat_flower_num', emoji: '🌷', name: '数字お花帽子',
        description: '春の花に数字が咲いている', category: '期間限定', coinCost: 150),
  ],
  'summer': [
    AppShopItem(id: 'bg_summer_calc', emoji: '🎆', name: '花火カウント',
        description: '花火が数字でカウントダウン', category: '期間限定', coinCost: 300),
    AppShopItem(id: 'hat_sun_number', emoji: '☀️', name: '太陽数字帽',
        description: '夏の太陽に数字が輝く', category: '期間限定', coinCost: 100),
    AppShopItem(id: 'effect_bubbles', emoji: '🫧', name: '数字バブル',
        description: '数字が入った泡が浮かぶ', category: '期間限定', coinCost: 250),
  ],
  'autumn': [
    AppShopItem(id: 'bg_autumn_graph', emoji: '🍁', name: '秋のグラフ背景',
        description: '紅葉が棒グラフ状に並ぶ', category: '期間限定', coinCost: 300),
    AppShopItem(id: 'frame_study',   emoji: '📚', name: '読書の秋フレーム',
        description: '算数と読書の秋フレーム', category: '期間限定', coinCost: 200),
    AppShopItem(id: 'hat_mushroom_num', emoji: '🍄', name: '数字キノコ帽',
        description: '秋の森のキノコに数字が', category: '期間限定', coinCost: 120),
  ],
  'winter': [
    AppShopItem(id: 'bg_snow_formula', emoji: '❄️', name: '雪の数式背景',
        description: '雪の結晶に数式が輝く', category: '期間限定', coinCost: 300),
    AppShopItem(id: 'hat_santa_calc', emoji: '🎅', name: 'サンタ計算帽',
        description: 'サンタの帽子に計算式が', category: '期間限定', coinCost: 150),
    AppShopItem(id: 'frame_newyear_sansu', emoji: '🎍', name: '算数お正月フレーム',
        description: '新年の抱負は算数！', category: '期間限定', coinCost: 200),
    AppShopItem(id: 'effect_snow_num', emoji: '🌨️', name: '数字の雪',
        description: '数字が雪のように降ってくる', category: '期間限定', coinCost: 200),
  ],
};

// ── ShopScreen ────────────────────────────────────────────────────────────
//
// 算数コレ版ショップ。
//
// 以前はここに「キャラクター購入」タブ（コインでキャラを解放する独自実装）が
// あったが、以下の理由で廃止した:
//   - キャラの解放条件は「キャラ画面」（characterStateProvider / unlockAt）が
//     唯一の正とし、ステージクリア数のみで解放する方針に統一（購入と二重管理しない）
//   - 旧実装の characterPrices は実在しないキャラID（gosanko 等）を参照しており、
//     実際の kSansuCharacters（ichiko 等）とは一致せず機能していなかった
//   - CoinShopPage（shared_core）の「キャラ育成」タブは characterStateProvider を
//     直接参照するレベルアップ機能が既に実装済みで、キャラ画面と自然に連動する
//
// そのため ShopScreen は CoinShopPage をそのまま返すだけでよい
// （旧実装は CoinShopPage を独自の2タブ Scaffold でラップしており、
//   CoinShopPage 自身も Scaffold+AppBar+TabBar を持つため二重表示になっていた）。
class ShopScreen extends CoinShopPage {
  const ShopScreen({super.key})
      : super(
          characters: kSansuCharacters,
          // 共通カタログ（背景テーマ4種 + プロフィールフレーム4種）を交換所に追加。
          exchangeItems: kCommonShopItems,
          seasonalItems: const {},
        );
}
