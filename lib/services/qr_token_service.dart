import 'dart:convert';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRTokenService {
  
  /// Firebase Functions経由でJWTトークンを発行
  static Future<Map<String, dynamic>> issueToken({String? deviceId}) async {
    try {
      print('QRTokenService: トークン発行を開始');
      
      // Firebase Functionsがデプロイされていない場合のモック実装
      final user = FirebaseAuth.instance.currentUser;
      print('QRTokenService: 現在のユーザー: ${user?.uid}');
      
      if (user == null) {
        print('QRTokenService: ユーザーがログインしていない');
        throw Exception('ユーザーがログインしていません');
      }
      
      // モックJWTトークンを生成
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(seconds: 60));
      final jti = _generateRandomId();
      
      print('QRTokenService: トークン有効期限: $expiresAt');
      
      // 簡単なJWTペイロード（実際のJWTではないが、テスト用）
      final payload = {
        'sub': user.uid,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
        'jti': jti,
        'ver': 1,
      };
      
      final token = base64Encode(utf8.encode(jsonEncode(payload)));
      
      print('QRTokenService: モックトークン生成成功 - トークン長: ${token.length}');
      
      final result = {
        'token': token,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'jti': jti,
      };
      
      print('QRTokenService: 結果返却: ${result.keys}');
      return result;
      
      // 実際のFirebase Functions呼び出し（コメントアウト）
      /*
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('issueQrToken');
      
      print('QRTokenService: Firebase Functions callable作成完了');
      
      final result = await callable.call({
        if (deviceId != null) 'deviceId': deviceId,
      });
      
      print('QRTokenService: トークン発行成功: ${result.data}');
      
      return {
        'token': result.data['token'],
        'expiresAt': result.data['expiresAt'],
        'jti': result.data['jti'],
      };
      */
    } catch (e) {
      print('QRTokenService: トークン発行エラー: $e');
      print('QRTokenService: エラータイプ: ${e.runtimeType}');
      rethrow;
    }
  }
  
  /// ランダムIDを生成
  static String _generateRandomId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
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
