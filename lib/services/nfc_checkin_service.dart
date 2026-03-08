import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class NfcCheckinSession {
  final String sessionToken;
  NfcCheckinSession({required this.sessionToken});
}

class NfcCheckinResult {
  final int stampsAfter;
  final bool cardCompleted;
  final String storeName;
  final bool isFirstVisit;
  final List<Map<String, dynamic>> awardedCoupons;
  final List<Map<String, dynamic>> usedCoupons;
  final String? usageVerificationCode;
  final bool hiddenExplorerIncremented;

  NfcCheckinResult({
    required this.stampsAfter,
    required this.cardCompleted,
    required this.storeName,
    required this.isFirstVisit,
    required this.awardedCoupons,
    required this.usedCoupons,
    this.usageVerificationCode,
    this.hiddenExplorerIncremented = false,
  });

  factory NfcCheckinResult.fromMap(Map<String, dynamic> data) {
    final coupons = (data['awardedCoupons'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final used = (data['usedCoupons'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    return NfcCheckinResult(
      stampsAfter: (data['stampsAfter'] as num?)?.toInt() ?? 0,
      cardCompleted: data['cardCompleted'] as bool? ?? false,
      storeName: data['storeName'] as String? ?? '',
      isFirstVisit: data['isFirstVisit'] as bool? ?? false,
      awardedCoupons: coupons,
      usedCoupons: used,
      usageVerificationCode: data['usageVerificationCode'] as String?,
      hiddenExplorerIncremented: data['hiddenExplorerIncremented'] as bool? ?? false,
    );
  }
}

class NfcCheckinService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  /// NFCタグを検証してチェックインセッションを作成する（10分間有効）
  Future<NfcCheckinSession> createCheckinSession({
    required String storeId,
    required String tagSecret,
  }) async {
    try {
      final callable = _functions.httpsCallable('createCheckinSession');
      final result = await callable.call({
        'storeId': storeId,
        'tagSecret': tagSecret,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return NfcCheckinSession(sessionToken: data['sessionToken'] as String);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          'createCheckinSession error: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('createCheckinSession error: $e');
      rethrow;
    }
  }

  /// チェックインを実行する（セッショントークン + 現在地を送信）
  Future<NfcCheckinResult> checkin({
    required String sessionToken,
    required double userLat,
    required double userLng,
    List<String>? selectedUserCouponIds,
  }) async {
    try {
      final callable = _functions.httpsCallable('nfcCheckin');
      final params = <String, dynamic>{
        'sessionToken': sessionToken,
        'userLat': userLat,
        'userLng': userLng,
      };
      if (selectedUserCouponIds != null && selectedUserCouponIds.isNotEmpty) {
        params['selectedUserCouponIds'] = selectedUserCouponIds;
      }
      final result = await callable.call(params);
      final data = Map<String, dynamic>.from(result.data as Map);
      return NfcCheckinResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          'NFC checkin error: code=${e.code}, message=${e.message}, details=${e.details}');
      rethrow;
    } catch (e) {
      debugPrint('NFC checkin error: $e');
      rethrow;
    }
  }
}
