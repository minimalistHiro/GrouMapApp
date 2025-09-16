import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// 投稿モデル
class PostModel {
  final String id;
  final String title;
  final String content;
  final String? storeId;
  final String? storeName;
  final String? category;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int viewCount;
  final int likeCount;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.storeId,
    this.storeName,
    this.category,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.viewCount,
    required this.likeCount,
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String id) {
    return PostModel(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      storeId: data['storeId'],
      storeName: data['storeName'],
      category: data['category'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'storeId': storeId,
      'storeName': storeName,
      'category': category,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'viewCount': viewCount,
      'likeCount': likeCount,
    };
  }
}

// 投稿プロバイダー
final allPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['isActive'] == true;
        })
        .map((doc) {
          return PostModel.fromMap(doc.data(), doc.id);
        }).toList();
  }).handleError((error) {
    debugPrint('Error fetching posts: $error');
    return <PostModel>[];
  });
});

// 特定の店舗の投稿プロバイダー
final storePostsProvider = StreamProvider.family<List<PostModel>, String>((ref, storeId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('storeId', isEqualTo: storeId)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['isActive'] == true;
        })
        .map((doc) {
          return PostModel.fromMap(doc.data(), doc.id);
        }).toList();
  }).handleError((error) {
    debugPrint('Error fetching store posts: $error');
    // インデックスエラーの場合は空のリストを返す
    if (error.toString().contains('failed-precondition') || 
        error.toString().contains('requires an index')) {
      debugPrint('Index error detected, returning empty list');
      return <PostModel>[];
    }
    // その他のエラーの場合は空のリストを返す
    return <PostModel>[];
  });
});

// 投稿サービス
class PostsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 投稿を取得
  static Future<List<PostModel>> getPosts({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isActive'] == true;
          })
          .map((doc) {
            return PostModel.fromMap(doc.data(), doc.id);
          }).toList();
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }

  // 特定の店舗の投稿を取得
  static Future<List<PostModel>> getStorePosts(String storeId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isActive'] == true;
          })
          .map((doc) {
            return PostModel.fromMap(doc.data(), doc.id);
          }).toList();
    } catch (e) {
      debugPrint('Error getting store posts: $e');
      return [];
    }
  }

  // 投稿の閲覧数を増加
  static Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  // 投稿のいいね数を増加
  static Future<void> incrementLikeCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likeCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error incrementing like count: $e');
    }
  }
}
