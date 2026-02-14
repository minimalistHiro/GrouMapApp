import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'sign_in_view.dart';
import 'email_verification_pending_view.dart';
import 'user_info_view.dart';
import '../main_navigation_view.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        if (signInNotifier.lastOperation == 'アカウント作成') {
          SuccessSnackBar.show(context, message: 'アカウントを作成しました。認証コードを送信しました');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const EmailVerificationPendingView(
                goToUserInfoAfterVerify: true,
                autoSendOnLoad: false,
              ),
            ),
            (route) => false,
          );
          return;
        }

        if (signInNotifier.lastOperation == 'Googleサインイン' ||
            signInNotifier.lastOperation == 'Appleサインイン') {
          if (signInNotifier.lastIsNewUser == true) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const UserInfoView()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainNavigationView()),
              (route) => false,
            );
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '新規アカウント作成',
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
                
                const SizedBox(height: 40),

                // Appleサインアップ（iOSのみ）
                if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                  CustomButton(
                    text: 'Appleで続ける',
                    onPressed: signInState == SignInState.loading ? null : _handleAppleSignUp,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    height: 52,
                    borderRadius: 999,
                    icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Googleサインアップ
                CustomButton(
                  text: 'Googleで続ける',
                  onPressed: signInState == SignInState.loading ? null : _handleGoogleSignUp,
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
                
                const SizedBox(height: 16),
                
                // パスワード確認入力
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'パスワード確認',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワード確認を入力してください';
                    }
                    if (value != _passwordController.text) {
                      return 'パスワードが一致しません';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 登録ボタン
                CustomButton(
                  text: 'アカウント作成',
                  onPressed: signInState == SignInState.loading ? null : _handleSignUp,
                  isLoading: signInState == SignInState.loading,
                  backgroundColor: const Color(0xFFFF6B35),
                  textColor: Colors.white,
                  borderRadius: 999,
                ),
                
                const SizedBox(height: 32),
                
                // ログインリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('既にアカウントをお持ちの方は '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const SignInView()),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      child: const Text('ログイン'),
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

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      // 追加のユーザー情報を準備
      final additionalUserInfo = <String, dynamic>{
        'createdAt': DateTime.now(), // アカウント作成日時
      };
      
      ref.read(signInStateProvider.notifier).createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: '',
        additionalUserInfo: additionalUserInfo,
      );
    }
  }

  void _handleGoogleSignUp() {
    ref.read(signInStateProvider.notifier).signInWithGoogle();
  }

  void _handleAppleSignUp() {
    ref.read(signInStateProvider.notifier).signInWithApple();
  }

  void _showErrorDialog(SignInStateNotifier notifier) {
    final canRetry = notifier.lastOperation == 'Googleサインイン' ||
                    notifier.lastOperation == 'Appleサインイン' ||
                    notifier.lastOperation == '匿名サインイン';

    ErrorDialog.show(
      context,
      title: 'アカウント作成エラー',
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
