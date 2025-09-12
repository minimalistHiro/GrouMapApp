import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('user_stamps')
          .where('userId', isEqualTo: user.uid)
          .where('storeId', isEqualTo: widget.store['id'])
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _userStamps = {
            'goldStamps': data['goldStamps'] ?? 0,
            'regularStamps': data['regularStamps'] ?? 0,
            'lastVisited': data['lastVisited'],
            'totalSpending': data['totalSpending'] ?? 0.0,
          };
        });
      } else {
        setState(() {
          _userStamps = {
            'goldStamps': 0,
            'regularStamps': 0,
            'lastVisited': null,
            'totalSpending': 0.0,
          };
        });
      }
    } catch (e) {
      print('ユーザースタンプデータの読み込みに失敗しました: $e');
      setState(() {
        _userStamps = {
          'goldStamps': 0,
          'regularStamps': 0,
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
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF6B35),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF6B35),
                tabs: const [
                  Tab(text: '投稿'),
                  Tab(text: 'メニュー'),
                  Tab(text: '店舗詳細'),
                ],
              ),
            ),
          ),
          
          // タブコンテンツ
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildMenuTab(),
                _buildStoreDetailsTab(),
              ],
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
        background: widget.store['backgroundImageUrl']?.isNotEmpty == true
            ? Image.network(
                widget.store['backgroundImageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFFF6B35),
                    child: const Center(
                      child: Icon(
                        Icons.store,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: const Color(0xFFFF6B35),
                child: const Center(
                  child: Icon(
                    Icons.store,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
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
                color: _getCategoryColor(widget.store['category']).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getCategoryColor(widget.store['category']).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: widget.store['iconImageUrl']?.isNotEmpty == true
                  ? ClipOval(
                      child: Image.network(
                        widget.store['iconImageUrl'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getCategoryIcon(widget.store['category']),
                            color: _getCategoryColor(widget.store['category']),
                            size: 40,
                          );
                        },
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(widget.store['category']),
                      color: _getCategoryColor(widget.store['category']),
                      size: 40,
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // 店舗名とカテゴリ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store['name'] ?? '店舗名なし',
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
                      color: _getCategoryColor(widget.store['category']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getCategoryColor(widget.store['category']).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.store['category'] ?? 'その他',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCategoryColor(widget.store['category']),
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

    final goldStamps = _userStamps?['goldStamps'] ?? 0;
    final regularStamps = _userStamps?['regularStamps'] ?? 0;
    final totalStamps = goldStamps + regularStamps;

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
            const Text(
              'スタンプカード',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
                final isGold = index < goldStamps;
                final isRegular = index >= goldStamps && index < totalStamps;
                final isEmpty = index >= totalStamps;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isGold
                        ? Colors.amber
                        : isRegular
                            ? Colors.blue
                            : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isGold
                          ? Colors.amber[700]!
                          : isRegular
                              ? Colors.blue[700]!
                              : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isGold
                        ? const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 20,
                          )
                        : isRegular
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ゴールドスタンプ: $goldStamps',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'レギュラースタンプ: $regularStamps',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          '投稿機能は今後実装予定です',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 説明
          if (widget.store['description']?.isNotEmpty == true) ...[
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
              widget.store['description'],
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
          
          // 住所
          if (widget.store['address']?.isNotEmpty == true) ...[
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
                    widget.store['address'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 電話番号
          if (widget.store['phoneNumber']?.isNotEmpty == true) ...[
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
                  widget.store['phoneNumber'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 営業時間
          if (widget.store['businessHours']?.isNotEmpty == true) ...[
            const Text(
              '営業時間',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.store['businessHours'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
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
                  color: widget.store['isActive'] == true
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.store['isActive'] == true
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.store['isActive'] == true ? '営業中' : '休業中',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.store['isActive'] == true
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
                  color: widget.store['isApproved'] == true
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.store['isApproved'] == true
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.store['isApproved'] == true ? '承認済み' : '承認待ち',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.store['isApproved'] == true
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
}
