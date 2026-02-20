import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_switch_tile.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/common_header.dart';

class NotificationSettingsView extends ConsumerStatefulWidget {
  const NotificationSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends ConsumerState<NotificationSettingsView> {
  // プッシュ通知設定
  bool _couponIssued = true;
  bool _post = true;

  // メール通知設定
  bool _announcements = true;
  bool _newsletters = true;
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

      final pushSettings = data?['notificationSettings'] as Map<String, dynamic>?;
      final emailSettings = data?['emailNotificationSettings'] as Map<String, dynamic>?;

      setState(() {
        _couponIssued = pushSettings?['couponIssued'] as bool? ?? true;
        _post = pushSettings?['post'] as bool? ?? true;
        _announcements = emailSettings?['announcements'] as bool? ?? true;
        _newsletters = emailSettings?['newsletters'] as bool? ?? true;
        _promotions = emailSettings?['promotions'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ErrorDialog.show(
        context,
        title: '読み込みに失敗しました',
        message: '通知設定の取得に失敗しました。時間をおいて再度お試しください。',
        details: e.toString(),
      );
    }
  }

  Future<void> _savePushSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ErrorDialog.show(
        context,
        title: '保存できません',
        message: 'ログイン情報を確認できませんでした。再ログイン後にお試しください。',
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'notificationSettings': {
          'couponIssued': _couponIssued,
          'post': _post,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        title: '保存に失敗しました',
        message: '通知設定の保存に失敗しました。時間をおいて再度お試しください。',
        details: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveEmailSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ErrorDialog.show(
        context,
        title: '保存できません',
        message: 'ログイン情報を確認できませんでした。再ログイン後にお試しください。',
      );
      return;
    }
    if (_isSaving) return;
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '通知設定'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionLabel('プッシュ通知'),
                const SizedBox(height: 8),
                _buildCard([
                  CustomSwitchListTile(
                    title: const Text('クーポン発行'),
                    subtitle: const Text('フォロー中の店舗がクーポンを発行した時'),
                    value: _couponIssued,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _couponIssued = value);
                            _savePushSettings();
                          },
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('投稿'),
                    subtitle: const Text('フォロー中の店舗が投稿した時'),
                    value: _post,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _post = value);
                            _savePushSettings();
                          },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionLabel('メール通知'),
                const SizedBox(height: 8),
                _buildCard([
                  CustomSwitchListTile(
                    title: const Text('お知らせメール'),
                    subtitle: const Text('重要なお知らせやアップデート情報'),
                    value: _announcements,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _announcements = value);
                            _saveEmailSettings();
                          },
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('ニュースレター'),
                    subtitle: const Text('新機能やおすすめ情報'),
                    value: _newsletters,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _newsletters = value);
                            _saveEmailSettings();
                          },
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('キャンペーン・プロモーション'),
                    value: _promotions,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _promotions = value);
                            _saveEmailSettings();
                          },
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
      backgroundColor: Colors.grey[50],
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
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
