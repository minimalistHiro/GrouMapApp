import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_model.freezed.dart';
part 'feedback_model.g.dart';

@freezed
class FeedbackModel with _$FeedbackModel {
  const factory FeedbackModel({
    required String id,
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String message,
    required String category,
    required DateTime createdAt,
    required String status, // 'pending', 'in_progress', 'resolved', 'closed'
    required DateTime updatedAt,
  }) = _FeedbackModel;

  factory FeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FeedbackModelFromJson(json);
}


