import 'dart:async';
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
import 'payment/point_payment_detail_view.dart';

class MainNavigationView extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationView({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  ConsumerState<MainNavigationView> createState() => _MainNavigationViewState();
}

class _LoweredFabLocation extends FloatingActionButtonLocation {
  final double offset;
  const _LoweredFabLocation(this.offset);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final baseOffset = FloatingActionButtonLocation.centerDocked.getOffset(scaffoldGeometry);
    return Offset(baseOffset.dx, baseOffset.dy + offset);
  }
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
  int _lastNonQrTabIndex = 0;
  static const double _fabVerticalOffset = 12;
  static const double _fabIconSize = 20;
  static const double _fabLabelSize = 10;
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;
  ProviderSubscription<AsyncValue<Map<String, dynamic>?>>? _userDataSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _storesSub;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _storeRequestSubs = {};
  bool _isNavigatingToPointDetail = false;
  String? _lastHandledRequestId;
  bool _referralPopupShown = false;
  bool _didInitialLoad = false;
  String? _lastInitialUserId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _authSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) {
        next.whenData((user) {
          _triggerInitialLoad(user);
          _userDataSubscription?.close();
          _stopPointRequestListener();
          if (user == null) {
            return;
          }
          _startPointRequestListener(user.uid);
          _userDataSubscription = ref.listenManual<AsyncValue<Map<String, dynamic>?>>(
            userDataProvider(user.uid),
            (prev, data) {
              final userData = data.valueOrNull;
              if (userData == null) return;
              _maybeShowReferralPopup(user.uid, userData);
            },
          );
        });
      },
    );
    // 初期データ読み込みをフレーム後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didInitialLoad) {
        return;
      }
      final authState = ref.read(authStateProvider);
      authState.when(
        data: (user) async {
          _triggerInitialLoad(user);
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
      ref.invalidate(userDataProvider(userId));
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

  List<_MainTab> _bottomTabsFor(List<_MainTab> tabs) {
    return tabs.where((tab) => tab != _MainTab.qr).toList();
  }

  void _setCurrentTab(int index, List<_MainTab> tabs) {
    _currentIndex = index;
    final tab = tabs[index];
    if (tab != _MainTab.qr) {
      final bottomIndex = _bottomTabsFor(tabs).indexOf(tab);
      if (bottomIndex >= 0) {
        _lastNonQrTabIndex = bottomIndex;
      }
    }
  }

  // タブ切り替え時のデータ読み込み（BottomNavigationBar用）
  Future<void> _onBottomTabChanged(int bottomIndex, List<_MainTab> tabs) async {
    final bottomTabs = _bottomTabsFor(tabs);
    final showPlaceholder = tabs.contains(_MainTab.qr);
    final placeholderIndex = showPlaceholder ? _placeholderIndexFor(bottomTabs) : -1;
    final bottomTabIndex = _bottomTabIndexForVisualIndex(bottomIndex, placeholderIndex);
    if (bottomTabIndex == null) {
      return;
    }
    final nextTab = bottomTabs[bottomTabIndex];
    final nextIndex = tabs.indexOf(nextTab);
    setState(() {
      _setCurrentTab(nextIndex, tabs);
    });

    // タブに応じて必要なデータを読み込み
    await _loadTabSpecificData(nextTab);
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

  void _triggerInitialLoad(User? user) {
    final userId = user?.uid;
    if (_didInitialLoad && userId == _lastInitialUserId) {
      return;
    }
    _didInitialLoad = true;
    _lastInitialUserId = userId;
    _loadInitialData(user);
    final tabs = _tabsForUser(user);
    final safeIndex = _coerceIndex(tabs.length);
    _loadTabSpecificData(tabs[safeIndex]);
  }

  void _onQrFabPressed(List<_MainTab> tabs) {
    if (!tabs.contains(_MainTab.qr)) {
      return;
    }
    _loadTabSpecificData(_MainTab.qr);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRGeneratorView(),
      ),
    );
  }

  int _safeBottomIndex(List<_MainTab> bottomTabs) {
    if (bottomTabs.isEmpty) {
      return 0;
    }
    return _lastNonQrTabIndex.clamp(0, bottomTabs.length - 1);
  }

  int _placeholderIndexFor(List<_MainTab> bottomTabs) {
    final mapIndex = bottomTabs.indexOf(_MainTab.map);
    final couponsIndex = bottomTabs.indexOf(_MainTab.coupons);
    if (mapIndex >= 0 && couponsIndex >= 0 && mapIndex < couponsIndex) {
      return mapIndex + 1;
    }
    return -1;
  }

  int? _bottomTabIndexForVisualIndex(int visualIndex, int placeholderIndex) {
    if (placeholderIndex < 0) {
      return visualIndex;
    }
    if (visualIndex == placeholderIndex) {
      return null;
    }
    return visualIndex > placeholderIndex ? visualIndex - 1 : visualIndex;
  }

  int _visualIndexForBottomTabIndex(int bottomTabIndex, int placeholderIndex) {
    if (placeholderIndex < 0) {
      return bottomTabIndex;
    }
    return bottomTabIndex >= placeholderIndex ? bottomTabIndex + 1 : bottomTabIndex;
  }

  List<BottomNavigationBarItem> _bottomNavItemsWithPlaceholder(
    List<_MainTab> bottomTabs,
    bool showPlaceholder, {
    int profileBadgeCount = 0,
  }) {
    final items = _navItemsForTabs(
      bottomTabs,
      profileBadgeCount: profileBadgeCount,
    );
    final placeholderIndex = showPlaceholder ? _placeholderIndexFor(bottomTabs) : -1;
    if (placeholderIndex >= 0 && placeholderIndex <= items.length) {
      items.insert(
        placeholderIndex,
        const BottomNavigationBarItem(
          icon: SizedBox.shrink(),
          label: '',
        ),
      );
    }
    return items;
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

  List<BottomNavigationBarItem> _navItemsForTabs(
    List<_MainTab> tabs, {
    int profileBadgeCount = 0,
  }) {
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
          return BottomNavigationBarItem(
            icon: _buildProfileNavIcon(profileBadgeCount),
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
  void dispose() {
    _authSubscription?.close();
    _userDataSubscription?.close();
    _stopPointRequestListener();
    super.dispose();
  }

  void _startPointRequestListener(String userId) {
    _stopPointRequestListener();
    _storesSub = FirebaseFirestore.instance.collection('stores').snapshots().listen((storesSnap) {
      if (!mounted) return;
      final currentStoreIds =
          _storeRequestSubs.keys.map((key) => key.split(':').first).toSet();
      final incomingStoreIds = storesSnap.docs.map((d) => d.id).toSet();

      for (final storeId in incomingStoreIds.difference(currentStoreIds)) {
        final key = '$storeId:award';
        final docRef = FirebaseFirestore.instance
            .collection('point_requests')
            .doc(storeId)
            .collection(userId)
            .doc('award_request');
        final sub = docRef.snapshots().listen((doc) async {
          if (!mounted) return;
          if (!doc.exists) return;
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString();
          if (status != 'accepted') return;
          if (_isRequestAlreadyNotified(data)) return;
          final combinedRequestId = '${storeId}_$userId';
          if (_isNavigatingToPointDetail || _lastHandledRequestId == combinedRequestId) return;

          _isNavigatingToPointDetail = true;
          _lastHandledRequestId = combinedRequestId;
          try {
            final points = _parseRequestPoints(data);
            final amount = _parseRequestAmount(data);
            final usedPoints = _parseRequestUsedPoints(data);
            final usedCouponIds = _parseRequestCouponIds(data);
            await _markRequestNotified(storeId: storeId, userId: userId);
            if (!mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PointPaymentDetailView(
                  storeId: storeId,
                  paid: amount,
                  pointsAwarded: points,
                  pointsUsed: usedPoints,
                  usedCouponIds: usedCouponIds,
                ),
              ),
            );
          } finally {
            if (mounted) {
              _isNavigatingToPointDetail = false;
            }
          }
        });
        _storeRequestSubs[key] = sub;
      }

      for (final removedId in currentStoreIds.difference(incomingStoreIds)) {
        _storeRequestSubs.remove('$removedId:award')?.cancel();
      }
    }, onError: (_) {});
  }

  void _stopPointRequestListener() {
    _storesSub?.cancel();
    _storesSub = null;
    for (final sub in _storeRequestSubs.values) {
      sub.cancel();
    }
    _storeRequestSubs.clear();
  }

  bool _isRequestAlreadyNotified(Map<String, dynamic> data) {
    final notified = data['userNotified'];
    if (notified is bool && notified) return true;
    return data.containsKey('userNotifiedAt') && data['userNotifiedAt'] != null;
  }

  int _parseRequestPoints(Map<String, dynamic> data) {
    final pointsValue = data['userPoints'] ?? data['pointsToAward'];
    if (pointsValue is int) return pointsValue;
    if (pointsValue is num) return pointsValue.toInt();
    return int.tryParse('$pointsValue') ?? 0;
  }

  int _parseRequestAmount(Map<String, dynamic> data) {
    final amountValue = data['amount'];
    if (amountValue is int) return amountValue;
    if (amountValue is num) return amountValue.toInt();
    return int.tryParse('$amountValue') ?? 0;
  }

  int _parseRequestUsedPoints(Map<String, dynamic> data) {
    final usedValue = data['usedPoints'];
    if (usedValue is int) return usedValue;
    if (usedValue is num) return usedValue.toInt();
    return int.tryParse('$usedValue') ?? 0;
  }

  List<String> _parseRequestCouponIds(Map<String, dynamic> data) {
    final raw = data['selectedCouponIds'] ?? data['usedCouponIds'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  Future<void> _markRequestNotified({
    required String storeId,
    required String userId,
  }) async {
    await FirebaseFirestore.instance
        .collection('point_requests')
        .doc(storeId)
        .collection(userId)
        .doc('award_request')
        .update({
      'userNotified': true,
      'userNotifiedAt': FieldValue.serverTimestamp(),
    });
  }

  void _maybeShowReferralPopup(String userId, Map<String, dynamic> userData) {
    if (_referralPopupShown) return;
    final inviteePopupShown = userData['friendReferralPopupShown'] == true;
    final inviteePopupData = userData['friendReferralPopup'];
    final referrerPopupShown = userData['friendReferralPopupReferrerShown'] == true;
    final referrerPopupData = userData['friendReferralPopupReferrer'];

    if (!inviteePopupShown && inviteePopupData is Map) {
      _showInviteeReferralPopup(userId, inviteePopupData);
      return;
    }
    if (!referrerPopupShown && referrerPopupData is Map) {
      _showReferrerReferralPopup(userId, referrerPopupData);
    }
  }

  void _showInviteeReferralPopup(String userId, Map<dynamic, dynamic> popupData) {
    final pointsRaw = popupData['points'];
    final referrerNameRaw = popupData['referrerName'];
    final points = pointsRaw is int
        ? pointsRaw
        : pointsRaw is num
            ? pointsRaw.toInt()
            : int.tryParse('$pointsRaw') ?? 0;
    final referrerName = (referrerNameRaw is String && referrerNameRaw.trim().isNotEmpty)
        ? referrerNameRaw.trim()
        : '友達';
    _referralPopupShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('友達紹介ポイント獲得'),
          content: Text('$referrerNameさんの友達コードで${points}ポイント付与されました'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'friendReferralPopupShown': true,
        'friendReferralPopup': FieldValue.delete(),
      });
    });
  }

  void _showReferrerReferralPopup(String userId, Map<dynamic, dynamic> popupData) {
    final pointsRaw = popupData['points'];
    final referredNameRaw = popupData['referredName'];
    final points = pointsRaw is int
        ? pointsRaw
        : pointsRaw is num
            ? pointsRaw.toInt()
            : int.tryParse('$pointsRaw') ?? 0;
    final referredName = (referredNameRaw is String && referredNameRaw.trim().isNotEmpty)
        ? referredNameRaw.trim()
        : '友達';
    _referralPopupShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('友達紹介ポイント獲得'),
          content: Text('$referredNameさんがあなたの友達コードで登録し${points}ポイント付与されました'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'friendReferralPopupReferrerShown': true,
        'friendReferralPopupReferrer': FieldValue.delete(),
      });
    });
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
        final bottomTabs = _bottomTabsFor(tabs);
        final showPlaceholder = tabs.contains(_MainTab.qr);
        final placeholderIndex = showPlaceholder ? _placeholderIndexFor(bottomTabs) : -1;
        final safeIndex = _coerceIndex(pages.length);

        if (safeIndex != _currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _setCurrentTab(safeIndex, tabs);
            });
          });
        }

        final currentTab = tabs[safeIndex];
        final bottomIndex = bottomTabs.isEmpty
            ? 0
            : currentTab == _MainTab.qr
                ? _visualIndexForBottomTabIndex(_safeBottomIndex(bottomTabs), placeholderIndex)
                : _visualIndexForBottomTabIndex(
                    bottomTabs.indexOf(currentTab).clamp(0, bottomTabs.length - 1),
                    placeholderIndex,
                  );

        if (user == null) {
          final items = _bottomNavItemsWithPlaceholder(
            bottomTabs,
            showPlaceholder,
          );
          return _buildBottomScaffold(
            tabs: tabs,
            pages: pages,
            pageIndex: safeIndex,
            bottomIndex: bottomIndex,
            items: items,
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('messages')
              .where('userId', isEqualTo: user.uid)
              .where('senderRole', isEqualTo: 'owner')
              .where('readByUserAt', isNull: true)
              .snapshots(),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.hasError
                ? 0
                : (unreadSnapshot.data?.docs.length ?? 0);
            final items = _bottomNavItemsWithPlaceholder(
              bottomTabs,
              showPlaceholder,
              profileBadgeCount: unreadCount,
            );
            return _buildBottomScaffold(
              tabs: tabs,
              pages: pages,
              pageIndex: safeIndex,
              bottomIndex: bottomIndex,
              items: items,
            );
          },
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

  Widget _buildBottomScaffold({
    required List<_MainTab> tabs,
    required List<Widget> pages,
    required int pageIndex,
    required int bottomIndex,
    required List<BottomNavigationBarItem> items,
  }) {
    return Scaffold(
      body: pages[pageIndex.clamp(0, pages.length - 1)],
      floatingActionButton: tabs.contains(_MainTab.qr)
          ? FloatingActionButton(
              onPressed: () => _onQrFabPressed(tabs),
              backgroundColor: const Color(0xFFFF6B35),
              shape: const CircleBorder(),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code, color: Colors.white, size: _fabIconSize),
                  SizedBox(height: 2),
                  Text(
                    'QRコード',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _fabLabelSize,
                      height: 1,
                    ),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButtonLocation: tabs.contains(_MainTab.qr)
          ? const _LoweredFabLocation(_fabVerticalOffset)
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: bottomIndex,
        onTap: (index) => _onBottomTabChanged(index, tabs),
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        backgroundColor: Colors.white,
        elevation: 8,
        items: items,
      ),
    );
  }

  Widget _buildProfileNavIcon(int badgeCount) {
    if (badgeCount <= 0) {
      return const Icon(Icons.person);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.person),
        Positioned(
          right: -4,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
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
