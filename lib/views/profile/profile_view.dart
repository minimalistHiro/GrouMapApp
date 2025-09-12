import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/level_provider.dart';
import '../../widgets/custom_button.dart';
import 'badges_view.dart';
import 'level_view.dart';
import '../settings/settings_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('プロフィール'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ユーザー情報が取得できません'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // ユーザー情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName ?? 'ユーザー',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // レベルとバッジ情報
                        _buildStatsRow(user.uid, ref),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // メニュー項目
                _buildSettingsMenu(context),
                
                const SizedBox(height: 24),
                
                // ログアウトボタン
                CustomButton(
                  text: 'ログアウト',
                  onPressed: () async {
                    await ref.read(signInStateProvider.notifier).signOut();
                    // ログアウト後は自動的にホーム画面に戻る
                  },
                  backgroundColor: Colors.red,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildStatsRow(String userId, WidgetRef ref) {
    final userLevelAsync = ref.watch(userLevelProvider(userId));
    final newBadgeCountAsync = ref.watch(FutureProvider.family<int, String>((ref, userId) async {
      final badgeService = ref.read(badgeProvider);
      return await badgeService.getNewBadgeCount(userId);
    })(userId));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // レベル情報
        userLevelAsync.when(
          data: (userLevel) => _buildStatItem(
            icon: Icons.trending_up,
            label: 'レベル',
            value: userLevel?.currentLevel.toString() ?? '1',
            color: Colors.blue,
          ),
          loading: () => _buildStatItem(
            icon: Icons.trending_up,
            label: 'レベル',
            value: '...',
            color: Colors.blue,
          ),
          error: (_, __) => _buildStatItem(
            icon: Icons.trending_up,
            label: 'レベル',
            value: '1',
            color: Colors.blue,
          ),
        ),
        
        // バッジ情報
        newBadgeCountAsync.when(
          data: (newBadgeCount) => _buildStatItem(
            icon: Icons.emoji_events,
            label: 'バッジ',
            value: newBadgeCount > 0 ? '$newBadgeCount 新' : 'バッジ',
            color: newBadgeCount > 0 ? Colors.orange : Colors.purple,
          ),
          loading: () => _buildStatItem(
            icon: Icons.emoji_events,
            label: 'バッジ',
            value: '...',
            color: Colors.purple,
          ),
          error: (_, __) => _buildStatItem(
            icon: Icons.emoji_events,
            label: 'バッジ',
            value: 'バッジ',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsMenu(BuildContext context) {
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
        children: [
          _buildMenuItem(
            icon: Icons.emoji_events,
            title: 'バッジ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BadgesView()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.trending_up,
            title: 'レベル',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LevelView()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.person,
            title: 'プロフィール編集',
            onTap: () {
              // TODO: プロフィール編集画面へ遷移
            },
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: '設定',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'ヘルプ',
            onTap: () {
              // TODO: ヘルプ画面へ遷移
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
