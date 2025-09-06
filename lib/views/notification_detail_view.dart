import 'package:flutter/material.dart';

class NotificationDetailView extends StatelessWidget {
  final String notificationId;
  const NotificationDetailView({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知詳細'),
      ),
      body: const Center(
        child: Text('通知詳細（開発中）'),
      ),
    );
  }
}
