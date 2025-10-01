import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String category;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.isUnlocked,
    this.unlockedAt,
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
  
  // バッジのロック状態を管理するMap
  final Map<String, bool> _badgeUnlockStates = {};

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
          isUnlocked: false,
          unlockedAt: null,
          category: (data['category'] ?? '未分類').toString(),
        );
      }).toList();
    });
  }

  // Firestore: ユーザーの取得済みバッジを購読
  Stream<Map<String, Map<String, dynamic>>> _userBadgesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({});
    }
    return FirebaseFirestore.instance
        .collection('user_badges')
        .doc(user.uid)
        .collection('badges')
        .snapshots()
        .map((snapshot) {
      final Map<String, Map<String, dynamic>> result = {};
      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
      return result;
    });
  }

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
      body: StreamBuilder<List<BadgeModel>>(
        stream: _badgesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('バッジ取得に失敗しました: ${snapshot.error}'));
          }

          final badges = snapshot.data ?? [];
          // ユーザーバッジを購読して統合
          return StreamBuilder<Map<String, Map<String, dynamic>>>(
            stream: _userBadgesStream(),
            builder: (context, userSnapshot) {
              final userBadgesMap = userSnapshot.data ?? {};

              // カテゴリをデータから動的生成
              final categories = <String>{'すべて'}
                ..addAll(badges.map((b) => b.category).where((c) => c.isNotEmpty));

              if (!categories.contains(_selectedCategory)) {
                _selectedCategory = 'すべて';
              }
              _categories = categories.toList();

              final filteredBadges = _selectedCategory == 'すべて'
                  ? badges
                  : badges.where((b) => b.category == _selectedCategory).toList();

              return Column(
                children: [
                  _buildCategoryFilter(_categories),
                  Expanded(child: _buildBadgeGrid(filteredBadges, userBadgesMap)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
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

  Widget _buildBadgeGrid(List<BadgeModel> badges, Map<String, Map<String, dynamic>> userBadgesMap) {
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
          return _buildBadgeCard(badge, userBadgesMap: userBadgesMap);
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, {required Map<String, Map<String, dynamic>> userBadgesMap}) {
    // 現在のロック状態を取得（デフォルトはbadge.isUnlocked）
    final isUnlockedFromDB = userBadgesMap.containsKey(badge.id);
    final isCurrentlyUnlocked = _badgeUnlockStates[badge.id] ?? isUnlockedFromDB;

    // 表示用アイコン（アンロック済みは user_badges の iconUrl/iconPath を優先）
    String displayIconPath = badge.iconPath;
    if (isCurrentlyUnlocked) {
      final data = userBadgesMap[badge.id];
      final unlockedIcon = (data?['imageUrl'] ?? data?['iconUrl'] ?? data?['iconPath'])?.toString();
      if (unlockedIcon != null && unlockedIcon.isNotEmpty) {
        displayIconPath = unlockedIcon;
      }
    }
    
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
                color: isCurrentlyUnlocked 
                    ? const Color(0xFFFF6B35).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: isCurrentlyUnlocked
                    ? null
                    : Border.all(
                        color: Colors.grey,
                        width: 2,
                      ),
              ),
              child: _getBadgeIcon(
                displayIconPath,
                isUnlocked: isCurrentlyUnlocked,
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
                color: isCurrentlyUnlocked ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // ロック状態
            if (!isCurrentlyUnlocked)
              const Icon(
                Icons.lock,
                size: 12,
                color: Colors.grey,
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

  Widget _getBadgeIcon(String iconPath, {bool isUnlocked = true, double size = 24}) {
    // アンロック状態に応じて表示を切り替え
    if (!isUnlocked) {
      return Icon(
        Icons.lock,
        size: size,
        color: Colors.grey,
      );
    }
    
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
            color: isUnlocked ? const Color(0xFFFF6B35) : Colors.grey,
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
            color: isUnlocked ? const Color(0xFFFF6B35) : Colors.grey,
          );
        },
      );
    }
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge) {
    // 現在のロック状態を取得
    final isCurrentlyUnlocked = _badgeUnlockStates[badge.id] ?? badge.isUnlocked;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    color: isCurrentlyUnlocked 
                        ? const Color(0xFFFF6B35).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(150),
                    border: isCurrentlyUnlocked
                        ? null
                        : Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                  ),
                  child: _getBadgeIcon(
                    badge.iconPath,
                    isUnlocked: isCurrentlyUnlocked,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // テストボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      // リクエスト: アンロック押下で user_badges から削除
                      await _lockBadge(badge);
                      setState(() {
                        _badgeUnlockStates[badge.id] = false;
                      });
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('アンロック'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _lockBadge(badge);
                      setState(() {
                        _badgeUnlockStates[badge.id] = false;
                      });
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text('ロック'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 現在の状態表示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentlyUnlocked 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentlyUnlocked 
                        ? Colors.green
                        : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCurrentlyUnlocked ? Icons.check_circle : Icons.lock,
                      size: 20,
                      color: isCurrentlyUnlocked ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCurrentlyUnlocked ? 'アンロック済み' : 'ロック中',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCurrentlyUnlocked ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
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

  // 以降、バッジ一覧は Firestore から取得するためローカル生成は不要

  // Firestore: バッジを付与（user_badges/{userId}/badges/{badgeId}）
  Future<void> _unlockBadge(BadgeModel badge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です')),
        );
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      final ref = firestore
          .collection('user_badges')
          .doc(user.uid)
          .collection('badges')
          .doc(badge.id);

      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'userId': user.uid,
          'badgeId': badge.id,
          'unlockedAt': FieldValue.serverTimestamp(),
          'progress': 1,
          'requiredValue': 1,
          'isNew': true,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バッジを保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  // Firestore: バッジを削除（ロックに戻す）user_badges/{userId}/badges/{badgeId}
  Future<void> _lockBadge(BadgeModel badge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です')),
        );
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      final ref = firestore
          .collection('user_badges')
          .doc(user.uid)
          .collection('badges')
          .doc(badge.id);
      await ref.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バッジを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }
}
