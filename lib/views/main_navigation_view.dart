import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/owner_settings_provider.dart';
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
      // ユーザー関連データは各Providerのストリームで管理する
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

    final maintenanceGate = _buildMaintenanceGate(context, ref, authState);
    if (maintenanceGate != null) {
      return maintenanceGate;
    }

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

  Widget? _buildMaintenanceGate(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<User?> authState,
  ) {
    final settings = ref.watch(ownerSettingsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (settings == null) {
      return null;
    }
    final currentSettings = _resolveCurrentSettings(settings);
    final startDate = _parseDate(currentSettings['maintenanceStartDate']);
    final startTime = _parseString(currentSettings['maintenanceStartTime']);
    final endDate = _parseDate(currentSettings['maintenanceEndDate']);
    final endTime = _parseString(currentSettings['maintenanceEndTime']);
    final startAt = _combineDateTime(startDate, startTime);
    final endAt = _combineDateTime(endDate, endTime);
    if (startAt == null || endAt == null) {
      return null;
    }
    final now = DateTime.now();
    if (now.isBefore(startAt) || now.isAfter(endAt)) {
      return null;
    }
    final userId = authState.maybeWhen(
      data: (user) => user?.uid,
      orElse: () => null,
    );
    if (userId == null) {
      return _buildMaintenanceScreen(context, startAt, endAt);
    }
    final userData = ref.watch(userDataProvider(userId)).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (userData == null) {
      return null;
    }
    final isOwner = userData['isOwner'] == true;
    if (isOwner) {
      return null;
    }
    return _buildMaintenanceScreen(context, startAt, endAt);
  }

  Widget _buildMaintenanceScreen(
    BuildContext context,
    DateTime startAt,
    DateTime endAt,
  ) {
    final displayText = _isSameDate(startAt, endAt)
        ? '${_formatDate(startAt)} ${_formatTime(startAt)}〜${_formatTime(endAt)}'
        : '${_formatDateTime(startAt)} 〜 ${_formatDateTime(endAt)}';
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.build_circle_outlined,
                  size: 72,
                  color: Color(0xFF1E88E5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'メンテナンス中',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '現在メンテナンスを実施しています。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E88E5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String? _parseString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  DateTime? _combineDateTime(DateTime? date, String? time) {
    if (date == null || time == null || time.trim().isEmpty) {
      return null;
    }
    final parsed = _parseTime(time);
    if (parsed == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameDate(DateTime start, DateTime end) {
    return start.year == end.year && start.month == end.month && start.day == end.day;
  }

  Map<String, dynamic> _resolveCurrentSettings(Map<String, dynamic>? ownerSettings) {
    final rawCurrent = ownerSettings?['current'];
    if (rawCurrent is Map<String, dynamic>) {
      return rawCurrent;
    }
    return ownerSettings ?? <String, dynamic>{};
  }
}
