import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/character_data.dart';
import '../providers/character_state_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/equipped_items_provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme_base.dart';
import 'coin_balance_widget.dart';

/// [ShopItemKind.emoji] 以外（テーマ・フレーム・アクセサリ）は
/// 購入後に「装着する」概念を持つアイテムとして扱う。
bool _isEquippable(AppShopItem item) => item.kind != ShopItemKind.emoji;

String _currentSeason() {
  final m = DateTime.now().month;
  if (m >= 3 && m <= 5) return 'spring';
  if (m >= 6 && m <= 8) return 'summer';
  if (m >= 9 && m <= 11) return 'autumn';
  return 'winter';
}

/// 全教科共通のコインショップページ（3タブ）。
///
/// 使い方:
/// ```dart
/// class ShopScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return CoinShopPage(
///       characters: kMyCharacters,
///       exchangeItems: _myExchangeItems,
///       seasonalItems: _mySeasonalItems,
///     );
///   }
/// }
/// ```
class CoinShopPage extends StatelessWidget {
  final List<BaseCharacter> characters;
  final List<AppShopItem> exchangeItems;
  final Map<String, List<AppShopItem>> seasonalItems;

  const CoinShopPage({
    super.key,
    required this.characters,
    required this.exchangeItems,
    required this.seasonalItems,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Row(
            children: [
              Text('コレショップ'),
              Spacer(),
              CoinBalanceWidget(),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'キャラ育成'),
              Tab(icon: Icon(Icons.store, size: 18), text: '交換所'),
              Tab(icon: Icon(Icons.event, size: 18), text: '期間限定'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CharacterLevelUpTab(characters: characters),
            _ExchangeTab(items: exchangeItems),
            _SeasonalTab(seasonalItems: seasonalItems),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: キャラ育成 ────────────────────────────────────────────────────

class _CharacterLevelUpTab extends ConsumerWidget {
  final List<BaseCharacter> characters;

  const _CharacterLevelUpTab({required this.characters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charStates = ref.watch(characterStateProvider);
    final coins = ref.watch(coinProvider).totalCoins;

    final unlocked = characters
        .where((c) => charStates[c.id]?.isUnlocked ?? false)
        .toList();

    if (charStates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (unlocked.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📖', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('まだキャラクターがいないよ',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextDark)),
              const SizedBox(height: 8),
              const Text('クイズをといてキャラクターをゲットしよう！',
                  style: TextStyle(color: kTextMuted, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/learn'),
                child: const Text('学習をはじめる'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Text(
            '🪙 コインでキャラクターを育てよう！\n'
            'Lv.MAX になるとLINEスタンプ無料引換券がもらえるよ✨',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: unlocked.length,
          itemBuilder: (ctx, i) {
            final c = unlocked[i];
            final state =
                charStates[c.id] ?? const CharacterState(isUnlocked: true);
            return _LevelUpCard(
                character: c, state: state, currentCoins: coins);
          },
        ),
      ],
    );
  }
}

class _LevelUpCard extends ConsumerWidget {
  final BaseCharacter character;
  final CharacterState state;
  final int currentCoins;

  const _LevelUpCard(
      {required this.character,
      required this.state,
      required this.currentCoins});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final nextLevel = state.level + 1;
    final cost = state.nextLevelCost;
    final canAfford = cost != null && currentCoins >= cost;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: state.hasSparkle
            ? BorderSide(color: Colors.amber.shade400, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(character.emoji,
                        style: const TextStyle(fontSize: 40))),
                if (state.hasSparkle)
                  const Text('✨', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(character.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kTextDark),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Container(
                  width: 12,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i < state.level
                        ? Colors.amber
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(state.levelLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: state.isMaxLevel
                        ? Colors.amber.shade700
                        : kTextMuted,
                    fontWeight: state.isMaxLevel
                        ? FontWeight.bold
                        : FontWeight.normal)),
            const Spacer(),
            if (state.isMaxLevel)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('✨ MAX達成！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canAfford
                      ? () => _confirmLevelUp(
                          context, ref, primary, nextLevel, cost!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canAfford ? primary : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(cost != null ? '$cost でLv.$nextLevel' : '',
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLevelUp(BuildContext context, WidgetRef ref,
      Color primary, int nextLevel, int cost) async {
    final featureDesc = kLevelUpFeatureDesc[nextLevel] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${character.name} をLv.$nextLevel にする？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('$cost コイン消費',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            Text(featureDesc,
                style: const TextStyle(
                    color: kAccentGreen, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('やめる')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary, foregroundColor: Colors.white),
              child: const Text('レベルアップ！')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final err =
        await ref.read(characterStateProvider.notifier).levelUp(character.id);
    if (!context.mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: kAccentRed));
    } else {
      final isMax = nextLevel >= 5;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: isMax
              ? const Text('🎉 MAX達成！')
              : Text('🎊 Lv.$nextLevel になった！'),
          content: Text(isMax
              ? '${character.name} がMAXレベルになりました！\nLINEスタンプ無料引換券をゲット！🎁'
              : featureDesc),
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white),
                child: const Text('やった！')),
          ],
        ),
      );
    }
  }
}

// ── Tab 2: 確定交換所 ─────────────────────────────────────────────────────

class _ExchangeTab extends ConsumerWidget {
  final List<AppShopItem> items;

  const _ExchangeTab({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(inventoryProvider);
    final coins = ref.watch(coinProvider).totalCoins;

    final categories = <String, List<AppShopItem>>{};
    for (final item in items) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Text(
            '🛒 コインと好きなアイテムを交換しよう！\n一度購入したアイテムは所持済みになるよ。',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in categories.entries) ...[
          _CategoryHeader(category: entry.key),
          const SizedBox(height: 8),
          ...entry.value.map((item) => ShopItemTile(
                item: item,
                isOwned: owned.contains(item.id),
                currentCoins: coins,
                onPurchase: () => _purchase(context, ref, item),
              )),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _purchase(
      BuildContext context, WidgetRef ref, AppShopItem item) async {
    final owned = ref.read(inventoryProvider);
    if (owned.contains(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('すでに所持しているアイテムです')));
      return;
    }
    final primary = Theme.of(context).colorScheme.primary;
    final confirmed = await _showPurchaseDialog(context, primary, item);
    if (confirmed != true || !context.mounted) return;

    final err =
        await ref.read(inventoryProvider.notifier).purchase(item.id, item.coinCost);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: kAccentRed));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${item.name} をゲット！'),
          backgroundColor: kAccentGreen));
    }
  }
}

// ── Tab 3: 期間限定 ───────────────────────────────────────────────────────

class _SeasonalTab extends ConsumerWidget {
  final Map<String, List<AppShopItem>> seasonalItems;

  const _SeasonalTab({required this.seasonalItems});

  static const _seasonLabel = {
    'spring': '🌸 春の限定アイテム',
    'summer': '🌞 夏の限定アイテム',
    'autumn': '🍁 秋の限定アイテム',
    'winter': '❄️ 冬の限定アイテム',
  };

  List<Color> _gradient(String season) => switch (season) {
        'spring' => [Colors.pink.shade300, Colors.pink.shade100],
        'summer' => [Colors.blue.shade400, Colors.cyan.shade300],
        'autumn' => [Colors.orange.shade600, Colors.amber.shade400],
        _ => [Colors.blue.shade700, Colors.lightBlue.shade300],
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = _currentSeason();
    final items = seasonalItems[season] ?? [];
    final owned = ref.watch(inventoryProvider);
    final coins = ref.watch(coinProvider).totalCoins;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: _gradient(season),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(_seasonLabel[season] ?? '限定アイテム',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text('今だけの特別アイテムだよ！',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('このシーズンのアイテムはまだないよ',
                  style: TextStyle(color: kTextMuted)),
            ),
          )
        else
          ...items.map((item) => ShopItemTile(
                item: item,
                isOwned: owned.contains(item.id),
                currentCoins: coins,
                onPurchase: () => _purchase(context, ref, item),
              )),
      ],
    );
  }

  Future<void> _purchase(
      BuildContext context, WidgetRef ref, AppShopItem item) async {
    final owned = ref.read(inventoryProvider);
    if (owned.contains(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('すでに所持しているアイテムです')));
      return;
    }
    final primary = Theme.of(context).colorScheme.primary;
    final confirmed = await _showPurchaseDialog(context, primary, item);
    if (confirmed != true || !context.mounted) return;

    final err =
        await ref.read(inventoryProvider.notifier).purchase(item.id, item.coinCost);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: kAccentRed));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${item.name} をゲット！'),
          backgroundColor: kAccentGreen));
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────

Future<bool?> _showPurchaseDialog(
    BuildContext context, Color primary, AppShopItem item) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${item.emoji} ${item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.description),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('${item.coinCost} コイン',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('やめる')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: primary, foregroundColor: Colors.white),
            child: const Text('こうかん！')),
      ],
    ),
  );
}

/// カテゴリヘッダー（交換所タブ用）
class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  static const _icons = {
    '帽子': '🎩', '背景': '🖼️', 'BGM': '🎵', 'フレーム': '🖼',
    'スペシャル': '⭐', '期間限定': '⏰',
  };

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(_icons[category] ?? '•', style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(category,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
    ]);
  }
}

/// ショップアイテムの1行タイル（交換所・期間限定共通）
class ShopItemTile extends ConsumerWidget {
  final AppShopItem item;
  final bool isOwned;
  final int currentCoins;
  final VoidCallback onPurchase;

  const ShopItemTile({
    super.key,
    required this.item,
    required this.isOwned,
    required this.currentCoins,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final canAfford = currentCoins >= item.coinCost;
    final equippable = isOwned && _isEquippable(item);
    final equipped = equippable
        ? ref.watch(equippedItemsProvider
            .select((s) => s.equippedByCategory[item.category] == item.id))
        : false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: equipped
            ? BorderSide(color: primary, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          padding: item.assetPath != null ? const EdgeInsets.all(4) : null,
          decoration: BoxDecoration(
            color: isOwned
                ? kAccentGreen.withAlpha(20)
                : primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.assetPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SvgPicture.asset(item.assetPath!, fit: BoxFit.cover),
                )
              : Center(
                  child:
                      Text(item.emoji, style: const TextStyle(fontSize: 22))),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            if (equipped) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 15, color: primary),
            ],
          ],
        ),
        subtitle: Text(item.description,
            style: const TextStyle(fontSize: 11, color: kTextMuted)),
        trailing: isOwned
            ? (equippable
                ? _EquipButton(item: item, equipped: equipped)
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kAccentGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kAccentGreen.withAlpha(60)),
                    ),
                    child: const Text('所持済み',
                        style: TextStyle(
                            fontSize: 11,
                            color: kAccentGreen,
                            fontWeight: FontWeight.bold)),
                  ))
            : ElevatedButton(
                onPressed: canAfford ? onPurchase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canAfford ? primary : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(72, 34),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 10)),
                    Text('${item.coinCost}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

/// 所持済み・装着可能なアイテムの「装着する / 解除する」ボタン。
class _EquipButton extends ConsumerWidget {
  final AppShopItem item;
  final bool equipped;

  const _EquipButton({required this.item, required this.equipped});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    return ElevatedButton(
      onPressed: () {
        final notifier = ref.read(equippedItemsProvider.notifier);
        if (equipped) {
          notifier.unequip(item.category);
        } else {
          notifier.equip(item.category, item.id);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: equipped ? Colors.grey.shade300 : primary,
        foregroundColor: equipped ? kTextDark : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(72, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(equipped ? '解除する' : '装着する',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
