import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/store_management_model.dart';

// 店舗管理サービスプロバイダー
final storeManagementProvider = Provider<StoreManagementService>((ref) {
  return StoreManagementService();
});

// 店舗管理一覧プロバイダー
final storeManagementListProvider = StreamProvider<List<StoreManagement>>((ref) {
  final storeManagementService = ref.watch(storeManagementProvider);
  return storeManagementService.getStoreManagementList();
});

// 店舗詳細プロバイダー
final storeManagementDetailProvider = StreamProvider.family<StoreManagement?, String>((ref, storeId) {
  final storeManagementService = ref.watch(storeManagementProvider);
  return storeManagementService.getStoreManagement(storeId);
});

// 店舗スタッフ一覧プロバイダー
final storeStaffProvider = StreamProvider.family<List<StoreStaff>, String>((ref, storeId) {
  final storeManagementService = ref.watch(storeManagementProvider);
  return storeManagementService.getStoreStaff(storeId);
});

// 店舗メニュー一覧プロバイダー
final storeMenuProvider = StreamProvider.family<List<StoreMenu>, String>((ref, storeId) {
  final storeManagementService = ref.watch(storeManagementProvider);
  return storeManagementService.getStoreMenu(storeId);
});

// 店舗分析データプロバイダー
final storeAnalyticsProvider = StreamProvider.family<List<StoreAnalytics>, String>((ref, storeId) {
  final storeManagementService = ref.watch(storeManagementProvider);
  return storeManagementService.getStoreAnalytics(storeId);
});

class StoreManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 店舗管理一覧を取得
  Stream<List<StoreManagement>> getStoreManagementList() {
    try {
      return _firestore
          .collection('store_management')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return StoreManagement.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting store management list: $error');
        return <StoreManagement>[];
      });
    } catch (e) {
      debugPrint('Error getting store management list: $e');
      return Stream.value([]);
    }
  }

  // 店舗管理詳細を取得
  Stream<StoreManagement?> getStoreManagement(String storeId) {
    try {
      return _firestore
          .collection('store_management')
          .doc(storeId)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        if (snapshot.exists) {
          return StoreManagement.fromJson({
            'id': storeId,
            ...snapshot.data()!,
          });
        }
        return null;
      }).handleError((error) {
        debugPrint('Error getting store management: $error');
        return null;
      });
    } catch (e) {
      debugPrint('Error getting store management: $e');
      return Stream.value(null);
    }
  }

  // 店舗管理を作成
  Future<void> createStoreManagement({
    required String storeId,
    required String managerId,
    required String storeName,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phoneNumber,
    required String email,
    String? imageUrl,
    List<String>? businessHours,
    List<String>? paymentMethods,
    Map<String, dynamic>? settings,
    List<String>? tags,
  }) async {
    try {
      final storeManagementData = {
        'storeId': storeId,
        'managerId': managerId,
        'storeName': storeName,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'phoneNumber': phoneNumber,
        'email': email,
        'status': StoreStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'businessHours': businessHours ?? [],
        'paymentMethods': paymentMethods ?? [],
        'settings': settings ?? {},
        'totalVisitors': 0,
        'totalPointsAwarded': 0,
        'totalCouponsIssued': 0,
        'tags': tags ?? [],
      };

      await _firestore.collection('store_management').add(storeManagementData);
    } catch (e) {
      debugPrint('Error creating store management: $e');
      throw Exception('店舗管理の作成に失敗しました: $e');
    }
  }

  // 店舗管理を更新
  Future<void> updateStoreManagement({
    required String storeId,
    String? storeName,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? email,
    String? imageUrl,
    List<String>? businessHours,
    List<String>? paymentMethods,
    Map<String, dynamic>? settings,
    List<String>? tags,
    StoreStatus? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (storeName != null) updateData['storeName'] = storeName;
      if (description != null) updateData['description'] = description;
      if (address != null) updateData['address'] = address;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (email != null) updateData['email'] = email;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (businessHours != null) updateData['businessHours'] = businessHours;
      if (paymentMethods != null) updateData['paymentMethods'] = paymentMethods;
      if (settings != null) updateData['settings'] = settings;
      if (tags != null) updateData['tags'] = tags;
      if (status != null) updateData['status'] = status.name;

      await _firestore.collection('store_management').doc(storeId).update(updateData);
    } catch (e) {
      debugPrint('Error updating store management: $e');
      throw Exception('店舗管理の更新に失敗しました: $e');
    }
  }

  // 店舗スタッフ一覧を取得
  Stream<List<StoreStaff>> getStoreStaff(String storeId) {
    try {
      return _firestore
          .collection('store_staff')
          .where('storeId', isEqualTo: storeId)
          .orderBy('joinedAt', descending: true)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return StoreStaff.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting store staff: $error');
        return <StoreStaff>[];
      });
    } catch (e) {
      debugPrint('Error getting store staff: $e');
      return Stream.value([]);
    }
  }

  // スタッフを追加
  Future<void> addStaff({
    required String storeId,
    required String userId,
    required String name,
    required String email,
    required StaffRole role,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final staffData = {
        'storeId': storeId,
        'userId': userId,
        'name': name,
        'email': email,
        'role': role.name,
        'joinedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'permissions': permissions ?? {},
      };

      await _firestore.collection('store_staff').add(staffData);
    } catch (e) {
      debugPrint('Error adding staff: $e');
      throw Exception('スタッフの追加に失敗しました: $e');
    }
  }

  // スタッフを削除
  Future<void> removeStaff(String staffId) async {
    try {
      await _firestore.collection('store_staff').doc(staffId).update({
        'isActive': false,
      });
    } catch (e) {
      debugPrint('Error removing staff: $e');
      throw Exception('スタッフの削除に失敗しました: $e');
    }
  }

  // 店舗メニュー一覧を取得
  Stream<List<StoreMenu>> getStoreMenu(String storeId) {
    try {
      return _firestore
          .collection('store_menu')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return StoreMenu.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting store menu: $error');
        return <StoreMenu>[];
      });
    } catch (e) {
      debugPrint('Error getting store menu: $e');
      return Stream.value([]);
    }
  }

  // メニューアイテムを追加
  Future<void> addMenuItem({
    required String storeId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
    List<String>? ingredients,
    Map<String, dynamic>? nutritionInfo,
  }) async {
    try {
      final menuData = {
        'storeId': storeId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'ingredients': ingredients ?? [],
        'nutritionInfo': nutritionInfo ?? {},
        'orderCount': 0,
      };

      await _firestore.collection('store_menu').add(menuData);
    } catch (e) {
      debugPrint('Error adding menu item: $e');
      throw Exception('メニューアイテムの追加に失敗しました: $e');
    }
  }

  // メニューアイテムを更新
  Future<void> updateMenuItem({
    required String menuId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    List<String>? ingredients,
    Map<String, dynamic>? nutritionInfo,
    bool? isAvailable,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (ingredients != null) updateData['ingredients'] = ingredients;
      if (nutritionInfo != null) updateData['nutritionInfo'] = nutritionInfo;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;

      await _firestore.collection('store_menu').doc(menuId).update(updateData);
    } catch (e) {
      debugPrint('Error updating menu item: $e');
      throw Exception('メニューアイテムの更新に失敗しました: $e');
    }
  }

  // メニューアイテムを削除
  Future<void> deleteMenuItem(String menuId) async {
    try {
      await _firestore.collection('store_menu').doc(menuId).delete();
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
      throw Exception('メニューアイテムの削除に失敗しました: $e');
    }
  }

  // 店舗分析データを取得
  Stream<List<StoreAnalytics>> getStoreAnalytics(String storeId) {
    try {
      return _firestore
          .collection('store_analytics')
          .where('storeId', isEqualTo: storeId)
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return StoreAnalytics.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error getting store analytics: $error');
        return <StoreAnalytics>[];
      });
    } catch (e) {
      debugPrint('Error getting store analytics: $e');
      return Stream.value([]);
    }
  }

  // 店舗統計を更新
  Future<void> updateStoreStats({
    required String storeId,
    int? visitors,
    int? pointsAwarded,
    int? couponsIssued,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (visitors != null) updateData['totalVisitors'] = FieldValue.increment(visitors);
      if (pointsAwarded != null) updateData['totalPointsAwarded'] = FieldValue.increment(pointsAwarded);
      if (couponsIssued != null) updateData['totalCouponsIssued'] = FieldValue.increment(couponsIssued);

      if (updateData.isNotEmpty) {
        await _firestore.collection('store_management').doc(storeId).update(updateData);
      }
    } catch (e) {
      debugPrint('Error updating store stats: $e');
      throw Exception('店舗統計の更新に失敗しました: $e');
    }
  }
}