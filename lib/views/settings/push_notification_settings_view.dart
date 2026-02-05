import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_switch_tile.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/common_header.dart';

class PushNotificationSettingsView extends ConsumerStatefulWidget {
  const PushNotificationSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<PushNotificationSettingsView> createState() => _PushNotificationSettingsViewState();
}

class _PushNotificationSettingsViewState extends ConsumerState<PushNotificationSettingsView> {
  bool _couponIssued = true;
  bool _post = true;
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
      final settings = data?['notificationSettings'] as Map<String, dynamic>?;
      setState(() {
        _couponIssued = settings?['couponIssued'] as bool? ?? true;
        _post = settings?['post'] as bool? ?? true;
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleCouponIssued(bool value) async {
    setState(() => _couponIssued = value);
    await _saveSettings();
  }

  Future<void> _togglePost(bool value) async {
    setState(() => _post = value);
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: 'プッシュ通知'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCard([
                  CustomSwitchListTile(
                    title: const Text('クーポン発行'),
                    value: _couponIssued,
                    onChanged: _isSaving ? null : _toggleCouponIssued,
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('投稿'),
                    value: _post,
                    onChanged: _isSaving ? null : _togglePost,
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
