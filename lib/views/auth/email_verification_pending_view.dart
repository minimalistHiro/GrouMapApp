import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../home_view.dart';
import '../main_navigation_view.dart';
import 'user_info_view.dart';

class EmailVerificationPendingView extends ConsumerStatefulWidget {
  final bool goToUserInfoAfterVerify;
  final bool autoSendOnLoad;

  const EmailVerificationPendingView({
    Key? key,
    this.goToUserInfoAfterVerify = false,
    this.autoSendOnLoad = true,
  }) : super(key: key);

  @override
  ConsumerState<EmailVerificationPendingView> createState() => _EmailVerificationPendingViewState();
}

class _EmailVerificationPendingViewState extends ConsumerState<EmailVerificationPendingView> {
  bool _isResending = false;
  bool _isVerifying = false;
  bool _isDeleting = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.autoSendOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestEmailOtp();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.maybeWhen(
      data: (u) => u,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.mark_email_unread,
                size: 100,
                color: Color(0xFFFF6B35),
              ),
              const SizedBox(height: 24),
              const Text(
                'メール認証コードの入力',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${user?.email ?? "登録したメールアドレス"}に6桁の認証コードを送信しました。\nメールに記載されたコードを入力してください。',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (user?.email?.contains('@rakumail.jp') == true ||
                  user?.email?.contains('@yahoo.co.jp') == true)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ご利用のメールサービスでは、メールが届きにくい場合があります。迷惑メールフォルダもご確認ください。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ご注意',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• メールが届かない場合は、迷惑メールフォルダをご確認ください\n• 認証コードの有効期限は10分です\n• 認証が完了するまで、一部の機能がご利用いただけません',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: '認証コード（6桁）',
                  hintText: '123456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: '認証する',
                onPressed: _verifyEmailOtp,
                isLoading: _isVerifying,
                backgroundColor: const Color(0xFFFF6B35),
                textColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: '認証コードを再送信',
                onPressed: _resendEmailVerification,
                isLoading: _isResending,
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _isDeleting ? null : _deleteAccountAndGoHome,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  'トップに戻る',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyEmailOtp() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('6桁の認証コードを入力してください'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });
    try {
      await ref.read(authServiceProvider).verifyEmailOtp(code);
      if (mounted) {
        final nextView = widget.goToUserInfoAfterVerify
            ? const UserInfoView()
            : const MainNavigationView();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => nextView),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('認証に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _requestEmailOtp() async {
    setState(() {
      _isResending = true;
    });
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('認証コードを送信しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _resendEmailVerification() async {
    await _requestEmailOtp();
  }

  Future<void> _deleteAccountAndGoHome() async {
    setState(() {
      _isDeleting = true;
    });
    final authService = ref.read(authServiceProvider);
    final deleted = await _deleteAccountWithReauth(authService);
    if (!mounted) return;

    if (deleted == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationView()),
        (route) => false,
      );
      return;
    }

    if (deleted == false) {
      setState(() {
        _isDeleting = false;
      });
      return;
    }

    final password = await _promptPassword();
    if (!mounted || password == null || password.isEmpty) {
      setState(() {
        _isDeleting = false;
      });
      return;
    }

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      await _showErrorDialog('再認証に必要なメールアドレスを取得できませんでした');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
      return;
    }

    try {
      await authService.reauthenticateWithPassword(email: email, password: password);
      await authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationView()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      await _showErrorDialog('再認証に失敗しました: ${e.message ?? e.code}');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    } catch (e) {
      await _showErrorDialog('再認証に失敗しました: ${e.toString()}');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<bool?> _deleteAccountWithReauth(AuthService authService) async {
    try {
      await authService.deleteAccount();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        await _showErrorDialog('アカウント削除に失敗しました: ${e.message ?? e.code}');
        return false;
      }
      return null;
    } catch (e) {
      await _showErrorDialog('アカウント削除に失敗しました: ${e.toString()}');
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
        title: const Text('エラー'),
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
}
