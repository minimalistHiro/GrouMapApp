import 'package:flutter/material.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: const Center(
        child: Text('通知設定（開発中）'),
      ),
    );
  }
}
