import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../settings/profile_edit_view.dart';
import '../settings/password_change_view.dart';
import '../settings/notification_settings_view.dart';
import '../legal/privacy_policy_view.dart';
import '../legal/terms_view.dart';
import '../support/help_view.dart';
import '../feedback/feedback_view.dart';
import '../main_navigation_view.dart';
import '../auth/account_deletion_views.dart';
import '../../widgets/user_stats_card.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authState = ref.read(authStateProvider);
      await authState.when(
        data: (user) async {
          if (user != null) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            if (doc.exists) {
              final userData = doc.data();
              setState(() {
                _userData = userData;
                _isLoadingUserData = false;
              });
              
            } else {
              setState(() {
                _isLoadingUserData = false;
              });
            }
          } else {
            setState(() {
              _isLoadingUserData = false;
            });
          }
        },
        loading: () {},
        error: (_, __) {
          setState(() {
            _isLoadingUserData = false;
          });
        },
      );
    } catch (e) {
      print('ユーザーデータの読み込みエラー: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<String?> _loadImageAsBase64(String imageUrl) async {
    try {
      print('画像をBase64で読み込み開始: $imageUrl');
      
      // CORS制限を回避するためのプロキシ経由での読み込み
      final proxyUrl = 'https://cors-anywhere.herokuapp.com/$imageUrl';
      
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Origin': 'https://your-app-domain.com', // 実際のドメインに変更
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final base64String = base64Encode(bytes);
        print('画像をBase64で読み込み成功');
        return base64String;
      } else {
        print('プロキシ経由の画像読み込みが失敗: ${response.statusCode}');
        
        // プロキシが失敗した場合は直接読み込みを試行
        return await _loadImageDirectly(imageUrl);
      }
    } catch (e) {
      print('プロキシ経由の画像読み込みエラー: $e');
      
      // プロキシが失敗した場合は直接読み込みを試行
      return await _loadImageDirectly(imageUrl);
    }
  }

  Future<String?> _loadImageDirectly(String imageUrl) async {
    try {
      print('直接画像読み込みを試行: $imageUrl');
      
      // Firebase Storageの場合は特別なヘッダーを設定
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      };
      
      // Firebase Storageの場合はCORSヘッダーを追加
      if (imageUrl.contains('firebasestorage.googleapis.com')) {
        headers['Origin'] = 'https://your-app-domain.com';
        headers['Referer'] = 'https://your-app-domain.com';
      }
      
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final base64String = base64Encode(bytes);
        print('直接画像読み込み成功');
        return base64String;
      } else {
        print('直接画像読み込みが失敗: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('直接画像読み込みエラー: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        top: true,
        bottom: false,
        child: authState.when(
          data: (user) {
            if (user == null) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'ゲスト',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/signin');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B35),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('ログイン'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/signup');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFFF6B35),
                                        side: const BorderSide(color: Color(0xFFFF6B35)),
                                      ),
                                      child: const Text('新規アカウント作成'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final canChangePassword = user.providerData.any(
            (provider) => provider.providerId == 'password',
          );

          if (_isLoadingUserData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // ユーザー情報（カードなし）
                Column(
                  children: [
                    _buildUserAvatar(user, _userData),
                    const SizedBox(height: 16),
                    Text(
                      (_userData?['displayName'] is String &&
                              (_userData?['displayName'] as String).trim().isNotEmpty)
                          ? (_userData?['displayName'] as String).trim()
                          : (user.displayName?.trim().isNotEmpty == true
                              ? user.displayName!.trim()
                              : 'ユーザー'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    UserStatsCard(userId: user.uid),
                  ],
                ),

                // プロフィール完成度カード
                if (_userData != null && _calcProfileCompletion(_userData!) < 1.0) ...[
                  const SizedBox(height: 16),
                  _buildProfileCompletionCard(context, _userData!),
                ],

                const SizedBox(height: 24),

                // 設定セクション（SettingsView と同様）
                _buildSectionTitle('アカウント'),
                _buildSettingsMenuContainer(context, [
                  if (_userData == null || _calcProfileCompletion(_userData!) >= 1.0)
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'プロフィール編集',
                      subtitle: 'アイコンや表示名を変更',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileEditView()),
                        );
                        _loadUserData();
                      },
                    ),
                  if (canChangePassword)
                    _buildMenuItem(
                      icon: Icons.lock,
                      title: 'パスワード変更',
                      subtitle: 'ログインパスワードを変更',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PasswordChangeView()),
                        );
                      },
                    ),
                ]),

                const SizedBox(height: 24),

                _buildSectionTitle('通知'),
                _buildSettingsMenuContainer(context, [
                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: '通知設定',
                    subtitle: 'プッシュ通知・メール通知の設定',
                    onTap: () => _openNotificationSettings(context),
                  ),
                ]),

                const SizedBox(height: 24),

                // 店舗管理セクションは表示しない

                _buildSectionTitle('サポート'),
                _buildSettingsMenuContainer(context, [
                  _buildMenuItem(
                    icon: Icons.help,
                    title: 'ヘルプ・サポート',
                    subtitle: 'よくある質問やサポート',
                    trailing: _buildLiveChatUnreadTrailing(),
                    onTap: () => _showHelp(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'フィードバック',
                    subtitle: 'ご意見・不具合の報告',
                    onTap: () => _openFeedback(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.description,
                    title: '利用規約',
                    subtitle: 'サービス利用規約を確認',
                    onTap: () => _showTerms(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.policy,
                    title: 'プライバシーポリシー',
                    subtitle: '個人情報の取り扱いについて',
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                ]),

                const SizedBox(height: 24),

                _buildSectionTitle('アカウント'),
                _buildSettingsMenuContainer(context, [
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'ログアウト',
                    subtitle: 'アカウントからログアウト',
                    onTap: () => _showLogoutDialog(context, ref),
                    isDestructive: true,
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_forever,
                    title: '退会する',
                    subtitle: 'アカウントを完全に削除',
                    onTap: () => _showDeleteAccountDialog(context),
                    isDestructive: true,
                  ),
                ]),
                const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildUserAvatar(user, Map<String, dynamic>? userData) {
    final Color defaultAvatarColor = Colors.grey.withOpacity(0.1);
    // Firestoreから取得したprofileImageUrlを優先し、なければFirebase AuthのphotoURLを使用
    String? imageUrl;
    if (userData != null && userData['profileImageUrl'] != null && userData['profileImageUrl'].toString().isNotEmpty) {
      imageUrl = userData['profileImageUrl'];
    } else if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      imageUrl = user.photoURL;
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: defaultAvatarColor,
      child: imageUrl != null
          ? ClipOval(
              child: _buildImageWidget(imageUrl),
            )
          : const Icon(
              Icons.person,
              size: 40,
              color: Colors.grey,
            ),
    );
  }


  Widget _buildImageWidget(String imageUrl) {
    // CORS制限を回避する画像表示方法
    if (kIsWeb) {
      // Web用 - CORS制限を回避する複数の方法
      return _buildWebImageWithCorsFix(imageUrl);
    } else {
      // モバイル用の画像読み込み
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) {
          print('画像読み込みエラー: $error');
          return const Icon(
            Icons.person,
            size: 40,
            color: Colors.grey,
          );
        },
      );
    }
  }

  Widget _buildWebImageWithCorsFix(String imageUrl) {
    // Flutter Webでは、シンプルなImage.networkを使用
    return _buildSimpleWebImage(imageUrl);
  }

  Widget _buildFirebaseStorageImage(String imageUrl) {
    // Firebase Storageの画像を直接表示
    print('Firebase Storage画像を直接表示: $imageUrl');
    
    return _buildSimpleWebImage(imageUrl);
  }

  Future<String?> _loadImageWithCorsFix(String imageUrl) async {
    try {
      print('CORS修正で画像読み込み開始: $imageUrl');
      
      // 1. 複数のプロキシサービスを試行
      final proxyServices = [
        'https://api.allorigins.win/raw?url=',
        'https://cors-anywhere.herokuapp.com/',
        'https://thingproxy.freeboard.io/fetch/',
      ];
      
      for (final proxy in proxyServices) {
        try {
          final proxyUrl = '$proxy$imageUrl';
          print('プロキシ試行: $proxyUrl');
          
          final response = await http.get(
            Uri.parse(proxyUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ).timeout(const Duration(seconds: 8));
          
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final base64String = base64Encode(bytes);
            print('プロキシ経由で画像読み込み成功: $proxy');
            return base64String;
          }
        } catch (e) {
          print('プロキシ $proxy でエラー: $e');
          continue;
        }
      }
      
      // 2. 直接読み込みを試行（ヘッダーなし）
      try {
        final directResponse = await http.get(
          Uri.parse(imageUrl),
        ).timeout(const Duration(seconds: 5));
        
        if (directResponse.statusCode == 200) {
          final bytes = directResponse.bodyBytes;
          final base64String = base64Encode(bytes);
          print('直接読み込みで画像読み込み成功');
          return base64String;
        }
      } catch (e) {
        print('直接読み込みでエラー: $e');
      }
      
      print('すべての画像読み込み方法が失敗');
      return null;
    } catch (e) {
      print('CORS修正で画像読み込みエラー: $e');
      return null;
    }
  }

  Widget _buildSimpleWebImage(String imageUrl) {
    // Flutter WebでシンプルなImage.networkを使用
    print('シンプルなWeb画像表示開始: $imageUrl');
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          // エラーハンドリング（無限ループを防ぐ）
          errorBuilder: (context, error, stackTrace) {
            print('シンプルなWeb画像読み込みエラー: $error');
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 40,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebImageWidget(String imageUrl) {
    // Web用の画像読み込み - 複数の方法でCORS制限を回避
    return FutureBuilder<String?>(
      future: _loadImageWithFallback(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6B35),
              strokeWidth: 2,
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            base64Decode(snapshot.data!),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          );
        }
        
        // エラー時は直接Image.networkを試行
        return _buildDirectWebImage(imageUrl);
      },
    );
  }

  Future<String?> _loadImageWithFallback(String imageUrl) async {
    // 複数の方法で画像読み込みを試行
    try {
      // 1. 直接読み込み（Firebase Storageは直接読み込める）
      final directResult = await _loadImageDirectly(imageUrl);
      if (directResult != null) return directResult;
      
      // 2. プロキシ経由での読み込み
      final result = await _loadImageAsBase64(imageUrl);
      if (result != null) return result;
      
      // 3. 代替プロキシサービス
      return await _loadImageWithAlternativeProxy(imageUrl);
    } catch (e) {
      print('すべての画像読み込み方法が失敗: $e');
      return null;
    }
  }

  Future<String?> _loadImageWithAlternativeProxy(String imageUrl) async {
    try {
      // 代替のCORSプロキシサービス
      final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}';
      
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final base64String = base64Encode(bytes);
        print('代替プロキシ経由で画像読み込み成功');
        return base64String;
      }
    } catch (e) {
      print('代替プロキシ経由の画像読み込みエラー: $e');
    }
    return null;
  }

  Widget _buildDirectWebImage(String imageUrl) {
    // 最後の手段として直接Image.networkを使用
    return Image.network(
      imageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('直接画像読み込みも失敗: $error');
        return const Icon(
          Icons.person,
          size: 40,
          color: Colors.grey,
        );
      },
    );
  }

  Widget _buildStatsRow(String userId, WidgetRef ref) {
    final userDocAsync = ref.watch(StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>?, String>((ref, uid) {
      return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    })(userId));
    final newBadgeCountAsync = ref.watch(FutureProvider.family<int, String>((ref, userId) async {
      final badgeService = ref.read(badgeProvider);
      return await badgeService.getNewBadgeCount(userId);
    })(userId));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
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

  // =============== Profile Completion ===============
  double _calcProfileCompletion(Map<String, dynamic> data) {
    int filled = 0;
    const total = 9;

    if (data['displayName'] is String && (data['displayName'] as String).trim().isNotEmpty) filled++;
    if (data['birthDate'] != null) filled++;
    if (data['gender'] is String && (data['gender'] as String).isNotEmpty) filled++;
    if (data['prefecture'] is String && (data['prefecture'] as String).isNotEmpty) filled++;
    if (data['city'] is String && (data['city'] as String).isNotEmpty) filled++;
    if (data['occupation'] is String && (data['occupation'] as String).isNotEmpty) filled++;
    if (data['bio'] is String && (data['bio'] as String).trim().isNotEmpty) filled++;
    if (data['interestCategories'] is List && (data['interestCategories'] as List).isNotEmpty) filled++;
    if (data['profileImageUrl'] is String && (data['profileImageUrl'] as String).isNotEmpty) filled++;

    return filled / total;
  }

  Widget _buildProfileCompletionCard(BuildContext context, Map<String, dynamic> data) {
    final completion = _calcProfileCompletion(data);
    final percent = (completion * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'プロフィールを完成させよう！',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '完成させると5コインもらえる＆あなたに合ったお店が見つかりやすくなります',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditView()),
                );
                _loadUserData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'プロフィールを編集する',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============== Settings-style helpers (mirroring SettingsView) ===============
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsMenuContainer(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFFFF6B35)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey[600]))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildLiveChatUnreadTrailing() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final userId = authSnapshot.data?.uid;
        if (userId == null) {
          return const Icon(Icons.chevron_right);
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('messages')
              .where('userId', isEqualTo: userId)
              .where('senderRole', isEqualTo: 'owner')
              .where('readByUserAt', isNull: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Icon(Icons.chevron_right);
            }
            final totalUnread = snapshot.data?.docs.length ?? 0;
            if (totalUnread <= 0) {
              return const Icon(Icons.chevron_right);
            }
            final badgeText = totalUnread > 99 ? '99+' : totalUnread.toString();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            );
          },
        );
      },
    );
  }

  void _openNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsView(),
      ),
    );
  }

  // （削除）_showCacheClear / _showDataCleanup は不要になりました

  void _showHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpView(),
      ),
    );
  }

  void _openFeedback(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FeedbackView(),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsView(),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyView(),
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
              await _performLogout(context);
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainNavigationView(
              key: ValueKey('guest'),
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウトに失敗しました: $e')),
        );
      }
    }
  }

  // 退会ダイアログ（SettingsView 削除に伴いこちらで提供）
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退会'),
        content: const Text('退会しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountDeletionProcessingView(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('退会する'),
          ),
        ],
      ),
    );
  }

}
