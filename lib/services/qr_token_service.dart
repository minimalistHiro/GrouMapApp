import 'package:cloud_functions/cloud_functions.dart';

class QRTokenService {
  
  /// Firebase Functions経由でJWTトークンを発行
  static Future<Map<String, dynamic>> issueToken({String? deviceId}) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('issueQrToken');
      
      final result = await callable.call({
        if (deviceId != null) 'deviceId': deviceId,
      });
      
      return {
        'token': result.data['token'],
        'expiresAt': result.data['expiresAt'],
        'jti': result.data['jti'],
      };
    } catch (e) {
      print('トークン発行エラー: $e');
      rethrow;
    }
  }
  
  /// Firebase Functions経由でトークンを検証（店舗アプリ用）
  static Future<Map<String, dynamic>> verifyToken(String token, String storeId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('verifyQrToken');
      
      final result = await callable.call({
        'token': token,
        'storeId': storeId,
      });
      
      return {
        'uid': result.data['uid'],
        'status': result.data['status'],
        'jti': result.data['jti'],
      };
    } catch (e) {
      print('トークン検証エラー: $e');
      rethrow;
    }
  }
  
  /// トークンの残り有効時間を取得（秒）
  static int getRemainingSeconds(int expiresAt) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = (expiresAt - now) ~/ 1000;
    return remaining > 0 ? remaining : 0;
  }
  
  /// トークンが期限切れかチェック
  static bool isTokenExpired(int expiresAt) {
    return getRemainingSeconds(expiresAt) <= 0;
  }
}
