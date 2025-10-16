import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/store_provider.dart';
import '../widgets/custom_button.dart';
import 'auth/welcome_view.dart';
import 'notifications/notifications_view.dart';
import 'points/points_view.dart';
import 'ranking/leaderboard_view.dart';
import 'stores/store_list_view.dart';
import 'stamps/stamp_cards_view.dart';
import 'referral/friend_referral_view.dart';
import 'referral/store_referral_view.dart';
import 'feedback/feedback_view.dart';
import 'posts/post_detail_view.dart';
import 'coupons/coupon_detail_view.dart';
import 'badges/badges_view.dart';

// ユーザーデータプロバイダー（usersコレクションから直接取得）
final userDataProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  try {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).handleError((error) {
      debugPrint('Error fetching user data: $error');
      return null;
    });
  } catch (e) {
    debugPrint('Error creating user data stream: $e');
    return Stream.value(null);
  }
});

class HomeView extends ConsumerWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // ログイン済みの場合は新しいホーム画面を表示
          return _buildHomeContent(context, ref, user.uid);
        } else {
          // 未ログインの場合はウェルカム画面を表示
          return const WelcomeView();
        }
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
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
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(authStateProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, WidgetRef ref, String userId) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ヘッダー部分
              _buildHeader(context, ref, userId),
              
              const SizedBox(height: 24),
              
              // カード部分
              _buildStatsCard(context, ref, userId),
              
              const SizedBox(height: 24),
              
              // その他のコンテンツ
              _buildAdditionalContent(context, ref, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String userId) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 左側：アプリアイコン&サービス名（固定幅）
          SizedBox(
            width: 120, // 固定幅を設定
            child: Row(
              children: [
                Image.asset(
                  'assets/images/groumap_icon.png',
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.location_on, size: 30, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GrouMap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // 中央：ユーザーアイコンと円形経験値バー
          Expanded(
            child: Center(
              child: ref.watch(userDataProvider(userId)).when(
                data: (userData) {
                  if (userData == null) {
                    return const SizedBox.shrink();
                  }
                  
                  final level = userData['level'] ?? 1;
                  final experience = userData['experience'] ?? 0;
                  final profileImageUrl = userData['profileImageUrl'] as String?;
                  
                  // 現在のレベルの経験値計算
                  final currentLevelExp = experience;
                  final currentLevelRequiredExp = level * 100; // 現在のレベルに必要な経験値
                  final progressValue = currentLevelExp > currentLevelRequiredExp 
                      ? 1.0 
                      : (currentLevelExp - (level - 1) * 100) / 100.0;
                  
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // 円形の経験値バー（周囲に余白を確保）
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: progressValue.clamp(0.0, 1.0),
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                          ),
                        ),
                        // ユーザーアイコン
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF6B35),
                              width: 2,
                            ),
                          ),
                          child: profileImageUrl != null && profileImageUrl.isNotEmpty
                              ? ClipOval(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: Image.network(
                                      profileImageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              : ClipOval(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                        // レベル表示（はみ出しを許容してクリップしない）
                        Positioned(
                          bottom: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Lv.$level',
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
                  );
                },
                loading: () => const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                    strokeWidth: 2,
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          
          // 右側：お知らせのベルボタン（固定幅）
          SizedBox(
            width: 60, // 固定幅を設定
            child: IconButton(
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 28,
                    color: Colors.black87,
                  ),
                  // 未読通知のバッジ（readNotificationsフィールドと比較）
                  ref.watch(userDataProvider(userId)).when(
                    data: (userData) {
                      if (userData == null) return const SizedBox.shrink();
                      
                      final readNotifications = List<String>.from(userData['readNotifications'] ?? []);
                      
                      return ref.watch(announcementsProvider).when(
                        data: (announcements) {
                          // 未読のお知らせ数を計算
                          final unreadCount = announcements.where((announcement) => 
                            !readNotifications.contains(announcement['id'])
                          ).length;
                          
                          if (unreadCount > 0) {
                            return Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsView(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, String userId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 獲得ポイント（画像のような表記に変更）
          ref.watch(userDataProvider(userId)).when(
            data: (userData) {
              if (userData != null) {
                final points = userData['points'] ?? 0;
                final String pointsText = '$points';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '獲得ポイント',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: pointsText,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.0,
                            ),
                            children: const [
                              TextSpan(
                                text: '  pt',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          tooltip: '更新',
                          onPressed: () {
                            ref.invalidate(userDataProvider(userId));
                          },
                          icon: const Icon(Icons.refresh, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 16),
          
          // ポイント、バッジ、総支払額のカード
          ref.watch(userDataProvider(userId)).when(
            data: (userData) {
              if (userData != null) {
                final points = userData['points'] ?? 0;
                final badgeCount = userData['badges']?.length ?? 0;
                final dynamic paidRaw = userData['paid'];
                final num paidNum = paidRaw is num ? paidRaw : num.tryParse('$paidRaw') ?? 0;
                final String paidFormatted = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0).format(paidNum);
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 左：ポイント
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/point_icon.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.monetization_on, size: 24, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$points',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  'ポイント',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 仕切り
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      
                      // 中：バッジ
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/badge_icon.PNG',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.military_tech, color: Colors.amber, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$badgeCount',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  'バッジ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 仕切り
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      
                      // 右：総支払額
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/bills_icon.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.receipt_long, size: 24, color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paidFormatted,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  '総支払額',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
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
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalContent(BuildContext context, WidgetRef ref, String userId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // メニューグリッド
          _buildMenuGrid(context, ref, userId),
          
          const SizedBox(height: 20),
          
          // クーポンセクション
          _buildCouponSection(context, ref, userId),
          
          const SizedBox(height: 20),
          
          // 投稿セクション
          _buildPostSection(context, ref, userId),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, WidgetRef ref, String userId) {
    final menuItems = [
      {'icon': 'assets/images/point_icon.png', 'label': 'ポイント履歴', 'isImage': true},
      {'icon': 'assets/images/gold_coin_icon2.png', 'label': 'スタンプ', 'isImage': true},
      {'icon': 'assets/images/badge_icon.PNG', 'label': 'バッジ', 'isImage': true},
      {'icon': 'assets/images/store_icon.png', 'label': '店舗一覧', 'isImage': true},
      {'icon': 'assets/images/trophy_icon.png', 'label': 'ランキング', 'isImage': true},
      {'icon': 'assets/images/friend_intro_icon.png', 'label': '友達紹介', 'isImage': true},
      {'icon': 'assets/images/store_icon.png', 'label': '店舗紹介', 'isImage': true},
      {'icon': 'assets/images/chats_icon.png', 'label': 'フィードバック', 'isImage': true},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 画面幅に基づいてアイコンサイズとグリッドサイズを動的に調整
            final iconSize = 24.0; // メニューアイコンをステータスカードと同じサイズに固定
            final fontSize = 12.0; // メニューテキストは固定サイズ
            
            // より安定したアスペクト比の計算
            final itemHeight = 120.0; // 固定の高さを使用
            final aspectRatio = constraints.maxWidth / (itemHeight * 2);
            
            return GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: aspectRatio,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: menuItems.map((item) => _buildMenuButton(
                context,
                item['label'] as String,
                item['icon'] as String,
                true, // isLogin
                isImage: item['isImage'] as bool,
                iconSize: iconSize,
                fontSize: fontSize,
              )).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context, WidgetRef ref, String userId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                'クーポン',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // クーポン一覧画面に遷移
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: ref.watch(availableCouponsProvider(userId)).when(
            data: (coupons) {
              if (coupons.isEmpty) {
                return const Center(
                  child: Text(
                    '利用可能なクーポンがありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  return _buildCouponCard(context, ref, coupon);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
            error: (error, _) => const Center(
              child: Text(
                'クーポンの取得に失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostSection(BuildContext context, WidgetRef ref, String userId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                '店舗からのお知らせ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // 投稿一覧画面に遷移
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: ref.watch(allPostsProvider).when(
            data: (posts) {
              if (posts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        '投稿がありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostCard(context, post);
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
                      fontSize: 12,
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
                      fontSize: 14,
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
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(BuildContext context, WidgetRef ref, dynamic coupon) {
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
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 5),
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
            // 画像
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: coupon.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        coupon.imageUrl,
                        width: 150,
                        height: 150,
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
              child: ref.watch(storeNameProvider(coupon.storeId)).when(
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
                  coupon.storeId ?? '店舗名なし',
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }

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

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailView(post: post),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 5),
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
            // 画像
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: post.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        post.imageUrls[0],
                        width: 150,
                        height: 150,
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
            
            // カテゴリバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                post.category ?? 'お知らせ',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 5),
            
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            const Divider(),
            
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post.storeName ?? '店舗名なし',
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 5),
            
            // 投稿日
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatDate(),
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, dynamic icon, bool isLogin, {bool isImage = false, double? iconSize, double? fontSize}) {
    return GestureDetector(
      onTap: () {
        if (!isLogin) {
          // ログインしていない場合はログイン画面に遷移
          Navigator.of(context).pushNamed('/signin');
          return;
        }

        if (title == 'ポイント履歴') {
          // ポイント履歴画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PointsView(),
            ),
          );
        } else if (title == 'スタンプ') {
          // スタンプカード一覧画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StampCardsView(),
            ),
          );
        } else if (title == 'バッジ') {
          // バッジ一覧画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BadgesView(),
            ),
          );
        } else if (title == '店舗一覧') {
          // 店舗一覧画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StoreListView(),
            ),
          );
        } else if (title == 'ランキング') {
          // ランキング画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LeaderboardView(),
            ),
          );
        } else if (title == '友達紹介') {
          // 友達紹介画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FriendReferralView(),
            ),
          );
        } else if (title == '店舗紹介') {
          // 店舗紹介画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StoreReferralView(),
            ),
          );
        } else if (title == 'フィードバック') {
          // フィードバック画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FeedbackView(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: isImage
                  ? Image.asset(
                      icon,
                      width: iconSize ?? 24,
                      height: iconSize ?? 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.monetization_on,
                          size: iconSize ?? 24,
                          color: isLogin ? const Color(0xFFFF6B35) : Colors.grey,
                        );
                      },
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      size: iconSize ?? 24,
                      color: isLogin ? const Color(0xFFFF6B35) : Colors.grey,
                    ),
            ),
            SizedBox(height: (iconSize ?? 24) * 0.15),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontSize ?? 10,
                  fontWeight: FontWeight.bold,
                  color: isLogin ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotLoggedInView(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴ
            Image.asset(
              'assets/images/groumap_icon.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.location_on, size: 200, color: Colors.blue),
            ),
            
            const SizedBox(height: 32),
            
            // アプリ名
            const Text(
              'GrouMap',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // サブタイトル
            const Text(
              '近くの店舗を見つけて、ポイントを獲得しよう！',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // 機能説明
            _buildFeatureCard(
              icon: Icons.map,
              title: '地図で店舗検索',
              description: '現在地から近くの店舗を簡単に見つけられます',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.qr_code,
              title: 'QRコードでポイント獲得',
              description: '店舗でQRコードをスキャンしてポイントを獲得',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.card_giftcard,
              title: 'ポイントでお得に',
              description: '獲得したポイントで商品を割引価格で購入',
            ),
            
            const SizedBox(height: 48),
            
            // ログインボタン
            CustomButton(
              text: 'ログイン',
              onPressed: () {
                Navigator.of(context).pushNamed('/signin');
              },
            ),
            
            const SizedBox(height: 16),
            
            // 新規登録ボタン
            CustomButton(
              text: '新規登録',
              onPressed: () {
                Navigator.of(context).pushNamed('/signup');
              },
              backgroundColor: Colors.white,
              textColor: Colors.blue,
              borderColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
