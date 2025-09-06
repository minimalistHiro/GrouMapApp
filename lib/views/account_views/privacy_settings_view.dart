import 'package:flutter/material.dart';

class PrivacySettingsView extends StatelessWidget {
  const PrivacySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシー設定'),
      ),
      body: const Center(
        child: Text('プライバシー設定（開発中）'),
      ),
    );
  }
}