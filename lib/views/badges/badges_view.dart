import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int requiredPoints;
  final String category;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.isUnlocked,
    this.unlockedAt,
    required this.requiredPoints,
    required this.category,
  });
}

class BadgesView extends ConsumerStatefulWidget {
  const BadgesView({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgesView> createState() => _BadgesViewState();
}

class _BadgesViewState extends ConsumerState<BadgesView> {
  String _selectedCategory = 'すべて';
  final List<String> _categories = [
    'すべて',
    '初回',
    'ポイント',
    '店舗',
    '友達',
    '特別',
    'イベント',
    '長期',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('バッジ一覧'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // カテゴリフィルター
          _buildCategoryFilter(),
          
          // バッジグリッド
          Expanded(
            child: _buildBadgeGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFFFF6B35).withOpacity(0.2),
              checkmarkColor: const Color(0xFFFF6B35),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeGrid() {
    final badges = _generateSampleBadges();
    final filteredBadges = _selectedCategory == 'すべて'
        ? badges
        : badges.where((badge) => badge.category == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: filteredBadges.length,
        itemBuilder: (context, index) {
          final badge = filteredBadges[index];
          return _buildBadgeCard(badge);
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // バッジアイコン
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badge.isUnlocked 
                    ? const Color(0xFFFF6B35).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: badge.isUnlocked 
                      ? const Color(0xFFFF6B35)
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                _getBadgeIcon(badge.iconPath),
                size: 24,
                color: badge.isUnlocked 
                    ? const Color(0xFFFF6B35)
                    : Colors.grey,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // バッジ名
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // ロック状態
            if (!badge.isUnlocked)
              Text(
                '${badge.requiredPoints}pt',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                ),
              )
            else
              const Icon(
                Icons.check_circle,
                size: 12,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String iconPath) {
    // アイコンパスに基づいてアイコンを返す
    switch (iconPath) {
      case 'first_visit':
        return Icons.place;
      case 'points_100':
        return Icons.monetization_on;
      case 'points_500':
        return Icons.account_balance_wallet;
      case 'points_1000':
        return Icons.diamond;
      case 'store_visit':
        return Icons.store;
      case 'friend_invite':
        return Icons.people;
      case 'special_event':
        return Icons.celebration;
      case 'long_term':
        return Icons.schedule;
      default:
        return Icons.star;
    }
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: badge.isUnlocked 
                    ? const Color(0xFFFF6B35).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: badge.isUnlocked 
                      ? const Color(0xFFFF6B35)
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                _getBadgeIcon(badge.iconPath),
                size: 30,
                color: badge.isUnlocked 
                    ? const Color(0xFFFF6B35)
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    badge.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '必要ポイント: ${badge.requiredPoints}pt',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (badge.isUnlocked && badge.unlockedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '獲得日: ${_formatDate(badge.unlockedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((category) {
            return ListTile(
              title: Text(category),
              leading: Radio<String>(
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  List<BadgeModel> _generateSampleBadges() {
    final badges = <BadgeModel>[];
    final now = DateTime.now();
    
    // 初回バッジ（10個）
    for (int i = 1; i <= 10; i++) {
      badges.add(BadgeModel(
        id: 'first_$i',
        name: '初回訪問$i',
        description: '初めて店舗を訪問しました',
        iconPath: 'first_visit',
        isUnlocked: i <= 3,
        unlockedAt: i <= 3 ? now.subtract(Duration(days: i * 10)) : null,
        requiredPoints: i * 10,
        category: '初回',
      ));
    }
    
    // ポイントバッジ（20個）
    for (int i = 1; i <= 20; i++) {
      final points = i * 50;
      badges.add(BadgeModel(
        id: 'points_$i',
        name: 'ポイント${points}pt',
        description: '${points}ポイントを獲得しました',
        iconPath: 'points_100',
        isUnlocked: i <= 8,
        unlockedAt: i <= 8 ? now.subtract(Duration(days: i * 5)) : null,
        requiredPoints: points,
        category: 'ポイント',
      ));
    }
    
    // 店舗バッジ（15個）
    for (int i = 1; i <= 15; i++) {
      badges.add(BadgeModel(
        id: 'store_$i',
        name: '店舗マスター$i',
        description: '${i}回店舗を訪問しました',
        iconPath: 'store_visit',
        isUnlocked: i <= 5,
        unlockedAt: i <= 5 ? now.subtract(Duration(days: i * 7)) : null,
        requiredPoints: i * 20,
        category: '店舗',
      ));
    }
    
    // 友達バッジ（10個）
    for (int i = 1; i <= 10; i++) {
      badges.add(BadgeModel(
        id: 'friend_$i',
        name: '友達紹介$i',
        description: '${i}人の友達を紹介しました',
        iconPath: 'friend_invite',
        isUnlocked: i <= 2,
        unlockedAt: i <= 2 ? now.subtract(Duration(days: i * 15)) : null,
        requiredPoints: i * 100,
        category: '友達',
      ));
    }
    
    // 特別バッジ（15個）
    for (int i = 1; i <= 15; i++) {
      badges.add(BadgeModel(
        id: 'special_$i',
        name: '特別バッジ$i',
        description: '特別な条件をクリアしました',
        iconPath: 'special_event',
        isUnlocked: i <= 4,
        unlockedAt: i <= 4 ? now.subtract(Duration(days: i * 20)) : null,
        requiredPoints: i * 200,
        category: '特別',
      ));
    }
    
    // イベントバッジ（15個）
    for (int i = 1; i <= 15; i++) {
      badges.add(BadgeModel(
        id: 'event_$i',
        name: 'イベント参加$i',
        description: 'イベントに参加しました',
        iconPath: 'special_event',
        isUnlocked: i <= 3,
        unlockedAt: i <= 3 ? now.subtract(Duration(days: i * 30)) : null,
        requiredPoints: i * 150,
        category: 'イベント',
      ));
    }
    
    // 長期バッジ（15個）
    for (int i = 1; i <= 15; i++) {
      badges.add(BadgeModel(
        id: 'long_$i',
        name: '継続${i}日',
        description: '${i}日間継続してログインしました',
        iconPath: 'long_term',
        isUnlocked: i <= 6,
        unlockedAt: i <= 6 ? now.subtract(Duration(days: i * 50)) : null,
        requiredPoints: i * 300,
        category: '長期',
      ));
    }
    
    return badges;
  }
}
