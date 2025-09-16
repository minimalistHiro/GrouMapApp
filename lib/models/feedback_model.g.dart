// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedbackModelImpl _$$FeedbackModelImplFromJson(Map<String, dynamic> json) =>
    _$FeedbackModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String,
      adminResponse: json['adminResponse'] as String?,
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      respondedBy: json['respondedBy'] as String?,
    );

Map<String, dynamic> _$$FeedbackModelImplToJson(_$FeedbackModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'userEmail': instance.userEmail,
      'subject': instance.subject,
      'message': instance.message,
      'category': instance.category,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': instance.status,
      'adminResponse': instance.adminResponse,
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'respondedBy': instance.respondedBy,
    };
