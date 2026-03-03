import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class NfcCheckinResult {
  final int stampsAfter;
  final bool cardCompleted;
  final String storeName;
  final int coinsAdded;
  final List<Map<String, dynamic>> awardedCoupons;
  final List<Map<String, dynamic>> usedCoupons;
  final String? usageVerificationCode;

  NfcCheckinResult({
    required this.stampsAfter,
    required this.cardCompleted,
    required this.storeName,
    required this.coinsAdded,
    required this.awardedCoupons,
    required this.usedCoupons,
    this.usageVerificationCode,
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
      coinsAdded: (data['coinsAdded'] as num?)?.toInt() ?? 0,
      awardedCoupons: coupons,
      usedCoupons: used,
      usageVerificationCode: data['usageVerificationCode'] as String?,
    );
  }
}

class NfcCheckinService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  Future<NfcCheckinResult> checkin({
    required String storeId,
    required String tagSecret,
    List<String>? selectedUserCouponIds,
  }) async {
    try {
      final callable = _functions.httpsCallable('nfcCheckin');
      final params = <String, dynamic>{
        'storeId': storeId,
        'tagSecret': tagSecret,
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
