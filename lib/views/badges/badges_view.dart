import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../models/badge_model.dart';
import '../../data/badge_definitions.dart';
import '../../widgets/custom_button.dart';

class BadgesView extends ConsumerStatefulWidget {
  const BadgesView({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgesView> createState() => _BadgesViewState();
}

class _BadgesViewState extends ConsumerState<BadgesView> {
  String _selectedCategory = 'すべて';

  List<String> _buildCategories(List<BadgeModel> badges) {
    final categorySet = <String>{'すべて'};
    for (final badge in badges) {
      categorySet.add(badge.category ?? '未分類');
    }
    return categorySet.toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

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
      body: authState.when(
        data: (user) {
          if (user == null) {
            return _buildAuthRequired(context);
          }
          return _buildBadgesContent(context, user.uid);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildBadgesContent(BuildContext context, String userId) {
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));

    return userBadgesAsync.when(
      data: (userBadges) {
        // 取得済みバッジIDのセット
        final earnedBadgeIds = userBadges.map((ub) => ub.badgeId).toSet();

        // カテゴリフィルター適用（全バッジ定義から）
        final filteredBadges = _selectedCategory == 'すべて'
            ? kBadgeDefinitions
            : kBadgeDefinitions
                .where((b) => (b.category ?? '未分類') == _selectedCategory)
                .toList();

        return _buildBadgeGrid(filteredBadges, earnedBadgeIds);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Text('バッジの読み込みに失敗しました'),
      ),
    );
  }

  Widget _buildAuthRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ログインが必要です',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240,
              child: CustomButton(
                text: 'ログイン',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signin');
                },
                backgroundColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 240,
              child: CustomButton(
                text: '新規アカウント作成',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signup');
                },
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<BadgeModel> badges, Set<String> earnedBadgeIds) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final isEarned = earnedBadgeIds.contains(badge.badgeId);
          return _buildBadgeCard(badge, isEarned: isEarned);
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, {required bool isEarned}) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge, isEarned: isEarned),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? Colors.white : Colors.grey[100],
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isEarned
                    ? const Color(0xFFFF6B35).withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(40),
              ),
              child: isEarned
                  ? _getBadgeIcon(badge.iconUrl, size: 48)
                  : Icon(
                      Icons.help_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              isEarned ? badge.name : '？？？',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.black87 : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBadgeIcon(String iconPath, {double size = 24}) {
    if (iconPath.isEmpty) {
      return Icon(
        Icons.emoji_events,
        size: size,
        color: const Color(0xFFFF6B35),
      );
    }

    return Image.asset(
      'assets/images/badges/$iconPath',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.emoji_events,
          size: size,
          color: const Color(0xFFFF6B35),
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge, {required bool isEarned}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: isEarned
                      ? const Color(0xFFFF6B35).withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(150),
                ),
                child: isEarned
                    ? _getBadgeIcon(badge.iconUrl, size: 144)
                    : Icon(
                        Icons.help_outline,
                        size: 144,
                        color: Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isEarned ? badge.name : '？？？',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              badge.category ?? '未分類',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            isEarned ? badge.description : '条件を達成してバッジを獲得しよう！',
            style: const TextStyle(fontSize: 14),
          ),
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
    final categories = _buildCategories(kBadgeDefinitions);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((category) {
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
}
