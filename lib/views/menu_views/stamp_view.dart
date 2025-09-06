import 'package:flutter/material.dart';

class StampView extends StatelessWidget {
  const StampView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スタンプ'),
      ),
      body: const Center(
        child: Text('スタンプ（開発中）'),
      ),
    );
  }
}