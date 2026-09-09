#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自動ふりがな追加スクリプト
説明文（explanation）に「数（かず）」形式でふりがなを追加
"""

import re
import os

# 教育数学用語とふりがなの辞書
KANJI_FURIGANA_DICT = {
    # 数値
    '数': 'かず',
    '個': 'こ',
    '本': 'ほん',
    '枚': 'まい',
    '台': 'だい',
    '人': 'にん',

    # 計算
    '計算': 'けいさん',
    '足し': 'たし',
    '引き': 'ひき',
    '掛け': 'かけ',
    '割り': 'わり',
    '倍': 'ばい',
    '半': 'はん',
    '余り': 'あまり',

    # 図形
    '図形': 'ずけい',
    '三角形': 'さんかくけい',
    '四角形': 'しかくけい',
    '正方形': 'せいほうけい',
    '長方形': 'ちょうほうけい',
    '円': 'えん',
    '球': 'きゅう',
    '立方体': 'りっぽうたい',
    '直方体': 'ちょくほうたい',
    '角': 'かく',
    '辺': 'へん',
    '頂点': 'ちょうてん',
    '面': 'めん',
    '周': 'しゅう',
    '周囲': 'しゅうい',
    '面積': 'めんせき',
    '体積': 'たいせき',
    '高さ': 'たかさ',
    '幅': 'はば',
    '奥': 'おく',
    '底面': 'ていめん',
    '側面': 'そくめん',

    # 分数
    '分数': 'ぶんすう',
    '分子': 'ぶんし',
    '分母': 'ぶんぼ',
    '通分': 'つうぶん',
    '約分': 'やくぶん',

    # 小数
    '小数': 'しょうすう',
    '小数点': 'しょうすうてん',

    # 単位
    '単位': 'たんい',
    '㎝': 'せんちめーとる',
    '㎜': 'みりめーとる',
    '㎞': 'きろめーとる',
    '㏄': 'しーしー',
    '㍑': 'りっとる',
    '㎏': 'きろぐらむ',
    'グラム': 'ぐらむ',
    'メートル': 'めーとる',
    '時': 'じ',
    '分': 'ぶん',
    '秒': 'びょう',
    '時間': 'じかん',

    # その他
    '問題': 'もんだい',
    '答え': 'こたえ',
    '式': 'しき',
    '和': 'わ',
    '差': 'さ',
    '積': 'せき',
    '商': 'しょう',
    '順序': 'じゅんじょ',
    '関係': 'かんけい',
    '等しい': 'ひとしい',
    '異なる': 'ことなる',
    '大きい': 'おおきい',
    '小さい': 'ちいさい',
    '多い': 'おおい',
    '少ない': 'すくない',
}

def has_furigana(text):
    """テキストに既にふりがながあるか確認"""
    # {kanji|furigana} または 数（かず） 形式を確認
    return bool(re.search(r'\{[^}]+\|[^}]+\}', text)) or bool(re.search(r'[ぁ-ん]（[ぁ-ん]+）', text))

def add_furigana_to_text(text):
    """テキストにふりがなを追加（既存形式を優先）"""
    if has_furigana(text):
        return text  # 既に含まれている場合はスキップ

    # 辞書から長い単語順に処理（より長い一致を優先）
    sorted_dict = sorted(KANJI_FURIGANA_DICT.items(), key=lambda x: len(x[0]), reverse=True)

    result = text
    for kanji, furigana in sorted_dict:
        # 単語を探して置換（既に処理済み部分を避ける）
        # 単語境界を考慮した置換
        pattern = kanji + r'(?!（)'  # 後ろに（がない場合のみ
        if re.search(pattern, result):
            result = re.sub(pattern, f'{kanji}（{furigana}）', result, count=1)

    return result

def process_stage_data(input_file, output_file):
    """stage_data.dart を処理してふりがなを追加"""

    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # explanation フィールドを抽出して処理
    # 正規表現でexplanation: '...' を探す
    def replace_explanation(match):
        prefix = match.group(1)  # explanation: '
        text = match.group(2)    # 実際のテキスト
        suffix = match.group(3)  # '

        if has_furigana(text):
            return match.group(0)  # 既にふりがながある場合はそのまま

        new_text = add_furigana_to_text(text)
        return f"{prefix}{new_text}{suffix}"

    # explanation: '...' パターンに対応
    pattern = r"(explanation:\s*['\"])(.*?)(['\"])"
    new_content = re.sub(pattern, replace_explanation, content, flags=re.DOTALL)

    # ファイルに書き込み
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"✅ 処理完了: {output_file}")

if __name__ == '__main__':
    input_file = '/home/user/sansu-kore/lib/data/stage_data.dart'
    output_file = '/home/user/sansu-kore/lib/data/stage_data.dart'

    process_stage_data(input_file, output_file)
    print("✅ ふりがな自動追加完了！")
