import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/area_model.dart';
import 'zukan_provider.dart';

/// isActive=true のエリア一覧（order 昇順）
final areasProvider = StreamProvider<List<AreaModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('areas')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    final areas =
        snapshot.docs.map((doc) => AreaModel.fromFirestore(doc)).toList();
    areas.sort((a, b) => (a.order ?? 999).compareTo(b.order ?? 999));
    return areas;
  });
});

/// エリア開拓率データクラス
class AreaExplorationRate {
  final AreaModel area;
  final int totalStores;
  final int myVisitedStores;
  final int communityDiscoveredStores;

  const AreaExplorationRate({
    required this.area,
    required this.totalStores,
    required this.myVisitedStores,
    required this.communityDiscoveredStores,
  });

  /// 個人開拓率（0.0〜1.0）
  double get myRate =>
      totalStores == 0 ? 0.0 : myVisitedStores / totalStores;

  /// コミュニティ開拓率（0.0〜1.0）
  double get communityRate =>
      totalStores == 0 ? 0.0 : communityDiscoveredStores / totalStores;
}

/// エリア開拓率プロバイダー
/// 個人開拓率（myRate）とコミュニティ開拓率（communityRate）を同時に提供する
final areaExplorationRateProvider =
    Provider<AsyncValue<List<AreaExplorationRate>>>((ref) {
  final areasAsync = ref.watch(areasProvider);
  final allStoresAsync = ref.watch(zukanAllStoresProvider);
  final visitedIdsAsync = ref.watch(userVisitedStoreIdsProvider);

  return areasAsync.whenData((areas) {
    final allStores = allStoresAsync.valueOrNull ?? [];
    final visitedIds = visitedIdsAsync.valueOrNull ?? {};

    return areas.map((area) {
      final areaStores =
          allStores.where((s) => s['areaId'] == area.areaId).toList();
      final totalStores = areaStores.length;

      final myVisitedStores = areaStores
          .where((s) => visitedIds.contains(s['storeId'] as String?))
          .length;

      final communityDiscoveredStores = areaStores
          .where((s) =>
              ((s['discoveredCount'] as num?)?.toInt() ?? 0) >= 1)
          .length;

      return AreaExplorationRate(
        area: area,
        totalStores: totalStores,
        myVisitedStores: myVisitedStores,
        communityDiscoveredStores: communityDiscoveredStores,
      );
    }).toList();
  });
});
