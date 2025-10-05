import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PushNotificationSettingsView extends ConsumerStatefulWidget {
  const PushNotificationSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<PushNotificationSettingsView> createState() => _PushNotificationSettingsViewState();
}

class _PushNotificationSettingsViewState extends ConsumerState<PushNotificationSettingsView> {
  bool _enabled = true;
  bool _sound = true;
  bool _badge = true;
  bool _showPreviews = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プッシュ通知設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard([
            SwitchListTile(
              title: const Text('プッシュ通知を有効にする'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ]),
          const SizedBox(height: 16),
          _buildCard([
            SwitchListTile(
              title: const Text('サウンド'),
              value: _sound,
              onChanged: _enabled ? (v) => setState(() => _sound = v) : null,
            ),
            const Divider(height: 0),
            SwitchListTile(
              title: const Text('バッジ'),
              value: _badge,
              onChanged: _enabled ? (v) => setState(() => _badge = v) : null,
            ),
            const Divider(height: 0),
            SwitchListTile(
              title: const Text('プレビューを表示'),
              value: _showPreviews,
              onChanged: _enabled ? (v) => setState(() => _showPreviews = v) : null,
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('通知設定を保存しました')),
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


