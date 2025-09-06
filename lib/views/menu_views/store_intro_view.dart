import 'package:flutter/material.dart';

class StoreIntroView extends StatelessWidget {
  const StoreIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗紹介'),
      ),
      body: const Center(
        child: Text('店舗紹介（開発中）'),
      ),
    );
  }
}