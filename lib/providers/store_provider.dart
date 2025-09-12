import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/store_model.dart';

// Firestoreサービスプロバイダー
final firestoreServiceProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// 店舗一覧プロバイダー
final storesProvider = StreamProvider<List<StoreModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  
  return firestore
      .collection('stores')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => StoreModel.fromJson({
                ...doc.data(),
                'storeId': doc.id,
              }))
          .toList());
});

// 特定の店舗プロバイダー
final storeProvider = StreamProvider.family<StoreModel?, String>((ref, storeId) {
  final firestore = ref.watch(firestoreServiceProvider);
  
  return firestore
      .collection('stores')
      .doc(storeId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return StoreModel.fromJson({
      ...snapshot.data()!,
      'storeId': snapshot.id,
    });
  });
});

// 近くの店舗プロバイダー（位置情報ベース）
final nearbyStoresProvider = StreamProvider.family<List<StoreModel>, StoreLocation>((ref, location) {
  final firestore = ref.watch(firestoreServiceProvider);
  
  // 簡易的な近くの店舗検索（実際の実装ではGeoHashを使用）
  return firestore
      .collection('stores')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    final stores = snapshot.docs
        .map((doc) => StoreModel.fromJson({
              ...doc.data(),
              'storeId': doc.id,
            }))
        .toList();
    
    // 距離でソート（簡易実装）
    stores.sort((a, b) {
      final distanceA = _calculateDistance(
        location.latitude,
        location.longitude,
        a.location.latitude,
        a.location.longitude,
      );
      final distanceB = _calculateDistance(
        location.latitude,
        location.longitude,
        b.location.latitude,
        b.location.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    
    return stores.take(20).toList(); // 最大20件
  });
});

// 店舗カテゴリ別プロバイダー
final storesByCategoryProvider = StreamProvider.family<List<StoreModel>, String>((ref, category) {
  final firestore = ref.watch(firestoreServiceProvider);
  
  return firestore
      .collection('stores')
      .where('isActive', isEqualTo: true)
      .where('category', isEqualTo: category)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => StoreModel.fromJson({
                ...doc.data(),
                'storeId': doc.id,
              }))
          .toList());
});

// 距離計算関数（簡易実装）
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // 地球の半径（km）
  
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);
  
  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) * 
      math.sin(dLon / 2) * math.sin(dLon / 2);
  final double c = 2 * math.asin(math.sqrt(a));
  
  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * (math.pi / 180);
}
