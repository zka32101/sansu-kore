import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sansu_kore/data/sansu_characters.dart';
import 'package:sansu_kore/providers/character_level_provider.dart';

/// Flutter の assets 宣言はサブフォルダを再帰しない。
/// キャラ画像が未同梱になる宣言漏れを検出する。
Set<String> _declaredDirs() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final dirs = <String>{};
  var inAssets = false;
  for (final raw in lines) {
    final l = raw.trimRight();
    if (l.trim() == 'assets:') {
      inAssets = true;
      continue;
    }
    if (!inAssets) continue;
    final m = RegExp(r'^\s+-\s+(\S+)\s*$').firstMatch(l);
    if (m != null) {
      dirs.add(m.group(1)!);
    } else if (l.trim().isNotEmpty && !l.trim().startsWith('#')) {
      break;
    }
  }
  return dirs;
}

bool _isCovered(String asset, Set<String> declared) {
  if (declared.contains(asset)) return true;
  final dir = asset.substring(0, asset.lastIndexOf('/') + 1);
  return declared.contains(dir);
}

void main() {
  final declared = _declaredDirs();

  test('kSansuCharacters の imageAsset は実在し、assets 宣言の直下にある', () {
    for (final c in kSansuCharacters) {
      final path = c.imageAsset;
      if (path == null) continue;
      expect(File(path).existsSync(), isTrue, reason: '実ファイルなし: $path');
      expect(_isCovered(path, declared), isTrue, reason: 'pubspec 未宣言: $path');
    }
  });

  test('getCharacterImagePath が組み立てる全 Lv パスが実在し宣言済み', () {
    final ids = <String>{
      ...kSansuCharacters.map((c) => c.id),
      'fukuju',
    };
    for (final id in ids) {
      for (var lv = 1; lv <= 5; lv++) {
        final path = getCharacterImagePath(id, lv);
        expect(File(path).existsSync(), isTrue, reason: '実ファイルなし: $path');
        expect(_isCovered(path, declared), isTrue,
            reason: 'pubspec 未宣言: $path');
      }
    }
  });

  test('assets/characters 配下の全 png が宣言ディレクトリ直下にある', () {
    final files = Directory('assets/characters')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
    for (final p in files) {
      expect(_isCovered(p, declared), isTrue, reason: 'pubspec 未宣言: $p');
    }
  });
}
