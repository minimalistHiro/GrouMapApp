import 'dart:convert';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_transaction_model.dart';

class QRService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // JWT署名用の秘密鍵（本番環境では環境変数から取得）
  static const String _secretKey = 'groumap_secret_key_2024';
  
  // QRコード生成
  Future<QRCodeData> generateQRCode({
    required String storeId,
    required int points,
    required String createdBy,
    String? description,
    Duration? expiresIn,
  }) async {
    try {
      final qrCodeId = _generateQRCodeId();
      final expiresAt = DateTime.now().add(expiresIn ?? const Duration(hours: 1));
      
      // JWTペイロードを作成
      final payload = {
        'qrCodeId': qrCodeId,
        'storeId': storeId,
        'points': points,
        'createdBy': createdBy,
        'description': description,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'iat': DateTime.now().millisecondsSinceEpoch,
      };
      
      // JWTトークンを生成
      final jwt = JWT(payload);
      final token = jwt.sign(SecretKey(_secretKey));
      
      // QRコードデータを作成
      final qrCodeData = QRCodeData(
        qrCodeId: qrCodeId,
        storeId: storeId,
        points: points,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        description: description,
        token: token,
      );
      
      // Firestoreに保存
      await _firestore
          .collection('qr_codes')
          .doc(qrCodeId)
          .set(qrCodeData.toJson());
      
      return qrCodeData;
    } catch (e) {
      throw Exception('QRコード生成に失敗しました: $e');
    }
  }
  
  // QRコード検証
  Future<QRCodeValidationResult> validateQRCode(String token) async {
    try {
      // JWTトークンを検証
      final jwt = JWT.verify(token, SecretKey(_secretKey));
      final payload = jwt.payload;
      
      final qrCodeId = payload['qrCodeId'] as String;
      final storeId = payload['storeId'] as String;
      final points = payload['points'] as int;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(payload['expiresAt'] as int);
      
      // 期限切れチェック
      if (expiresAt.isBefore(DateTime.now())) {
        return QRCodeValidationResult(
          isValid: false,
          error: 'QRコードの有効期限が切れています',
        );
      }
      
      // FirestoreでQRコードの状態を確認
      final qrCodeDoc = await _firestore
          .collection('qr_codes')
          .doc(qrCodeId)
          .get();
      
      if (!qrCodeDoc.exists) {
        return QRCodeValidationResult(
          isValid: false,
          error: 'QRコードが見つかりません',
        );
      }
      
      final qrCodeData = QRCodeData.fromJson({
        ...qrCodeDoc.data()!,
        'qrCodeId': qrCodeDoc.id,
      });
      
      if (qrCodeData.isUsed) {
        return QRCodeValidationResult(
          isValid: false,
          error: 'このQRコードは既に使用されています',
        );
      }
      
      return QRCodeValidationResult(
        isValid: true,
        qrCodeData: qrCodeData,
      );
    } catch (e) {
      return QRCodeValidationResult(
        isValid: false,
        error: 'QRコードの検証に失敗しました: $e',
      );
    }
  }
  
  // QRコード使用
  Future<void> useQRCode({
    required String qrCodeId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final qrCodeRef = _firestore.collection('qr_codes').doc(qrCodeId);
        final qrCodeDoc = await transaction.get(qrCodeRef);
        
        if (!qrCodeDoc.exists) {
          throw Exception('QRコードが見つかりません');
        }
        
        final qrCodeData = QRCodeData.fromJson({
          ...qrCodeDoc.data()!,
          'qrCodeId': qrCodeDoc.id,
        });
        
        if (qrCodeData.isUsed) {
          throw Exception('このQRコードは既に使用されています');
        }
        
        if (qrCodeData.expiresAt.isBefore(DateTime.now())) {
          throw Exception('QRコードの有効期限が切れています');
        }
        
        // QRコードを使用済みにマーク
        transaction.update(qrCodeRef, {
          'isUsed': true,
          'usedBy': userId,
          'usedAt': DateTime.now(),
        });
      });
    } catch (e) {
      throw Exception('QRコード使用に失敗しました: $e');
    }
  }
  
  // QRコードID生成
  String _generateQRCodeId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'qr_${timestamp}_$randomNum';
  }
  
  // QRコード履歴取得
  Future<List<QRCodeData>> getQRCodeHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('qr_codes')
          .where('usedBy', isEqualTo: userId)
          .orderBy('usedAt', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs
          .map((doc) => QRCodeData.fromJson({
                ...doc.data(),
                'qrCodeId': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('QRコード履歴の取得に失敗しました: $e');
    }
  }
}

// QRコードデータクラス
class QRCodeData {
  final String qrCodeId;
  final String storeId;
  final int points;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String createdBy;
  final String? description;
  final String token;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  
  QRCodeData({
    required this.qrCodeId,
    required this.storeId,
    required this.points,
    required this.expiresAt,
    required this.createdAt,
    required this.createdBy,
    this.description,
    required this.token,
    this.isUsed = false,
    this.usedBy,
    this.usedAt,
  });
  
  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      qrCodeId: json['qrCodeId'] as String,
      storeId: json['storeId'] as String,
      points: json['points'] as int,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      createdBy: json['createdBy'] as String,
      description: json['description'] as String?,
      token: json['token'] as String,
      isUsed: json['isUsed'] as bool? ?? false,
      usedBy: json['usedBy'] as String?,
      usedAt: json['usedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['usedAt'] as int)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'qrCodeId': qrCodeId,
      'storeId': storeId,
      'points': points,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'description': description,
      'token': token,
      'isUsed': isUsed,
      'usedBy': usedBy,
      'usedAt': usedAt?.millisecondsSinceEpoch,
    };
  }
}

// QRコード検証結果
class QRCodeValidationResult {
  final bool isValid;
  final String? error;
  final QRCodeData? qrCodeData;
  
  QRCodeValidationResult({
    required this.isValid,
    this.error,
    this.qrCodeData,
  });
}
