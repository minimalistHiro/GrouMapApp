import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/social_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/social_model.dart' as model;
import '../../widgets/custom_button.dart';

class SocialView extends ConsumerWidget {
  const SocialView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ソーシャル'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showFollowDialog(context),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }
          return _buildSocialContent(context, ref, user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSocialContent(BuildContext context, WidgetRef ref, String userId) {
    final feedPosts = ref.watch(feedPostsProvider);

    return feedPosts.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('投稿がありません'),
                SizedBox(height: 8),
                Text('最初の投稿を作成してみましょう！'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(context, ref, post);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(feedPostsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, model.Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー情報
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.userId.isNotEmpty
                      ? const NetworkImage('https://via.placeholder.com/40')
                      : null,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ユーザー ${post.userId.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('報告'),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('ブロック'),
                    ),
                  ],
                  onSelected: (value) {
                    // メニューアイテムの処理
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 投稿内容
            Text(post.content),
            const SizedBox(height: 12),
            // 画像（あれば）
            if (post.images.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(post.images.first),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // タグ
            if (post.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: post.tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.blue.shade100,
                )).toList(),
              ),
            const SizedBox(height: 12),
            // アクションボタン
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.likedBy.isNotEmpty ? Icons.favorite : Icons.favorite_border,
                    color: post.likedBy.isNotEmpty ? Colors.red : null,
                  ),
                  onPressed: () {
                    // いいね機能
                  },
                ),
                Text('${post.likeCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () => _showCommentsDialog(context, ref, post.id),
                ),
                Text('${post.commentCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // シェア機能
                  },
                ),
                Text('${post.shareCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザー検索'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'ユーザー名を入力',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('検索'),
          ),
        ],
      ),
    );
  }

  void _showFollowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザーをフォロー'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'ユーザーIDを入力',
            prefixIcon: Icon(Icons.person_add),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('フォロー'),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, WidgetRef ref) {
    final contentController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しい投稿'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: '何をシェアしますか？',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                hintText: 'タグ（カンマ区切り）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                // 投稿を作成
                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                ref.read(socialProvider).createPost(
                  userId: 'current_user_id', // 実際のユーザーID
                  content: contentController.text,
                  type: model.PostType.text,
                  tags: tags,
                );

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('投稿を作成しました')),
                );
              }
            },
            child: const Text('投稿'),
          ),
        ],
      ),
    );
  }

  void _showCommentsDialog(BuildContext context, WidgetRef ref, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメント'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<model.Comment>>(
                  stream: ref.read(socialProvider).getPostComments(postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('エラー: ${snapshot.error}'));
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('コメントがありません'),
                      );
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          title: Text(comment.content),
                          subtitle: Text(_formatDate(comment.createdAt)),
                          trailing: Text('${comment.likeCount}'),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'コメントを入力',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          ref.read(socialProvider).createComment(
                            postId: postId,
                            userId: 'current_user_id', // 実際のユーザーID
                            content: value,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
