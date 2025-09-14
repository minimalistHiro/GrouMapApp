import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/store_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/badge_provider.dart';
import 'home_view.dart';
import 'map/map_view.dart';
import 'qr/qr_generator_view.dart';
import 'profile/profile_view.dart';
import 'coupons/coupons_view.dart';

class MainNavigationView extends ConsumerStatefulWidget {
  const MainNavigationView({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends ConsumerState<MainNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    const MapView(),
    const QRGeneratorView(),
    const CouponsView(),
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // 初期データ読み込み
    _loadInitialData();
  }

  // 初期データ読み込み
  Future<void> _loadInitialData() async {
    // 認証状態を確認
    final authState = ref.read(authStateProvider);
    await authState.when(
      data: (user) async {
        if (user != null) {
          // ログイン済みの場合、必要なデータを並列で読み込み
          await Future.wait([
            _loadUserData(user.uid),
            _loadLocationData(),
            _loadStoreData(),
          ]);
        }
      },
      loading: () async {},
      error: (error, _) async {},
    );
  }

  // ユーザーデータ読み込み
  Future<void> _loadUserData(String userId) async {
    try {
      // ユーザーデータのプロバイダーを無効化して再読み込み
      ref.invalidate(authStateProvider);
    } catch (e) {
      debugPrint('ユーザーデータ読み込みエラー: $e');
    }
  }

  // 位置情報データ読み込み
  Future<void> _loadLocationData() async {
    try {
      final locationNotifier = ref.read(locationStateProvider.notifier);
      await locationNotifier.getCurrentPosition();
    } catch (e) {
      debugPrint('位置情報読み込みエラー: $e');
    }
  }

  // 店舗データ読み込み
  Future<void> _loadStoreData() async {
    try {
      // 店舗データのプロバイダーを無効化して再読み込み
      ref.invalidate(storesProvider);
    } catch (e) {
      debugPrint('店舗データ読み込みエラー: $e');
    }
  }

  // タブ切り替え時のデータ読み込み
  Future<void> _onTabChanged(int index) async {
    setState(() {
      _currentIndex = index;
    });

    // タブに応じて必要なデータを読み込み
    await _loadTabSpecificData(index);
  }

  // タブ固有のデータ読み込み
  Future<void> _loadTabSpecificData(int tabIndex) async {
    final authState = ref.read(authStateProvider);
    await authState.when(
      data: (user) async {
        if (user == null) return;

        switch (tabIndex) {
          case 0: // ホーム
            await _loadHomeData(user.uid);
            break;
          case 1: // マップ
            await _loadMapData(user.uid);
            break;
          case 2: // QRコード
            await _loadQRData(user.uid);
            break;
          case 3: // クーポン
            await _loadCouponData(user.uid);
            break;
          case 4: // プロフィール
            await _loadProfileData(user.uid);
            break;
        }
      },
      loading: () async {},
      error: (error, _) async {},
    );
  }

  // 各タブのデータ読み込みメソッド
  Future<void> _loadHomeData(String userId) async {
    // ホーム画面のデータは既にuserDataProviderで管理されているため、
    // 必要に応じてプロバイダーを無効化
    ref.invalidate(authStateProvider);
  }

  Future<void> _loadMapData(String userId) async {
    // マップ画面のデータ読み込み
    await _loadLocationData();
    await _loadStoreData();
  }

  Future<void> _loadQRData(String userId) async {
    // QRコード画面のデータ読み込み
    // QRコード画面は主にスキャン機能のため、特別なデータ読み込みは不要
  }


  Future<void> _loadCouponData(String userId) async {
    // クーポン画面のデータ読み込み
    try {
      ref.invalidate(availableCouponsProvider(userId));
      ref.invalidate(userCouponsProvider(userId));
      ref.invalidate(promotionsProvider);
    } catch (e) {
      debugPrint('クーポンデータ読み込みエラー: $e');
    }
  }

  Future<void> _loadProfileData(String userId) async {
    // プロフィール画面のデータ読み込み
    try {
      ref.invalidate(authStateProvider);
      ref.invalidate(userBadgesProvider(userId));
    } catch (e) {
      debugPrint('プロフィールデータ読み込みエラー: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'マップ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QRコード',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'クーポン',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}
