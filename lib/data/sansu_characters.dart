import 'package:shared_core/shared_core.dart';

// 算数コレ 10体のキャラクター（設計書「小学コレシリーズ_キャラクター図鑑＋LINEスタンプ化」準拠）
// unlockAt: clearedStageIds.length の閾値（最大92ステージ）
const List<BaseCharacter> kSansuCharacters = [

  // ── Tier 1（はじめての算数）4体 ──────────────────────────────────
  BaseCharacter(
    id: 'ichiko', name: 'イチコ', emoji: '🔢', tier: 1, unlockAt: 0,
    imageAsset: 'assets/characters/tier1/ichiko/ichiko_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier1/ichiko/ichiko_lv2_normal.png',
      3: 'assets/characters/tier1/ichiko/ichiko_lv3_normal.png',
      4: 'assets/characters/tier1/ichiko/ichiko_lv4_normal.png',
      5: 'assets/characters/tier1/ichiko/ichiko_lv5_normal.png',
    },
    subject: 'たし算',
    backstory: 'イチコは数字の「1」からうまれた算数の妖精。\n'
        '「最初の一歩はいつも勇気がいるけど、一緒に踏み出そう！」\n'
        'が口癖で、たし算が大の得意。数字のことならイチコに聞いてね。\n'
        'みんなが1を覚えるたびに、イチコはとても嬉しそうに笑うんだよ。',
    stampPhrases: [
      'たし算できた！', '1から始めよう', 'イチコと練習！', 'できたよ！',
      '算数すき！', 'ありがとう！', 'また明日ね', '一緒に頑張ろう',
    ],
  ),

  BaseCharacter(
    id: 'niniko', name: 'ニニコ', emoji: '✌️', tier: 1, unlockAt: 3,
    imageAsset: 'assets/characters/tier1/niniko/niniko_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier1/niniko/niniko_lv2_normal.png',
      3: 'assets/characters/tier1/niniko/niniko_lv3_normal.png',
      4: 'assets/characters/tier1/niniko/niniko_lv4_normal.png',
      5: 'assets/characters/tier1/niniko/niniko_lv5_normal.png',
    },
    subject: 'ひき算',
    backstory: '双子の「2」がぴったり寄り添ったのがニニコ。\n'
        '協力することとバランスをとることが大好きで、\n'
        '「2つが並ぶとき、どちらが大きいか見てみよう！」と教えてくれる。\n'
        'ひき算は「どれだけ残るか」を調べる大切な計算だって知ってる。',
    stampPhrases: [
      'ひき算OK！', 'バランスとれた！', 'ニニコと勉強', '残りはいくつ？',
      '2つ並んでる！', 'ありがとう！', 'また来てね', '一緒に考えよう',
    ],
  ),

  BaseCharacter(
    id: 'trai', name: 'トライ', emoji: '🔺', tier: 1, unlockAt: 5,
    imageAsset: 'assets/characters/tier1/trai/trai_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier1/trai/trai_lv2_normal.png',
      3: 'assets/characters/tier1/trai/trai_lv3_normal.png',
      4: 'assets/characters/tier1/trai/trai_lv4_normal.png',
      5: 'assets/characters/tier1/trai/trai_lv5_normal.png',
    },
    subject: 'かけ算',
    backstory: '三角形の頂点から生まれたトライは「安定」の象徴。\n'
        '三角形はどんな形の中でも最も強いって知ってるかな？\n'
        '「かけ算は同じ数をたくさん集める魔法だよ！」と教えてくれる。\n'
        'コツコツ繰り返すことが好きで、九九を全部暗唱できるんだ。',
    stampPhrases: [
      'かけ算できた！', '九九覚えた！', 'トライと一緒に', '何倍だろう？',
      '三角形は強い！', 'ありがとう！', 'また挑戦！', '繰り返しが大切',
    ],
  ),

  BaseCharacter(
    id: 'fouku', name: 'フォーク', emoji: '🍴', tier: 1, unlockAt: 8,
    imageAsset: 'assets/characters/tier1/fouku/fouku_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier1/fouku/fouku_lv2_normal.png',
      3: 'assets/characters/tier1/fouku/fouku_lv3_normal.png',
      4: 'assets/characters/tier1/fouku/fouku_lv4_normal.png',
      5: 'assets/characters/tier1/fouku/fouku_lv5_normal.png',
    },
    subject: 'わり算',
    backstory: '4本の枝に分かれる形をしたフォーク。\n'
        '「分ける」ことと「選ぶ」ことが大好きで、\n'
        'わり算は「みんなに同じ数ずつ配るための計算」だって教えてくれる。\n'
        '食べ物をみんなで公平に分けることが、世界で一番大切だと思ってるよ。',
    stampPhrases: [
      'わり算できた！', '等しく分けた！', 'フォークと計算', 'あまりはいくつ？',
      '公平が大事！', 'ありがとう！', 'また来てね', '一緒に分けよう',
    ],
  ),

  // ── Tier 2（計算の達人）3体 ──────────────────────────────────────
  BaseCharacter(
    id: 'gogo', name: 'ゴーゴ', emoji: '✋', tier: 2, unlockAt: 12,
    imageAsset: 'assets/characters/tier2/gogo/gogo_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier2/gogo/gogo_lv2_normal.png',
      3: 'assets/characters/tier2/gogo/gogo_lv3_normal.png',
      4: 'assets/characters/tier2/gogo/gogo_lv4_normal.png',
      5: 'assets/characters/tier2/gogo/gogo_lv5_normal.png',
    },
    subject: '分数・小数',
    backstory: '手の指5本から生まれたゴーゴは行動派。\n'
        '「数字は整数だけじゃない！分数や小数もあるんだよ！」\n'
        'と興奮して教えてくれる。1を5等分したり、0.1を10個集めたり、\n'
        'いろんな数の形を楽しめるようになるとゴーゴもハイタッチ！',
    stampPhrases: [
      '分数わかった！', '小数もOK！', 'ゴーゴと挑戦', '1より小さい数',
      '5本指の力！', 'ありがとう！', 'ハイタッチ！', '一緒に進もう',
    ],
  ),

  BaseCharacter(
    id: 'multiko', name: 'マルティプル', emoji: '✖️', tier: 2, unlockAt: 18,
    imageAsset: 'assets/characters/tier2/multiko/multiko_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier2/multiko/multiko_lv2_normal.png',
      3: 'assets/characters/tier2/multiko/multiko_lv3_normal.png',
      4: 'assets/characters/tier2/multiko/multiko_lv4_normal.png',
      5: 'assets/characters/tier2/multiko/multiko_lv5_normal.png',
    },
    subject: '大きい数のかけ算',
    backstory: 'かけ算記号「×」が目になった強力なキャラクター。\n'
        '「かけ算はたし算の超スピード版！」が口癖で、\n'
        '2桁×2桁、3桁×2桁の計算も苦にしない。\n'
        '数字が大きくなるほど、マルティプルは嬉しそうになるんだって。',
    stampPhrases: [
      'かけ算マスター！', '計算速い！', 'マルティプルと', '大きな数も平気',
      '×で世界が広がる！', 'ありがとう！', 'また挑戦！', '一緒に計算しよう',
    ],
  ),

  BaseCharacter(
    id: 'divido', name: 'ディバイド', emoji: '➗', tier: 2, unlockAt: 24,
    imageAsset: 'assets/characters/tier2/divido/divido_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier2/divido/divido_lv2_normal.png',
      3: 'assets/characters/tier2/divido/divido_lv3_normal.png',
      4: 'assets/characters/tier2/divido/divido_lv4_normal.png',
      5: 'assets/characters/tier2/divido/divido_lv5_normal.png',
    },
    subject: 'わり算の筆算',
    backstory: '割り算記号「÷」の形をしたディバイドは公平の守護者。\n'
        '「分ける美しさを理解した者だけが、ディバイドと友達になれる」\n'
        'と言われている。難しい筆算のわり算も丁寧に教えてくれるよ。\n'
        '余りがピッタリ0になったとき、一番嬉しそうな顔をするんだ。',
    stampPhrases: [
      'わり算マスター！', '筆算できた！', 'ディバイドと', '余りゼロ！',
      '分けることは美しい', 'ありがとう！', 'また計算しよう', '一緒に学ぼう',
    ],
  ),

  // ── Tier 3（図形と量の世界）2体 ──────────────────────────────────
  BaseCharacter(
    id: 'geome', name: 'ジオメ', emoji: '📐', tier: 3, unlockAt: 32,
    imageAsset: 'assets/characters/tier3/geome/geome_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier3/geome/geome_lv2_normal.png',
      3: 'assets/characters/tier3/geome/geome_lv3_normal.png',
      4: 'assets/characters/tier3/geome/geome_lv4_normal.png',
      5: 'assets/characters/tier3/geome/geome_lv5_normal.png',
    },
    subject: '図形',
    backstory: '幾何学模様とコンパスが融合したジオメは完璧主義者。\n'
        '三角形、四角形、円、立体…あらゆる形を愛している。\n'
        '「図形は数字と芸術が合わさったもの！」と熱く語るジオメの話は\n'
        'いつも面白くて、聞いていると形が好きになってくるよ。',
    stampPhrases: [
      '図形わかった！', 'きれいな形！', 'ジオメと学ぼう', '面積計算OK！',
      '図形は芸術！', 'ありがとう！', 'また描こう', '一緒に考えよう',
    ],
  ),

  BaseCharacter(
    id: 'calcuku', name: 'カルキュ', emoji: '🧮', tier: 3, unlockAt: 40,
    imageAsset: 'assets/characters/tier3/calcuku/calcuku_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier3/calcuku/calcuku_lv2_normal.png',
      3: 'assets/characters/tier3/calcuku/calcuku_lv3_normal.png',
      4: 'assets/characters/tier3/calcuku/calcuku_lv4_normal.png',
      5: 'assets/characters/tier3/calcuku/calcuku_lv5_normal.png',
    },
    subject: '算数総合',
    backstory: '古い計算機とそろばんを背負ったカルキュは算数の賢者。\n'
        '数千年の算数の歴史を知っていて、\n'
        '「計算は人類が積み重ねてきた知恵だよ！」と教えてくれる。\n'
        'どんな難問も笑顔で解くカルキュに出会えるのは、本物の算数好きだけ。',
    stampPhrases: [
      '算数全部OK！', '賢者に近づいた！', 'カルキュと一緒', 'どんな問題も',
      '計算は人類の知恵', 'ありがとう！', 'また挑戦！', '算数の達人！',
    ],
  ),

  // ── Tier 4（伝説の存在）1体 ──────────────────────────────────────
  BaseCharacter(
    id: 'plus_minus', name: 'プラスマイナス', emoji: '⚡', tier: 4, unlockAt: 48,
    imageAsset: 'assets/characters/tier4/plus_minus/plus_minus_lv1_normal.png',
    levelImages: {
      2: 'assets/characters/tier4/plus_minus/plus_minus_lv2_normal.png',
      3: 'assets/characters/tier4/plus_minus/plus_minus_lv3_normal.png',
      4: 'assets/characters/tier4/plus_minus/plus_minus_lv4_normal.png',
      5: 'assets/characters/tier4/plus_minus/plus_minus_lv5_normal.png',
    },
    subject: '算数マスター',
    backstory: '+と−が合体した伝説の存在、プラスマイナス。\n'
        'たし算もひき算も、かけ算もわり算も、図形も、全部マスターした。\n'
        '「調和こそが算数の真髄。足して引いて、かけて割って、\n'
        'それが宇宙の法則なんだよ！」この言葉を聞いた者は、算数の神になれる。',
    stampPhrases: [
      '算数マスター！！', '全制覇した！', '伝説の算数使い', 'どんな計算も',
      '⚡算数の神⚡', 'ありがとう！！', 'また会おう！', 'これが算数の極意',
    ],
  ),
];
