import 'package:flutter/material.dart';

class FriendIntroView extends StatelessWidget {
  const FriendIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('友達紹介'),
      ),
      body: const Center(
        child: Text('友達紹介（開発中）'),
      ),
    );
  }
}