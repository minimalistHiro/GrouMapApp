import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

final feedbackProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(FirebaseFirestore.instance);
});

class FeedbackService {
  final FirebaseFirestore _firestore;

  FeedbackService(this._firestore);

  // フィードバックを送信
  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String message,
    required String category,
  }) async {
    try {
      final feedback = FeedbackModel(
        id: _firestore.collection('feedback').doc().id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        subject: subject,
        message: message,
        category: category,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      await _firestore
          .collection('feedback')
          .doc(feedback.id)
          .set(feedback.toJson());

      print('フィードバックが送信されました: ${feedback.id}');
    } catch (e) {
      print('フィードバックの送信に失敗しました: $e');
      rethrow;
    }
  }

  // ユーザーのフィードバック履歴を取得
  Stream<List<FeedbackModel>> getUserFeedback(String userId) {
    return _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedbackModel.fromJson(doc.data()))
          .toList();
    });
  }

  // 全フィードバックを取得（管理者用）
  Stream<List<FeedbackModel>> getAllFeedback() {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedbackModel.fromJson(doc.data()))
          .toList();
    });
  }

  // フィードバックのステータスを更新（管理者用）
  Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
    String? adminResponse,
    String? respondedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminResponse != null) {
        updateData['adminResponse'] = adminResponse;
        updateData['respondedAt'] = FieldValue.serverTimestamp();
        updateData['respondedBy'] = respondedBy;
      }

      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .update(updateData);

      print('フィードバックステータスが更新されました: $feedbackId');
    } catch (e) {
      print('フィードバックステータスの更新に失敗しました: $e');
      rethrow;
    }
  }
}
