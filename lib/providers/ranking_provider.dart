import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/ranking_model.dart';
import '../models/level_model.dart';
import '../models/badge_model.dart';

// ランキングサービスプロバイダー
final rankingProvider = Provider<RankingService>((ref) {
  return RankingService();
});

// ランキングデータプロバイダー
final rankingDataProvider = StreamProvider.family<List<RankingModel>, RankingQuery>((ref, query) {
  final rankingService = ref.watch(rankingProvider);
  return rankingService.getRankingData(query)
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Ranking data provider error: $error');
    if (error.toString().contains('permission-denied')) {
      return <RankingModel>[];
    }
    return <RankingModel>[];
  });
});

// ユーザーのランキング位置プロバイダー
final userRankingProvider = StreamProvider.family<RankingModel?, String>((ref, userId) {
  final rankingService = ref.watch(rankingProvider);
  return rankingService.getUserRanking(userId);
});

// ランキング期間プロバイダー
final rankingPeriodsProvider = StreamProvider<List<RankingPeriod>>((ref) {
  final rankingService = ref.watch(rankingProvider);
  return rankingService.getRankingPeriods();
});

// ユーザーのランキング履歴プロバイダー
final userRankingHistoryProvider = StreamProvider.family<List<UserRankingHistory>, String>((ref, userId) {
  final rankingService = ref.watch(rankingProvider);
  return rankingService.getUserRankingHistory(userId);
});

class RankingQuery {
  final RankingType type;
  final RankingPeriodType period;
  final int limit;
  final String? periodId;

  const RankingQuery({
    required this.type,
    required this.period,
    this.limit = 100,
    this.periodId,
  });
}

class RankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ランキングデータを取得
  Stream<List<RankingModel>> getRankingData(RankingQuery query) {
    try {
      return _firestore
          .collection('rankings')
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final data = doc.data() as Map<String, dynamic>;
          
          return RankingModel.fromJson({
            ...data,
            'rank': index + 1,
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error in ranking data stream: $error');
        // 権限エラーの場合は空のリストを返す
        if (error.toString().contains('permission-denied')) {
          return <RankingModel>[];
        }
        // その他のエラーも空のリストを返す
        return <RankingModel>[];
      });
    } catch (e) {
      debugPrint('Error getting ranking data: $e');
      return Stream.value([]);
    }
  }

  // ユーザーのランキング位置を取得
  Stream<RankingModel?> getUserRanking(String userId) {
    try {
      return _firestore
          .collection('rankings')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        
        final data = snapshot.docs.first.data();
        return RankingModel.fromJson(data);
      });
    } catch (e) {
      debugPrint('Error getting user ranking: $e');
      return Stream.value(null);
    }
  }

  // ランキング期間を取得
  Stream<List<RankingPeriod>> getRankingPeriods() {
    try {
      return _firestore
          .collection('ranking_periods')
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return RankingPeriod.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting ranking periods: $e');
      return Stream.value([]);
    }
  }

  // ユーザーのランキング履歴を取得
  Stream<List<UserRankingHistory>> getUserRankingHistory(String userId) {
    try {
      return _firestore
          .collection('user_ranking_history')
          .where('userId', isEqualTo: userId)
          .orderBy('achievedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserRankingHistory.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting user ranking history: $e');
      return Stream.value([]);
    }
  }

  // ランキングを更新
  Future<void> updateUserRanking({
    required String userId,
    required String displayName,
    required String? photoURL,
    required int totalPoints,
    required int currentLevel,
    required int badgeCount,
    String? periodId,
  }) async {
    try {
      final rankingData = {
        'userId': userId,
        'displayName': displayName,
        'photoURL': photoURL,
        'totalPoints': totalPoints,
        'currentLevel': currentLevel,
        'badgeCount': badgeCount,
        'lastUpdated': FieldValue.serverTimestamp(),
        'periodId': periodId,
      };

      await _firestore
          .collection('rankings')
          .doc(userId)
          .set(rankingData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user ranking: $e');
      throw Exception('ランキングの更新に失敗しました: $e');
    }
  }

  // ランキング期間を作成
  Future<void> createRankingPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    List<String> rewards = const [],
  }) async {
    try {
      final periodData = {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': true,
        'rewards': rewards,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('ranking_periods').add(periodData);
    } catch (e) {
      debugPrint('Error creating ranking period: $e');
      throw Exception('ランキング期間の作成に失敗しました: $e');
    }
  }

  // ランキング期間を終了
  Future<void> endRankingPeriod(String periodId) async {
    try {
      await _firestore
          .collection('ranking_periods')
          .doc(periodId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error ending ranking period: $e');
      throw Exception('ランキング期間の終了に失敗しました: $e');
    }
  }

  // 期間フィルターを適用
  Query _applyPeriodFilter(Query collection, RankingPeriodType period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriodType.daily:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return collection.where('lastUpdated', isGreaterThanOrEqualTo: startOfDay);
      
      case RankingPeriodType.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return collection.where('lastUpdated', isGreaterThanOrEqualTo: startOfWeekDay);
      
      case RankingPeriodType.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return collection.where('lastUpdated', isGreaterThanOrEqualTo: startOfMonth);
      
      case RankingPeriodType.allTime:
        return collection;
    }
  }

  // ソートフィールドを取得
  String _getOrderByField(RankingType type) {
    switch (type) {
      case RankingType.totalPoints:
        return 'totalPoints';
      case RankingType.monthlyPoints:
        return 'monthlyPoints';
      case RankingType.badgeCount:
        return 'badgeCount';
      case RankingType.level:
        return 'currentLevel';
    }
  }
}
