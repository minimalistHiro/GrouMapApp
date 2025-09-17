import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'sign_in_view.dart';
import '../main_navigation_view.dart';

class SignUpView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? userInfo;
  
  const SignUpView({Key? key, this.userInfo}) : super(key: key);

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
        SuccessSnackBar.show(context, message: 'アカウントを作成しました');
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
                  '新規登録',
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
                
                // Googleサインアップ
                CustomButton(
                  text: 'Googleで登録',
                  onPressed: signInState == SignInState.loading ? null : _handleGoogleSignUp,
                  backgroundColor: const Color(0xFFE75B41),
                  textColor: Colors.black,
                  borderColor: Colors.grey,
                  icon: Image.asset(
                    'assets/images/groumap_icon.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.login, size: 20),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Appleサインアップ（iOSのみ）
                if (Theme.of(context).platform == TargetPlatform.iOS)
                  CustomButton(
                    text: 'Appleで登録',
                    onPressed: signInState == SignInState.loading ? null : _handleAppleSignUp,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    icon: const Icon(Icons.apple, color: Colors.white, size: 20),
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
      // ユーザー情報がある場合は、displayNameとして使用
      final displayName = widget.userInfo?['name'] ?? '';
      
      // 追加のユーザー情報を準備
      final additionalUserInfo = <String, dynamic>{
        'level': 1, // 初期レベルを1に設定
        'experience': 0, // 初期経験値を0に設定
        'createdAt': DateTime.now(), // アカウント作成日時
      };
      if (widget.userInfo != null) {
        additionalUserInfo.addAll({
          'birthDate': widget.userInfo!['birthDate'],
          'gender': widget.userInfo!['gender'],
          'prefecture': widget.userInfo!['prefecture'],
          'city': widget.userInfo!['city'],
          'profileImageUrl': widget.userInfo!['profileImageUrl'],
        });
      }
      
      ref.read(signInStateProvider.notifier).createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: displayName,
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
