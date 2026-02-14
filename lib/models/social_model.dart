import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_model.freezed.dart';
part 'social_model.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String displayName,
    required String? photoURL,
    required String? bio,
    required int totalPoints,
    required int badgeCount,
    required DateTime createdAt,
    required DateTime lastActiveAt,
    @Default([]) List<String> following,
    @Default([]) List<String> followers,
    @Default([]) List<String> blockedUsers,
    @Default(false) bool isPrivate,
    @Default(false) bool allowFollowRequests,
    @Default([]) List<String> interests,
    @Default({}) Map<String, dynamic> socialStats,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

@freezed
class FollowRequest with _$FollowRequest {
  const factory FollowRequest({
    required String id,
    required String fromUserId,
    required String toUserId,
    required DateTime createdAt,
    @Default(false) bool isAccepted,
    @Default(false) bool isDeclined,
    DateTime? respondedAt,
  }) = _FollowRequest;

  factory FollowRequest.fromJson(Map<String, dynamic> json) => _$FollowRequestFromJson(json);
}

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String userId,
    required String content,
    required PostType type,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<String> images,
    @Default([]) List<String> tags,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int shareCount,
    @Default([]) List<String> likedBy,
    @Default(false) bool isPublic,
    String? storeId,
    String? location,
    @Default({}) Map<String, dynamic> metadata,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String postId,
    required String userId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int likeCount,
    @Default([]) List<String> likedBy,
    String? parentCommentId,
    @Default([]) List<String> replies,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}

@freezed
class Like with _$Like {
  const factory Like({
    required String id,
    required String userId,
    required String targetId,
    required LikeType type,
    required DateTime createdAt,
  }) = _Like;

  factory Like.fromJson(Map<String, dynamic> json) => _$LikeFromJson(json);
}

enum PostType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
  @JsonValue('check_in')
  checkIn,
  @JsonValue('achievement')
  achievement,
  @JsonValue('review')
  review,
}

enum LikeType {
  @JsonValue('post')
  post,
  @JsonValue('comment')
  comment,
}

enum FollowStatus {
  @JsonValue('not_following')
  notFollowing,
  @JsonValue('following')
  following,
  @JsonValue('requested')
  requested,
  @JsonValue('blocked')
  blocked,
}
