import 'package:flutter/material.dart';

class MyStoreListView extends StatelessWidget {
  const MyStoreListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗情報変更'),
      ),
      body: const Center(
        child: Text('店舗情報変更（開発中）'),
      ),
    );
  }
}
