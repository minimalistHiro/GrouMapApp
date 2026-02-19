import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/social_model.dart';
import 'badge_provider.dart';

// ソーシャルサービスプロバイダー
final socialProvider = Provider<SocialService>((ref) {
  return SocialService();
});

// ユーザープロフィールプロバイダー
final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  final socialService = ref.watch(socialProvider);
  return socialService.getUserProfile(userId);
});

// フォロー状態プロバイダー
final followStatusProvider = StreamProvider.family<FollowStatus, String>((ref, targetUserId) {
  final socialService = ref.watch(socialProvider);
  return socialService.getFollowStatus(targetUserId);
});

// フォロワー一覧プロバイダー
final followersProvider = StreamProvider.family<List<UserProfile>, String>((ref, userId) {
  final socialService = ref.watch(socialProvider);
  return socialService.getFollowers(userId);
});

// フォロー中一覧プロバイダー
final followingProvider = StreamProvider.family<List<UserProfile>, String>((ref, userId) {
  final socialService = ref.watch(socialProvider);
  return socialService.getFollowing(userId);
});

// 投稿一覧プロバイダー
final postsProvider = StreamProvider.family<List<Post>, String>((ref, userId) {
  final socialService = ref.watch(socialProvider);
  return socialService.getUserPosts(userId);
});

// フィード投稿プロバイダー
final feedPostsProvider = StreamProvider<List<Post>>((ref) {
  final socialService = ref.watch(socialProvider);
  return socialService.getFeedPosts()
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Feed posts provider error: $error');
    if (error.toString().contains('permission-denied')) {
      return <Post>[];
    }
    return <Post>[];
  });
});

// 投稿のコメントプロバイダー
final postCommentsProvider = StreamProvider.family<List<Comment>, String>((ref, postId) {
  final socialService = ref.watch(socialProvider);
  return socialService.getPostComments(postId);
});

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ユーザープロフィールを取得
  Stream<UserProfile?> getUserProfile(String userId) {
    try {
      return _firestore
          .collection('user_profiles')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return UserProfile.fromJson({
            'userId': userId,
            ...snapshot.data()!,
          });
        }
        return null;
      });
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return Stream.value(null);
    }
  }

  // ユーザープロフィールを作成・更新
  Future<void> createOrUpdateUserProfile({
    required String userId,
    required String displayName,
    required String? photoURL,
    String? bio,
    List<String> interests = const [],
  }) async {
    try {
      final profileData = {
        'userId': userId,
        'displayName': displayName,
        'photoURL': photoURL,
        'bio': bio,
        'interests': interests,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'following': [],
        'followers': [],
        'blockedUsers': [],
        'isPrivate': false,
        'allowFollowRequests': true,
        'socialStats': {},
      };

      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .set(profileData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating/updating user profile: $e');
      throw Exception('プロフィールの更新に失敗しました: $e');
    }
  }

  // フォロー状態を取得
  Stream<FollowStatus> getFollowStatus(String targetUserId) {
    try {
      // 実際の実装では、現在のユーザーIDを取得してフォロー状態を確認
      // ここでは簡略化してnotFollowingを返す
      return Stream.value(FollowStatus.notFollowing);
    } catch (e) {
      debugPrint('Error getting follow status: $e');
      return Stream.value(FollowStatus.notFollowing);
    }
  }

  // ユーザーをフォロー
  Future<void> followUser(String targetUserId) async {
    try {
      // 実際の実装では、現在のユーザーIDを取得してフォロー処理を実行
      debugPrint('Following user: $targetUserId');

      // バッジカウンター: フォロー
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        BadgeService().incrementBadgeCounter(currentUserId, 'followUser');
      }
    } catch (e) {
      debugPrint('Error following user: $e');
      throw Exception('フォローに失敗しました: $e');
    }
  }

  // ユーザーのフォローを解除
  Future<void> unfollowUser(String targetUserId) async {
    try {
      // 実際の実装では、現在のユーザーIDを取得してフォロー解除処理を実行
      debugPrint('Unfollowing user: $targetUserId');
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      throw Exception('フォロー解除に失敗しました: $e');
    }
  }

  // フォロワー一覧を取得
  Stream<List<UserProfile>> getFollowers(String userId) {
    try {
      return _firestore
          .collection('user_profiles')
          .where('followers', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserProfile.fromJson({
            'userId': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return Stream.value([]);
    }
  }

  // フォロー中一覧を取得
  Stream<List<UserProfile>> getFollowing(String userId) {
    try {
      return _firestore
          .collection('user_profiles')
          .where('following', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserProfile.fromJson({
            'userId': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting following: $e');
      return Stream.value([]);
    }
  }

  // 投稿を作成
  Future<void> createPost({
    required String userId,
    required String content,
    required PostType type,
    List<String> images = const [],
    List<String> tags = const [],
    String? storeId,
    String? location,
  }) async {
    try {
      final postData = {
        'userId': userId,
        'content': content,
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'images': images,
        'tags': tags,
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'likedBy': [],
        'isPublic': true,
        'storeId': storeId,
        'location': location,
        'metadata': {},
      };

      await _firestore.collection('posts').add(postData);
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('投稿の作成に失敗しました: $e');
    }
  }

  // ユーザーの投稿一覧を取得
  Stream<List<Post>> getUserPosts(String userId) {
    try {
      return _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Post.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return Stream.value([]);
    }
  }

  // フィード投稿を取得
  Stream<List<Post>> getFeedPosts() {
    try {
      return _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Post.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      }).handleError((error) {
        debugPrint('Error in feed posts stream: $error');
        // 権限エラーの場合は空のリストを返す
        if (error.toString().contains('permission-denied')) {
          return <Post>[];
        }
        // その他のエラーも空のリストを返す
        return <Post>[];
      });
    } catch (e) {
      debugPrint('Error getting feed posts: $e');
      return Stream.value([]);
    }
  }

  // コメントを作成
  Future<void> createComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final commentData = {
        'postId': postId,
        'userId': userId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'likedBy': [],
        'parentCommentId': parentCommentId,
        'replies': [],
      };

      await _firestore.collection('comments').add(commentData);

      // バッジカウンター: コメント投稿
      BadgeService().incrementBadgeCounter(userId, 'commentPosted');

      // 投稿のコメント数を更新
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error creating comment: $e');
      throw Exception('コメントの作成に失敗しました: $e');
    }
  }

  // 投稿のコメント一覧を取得
  Stream<List<Comment>> getPostComments(String postId) {
    try {
      return _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .where('parentCommentId', isNull: true)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Comment.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting post comments: $e');
      return Stream.value([]);
    }
  }

  // いいねを追加
  Future<void> likePost(String postId, String userId) async {
    try {
      final likeData = {
        'userId': userId,
        'targetId': postId,
        'type': LikeType.post.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('likes').add(likeData);

      // 投稿のいいね数を更新
      await _firestore.collection('posts').doc(postId).update({
        'likeCount': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });

      // バッジカウンター: いいね
      BadgeService().incrementBadgeCounter(userId, 'likeGiven');
    } catch (e) {
      debugPrint('Error liking post: $e');
      throw Exception('いいねに失敗しました: $e');
    }
  }

  // いいねを解除
  Future<void> unlikePost(String postId, String userId) async {
    try {
      // いいねレコードを削除
      final likesQuery = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .where('targetId', isEqualTo: postId)
          .where('type', isEqualTo: LikeType.post.name)
          .get();

      for (final doc in likesQuery.docs) {
        await doc.reference.delete();
      }

      // 投稿のいいね数を更新
      await _firestore.collection('posts').doc(postId).update({
        'likeCount': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error unliking post: $e');
      throw Exception('いいね解除に失敗しました: $e');
    }
  }
}
