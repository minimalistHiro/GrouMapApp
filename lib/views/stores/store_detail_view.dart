import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/posts_provider.dart';
import '../../providers/coupon_provider.dart';
import '../posts/post_detail_view.dart';
import '../coupons/coupon_detail_view.dart';

class StoreDetailView extends ConsumerStatefulWidget {
  final Map<String, dynamic> store;
  
  const StoreDetailView({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  ConsumerState<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends ConsumerState<StoreDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userStamps;
  bool _isLoadingStamps = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserStamps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ユーザーのスタンプ状況を読み込む
  Future<void> _loadUserStamps() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 新しい構造: users/{userId}/stores/{storeId}
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.store['id'])
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _userStamps = {
            'stamps': data['stamps'] ?? 0,
            'lastVisited': data['lastVisited'],
            'totalSpending': data['totalSpending'] ?? 0.0,
          };
        });
      } else {
        setState(() {
          _userStamps = {
            'stamps': 0,
            'lastVisited': null,
            'totalSpending': 0.0,
          };
        });
      }
    } catch (e) {
      print('ユーザースタンプデータの読み込みに失敗しました: $e');
      setState(() {
        _userStamps = {
          'stamps': 0,
          'lastVisited': null,
          'totalSpending': 0.0,
        };
      });
    } finally {
      setState(() {
        _isLoadingStamps = false;
      });
    }
  }

  // スタンプ数を更新する
  Future<void> _updateStamps(int newStampCount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // スタンプ数を0-10の範囲に制限
      final clampedStamps = newStampCount.clamp(0, 10);
      
      // 新しい構造: users/{userId}/stores/{storeId} に保存
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.store['id'])
          .set({
        'stamps': clampedStamps,
        'lastVisited': DateTime.now(),
        'totalSpending': _userStamps?['totalSpending'] ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
        'storeId': widget.store['id'],
        'storeName': widget.store['name'],
      }, SetOptions(merge: true));

      // ローカル状態を更新
      setState(() {
        _userStamps = {
          'stamps': clampedStamps,
          'lastVisited': DateTime.now(),
          'totalSpending': _userStamps?['totalSpending'] ?? 0.0,
        };
      });

      // スタンプカード完成時の通知
      if (clampedStamps >= 10) {
        _showStampCompletionDialog();
      }

    } catch (e) {
      print('スタンプ数の更新に失敗しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('スタンプの更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // いいね数を取得するメソッド
  Future<int> _getLikeCount(String postId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('public_posts')
          .doc(postId)
          .collection('likes')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('いいね数取得エラー: $e');
      return 0;
    }
  }

  // スタンプカード完成ダイアログを表示
  void _showStampCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('スタンプカード完成！'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'おめでとうございます！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'スタンプカードが完成しました。\n特典を受け取ることができます！',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 店舗背景画像
          _buildStoreHeader(),
          
          // 店舗基本情報
          _buildStoreInfo(),
          
          // スタンプカード
          _buildStampCard(),
          
          // タブバー
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF6B35),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF6B35),
                tabs: const [
                  Tab(text: '投稿'),
                  Tab(text: 'クーポン'),
                  Tab(text: 'メニュー'),
                  Tab(text: '店舗詳細'),
                ],
              ),
            ),
          ),
          
          // タブコンテンツ
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                switch (_tabController.index) {
                  case 0:
                    return _buildPostsTab();
                  case 1:
                    return _buildCouponsTab();
                  case 2:
                    return _buildMenuTab();
                  case 3:
                  default:
                    return _buildStoreDetailsTab();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFFFF6B35),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildStoreBackground(),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // 店舗背景画像を構築
  Widget _buildStoreBackground() {
    // 両方のフィールド名をサポート
    final backgroundImageUrl = _getStringValue(widget.store['backgroundImageUrl'], '');
    final storeImageUrl = _getStringValue(widget.store['storeImageUrl'], '');
    final imageUrl = backgroundImageUrl.isNotEmpty ? backgroundImageUrl : storeImageUrl;
    
    if (imageUrl.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          // 画像読み込みの設定
          isAntiAlias: true,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, child, loadingProgress) {
            print('背景画像読み込み中...');
            if (loadingProgress == null) {
              print('背景画像読み込み完了');
              return child;
            }
            return Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFFF6B35),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('店舗背景画像の読み込みエラー: $error');
            print('スタックトレース: $stackTrace');
            return Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFFF6B35),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '画像読み込みエラー',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // 背景画像がない場合の表示
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF6B35),
              const Color(0xFFFF6B35).withOpacity(0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                '背景画像なし',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStoreInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 店舗アイコン
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _buildStoreIcon(),
            ),
            
            const SizedBox(width: 16),
            
            // 店舗名とカテゴリ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStringValue(widget.store['name'], '店舗名なし'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStringValue(widget.store['category'], 'その他'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampCard() {
    if (_isLoadingStamps) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
          ),
        ),
      );
    }

    final stamps = _userStamps?['stamps'] ?? 0;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'スタンプカード',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // 開発用テスター表示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'テストモード',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // スタンプ表示（5x2のグリッド）
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                final hasStamp = index < stamps;
                
                return Container(
                  decoration: BoxDecoration(
                    color: hasStamp ? Colors.blue : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasStamp ? Colors.blue[700]! : Colors.grey[400]!,
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
            
            // スタンプ状況テキスト
            Center(
              child: Text(
                'スタンプ: $stamps/10',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // スタンプカード完成通知
            if (stamps >= 10)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'おめでとうございます！スタンプカードが完成しました！',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    final storeId = widget.store['id'];
    
    // まずメインプロバイダーを試す
    final posts = ref.watch(storePostsProvider(storeId));
    
    return posts.when(
      data: (posts) {
        print('投稿データ取得成功: ${posts.length}件');
        
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '投稿がありません',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'この店舗からの投稿をお待ちください！',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildInstagramPostCard(context, post);
            },
          ),
        );
      },
      loading: () {
        print('投稿データ読み込み中...');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
              SizedBox(height: 8),
              Text(
                '投稿を読み込み中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        print('メインプロバイダーエラー: $error');
        
        // エラーが発生した場合はフォールバックプロバイダーを使用
        return _buildFallbackPostsTab(storeId);
      },
    );
  }

  Widget _buildFallbackPostsTab(String storeId) {
    final fallbackPosts = ref.watch(storePostsFallbackProvider(storeId));
    
    return fallbackPosts.when(
      data: (posts) {
        print('フォールバック投稿データ取得成功: ${posts.length}件');
        
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '投稿がありません',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'この店舗からの投稿をお待ちください！',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildInstagramPostCard(context, post);
            },
          ),
        );
      },
      loading: () {
        print('フォールバック投稿データ読み込み中...');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
              SizedBox(height: 8),
              Text(
                '投稿を読み込み中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        print('フォールバックプロバイダーエラー: $error');
        
        // フォールバックも失敗した場合は投稿なしとして表示
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '投稿がありません',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'この店舗からの投稿をお待ちください！',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponsTab() {
    final storeId = widget.store['id'];
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final coupons = ref.watch(availableCouponsProvider(userId));

    return coupons.when(
      data: (coupons) {
        // この店舗のクーポンのみをフィルタリング
        final storeCoupons = coupons.where((coupon) => coupon.storeId == storeId).toList();
        
        if (storeCoupons.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'この店舗のクーポンはありません',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '新しいクーポンをお待ちください！',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: storeCoupons.length,
            itemBuilder: (context, index) {
              final coupon = storeCoupons[index];
              return _buildCouponCard(context, coupon);
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
            SizedBox(height: 8),
            Text(
              'クーポンを読み込み中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'クーポンの取得に失敗しました',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'データが存在しない可能性があります',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'メニュー機能は今後実装予定です',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStoreDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 説明
          if (_getStringValue(widget.store['description'], '').isNotEmpty) ...[
            const Text(
              '店舗説明',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStringValue(widget.store['description'], ''),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
          
          // 住所
          if (_getStringValue(widget.store['address'], '').isNotEmpty) ...[
            const Text(
              '住所',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStringValue(widget.store['address'], ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 電話番号
          if (_getStringValue(widget.store['phone'], '').isNotEmpty) ...[
            const Text(
              '電話番号',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getStringValue(widget.store['phone'], ''),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 営業時間
          if (widget.store['businessHours'] != null) ...[
            const Text(
              '営業時間',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildBusinessHoursDisplay(),
            const SizedBox(height: 16),
          ],
          
          // タグ
          if (widget.store['tags'] != null && (widget.store['tags'] as List).isNotEmpty) ...[
            const Text(
              'タグ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (widget.store['tags'] as List).map<Widget>((tag) => Chip(
                label: Text(tag.toString()),
                backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
                labelStyle: const TextStyle(fontSize: 12),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // SNS・ウェブサイト
          if (_hasSocialMedia()) ...[
            const Text(
              'SNS・ウェブサイト',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildSocialMediaDisplay(),
            const SizedBox(height: 16),
          ],
          
          // 位置情報
          if (widget.store['location'] != null) ...[
            const Text(
              '位置情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildLocationDisplay(),
            const SizedBox(height: 16),
          ],
          
          // ステータス
          const Text(
            'ステータス',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBoolValue(widget.store['isActive'], false)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBoolValue(widget.store['isActive'], false)
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getBoolValue(widget.store['isActive'], false) ? '営業中' : '休業中',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getBoolValue(widget.store['isActive'], false)
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBoolValue(widget.store['isApproved'], false)
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBoolValue(widget.store['isApproved'], false)
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getBoolValue(widget.store['isApproved'], false) ? '承認済み' : '承認待ち',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getBoolValue(widget.store['isApproved'], false)
                        ? Colors.blue[700]
                        : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 安全にStringを取得するヘルパーメソッド
  String _getStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) return value.toString();
    return value.toString();
  }

  // 安全にboolを取得するヘルパーメソッド
  bool _getBoolValue(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  // カテゴリに応じた色を取得
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'レストラン':
        return Colors.red;
      case 'カフェ':
        return Colors.brown;
      case 'ショップ':
        return Colors.blue;
      case '美容院':
        return Colors.pink;
      case '薬局':
        return Colors.green;
      case 'コンビニ':
        return Colors.orange;
      case 'スーパー':
        return Colors.lightGreen;
      case '書店':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 店舗アイコンを構築
  Widget _buildStoreIcon() {
    final iconImageUrl = _getStringValue(widget.store['iconImageUrl'], '');
    final category = _getStringValue(widget.store['category'], 'その他');
    
    if (iconImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          iconImageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          // CORSエラーを回避する設定
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET',
            'Access-Control-Allow-Headers': 'Content-Type',
          },
          // 画像読み込みの設定
          isAntiAlias: true,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: _getCategoryColor(category),
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('店舗アイコン画像の読み込みエラー: $error');
            return Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 40,
            );
          },
        ),
      );
    } else {
      return Icon(
        _getCategoryIcon(category),
        color: _getCategoryColor(category),
        size: 40,
      );
    }
  }


  // カテゴリに応じたアイコンを取得
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'レストラン':
        return Icons.restaurant;
      case 'カフェ':
        return Icons.local_cafe;
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

  // 営業時間表示を構築
  Widget _buildBusinessHoursDisplay() {
    final businessHours = widget.store['businessHours'] as Map<String, dynamic>?;
    if (businessHours == null) return const SizedBox.shrink();

    final dayNames = {
      'monday': '月',
      'tuesday': '火',
      'wednesday': '水',
      'thursday': '木',
      'friday': '金',
      'saturday': '土',
      'sunday': '日',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: dayNames.entries.map((entry) {
          final dayKey = entry.key;
          final dayName = entry.value;
          final dayData = businessHours[dayKey] as Map<String, dynamic>?;
          
          if (dayData == null) return const SizedBox.shrink();
          
          final isOpen = _getBoolValue(dayData['isOpen'], false);
          final openTime = _getStringValue(dayData['open'], '');
          final closeTime = _getStringValue(dayData['close'], '');
          
          // 今日の曜日をハイライト
          final now = DateTime.now();
          final todayIndex = now.weekday - 1; // Monday = 0, Sunday = 6
          final dayIndex = dayNames.keys.toList().indexOf(dayKey);
          final isToday = dayIndex == todayIndex;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFF6B35).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // 曜日表示
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday 
                        ? const Color(0xFFFF6B35)
                        : isOpen 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday 
                          ? const Color(0xFFFF6B35)
                          : isOpen 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isToday 
                            ? Colors.white
                            : isOpen 
                                ? Colors.green[700]
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 営業時間表示
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isOpen ? Icons.access_time : Icons.close,
                        color: isOpen ? Colors.green[600] : Colors.red[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOpen ? '$openTime - $closeTime' : '定休日',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isOpen ? Colors.black87 : Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 今日のマーク
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '今日',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // SNS・ウェブサイト表示を構築
  Widget _buildSocialMediaDisplay() {
    final socialMedia = widget.store['socialMedia'] as Map<String, dynamic>?;
    if (socialMedia == null) return const SizedBox.shrink();

    final List<Widget> socialItems = [];

    if (_getStringValue(socialMedia['website'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('ウェブサイト', socialMedia['website'], Icons.language));
    }
    if (_getStringValue(socialMedia['instagram'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('Instagram', socialMedia['instagram'], Icons.camera_alt));
    }
    if (_getStringValue(socialMedia['x'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('X (Twitter)', socialMedia['x'], Icons.flutter_dash));
    }
    if (_getStringValue(socialMedia['facebook'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('Facebook', socialMedia['facebook'], Icons.facebook));
    }

    return Column(
      children: socialItems,
    );
  }

  Widget _buildSocialItem(String label, String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // URLを開く処理（実装が必要）
              },
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 位置情報表示を構築
  Widget _buildLocationDisplay() {
    final location = widget.store['location'] as Map<String, dynamic>?;
    if (location == null) return const SizedBox.shrink();

    final latitude = location['latitude'] as double? ?? 0.0;
    final longitude = location['longitude'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Text('位置情報', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '緯度: ${latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12, color: Colors.blue, fontFamily: 'monospace'),
          ),
          Text(
            '経度: ${longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12, color: Colors.blue, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  // SNS・ウェブサイトがあるかチェック
  bool _hasSocialMedia() {
    final socialMedia = widget.store['socialMedia'] as Map<String, dynamic>?;
    if (socialMedia == null) return false;

    return _getStringValue(socialMedia['website'], '').isNotEmpty ||
           _getStringValue(socialMedia['instagram'], '').isNotEmpty ||
           _getStringValue(socialMedia['x'], '').isNotEmpty ||
           _getStringValue(socialMedia['facebook'], '').isNotEmpty;
  }

  // Instagram風の投稿カードを構築
  Widget _buildInstagramPostCard(BuildContext context, PostModel post) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailView(post: post),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: post.imageUrls.isNotEmpty
            ? Stack(
                children: [
                  // メイン画像
                  Positioned.fill(
                    child: Image.network(
                      post.imageUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // 複数画像インジケーター（画像が複数ある場合）
                  if (post.imageUrls.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.grid_on,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${post.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // いいね数オーバーレイ（いいねがある場合）
                  FutureBuilder<int>(
                    future: _getLikeCount(post.id),
                    builder: (context, snapshot) {
                      final likeCount = snapshot.data ?? 0;
                      if (likeCount > 0) {
                        return Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$likeCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              )
            : Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),
      ),
    );
  }

  // 投稿カードを構築（詳細表示用）
  Widget _buildPostCard(BuildContext context, PostModel post) {
    // 作成日の表示用フォーマット
    String formatDate() {
      try {
        final date = post.createdAt;
        final now = DateTime.now();
        final difference = now.difference(date).inDays;
        
        if (difference == 0) return '今日';
        if (difference == 1) return '昨日';
        if (difference < 7) return '${difference}日前';
        
        return '${date.month}月${date.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailView(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 画像がある場合は表示
              if (post.imageUrls.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrls[0],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              Row(
                children: [
                  Icon(
                    Icons.article,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          post.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.category ?? 'お知らせ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    post.storeName ?? '店舗名なし',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${post.viewCount}回閲覧',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  FutureBuilder<int>(
                    future: _getLikeCount(post.id),
                    builder: (context, snapshot) {
                      final likeCount = snapshot.data ?? 0;
                      return Text(
                        '${likeCount}いいね',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // クーポンカードを構築
  Widget _buildCouponCard(BuildContext context, dynamic coupon) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon.validUntil;
      if (endDate == null) return '期限不明';
      
      try {
        final date = endDate is DateTime ? endDate : endDate.toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(date.year, date.month, date.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${date.month}月${date.day}日';
        }
        
        return '$dateText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon.discountType ?? 'percentage';
      final discountValue = coupon.discountValue ?? 0.0;
      
      if (discountType == 'percentage') {
        return '${discountValue.toInt()}%OFF';
      } else if (discountType == 'fixed_amount') {
        return '${discountValue.toInt()}円OFF';
      } else if (discountType == 'fixed_price') {
        return '${discountValue.toInt()}円';
      }
      return '特典あり';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CouponDetailView(coupon: coupon),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
          children: [
            // 画像（正方形）
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 7, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7),
                ),
                child: coupon.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          coupon.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            
            // 期限
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                formatEndDate(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon.title ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 割引情報
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                getDiscountText(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Divider(height: 1),
            
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                widget.store['name'] ?? '店舗名なし',
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 1),
          ],
        ),
      ),
    );
  }

  
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
