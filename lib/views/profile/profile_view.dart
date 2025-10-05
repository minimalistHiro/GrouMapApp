import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/level_provider.dart';
import '../badges/badges_view.dart';
import '../settings/profile_edit_view.dart';
import '../settings/settings_view.dart';

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
                // ユーザー情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildUserAvatar(user, _userData),
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

  Widget _buildUserAvatar(user, Map<String, dynamic>? userData) {
    // Firestoreから取得したprofileImageUrlを優先し、なければFirebase AuthのphotoURLを使用
    String? imageUrl;
    if (userData != null && userData['profileImageUrl'] != null && userData['profileImageUrl'].toString().isNotEmpty) {
      imageUrl = userData['profileImageUrl'];
    } else if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      imageUrl = user.photoURL;
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey[300],
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
            icon: Icons.person,
            title: 'プロフィール編集',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileEditView()),
              );
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
