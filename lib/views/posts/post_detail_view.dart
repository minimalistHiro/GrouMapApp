import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/posts_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _likeCount = widget.post.likeCount;
    _loadComments();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
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

  Future<void> _toggleLike() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id);

      if (_isLiked) {
        // いいねを削除
        await postRef.update({
          'likeCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        // いいねを追加
        await postRef.update({
          'likeCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
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

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': user.displayName ?? '匿名ユーザー',
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(),
            
            // 画像スライダー
            Expanded(
              flex: 3,
              child: _buildImageSlider(),
            ),
            
            // 投稿情報
            Expanded(
              flex: 2,
              child: _buildPostInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFFF6B35),
            child: Text(
              widget.post.storeName?.substring(0, 1).toUpperCase() ?? 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.storeName ?? '店舗名なし',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(widget.post.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // メニュー表示
            },
          ),
        ],
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

  Widget _buildPostInfo() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // いいね・コメント・シェアボタン
          _buildActionButtons(),
          
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 本文
                Text(
                  widget.post.content,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // コメントセクション
                _buildCommentsSection(),
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
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // ブックマーク機能
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // コメント入力
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
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _comments.length,
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
          ),
      ],
    );
  }
}
