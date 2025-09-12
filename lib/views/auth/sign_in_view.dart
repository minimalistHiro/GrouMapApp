import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'sign_up_view.dart';
import 'welcome_view.dart';
import 'user_info_view.dart';
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
        // ホーム画面に遷移
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationView()),
          (route) => false, // すべての前の画面を削除
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE75B41),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WelcomeView()),
            );
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
                const SizedBox(height: 40),
                
                // ロゴ
                Center(
                  child: Image.asset(
                    'assets/images/groumap_icon.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.location_on, size: 120, color: Colors.blue),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // タイトル
                const Text(
                  'GrouMap',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'ログイン',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
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
                ),
                
                const SizedBox(height: 16),
                
                // パスワードリセット
                TextButton(
                  onPressed: _handlePasswordReset,
                  child: const Text('パスワードを忘れた場合'),
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
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Googleサインイン
                CustomButton(
                  text: 'Googleでログイン',
                  onPressed: signInState == SignInState.loading ? null : _handleGoogleSignIn,
                  backgroundColor: const Color(0xFFE75B41),
                  textColor: Colors.black,
                  borderColor: Colors.grey,
                  icon: Image.asset(
                    'assets/images/google_icon.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.login, size: 20),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Appleサインイン（iOSのみ）
                if (Theme.of(context).platform == TargetPlatform.iOS)
                  CustomButton(
                    text: 'Appleでログイン',
                    onPressed: signInState == SignInState.loading ? null : _handleAppleSignIn,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    icon: const Icon(Icons.apple, color: Colors.white, size: 20),
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
                          MaterialPageRoute(builder: (context) => const UserInfoView()),
                        );
                      },
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
