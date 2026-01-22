import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'terms_privacy_consent_view.dart';
import 'email_verification_pending_view.dart';
import '../main_navigation_view.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(signInStateProvider);
    final signInNotifier = ref.read(signInStateProvider.notifier);

    // エラー状態の監視
    ref.listen<SignInState>(signInStateProvider, (previous, next) {
      if (next == SignInState.error) {
        _showErrorDialog(signInNotifier);
      } else if (next == SignInState.success) {
        SuccessSnackBar.show(context, message: 'ログインしました');
        _navigateAfterSignIn();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ログイン',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Appleサインイン（iOSのみ）
                if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                  CustomButton(
                    text: 'Appleでサインイン',
                    onPressed: signInState == SignInState.loading ? null : _handleAppleSignIn,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    height: 52,
                    borderRadius: 999,
                    icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 16),
                ],

                // Googleサインイン
                CustomButton(
                  text: 'Googleでサインイン',
                  onPressed: signInState == SignInState.loading ? null : _handleGoogleSignIn,
                  height: 52,
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  borderColor: const Color(0xFFBDBDBD),
                  borderRadius: 999,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    width: 24,
                    height: 24,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 32),

                // 区切り線
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'または',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 32),

                // メールアドレス入力
                CustomTextField(
                  controller: _emailController,
                  labelText: 'メールアドレス',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // パスワード入力
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'パスワード',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 6) {
                      return 'パスワードは6文字以上で入力してください';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ログインボタン
                CustomButton(
                  text: 'ログイン',
                  onPressed: signInState == SignInState.loading ? null : _handleSignIn,
                  isLoading: signInState == SignInState.loading,
                  backgroundColor: const Color(0xFFFF6B35),
                  textColor: Colors.white,
                  borderRadius: 999,
                ),

                const SizedBox(height: 16),

                // パスワードリセット
                TextButton(
                  onPressed: _handlePasswordReset,
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  child: const Text('パスワードを忘れた場合'),
                ),

                const SizedBox(height: 32),
                
                // サインアップリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('アカウントをお持ちでない方は '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const TermsPrivacyConsentView(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      child: const Text('新規登録'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      ref.read(signInStateProvider.notifier).signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  Future<void> _navigateAfterSignIn() async {
    try {
      final isVerified = await ref.read(authServiceProvider).isEmailVerified();
      if (!mounted) return;
      if (isVerified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationView()),
          (route) => false,
        );
      } else {
        await ref.read(authServiceProvider).sendEmailVerification();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EmailVerificationPendingView()),
          (route) => false,
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const EmailVerificationPendingView()),
        (route) => false,
      );
    }
  }

  void _handleGoogleSignIn() {
    ref.read(signInStateProvider.notifier).signInWithGoogle();
  }

  void _handleAppleSignIn() {
    ref.read(signInStateProvider.notifier).signInWithApple();
  }

  void _handlePasswordReset() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスを入力してください')),
      );
      return;
    }

    ref.read(signInStateProvider.notifier).sendPasswordResetEmail(
      _emailController.text.trim(),
    );
  }

  void _showErrorDialog(SignInStateNotifier notifier) {
    final canRetry = notifier.lastOperation == 'Googleサインイン' ||
                    notifier.lastOperation == 'Appleサインイン' ||
                    notifier.lastOperation == '匿名サインイン' ||
                    notifier.lastOperation == 'サインアウト';

    ErrorDialog.show(
      context,
      title: 'ログインエラー',
      message: notifier.errorMessage ?? 'エラーが発生しました',
      details: notifier.errorDetails,
      onRetry: canRetry ? () {
        Navigator.of(context).pop(); // ダイアログを閉じる
        notifier.retryLastOperation();
      } : null,
      onDismiss: () {
        Navigator.of(context).pop(); // ダイアログを閉じる
      },
    );
  }
}
