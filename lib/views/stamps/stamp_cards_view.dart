import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';

class StampCardsView extends StatefulWidget {
  const StampCardsView({Key? key, this.showAppBar = true}) : super(key: key);

  final bool showAppBar;

  @override
  State<StampCardsView> createState() => _StampCardsViewState();
}

class _StampCardsViewState extends State<StampCardsView> {
  List<Map<String, dynamic>> _stampCards = [];
  bool _isLoading = true;
  String? _error;
  bool _needsAuth = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _needsAuth = true;
          _stampCards = [];
          _error = null;
          _isLoading = false;
        });
        return;
      }
      _needsAuth = false;
      _loadStampCards();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // スタンプカードデータを読み込む
  Future<void> _loadStampCards() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _needsAuth = false;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _needsAuth = true;
          _isLoading = false;
          _error = null;
        });
        return;
      }

      print('スタンプカードの読み込みを開始...');
      
      // 新しい構造: users/{userId}/stores から直接取得
      final QuerySnapshot userStoresSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .get();

      print('取得したユーザー店舗数: ${userStoresSnapshot.docs.length}');
      
      final List<Map<String, dynamic>> stampCards = [];
      
      for (final userStoreDoc in userStoresSnapshot.docs) {
        final userStoreData = userStoreDoc.data() as Map<String, dynamic>;
        final storeId = userStoreDoc.id;
        
        // 店舗の詳細情報を取得
        final storeDocSnapshot = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
        
        if (!storeDocSnapshot.exists) {
          print('店舗が見つかりません: $storeId');
          continue;
        }
        
        final storeData = storeDocSnapshot.data() as Map<String, dynamic>;
        
        // 店舗がアクティブで承認済みかチェック
        final isActive = storeData['isActive'] as bool? ?? false;
        final isApproved = storeData['isApproved'] as bool? ?? false;
        
        if (!isActive || !isApproved) {
          print('店舗がアクティブでないか承認されていません: $storeId');
          continue;
        }
        
        // ユーザーのスタンプデータを取得
        final stamps = userStoreData['stamps'] as int? ?? 0;
        final lastVisited = userStoreData['lastVisited'];
        final totalSpendingRaw = userStoreData['totalSpending'];
        final totalSpending = (totalSpendingRaw is num) ? totalSpendingRaw.toDouble() : 0.0;
        
        stampCards.add({
          'storeId': storeId,
          'storeName': storeData['name'] ?? '店舗名なし',
          'storeCategory': storeData['category'] ?? 'その他',
          'iconImageUrl': storeData['iconImageUrl'],
          'stamps': stamps,
          'lastVisited': lastVisited,
          'totalSpending': totalSpending,
          'isActive': isActive,
          'isApproved': isApproved,
        });
      }
      
      // スタンプ数が多い順にソート
      stampCards.sort((a, b) => (b['stamps'] as int).compareTo(a['stamps'] as int));
      
      print('読み込んだスタンプカード数: ${stampCards.length}');
      
      if (mounted) {
        setState(() {
          _stampCards = stampCards;
          _isLoading = false;
          _needsAuth = false;
        });
      }
    } catch (e) {
      print('スタンプカードデータの読み込みに失敗しました: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _needsAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (!widget.showAppBar) {
      return Container(
        color: Colors.grey[50],
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('スタンプカード'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStampCards,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_needsAuth) {
      return _buildAuthRequired(context);
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStampCards,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_stampCards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'スタンプカードがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '店舗を訪れてスタンプを集めましょう！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStampCards,
      color: const Color(0xFFFF6B35),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stampCards.length,
        itemBuilder: (context, index) {
          final stampCard = _stampCards[index];
          return _buildStampCard(stampCard);
        },
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

  Widget _buildStampCard(Map<String, dynamic> stampCard) {
    final stamps = stampCard['stamps'] as int;
    final maxStamps = 10; // 最大スタンプ数
    final progress = stamps / maxStamps;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ヘッダー部分
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCategoryColor(stampCard['storeCategory']).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // 店舗アイコン
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(stampCard['storeCategory']).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getCategoryColor(stampCard['storeCategory']).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _buildStoreIcon(stampCard),
                ),
                
                const SizedBox(width: 12),
                
                // 店舗情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stampCard['storeName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(stampCard['storeCategory']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stampCard['storeCategory'],
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(stampCard['storeCategory']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // スタンプ数表示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$stamps/$maxStamps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // スタンプ表示部分
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // プログレスバー
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCategoryColor(stampCard['storeCategory']),
                  ),
                  minHeight: 8,
                ),
                
                const SizedBox(height: 16),
                
                // スタンプグリッド（5x2）
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: maxStamps,
                  itemBuilder: (context, index) {
                    final hasStamp = index < stamps;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: hasStamp 
                            ? _getCategoryColor(stampCard['storeCategory'])
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasStamp 
                              ? _getCategoryColor(stampCard['storeCategory']).withOpacity(0.7)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: hasStamp
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : const Icon(
                                Icons.radio_button_unchecked,
                                color: Colors.grey,
                                size: 20,
                              ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 統計情報
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.location_on,
                      label: '訪問回数',
                      value: '${_calculateVisitCount(stamps)}回',
                    ),
                    _buildStatItem(
                      icon: Icons.monetization_on,
                      label: '総支出',
                      value: '¥${(stampCard['totalSpending'] as double?)?.toStringAsFixed(0) ?? '0'}',
                    ),
                    _buildStatItem(
                      icon: Icons.schedule,
                      label: '最終訪問',
                      value: _formatLastVisited(stampCard['lastVisited']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreIcon(Map<String, dynamic> stampCard) {
    final iconImageUrl = stampCard['iconImageUrl'] as String?;
    final category = stampCard['storeCategory'] as String;
    
    if (iconImageUrl != null && iconImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          iconImageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 25,
            );
          },
        ),
      );
    } else {
      return Icon(
        _getCategoryIcon(category),
        color: _getCategoryColor(category),
        size: 25,
      );
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 訪問回数を計算（スタンプ数から推定）
  int _calculateVisitCount(int stamps) {
    // 1回の訪問で1スタンプ獲得と仮定
    return stamps;
  }

  // 最終訪問日をフォーマット
  String _formatLastVisited(dynamic lastVisited) {
    if (lastVisited == null) return '未訪問';
    
    try {
      final date = lastVisited.toDate();
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) return '今日';
      if (difference == 1) return '昨日';
      if (difference < 7) return '${difference}日前';
      
      return '${date.month}/${date.day}';
    } catch (e) {
      return '不明';
    }
  }

  // カテゴリに応じた色を取得
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'カフェ・喫茶店':
        return const Color(0xFF6F4E37);
      case 'レストラン':
        return const Color(0xFFD32F2F);
      case '居酒屋':
        return const Color(0xFF6D4C41);
      case '和食':
        return const Color(0xFFB71C1C);
      case '日本料理':
        return const Color(0xFF8E0000);
      case '海鮮':
        return const Color(0xFF00695C);
      case '寿司':
        return const Color(0xFF00897B);
      case 'そば':
        return const Color(0xFF5D4037);
      case 'うどん':
        return const Color(0xFF795548);
      case 'うなぎ':
        return const Color(0xFF3E2723);
      case '焼き鳥':
        return const Color(0xFFBF360C);
      case 'とんかつ':
        return const Color(0xFFEF6C00);
      case '串揚げ':
        return const Color(0xFFF57C00);
      case '天ぷら':
        return const Color(0xFFFF8F00);
      case 'お好み焼き':
        return const Color(0xFF9E9D24);
      case 'もんじゃ焼き':
        return const Color(0xFF827717);
      case 'しゃぶしゃぶ':
        return const Color(0xFFAD1457);
      case '鍋':
        return const Color(0xFFC2185B);
      case '焼肉':
        return const Color(0xFFD84315);
      case 'ホルモン':
        return const Color(0xFFBF360C);
      case 'ラーメン':
        return const Color(0xFF7B1FA2);
      case '中華料理':
        return const Color(0xFFB71C1C);
      case '餃子':
        return const Color(0xFF9C27B0);
      case '韓国料理':
        return const Color(0xFF5E35B1);
      case 'タイ料理':
        return const Color(0xFF00838F);
      case 'カレー':
        return const Color(0xFFF9A825);
      case '洋食':
        return const Color(0xFF1976D2);
      case 'フレンチ':
        return const Color(0xFF3F51B5);
      case 'スペイン料理':
        return const Color(0xFFE65100);
      case 'ビストロ':
        return const Color(0xFF5C6BC0);
      case 'パスタ':
        return const Color(0xFF4CAF50);
      case 'ピザ':
        return const Color(0xFF388E3C);
      case 'ステーキ':
        return const Color(0xFFB71C1C);
      case 'ハンバーグ':
        return const Color(0xFF8D6E63);
      case 'ハンバーガー':
        return const Color(0xFF6D4C41);
      case 'ビュッフェ':
        return const Color(0xFF0097A7);
      case '食堂':
        return const Color(0xFF607D8B);
      case 'パン・サンドイッチ':
        return const Color(0xFF8D6E63);
      case 'スイーツ':
        return const Color(0xFFFF80AB);
      case 'ケーキ':
        return const Color(0xFFFF4081);
      case 'タピオカ':
        return const Color(0xFF7E57C2);
      case 'バー・お酒':
        return const Color(0xFF455A64);
      case 'スナック':
        return const Color(0xFF546E7A);
      case '料理旅館':
        return const Color(0xFF4E342E);
      case '沖縄料理':
        return const Color(0xFF00ACC1);
      case 'ショップ':
        return const Color(0xFF1565C0);
      case '美容院':
        return const Color(0xFFEC407A);
      case '薬局':
        return const Color(0xFF43A047);
      case 'コンビニ':
        return const Color(0xFFFF8A65);
      case 'スーパー':
        return const Color(0xFF8BC34A);
      case '書店':
        return const Color(0xFF7E57C2);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // カテゴリに応じたアイコンを取得
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'カフェ・喫茶店':
        return Icons.local_cafe;
      case 'レストラン':
        return Icons.restaurant;
      case '居酒屋':
        return Icons.sports_bar;
      case '和食':
        return Icons.ramen_dining;
      case '日本料理':
        return Icons.set_meal;
      case '海鮮':
        return Icons.set_meal;
      case '寿司':
        return Icons.set_meal;
      case 'そば':
        return Icons.ramen_dining;
      case 'うどん':
        return Icons.ramen_dining;
      case 'うなぎ':
        return Icons.set_meal;
      case '焼き鳥':
        return Icons.outdoor_grill;
      case 'とんかつ':
        return Icons.set_meal;
      case '串揚げ':
        return Icons.outdoor_grill;
      case '天ぷら':
        return Icons.set_meal;
      case 'お好み焼き':
        return Icons.local_dining;
      case 'もんじゃ焼き':
        return Icons.local_dining;
      case 'しゃぶしゃぶ':
        return Icons.soup_kitchen;
      case '鍋':
        return Icons.soup_kitchen;
      case '焼肉':
        return Icons.local_fire_department;
      case 'ホルモン':
        return Icons.local_fire_department;
      case 'ラーメン':
        return Icons.ramen_dining;
      case '中華料理':
        return Icons.restaurant_menu;
      case '餃子':
        return Icons.restaurant_menu;
      case '韓国料理':
        return Icons.restaurant_menu;
      case 'タイ料理':
        return Icons.restaurant_menu;
      case 'カレー':
        return Icons.rice_bowl;
      case '洋食':
        return Icons.dinner_dining;
      case 'フレンチ':
        return Icons.wine_bar;
      case 'スペイン料理':
        return Icons.wine_bar;
      case 'ビストロ':
        return Icons.wine_bar;
      case 'パスタ':
        return Icons.dinner_dining;
      case 'ピザ':
        return Icons.local_pizza;
      case 'ステーキ':
        return Icons.local_fire_department;
      case 'ハンバーグ':
        return Icons.dinner_dining;
      case 'ハンバーガー':
        return Icons.fastfood;
      case 'ビュッフェ':
        return Icons.restaurant;
      case '食堂':
        return Icons.restaurant;
      case 'パン・サンドイッチ':
        return Icons.bakery_dining;
      case 'スイーツ':
        return Icons.icecream;
      case 'ケーキ':
        return Icons.cake;
      case 'タピオカ':
        return Icons.local_drink;
      case 'バー・お酒':
        return Icons.local_bar;
      case 'スナック':
        return Icons.local_bar;
      case '料理旅館':
        return Icons.house;
      case '沖縄料理':
        return Icons.beach_access;
      case 'ショップ':
        return Icons.shopping_bag;
      case '美容院':
        return Icons.content_cut;
      case '薬局':
        return Icons.local_pharmacy;
      case 'コンビニ':
        return Icons.store;
      case 'スーパー':
        return Icons.shopping_cart;
      case '書店':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }
}
