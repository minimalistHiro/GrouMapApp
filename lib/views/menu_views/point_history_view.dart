import 'package:flutter/material.dart';

class PointHistoryView extends StatelessWidget {
  const PointHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント履歴'),
      ),
      body: const Center(
        child: Text('ポイント履歴（開発中）'),
      ),
    );
  }
}