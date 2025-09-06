import 'package:flutter/material.dart';

class CreateNotificationView extends StatelessWidget {
  const CreateNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規お知らせ作成'),
      ),
      body: const Center(
        child: Text('新規お知らせ作成（開発中）'),
      ),
    );
  }
}
