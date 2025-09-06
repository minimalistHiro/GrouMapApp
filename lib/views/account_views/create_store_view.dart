import 'package:flutter/material.dart';

class CreateStoreView extends StatelessWidget {
  const CreateStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規店舗作成'),
      ),
      body: const Center(
        child: Text('新規店舗作成（開発中）'),
      ),
    );
  }
}
