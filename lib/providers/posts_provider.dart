import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

Stream<List<PostModel>> _instagramPostsStream({
  required Query<Map<String, dynamic>> query,
  required String logLabel,
}) async* {
  try {
    await for (final snapshot in query.snapshots()) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromInstagramMap(doc.data(), doc.id))
          .where((p) => p.isActive == true && p.imageUrls.isNotEmpty)
          .toList();
      yield posts;
    }
  } on FirebaseException catch (error) {
    debugPrint('Error fetching $logLabel instagram posts: $error');
    if (error.code == 'permission-denied') {
      yield <PostModel>[];
      return;
    }
    rethrow;
  }
}

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
  final String source;
  final String? permalink;
  final String? storeIconImageUrl;
  final String? storeCategory;

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
    this.source = 'app',
    this.permalink,
    this.storeIconImageUrl,
    this.storeCategory,
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
      source: data['source'] ?? 'app',
      permalink: data['permalink']?.toString(),
      storeIconImageUrl: data['storeIconImageUrl']?.toString(),
      storeCategory: data['storeCategory']?.toString(),
    );
  }

  factory PostModel.fromInstagramMap(Map<String, dynamic> data, String id) {
    final mediaType = (data['mediaType'] ?? '').toString();
    final mediaUrl = (data['mediaUrl'] ?? '').toString();
    final thumbnailUrl = (data['thumbnailUrl'] ?? '').toString();
    final rawImageUrls = data['imageUrls'];
    final imageUrls = <String>[];

    if (rawImageUrls is List) {
      for (final url in rawImageUrls) {
        final parsed = url?.toString() ?? '';
        if (parsed.isNotEmpty) {
          imageUrls.add(parsed);
        }
      }
    }

    if (imageUrls.isEmpty) {
      if (mediaType == 'VIDEO') {
        if (thumbnailUrl.isNotEmpty) {
          imageUrls.add(thumbnailUrl);
        }
      } else if (mediaUrl.isNotEmpty) {
        imageUrls.add(mediaUrl);
      }
    }
    return PostModel(
      id: id,
      title: (data['storeName'] ?? 'Instagramの投稿').toString(),
      content: (data['caption'] ?? '').toString(),
      storeId: data['storeId']?.toString(),
      storeName: data['storeName']?.toString(),
      category: data['category']?.toString() ?? 'Instagram',
      imageUrls: imageUrls,
      createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      viewCount: data['viewCount'] ?? 0,
      source: 'instagram',
      permalink: data['permalink']?.toString(),
      storeIconImageUrl: data['storeIconImageUrl']?.toString(),
      storeCategory: data['storeCategory']?.toString(),
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
      'source': source,
      'storeCategory': storeCategory,
    };
  }
}

class InstagramSearchPostsState {
  final List<PostModel> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const InstagramSearchPostsState({
    required this.items,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
  });

  factory InstagramSearchPostsState.initial() {
    return const InstagramSearchPostsState(
      items: <PostModel>[],
      isInitialLoading: false,
      isLoadingMore: false,
      hasMore: true,
      errorMessage: null,
    );
  }

  InstagramSearchPostsState copyWith({
    List<PostModel>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InstagramSearchPostsState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InstagramSearchPostsNotifier
    extends StateNotifier<InstagramSearchPostsState> {
  static const int _pageSize = 51;
  static const int _maxItems = 306;

  final FirebaseFirestore _firestore;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  InstagramSearchPostsNotifier({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(InstagramSearchPostsState.initial());

  Future<void> loadInitial() async {
    if (state.isInitialLoading) return;

    _lastDoc = null;
    state = state.copyWith(
      items: <PostModel>[],
      isInitialLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
    );

    try {
      final page = await _fetchPage();
      state = state.copyWith(
        items: page.items,
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: page.hasMore,
        clearError: true,
      );
    } catch (e) {
      debugPrint('Error loading initial instagram search posts: $e');
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: false,
        errorMessage: '投稿の取得に失敗しました',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.items.length >= _maxItems) {
      state = state.copyWith(hasMore: false);
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final remaining = _maxItems - state.items.length;
      final page = await _fetchPage(remaining: remaining);
      final merged = <PostModel>[
        ...state.items,
        ...page.items,
      ];
      final clipped = merged.take(_maxItems).toList();
      state = state.copyWith(
        items: clipped,
        isLoadingMore: false,
        hasMore: page.hasMore && clipped.length < _maxItems,
      );
    } catch (e) {
      debugPrint('Error loading more instagram search posts: $e');
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: '投稿の取得に失敗しました',
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<_InstagramSearchPage> _fetchPage({int? remaining}) async {
    final queryLimit = _resolveLimit(remaining);
    Query<Map<String, dynamic>> query = _firestore
        .collection('public_instagram_posts')
        .where('isVideo', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(queryLimit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
    }

    final items = snapshot.docs
        .map((doc) => PostModel.fromInstagramMap(doc.data(), doc.id))
        .where((post) => post.isActive == true && post.imageUrls.isNotEmpty)
        .toList();
    final hasMore = snapshot.docs.length == queryLimit;

    return _InstagramSearchPage(items: items, hasMore: hasMore);
  }

  int _resolveLimit(int? remaining) {
    if (remaining == null || remaining >= _pageSize) {
      return _pageSize;
    }
    return remaining <= 0 ? 1 : remaining;
  }
}

class _InstagramSearchPage {
  final List<PostModel> items;
  final bool hasMore;

  const _InstagramSearchPage({
    required this.items,
    required this.hasMore,
  });
}

final instagramSearchPostsProvider = StateNotifierProvider<
    InstagramSearchPostsNotifier, InstagramSearchPostsState>((ref) {
  final notifier = InstagramSearchPostsNotifier();
  notifier.loadInitial();
  return notifier;
});

// 投稿プロバイダー
final allPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('public_posts')
      .limit(51)
      .snapshots()
      .map((snapshot) {
    final posts = snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList();

    // クライアント側フィルタで公開中かつ有効のみを表示（複合インデックス不要化）
    final filtered = posts.where((p) => p.isActive == true && p.imageUrls.isNotEmpty).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }).handleError((error) {
    debugPrint('Error fetching posts (collectionGroup): $error');
    return <PostModel>[];
  });
});

// Instagram公開投稿（ホーム用）
final publicInstagramPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final query = FirebaseFirestore.instance
      .collection('public_instagram_posts')
      .where('isVideo', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .limit(10);
  return _instagramPostsStream(
    query: query,
    logLabel: 'public',
  );
});

// 通常投稿（ホーム用）
final appPostsHomeProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('public_posts')
      .limit(10)
      .snapshots()
      .map((snapshot) {
    final posts = snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .where((p) => p.isActive && p.imageUrls.isNotEmpty)
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }).handleError((error) {
    debugPrint('Error fetching app posts for home: $error');
    return <PostModel>[];
  });
});

// 統一フィード（ホーム用）: Instagram投稿 + 通常投稿を日付順で混合
final unifiedHomePostsProvider =
    Provider<AsyncValue<List<PostModel>>>((ref) {
  final instagram = ref.watch(publicInstagramPostsProvider);
  final appPosts = ref.watch(appPostsHomeProvider);

  if (instagram is AsyncLoading<List<PostModel>> &&
      appPosts is AsyncLoading<List<PostModel>>) {
    return const AsyncValue.loading();
  }

  final instagramList = instagram.valueOrNull ?? [];
  final appList = appPosts.valueOrNull ?? [];
  final merged = [...instagramList, ...appList];
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(merged.take(10).toList());
});

// 統一フィード状態（投稿一覧用）
class UnifiedFeedState {
  final List<PostModel> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const UnifiedFeedState({
    required this.items,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
  });

  factory UnifiedFeedState.initial() {
    return const UnifiedFeedState(
      items: <PostModel>[],
      isInitialLoading: false,
      isLoadingMore: false,
      hasMore: true,
      errorMessage: null,
    );
  }

  UnifiedFeedState copyWith({
    List<PostModel>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UnifiedFeedState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// 統一フィードNotifier（投稿一覧用）: 2コレクションからページネーション取得
class UnifiedFeedNotifier extends StateNotifier<UnifiedFeedState> {
  static const int _pageSize = 51;
  static const int _maxItems = 306;

  final FirebaseFirestore _firestore;
  DocumentSnapshot<Map<String, dynamic>>? _lastInstagramDoc;
  DocumentSnapshot<Map<String, dynamic>>? _lastAppDoc;
  bool _instagramHasMore = true;
  bool _appHasMore = true;

  UnifiedFeedNotifier({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(UnifiedFeedState.initial());

  Future<void> loadInitial() async {
    if (state.isInitialLoading) return;

    _lastInstagramDoc = null;
    _lastAppDoc = null;
    _instagramHasMore = true;
    _appHasMore = true;

    state = state.copyWith(
      items: <PostModel>[],
      isInitialLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
    );

    try {
      final items = await _fetchMergedPage();
      state = state.copyWith(
        items: items,
        isInitialLoading: false,
        hasMore: _instagramHasMore || _appHasMore,
        clearError: true,
      );
    } catch (e) {
      debugPrint('Error loading initial unified feed: $e');
      state = state.copyWith(
        isInitialLoading: false,
        hasMore: false,
        errorMessage: '投稿の取得に失敗しました',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.items.length >= _maxItems) {
      state = state.copyWith(hasMore: false);
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final newItems = await _fetchMergedPage();
      final merged = [...state.items, ...newItems];
      final clipped = merged.take(_maxItems).toList();
      state = state.copyWith(
        items: clipped,
        isLoadingMore: false,
        hasMore: (_instagramHasMore || _appHasMore) &&
            clipped.length < _maxItems,
      );
    } catch (e) {
      debugPrint('Error loading more unified feed: $e');
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: '投稿の取得に失敗しました',
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<List<PostModel>> _fetchMergedPage() async {
    final results = <PostModel>[];

    // Instagram投稿を取得
    if (_instagramHasMore) {
      Query<Map<String, dynamic>> igQuery = _firestore
          .collection('public_instagram_posts')
          .where('isVideo', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);
      if (_lastInstagramDoc != null) {
        igQuery = igQuery.startAfterDocument(_lastInstagramDoc!);
      }
      final igSnap = await igQuery.get();
      if (igSnap.docs.isNotEmpty) {
        _lastInstagramDoc = igSnap.docs.last;
      }
      _instagramHasMore = igSnap.docs.length == _pageSize;
      results.addAll(
        igSnap.docs
            .map((doc) => PostModel.fromInstagramMap(doc.data(), doc.id))
            .where((p) => p.isActive && p.imageUrls.isNotEmpty),
      );
    }

    // 通常投稿を取得
    if (_appHasMore) {
      Query<Map<String, dynamic>> appQuery = _firestore
          .collection('public_posts')
          .limit(_pageSize);
      if (_lastAppDoc != null) {
        appQuery = appQuery.startAfterDocument(_lastAppDoc!);
      }
      final appSnap = await appQuery.get();
      if (appSnap.docs.isNotEmpty) {
        _lastAppDoc = appSnap.docs.last;
      }
      _appHasMore = appSnap.docs.length == _pageSize;
      results.addAll(
        appSnap.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .where((p) => p.isActive && p.imageUrls.isNotEmpty),
      );
    }

    // 日付順でソート
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 1店舗あたり51件に制限（3で割り切れる数）
    final storeCount = <String, int>{};
    final limited = <PostModel>[];
    for (final post in results) {
      final sid = post.storeId ?? '';
      final count = storeCount[sid] ?? 0;
      if (count < 51) {
        limited.add(post);
        storeCount[sid] = count + 1;
      }
    }
    return limited;
  }
}

final unifiedFeedProvider =
    StateNotifierProvider<UnifiedFeedNotifier, UnifiedFeedState>((ref) {
  final notifier = UnifiedFeedNotifier();
  notifier.loadInitial();
  return notifier;
});

// 店舗のInstagram投稿（店舗詳細用）
final storeInstagramPostsProvider =
    StreamProvider.family<List<PostModel>, String>((ref, storeId) {
  final query = FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('instagram_posts')
      .where('isVideo', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .limit(51);
  return _instagramPostsStream(
    query: query,
    logLabel: 'store',
  );
});

// 特定の店舗の投稿プロバイダー
final storePostsProvider =
    StreamProvider.family<List<PostModel>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('public_posts')
        .where('storeId', isEqualTo: storeId)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((p) => p.isActive == true && p.imageUrls.isNotEmpty)
          .toList();

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('Store posts (collectionGroup) loaded: ${posts.length} posts');
      return posts;
    }).timeout(
      const Duration(seconds: 3),
      onTimeout: (eventSink) {
        debugPrint('Store posts query timed out, returning empty list');
        eventSink.add(<PostModel>[]);
        eventSink.close();
      },
    ).handleError((error) {
      debugPrint('Error fetching store posts (collectionGroup): $error');
      return <PostModel>[];
    });
  } catch (e) {
    debugPrint('Exception in storePostsProvider: $e');
    return Stream.value(<PostModel>[]);
  }
});

// 店舗配下の投稿プロバイダー（posts/{storeId}/posts）
final storePostsNestedProvider =
    StreamProvider.family<List<PostModel>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(storeId)
        .collection('posts')
        .limit(51)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((p) => p.isActive == true && p.imageUrls.isNotEmpty)
          .toList();

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('Store posts (nested) loaded: ${posts.length} posts');
      return posts;
    }).handleError((error) {
      debugPrint('Error fetching store posts (nested): $error');
      return <PostModel>[];
    });
  } catch (e) {
    debugPrint('Exception in storePostsNestedProvider: $e');
    return Stream.value(<PostModel>[]);
  }
});

// 店舗の統一投稿プロバイダー（店舗詳細用: Instagram + 通常投稿を混合、最大50件）
final storeUnifiedPostsProvider =
    Provider.family<AsyncValue<List<PostModel>>, String>((ref, storeId) {
  final igPosts = ref.watch(storeInstagramPostsProvider(storeId));
  final regularPosts = ref.watch(storePostsNestedProvider(storeId));

  if (igPosts is AsyncLoading<List<PostModel>> &&
      regularPosts is AsyncLoading<List<PostModel>>) {
    return const AsyncValue.loading();
  }

  final igList = igPosts.valueOrNull ?? [];
  final regularList = regularPosts.valueOrNull ?? [];
  final merged = [...igList, ...regularList];
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(merged.take(51).toList());
});

// フォールバック用の投稿プロバイダー（インデックスエラーを完全に回避）
final storePostsFallbackProvider =
    FutureProvider.family<List<PostModel>, String>((ref, storeId) async {
  try {
    debugPrint('Using fallback provider for store: $storeId');

    // より単純なクエリで投稿を取得
    final snapshot = await FirebaseFirestore.instance
        .collection('public_posts')
        .where('storeId', isEqualTo: storeId)
        .get()
        .timeout(const Duration(seconds: 2));

    final posts = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['isActive'] == true;
    }).map((doc) {
      return PostModel.fromMap(doc.data(), doc.id);
    }).toList();

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
      final snapshot =
          await _firestore.collection('public_posts').limit(limit).get();

      final items = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isActive'] == true;
      }).map((doc) {
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
  static Future<List<PostModel>> getStorePosts(String storeId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('public_posts')
          .where('storeId', isEqualTo: storeId)
          .limit(limit)
          .get();

      final items = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isActive'] == true;
      }).map((doc) {
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
      await _firestore.collection('public_posts').doc(postId).update({
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
      await _firestore.collection('public_posts').doc(postId).update({
        'likeCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error incrementing like count: $e');
    }
  }
}
