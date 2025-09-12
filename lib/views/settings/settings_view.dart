import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../notifications/create_notification_view.dart';
import '../posts/create_post_view.dart';
import '../coupons/create_coupon_view.dart';
import '../stores/create_store_view.dart';
import '../stores/store_list_for_edit_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }
          return _buildSettingsContent(context, ref, user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref, user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle('アカウント'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.person,
              title: 'プロフィール編集',
              onTap: () => _showProfileEdit(context),
            ),
            _buildMenuItem(
              icon: Icons.lock,
              title: 'パスワード変更',
              onTap: () => _showPasswordChange(context),
            ),
            _buildMenuItem(
              icon: Icons.email,
              title: 'メールアドレス変更',
              onTap: () => _showEmailChange(context),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('通知'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.notifications,
              title: 'プッシュ通知',
              onTap: () => _showNotificationSettings(context),
            ),
            _buildMenuItem(
              icon: Icons.mail,
              title: 'メール通知',
              onTap: () => _showEmailNotificationSettings(context),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('プライバシー'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.privacy_tip,
              title: 'プライバシー設定',
              onTap: () => _showPrivacySettings(context),
            ),
            _buildMenuItem(
              icon: Icons.storage,
              title: 'データ管理',
              onTap: () => _showDataManagement(context),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('アプリ'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.language,
              title: '言語設定',
              onTap: () => _showLanguageSettings(context),
            ),
            _buildMenuItem(
              icon: Icons.palette,
              title: 'テーマ設定',
              onTap: () => _showThemeSettings(context),
            ),
            _buildMenuItem(
              icon: Icons.clear_all,
              title: 'キャッシュクリア',
              onTap: () => _showCacheClear(context),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('店舗管理'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.store,
              title: '新規店舗作成',
              onTap: () => _showCreateStore(context),
            ),
            _buildMenuItem(
              icon: Icons.edit_location,
              title: '店舗情報変更',
              onTap: () => _showStoreManagement(context),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('コンテンツ管理'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.announcement,
              title: '新規お知らせ作成',
              onTap: () => _showCreateNotification(context),
            ),
            _buildMenuItem(
              icon: Icons.post_add,
              title: '新規投稿作成',
              onTap: () => _showCreatePost(context),
            ),
            _buildMenuItem(
              icon: Icons.local_offer,
              title: '新規クーポン作成',
              onTap: () => _showCreateCoupon(context),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('サポート'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.help,
              title: 'ヘルプ',
              onTap: () => _showHelp(context),
            ),
            _buildMenuItem(
              icon: Icons.contact_support,
              title: 'お問い合わせ',
              onTap: () => _showContact(context),
            ),
            _buildMenuItem(
              icon: Icons.description,
              title: '利用規約',
              onTap: () => _showTerms(context),
            ),
            _buildMenuItem(
              icon: Icons.policy,
              title: 'プライバシーポリシー',
              onTap: () => _showPrivacyPolicy(context),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('アカウント'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.logout,
              title: 'ログアウト',
              onTap: () => _showLogoutDialog(context, ref),
              isDestructive: true,
            ),
            _buildMenuItem(
              icon: Icons.delete_forever,
              title: 'アカウント削除',
              onTap: () => _showDeleteAccountDialog(context, ref),
              isDestructive: true,
            ),
          ]),
          
          const SizedBox(height: 32),
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildAppInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.apps,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              'GrouMap',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'バージョン 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2024 GrouMap. All rights reserved.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileEdit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィール編集'),
        content: const Text('プロフィール編集機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showPasswordChange(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワード変更'),
        content: const Text('パスワード変更機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showEmailChange(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メールアドレス変更'),
        content: const Text('メールアドレス変更機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プッシュ通知設定'),
        content: const Text('プッシュ通知設定機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showEmailNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メール通知設定'),
        content: const Text('メール通知設定機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プライバシー設定'),
        content: const Text('プライバシー設定機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showDataManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データ管理'),
        content: const Text('データ管理機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('言語設定'),
        content: const Text('言語設定機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ設定'),
        content: const Text('テーマ設定機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showCacheClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キャッシュクリア'),
        content: const Text('キャッシュをクリアしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('キャッシュをクリアしました')),
              );
            },
            child: const Text('クリア'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヘルプ'),
        content: const Text('ヘルプ機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お問い合わせ'),
        content: const Text('お問い合わせ機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('利用規約'),
        content: const Text('利用規約は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プライバシーポリシー'),
        content: const Text('プライバシーポリシーは今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ログアウト処理
              ref.read(authServiceProvider).signOut();
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text('アカウントを完全に削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('アカウント削除機能は今後実装予定です')),
              );
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showCreateStore(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateStoreView(),
      ),
    );
  }

  void _showStoreManagement(BuildContext context) {
    // 店舗一覧を表示して編集する店舗を選択する画面に遷移
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoreListForEditView(),
      ),
    );
  }

  void _showCreateNotification(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateNotificationView(),
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreatePostView(),
      ),
    );
  }

  void _showCreateCoupon(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateCouponView(),
      ),
    );
  }
}

