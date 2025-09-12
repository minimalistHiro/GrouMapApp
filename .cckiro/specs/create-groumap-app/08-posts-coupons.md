# 投稿機能とクーポン機能設計

## 17. 投稿機能設計（プレミアム限定）

### 17.1 投稿データモデル
```dart
class PostModel {
  final String postId;
  final String userId;
  final String storeId;
  final String title;
  final String content;
  final int rating;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final PostStats stats;

  const PostModel({
    required this.postId,
    required this.userId,
    required this.storeId,
    required this.title,
    required this.content,
    required this.rating,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    required this.stats,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['postId'],
      userId: json['userId'],
      storeId: json['storeId'],
      title: json['title'],
      content: json['content'],
      rating: json['rating'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? true,
      stats: PostStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class PostStats {
  final int likeCount;
  final int commentCount;
  final int viewCount;

  const PostStats({
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
    );
  }
}
```

### 17.2 投稿・クーポンタブ画面設計

#### 17.2.1 投稿タブメイン画面
```dart
class PostsTabScreen extends ConsumerStatefulWidget {
  const PostsTabScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PostsTabScreen> createState() => _PostsTabScreenState();
}

class _PostsTabScreenState extends ConsumerState<PostsTabScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '投稿'),
            Tab(text: 'クーポン'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 投稿タブ
          PostsGridView(),
          
          // クーポンタブ
          CouponsGridView(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

#### 17.2.2 投稿グリッドビュー（2×N、20件表示、新規投稿順）
```dart
class PostsGridView extends ConsumerWidget {
  const PostsGridView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(recentPostsProvider);
    
    return posts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorWidget(error: error.toString()),
      data: (postsList) => RefreshIndicator(
        onRefresh: () async {
          ref.refresh(recentPostsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // 縦長のカード
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(post: postsList[index]),
                  childCount: math.min(postsList.length, 20), // 最大20件
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostModel post;
  
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 写真（上部）
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                child: post.imageUrls.isNotEmpty
                  ? Image.network(
                      post.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.photo,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
              ),
            ),
          ),
          
          // コンテンツ部分
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // テキスト
                  Expanded(
                    child: Text(
                      post.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 店舗情報（下部）
                  _buildStoreInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Consumer(
      builder: (context, ref, _) {
        final store = ref.watch(storeProvider(post.storeId));
        
        return store.when(
          data: (storeData) => Row(
            children: [
              // 小さな店舗アイコン
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  storeData.images.isNotEmpty ? storeData.images.first : '',
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        width: 16,
                        height: 16,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.store,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 6),
              
              // 店舗名
              Expanded(
                child: Text(
                  storeData.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          loading: () => const SizedBox(height: 16),
          error: (error, _) => const SizedBox(height: 16),
        );
      },
    );
  }
}
```

#### 17.2.3 クーポングリッドビュー（2×N、20件表示、有効期限近い順）
```dart
class CouponsGridView extends ConsumerWidget {
  const CouponsGridView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(availableCouponsProvider);
    
    return coupons.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorWidget(error: error.toString()),
      data: (couponsList) => RefreshIndicator(
        onRefresh: () async {
          ref.refresh(availableCouponsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // 縦長のカード
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => CouponCard(coupon: couponsList[index]),
                  childCount: math.min(couponsList.length, 20), // 最大20件
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  
  const CouponCard({Key? key, required this.coupon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getExpiryColor(),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 写真（上部）
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    child: coupon.imageUrls != null && coupon.imageUrls!.isNotEmpty
                      ? Image.network(
                          coupon.imageUrls!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.local_offer,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.local_offer,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                  ),
                ),
                
                // 有効期限バッジ（右上）
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getExpiryColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getExpiryText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // コンテンツ部分
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    coupon.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // テキスト
                  Expanded(
                    child: Text(
                      coupon.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 店舗情報（下部）
                  _buildStoreInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExpiryText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final expiryDate = DateTime(coupon.validUntil.year, coupon.validUntil.month, coupon.validUntil.day);

    if (expiryDate.isAtSameMomentAs(today)) {
      return '本日まで';
    } else if (expiryDate.isAtSameMomentAs(tomorrow)) {
      return '明日まで';
    } else {
      return '${coupon.validUntil.year}/${coupon.validUntil.month.toString().padLeft(2, '0')}/${coupon.validUntil.day.toString().padLeft(2, '0')}まで';
    }
  }

  Color _getExpiryColor() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final expiryDate = DateTime(coupon.validUntil.year, coupon.validUntil.month, coupon.validUntil.day);

    if (expiryDate.isAtSameMomentAs(today)) {
      return Colors.red; // 本日まで
    } else if (expiryDate.isAtSameMomentAs(tomorrow)) {
      return Colors.orange; // 明日まで
    } else {
      return AppColors.primary; // それ以外
    }
  }

  Widget _buildStoreInfo() {
    return Consumer(
      builder: (context, ref, _) {
        final store = ref.watch(storeProvider(coupon.storeId));
        
        return store.when(
          data: (storeData) => Row(
            children: [
              // 小さな店舗アイコン
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  storeData.images.isNotEmpty ? storeData.images.first : '',
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        width: 16,
                        height: 16,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.store,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 6),
              
              // 店舗名
              Expanded(
                child: Text(
                  storeData.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          loading: () => const SizedBox(height: 16),
          error: (error, _) => const SizedBox(height: 16),
        );
      },
    );
  }
}
```

#### 17.2.4 データプロバイダー
```dart
// 最新投稿取得プロバイダー（新規投稿順）
final recentPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PostModel.fromJson({...doc.data(), 'postId': doc.id}))
          .toList());
});

// 利用可能クーポン取得プロバイダー（有効期限近い順）
final availableCouponsProvider = StreamProvider<List<CouponModel>>((ref) {
  final now = DateTime.now();
  
  return FirebaseFirestore.instance
      .collection('coupons')
      .where('isActive', isEqualTo: true)
      .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
      .orderBy('validUntil', descending: false) // 有効期限近い順
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => CouponModel.fromJson({...doc.data(), 'couponId': doc.id}))
          .toList());
});
```

### 17.3 投稿作成画面設計
```dart
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<File> _images = [];
  String? _selectedStoreId;
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final stores = ref.watch(nearbyStoresProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを投稿'),
        actions: [
          TextButton(
            onPressed: _isValidPost() ? _submitPost : null,
            child: const Text('投稿', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoreSelector(stores),
            const SizedBox(height: 16),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildContentField(),
            const SizedBox(height: 16),
            _buildImageSelector(),
            const SizedBox(height: 16),
            _buildPreview(),
          ],
        ),
      ),
    );
  }

  bool _isValidPost() {
    return _titleController.text.isNotEmpty &&
           _contentController.text.isNotEmpty &&
           _selectedStoreId != null &&
           _rating > 0;
  }
}
```

## 18. クーポン機能詳細設計

### 18.1 クーポンデータモデル拡張
```dart
class CouponModel {
  final String couponId;
  final String storeId;
  final String title;
  final String description;
  final CouponType type;
  final CouponValue value;
  final CouponConditions conditions;
  final DateTime validFrom;
  final DateTime validUntil;
  final int totalQuantity;
  final int usedQuantity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CouponModel({
    required this.couponId,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.conditions,
    required this.validFrom,
    required this.validUntil,
    required this.totalQuantity,
    this.usedQuantity = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
}

enum CouponType {
  percentage,      // パーセント割引
  fixedAmount,     // 固定額割引
  freeItem,        // 無料商品
  pointMultiplier, // ポイント倍率
}
```