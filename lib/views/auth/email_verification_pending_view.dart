import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
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
              const SizedBox(height: 12),
              const Text(
                '6桁の認証コードをメールで送信しました。メールに記載されたコードを入力してください。',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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
              CustomButton(
                text: 'トップに戻る',
                onPressed: _deleteAccountAndGoHome,
                isLoading: _isDeleting,
                backgroundColor: Colors.white,
                textColor: Colors.redAccent,
                borderColor: Colors.redAccent,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アカウント削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
