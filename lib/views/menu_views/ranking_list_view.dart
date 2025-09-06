import 'package:flutter/material.dart';

class RankingListView extends StatelessWidget {
  const RankingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
      ),
      body: const Center(
        child: Text('ランキング（開発中）'),
      ),
    );
  }
}