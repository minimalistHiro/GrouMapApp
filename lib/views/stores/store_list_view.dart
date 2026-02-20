import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_top_tab_bar.dart';
import '../../widgets/common_header.dart';
import 'store_detail_view.dart';

class StoreListView extends ConsumerStatefulWidget {
  const StoreListView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreListView> createState() => _StoreListViewState();
}

class _StoreListViewState extends ConsumerState<StoreListView> {
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Map<String, dynamic> _toStoreDetailStore(
    String id,
    Map<String, dynamic> data,
  ) {
    final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
    final phoneNumber = (data['phoneNumber'] ?? data['phone'] ?? '').toString();

    final rawBusinessHours = data['businessHours'];
    final businessHours = rawBusinessHours is Map
        ? Map<String, dynamic>.from(rawBusinessHours)
        : null;

    final rawTags = data['tags'];
    final tags = rawTags is List
        ? rawTags.map((tag) => tag.toString()).toList()
        : <String>[];

    final rawSocialMedia = data['socialMedia'];
    final socialMedia = rawSocialMedia is Map
        ? Map<String, dynamic>.from(rawSocialMedia)
        : <String, dynamic>{};

    final rawLocation = data['location'];
    Map<String, dynamic>? location;
    if (rawLocation is GeoPoint) {
      location = {
        'latitude': rawLocation.latitude,
        'longitude': rawLocation.longitude,
      };
    } else if (rawLocation is Map) {
      location = Map<String, dynamic>.from(rawLocation);
    }

    return {
      'id': id,
      'name': data['name'] ?? '店舗名なし',
      'category': data['category'] ?? 'その他',
      'subCategory': data['subCategory'] ?? '',
      'description': data['description'] ?? '',
      'address': data['address'] ?? '',
      'iconImageUrl': data['iconImageUrl'],
      'storeImageUrl': data['storeImageUrl'],
      'backgroundImageUrl': data['backgroundImageUrl'],
      'phone': phone,
      'phoneNumber': phoneNumber,
      'businessHours': businessHours,
      'location': location,
      'tags': tags,
      'socialMedia': socialMedia,
      'paymentMethods': data['paymentMethods'],
      'facilityInfo': data['facilityInfo'],
      'isActive': data['isActive'] ?? false,
      'isApproved': data['isApproved'] ?? false,
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
      'isVisited': false,
    };
  }

  // データベースから店舗を読み込む
  Future<void> _loadStores() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('店舗一覧の読み込みを開始...');
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('stores').get();
      final ownerUsersBoolSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isOwner', isEqualTo: true)
          .get();
      final ownerUsersStringSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isOwner', isEqualTo: 'true')
          .get();
      final ownerUserIds = <String>{
        ...ownerUsersBoolSnapshot.docs.map((doc) => doc.id),
        ...ownerUsersStringSnapshot.docs.map((doc) => doc.id),
      };
      print('取得したドキュメント数: ${snapshot.docs.length}');
      print('isOwner=true ユーザー数: ${ownerUserIds.length}');

      final List<Map<String, dynamic>> stores = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rawIsOwner = data['isOwner'];
        final hasOwnerFlag = rawIsOwner == true ||
            rawIsOwner?.toString().toLowerCase() == 'true';
        final createdBy = (data['createdBy'] ?? data['ownerId'])?.toString();
        final isOwnerByCreator =
            createdBy != null && ownerUserIds.contains(createdBy);
        final isOwnerStore = hasOwnerFlag || isOwnerByCreator;
        print(
            '店舗データ: ${doc.id} - isActive: ${data['isActive']}, isApproved: ${data['isApproved']}');
        if (isOwnerStore) {
          print(
              'isOwner=true のため除外: ${doc.id} (storeFlag: $hasOwnerFlag, createdBy: $createdBy, creatorOwner: $isOwnerByCreator)');
          continue;
        }

        // マップ画面と同様に、isOwner=false かつアクティブかつ承認済みのみ表示
        if (data['isActive'] == true && data['isApproved'] == true) {
          stores.add(_toStoreDetailStore(doc.id, data));
          print('店舗を追加: ${data['name']}');
        }
      }

      print('読み込んだ店舗数: ${stores.length}');

      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('店舗データの読み込みに失敗しました: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return _buildStoreListScaffold();
        }
        final userData = ref.watch(userDataProvider(user.uid)).maybeWhen(
              data: (data) => data,
              orElse: () => null,
            );
        final favoriteIds = _extractFavoriteIds(userData);
        final followedIds = _extractFollowedIds(userData);
        return _buildStoreListScaffold(favoriteIds: favoriteIds, followedIds: followedIds);
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.grey,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: const CommonHeader(title: '店舗一覧'),
        body: Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildStoreListScaffold({Set<String>? favoriteIds, Set<String>? followedIds}) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: const CommonHeader(title: '店舗一覧'),
        body: Column(
          children: [
            const CustomTopTabBar(
              tabs: [
                Tab(text: 'お気に入り'),
                Tab(text: 'フォロー'),
                Tab(text: '店舗一覧'),
              ],
            ),
            Expanded(
              child: _buildBody(favoriteIds: favoriteIds ?? {}, followedIds: followedIds ?? {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required Set<String> favoriteIds, required Set<String> followedIds}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '再試行',
              onPressed: _loadStores,
            ),
          ],
        ),
      );
    }

    final favoriteStores = _filterFavoriteStores(_stores, favoriteIds);
    final followedStores = _filterFollowedStores(_stores, followedIds);

    return TabBarView(
      children: [
        _buildStoresContent(
          stores: favoriteStores,
          emptyMessage: 'お気に入りの店舗がありません',
        ),
        _buildStoresContent(
          stores: followedStores,
          emptyMessage: 'フォロー中の店舗がありません',
        ),
        _buildStoresContent(
          stores: _stores,
          emptyMessage: '店舗が見つかりませんでした',
        ),
      ],
    );
  }

  Set<String> _extractFavoriteIds(Map<String, dynamic>? userData) {
    if (userData == null) return {};
    final raw = userData['favoriteStoreIds'];
    if (raw is List) {
      return raw.map((id) => id.toString()).toSet();
    }
    return {};
  }

  Set<String> _extractFollowedIds(Map<String, dynamic>? userData) {
    if (userData == null) return {};
    final raw = userData['followedStoreIds'];
    if (raw is List) {
      return raw.map((id) => id.toString()).toSet();
    }
    return {};
  }

  List<Map<String, dynamic>> _filterFavoriteStores(
    List<Map<String, dynamic>> stores,
    Set<String> favoriteIds,
  ) {
    if (favoriteIds.isEmpty) return [];
    final favorites = <Map<String, dynamic>>[];
    for (final store in stores) {
      final storeId = store['id']?.toString();
      if (storeId != null && favoriteIds.contains(storeId))
        favorites.add(store);
    }
    return favorites;
  }

  List<Map<String, dynamic>> _filterFollowedStores(
    List<Map<String, dynamic>> stores,
    Set<String> followedIds,
  ) {
    if (followedIds.isEmpty) return [];
    final followed = <Map<String, dynamic>>[];
    for (final store in stores) {
      final storeId = store['id']?.toString();
      if (storeId != null && followedIds.contains(storeId))
        followed.add(store);
    }
    return followed;
  }

  Widget _buildStoresContent({
    required List<Map<String, dynamic>> stores,
    required String emptyMessage,
  }) {
    if (stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4列
          childAspectRatio: 0.7, // 縦長の比率（カードの高さを少し上げる）
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return _buildStoreCard(store);
        },
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoreDetailView(store: store),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 店舗アイコン
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    _getCategoryColor(_getStringValue(store['category'], 'その他'))
                        .withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getCategoryColor(
                          _getStringValue(store['category'], 'その他'))
                      .withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _buildStoreIcon(store),
            ),

            const SizedBox(height: 8),

            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _getStringValue(store['name'], '店舗名なし'),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            // カテゴリ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    _getCategoryColor(_getStringValue(store['category'], 'その他'))
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getCategoryColor(
                          _getStringValue(store['category'], 'その他'))
                      .withOpacity(0.3),
                ),
              ),
              child: Text(
                _getStringValue(store['category'], 'その他'),
                style: TextStyle(
                  fontSize: 8,
                  color: _getCategoryColor(
                      _getStringValue(store['category'], 'その他')),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 安全にStringを取得するヘルパーメソッド
  String _getStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) return value.toString();
    return value.toString();
  }

  // カテゴリに応じた色を取得
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'カフェ・喫茶店':
        return const Color(0xFF6F4E37);
      case 'レストラン':
        return const Color(0xFFD32F2F);
      case '居酒屋':
        return const Color(0xFF6D4C41);
      case '和食':
        return const Color(0xFFB71C1C);
      case '日本料理':
        return const Color(0xFF8E0000);
      case '海鮮':
        return const Color(0xFF00695C);
      case '寿司':
        return const Color(0xFF00897B);
      case 'そば':
        return const Color(0xFF5D4037);
      case 'うどん':
        return const Color(0xFF795548);
      case 'うなぎ':
        return const Color(0xFF3E2723);
      case '焼き鳥':
        return const Color(0xFFBF360C);
      case 'とんかつ':
        return const Color(0xFFEF6C00);
      case '串揚げ':
        return const Color(0xFFF57C00);
      case '天ぷら':
        return const Color(0xFFFF8F00);
      case 'お好み焼き':
        return const Color(0xFF9E9D24);
      case 'もんじゃ焼き':
        return const Color(0xFF827717);
      case 'しゃぶしゃぶ':
        return const Color(0xFFAD1457);
      case '鍋':
        return const Color(0xFFC2185B);
      case '焼肉':
        return const Color(0xFFD84315);
      case 'ホルモン':
        return const Color(0xFFBF360C);
      case 'ラーメン':
        return const Color(0xFF7B1FA2);
      case '中華料理':
        return const Color(0xFFB71C1C);
      case '餃子':
        return const Color(0xFF9C27B0);
      case '韓国料理':
        return const Color(0xFF5E35B1);
      case 'タイ料理':
        return const Color(0xFF00838F);
      case 'カレー':
        return const Color(0xFFF9A825);
      case '洋食':
        return const Color(0xFF1976D2);
      case 'フレンチ':
        return const Color(0xFF3F51B5);
      case 'スペイン料理':
        return const Color(0xFFE65100);
      case 'ビストロ':
        return const Color(0xFF5C6BC0);
      case 'パスタ':
        return const Color(0xFF4CAF50);
      case 'ピザ':
        return const Color(0xFF388E3C);
      case 'ステーキ':
        return const Color(0xFFB71C1C);
      case 'ハンバーグ':
        return const Color(0xFF8D6E63);
      case 'ハンバーガー':
        return const Color(0xFF6D4C41);
      case 'ビュッフェ':
        return const Color(0xFF0097A7);
      case '食堂':
        return const Color(0xFF607D8B);
      case 'パン・サンドイッチ':
        return const Color(0xFF8D6E63);
      case 'スイーツ':
        return const Color(0xFFFF80AB);
      case 'ケーキ':
        return const Color(0xFFFF4081);
      case 'タピオカ':
        return const Color(0xFF7E57C2);
      case 'バー・お酒':
        return const Color(0xFF455A64);
      case 'スナック':
        return const Color(0xFF546E7A);
      case '料理旅館':
        return const Color(0xFF4E342E);
      case '沖縄料理':
        return const Color(0xFF00ACC1);
      case 'ショップ':
        return const Color(0xFF1565C0);
      case '美容院':
        return const Color(0xFFEC407A);
      case '薬局':
        return const Color(0xFF43A047);
      case 'コンビニ':
        return const Color(0xFFFF8A65);
      case 'スーパー':
        return const Color(0xFF8BC34A);
      case '書店':
        return const Color(0xFF7E57C2);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // 店舗アイコンを構築
  Widget _buildStoreIcon(Map<String, dynamic> store) {
    final iconImageUrl = _getStringValue(store['iconImageUrl'], '');
    final category = _getStringValue(store['category'], 'その他');

    if (iconImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          iconImageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: _getCategoryColor(category),
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('店舗アイコン画像の読み込みエラー: $error / url=$iconImageUrl');
            return Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 30,
            );
          },
        ),
      );
    } else {
      return Icon(
        _getCategoryIcon(category),
        color: _getCategoryColor(category),
        size: 30,
      );
    }
  }

  // カテゴリに応じたアイコンを取得
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'カフェ・喫茶店':
        return Icons.local_cafe;
      case 'レストラン':
        return Icons.restaurant;
      case '居酒屋':
        return Icons.sports_bar;
      case '和食':
        return Icons.ramen_dining;
      case '日本料理':
        return Icons.set_meal;
      case '海鮮':
        return Icons.set_meal;
      case '寿司':
        return Icons.set_meal;
      case 'そば':
        return Icons.ramen_dining;
      case 'うどん':
        return Icons.ramen_dining;
      case 'うなぎ':
        return Icons.set_meal;
      case '焼き鳥':
        return Icons.outdoor_grill;
      case 'とんかつ':
        return Icons.set_meal;
      case '串揚げ':
        return Icons.outdoor_grill;
      case '天ぷら':
        return Icons.set_meal;
      case 'お好み焼き':
        return Icons.local_dining;
      case 'もんじゃ焼き':
        return Icons.local_dining;
      case 'しゃぶしゃぶ':
        return Icons.soup_kitchen;
      case '鍋':
        return Icons.soup_kitchen;
      case '焼肉':
        return Icons.local_fire_department;
      case 'ホルモン':
        return Icons.local_fire_department;
      case 'ラーメン':
        return Icons.ramen_dining;
      case '中華料理':
        return Icons.restaurant_menu;
      case '餃子':
        return Icons.restaurant_menu;
      case '韓国料理':
        return Icons.restaurant_menu;
      case 'タイ料理':
        return Icons.restaurant_menu;
      case 'カレー':
        return Icons.rice_bowl;
      case '洋食':
        return Icons.dinner_dining;
      case 'フレンチ':
        return Icons.wine_bar;
      case 'スペイン料理':
        return Icons.wine_bar;
      case 'ビストロ':
        return Icons.wine_bar;
      case 'パスタ':
        return Icons.dinner_dining;
      case 'ピザ':
        return Icons.local_pizza;
      case 'ステーキ':
        return Icons.local_fire_department;
      case 'ハンバーグ':
        return Icons.dinner_dining;
      case 'ハンバーガー':
        return Icons.fastfood;
      case 'ビュッフェ':
        return Icons.restaurant;
      case '食堂':
        return Icons.restaurant;
      case 'パン・サンドイッチ':
        return Icons.bakery_dining;
      case 'スイーツ':
        return Icons.icecream;
      case 'ケーキ':
        return Icons.cake;
      case 'タピオカ':
        return Icons.local_drink;
      case 'バー・お酒':
        return Icons.local_bar;
      case 'スナック':
        return Icons.local_bar;
      case '料理旅館':
        return Icons.house;
      case '沖縄料理':
        return Icons.beach_access;
      case 'ショップ':
        return Icons.shopping_bag;
      case '美容院':
        return Icons.content_cut;
      case '薬局':
        return Icons.local_pharmacy;
      case 'コンビニ':
        return Icons.store;
      case 'スーパー':
        return Icons.shopping_cart;
      case '書店':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }
}
