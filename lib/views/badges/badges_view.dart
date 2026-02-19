import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final String category;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
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
  List<String> _categories = ['すべて'];

  // 英語カテゴリ → 日本語ラベルの対応
  String _displayCategory(String raw) {
    final key = (raw.isEmpty ? 'その他' : raw).toLowerCase();
    switch (key) {
      case 'basic':
        return '基本';
      case 'advanced':
        return '上級';
      case 'event':
        return 'イベント';
      case 'shop':
      case 'store':
        return '店舗';
      case 'social':
        return 'ソーシャル';
      case 'seasonal':
        return '季節';
      case 'rare':
        return 'レア';
      case 'challenge':
        return 'チャレンジ';
      case 'other':
      case 'others':
        return 'その他';
      default:
        // 既に日本語の場合や未定義はそのまま
        return raw.isEmpty ? '未分類' : raw;
    }
  }

  // Firestore からバッジを購読
  Stream<List<BadgeModel>> _badgesStream() {
    return FirebaseFirestore.instance
        .collection('badges')
        .orderBy('requiredValue', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BadgeModel(
          id: (data['badgeId'] ?? doc.id).toString(),
          name: (data['name'] ?? '').toString(),
          description: (data['description'] ?? '').toString(),
          // iconUrl または iconPath を許容
          iconPath: (data['imageUrl'] ?? data['iconUrl'] ?? data['iconPath'] ?? '').toString(),
          category: (data['category'] ?? '未分類').toString(),
        );
      }).toList();
    });
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
          return _buildBadgesContent(context);
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

  Widget _buildBadgesContent(BuildContext context) {
    return StreamBuilder<List<BadgeModel>>(
      stream: _badgesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('バッジ取得に失敗しました: ${snapshot.error}'));
        }

        final badges = snapshot.data ?? [];
        final categories = <String>{'すべて'}
          ..addAll(
            badges.map((b) => _displayCategory(b.category)).where((c) => c.isNotEmpty),
          );

        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = 'すべて';
        }
        _categories = categories.toList();

        final filteredBadges = _selectedCategory == 'すべて'
            ? badges
            : badges.where((b) => _displayCategory(b.category) == _selectedCategory).toList();

        return _buildBadgeGrid(filteredBadges);
      },
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

  Widget _buildBadgeGrid(List<BadgeModel> badges) {
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: _getBadgeIcon(
                badge.iconPath,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // バッジ名
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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

    // URL or アセットの両方に対応
    final isUrl = iconPath.startsWith('http');
    if (isUrl) {
      return Image.network(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.star,
            size: size,
            color: const Color(0xFFFF6B35),
          );
        },
      );
    } else {
      return Image.asset(
        'assets/images/badges/$iconPath',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // デバッグ用にエラーをコンソールに出力
          print('画像読み込みエラー: assets/images/badges/$iconPath - $error');
          return Icon(
            Icons.star,
            size: size,
            color: const Color(0xFFFF6B35),
          );
        },
      );
    }
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge) {
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
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(150),
                ),
                child: _getBadgeIcon(
                  badge.iconPath,
                  size: 144,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              badge.category,
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
            badge.description,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: SingleChildScrollView(
          child: Column(
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
