import 'package:flutter/material.dart';

class TutorialView extends StatelessWidget {
  const TutorialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チュートリアル'),
      ),
      body: const Center(
        child: Text('チュートリアル（開発中）'),
      ),
    );
  }
}
