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
    };
  }
}

// 投稿プロバイダー
final allPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('posts')
      .limit(50)
      .snapshots()
      .map((snapshot) {
    final posts = snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList();

    // クライアント側フィルタで公開中かつ有効のみを表示（複合インデックス不要化）
    final filtered = posts.where((p) => p.isActive == true).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }).handleError((error) {
    debugPrint('Error fetching posts (collectionGroup): $error');
    return <PostModel>[];
  });
});

// 特定の店舗の投稿プロバイダー
final storePostsProvider = StreamProvider.family<List<PostModel>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collectionGroup('posts')
        .where('storeId', isEqualTo: storeId)
        .limit(20)
        .snapshots()
        .timeout(
          const Duration(seconds: 3),
          onTimeout: (eventSink) {
            debugPrint('Store posts query timed out, returning empty list');
          },
        )
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((p) => p.isActive == true)
          .toList();

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('Store posts (collectionGroup) loaded: ${posts.length} posts');
      return posts;
    }).handleError((error) {
      debugPrint('Error fetching store posts (collectionGroup): $error');
      return <PostModel>[];
    });
  } catch (e) {
    debugPrint('Exception in storePostsProvider: $e');
    return Stream.value(<PostModel>[]);
  }
});

// フォールバック用の投稿プロバイダー（インデックスエラーを完全に回避）
final storePostsFallbackProvider = FutureProvider.family<List<PostModel>, String>((ref, storeId) async {
  try {
    debugPrint('Using fallback provider for store: $storeId');
    
    // より単純なクエリで投稿を取得
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('storeId', isEqualTo: storeId)
        .get()
        .timeout(const Duration(seconds: 2));
    
    final posts = snapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['isActive'] == true;
        })
        .map((doc) {
          return PostModel.fromMap(doc.data(), doc.id);
        })
        .toList();
    
    // クライアント側でソート
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    debugPrint('Fallback provider loaded: ${posts.length} posts');
    return posts;
  } catch (e) {
    debugPrint('Fallback provider error: $e');
    return <PostModel>[];
  }
});

// 投稿サービス
class PostsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 投稿を取得
  static Future<List<PostModel>> getPosts({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('posts')
          .limit(limit)
          .get();

      final items = snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isActive'] == true;
          })
          .map((doc) {
            return PostModel.fromMap(doc.data(), doc.id);
          }).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }

  // 特定の店舗の投稿を取得
  static Future<List<PostModel>> getStorePosts(String storeId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('posts')
          .where('storeId', isEqualTo: storeId)
          .limit(limit)
          .get();

      final items = snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isActive'] == true;
          })
          .map((doc) {
            return PostModel.fromMap(doc.data(), doc.id);
          }).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
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
