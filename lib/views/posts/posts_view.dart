import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/posts_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_top_tab_bar.dart';
import '../posts/post_detail_view.dart';

class PostsView extends ConsumerWidget {
  const PostsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF6F2),
        appBar: const CommonHeader(
          title: '投稿',
          showBack: false,
        ),
        body: Column(
          children: [
            const CustomTopTabBar(
              tabs: [
                Tab(text: 'フィード'),
                Tab(text: '検索'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFeedTab(),
                  _buildSearchTab(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    return const SizedBox.expand();
  }

  Widget _buildSearchTab(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(allPostsProvider);

    return posts.when(
      data: (posts) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: posts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('投稿がありません'),
                          SizedBox(height: 8),
                          Text('新しい投稿をお待ちください！'),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                        childAspectRatio: 1,
                      ),
                      itemCount: posts.length > 60 ? 60 : posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _buildPostCard(context, ref, post);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
            SizedBox(height: 8),
            Text(
              '投稿を読み込み中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              '投稿の取得に失敗しました',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'データが存在しない可能性があります',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: '再試行',
                onPressed: () {
                  ref.invalidate(allPostsProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: '投稿を検索',
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.grey,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, PostModel post) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailView(post: post),
          ),
        );
      },
      child: Container(
        color: Colors.grey[200],
        child: post.imageUrls.isNotEmpty
            ? Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      post.imageUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (post.imageUrls.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.grid_on,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${post.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),
      ),
    );
  }
}
