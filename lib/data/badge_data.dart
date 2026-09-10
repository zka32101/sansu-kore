import 'package:shared_core/shared_core.dart';

// 小学コレ！算数のバッジ定義
// content1 = 算数正解数, content2 = 未使用（sansu-koreでは全問primary）
// streak はログイン連続日数・学習連続日数の両方に対応
const allSansuBadges = [
  BadgeModel(
    id: 'streak_3',
    title: '3日連続！',
    description: '3日連続で学習した',
    emoji: '🔥',
    category: BadgeCategory.streak,
    requiredCount: 3,
  ),
  BadgeModel(
    id: 'streak_7',
    title: '7日連続！',
    description: '1週間毎日学習した',
    emoji: '⚡',
    category: BadgeCategory.streak,
    requiredCount: 7,
  ),
  BadgeModel(
    id: 'streak_30',
    title: '継続力マスター',
    description: '30日連続で学習した',
    emoji: '🏆',
    category: BadgeCategory.streak,
    requiredCount: 30,
  ),
  BadgeModel(
    id: 'daily_7',
    title: '1週間皆勤！',
    description: '7日連続ログインした',
    emoji: '📅',
    category: BadgeCategory.streak,
    requiredCount: 7,
  ),
  BadgeModel(
    id: 'daily_30',
    title: '月間皆勤！',
    description: '30日連続ログインした',
    emoji: '🗓️',
    category: BadgeCategory.streak,
    requiredCount: 30,
  ),
  BadgeModel(
    id: 'math_first',
    title: 'はじめての算数',
    description: '算数クイズを初めてクリア',
    emoji: '➕',
    category: BadgeCategory.content1,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'math_50',
    title: '計算名人',
    description: '算数問題を50問正解',
    emoji: '🔢',
    category: BadgeCategory.content1,
    requiredCount: 50,
  ),
  BadgeModel(
    id: 'math_100',
    title: '計算博士',
    description: '算数問題を100問正解',
    emoji: '🎓',
    category: BadgeCategory.content1,
    requiredCount: 100,
  ),
  BadgeModel(
    id: 'perfect_score',
    title: '満点！',
    description: 'ステージで全問正解した',
    emoji: '⭐',
    category: BadgeCategory.score,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'perfect_3',
    title: '3回満点！',
    description: '3回満点を取った',
    emoji: '🌟',
    category: BadgeCategory.score,
    requiredCount: 3,
  ),
  BadgeModel(
    id: 'stage_5',
    title: 'ステージ5達成',
    description: 'ステージ5をクリアした',
    emoji: '🚀',
    category: BadgeCategory.special,
    requiredCount: 5,
  ),
  BadgeModel(
    id: 'stage_10',
    title: 'ステージ10達成',
    description: 'ステージ10をクリアした',
    emoji: '👑',
    category: BadgeCategory.special,
    requiredCount: 10,
  ),
  BadgeModel(
    id: 'stage_20',
    title: '算数マスター',
    description: 'ステージ20をクリアした',
    emoji: '💎',
    category: BadgeCategory.special,
    requiredCount: 20,
  ),
  BadgeModel(
    id: 'stage_30',
    title: '算数エキスパート',
    description: 'ステージ30をクリアした',
    emoji: '🌈',
    category: BadgeCategory.special,
    requiredCount: 30,
  ),
  BadgeModel(
    id: 'stage_50',
    title: '算数チャンピオン',
    description: 'ステージ50をクリアした',
    emoji: '🏅',
    category: BadgeCategory.special,
    requiredCount: 50,
  ),
  BadgeModel(
    id: 'stage_92',
    title: '算数コンプリート！',
    description: '全92ステージをクリアした',
    emoji: '🎊',
    category: BadgeCategory.special,
    requiredCount: 92,
  ),
  BadgeModel(
    id: 'math_200',
    title: '計算の達人',
    description: '算数問題を200問正解',
    emoji: '🧠',
    category: BadgeCategory.content1,
    requiredCount: 200,
  ),
  BadgeModel(
    id: 'math_300',
    title: '計算の鬼',
    description: '算数問題を300問正解',
    emoji: '👹',
    category: BadgeCategory.content1,
    requiredCount: 300,
  ),
  BadgeModel(
    id: 'math_500',
    title: '算数の神様',
    description: '算数問題を500問正解',
    emoji: '⚡',
    category: BadgeCategory.content1,
    requiredCount: 500,
  ),
  BadgeModel(
    id: 'weekly_challenge_1',
    title: 'チャレンジャー',
    description: 'ウィークリーチャレンジ1週完走',
    emoji: '🏆',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'weekly_challenge_4',
    title: '継続の鬼',
    description: 'ウィークリーチャレンジ4週連続完走',
    emoji: '👹',
    category: BadgeCategory.special,
    requiredCount: 4,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // A. デイリーストリーク強化（3個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'streak_1',
    title: '学習スタート',
    description: '1日学習を開始した',
    emoji: '🔥',
    category: BadgeCategory.streak,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'streak_14',
    title: '2週間の鍛錬',
    description: '14日連続で学習した',
    emoji: '🔥',
    category: BadgeCategory.streak,
    requiredCount: 14,
  ),
  BadgeModel(
    id: 'streak_100',
    title: '百日の修行',
    description: '100日連続で学習した（究極目標）',
    emoji: '🔥',
    category: BadgeCategory.streak,
    requiredCount: 100,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // B. ランキング/競争要素（3個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'ranking_top100',
    title: 'トップ100',
    description: 'グローバルランキング Top 100に入った',
    emoji: '🏆',
    category: BadgeCategory.special,
    requiredCount: 100,
  ),
  BadgeModel(
    id: 'ranking_top10',
    title: 'トップ10',
    description: 'グローバルランキング Top 10に入った',
    emoji: '🥈',
    category: BadgeCategory.special,
    requiredCount: 10,
  ),
  BadgeModel(
    id: 'weekly_ranking_win',
    title: '週間チャンピオン',
    description: '週間ランキング1位になった',
    emoji: '🥇',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // C. キャラクター育成（3個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'character_levelup_3',
    title: 'キャラクターLv.3',
    description: 'キャラを Lv.3 に育成した',
    emoji: '⭐',
    category: BadgeCategory.character,
    requiredCount: 3,
  ),
  BadgeModel(
    id: 'character_levelup_5',
    title: 'キャラクターLv.MAX',
    description: 'キャラを Lv.5（MAX）に育成した',
    emoji: '⭐',
    category: BadgeCategory.character,
    requiredCount: 5,
  ),
  BadgeModel(
    id: 'character_max_all',
    title: '全キャラMAX育成',
    description: '全キャラを Lv.5に育成した（究極）',
    emoji: '⭐',
    category: BadgeCategory.character,
    requiredCount: 10,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // D. マスタリー/達成（8個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'grade_complete_1',
    title: '1年生マスター',
    description: '小学1年 全ステージをクリアした',
    emoji: '🎓',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'grade_complete_2',
    title: '2年生マスター',
    description: '小学2年 全ステージをクリアした',
    emoji: '🎓',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'grade_complete_3',
    title: '3年生マスター',
    description: '小学3年 全ステージをクリアした',
    emoji: '🎓',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'grade_complete_4',
    title: '4年生マスター',
    description: '小学4年 全ステージをクリアした',
    emoji: '🎓',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'grade_complete_5',
    title: '5年生マスター',
    description: '小学5年 全ステージをクリアした',
    emoji: '🎓',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'grade_complete_6',
    title: '6年生マスター',
    description: '小学6年 全ステージをクリアした',
    emoji: '🎓',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'stage_perfect_all',
    title: '全92ステージ満点',
    description: '全92ステージを満点でクリアした（究極）',
    emoji: '🎯',
    category: BadgeCategory.special,
    requiredCount: 92,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // E. 拡張正解数バッジ（4個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'math_1000',
    title: '千問突破',
    description: '算数問題を1000問正解',
    emoji: '🧠',
    category: BadgeCategory.content1,
    requiredCount: 1000,
  ),
  BadgeModel(
    id: 'perfect_10',
    title: '10回満点',
    description: '満点を10回取った',
    emoji: '🌟',
    category: BadgeCategory.score,
    requiredCount: 10,
  ),
  BadgeModel(
    id: 'perfect_50',
    title: '50回満点',
    description: '満点を50回取った',
    emoji: '💫',
    category: BadgeCategory.score,
    requiredCount: 50,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // F. スピード/効率バッジ（3個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'speed_clear',
    title: 'ライトニング',
    description: 'ステージを30秒以内にクリアした',
    emoji: '⚡',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'accuracy_90',
    title: '高精度操作',
    description: '正解率90%以上を10ステージキープ',
    emoji: '🎯',
    category: BadgeCategory.score,
    requiredCount: 10,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // G. コレクション/多様性（3個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'badge_collector_10',
    title: 'バッジコレクター',
    description: 'バッジを10個集めた',
    emoji: '🏅',
    category: BadgeCategory.special,
    requiredCount: 10,
  ),
  BadgeModel(
    id: 'badge_collector_20',
    title: 'バッジハンター',
    description: 'バッジを20個集めた',
    emoji: '🏅',
    category: BadgeCategory.special,
    requiredCount: 20,
  ),
  BadgeModel(
    id: 'badge_collector_30',
    title: 'バッジマスター',
    description: 'バッジを30個集めた',
    emoji: '🏅',
    category: BadgeCategory.special,
    requiredCount: 30,
  ),

  // ════════════════════════════════════════════════════════════════════════════════════
  // H. ソーシャル/シェア（2個）
  // ════════════════════════════════════════════════════════════════════════════════════
  BadgeModel(
    id: 'social_share',
    title: 'シェアリスト',
    description: 'スコアを友達とシェアした',
    emoji: '📱',
    category: BadgeCategory.special,
    requiredCount: 1,
  ),
  BadgeModel(
    id: 'friend_invite',
    title: 'リクルーター',
    description: '友達を3人招待した',
    emoji: '👥',
    category: BadgeCategory.special,
    requiredCount: 3,
  ),
];
