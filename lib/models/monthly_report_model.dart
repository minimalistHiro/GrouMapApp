import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedStore {
  final String storeId;
  final String storeName;
  final String category;
  final int rarity;
  final String? areaId;

  const RecommendedStore({
    required this.storeId,
    required this.storeName,
    required this.category,
    required this.rarity,
    this.areaId,
  });

  factory RecommendedStore.fromMap(Map<String, dynamic> data) {
    return RecommendedStore(
      storeId: data['storeId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      category: data['category'] as String? ?? '',
      rarity: (data['rarity'] as num?)?.toInt() ?? 1,
      areaId: data['areaId'] as String?,
    );
  }
}

class MonthlyReportModel {
  final String userId;
  final String yearMonth;
  final DateTime generatedAt;

  // 個人データ
  final int monthlyDiscoveredCount;
  final int totalDiscoveredCount;
  final String? topGenre;
  final int topGenreCount;
  final List<String> visitedAreas;
  final int legendDiscoveredCount;
  final int communityContributionCount;
  final int totalVisitsThisMonth;
  final int hotStoresCount;

  // コミュニティデータ
  final int communityDiscoveredCount;
  final double communityExplorationRateDelta;
  final int communityVisitsDelta;
  final int newStoresAddedCount;

  // 来月のおすすめ
  final List<RecommendedStore> recommendedStores;

  const MonthlyReportModel({
    required this.userId,
    required this.yearMonth,
    required this.generatedAt,
    required this.monthlyDiscoveredCount,
    required this.totalDiscoveredCount,
    this.topGenre,
    required this.topGenreCount,
    required this.visitedAreas,
    required this.legendDiscoveredCount,
    required this.communityContributionCount,
    required this.totalVisitsThisMonth,
    required this.hotStoresCount,
    required this.communityDiscoveredCount,
    required this.communityExplorationRateDelta,
    required this.communityVisitsDelta,
    required this.newStoresAddedCount,
    required this.recommendedStores,
  });

  factory MonthlyReportModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MonthlyReportModel.fromMap(data);
  }

  factory MonthlyReportModel.fromMap(Map<String, dynamic> data) {
    DateTime generatedAt;
    final raw = data['generatedAt'];
    if (raw is Timestamp) {
      generatedAt = raw.toDate();
    } else {
      generatedAt = DateTime.now();
    }

    final rawRecommended = data['recommendedStores'];
    final recommendedStores = <RecommendedStore>[];
    if (rawRecommended is List) {
      for (final item in rawRecommended) {
        if (item is Map<String, dynamic>) {
          recommendedStores.add(RecommendedStore.fromMap(item));
        }
      }
    }

    final rawAreas = data['visitedAreas'];
    final visitedAreas = <String>[];
    if (rawAreas is List) {
      for (final a in rawAreas) {
        if (a is String) visitedAreas.add(a);
      }
    }

    return MonthlyReportModel(
      userId: data['userId'] as String? ?? '',
      yearMonth: data['yearMonth'] as String? ?? '',
      generatedAt: generatedAt,
      monthlyDiscoveredCount:
          (data['monthlyDiscoveredCount'] as num?)?.toInt() ?? 0,
      totalDiscoveredCount:
          (data['totalDiscoveredCount'] as num?)?.toInt() ?? 0,
      topGenre: data['topGenre'] as String?,
      topGenreCount: (data['topGenreCount'] as num?)?.toInt() ?? 0,
      visitedAreas: visitedAreas,
      legendDiscoveredCount:
          (data['legendDiscoveredCount'] as num?)?.toInt() ?? 0,
      communityContributionCount:
          (data['communityContributionCount'] as num?)?.toInt() ?? 0,
      totalVisitsThisMonth:
          (data['totalVisitsThisMonth'] as num?)?.toInt() ?? 0,
      hotStoresCount: (data['hotStoresCount'] as num?)?.toInt() ?? 0,
      communityDiscoveredCount:
          (data['communityDiscoveredCount'] as num?)?.toInt() ?? 0,
      communityExplorationRateDelta:
          (data['communityExplorationRateDelta'] as num?)?.toDouble() ?? 0.0,
      communityVisitsDelta:
          (data['communityVisitsDelta'] as num?)?.toInt() ?? 0,
      newStoresAddedCount: (data['newStoresAddedCount'] as num?)?.toInt() ?? 0,
      recommendedStores: recommendedStores,
    );
  }
}
