import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon_model.dart' as model;
import '../providers/store_provider.dart';

class CouponListCard extends ConsumerWidget {
  const CouponListCard({
    super.key,
    required this.coupon,
    required this.userId,
    required this.isUsed,
    required this.onTap,
    this.storeNameOverride,
  });

  final model.Coupon coupon;
  final String userId;
  final bool isUsed;
  final VoidCallback onTap;
  final String? storeNameOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<int>>(
      future: _fetchStampStatus(coupon, userId),
      builder: (context, snapshot) {
        final requiredStamps = snapshot.data?[0] ?? 0;
        final userStamps = snapshot.data?[1] ?? 0;
        final remaining = requiredStamps - userStamps;
        final isInsufficient = requiredStamps > 0 && remaining > 0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: coupon.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                coupon.imageUrl!,
                                fit: BoxFit.cover,
                                width: 86,
                                height: 86,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.image,
                                    size: 32,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 32,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _buildStoreNameText(ref),
                          const SizedBox(height: 6),
                          Text(
                            _getDiscountLabel(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '有効期限: ${_formatCouponExpiry(coupon.validUntil)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(minWidth: 80, maxWidth: 96),
                      child: _buildStampCountBadge(requiredStamps, isUsed),
                    ),
                  ],
                ),
              ),
              if (isInsufficient)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _buildOutlinedWarningText('あと$remainingスタンプ'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoreNameText(WidgetRef ref) {
    final override = storeNameOverride;
    if (override != null && override.isNotEmpty) {
      return Text(
        override,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return ref.watch(storeNameProvider(coupon.storeId)).when(
          data: (storeName) => Text(
            storeName ?? '店舗名なし',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => Text(
            '読み込み中...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          error: (_, __) => Text(
            coupon.storeId,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
  }

  String _getDiscountLabel() {
    final discountType = coupon.discountType;
    final discountValue = coupon.discountValue;
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}% OFF';
    } else if (discountType == 'fixed_amount') {
      return '¥${discountValue.toInt()} OFF';
    } else if (discountType == 'fixed_price') {
      return '¥${discountValue.toInt()}';
    }
    return '特典あり';
  }

  Widget _buildStampCountBadge(int stampCount, bool isUsed) {
    final labelColor = isUsed ? Colors.grey[400] : const Color(0xFFFF6B35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: labelColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '必要スタンプ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '$stampCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedWarningText(String text) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<List<int>> _fetchStampStatus(
      model.Coupon coupon, String userId) async {
    final requiredStamps = await _fetchRequiredStampCount(coupon);
    final userStamps = await _fetchUserStampCount(userId, coupon.storeId);
    return [requiredStamps, userStamps];
  }

  Future<int> _fetchUserStampCount(String userId, String storeId) async {
    if (userId.isEmpty || userId == 'guest' || storeId.isEmpty) {
      return 0;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stores')
          .doc(storeId)
          .get();
      final data = doc.data();
      return (data?['stamps'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchRequiredStampCount(model.Coupon coupon) async {
    final localValue = coupon.conditions?['requiredStampCount'];
    if (localValue is num) {
      return localValue.toInt();
    }

    if (coupon.storeId.isEmpty || coupon.id.isEmpty) {
      return 0;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(coupon.storeId)
          .collection('coupons')
          .doc(coupon.id)
          .get();
      final data = doc.data();
      return (data?['requiredStampCount'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatCouponExpiry(DateTime date) {
    if (date.year >= 2100) return '無期限';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
