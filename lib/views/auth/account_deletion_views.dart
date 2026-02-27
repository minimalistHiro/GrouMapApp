import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dismiss_keyboard.dart';
import 'welcome_view.dart';

class AccountDeletionReasonView extends ConsumerStatefulWidget {
  const AccountDeletionReasonView({super.key});

  @override
  ConsumerState<AccountDeletionReasonView> createState() =>
      _AccountDeletionReasonViewState();
}

class _AccountDeletionReasonViewState
    extends ConsumerState<AccountDeletionReasonView> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _validationMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReasonAndProceed() async {
    final validationMessage = _validateReason(_reasonController.text);
    if (validationMessage != null) {
      setState(() => _validationMessage = validationMessage);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.submitUserAccountDeletionReason(
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AccountDeletionProcessingView(),
        ),
      );
    } catch (e) {
      await _showErrorDialog('退会理由の送信に失敗しました。\n時間をおいて再度お試しください。\n\n$e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateReason(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '退会理由を入力してください';
    }
    if (trimmed.length < 10) {
      return '退会理由は10文字以上で入力してください';
    }
    return null;
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('送信に失敗しました'),
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
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(
        title: '退会理由の入力',
      ),
      body: DismissKeyboard(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '退会するとアカウントデータは元に戻せません。退会理由を入力後、退会処理を開始します。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '退会理由',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 6,
                minLines: 6,
                onChanged: (_) {
                  if (_validationMessage != null) {
                    setState(() => _validationMessage = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: '退会理由を入力してください（10文字以上）',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide:
                        BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 10),
              if (_validationMessage != null)
                Text(
                  _validationMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 18),
              CustomButton(
                text: _isSubmitting ? '送信中...' : '理由を送信して退会する',
                onPressed: _isSubmitting ? null : _submitReasonAndProceed,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                isLoading: _isSubmitting,
                borderRadius: 999,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'キャンセル',
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountDeletionProcessingView extends ConsumerStatefulWidget {
  const AccountDeletionProcessingView({super.key});

  @override
  ConsumerState<AccountDeletionProcessingView> createState() =>
      _AccountDeletionProcessingViewState();
}

class _AccountDeletionProcessingViewState
    extends ConsumerState<AccountDeletionProcessingView> {
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
          MaterialPageRoute(
              builder: (context) => const AccountDeletionCompleteView()),
          (route) => false,
        );
        return;
      }

      if (deleted == false) {
        Navigator.of(context).pop();
        return;
      }

      final password = await _promptPassword();
      if (!mounted) return;
      if (password == null || password.isEmpty) {
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

      await authService.reauthenticateWithPassword(
          email: email, password: password);
      await authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const AccountDeletionCompleteView()),
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _logoutAndGoHome();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('ログアウトする'),
            ),
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
            onPressed: () async {
              Navigator.of(context).pop();
              await _logoutAndGoHome();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('ログアウトする'),
          ),
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
    return const Scaffold(
      backgroundColor: Color(0xFFFBF6F2),
      appBar: CommonHeader(
        title: '退会処理中',
        showBack: false,
      ),
      body: Center(
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

  Future<void> _logoutAndGoHome() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // 失敗しても遷移は行う
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WelcomeView(),
      ),
      (route) => false,
    );
  }
}

class AccountDeletionCompleteView extends StatelessWidget {
  const AccountDeletionCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
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
                      builder: (context) => const WelcomeView(),
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
