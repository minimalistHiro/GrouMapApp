import 'package:flutter/material.dart';

class RankDetailView extends StatelessWidget {
  const RankDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランク詳細'),
      ),
      body: const Center(
        child: Text('ランク詳細（開発中）'),
      ),
    );
  }
}
