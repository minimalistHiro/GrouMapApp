import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MissionService {
  final FirebaseFirestore _firestore;

  MissionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ========== デイリーミッション ==========

  /// デイリーミッション達成をマーク（冪等）
  Future<void> markDailyMission(String userId, String missionType) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_missions')
          .doc(_todayString);

      await docRef.set({
        missionType: true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('デイリーミッション達成マークエラー: $e');
    }
  }

  /// 今日のデイリーミッション状態を取得
  Future<Map<String, dynamic>> getDailyMissions(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_missions')
          .doc(_todayString)
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('デイリーミッション取得エラー: $e');
      return {};
    }
  }

  /// デイリーミッション報酬を受け取る（トランザクションで二重受取防止+コイン加算）
  Future<bool> claimDailyMission(
      String userId, String missionType, int coinReward) async {
    try {
      final dailyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_missions')
          .doc(_todayString);
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final dailyDoc = await transaction.get(dailyRef);
        final userDoc = await transaction.get(userRef);

        if (!dailyDoc.exists || !userDoc.exists) {
          throw Exception('ドキュメントが存在しません');
        }

        final dailyData = dailyDoc.data() ?? {};

        // 達成済みかチェック
        if (dailyData[missionType] != true) {
          throw Exception('ミッション未達成');
        }

        // 受取済みかチェック
        final claimedKey = '${missionType}_claimed';
        if (dailyData[claimedKey] == true) {
          throw Exception('既に受け取り済み');
        }

        final currentCoins =
            (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;

        // コイン加算 + claimed マーク
        transaction.update(userRef, {
          'coins': currentCoins + coinReward,
        });
        transaction.update(dailyRef, {
          claimedKey: true,
        });
      });

      return true;
    } catch (e) {
      debugPrint('デイリーミッション報酬受取エラー: $e');
      return false;
    }
  }

  // ========== ログインストリーク ==========

  /// ログインストリークを更新
  Future<int> updateLoginStreak(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return 0;

      final userData = userDoc.data() ?? {};
      final lastLoginDate = userData['lastLoginDate'] as String?;
      final currentStreak = (userData['loginStreak'] as num?)?.toInt() ?? 0;
      final today = _todayString;

      // 既に今日更新済みならスキップ
      if (lastLoginDate == today) return currentStreak;

      int newStreak;
      if (lastLoginDate != null) {
        final lastDate = DateTime.tryParse(lastLoginDate);
        final todayDate = DateTime.tryParse(today);
        if (lastDate != null && todayDate != null) {
          final diff = todayDate.difference(lastDate).inDays;
          if (diff == 1) {
            // 連続ログイン
            newStreak = currentStreak + 1;
          } else {
            // 連続が途切れた
            newStreak = 1;
          }
        } else {
          newStreak = 1;
        }
      } else {
        // 初回ログイン
        newStreak = 1;
      }

      await userRef.update({
        'loginStreak': newStreak,
        'lastLoginDate': today,
      });

      return newStreak;
    } catch (e) {
      debugPrint('ログインストリーク更新エラー: $e');
      return 0;
    }
  }

  /// ログインストリーク取得
  Future<int> getLoginStreak(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;
      return (userDoc.data()?['loginStreak'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('ログインストリーク取得エラー: $e');
      return 0;
    }
  }

  /// ログインボーナス報酬を受け取る
  Future<bool> claimLoginBonus(
      String userId, String milestone, int coinReward) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('ユーザーが存在しません');

        final userData = userDoc.data() ?? {};
        final missionProgress =
            (userData['missionProgress'] as Map<String, dynamic>?) ?? {};

        // 受取済みかチェック
        final claimedKey = '${milestone}_claimed';
        if (missionProgress[claimedKey] == true) {
          throw Exception('既に受け取り済み');
        }

        final currentCoins = (userData['coins'] as num?)?.toInt() ?? 0;

        transaction.update(userRef, {
          'coins': currentCoins + coinReward,
          'missionProgress.$claimedKey': true,
        });
      });

      return true;
    } catch (e) {
      debugPrint('ログインボーナス受取エラー: $e');
      return false;
    }
  }

  // ========== 新規登録ミッション ==========

  /// 新規登録ミッション達成をマーク（冪等）
  Future<void> markRegistrationMission(
      String userId, String missionType) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() ?? {};
      final missionProgress =
          (userData['missionProgress'] as Map<String, dynamic>?) ?? {};

      // 既に達成済みならスキップ
      if (missionProgress[missionType] == true) return;

      await userRef.update({
        'missionProgress.$missionType': true,
      });
    } catch (e) {
      debugPrint('新規登録ミッション達成マークエラー: $e');
    }
  }

  /// 新規登録ミッション報酬を受け取る
  Future<bool> claimRegistrationMission(
      String userId, String missionType, int coinReward) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('ユーザーが存在しません');

        final userData = userDoc.data() ?? {};
        final missionProgress =
            (userData['missionProgress'] as Map<String, dynamic>?) ?? {};

        // 達成済みかチェック
        if (missionProgress[missionType] != true) {
          throw Exception('ミッション未達成');
        }

        // 受取済みかチェック
        final claimedKey = '${missionType}_claimed';
        if (missionProgress[claimedKey] == true) {
          throw Exception('既に受け取り済み');
        }

        final currentCoins = (userData['coins'] as num?)?.toInt() ?? 0;

        transaction.update(userRef, {
          'coins': currentCoins + coinReward,
          'missionProgress.$claimedKey': true,
        });
      });

      return true;
    } catch (e) {
      debugPrint('新規登録ミッション報酬受取エラー: $e');
      return false;
    }
  }

  /// ミッション全体進捗を取得
  Future<Map<String, dynamic>> getMissionProgress(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};
      return (userDoc.data()?['missionProgress']
              as Map<String, dynamic>?) ??
          {};
    } catch (e) {
      debugPrint('ミッション進捗取得エラー: $e');
      return {};
    }
  }

  /// 受け取り可能（達成済み＆未受取）なミッションがあるか判定
  Future<bool> hasClaimableMissions(String userId) async {
    try {
      // デイリーミッション確認
      final dailyData = await getDailyMissions(userId);
      const dailyIds = ['app_open', 'recommendation_view', 'map_open'];
      for (final id in dailyIds) {
        if (dailyData[id] == true && dailyData['${id}_claimed'] != true) {
          return true;
        }
      }

      // missionProgress（新規登録ミッション＋ログインボーナス）確認
      final progress = await getMissionProgress(userId);

      // 新規登録ミッション
      const regIds = [
        'profile_completed',
        'first_map',
        'first_favorite',
        'first_store_detail',
        'first_slot',
      ];
      for (final id in regIds) {
        if (progress[id] == true && progress['${id}_claimed'] != true) {
          return true;
        }
      }

      // ログインボーナス
      final loginStreak = await getLoginStreak(userId);
      const loginMilestones = {'login_3': 3, 'login_7': 7, 'login_30': 30};
      for (final entry in loginMilestones.entries) {
        if (loginStreak >= entry.value &&
            progress['${entry.key}_claimed'] != true) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('受取可能ミッション判定エラー: $e');
      return false;
    }
  }

  /// ユーザーのコイン残高を取得
  Future<int> getUserCoins(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;
      return (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('コイン残高取得エラー: $e');
      return 0;
    }
  }

  // ========== コイン交換（未訪問店舗クーポン） ==========

  /// 訪問済み店舗IDのセットを取得
  Future<Set<String>> getVisitedStoreIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stores')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint('訪問済み店舗取得エラー: $e');
      return {};
    }
  }

  /// コイン10枚で未訪問店舗の100円引きクーポンを取得
  Future<bool> exchangeCoinForCoupon(String userId, String storeId, String storeName) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final couponRef = _firestore.collection('user_coupons').doc();

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('ユーザーが存在しません');

        final currentCoins = (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < 10) {
          throw Exception('コインが不足しています');
        }

        final now = DateTime.now();
        final validUntil = now.add(const Duration(days: 30));

        // コイン消費
        transaction.update(userRef, {
          'coins': currentCoins - 10,
        });

        // クーポン作成
        transaction.set(couponRef, {
          'userId': userId,
          'couponId': couponRef.id,
          'storeId': storeId,
          'storeName': storeName,
          'type': 'coin_exchange',
          'title': '100円引きクーポン',
          'discountValue': 100,
          'discountType': 'fixed_amount',
          'validFrom': Timestamp.fromDate(now),
          'validUntil': Timestamp.fromDate(validUntil),
          'isUsed': false,
          'obtainedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      debugPrint('コイン交換エラー: $e');
      return false;
    }
  }
}
