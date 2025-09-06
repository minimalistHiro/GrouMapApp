import 'package:flutter/material.dart';

class UpdateUsernameView extends StatelessWidget {
  final String username;
  const UpdateUsernameView({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー名変更'),
      ),
      body: const Center(
        child: Text('ユーザー名変更（開発中）'),
      ),
    );
  }
}
