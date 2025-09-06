import 'package:flutter/material.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('言語設定'),
      ),
      body: const Center(
        child: Text('言語設定（開発中）'),
      ),
    );
  }
}
