import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character_data.dart';
import '../providers/character_state_provider.dart';
import '../theme/app_theme_base.dart';

/// 全教科共通のキャラクター図鑑ページ。
///
/// 使い方:
/// ```dart
/// class CharacterScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return CharacterCollectionPage(
///       characters: kMySubjectCharacters,
///       totalStagesCleared: ref.watch(progressProvider).clearedStageIds.length,
///     );
///   }
/// }
/// ```
class CharacterCollectionPage extends ConsumerStatefulWidget {
  final List<BaseCharacter> characters;
  final int totalStagesCleared;

  const CharacterCollectionPage({
    super.key,
    required this.characters,
    required this.totalStagesCleared,
  });

  @override
  ConsumerState<CharacterCollectionPage> createState() =>
      _CharacterCollectionPageState();
}

class _CharacterCollectionPageState
    extends ConsumerState<CharacterCollectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(characterStateProvider.notifier)
          .checkUnlocks(widget.totalStagesCleared);
    });
  }

  @override
  void didUpdateWidget(CharacterCollectionPage old) {
    super.didUpdateWidget(old);
    if (old.totalStagesCleared != widget.totalStagesCleared) {
      ref
          .read(characterStateProvider.notifier)
          .checkUnlocks(widget.totalStagesCleared);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final charStates = ref.watch(characterStateProvider);

    final unlocked = widget.characters
        .where((c) => charStates[c.id]?.isUnlocked ?? false)
        .toList();
    final locked = widget.characters
        .where((c) => !(charStates[c.id]?.isUnlocked ?? false))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatBar(
              primary: primary,
              unlocked: unlocked.length,
              total: widget.characters.length,
              stagesCleared: widget.totalStagesCleared,
            ),
            const SizedBox(height: 20),
            if (unlocked.isNotEmpty) ...[
              _SectionLabel(
                  text: 'ゲット済みキャラ (${unlocked.length}体)', icon: '✅'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: unlocked.length,
                itemBuilder: (ctx, i) {
                  final c = unlocked[i];
                  return _CharacterCard(
                    character: c,
                    state: charStates[c.id] ??
                        const CharacterState(isUnlocked: true),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            if (locked.isNotEmpty) ...[
              _SectionLabel(
                  text: 'ロック中のキャラ (${locked.length}体)', icon: '🔒'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: locked.length,
                itemBuilder: (ctx, i) => _LockedCard(
                  character: locked[i],
                  currentStages: widget.totalStagesCleared,
                ),
              ),
            ],
            if (charStates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat bar ─────────────────────────────────────────────────────────────

class _StatBar extends StatelessWidget {
  final Color primary;
  final int unlocked, total, stagesCleared;

  const _StatBar({
    required this.primary,
    required this.unlocked,
    required this.total,
    required this.stagesCleared,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? unlocked / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withAlpha(30), primary.withAlpha(10)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withAlpha(60)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'コレクション', value: '$unlocked / $total体'),
              _StatItem(label: 'クリアステージ', value: '$stagesCleared'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: kTextMuted)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text, icon;
  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
      ],
    );
  }
}

// ── Unlocked card ─────────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final BaseCharacter character;
  final CharacterState state;

  const _CharacterCard({required this.character, required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: state.hasSparkle
              ? Border.all(color: Colors.amber.shade400, width: 2)
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                if (character.imageAssetForLevel(state.level) != null)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.asset(
                        character.imageAssetForLevel(state.level)!,
                        fit: BoxFit.contain),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(character.emoji,
                        style: const TextStyle(fontSize: 34)),
                  ),
                if (state.hasSparkle)
                  const Text('✨', style: TextStyle(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 4),
            Text(character.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: kTextDark),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(state.levelLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: state.isMaxLevel
                        ? Colors.amber.shade700
                        : kTextMuted,
                    fontWeight: state.isMaxLevel
                        ? FontWeight.bold
                        : FontWeight.normal)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: i < state.level
                        ? Colors.amber.shade400
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CharacterDetailSheet(
          character: character, state: state),
    );
  }
}

class _CharacterDetailSheet extends StatelessWidget {
  final BaseCharacter character;
  final CharacterState state;

  const _CharacterDetailSheet(
      {required this.character, required this.state});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  if (character.imageAssetForLevel(state.level) != null)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                          character.imageAssetForLevel(state.level)!,
                          fit: BoxFit.contain),
                    )
                  else
                    Text(character.emoji,
                        style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 8),
                  Text(character.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('担当：${character.subject}',
                      style: const TextStyle(
                          color: kTextMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        5,
                        (i) => Container(
                          width: 16,
                          height: 8,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i < state.level
                                ? Colors.amber
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(state.levelLabel,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: state.isMaxLevel
                                  ? Colors.amber.shade700
                                  : primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Unlocked features
            if (state.hasExpressions)
              _FeatureChip(text: '表情3種 解放済み', icon: '😊'),
            if (state.hasPoses)
              _FeatureChip(text: 'ポーズ3種 解放済み', icon: '🙌'),
            if (state.hasSparkle)
              _FeatureChip(text: 'きらきらエフェクト 解放済み', icon: '✨'),
            if (state.hasExpressions || state.hasPoses || state.hasSparkle)
              const SizedBox(height: 12),
            // Backstory
            if (state.hasBackstory) ...[
              const Text('📖 バックストーリー',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text(character.backstory,
                  style: const TextStyle(
                      fontSize: 13, height: 1.7, color: kTextDark)),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('Lv.4 でバックストーリーが解放されるよ！',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (state.hasStampCoupon)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Text('🎁', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('LINEスタンプ無料引換券をゲット済み！',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (!state.isMaxLevel)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/shop');
                  },
                  icon: const Icon(Icons.upgrade, size: 18),
                  label: Text(
                      'ショップでLv.${state.level + 1}に育てる'
                      '（${state.nextLevelCost}コイン）'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String text, icon;
  const _FeatureChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: kAccentGreen,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Locked card ───────────────────────────────────────────────────────────

class _LockedCard extends StatelessWidget {
  final BaseCharacter character;
  final int currentStages;

  const _LockedCard(
      {required this.character, required this.currentStages});

  @override
  Widget build(BuildContext context) {
    final remaining = character.unlockAt - currentStages;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: Colors.grey.shade200, shape: BoxShape.circle),
            child:
                const Icon(Icons.lock_outline, color: Colors.grey, size: 22),
          ),
          const SizedBox(height: 6),
          const Text('???',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 2),
          Text('あと$remainingステージ',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
