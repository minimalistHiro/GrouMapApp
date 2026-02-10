import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../providers/posts_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../models/coupon_model.dart' as model;
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/coupon_list_card.dart';
import '../../widgets/custom_top_tab_bar.dart';
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
  bool _isFavorite = false;
  bool _isFavoriteLoading = true;
  bool _isUpdatingFavorite = false;
  bool _isBusinessHoursExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (kDebugMode) {
      debugPrint(
        'StoreDetailView: storeId=${widget.store['id']} '
        'iconImageUrl=${widget.store['iconImageUrl']} '
        'storeImageUrl=${widget.store['storeImageUrl']} '
        'backgroundImageUrl=${widget.store['backgroundImageUrl']}',
      );
    }
    _loadUserStamps();
    _loadFavoriteStatus();
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

  Future<void> _loadFavoriteStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      final favoriteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorite_stores')
          .doc(widget.store['id'])
          .get();
      if (!mounted) return;
      setState(() {
        _isFavorite = favoriteDoc.exists;
      });
    } catch (e) {
      print('お気に入り状態の読み込みに失敗しました: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isFavoriteLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        _isUpdatingFavorite = true;
      });

      final storeId = widget.store['id'];
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final favoriteDocRef =
          userDocRef.collection('favorite_stores').doc(storeId);
      final storeFavoriteDocRef = FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('favorite_users')
          .doc(user.uid);

      final batch = FirebaseFirestore.instance.batch();

      if (_isFavorite) {
        batch.delete(favoriteDocRef);
        batch.delete(storeFavoriteDocRef);
        batch.set(
          userDocRef,
          {
            'favoriteStoreIds': FieldValue.arrayRemove([storeId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(favoriteDocRef, {
          'storeId': storeId,
          'storeName': widget.store['name'],
          'category': widget.store['category'],
          'storeImageUrl': widget.store['storeImageUrl'],
          'favoritedAt': FieldValue.serverTimestamp(),
        });
        batch.set(storeFavoriteDocRef, {
          'userId': user.uid,
          'userName': user.displayName ?? '匿名ユーザー',
          'favoritedAt': FieldValue.serverTimestamp(),
        });
        batch.set(
          userDocRef,
          {
            'favoriteStoreIds': FieldValue.arrayUnion([storeId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      print('お気に入り更新エラー: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('お気に入りの更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdatingFavorite = false;
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
    final storeName = _getStringValue(widget.store['name'], '店舗詳細');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CommonHeader(title: storeName),
      body: Column(
        children: [
          CustomTopTabBar(
            tabs: const [
              Tab(text: 'トップ'),
              Tab(text: '店内'),
              Tab(text: 'メニュー'),
              Tab(text: '投稿'),
            ],
            controller: _tabController,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopTab(),
                _buildInteriorTab(),
                _buildMenuTab(),
                _buildInstagramPostsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreHeaderBanner(),
          _buildStoreInfo(),
          _buildStampCard(),
          _buildStoreCouponsSection(),
          _buildStorePostsSection(),
          _buildStoreDetailsContent(),
        ],
      ),
    );
  }

  Future<void> _openCouponDetail(
      BuildContext context, model.Coupon coupon) async {
    final storeId = coupon.storeId;
    if (storeId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('coupons')
            .doc(storeId)
            .collection('coupons')
            .doc(coupon.id)
            .get();
        if (doc.exists && doc.data() != null) {
          final storeCoupon = model.Coupon.fromFirestore(doc.data()!, doc.id);
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CouponDetailView(coupon: storeCoupon),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error loading store coupon: $e');
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CouponDetailView(coupon: coupon),
      ),
    );
  }

  Widget _buildInteriorTab() {
    final storeId = widget.store['id'];
    if (storeId == null) {
      return const Center(
        child: Text('店舗情報が取得できませんでした。'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('interior_images')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('店内画像の取得に失敗しました。'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final items = docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();

        items.sort((a, b) {
          final aOrder = _parseSortOrder(a['sortOrder']);
          final bOrder = _parseSortOrder(b['sortOrder']);
          final aHasOrder = aOrder > 0;
          final bHasOrder = bOrder > 0;

          if (aHasOrder && bHasOrder) {
            return aOrder.compareTo(bOrder);
          }
          if (aHasOrder != bHasOrder) {
            return aHasOrder ? -1 : 1;
          }

          final aCreated = _parseCreatedAtMillis(a['createdAt']);
          final bCreated = _parseCreatedAtMillis(b['createdAt']);
          return aCreated.compareTo(bCreated);
        });

        if (items.isEmpty) {
          return const Center(
            child: Text('店内画像はまだありません。'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final imageUrl = item['imageUrl'] as String? ?? '';
            final caption = item['caption'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[100],
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      caption,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _parseSortOrder(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _parseCreatedAtMillis(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  Widget _buildStoreHeaderBanner() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: _buildStoreBackground(),
    );
  }

  // 店舗背景画像を構築
  Widget _buildStoreBackground() {
    // 両方のフィールド名をサポート
    final backgroundImageUrl =
        _getStringValue(widget.store['backgroundImageUrl'], '');
    final storeImageUrl = _getStringValue(widget.store['storeImageUrl'], '');
    final imageUrl =
        backgroundImageUrl.isNotEmpty ? backgroundImageUrl : storeImageUrl;

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
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
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
    final String category = _getStringValue(widget.store['category'], 'その他');
    final String subCategory = _getStringValue(widget.store['subCategory'], '');
    final String description = _getStringValue(widget.store['description'], '');
    final bool hasSubCategory =
        subCategory.isNotEmpty && subCategory != category;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 店舗アイコン
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getCategoryColor(category).withOpacity(0.3),
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: (_isFavoriteLoading || _isUpdatingFavorite)
                              ? null
                              : _toggleFavorite,
                          icon: Icon(
                            _isFavorite ? Icons.star : Icons.star_border,
                            color:
                                _isFavorite ? Colors.amber[700] : Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: _isFavorite ? 'お気に入り解除' : 'お気に入り登録',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isFavorite ? 'お気に入り登録済み' : 'お気に入り',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isFavorite
                                ? Colors.amber[700]
                                : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBusinessStatusChip(),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  _getCategoryColor(category).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getCategoryColor(category),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (hasSubCategory) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  _getCategoryColor(category).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getCategoryColor(category)
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              subCategory,
                              style: TextStyle(
                                fontSize: 14,
                                color: _getCategoryColor(category),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '店舗説明',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBusinessStatusChip() {
    final businessHours =
        widget.store['businessHours'] as Map<String, dynamic>?;
    if (businessHours == null) {
      return const SizedBox.shrink();
    }

    final statusInfo = _getBusinessStatus(businessHours);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusInfo.color.withOpacity(0.4)),
      ),
      child: Text(
        statusInfo.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusInfo.color,
        ),
      ),
    );
  }

  Widget _buildStampCard() {
    if (_isLoadingStamps) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    }

    final stamps = _userStamps?['stamps'] ?? 0;

    return Container(
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
    );
  }

  Widget _buildStoreCouponsSection() {
    final storeId = _getStringValue(widget.store['id'], '');
    if (storeId.isEmpty) {
      return const SizedBox.shrink();
    }

    final storeName = _getStringValue(widget.store['name'], '店舗名なし');
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final availableCoupons = ref.watch(availableCouponsProvider(userId));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'クーポン',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          availableCoupons.when(
            data: (coupons) {
              final storeCoupons =
                  coupons.where((coupon) => coupon.storeId == storeId).toList();
              if (storeCoupons.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('利用可能なクーポンがありません'),
                        SizedBox(height: 8),
                        Text('新しいクーポンをお待ちください！'),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: storeCoupons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final coupon = storeCoupons[index];
                  return CouponListCard(
                    coupon: coupon,
                    userId: userId,
                    isUsed: false,
                    storeNameOverride: storeName,
                    onTap: () => _openCouponDetail(context, coupon),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
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
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text(
                      'データの取得に失敗しました',
                      style: TextStyle(
                        fontSize: 16,
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
            ),
          ),
        ],
      ),
    );
  }

  void _openPostsTab() {
    if (!_tabController.indexIsChanging && _tabController.index == 3) {
      return;
    }
    _tabController.animateTo(3);
  }

  Widget _buildStorePostsSection() {
    final storeId = _getStringValue(widget.store['id'], '');
    if (storeId.isEmpty) {
      return const SizedBox.shrink();
    }

    final storePosts = ref.watch(storeInstagramPostsProvider(storeId));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '投稿',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openPostsTab,
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          storePosts.when(
            data: (posts) {
              if (posts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
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
                  ),
                );
              }

              final latestPosts = [...posts]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final previewPosts = latestPosts.take(15).toList();

              return GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemCount: previewPosts.length,
                itemBuilder: (context, index) {
                  final post = previewPosts[index];
                  return _buildInstagramPostCard(context, post);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
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
            ),
            error: (error, _) => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      '投稿の取得に失敗しました',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramPostsTab() {
    final storeId = widget.store['id'];
    if (storeId == null || storeId.toString().isEmpty) {
      return const Center(
        child: Text('店舗情報が取得できませんでした。'),
      );
    }

    final posts = ref.watch(storeInstagramPostsProvider(storeId));

    return posts.when(
      data: (posts) {
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

        return GridView.builder(
          padding: const EdgeInsets.all(2),
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
      error: (error, _) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '投稿の取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return SingleChildScrollView(
      child: Container(
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
      ),
    );
  }

  Widget _buildStoreDetailsContent() {
    final displayAddress = _getDisplayAddress();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 住所
          if (displayAddress.isNotEmpty) ...[
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
                    displayAddress,
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
            _buildBusinessHoursDisplay(),
            const SizedBox(height: 16),
          ],

          // タグ
          if (widget.store['tags'] != null &&
              (widget.store['tags'] as List).isNotEmpty) ...[
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
              children: (widget.store['tags'] as List)
                  .map<Widget>((tag) => Chip(
                        label: Text(tag.toString()),
                        backgroundColor:
                            const Color(0xFFFF6B35).withOpacity(0.1),
                        labelStyle: const TextStyle(fontSize: 12),
                      ))
                  .toList(),
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

  String _getDisplayAddress() {
    final addressValue = widget.store['address'];
    if (addressValue is String && addressValue.trim().isNotEmpty) {
      final trimmed = addressValue.trim();
      if (!_looksLikeCoordinates(trimmed)) {
        return trimmed;
      }
    }
    if (addressValue is Map) {
      final map = addressValue.cast<String, dynamic>();
      final candidates = [
        map['address'],
        map['formattedAddress'],
        map['fullAddress'],
      ];
      for (final candidate in candidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          final trimmed = candidate.trim();
          if (!_looksLikeCoordinates(trimmed)) {
            return trimmed;
          }
        }
      }
    }
    final locationValue = widget.store['location'];
    if (locationValue is Map) {
      final address =
          locationValue['address'] ?? locationValue['formattedAddress'];
      if (address is String && address.trim().isNotEmpty) {
        final trimmed = address.trim();
        if (!_looksLikeCoordinates(trimmed)) {
          return trimmed;
        }
      }
    }
    return '';
  }

  bool _looksLikeCoordinates(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('latitude') ||
        lower.contains('longitude') ||
        lower.contains('geopoint')) {
      return true;
    }
    final coordPattern = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');
    return coordPattern.hasMatch(value);
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
          // 画像読み込みの設定
          isAntiAlias: true,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: _getCategoryColor(category),
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('店舗アイコン画像の読み込みエラー: $error / url=$iconImageUrl');
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

  // 営業時間表示を構築
  Widget _buildBusinessHoursDisplay() {
    final businessHours =
        widget.store['businessHours'] as Map<String, dynamic>?;
    if (businessHours == null) return const SizedBox.shrink();

    final statusInfo = _getBusinessStatus(businessHours);
    final dayNames = {
      'monday': '月',
      'tuesday': '火',
      'wednesday': '水',
      'thursday': '木',
      'friday': '金',
      'saturday': '土',
      'sunday': '日',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '営業時間',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isBusinessHoursExpanded = !_isBusinessHoursExpanded;
                });
              },
              icon: Icon(
                _isBusinessHoursExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Colors.grey[700],
              ),
              tooltip: _isBusinessHoursExpanded ? '閉じる' : '開く',
            ),
          ],
        ),
        if (_isBusinessHoursExpanded)
          Container(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFFF6B35).withOpacity(0.1)
                        : Colors.transparent,
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
                              color:
                                  isOpen ? Colors.green[600] : Colors.red[600],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOpen ? '$openTime - $closeTime' : '定休日',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isOpen ? Colors.black87 : Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 今日のマーク
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusInfo.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusInfo.color.withOpacity(0.4)),
              ),
              child: Text(
                statusInfo.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusInfo.color,
                ),
              ),
            ),
          ),
      ],
    );
  }

  ({String label, Color color}) _getBusinessStatus(
    Map<String, dynamic> businessHours,
  ) {
    final dayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final now = DateTime.now();
    final dayKey = dayKeys[now.weekday - 1];
    final dayData = businessHours[dayKey] as Map<String, dynamic>?;
    if (dayData == null) {
      return (label: '営業時間外', color: Colors.red);
    }

    final isOpen = _getBoolValue(dayData['isOpen'], false);
    if (!isOpen) {
      return (label: '営業時間外', color: Colors.red);
    }

    final openTime = _getStringValue(dayData['open'], '');
    final closeTime = _getStringValue(dayData['close'], '');
    final openDateTime = _parseTimeForToday(openTime, now);
    final closeDateTime = _parseTimeForToday(closeTime, now);
    if (openDateTime == null || closeDateTime == null) {
      return (label: '営業時間外', color: Colors.red);
    }

    var start = openDateTime;
    var end = closeDateTime;
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    if (now.isAfter(start) && now.isBefore(end)) {
      final remaining = end.difference(now);
      if (remaining <= const Duration(hours: 1)) {
        return (label: 'まもなく営業終了', color: Colors.amber[700]!);
      }
      return (label: '営業中', color: Colors.green[700]!);
    }

    if (now.isBefore(start)) {
      final untilOpen = start.difference(now);
      if (untilOpen <= const Duration(hours: 1)) {
        return (label: 'まもなく営業開始', color: Colors.amber[700]!);
      }
      return (label: '営業時間外', color: Colors.red);
    }

    return (label: '営業時間外', color: Colors.red);
  }

  DateTime? _parseTimeForToday(String time, DateTime now) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // SNS・ウェブサイト表示を構築
  Widget _buildSocialMediaDisplay() {
    final socialMedia = widget.store['socialMedia'] as Map<String, dynamic>?;
    if (socialMedia == null) return const SizedBox.shrink();

    final List<Widget> socialItems = [];

    if (_getStringValue(socialMedia['website'], '').isNotEmpty) {
      socialItems.add(
          _buildSocialItem('ウェブサイト', socialMedia['website'], Icons.language));
    }
    if (_getStringValue(socialMedia['instagram'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem(
          'Instagram', socialMedia['instagram'], Icons.camera_alt));
    }
    if (_getStringValue(socialMedia['x'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem(
          'X (Twitter)', socialMedia['x'], Icons.flutter_dash));
    }
    if (_getStringValue(socialMedia['facebook'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem(
          'Facebook', socialMedia['facebook'], Icons.facebook));
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
    final isInstagram = post.source == 'instagram';
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                  if (!isInstagram)
                    FutureBuilder<int>(
                      future: _getLikeCount(post.id),
                      builder: (context, snapshot) {
                        final likeCount = snapshot.data ?? 0;
                        if (likeCount > 0) {
                          return Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
}
