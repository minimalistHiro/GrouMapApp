import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class StoreReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 店舗紹介コードを生成・取得
  Future<String> getStoreReferralCode(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        // 既存の店舗紹介コードがあるかチェック
        if (userData.containsKey('storeReferralCode') && 
            userData['storeReferralCode'] != null &&
            userData['storeReferralCode'].toString().isNotEmpty) {
          return userData['storeReferralCode'];
        }
      }
      
      // 店舗紹介コードが存在しない場合は新規作成
      String newCode;
      bool isUnique = false;
      int attempts = 0;
      const maxAttempts = 10;
      
      do {
        newCode = _generateStoreReferralCode();
        
        // ユニークかチェック
        final existingCodeQuery = await _firestore
            .collection('users')
            .where('storeReferralCode', isEqualTo: newCode)
            .get();
        
        isUnique = existingCodeQuery.docs.isEmpty;
        attempts++;
        
        if (attempts >= maxAttempts) {
          throw Exception('店舗紹介コードの生成に失敗しました（最大試行回数に達しました）');
        }
      } while (!isUnique);
      
      // 新しい店舗紹介コードをFirestoreに保存
      await _firestore.collection('users').doc(userId).update({
        'storeReferralCode': newCode,
      });
      
      print('新しい店舗紹介コード生成: $newCode');
      return newCode;
    } catch (e) {
      print('店舗紹介コード取得エラー: $e');
      throw Exception('店舗紹介コードの取得に失敗しました: $e');
    }
  }

  // 店舗紹介コードを生成（8桁の大文字、小文字、数字の組み合わせ）
  String _generateStoreReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // 店舗紹介の処理
  Future<bool> processStoreReferral({
    required String referrerUserId,
    required String storeName,
    required String storeLocation,
    required String contactInfo,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // 紹介履歴を作成
      final referralHistoryRef = _firestore.collection('store_referral_history').doc();
      batch.set(referralHistoryRef, {
        'referrerUserId': referrerUserId,
        'storeName': storeName,
        'storeLocation': storeLocation,
        'contactInfo': contactInfo,
        'pointsAwarded': 3000,
        'status': 'pending', // pending, approved, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': null,
      });

      // 一旦保留状態として記録（管理者承認後にポイント付与）
      await batch.commit();
      
      print('店舗紹介申請が送信されました: $storeName');
      return true;
    } catch (e) {
      print('店舗紹介処理エラー: $e');
      return false;
    }
  }

  // 店舗紹介統計を取得
  Future<Map<String, int>> getStoreReferralStats(String userId) async {
    try {
      // 承認された店舗紹介数を取得
      final approvedReferralsQuery = await _firestore
          .collection('store_referral_history')
          .where('referrerUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .get();

      // 保留中の店舗紹介数を取得
      final pendingReferralsQuery = await _firestore
          .collection('store_referral_history')
          .where('referrerUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final approvedCount = approvedReferralsQuery.docs.length;
      final pendingCount = pendingReferralsQuery.docs.length;
      final totalPointsEarned = approvedCount * 3000;

      return {
        'approvedReferralCount': approvedCount,
        'pendingReferralCount': pendingCount,
        'totalPointsEarned': totalPointsEarned,
      };
    } catch (e) {
      print('店舗紹介統計取得エラー: $e');
      return {
        'approvedReferralCount': 0,
        'pendingReferralCount': 0,
        'totalPointsEarned': 0,
      };
    }
  }

  // 店舗紹介履歴を取得
  Future<List<Map<String, dynamic>>> getStoreReferralHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('store_referral_history')
          .where('referrerUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'storeName': data['storeName'] ?? '店舗名なし',
          'storeLocation': data['storeLocation'] ?? '',
          'contactInfo': data['contactInfo'] ?? '',
          'pointsAwarded': data['pointsAwarded'] ?? 3000,
          'status': data['status'] ?? 'pending',
          'createdAt': data['createdAt'],
          'processedAt': data['processedAt'],
        };
      }).toList();
    } catch (e) {
      print('店舗紹介履歴取得エラー: $e');
      return [];
    }
  }

  // ステータス表示用の文字列を取得
  String getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return '審査中';
      case 'approved':
        return '承認済み';
      case 'rejected':
        return '非承認';
      default:
        return '不明';
    }
  }

  // ステータス表示用の色を取得
  String getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }
}