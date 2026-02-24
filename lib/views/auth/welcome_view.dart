import 'package:flutter/material.dart';
import '../main_navigation_view.dart';
import 'sign_in_view.dart';
import 'terms_privacy_consent_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // シンプルで安全なアニメーション
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic, // 安全なカーブ
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _logoController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ロゴとサービス名
              _buildLogoSection(),

              const Spacer(flex: 1),

              // 説明文
              _buildDescriptionSection(),

              const Spacer(flex: 1),

              // ボタンセクション
              _buildButtonSection(),

              const Spacer(flex: 1),

              // フッター
              _buildFooter(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // ロゴ画像
        AnimatedBuilder(
          animation: _logoAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _logoAnimation.value,
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // サービス名
        AnimatedBuilder(
          animation: _logoAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _logoAnimation.value)),
              child: Opacity(
                opacity: _logoAnimation.value,
                child: const Text(
                  'ぐるまっぷ',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // サブタイトル
        AnimatedBuilder(
          animation: _logoAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _logoAnimation.value)),
              child: Opacity(
                opacity: _logoAnimation.value,
                child: const Text(
                  '"知らなかった小さな名店"に出会う地図',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return const SizedBox.shrink();
  }

  Widget _buildButtonSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // 新規アカウント登録ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TermsPrivacyConsentView(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    '新規アカウント登録',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ログインボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignInView(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                    side: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'ログイン',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ログインせずに開始ボタン
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationView(
                          key: ValueKey('guest'),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'ログインせずに開始',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '一部機能はログインが必要です',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: const Text(
            'アプリを続行することで、利用規約とプライバシーポリシーに同意したことになります',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black45,
              height: 1.4,
            ),
          ),
        );
      },
    );
  }
}
