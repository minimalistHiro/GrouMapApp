import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../main_navigation_view.dart';

class AccountDeletionProcessingView extends ConsumerStatefulWidget {
  const AccountDeletionProcessingView({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountDeletionProcessingView> createState() => _AccountDeletionProcessingViewState();
}

class _AccountDeletionProcessingViewState extends ConsumerState<AccountDeletionProcessingView> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _startDeletion();
  }

  Future<void> _startDeletion() async {
    try {
      final authService = ref.read(authServiceProvider);
      final deleted = await _deleteAccountWithReauth(authService);
      if (!mounted) return;

      if (deleted == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AccountDeletionCompleteView()),
          (route) => false,
        );
        return;
      }

      if (deleted == false) {
        Navigator.of(context).pop();
        return;
      }

      final password = await _promptPassword();
      if (!mounted || password == null || password.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        await _showErrorDialog('再認証に必要なメールアドレスを取得できませんでした');
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      await authService.reauthenticateWithPassword(email: email, password: password);
      await authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AccountDeletionCompleteView()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('退会に失敗しました'),
          content: Text('退会処理に失敗しました: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _deleteAccountWithReauth(AuthService authService) async {
    try {
      await authService.deleteAccount();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        await _showErrorDialog('退会処理に失敗しました: ${e.message ?? e.code}');
        return false;
      }
      return null;
    } catch (e) {
      await _showErrorDialog('退会処理に失敗しました: ${e.toString()}');
      return false;
    }
  }

  Future<String?> _promptPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('再認証が必要です'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'パスワード',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('再認証'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退会に失敗しました'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonHeader(
        title: '退会処理中',
        showBack: false,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
            SizedBox(height: 16),
            Text(
              '退会処理を実行しています…',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountDeletionCompleteView extends StatelessWidget {
  const AccountDeletionCompleteView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonHeader(
        title: '退会完了',
        showBack: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Color(0xFFFF6B35),
              ),
              const SizedBox(height: 16),
              const Text(
                '退会が完了しました。ご利用ありがとうございました。',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'ログインへ',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signin');
                },
                backgroundColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'ホームへ戻る',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationView(
                        key: ValueKey('guest'),
                      ),
                    ),
                    (route) => false,
                  );
                },
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
