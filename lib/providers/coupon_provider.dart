import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/coupon_model.dart';

// クーポンサービスプロバイダー
final couponProvider = Provider<CouponService>((ref) {
  return CouponService();
});

// 店舗のクーポン一覧プロバイダー
final storeCouponsProvider = StreamProvider.family<List<Coupon>, String>((ref, storeId) {
  final couponService = ref.watch(couponProvider);
  return couponService.getStoreCoupons(storeId)
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Store coupons provider error: $error');
    if (error.toString().contains('permission-denied')) {
      return <Coupon>[];
    }
    return <Coupon>[];
  });
});

// ユーザーのクーポン一覧プロバイダー
final userCouponsProvider = StreamProvider.family<List<UserCoupon>, String>((ref, userId) {
  final couponService = ref.watch(couponProvider);
  return couponService.getUserCoupons(userId)
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('User coupons provider error: $error');
    if (error.toString().contains('permission-denied')) {
      return <UserCoupon>[];
    }
    return <UserCoupon>[];
  });
});

// 利用可能なクーポン一覧プロバイダー
final availableCouponsProvider = StreamProvider.family<List<Coupon>, String>((ref, userId) {
  final couponService = ref.watch(couponProvider);
  return couponService.getAvailableCoupons(userId)
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Available coupons provider error: $error');
    if (error.toString().contains('permission-denied')) {
      return <Coupon>[];
    }
    return <Coupon>[];
  });
});

// プロモーション一覧プロバイダー
final promotionsProvider = StreamProvider<List<Promotion>>((ref) {
  final couponService = ref.watch(couponProvider);
  return couponService.getActivePromotions()
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Promotions provider error: $error');
    return <Promotion>[];
  });
});

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 店舗のクーポン一覧を取得
  Stream<List<Coupon>> getStoreCoupons(String storeId) {
    try {
      return _firestore
          .collection('coupons')
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Coupon.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting store coupons: $error');
        return <Coupon>[];
      });
    } catch (e) {
      debugPrint('Error getting store coupons: $e');
      return Stream.value([]);
    }
  }

  // ユーザーのクーポン一覧を取得
  Stream<List<UserCoupon>> getUserCoupons(String userId) {
    try {
      return _firestore
          .collection('user_coupons')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserCoupon.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting user coupons: $error');
        return <UserCoupon>[];
      });
    } catch (e) {
      debugPrint('Error getting user coupons: $e');
      return Stream.value([]);
    }
  }

  // 利用可能なクーポン一覧を取得
  Stream<List<Coupon>> getAvailableCoupons(String userId) {
    try {
      return _firestore
          .collection('coupons')
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Coupon.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting available coupons: $error');
        return <Coupon>[];
      });
    } catch (e) {
      debugPrint('Error getting available coupons: $e');
      return Stream.value([]);
    }
  }

  // アクティブなプロモーション一覧を取得
  Stream<List<Promotion>> getActivePromotions() {
    try {
      return _firestore
          .collection('promotions')
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Promotion.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting promotions: $error');
        return <Promotion>[];
      });
    } catch (e) {
      debugPrint('Error getting promotions: $e');
      return Stream.value([]);
    }
  }

  // クーポンを作成
  Future<void> createCoupon({
    required String storeId,
    required String title,
    required String description,
    required CouponType type,
    required double discountValue,
    required String discountType,
    required DateTime validFrom,
    required DateTime validUntil,
    required int usageLimit,
    required int minOrderAmount,
    String? imageUrl,
    List<String>? applicableItems,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      final couponData = {
        'storeId': storeId,
        'title': title,
        'description': description,
        'type': type.name,
        'discountValue': discountValue,
        'discountType': discountType,
        'validFrom': validFrom,
        'validUntil': validUntil,
        'usageLimit': usageLimit,
        'usedCount': 0,
        'minOrderAmount': minOrderAmount,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'applicableItems': applicableItems ?? [],
        'conditions': conditions ?? {},
        'usedBy': [],
      };

      await _firestore.collection('coupons').add(couponData);
    } catch (e) {
      debugPrint('Error creating coupon: $e');
      throw Exception('クーポンの作成に失敗しました: $e');
    }
  }

  // クーポンを取得
  Future<void> obtainCoupon(String userId, String couponId) async {
    try {
      // ユーザーがクーポンを既に取得していないかチェック
      final existingCoupon = await _firestore
          .collection('user_coupons')
          .where('userId', isEqualTo: userId)
          .where('couponId', isEqualTo: couponId)
          .get();

      if (existingCoupon.docs.isNotEmpty) {
        throw Exception('このクーポンは既に取得済みです');
      }

      // クーポンの詳細を取得
      final couponDoc = await _firestore.collection('coupons').doc(couponId).get();
      if (!couponDoc.exists) {
        throw Exception('クーポンが見つかりません');
      }

      final coupon = Coupon.fromJson({
        'id': couponDoc.id,
        ...couponDoc.data()!,
      });

      // クーポンが有効かチェック
      if (!coupon.isActive || coupon.validUntil.isBefore(DateTime.now())) {
        throw Exception('このクーポンは利用できません');
      }

      // 使用制限をチェック
      if (coupon.usedCount >= coupon.usageLimit) {
        throw Exception('このクーポンの配布は終了しました');
      }

      // ユーザーにクーポンを付与
      final userCouponData = {
        'userId': userId,
        'couponId': couponId,
        'obtainedAt': FieldValue.serverTimestamp(),
        'usedAt': null,
        'isUsed': false,
        'storeId': coupon.storeId,
        'orderId': null,
      };

      await _firestore.collection('user_coupons').add(userCouponData);
    } catch (e) {
      debugPrint('Error obtaining coupon: $e');
      throw Exception('クーポンの取得に失敗しました: $e');
    }
  }

  // クーポンを使用
  Future<void> useCoupon(String userCouponId, String orderId) async {
    try {
      await _firestore.collection('user_coupons').doc(userCouponId).update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
        'orderId': orderId,
      });

      // クーポンの使用回数を更新
      final userCouponDoc = await _firestore.collection('user_coupons').doc(userCouponId).get();
      if (userCouponDoc.exists) {
        final userCoupon = UserCoupon.fromJson({
          'id': userCouponDoc.id,
          ...userCouponDoc.data()!,
        });

        await _firestore.collection('coupons').doc(userCoupon.couponId).update({
          'usedCount': FieldValue.increment(1),
          'usedBy': FieldValue.arrayUnion([userCoupon.userId]),
        });
      }
    } catch (e) {
      debugPrint('Error using coupon: $e');
      throw Exception('クーポンの使用に失敗しました: $e');
    }
  }

  // プロモーションを作成
  Future<void> createPromotion({
    required String storeId,
    required String title,
    required String description,
    required PromotionType type,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    Map<String, dynamic>? conditions,
    List<String>? targetUsers,
  }) async {
    try {
      final promotionData = {
        'storeId': storeId,
        'title': title,
        'description': description,
        'type': type.name,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'conditions': conditions ?? {},
        'targetUsers': targetUsers ?? [],
        'viewCount': 0,
        'clickCount': 0,
      };

      await _firestore.collection('promotions').add(promotionData);
    } catch (e) {
      debugPrint('Error creating promotion: $e');
      throw Exception('プロモーションの作成に失敗しました: $e');
    }
  }

  // プロモーションの表示回数を更新
  Future<void> recordPromotionView(String promotionId) async {
    try {
      await _firestore.collection('promotions').doc(promotionId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error recording promotion view: $e');
    }
  }

  // プロモーションのクリック回数を更新
  Future<void> recordPromotionClick(String promotionId) async {
    try {
      await _firestore.collection('promotions').doc(promotionId).update({
        'clickCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error recording promotion click: $e');
    }
  }
}