import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/ranking_model.dart';

// ランキングサービスプロバイダー
final rankingProvider = Provider<RankingService>((ref) {
  return RankingService();
});

// ランキング状態管理
class RankingNotifier extends StateNotifier<AsyncValue<List<RankingModel>>> {
  final RankingService _rankingService;
  RankingQuery? _lastQuery;
  
  RankingNotifier(this._rankingService) : super(const AsyncValue.loading());
  
  Future<void> loadRanking(RankingQuery query) async {
    // 同じクエリの場合は再読み込みしない
    if (_lastQuery != null && 
        _lastQuery!.type == query.type && 
        _lastQuery!.period == query.period &&
        _lastQuery!.limit == query.limit) {
      return;
    }
    
    _lastQuery = query;
    debugPrint('RankingNotifier: Loading ranking for ${query.type}, ${query.period}');
    
    state = const AsyncValue.loading();
    
    try {
      final data = await _rankingService.getRankingDataOnce(query);
      debugPrint('RankingNotifier: Loaded ${data.length} ranking items');
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      debugPrint('RankingNotifier: Error loading ranking: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// ランキングプロバイダー
final rankingNotifierProvider = StateNotifierProvider<RankingNotifier, AsyncValue<List<RankingModel>>>((ref) {
  final rankingService = ref.watch(rankingProvider);
  return RankingNotifier(rankingService);
});

// ランキングデータプロバイダー（StateNotifierProviderに変更）
final rankingDataProvider = Provider.family<AsyncValue<List<RankingModel>>, RankingQuery>((ref, query) {
  final notifier = ref.watch(rankingNotifierProvider.notifier);
  final state = ref.watch(rankingNotifierProvider);
  
  // 初回読み込み
  WidgetsBinding.instance.addPostFrameCallback((_) {
    notifier.loadRanking(query);
  });
  
  return state;
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

  // ランキングデータを一度だけ取得（FutureProvider用）
  Future<List<RankingModel>> getRankingDataOnce(RankingQuery query) async {
    try {
      debugPrint('RankingService: Getting ranking data once for type: ${query.type}, period: ${query.period}');
      
      final snapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));
      
      debugPrint('RankingService: Retrieved ${snapshot.docs.length} users from database');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('RankingService: No users found in database');
        return <RankingModel>[];
      }
      
      // ユーザーデータをRankingModelに変換
      final rankings = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          final userId = doc.id;
          final profileImageUrl = data['profileImageUrl'];
          
          debugPrint('RankingService: User $userId - profileImageUrl: $profileImageUrl');
          
          return RankingModel(
            userId: userId,
            displayName: data['displayName'] ?? 'Unknown User',
            photoURL: data['profileImageUrl'], // profileImageUrlから取得
            totalPoints: data['totalPoints'] ?? 0,
            currentLevel: data['currentLevel'] ?? 1,
            badgeCount: data['badgeCount'] ?? 0,
            stampCount: data['stampCount'] ?? 0,
            totalPayment: data['totalPayment'] ?? 0,
            rank: 0, // 後で設定
            lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        } catch (e) {
          debugPrint('RankingService: Error parsing user data for ${doc.id}: $e');
          return null;
        }
      }).where((ranking) => ranking != null).cast<RankingModel>().toList();
      
      debugPrint('RankingService: Successfully parsed ${rankings.length} user rankings');
      
      // ランキングタイプに応じてソート
      rankings.sort((a, b) {
        switch (query.type) {
          case RankingType.totalPoints:
            return b.totalPoints.compareTo(a.totalPoints);
          case RankingType.badgeCount:
            return b.badgeCount.compareTo(a.badgeCount);
          case RankingType.level:
            return b.currentLevel.compareTo(a.currentLevel);
          case RankingType.stampCount:
            return b.stampCount.compareTo(a.stampCount);
          case RankingType.totalPayment:
            return b.totalPayment.compareTo(a.totalPayment);
        }
      });
      
      // 期間フィルターを適用
      final filteredRankings = _applyPeriodFilterToList(rankings, query.period);
      debugPrint('RankingService: After period filter: ${filteredRankings.length} users');
      
      // ランクを設定
      final rankedList = filteredRankings.asMap().entries.map((entry) {
        final index = entry.key;
        final ranking = entry.value;
        return ranking.copyWith(rank: index + 1);
      }).toList();
      
      // 制限を適用
      final limitedList = rankedList.take(query.limit).toList();
      
      debugPrint('RankingService: Generated final ranking with ${limitedList.length} users');
      return limitedList;
    } catch (e) {
      debugPrint('RankingService: Error getting ranking data: $e');
      return <RankingModel>[];
    }
  }

  // ランキングデータを取得（実際のユーザーデータから）
  Stream<List<RankingModel>> getRankingData(RankingQuery query) {
    try {
      debugPrint('Getting ranking data for type: ${query.type}, period: ${query.period}');
      
      return _firestore
          .collection('users')
          .snapshots()
          .timeout(const Duration(seconds: 15))
          .map((snapshot) {
        debugPrint('Retrieved ${snapshot.docs.length} users from database');
        
        if (snapshot.docs.isEmpty) {
          debugPrint('No users found in database');
          return <RankingModel>[];
        }
        
        // ユーザーデータをRankingModelに変換
        final rankings = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          final userId = doc.id;
          final profileImageUrl = data['profileImageUrl'];
          
          debugPrint('RankingService: User $userId - profileImageUrl: $profileImageUrl');
          
          return RankingModel(
            userId: userId,
            displayName: data['displayName'] ?? 'Unknown User',
            photoURL: profileImageUrl, // profileImageUrlから取得
            totalPoints: data['totalPoints'] ?? 0,
            currentLevel: data['currentLevel'] ?? 1,
            badgeCount: data['badgeCount'] ?? 0,
            stampCount: data['stampCount'] ?? 0,
            totalPayment: data['totalPayment'] ?? 0,
            rank: 0, // 後で設定
            lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          } catch (e) {
            debugPrint('Error parsing user data for ${doc.id}: $e');
            return null;
          }
        }).where((ranking) => ranking != null).cast<RankingModel>().toList();
        
        debugPrint('Successfully parsed ${rankings.length} user rankings');
        
        // ランキングタイプに応じてソート
        rankings.sort((a, b) {
          switch (query.type) {
            case RankingType.totalPoints:
              return b.totalPoints.compareTo(a.totalPoints);
            case RankingType.badgeCount:
              return b.badgeCount.compareTo(a.badgeCount);
            case RankingType.level:
              return b.currentLevel.compareTo(a.currentLevel);
            case RankingType.stampCount:
              return b.stampCount.compareTo(a.stampCount);
            case RankingType.totalPayment:
              return b.totalPayment.compareTo(a.totalPayment);
          }
        });
        
        // 期間フィルターを適用
        final filteredRankings = _applyPeriodFilterToList(rankings, query.period);
        debugPrint('After period filter: ${filteredRankings.length} users');
        
        // ランクを設定
        final rankedList = filteredRankings.asMap().entries.map((entry) {
          final index = entry.key;
          final ranking = entry.value;
          return ranking.copyWith(rank: index + 1);
        }).toList();
        
        // 制限を適用
        final limitedList = rankedList.take(query.limit).toList();
        
        debugPrint('Generated final ranking with ${limitedList.length} users');
        return limitedList;
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

  // 期間フィルターをリストに適用
  List<RankingModel> _applyPeriodFilterToList(List<RankingModel> rankings, RankingPeriodType period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriodType.daily:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return rankings.where((ranking) => 
          ranking.lastUpdated.isAfter(startOfDay)).toList();
      
      case RankingPeriodType.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return rankings.where((ranking) => 
          ranking.lastUpdated.isAfter(startOfWeekDay)).toList();
      
      case RankingPeriodType.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return rankings.where((ranking) => 
          ranking.lastUpdated.isAfter(startOfMonth)).toList();
      
      case RankingPeriodType.allTime:
        return rankings;
    }
  }

  // 期間フィルターを適用（クエリ用 - 将来の拡張用）
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
      case RankingType.badgeCount:
        return 'badgeCount';
      case RankingType.level:
        return 'currentLevel';
      case RankingType.stampCount:
        return 'stampCount';
      case RankingType.totalPayment:
        return 'totalPayment';
    }
  }
}
