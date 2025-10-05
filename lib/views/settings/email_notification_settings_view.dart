import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailNotificationSettingsView extends ConsumerStatefulWidget {
  const EmailNotificationSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailNotificationSettingsView> createState() => _EmailNotificationSettingsViewState();
}

class _EmailNotificationSettingsViewState extends ConsumerState<EmailNotificationSettingsView> {
  bool _newsletters = true;
  bool _announcements = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メール通知設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard([
            SwitchListTile(
              title: const Text('お知らせメール'),
              subtitle: const Text('重要なお知らせやアップデート情報'),
              value: _announcements,
              onChanged: (v) => setState(() => _announcements = v),
            ),
            const Divider(height: 0),
            SwitchListTile(
              title: const Text('ニュースレター'),
              subtitle: const Text('新機能やおすすめ情報'),
              value: _newsletters,
              onChanged: (v) => setState(() => _newsletters = v),
            ),
            const Divider(height: 0),
            SwitchListTile(
              title: const Text('キャンペーン・プロモーション'),
              value: _promotions,
              onChanged: (v) => setState(() => _promotions = v),
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メール通知設定を保存しました')),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F7F7),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}


