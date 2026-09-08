/// ふりがな（読み仮名）マッピング
/// 学年別に漢字とその読み方を定義

/// Grade 1（1年生）の漢字
const Map<String, String> grade1Furigana = {
  '算': 'さん',
  '数': 'すう',
  '個': 'こ',
  '本': 'ほん',
  '合': 'あ',
  '残': 'のこ',
  '足': 'た',
  '引': 'ひ',
  '一': 'いち',
  '二': 'に',
  '三': 'さん',
  '四': 'し',
  '五': 'ご',
  '六': 'ろく',
  '七': 'しち',
  '八': 'はち',
  '九': 'きゅう',
  '十': 'じゅう',
  '百': 'ひゃく',
  '千': 'せん',
  '万': 'まん',
};

/// Grade 2（2年生）の漢字
const Map<String, String> grade2Furigana = {
  ...grade1Furigana,
  '乗': 'じょう',
  '掛': 'か',
  '割': 'わ',
  '除': 'じょ',
  '倍': 'ばい',
  '分': 'ぶん',
  '上': 'うえ',
  '下': 'した',
  '左': 'ひだり',
  '右': 'みぎ',
  '前': 'まえ',
  '後': 'うしろ',
  '大': 'おお',
  '小': 'ちい',
  '多': 'おお',
  '少': 'すく',
};

/// Grade 3（3年生）の漢字
const Map<String, String> grade3Furigana = {
  ...grade2Furigana,
  '分数': 'ぶんすう',
  '時': 'とき',
  '間': 'かん',
  '計': 'けい',
  '図': 'ず',
  '形': 'かたち',
  '角': 'かく',
  '辺': 'へん',
  '周': 'しゅう',
  '長': 'なが',
};

/// Grade 4（4年生）の漢字
const Map<String, String> grade4Furigana = {
  ...grade3Furigana,
  '小数': 'しょうすう',
  '点': 'てん',
  '位': 'くらい',
  '面': 'めん',
  '積': 'せき',
  '体': 'たい',
  '平': 'へい',
  '方': 'ほう',
  '地': 'ち',
  '域': 'いき',
  '広': 'ひろ',
  '深': 'ふか',
  '高': 'たか',
};

/// Grade 5（5年生）の漢字
const Map<String, String> grade5Furigana = {
  ...grade4Furigana,
  '通': 'つう',
  '約': 'やく',
  '率': 'りつ',
  '百分': 'ひゃくぶん',
  '比': 'ひ',
  '例': 'れい',
  '対': 'たい',
  '応': 'おう',
  '相': 'あい',
  '等': 'とう',
};

/// Grade 6（6年生）の漢字
const Map<String, String> grade6Furigana = {
  ...grade5Furigana,
  '正': 'せい',
  '負': 'ふ',
  '性': 'せい',
  '文': 'ぶん',
  '字': 'じ',
  '式': 'しき',
  '程': 'てい',
  '確': 'かく',
  '統': 'とう',
  '資': 'し',
  '料': 'りょう',
};

/// 指定された学年のふりがなマップを取得
Map<String, String> getFuriganaForGrade(int grade) {
  return switch (grade) {
    1 => grade1Furigana,
    2 => grade2Furigana,
    3 => grade3Furigana,
    4 => grade4Furigana,
    5 => grade5Furigana,
    6 => grade6Furigana,
    _ => grade1Furigana,
  };
}

/// テキストにふりがなマークアップを自動追加（指定学年用）
/// 例: '算数を勉強する' → '{算|さん}{数|すう}を勉強する'
String addFuriganaForGrade(String text, int grade) {
  final furiganaMap = getFuriganaForGrade(grade);
  String result = text;

  // 長い漢字から順に置換（重複マッチを避ける）
  final entries = furiganaMap.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));

  for (final entry in entries) {
    final kanji = entry.key;
    final furigana = entry.value;

    // すでにマークアップされていない場合のみ置換
    result = result.replaceAll(
      RegExp('(?<!\\{)${RegExp.escape(kanji)}(?!\\|)'),
      '{$kanji|$furigana}',
    );
  }

  return result;
}
