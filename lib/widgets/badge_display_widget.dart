import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// バッジ表示用の再利用可能ウィジェット集

/// 新規バッジ獲得時のポップアップ表示
class NewBadgeDialog extends StatefulWidget {
  final List<BadgeModel> badges;
  final VoidCallback onClose;

  const NewBadgeDialog({
    required this.badges,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  State<NewBadgeDialog> createState() => _NewBadgeDialogState();
}

class _NewBadgeDialogState extends State<NewBadgeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // タイトル
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.orange, Colors.yellow],
                ).createShader(bounds),
                child: Text(
                  'おめでとう！',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '新しいバッジを獲得しました',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              SizedBox(height: 20),

              // バッジグリッド
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: widget.badges.length,
                itemBuilder: (context, index) {
                  return _BadgeCard(badge: widget.badges[index]);
                },
              ),

              SizedBox(height: 24),

              // クローズボタン
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onClose();
                },
                icon: Icon(Icons.check),
                label: Text('了解'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 単一バッジカード
class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge.emoji, style: TextStyle(fontSize: 32)),
          SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

/// バッジ一覧表示（カテゴリ分類）
class BadgeCollectionView extends StatelessWidget {
  final List<EarnedBadge> earnedBadges;
  final List<BadgeModel> allAvailableBadges;

  const BadgeCollectionView({
    required this.earnedBadges,
    required this.allAvailableBadges,
    Key? key,
  }) : super(key: key);

  Map<BadgeCategory, List<BadgeModel>> _groupByCategory() {
    final grouped = <BadgeCategory, List<BadgeModel>>{};
    for (final badge in allAvailableBadges) {
      grouped.putIfAbsent(badge.category, () => []).add(badge);
    }
    return grouped;
  }

  String _categoryTitle(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.streak:
        return '🔥 ストリーク';
      case BadgeCategory.content1:
        return '📚 学習量';
      case BadgeCategory.content2:
        return '🎯 内容2';
      case BadgeCategory.score:
        return '⭐ 正解率';
      case BadgeCategory.special:
        return '✨ スペシャル';
      default:
        return 'その他';
    }
  }

  bool _hasEarnedBadge(String badgeId) {
    return earnedBadges.any((e) => e.badge.id == badgeId);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory();

    return ListView(
      children: grouped.entries.map((entry) {
        final category = entry.key;
        final badges = entry.value;

        return ExpansionTile(
          title: Text(
            _categoryTitle(category),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '${badges.where((b) => _hasEarnedBadge(b.id)).length} / ${badges.length}',
            style: TextStyle(color: Colors.grey),
          ),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                final isEarned = _hasEarnedBadge(badge.id);

                return _BadgeCollectionCard(
                  badge: badge,
                  isEarned: isEarned,
                  onTap: () {
                    _showBadgeDetail(context, badge, isEarned);
                  },
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    BadgeModel badge,
    bool isEarned,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(fontSize: 64),
              ),
              SizedBox(height: 12),
              Text(
                badge.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isEarned ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEarned ? '✓ 獲得済み' : '🔒 未獲得',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isEarned ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// バッジコレクション用カード（獲得/未獲得状態）
class _BadgeCollectionCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;
  final VoidCallback? onTap;

  const _BadgeCollectionCard({
    required this.badge,
    required this.isEarned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isEarned
              ? LinearGradient(
                  colors: [Colors.amber[100]!, Colors.yellow[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[200]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isEarned
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isEarned ? Colors.amber : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // バッジアイコン
            Center(
              child: Opacity(
                opacity: isEarned ? 1.0 : 0.5,
                child: Text(badge.emoji, style: TextStyle(fontSize: 32)),
              ),
            ),

            // タイトル
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                ),
                child: Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isEarned ? Colors.black87 : Colors.grey[700],
                  ),
                ),
              ),
            ),

            // 未獲得時のロックアイコン
            if (!isEarned)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// バッジプログレスバー（特定バッジの進捗表示）
class BadgeProgressBar extends StatelessWidget {
  final BadgeModel badge;
  final int currentProgress;

  const BadgeProgressBar({
    required this.badge,
    required this.currentProgress,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = (currentProgress / badge.requiredCount).clamp(0.0, 1.0);
    final isComplete = currentProgress >= badge.requiredCount;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // バッジアイコン
          Text(badge.emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),

          // 詳細
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$currentProgress / ${badge.requiredCount}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // ステータス
          if (isComplete)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '達成！',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
