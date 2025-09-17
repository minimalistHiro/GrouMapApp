import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/coupon_model.dart' as model;
import '../../providers/store_provider.dart';
import '../../widgets/custom_button.dart';

class CouponDetailView extends ConsumerStatefulWidget {
  final model.Coupon coupon;

  const CouponDetailView({Key? key, required this.coupon}) : super(key: key);

  @override
  ConsumerState<CouponDetailView> createState() => _CouponDetailViewState();
}

class _CouponDetailViewState extends ConsumerState<CouponDetailView> {
  bool _isUsing = false;
  bool _isUsed = false;

  @override
  void initState() {
    super.initState();
    _checkIfUsed();
  }

  // クーポンを既に使用しているかチェック
  Future<void> _checkIfUsed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final couponDoc = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(widget.coupon.id)
          .get();

      if (couponDoc.exists) {
        final data = couponDoc.data() as Map<String, dynamic>;
        final usedBy = data['usedBy'] as List<dynamic>? ?? [];
        
        setState(() {
          _isUsed = usedBy.contains(user.uid);
        });
      }
    } catch (e) {
      print('クーポン使用状態確認エラー: $e');
    }
  }

  // クーポンを使用する
  Future<void> _useCoupon() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        _isUsing = true;
      });

      // クーポンの使用確認ポップアップを表示
      final confirmed = await _showUseConfirmationDialog();
      if (!confirmed) {
        setState(() {
          _isUsing = false;
        });
        return;
      }

      // クーポンのusedByリストにユーザーIDを追加
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(widget.coupon.id)
          .update({
        'usedBy': FieldValue.arrayUnion([user.uid]),
        'usageCount': FieldValue.increment(1),
      });

      setState(() {
        _isUsed = true;
        _isUsing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('クーポンを使用しました！'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUsing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // クーポン使用確認ダイアログを表示
  Future<bool> _showUseConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: const Color(0xFFFF6B35),
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('クーポンを使用'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.coupon.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'このクーポンを使用しますか？',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '使用後は取り消すことができません。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              child: const Text('使用する'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 有効期限の表示用フォーマット
  String _formatValidUntil() {
    try {
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
          
          // 使用ボタン
          _buildUseButton(),
        ],
      ),
    );
  }

  Widget _buildCouponHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFFFF6B35),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          width: double.infinity,
          height: 300,
          child: widget.coupon.imageUrl != null
              ? Image.network(
                  widget.coupon.imageUrl!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 300,
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
                      height: 300,
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
                  height: 300,
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
                ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
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
            
            // 割引情報とタイプ
            Row(
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
                const SizedBox(width: 12),
                
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
            
            // 使用制限
            _buildDetailRow(
              icon: Icons.people,
              label: '使用制限',
              value: '${widget.coupon.usageLimit}枚まで',
              valueColor: Colors.grey[700]!,
            ),
            const SizedBox(height: 12),
            
            // 残り枚数
            _buildDetailRow(
              icon: Icons.inventory,
              label: '残り枚数',
              value: '${widget.coupon.usageLimit - widget.coupon.usedCount}枚',
              valueColor: Colors.green[700]!,
            ),
            const SizedBox(height: 12),
            
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

  Widget _buildUseButton() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 20),
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_isUsed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'クーポン使用済み',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              CustomButton(
                text: _isUsing ? '使用中...' : 'クーポンを使用',
                onPressed: _isUsing ? null : _useCoupon,
                backgroundColor: const Color(0xFFFF6B35),
                textColor: Colors.white,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // 注意事項
            Container(
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
                      'クーポンは店舗で提示してご利用ください。\n有効期限を過ぎたクーポンは使用できません。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
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
