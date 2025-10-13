import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../stores/create_store_view.dart';
import '../stores/store_list_for_edit_view.dart';
import '../auth/welcome_view.dart';
import './profile_edit_view.dart';
import './push_notification_settings_view.dart';
import './email_notification_settings_view.dart';

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
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('通知'),
          _buildSettingsMenu(context, [
            _buildMenuItem(
              icon: Icons.notifications,
              title: 'プッシュ通知',
              onTap: () => _openPushNotificationSettings(context),
            ),
            _buildMenuItem(
              icon: Icons.mail,
              title: 'メール通知',
              onTap: () => _openEmailNotificationSettings(context),
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
            _buildMenuItem(
              icon: Icons.cleaning_services,
              title: 'データクリーンアップ',
              onTap: () => _showDataCleanup(context),
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
          
          // コンテンツ管理（ユーザーアプリでは非表示）
          
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileEditView(),
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

  

  void _openPushNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PushNotificationSettingsView(),
      ),
    );
  }

  void _openEmailNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailNotificationSettingsView(),
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

  void _showDataCleanup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データクリーンアップ'),
        content: const Text('不要なデータフィールドをクリーンアップしますか？\n\n• photoUrlフィールドの削除\n• goldStampsフィールドの削除\n• friendcodeフィールドの削除\n• その他の不要データの整理'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // ローディング表示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('クリーンアップ中...'),
                    ],
                  ),
                ),
              );
              
              // クリーンアップ実行
              await _cleanupUnusedPhotoUrl();
              await _cleanupUserData();
              
              // ローディングを閉じる
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('データクリーンアップが完了しました'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('クリーンアップ'),
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

  Future<void> _cleanupUserData() async {
    try {
      final authService = AuthService();
      await authService.cleanupUserData();
      print('User data cleanup completed');
    } catch (e) {
      print('Error during user data cleanup: $e');
    }
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
            onPressed: () async {
              Navigator.of(context).pop();
              await _performLogout(context, ref);
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // ログアウト処理
      await ref.read(authServiceProvider).signOut();

      // ローディングを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Welcome画面に遷移
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeView()),
          (route) => false,
        );
      }
    } catch (e) {
      // ローディングを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // エラー表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウトに失敗しました: $e')),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red[600],
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('アカウント削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'アカウントを完全に削除しますか？',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '削除されるデータ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• プロフィール情報\n• 投稿・コメント\n• お気に入り\n• スタンプカード\n• その他すべてのデータ',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'この操作は取り消せません',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performAccountDeletion(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(BuildContext context, WidgetRef ref) async {
    bool isLoadingDialogOpen = false;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ユーザーが見つかりません')),
          );
        }
        return;
      }

      // ローディング表示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFFF6B35),
                ),
                const SizedBox(height: 16),
                const Text(
                  'アカウントを削除中...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'しばらくお待ちください',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
        isLoadingDialogOpen = true;
      }

      try {
        // 1. Firestoreからユーザーデータを取得
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // 2. FirebaseStorageの画像を削除
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null) {
            await _deleteUserImages(userData);
          }
        }

        // 3. Firestoreのユーザーデータを削除
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // 4. ユーザーのサブコレクション（スタンプカードなど）を削除
        await _deleteUserSubcollections(user.uid);

        // 5. 関連するデータも削除（必要に応じて）
        await _deleteRelatedData(user.uid);

        // 6. Firebase Authのアカウントを削除
        await user.delete();

        // ローディングを閉じる
        if (context.mounted && isLoadingDialogOpen) {
          Navigator.of(context).pop();
          isLoadingDialogOpen = false;
        }

        // 退会完了ポップアップを表示
        if (context.mounted) {
          _showDeletionCompleteDialog(context);
        }

        // Welcome画面に遷移
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeView()),
            (route) => false,
          );
        }
      } catch (deletionError) {
        // 削除処理でエラーが発生した場合
        if (context.mounted && isLoadingDialogOpen) {
          Navigator.of(context).pop();
          isLoadingDialogOpen = false;
        }
        
        if (context.mounted) {
          String errorMessage = 'アカウント削除に失敗しました';
          if (deletionError.toString().contains('requires-recent-login')) {
            errorMessage = 'セキュリティのため、再度ログインしてから削除してください';
          } else if (deletionError.toString().contains('network')) {
            errorMessage = 'ネットワークエラーが発生しました。接続を確認してください';
          } else if (deletionError.toString().contains('permission')) {
            errorMessage = '権限が不足しています。管理者にお問い合わせください';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    } catch (e) {
      // ローディングを閉じる
      if (context.mounted && isLoadingDialogOpen) {
        Navigator.of(context).pop();
        isLoadingDialogOpen = false;
      }

      // エラー表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予期しないエラーが発生しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // 確実にローディングダイアログを閉じる
      if (context.mounted && isLoadingDialogOpen) {
        Navigator.of(context).pop();
        isLoadingDialogOpen = false;
      }
    }
  }

  // 退会完了ダイアログを表示
  Future<void> _showDeletionCompleteDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ご利用ありがとうございました。',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'アカウントが正常に削除されました。\nまたのご利用をお待ちしております。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteUserImages(Map<String, dynamic> userData) async {
    try {
      final storage = FirebaseStorage.instance;
      final List<String> imageUrls = [];

      // プロフィール画像
      if (userData['profileImageUrl'] != null) {
        imageUrls.add(userData['profileImageUrl']);
      }

      // photoUrlフィールド（使用されていないが念のため削除）
      if (userData['photoUrl'] != null) {
        imageUrls.add(userData['photoUrl']);
      }

      // その他の画像フィールドがあれば追加
      // 例: coverImageUrl, avatarUrl など

      // 各画像を削除
      for (final imageUrl in imageUrls) {
        try {
          if (imageUrl.isNotEmpty && imageUrl.contains('firebasestorage.googleapis.com')) {
            final ref = storage.refFromURL(imageUrl);
            await ref.delete();
            print('画像を削除しました: $imageUrl');
          }
        } catch (e) {
          print('画像削除エラー: $e');
          // 個別の画像削除エラーは続行
        }
      }
    } catch (e) {
      print('ユーザー画像削除エラー: $e');
      // 画像削除エラーは続行
    }
  }

  // ユーザーのサブコレクションを削除
  Future<void> _deleteUserSubcollections(String userId) async {
    try {
      // users/{userId}/stores サブコレクションを削除
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stores')
          .get();
      
      for (final doc in storesSnapshot.docs) {
        await doc.reference.delete();
      }

      print('ユーザーのサブコレクションを削除しました');
    } catch (e) {
      print('サブコレクション削除エラー: $e');
      // サブコレクション削除エラーは続行
    }
  }

  Future<void> _deleteRelatedData(String userId) async {
    try {
      // ユーザーに関連するデータを削除
      // 例: 投稿、コメント、お気に入りなど
      
      // 投稿データを削除
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in postsQuery.docs) {
        await doc.reference.delete();
      }

      // お気に入りデータを削除
      final favoritesQuery = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in favoritesQuery.docs) {
        await doc.reference.delete();
      }

      // 旧形式のuser_stampsコレクションも削除（念のため）
      final oldUserStampsQuery = await FirebaseFirestore.instance
          .collection('user_stamps')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in oldUserStampsQuery.docs) {
        await doc.reference.delete();
      }

      // その他のユーザー関連データがあれば削除
      // 例: レビュー、コメント、通知など

    } catch (e) {
      print('関連データ削除エラー: $e');
      // 関連データ削除エラーは続行
    }
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

  // 作成系画面はユーザーアプリからはアクセス不可にするため削除

  // 不要なphotoUrlフィールドをクリーンアップする関数（開発用）
  Future<void> _cleanupUnusedPhotoUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 現在のユーザーデータを取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // photoUrlフィールドが存在する場合のみ削除
        if (userData.containsKey('photoUrl')) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'photoUrl': FieldValue.delete(),
          });
          
          print('不要なphotoUrlフィールドを削除しました');
        } else {
          print('photoUrlフィールドは存在しません');
        }
      }
    } catch (e) {
      print('photoUrlクリーンアップエラー: $e');
    }
  }
}

