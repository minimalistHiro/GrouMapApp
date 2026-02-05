import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_switch_tile.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/common_header.dart';

class EmailNotificationSettingsView extends ConsumerStatefulWidget {
  const EmailNotificationSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailNotificationSettingsView> createState() => _EmailNotificationSettingsViewState();
}

class _EmailNotificationSettingsViewState extends ConsumerState<EmailNotificationSettingsView> {
  bool _newsletters = true;
  bool _announcements = true;
  bool _promotions = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      final settings = data?['emailNotificationSettings'] as Map<String, dynamic>?;
      setState(() {
        _announcements = settings?['announcements'] as bool? ?? true;
        _newsletters = settings?['newsletters'] as bool? ?? true;
        _promotions = settings?['promotions'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ErrorDialog.show(
        context,
        title: '読み込みに失敗しました',
        message: 'メール通知設定の取得に失敗しました。時間をおいて再度お試しください。',
        details: e.toString(),
      );
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ErrorDialog.show(
        context,
        title: '保存できません',
        message: 'ログイン情報を確認できませんでした。再ログイン後にお試しください。',
      );
      return;
    }
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'emailNotificationSettings': {
          'announcements': _announcements,
          'newsletters': _newsletters,
          'promotions': _promotions,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        title: '保存に失敗しました',
        message: 'メール通知設定の保存に失敗しました。時間をおいて再度お試しください。',
        details: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleAnnouncements(bool value) async {
    setState(() => _announcements = value);
    await _saveSettings();
  }

  Future<void> _toggleNewsletters(bool value) async {
    setState(() => _newsletters = value);
    await _saveSettings();
  }

  Future<void> _togglePromotions(bool value) async {
    setState(() => _promotions = value);
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: 'メール通知'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCard([
                  CustomSwitchListTile(
                    title: const Text('お知らせメール'),
                    subtitle: const Text('重要なお知らせやアップデート情報'),
                    value: _announcements,
                    onChanged: _isSaving ? null : _toggleAnnouncements,
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('ニュースレター'),
                    subtitle: const Text('新機能やおすすめ情報'),
                    value: _newsletters,
                    onChanged: _isSaving ? null : _toggleNewsletters,
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('キャンペーン・プロモーション'),
                    value: _promotions,
                    onChanged: _isSaving ? null : _togglePromotions,
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
      backgroundColor: Colors.grey[50],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(children: children),
    );
  }
}
