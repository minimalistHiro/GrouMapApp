import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../home_view.dart';
import '../main_navigation_view.dart';
import 'user_info_view.dart';

class EmailVerificationPendingView extends ConsumerStatefulWidget {
  final bool goToUserInfoAfterVerify;

  const EmailVerificationPendingView({
    Key? key,
    this.goToUserInfoAfterVerify = false,
  }) : super(key: key);

  @override
  ConsumerState<EmailVerificationPendingView> createState() => _EmailVerificationPendingViewState();
}

class _EmailVerificationPendingViewState extends ConsumerState<EmailVerificationPendingView> {
  bool _isResending = false;
  bool _isChecking = false;
  bool _isDeleting = false;

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
                'メール認証が必要です',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '認証メールを送信しました。メール内のリンクをクリックして認証を完了してください。',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isChecking ? null : _checkEmailVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '認証状況を確認',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isResending ? null : _resendEmailVerification,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                        ),
                      )
                    : const Text(
                        '認証メールを再送信',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _isDeleting ? null : _deleteAccountAndGoHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                        ),
                      )
                    : const Text(
                        'トップに戻る',
                        style: TextStyle(
                          fontSize: 16,
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

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isChecking = true;
    });
    try {
      final isVerified = await ref.read(authServiceProvider).isEmailVerified();
      if (isVerified && mounted) {
        await ref.read(authServiceProvider).updateEmailVerificationStatus(true);
        final nextView = widget.goToUserInfoAfterVerify
            ? const UserInfoView()
            : const MainNavigationView();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => nextView),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('まだメール認証が完了していません'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendEmailVerification() async {
    setState(() {
      _isResending = true;
    });
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('認証メールを再送信しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('再送信に失敗しました: $e'),
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

  Future<void> _deleteAccountAndGoHome() async {
    setState(() {
      _isDeleting = true;
    });
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeView()),
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
