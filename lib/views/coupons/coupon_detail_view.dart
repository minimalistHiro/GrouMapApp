import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/coupon_model.dart' as model;
import '../../providers/coupon_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../providers/badge_provider.dart';

class CouponDetailView extends ConsumerStatefulWidget {
  final model.Coupon coupon;

  const CouponDetailView({Key? key, required this.coupon}) : super(key: key);

  @override
  ConsumerState<CouponDetailView> createState() => _CouponDetailViewState();
}

class _CouponDetailViewState extends ConsumerState<CouponDetailView> {
  bool _isStampInfoLoading = true;
  int _requiredStampCount = 0;
  int _userStampCount = 0;
  bool _isUsed = false;
  bool _isUsing = false;

  @override
  void initState() {
    super.initState();
    _incrementViewCount();
    _loadStampInfo();
  }

  bool get _isCoinExchangeCoupon =>
      widget.coupon.conditions != null &&
      widget.coupon.conditions!['coinExchange'] == true;

  // クーポン詳細を開いた際に閲覧数をインクリメント
  Future<void> _incrementViewCount() async {
    if (_isCoinExchangeCoupon) return;
    try {
      final storeId = widget.coupon.storeId;
      if (storeId.isEmpty) {
        return;
      }

      final couponRef = FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(widget.coupon.id);

      await couponRef.update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to increment coupon viewCount: $e');
    }
  }

  Future<void> _loadStampInfo() async {
    try {
      // coin_exchangeクーポンの場合はuser_couponsから使用済みチェックのみ
      if (_isCoinExchangeCoupon) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userCouponDoc = await FirebaseFirestore.instance
              .collection('user_coupons')
              .doc(widget.coupon.id)
              .get();
          if (userCouponDoc.exists) {
            final data = userCouponDoc.data();
            if (!mounted) return;
            setState(() {
              _isUsed = data?['isUsed'] as bool? ?? false;
              _isStampInfoLoading = false;
            });
            return;
          }
        }
        if (!mounted) return;
        setState(() {
          _isStampInfoLoading = false;
        });
        return;
      }

      final storeId = widget.coupon.storeId;
      final couponId = widget.coupon.id;
      if (storeId.isEmpty || couponId.isEmpty) {
        setState(() {
          _isStampInfoLoading = false;
        });
        return;
      }

      final couponDoc = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .get();
      final couponData = couponDoc.data();
      final requiredStampCount =
          (couponData?['requiredStampCount'] as num?)?.toInt() ?? 0;

      int userStamps = 0;
      bool isUsed = false;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userStoreDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('stores')
            .doc(storeId)
            .get();
        final userStoreData = userStoreDoc.data();
        userStamps = (userStoreData?['stamps'] as num?)?.toInt() ?? 0;

        // 使用済みチェック
        final usedCouponDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('used_coupons')
            .doc(couponId)
            .get();
        isUsed = usedCouponDoc.exists;
      }

      if (!mounted) return;
      setState(() {
        _requiredStampCount = requiredStampCount;
        _userStampCount = userStamps;
        _isUsed = isUsed;
        _isStampInfoLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requiredStampCount = 0;
        _userStampCount = 0;
        _isStampInfoLoading = false;
      });
    }
  }

  // クーポン使用処理
  Future<void> _useCoupon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クーポンを使用'),
        content: const Text('このクーポンを使用しますか？\n使用すると元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('使用する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUsing = true);

    try {
      // coin_exchangeクーポンの場合はuser_couponsを直接更新
      if (_isCoinExchangeCoupon) {
        await FirebaseFirestore.instance
            .collection('user_coupons')
            .doc(widget.coupon.id)
            .update({
          'isUsed': true,
          'usedAt': FieldValue.serverTimestamp(),
        });

        BadgeService().incrementBadgeCounter(user.uid, 'couponUsed');

        if (!mounted) return;
        setState(() {
          _isUsed = true;
          _isUsing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クーポンを使用しました')),
        );
        return;
      }

      final couponService = ref.read(couponProvider);
      await couponService.useCouponDirectly(
        user.uid,
        widget.coupon.id,
        widget.coupon.storeId,
      );

      // バッジカウンター: クーポン使用
      BadgeService().incrementBadgeCounter(user.uid, 'couponUsed');

      if (!mounted) return;
      setState(() {
        _isUsed = true;
        _isUsing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クーポンを使用しました')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUsing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  // ボタンが有効かどうかを判定
  bool get _canUseCoupon {
    if (_isUsed) return false;
    if (_isStampInfoLoading) return false;
    if (_isUsing) return false;
    if (FirebaseAuth.instance.currentUser == null) return false;
    if (widget.coupon.validUntil.year < 2100 &&
        widget.coupon.validUntil.isBefore(DateTime.now())) return false;
    if (!widget.coupon.noUsageLimit && widget.coupon.usedCount >= widget.coupon.usageLimit) return false;
    if (_requiredStampCount > 0 && _userStampCount < _requiredStampCount) {
      return false;
    }
    return true;
  }

  // ボタンのテキストを取得
  String get _buttonText {
    if (_isUsed) return '使用済み';
    if (_isStampInfoLoading) return '読み込み中...';
    if (FirebaseAuth.instance.currentUser == null) return 'ログインしてください';
    if (widget.coupon.validUntil.year < 2100 &&
        widget.coupon.validUntil.isBefore(DateTime.now())) return '有効期限切れ';
    if (!widget.coupon.noUsageLimit && widget.coupon.usedCount >= widget.coupon.usageLimit) return '配布終了';
    if (_requiredStampCount > 0 && _userStampCount < _requiredStampCount) {
      return 'スタンプ不足（あと${_requiredStampCount - _userStampCount}個）';
    }
    return '使用する';
  }

  // 有効期限の表示用フォーマット
  String _formatValidUntil() {
    try {
      if (widget.coupon.validUntil.year >= 2100) {
        return '無期限';
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final couponDate = DateTime(widget.coupon.validUntil.year, widget.coupon.validUntil.month, widget.coupon.validUntil.day);

      String dateText;
      if (couponDate.isAtSameMomentAs(today)) {
        dateText = '今日';
      } else if (couponDate.isAtSameMomentAs(tomorrow)) {
        dateText = '明日';
      } else {
        dateText = '${widget.coupon.validUntil.month}月${widget.coupon.validUntil.day}日';
      }

      return '$dateText ${widget.coupon.validUntil.hour.toString().padLeft(2, '0')}:${widget.coupon.validUntil.minute.toString().padLeft(2, '0')}まで';
    } catch (e) {
      return '期限不明';
    }
  }

  // 割引表示用テキスト
  String _getDiscountText() {
    final discountType = widget.coupon.discountType;
    final discountValue = widget.coupon.discountValue;

    if (discountType == 'percentage') {
      return '${discountValue.toInt()}%OFF';
    } else if (discountType == 'fixed_amount') {
      return '${discountValue.toInt()}円OFF';
    } else if (discountType == 'fixed_price') {
      return '${discountValue.toInt()}円';
    }
    return '特典あり';
  }

  // クーポンタイプのアイコンを取得
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: 'クーポン'),
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // クーポン画像ヘッダー
          _buildCouponHeader(),

          // クーポン基本情報
          _buildCouponInfo(),

          // クーポン詳細
          _buildCouponDetails(),

          // 店舗情報
          _buildStoreInfo(),

          // 注意事項
          _buildNotice(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: CustomButton(
            text: _buttonText,
            isLoading: _isUsing,
            onPressed: _canUseCoupon ? _useCoupon : null,
            backgroundColor: _isUsed ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCouponHeader() {
    // coin_exchangeクーポンの場合はローカルアセット画像を表示
    if (_isCoinExchangeCoupon) {
      return SliverToBoxAdapter(
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.asset(
            'assets/images/special_coupon_100yen.png',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFFFB300),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer, size: 80, color: Colors.white),
                      SizedBox(height: 8),
                      Text('100円OFF', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    final Widget imageContent = widget.coupon.imageUrl != null
        ? Image.network(
            widget.coupon.imageUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
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
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFFF6B35),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'クーポン画像なし',
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
            },
          )
        : Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFFF6B35),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'クーポン画像なし',
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
    return SliverToBoxAdapter(
      child: AspectRatio(
        aspectRatio: 1,
        child: imageContent,
      ),
    );
  }

  Widget _buildCouponInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              widget.coupon.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 説明
            Text(
              widget.coupon.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // 必要スタンプ数（目立つ表示）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    _isStampInfoLoading
                        ? '必要スタンプ: 読み込み中...'
                        : '必要スタンプ: $_requiredStampCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 割引情報とタイプ
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 割引情報
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getDiscountText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),

                // クーポンタイプ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCouponIcon(widget.coupon.type),
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCouponTypeText(widget.coupon.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponDetails() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'クーポン詳細',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 有効期限
            _buildDetailRow(
              icon: Icons.access_time,
              label: '有効期限',
              value: _formatValidUntil(),
              valueColor: Colors.red[700]!,
            ),
            const SizedBox(height: 12),

            // 必要スタンプ数
            _buildDetailRow(
              icon: Icons.stars,
              label: '必要スタンプ',
              value: _isStampInfoLoading ? '読み込み中...' : '$_requiredStampCount',
              valueColor: Colors.orange[700]!,
            ),
            const SizedBox(height: 12),

            // 現在のスタンプ数
            _buildDetailRow(
              icon: Icons.verified,
              label: '現在のスタンプ',
              value: _isStampInfoLoading ? '読み込み中...' : '$_userStampCount',
              valueColor: Colors.blueGrey[700]!,
            ),
            const SizedBox(height: 12),

            // 残り枚数
            if (!widget.coupon.noUsageLimit) ...[
              _buildDetailRow(
                icon: Icons.inventory,
                label: '残り枚数',
                value: '${widget.coupon.usageLimit - widget.coupon.usedCount}枚',
                valueColor: Colors.green[700]!,
              ),
              const SizedBox(height: 12),
            ],

            // 作成日
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: '作成日',
              value: '${widget.coupon.createdAt.year}/${widget.coupon.createdAt.month.toString().padLeft(2, '0')}/${widget.coupon.createdAt.day.toString().padLeft(2, '0')}',
              valueColor: Colors.grey[700]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '店舗情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            ref.watch(storeNameProvider(widget.coupon.storeId)).when(
              data: (storeName) => _buildDetailRow(
                icon: Icons.store,
                label: '店舗名',
                value: storeName ?? '店舗名なし',
                valueColor: Colors.black87,
              ),
              loading: () => _buildDetailRow(
                icon: Icons.store,
                label: '店舗名',
                value: '読み込み中...',
                valueColor: Colors.grey,
              ),
              error: (_, __) => _buildDetailRow(
                icon: Icons.store,
                label: '店舗名',
                value: '店舗名なし',
                valueColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 20),
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'クーポンは画面下部の「使用する」ボタンから利用できます。店舗スタッフに画面を見せてご利用ください。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getCouponTypeText(model.CouponType type) {
    switch (type) {
      case model.CouponType.discount:
        return '割引';
      case model.CouponType.freeShipping:
        return '送料無料';
      case model.CouponType.buyOneGetOne:
        return '買い得';
      case model.CouponType.cashback:
        return 'キャッシュバック';
      case model.CouponType.pointsMultiplier:
        return 'ポイント倍増';
    }
  }
}
