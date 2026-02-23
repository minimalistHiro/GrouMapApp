import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/posts_provider.dart';
import '../../services/mission_service.dart';
import '../../widgets/common_header.dart';

class PostDetailView extends ConsumerStatefulWidget {
  final PostModel post;
  
  const PostDetailView({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  ConsumerState<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends ConsumerState<PostDetailView> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  bool _isLiked = false;
  int _likeCount = 0;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  bool _hasRecordedView = false; // 閲覧記録の重複を防ぐフラグ
  late final bool _isInstagramPost;
  String? _storeIconUrl;

  DocumentReference<Map<String, dynamic>> _postDocRef() {
    if (_isInstagramPost) {
      return FirebaseFirestore.instance
          .collection('public_instagram_posts')
          .doc(widget.post.id);
    }
    final storeId = widget.post.storeId;
    if (storeId == null || storeId.isEmpty) {
      throw Exception('storeIdが取得できません');
    }
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(storeId)
        .collection('posts')
        .doc(widget.post.id);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isInstagramPost = widget.post.source == 'instagram';
    _storeIconUrl = widget.post.storeIconImageUrl;
    _loadStoreIcon();
    _loadComments();
    _checkIfLiked();
    _loadLikeCount();
    _recordView();
    _markFeedViewMission();
  }

  Future<void> _markFeedViewMission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // 新規登録ミッション完了済みの場合のみデイリーミッションを実行
    final missionService = MissionService();
    final regComplete = await missionService.isRegistrationComplete(user.uid);
    if (regComplete) {
      missionService.markDailyMission(user.uid, 'feed_view');
    }
  }

  Future<void> _loadStoreIcon() async {
    if (_storeIconUrl != null && _storeIconUrl!.isNotEmpty) return;
    final storeId = widget.post.storeId;
    if (storeId == null || storeId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();
      if (doc.exists && mounted) {
        final iconUrl = doc.data()?['iconImageUrl']?.toString();
        if (iconUrl != null && iconUrl.isNotEmpty) {
          setState(() {
            _storeIconUrl = iconUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('店舗アイコン取得エラー: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が表示された時にも閲覧を記録（より確実にするため）
    _recordView();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final likeDoc = await _postDocRef()
          .collection('likes')
          .doc(user.uid)
          .get();

      setState(() {
        _isLiked = likeDoc.exists;
      });
    } catch (e) {
      print('いいね状態確認エラー: $e');
    }
  }

  Future<void> _loadLikeCount() async {
    try {
      final snapshot = await _postDocRef().collection('likes').get();

      setState(() {
        _likeCount = snapshot.docs.length;
      });
    } catch (e) {
      print('いいね数取得エラー: $e');
    }
  }

  Future<void> _loadComments() async {
    try {
      final snapshot = await _postDocRef()
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _comments = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'userId': data['userId'],
            'userName': data['userName'],
            'content': data['content'],
            'createdAt': data['createdAt'],
          };
        }).toList();
        _isLoadingComments = false;
      });
    } catch (e) {
      print('コメント読み込みエラー: $e');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _recordView() async {
    // 既に記録済みの場合はスキップ
    if (_hasRecordedView) {
      print('既にローカルで閲覧記録済みです: ${widget.post.id}');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ ユーザーがログインしていません');
        return;
      }

      print('📊 投稿閲覧を記録開始: ${widget.post.id} by ${user.uid}');

      // 閲覧履歴を記録（重複を避けるため、既存の閲覧記録をチェック）
      final viewRef = _postDocRef().collection('views').doc(user.uid);

      print('🔍 既存の閲覧記録をチェック中...');
      final viewDoc = await viewRef.get();
      
      if (!viewDoc.exists) {
        print('✨ 初回閲覧として記録します');
        
        // 初回閲覧の場合のみ記録
        await _saveViewRecord(viewRef, user);
        await _updatePostViewCount(widget.post.id);

        // ローカルフラグを設定
        _hasRecordedView = true;

        print('🎉 閲覧記録が正常に完了しました: ${widget.post.id}');
      } else {
        print('ℹ️ 既に閲覧済みです: ${widget.post.id}');
        print('📄 既存の閲覧記録: ${viewDoc.data()}');
        _hasRecordedView = true; // 既に記録済みの場合もフラグを設定
      }
    } catch (e) {
      print('❌ 閲覧履歴記録エラー: $e');
      print('🔍 エラーの詳細: ${e.toString()}');
      // エラーが発生してもアプリがクラッシュしないようにする
    }
  }

  // 閲覧履歴を保存するメソッド
  Future<void> _saveViewRecord(DocumentReference viewRef, User user) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('💾 閲覧履歴をデータベースに保存中... (試行 ${retryCount + 1}/$maxRetries)');
        
        // タイムアウトを設定して書き込みを実行
        await viewRef.set({
          'userId': user.uid,
          'userName': user.displayName ?? '匿名ユーザー',
          'userEmail': user.email ?? '',
          'viewedAt': FieldValue.serverTimestamp(),
          'postId': widget.post.id,
          'postTitle': widget.post.title,
        }).timeout(const Duration(seconds: 10));
        
        print('✅ 閲覧履歴の保存が完了しました');
        return; // 成功したら終了
      } catch (e) {
        retryCount++;
        print('❌ 閲覧履歴の保存に失敗 (試行 $retryCount/$maxRetries): $e');
        
        if (retryCount >= maxRetries) {
          print('❌ 最大再試行回数に達しました。閲覧履歴の保存を諦めます。');
          rethrow;
        }
        
        // 再試行前に少し待機
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

  // 投稿の閲覧数を更新するメソッド
  Future<void> _updatePostViewCount(String postId) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('📈 投稿の閲覧数を更新中... (試行 ${retryCount + 1}/$maxRetries)');
        
        // タイムアウトを設定して書き込みを実行
        await _postDocRef().update({
          'viewCount': FieldValue.increment(1),
          'lastViewedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10));
        
        print('✅ 閲覧数の更新が完了しました');
        return; // 成功したら終了
      } catch (e) {
        retryCount++;
        print('❌ 閲覧数の更新に失敗 (試行 $retryCount/$maxRetries): $e');
        
        if (retryCount >= maxRetries) {
          print('❌ 最大再試行回数に達しました。閲覧数の更新を諦めます。');
          rethrow;
        }
        
        // 再試行前に少し待機
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final postsRef = _postDocRef();
      final likeRef = postsRef.collection('likes').doc(user.uid);

      if (_isLiked) {
        // いいねを削除
        final batch = FirebaseFirestore.instance.batch();
        batch.delete(likeRef);
        batch.delete(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('liked_posts')
              .doc(widget.post.id),
        );
        batch.update(postsRef, {
          'likeCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
        });
        await batch.commit();
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        // いいねを追加
        final batch = FirebaseFirestore.instance.batch();
        batch.set(likeRef, {
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('liked_posts')
              .doc(widget.post.id),
          {
            'postId': widget.post.id,
            'postTitle': widget.post.title,
            'storeId': widget.post.storeId,
            'storeName': widget.post.storeName,
            'likedAt': FieldValue.serverTimestamp(),
          },
        );
        batch.update(postsRef, {
          'likeCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
        });
        await batch.commit();
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      print('いいねエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('いいねの更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final commentRef = await _postDocRef().collection('comments').add({
        'userId': user.uid,
        'userName': user.displayName ?? '匿名ユーザー',
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('comments')
          .doc(commentRef.id)
          .set({
        'commentId': commentRef.id,
        'postId': widget.post.id,
        'storeId': widget.post.storeId,
        'postTitle': widget.post.title,
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      _loadComments(); // コメントを再読み込み
    } catch (e) {
      print('コメント投稿エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('コメントの投稿に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '今日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '投稿'),
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 画像スライダー
            SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildImageSlider(),
              ),
            ),

            // 店舗名・日付
            SliverToBoxAdapter(child: _buildStoreAndDate()),

            // 投稿情報
            SliverToBoxAdapter(child: _buildPostInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    if (widget.post.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.image,
            color: Colors.grey,
            size: 80,
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: widget.post.imageUrls.length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.post.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // 画像インジケーター
        if (widget.post.imageUrls.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${widget.post.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStoreAndDate() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (widget.post.storeName != null && widget.post.storeName!.isNotEmpty) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
              backgroundImage: _storeIconUrl != null && _storeIconUrl!.isNotEmpty
                  ? NetworkImage(_storeIconUrl!)
                  : null,
              child: _storeIconUrl == null || _storeIconUrl!.isEmpty
                  ? const Icon(Icons.store, size: 20, color: Color(0xFFFF6B35))
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.storeName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (widget.post.storeName == null || widget.post.storeName!.isEmpty) ...[
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              _formatDate(widget.post.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostInfo() {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // いいね・コメント・シェアボタン
          if (isLoggedIn) _buildActionButtons(),

          // いいね数
          if (_likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_likeCount件のいいね',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // 投稿内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル（店舗名と同じ場合は非表示）
                if (widget.post.title != widget.post.storeName) ...[
                  Text(
                    widget.post.title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 本文
                Text(
                  widget.post.content,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 14),
                ),

                // Instagramを開くボタン
                if (_isInstagramPost && widget.post.permalink != null && widget.post.permalink!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(widget.post.permalink!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text(
                        'Instagramを開く',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // コメントセクション
                _buildCommentsSection(isLoggedIn),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.black,
            ),
            onPressed: _toggleLike,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // コメント入力にフォーカス
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // シェア機能
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // コメント入力
        if (isLoggedIn) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'コメントを追加...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  maxLines: null,
                ),
              ),
              TextButton(
                onPressed: _addComment,
                child: const Text(
                  '投稿',
                  style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
        ],
        
        // コメント一覧
        if (_isLoadingComments)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
          )
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'コメントはまだありません',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          )
        else
          ListView.builder(
            itemCount: _comments.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFFFF6B35),
                      child: Text(
                        comment['userName'].substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${comment['userName']} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: comment['content'],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate((comment['createdAt'] as Timestamp).toDate()),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
