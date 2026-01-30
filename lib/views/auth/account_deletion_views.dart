import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
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
      await ref.read(authServiceProvider).deleteAccount();
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
