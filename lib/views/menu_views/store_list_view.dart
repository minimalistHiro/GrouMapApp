import 'package:flutter/material.dart';

class StoreListView extends StatelessWidget {
  const StoreListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗一覧'),
      ),
      body: const Center(
        child: Text('店舗一覧（開発中）'),
      ),
    );
  }
}
