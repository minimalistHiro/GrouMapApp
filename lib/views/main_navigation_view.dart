import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/badge_provider.dart';
import '../services/push_notification_service.dart';
import 'home_view.dart';
import 'map/map_view.dart';
import 'qr/qr_generator_view.dart';
import 'profile/profile_view.dart';
import 'coupons/coupons_view.dart';

class MainNavigationView extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationView({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  ConsumerState<MainNavigationView> createState() => _MainNavigationViewState();
}

enum _MainTab {
  home,
  map,
  qr,
  coupons,
  profile,
}

class _MainNavigationViewState extends ConsumerState<MainNavigationView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // 初期データ読み込みをフレーム後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      authState.when(
        data: (user) async {
          await _loadInitialData(user);
          final tabs = _tabsForUser(user);
          final safeIndex = _coerceIndex(tabs.length);
          await _loadTabSpecificData(tabs[safeIndex]);
        },
        loading: () {},
        error: (_, __) {},
      );
    });
  }

  // 初期データ読み込み
  Future<void> _loadInitialData(User? user) async {
    final tasks = <Future<void>>[
      _loadLocationData(),
      _loadStoreData(),
    ];

    if (user != null) {
      tasks.add(_loadUserData(user.uid));
    }

    await Future.wait(tasks);
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
      // 位置情報の読み込みは各画面で個別に処理
      debugPrint('位置情報読み込み（個別処理）');
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
  Future<void> _onTabChanged(int index, List<_MainTab> tabs) async {
    setState(() {
      _currentIndex = index;
    });

    // タブに応じて必要なデータを読み込み
    final tab = tabs[index];
    await _loadTabSpecificData(tab);
  }

  // タブ固有のデータ読み込み
  Future<void> _loadTabSpecificData(_MainTab tab) async {
    final authState = ref.read(authStateProvider);
    await authState.when(
      data: (user) async {
        switch (tab) {
          case _MainTab.home:
            if (user != null) {
              await _loadHomeData(user.uid);
            }
            break;
          case _MainTab.map:
            await _loadMapData(user?.uid ?? '');
            break;
          case _MainTab.qr:
            if (user != null) {
              await _loadQRData(user.uid);
            }
            break;
          case _MainTab.coupons:
            await _loadCouponData(user?.uid);
            break;
          case _MainTab.profile:
            if (user != null) {
              await _loadProfileData(user.uid);
            }
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
    final pushService = ref.read(pushNotificationServiceProvider);
    await pushService.syncForUser(userId);
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


  Future<void> _loadCouponData(String? userId) async {
    // クーポン画面のデータ読み込み
    try {
      if (userId != null) {
        ref.invalidate(availableCouponsProvider(userId));
        ref.invalidate(userCouponsProvider(userId));
      } else {
        ref.invalidate(availableCouponsProvider('guest'));
      }
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

  List<_MainTab> _tabsForUser(User? user) {
    if (user == null) {
      return const [
        _MainTab.home,
        _MainTab.map,
        _MainTab.coupons,
      ];
    }

    return const [
      _MainTab.home,
      _MainTab.map,
      _MainTab.qr,
      _MainTab.coupons,
      _MainTab.profile,
    ];
  }

  List<Widget> _pagesForTabs(List<_MainTab> tabs) {
    return tabs.map((tab) {
      switch (tab) {
        case _MainTab.home:
          return const HomeView();
        case _MainTab.map:
          return const MapView();
        case _MainTab.qr:
          return const QRGeneratorView();
        case _MainTab.coupons:
          return const CouponsView();
        case _MainTab.profile:
          return const ProfileView();
      }
    }).toList();
  }

  List<BottomNavigationBarItem> _navItemsForTabs(List<_MainTab> tabs) {
    return tabs.map((tab) {
      switch (tab) {
        case _MainTab.home:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          );
        case _MainTab.map:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'マップ',
          );
        case _MainTab.qr:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QRコード',
          );
        case _MainTab.coupons:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'クーポン',
          );
        case _MainTab.profile:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'アカウント',
          );
      }
    }).toList();
  }

  int _coerceIndex(int length) {
    if (length <= 0) {
      return 0;
    }
    if (_currentIndex >= length) {
      return length - 1;
    }
    return _currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        final tabs = _tabsForUser(user);
        final pages = _pagesForTabs(tabs);
        final items = _navItemsForTabs(tabs);
        final safeIndex = _coerceIndex(pages.length);

        if (safeIndex != _currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _currentIndex = safeIndex;
            });
          });
        }

        return Scaffold(
          body: pages[safeIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: safeIndex,
            onTap: (index) => _onTabChanged(index, tabs),
            selectedItemColor: const Color(0xFFFF6B35),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            backgroundColor: Colors.white,
            elevation: 8,
            items: items,
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }
}
