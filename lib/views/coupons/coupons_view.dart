import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../../models/coupon_model.dart' as model;
import '../../widgets/custom_button.dart';

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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }
          return _buildCouponsContent(context, ref, user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildCouponsContent(BuildContext context, WidgetRef ref, String userId) {
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
    final posts = ref.watch(feedPostsProvider);

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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(context, ref, post);
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
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(feedPostsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoupons(BuildContext context, WidgetRef ref, String userId) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '利用可能', icon: Icon(Icons.card_giftcard)),
              Tab(text: 'マイクーポン', icon: Icon(Icons.person)),
              Tab(text: 'プロモーション', icon: Icon(Icons.campaign)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableCoupons(context, ref, userId),
                _buildMyCoupons(context, ref, userId),
                _buildPromotions(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, dynamic post) {
    // 作成日の表示用フォーマット
    String formatDate() {
      final createdAt = post.createdAt;
      if (createdAt == null) return '日付不明';
      
      try {
        final date = createdAt.toDate();
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
          // 投稿詳細画面に遷移
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          post.title ?? 'タイトルなし',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          post.content ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
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
            ],
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coupons.length,
          itemBuilder: (context, index) {
            final coupon = coupons[index];
            return _buildCouponCard(context, ref, coupon, userId);
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
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(availableCouponsProvider(userId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoupons(BuildContext context, WidgetRef ref, String userId) {
    final userCoupons = ref.watch(userCouponsProvider(userId));

    return userCoupons.when(
      data: (coupons) {
        if (coupons.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('取得したクーポンがありません'),
                SizedBox(height: 8),
                Text('クーポンを取得してみましょう！'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coupons.length,
          itemBuilder: (context, index) {
            final userCoupon = coupons[index];
            return _buildUserCouponCard(context, ref, userCoupon);
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
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(userCouponsProvider(userId));
              },
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
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(promotionsProvider);
              },
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
                onPressed: () => _obtainCoupon(context, ref, coupon.id, userId),
              ),
            ),
          ],
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

  void _obtainCoupon(BuildContext context, WidgetRef ref, String couponId, String userId) async {
    try {
      await ref.read(couponProvider).obtainCoupon(userId, couponId);
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