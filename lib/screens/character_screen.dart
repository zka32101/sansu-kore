import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show CharacterCollectionPage;
import '../data/sansu_characters.dart';
import '../providers/progress_provider.dart';

/// 算数コレ版キャラクター図鑑。
/// 表示ロジックはすべて [CharacterCollectionPage] に委譲する。
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalStages =
        ref.watch(progressProvider).clearedStageIds.length;
    return CharacterCollectionPage(
      characters: kSansuCharacters,
      totalStagesCleared: totalStages,
    );
  }
}
