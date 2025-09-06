import 'package:flutter/material.dart';

class CreatePostView extends StatelessWidget {
  const CreatePostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規投稿作成'),
      ),
      body: const Center(
        child: Text('新規投稿作成（開発中）'),
      ),
    );
  }
}
