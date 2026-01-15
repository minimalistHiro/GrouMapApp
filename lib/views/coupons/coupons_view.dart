import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/coupon_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/store_provider.dart';
import '../../models/coupon_model.dart' as model;
import '../../widgets/custom_button.dart';
import '../posts/post_detail_view.dart';
import 'coupon_detail_view.dart';

class CouponsView extends ConsumerWidget {
  const CouponsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('クーポン'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          return _buildCouponsContent(context, ref, user?.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildCouponsContent(BuildContext context, WidgetRef ref, String? userId) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '投稿', icon: Icon(Icons.article)),
              Tab(text: 'クーポン', icon: Icon(Icons.card_giftcard)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPosts(context, ref),
                _buildCoupons(context, ref, userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosts(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(allPostsProvider);

    return posts.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('投稿がありません'),
                SizedBox(height: 8),
                Text('新しい投稿をお待ちください！'),
              ],
            ),
          );
        }

        final itemCount = posts.length > 60 ? 60 : posts.length;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            childAspectRatio: 1,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(context, ref, post);
          },
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
              '投稿を読み込み中...',
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
              '投稿の取得に失敗しました',
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: '再試行',
                onPressed: () {
                  ref.invalidate(allPostsProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoupons(BuildContext context, WidgetRef ref, String? userId) {
    final isLoggedIn = userId != null;
    final tabs = <Tab>[
      const Tab(text: '利用可能', icon: Icon(Icons.card_giftcard)),
      if (isLoggedIn) const Tab(text: '使用済み', icon: Icon(Icons.check_circle)),
      const Tab(text: 'プロモーション', icon: Icon(Icons.campaign)),
    ];
    final views = <Widget>[
      _buildAvailableCoupons(context, ref, userId ?? 'guest'),
      if (isLoggedIn) _buildUsedCoupons(context, ref, userId!),
      _buildPromotions(context, ref),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(tabs: tabs),
          Expanded(
            child: TabBarView(
              children: views,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, PostModel post) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailView(post: post),
          ),
        );
      },
      child: Container(
        color: Colors.grey[200],
        child: post.imageUrls.isNotEmpty
            ? Stack(
                children: [
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

  Widget _buildAvailableCoupons(BuildContext context, WidgetRef ref, String userId) {
    final availableCoupons = ref.watch(availableCouponsProvider(userId));

    return availableCoupons.when(
      data: (coupons) {
        if (coupons.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('利用可能なクーポンがありません'),
                SizedBox(height: 8),
                Text('新しいクーポンをお待ちください！'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8, // アスペクト比を調整してレイアウトエラーを防止
            ),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _buildCouponCardGrid(context, ref, coupon, userId);
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
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: '再試行',
                onPressed: () {
                  ref.invalidate(availableCouponsProvider(userId));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsedCoupons(BuildContext context, WidgetRef ref, String userId) {
    final usedCoupons = ref.watch(usedCouponsProvider(userId));
    final timedOut = ref.watch(_usedCouponsTimedOutProvider);

    return usedCoupons.when(
      data: (coupons) {
        if (coupons.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('使用済みクーポンがありません'),
                SizedBox(height: 8),
                Text('クーポンを使用してみましょう！'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8, // アスペクト比を調整してレイアウトエラーを防止
            ),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _buildUsedCouponCardGrid(context, ref, coupon);
            },
          ),
        );
      },
      loading: () {
        if (!timedOut) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('読み込みがタイムアウトしました'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomButton(
                  text: '再試行',
                  onPressed: () {
                    ref.invalidate(_usedCouponsTimedOutProvider);
                    ref.invalidate(usedCouponsProvider(userId));
                  },
                ),
              ),
            ],
          ),
        );
      },
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: '再試行',
                onPressed: () {
                  ref.invalidate(usedCouponsProvider(userId));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotions(BuildContext context, WidgetRef ref) {
    final promotions = ref.watch(promotionsProvider);

    return promotions.when(
      data: (promotions) {
        if (promotions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('プロモーションがありません'),
                SizedBox(height: 8),
                Text('新しいプロモーションをお待ちください！'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: promotions.length,
          itemBuilder: (context, index) {
            final promotion = promotions[index];
            return _buildPromotionCard(context, ref, promotion);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: '再試行',
                onPressed: () {
                  ref.invalidate(promotionsProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCardGrid(BuildContext context, WidgetRef ref, model.Coupon coupon, String userId) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon.validUntil;
      
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(endDate.year, endDate.month, endDate.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${endDate.month}月${endDate.day}日';
        }
        
        return '$dateText ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon.discountType;
      final discountValue = coupon.discountValue;
      
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
            // 画像（縦長）
            AspectRatio(
              aspectRatio: 0.8, // 縦長にする
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
            
            // コンテンツ部分
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 期限
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        formatEndDate(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // タイトル
                    Text(
                      coupon.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 割引情報
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        getDiscountText(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // 店舗名
                    ref.watch(storeNameProvider(coupon.storeId)).when(
                      data: (storeName) => Text(
                        storeName ?? '店舗名なし',
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text(
                        '読み込み中...',
                        style: TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                      error: (_, __) => Text(
                        coupon.storeId,
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, WidgetRef ref, model.Coupon coupon, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCouponIcon(coupon.type),
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        coupon.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getDiscountText(coupon),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '有効期限: ${_formatDate(coupon.validUntil)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '残り${coupon.usageLimit - coupon.usedCount}枚',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'クーポンを取得',
                onPressed: () => _obtainCoupon(context, ref, coupon.id, coupon.storeId, userId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsedCouponCardGrid(BuildContext context, WidgetRef ref, model.Coupon coupon) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon.validUntil;
      
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(endDate.year, endDate.month, endDate.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${endDate.month}月${endDate.day}日';
        }
        
        return '$dateText ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon.discountType;
      final discountValue = coupon.discountValue;
      
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
            // 画像（縦長）
            AspectRatio(
              aspectRatio: 0.8, // 縦長にする
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
            
            // コンテンツ部分
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 使用済みバッジ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Text(
                        '使用済み',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // タイトル
                    Text(
                      coupon.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 割引情報
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        getDiscountText(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // 店舗名
                    ref.watch(storeNameProvider(coupon.storeId)).when(
                      data: (storeName) => Text(
                        storeName ?? '店舗名なし',
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text(
                        '読み込み中...',
                        style: TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                      error: (_, __) => Text(
                        coupon.storeId,
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsedCouponCard(BuildContext context, WidgetRef ref, model.Coupon coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CouponDetailView(coupon: coupon),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '有効期限: ${_formatDate(coupon.validUntil)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '使用済み',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCouponCard(BuildContext context, WidgetRef ref, model.UserCoupon userCoupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              userCoupon.isUsed ? Icons.check_circle : Icons.card_giftcard,
              color: userCoupon.isUsed ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'クーポンID: ${userCoupon.couponId.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '取得日: ${_formatDate(userCoupon.obtainedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (userCoupon.isUsed)
                    Text(
                      '使用日: ${_formatDate(userCoupon.usedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: userCoupon.isUsed ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                userCoupon.isUsed ? '使用済み' : '未使用',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context, WidgetRef ref, model.Promotion promotion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showPromotionDetails(context, ref, promotion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getPromotionIcon(promotion.type),
                    color: Colors.purple,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          promotion.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPromotionTypeText(promotion.type),
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
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '期間: ${_formatDate(promotion.startDate)} - ${_formatDate(promotion.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCouponIcon(model.CouponType type) {
    switch (type) {
      case model.CouponType.discount:
        return Icons.local_offer;
      case model.CouponType.freeShipping:
        return Icons.local_shipping;
      case model.CouponType.buyOneGetOne:
        return Icons.shopping_bag;
      case model.CouponType.cashback:
        return Icons.monetization_on;
      case model.CouponType.pointsMultiplier:
        return Icons.stars;
    }
  }

  IconData _getPromotionIcon(model.PromotionType type) {
    switch (type) {
      case model.PromotionType.banner:
        return Icons.campaign;
      case model.PromotionType.popup:
        return Icons.open_in_new;
      case model.PromotionType.pushNotification:
        return Icons.notifications;
      case model.PromotionType.email:
        return Icons.email;
      case model.PromotionType.inApp:
        return Icons.apps;
    }
  }

  String _getDiscountText(model.Coupon coupon) {
    if (coupon.discountType == 'percentage') {
      return '${coupon.discountValue.toInt()}% OFF';
    } else {
      return '¥${coupon.discountValue.toInt()} OFF';
    }
  }

  String _getPromotionTypeText(model.PromotionType type) {
    switch (type) {
      case model.PromotionType.banner:
        return 'バナー';
      case model.PromotionType.popup:
        return 'ポップアップ';
      case model.PromotionType.pushNotification:
        return 'プッシュ通知';
      case model.PromotionType.email:
        return 'メール';
      case model.PromotionType.inApp:
        return 'アプリ内';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
  
  void _obtainCoupon(BuildContext context, WidgetRef ref, String couponId, String storeId, String userId) async {
    try {
      await ref.read(couponProvider).obtainCoupon(userId, couponId, storeId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クーポンを取得しました！')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クーポン検索'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'クーポン名を入力',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('検索'),
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
          children: [
            ListTile(
              title: const Text('割引クーポン'),
              leading: Radio<String>(
                value: 'discount',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('送料無料'),
              leading: Radio<String>(
                value: 'free_shipping',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('キャッシュバック'),
              leading: Radio<String>(
                value: 'cashback',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('適用'),
          ),
        ],
      ),
    );
  }

  void _showPromotionDetails(BuildContext context, WidgetRef ref, model.Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promotion.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(promotion.description),
            const SizedBox(height: 16),
            Text('期間: ${_formatDate(promotion.startDate)} - ${_formatDate(promotion.endDate)}'),
            Text('タイプ: ${_getPromotionTypeText(promotion.type)}'),
            Text('表示回数: ${promotion.viewCount}'),
            Text('クリック回数: ${promotion.clickCount}'),
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
}

// Usedタブの無限ローディング対策: 一定時間でタイムアウト表示に切り替える
final _usedCouponsTimedOutProvider = StateProvider.autoDispose<bool>((ref) {
  final controller = StreamController<bool>();
  Timer(const Duration(seconds: 10), () {
    try {
      controller.add(true);
    } catch (_) {}
  });
  final sub = controller.stream.listen((value) {
    ref.controller.state = value;
  });
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return false;
});
