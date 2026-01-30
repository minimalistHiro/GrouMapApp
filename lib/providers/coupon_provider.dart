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
    return <Coupon>[];
  });
});

// 店舗配下のクーポン一覧プロバイダー（coupons/{storeId}/coupons）
final storeCouponsNestedProvider = StreamProvider.family<List<Coupon>, String>((ref, storeId) {
  final couponService = ref.watch(couponProvider);
  return couponService.getStoreCouponsNested(storeId)
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Store coupons nested provider error: $error');
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

// 使用済みクーポン一覧プロバイダー
final usedCouponsProvider = StreamProvider.family<List<Coupon>, String>((ref, userId) {
  final couponService = ref.watch(couponProvider);
  return couponService.getUsedCoupons(userId)
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Used coupons provider error: $error');
    if (error.toString().contains('permission-denied')) {
      return <Coupon>[];
    }
    return <Coupon>[];
  });
});

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 店舗のクーポン一覧を取得（公開クーポン）
  Stream<List<Coupon>> getStoreCoupons(String storeId) {
    try {
      return _firestore
          .collection('public_coupons')
          .where('storeId', isEqualTo: storeId)
          .snapshots()
          .timeout(const Duration(seconds: 8))
          .map((snapshot) {
        final coupons = snapshot.docs
            .map((doc) => Coupon.fromFirestore(doc.data(), doc.id))
            .where((c) => c.isActive)
            .toList();
        coupons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return coupons;
      }).handleError((error) {
        debugPrint('Error getting store coupons (collectionGroup): $error');
        return <Coupon>[];
      });
    } catch (e) {
      debugPrint('Error getting store coupons: $e');
      return Stream.value([]);
    }
  }

  // 店舗配下のクーポン一覧を取得（coupons/{storeId}/coupons）
  Stream<List<Coupon>> getStoreCouponsNested(String storeId) {
    try {
      return _firestore
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .snapshots()
          .timeout(const Duration(seconds: 8))
          .map((snapshot) {
        final coupons = snapshot.docs
            .map((doc) => Coupon.fromFirestore(doc.data(), doc.id))
            .where((c) => c.isActive)
            .toList();
        coupons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return coupons;
      }).handleError((error) {
        debugPrint('Error getting store coupons (nested): $error');
        return <Coupon>[];
      });
    } catch (e) {
      debugPrint('Error getting store coupons nested: $e');
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
          return UserCoupon.fromFirestore(doc.data(), doc.id);
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

  // 利用可能なクーポン一覧を取得（公開クーポンから使用済みを除外）
  Stream<List<Coupon>> getAvailableCoupons(String userId) {
    try {
      if (userId.isEmpty || userId == 'guest') {
        return _getPublicAvailableCoupons();
      }

      return _getPublicAvailableCouponsExcludingUsed(userId);
    } catch (e) {
      debugPrint('Error getting available coupons: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Coupon>> _getPublicAvailableCoupons() {
    try {
      final now = DateTime.now();
      return _firestore
          .collection('public_coupons')
          .where('isActive', isEqualTo: true)
          .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
          .snapshots()
          .timeout(const Duration(seconds: 10))
          .map((snapshot) {
        final items = snapshot.docs
            .map((doc) => Coupon.fromFirestore(doc.data(), doc.id))
            .where((coupon) => coupon.isActive && coupon.validUntil.isAfter(now) && coupon.usedCount < coupon.usageLimit)
            .toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      }).handleError((error) {
        debugPrint('Error getting available coupons (collectionGroup): $error');
        return <Coupon>[];
      });
    } catch (e) {
      debugPrint('Error getting public available coupons: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Coupon>> _getPublicAvailableCouponsExcludingUsed(String userId) {
    try {
      final now = DateTime.now();
      return _firestore
          .collection('public_coupons')
          .where('isActive', isEqualTo: true)
          .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
          .snapshots()
          .timeout(const Duration(seconds: 10))
          .asyncMap((snapshot) async {
        final usedSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('used_coupons')
            .get();

        final usedKeys = <String>{};
        for (final usedDoc in usedSnapshot.docs) {
          final usedData = usedDoc.data();
          final storeId = usedData['storeId'] as String?;
          final couponId = (usedData['couponId'] as String?) ?? usedDoc.id;
          if (storeId == null || couponId.isEmpty) {
            continue;
          }
          usedKeys.add('$storeId::$couponId');
        }

        final items = snapshot.docs
            .map((doc) => Coupon.fromFirestore(doc.data(), doc.id))
            .where((coupon) {
              final key = '${coupon.storeId}::${coupon.id}';
              return coupon.isActive &&
                  coupon.validUntil.isAfter(now) &&
                  coupon.usedCount < coupon.usageLimit &&
                  !usedKeys.contains(key);
            })
            .toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      }).handleError((error) {
        debugPrint('Error getting public available coupons excluding used: $error');
        return <Coupon>[];
      });
    } catch (e) {
      debugPrint('Error getting public available coupons excluding used: $e');
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
          return Promotion.fromFirestore(doc.data(), doc.id);
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

  // 使用済みクーポン一覧を取得（users/{userId}/used_coupons と全クーポンを突合）
  Stream<List<Coupon>> getUsedCoupons(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('used_coupons')
          .snapshots()
          .timeout(const Duration(seconds: 8))
          .asyncMap((snapshot) async {
        final usedKeys = <String>{};

        for (final usedDoc in snapshot.docs) {
          final usedData = usedDoc.data();
          final storeId = usedData['storeId'] as String?;
          final couponId = (usedData['couponId'] as String?) ?? usedDoc.id;
          if (storeId == null || couponId.isEmpty) {
            continue;
          }
          usedKeys.add('$storeId::$couponId');
        }

        if (usedKeys.isEmpty) {
          return <Coupon>[];
        }

        final usedKeyList = usedKeys.toList();
        final coupons = <Coupon>[];

        for (var i = 0; i < usedKeyList.length; i += 10) {
          final end = (i + 10 < usedKeyList.length) ? i + 10 : usedKeyList.length;
          final chunk = usedKeyList.sublist(i, end);

          final couponsSnapshot = await _firestore
              .collection('public_coupons')
              .where('key', whereIn: chunk)
              .get();

          coupons.addAll(couponsSnapshot.docs.map((doc) {
            return Coupon.fromFirestore(doc.data(), doc.id);
          }));
        }

        coupons.retainWhere((coupon) {
          final key = '${coupon.storeId}::${coupon.id}';
          return usedKeys.contains(key);
        });

        coupons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return coupons;
      }).handleError((error) {
        debugPrint('Error getting used coupons (users/used_coupons): $error');
        return <Coupon>[];
      });
    } catch (e) {
      debugPrint('Error getting used coupons: $e');
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
        // usedByは配列ではなくサブコレクションとして管理
      };

      await _firestore
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .add(couponData);
    } catch (e) {
      debugPrint('Error creating coupon: $e');
      throw Exception('クーポンの作成に失敗しました: $e');
    }
  }

  // クーポンを取得
  Future<void> obtainCoupon(String userId, String couponId, String storeId) async {
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

      // クーポンの詳細を取得（トップレベル）
      final couponDoc = await _firestore
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .get();
          
      if (!couponDoc.exists) {
        throw Exception('クーポンが見つかりません');
      }

      final coupon = Coupon.fromFirestore(couponDoc.data()!, couponDoc.id);

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
      final userCouponRef =
          _firestore.collection('user_coupons').doc(userCouponId);
      await _firestore.runTransaction((txn) async {
        final userCouponSnap = await txn.get(userCouponRef);
        if (!userCouponSnap.exists) {
          throw Exception('クーポン情報が見つかりません');
        }
        final userCoupon =
            UserCoupon.fromFirestore(userCouponSnap.data()!, userCouponSnap.id);
        if (userCoupon.isUsed) {
          throw Exception('このクーポンは既に使用済みです');
        }

        final storeId = userCoupon.storeId;
        if (storeId == null || storeId.isEmpty) {
          throw Exception('クーポンの店舗情報が見つかりません');
        }

        final couponRef = _firestore
            .collection('coupons')
            .doc(storeId)
            .collection('coupons')
            .doc(userCoupon.couponId);
        final publicCouponRef =
            _firestore.collection('public_coupons').doc(userCoupon.couponId);
        final usedByRef =
            couponRef.collection('usedBy').doc(userCoupon.userId);

        final couponSnap = await txn.get(couponRef);
        if (!couponSnap.exists) {
          throw Exception('クーポンが見つかりません');
        }
        final data = couponSnap.data() ?? {};
        final isActive = data['isActive'] as bool? ?? true;
        final validUntil = (data['validUntil'] as Timestamp?)?.toDate();
        final usageLimit = (data['usageLimit'] as num?)?.toInt() ?? 0;
        final usedCount = (data['usedCount'] as num?)?.toInt() ?? 0;

        if (!isActive) {
          throw Exception('クーポンが無効です');
        }
        if (validUntil == null || !validUntil.isAfter(DateTime.now())) {
          throw Exception('クーポンの有効期限が切れています');
        }
        if (usedCount >= usageLimit) {
          throw Exception('クーポンの上限に達しています');
        }

        final usedBySnap = await txn.get(usedByRef);
        if (usedBySnap.exists) {
          throw Exception('このクーポンは既に使用済みです');
        }

        txn.update(userCouponRef, {
          'isUsed': true,
          'usedAt': FieldValue.serverTimestamp(),
          'orderId': orderId,
        });
        txn.set(usedByRef, {
          'userId': userCoupon.userId,
          'usedAt': FieldValue.serverTimestamp(),
          'couponId': userCoupon.couponId,
          'storeId': userCoupon.storeId,
          'orderId': orderId,
        });

        final nextUsedCount = usedCount + 1;
        final shouldDeactivate = usageLimit > 0 && nextUsedCount == usageLimit;
        txn.update(couponRef, {
          'usedCount': nextUsedCount,
          if (shouldDeactivate) 'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final publicSnap = await txn.get(publicCouponRef);
        if (publicSnap.exists) {
          txn.update(publicCouponRef, {
            'usedCount': nextUsedCount,
            if (shouldDeactivate) 'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
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
