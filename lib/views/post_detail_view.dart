import 'package:flutter/material.dart';

class PostDetailView extends StatelessWidget {
  final String postId;
  const PostDetailView({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿詳細'),
      ),
      body: const Center(
        child: Text('投稿詳細（開発中）'),
      ),
    );
  }
}
