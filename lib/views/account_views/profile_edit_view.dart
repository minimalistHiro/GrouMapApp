import 'package:flutter/material.dart';

class ProfileEditView extends StatelessWidget {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
      ),
      body: const Center(
        child: Text('プロフィール編集（開発中）'),
      ),
    );
  }
}
