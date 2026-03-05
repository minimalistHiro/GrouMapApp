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
import '../providers/posts_provider.dart';
import '../services/push_notification_service.dart';
import '../services/mission_service.dart';
import 'home_view.dart';
import 'map/map_view.dart';
import 'qr/qr_generator_view.dart';
import 'profile/profile_view.dart';
import 'posts/posts_view.dart';
import 'payment/point_payment_detail_view.dart';
import 'stamps/daily_recommendation_view.dart';
import 'stamps/badge_awarded_view.dart';
import 'tutorial/tutorial_view.dart';
import '../providers/walkthrough_provider.dart';
import 'walkthrough/walkthrough_overlay.dart';
import 'walkthrough/walkthrough_step_config.dart';
import '../services/deep_link_service.dart';
import '../theme/app_ui.dart';
import 'checkin/nfc_coupon_select_view.dart';

class MainNavigationView extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationView({Key? key, this.initialIndex = 0}) : super(key: key);

  static Future<void> switchToPostsTab(BuildContext context) async {
    final state = context.findAncestorStateOfType<_MainNavigationViewState>();
    if (state == null) {
      return;
    }
    await state._switchToTab(_MainTab.coupons);
  }

  @override
  ConsumerState<MainNavigationView> createState() => _MainNavigationViewState();
}

class _LoweredFabLocation extends FloatingActionButtonLocation {
  final double offset;
  const _LoweredFabLocation(this.offset);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final baseOffset =
        FloatingActionButtonLocation.centerDocked.getOffset(scaffoldGeometry);
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
  ProviderSubscription<AsyncValue<Map<String, dynamic>?>>?
      _userDataSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _storesSub;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _storeRequestSubs = {};
  bool _isNavigatingToPointDetail = false;
  String? _lastHandledRequestId;
  bool _referralPopupShown = false;
  bool _dailyRecommendationShown = false;
  bool _didInitialLoad = false;
  String? _lastInitialUserId;
  bool _badgePopupShown = false;

  // static: ウィジェット再生成（ValueKey変更等）を跨いで保持
  // ポップアップ表示が完了済みかどうか
  static bool _dailyLoginProcessed = false;
  // 日次ログインの統計・ミッション処理が実行済みか
  static bool _dailyLoginRecorded = false;
  // 本日初ログインだったかのキャッシュ（ポップアップ表示判定用）
  static bool _wasFirstLoginToday = false;
  // 本日の包括バッジチェック完了済みかどうか
  static bool _dailyBadgeCheckDone = false;
  // セッション中に表示済みのバッジIDを記録（重複表示防止）
  static final Set<String> _shownBadgeIds = {};
  // チュートリアル表示済みかどうか（ユーザー単位で管理）
  static bool _tutorialShown = false;
  // ウォークスルー開始済みかどうか（ユーザー単位で管理）
  static bool _walkthroughStarted = false;
  // 前回のユーザーID（ユーザー切替検出用）
  static String? _lastUserId;

  // BottomNavigationBar全体のGlobalKey（タブ位置計算用）
  final GlobalKey _bottomNavKey = GlobalKey();

  // Deep Link (NFC チェックイン)
  final DeepLinkService _deepLinkService = DeepLinkService();
  bool _isProcessingCheckin = false;
  static const Duration _checkinDedupeWindow = Duration(seconds: 5);
  String? _activeCheckinKey;
  String? _lastHandledCheckinKey;
  DateTime? _lastHandledAt;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // 前インスタンスのゴースト状態をクリア
    // AuthWrapperが背後でMainNavigationViewを作成した場合に、
    // そのインスタンスが設定したwalkthrough状態が残るのを防ぐ
    // ValueKey('user:${user.uid}')により同一ユーザーのリビルドではinitStateが呼ばれないため安全
    final currentWalkthrough = ref.read(walkthroughProvider);
    if (currentWalkthrough.isActive) {
      ref.read(walkthroughProvider.notifier).resetState();
    }
    _tutorialShown = false;
    _walkthroughStarted = false;

    _authSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) {
        next.whenData((user) {
          _triggerInitialLoad(user);
          _userDataSubscription?.close();
          _stopPointRequestListener();
          if (user == null) {
            _lastUserId = null;
            return;
          }
          // ユーザーが変わったらチュートリアル・ウォークスルーのフラグをリセット
          if (_lastUserId != user.uid) {
            _tutorialShown = false;
            _walkthroughStarted = false;
          }
          _lastUserId = user.uid;
          _startPointRequestListener(user.uid);
          // 日次統計・ミッション処理（1日1回、lastLoginDateで判定）
          _recordDailyLoginIfNeeded(user.uid);
          _userDataSubscription =
              ref.listenManual<AsyncValue<Map<String, dynamic>?>>(
            userDataProvider(user.uid),
            (prev, data) {
              final userData = data.valueOrNull;
              if (userData == null) return;
              _maybeShowReferralPopup(user.uid, userData);
              _maybeShowDailyRecommendation(user.uid, userData);
            },
          );
        });
      },
      // authStateProviderが既にAsyncData(user)で安定している場合でも
      // コールバックを確実に発火させ、userDataSubscriptionを作成する
      fireImmediately: true,
    );
    // 初期データ読み込みをフレーム後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

      // 前のウィジェットでmounted=falseにより失敗したレコメンドポップアップをリトライ
      if (_wasFirstLoginToday && !_dailyLoginProcessed) {
        _retryPendingDailyRecommendation();
      }
    });
    // フォールバック: authリスナーが発火しなかった場合のウォークスルー起動保証
    // YamaGoパターン: addPostFrameCallbackで初期状態を明示的にチェック
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureWalkthroughIfNeeded();
    });
    // lastLoginAtを独立して更新（authリスナーチェーンに依存しない）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _updateLastLoginAt(currentUser.uid);
      }
    });
    // Deep Link リスナー（NFC チェックイン用）
    _initDeepLinkListener();
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

  // Deep Link リスナー初期化（NFC チェックイン用）
  void _initDeepLinkListener() {
    // コールドスタート時の初期リンクを処理
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final initialLink = await _deepLinkService.getInitialCheckinLink();
      if (initialLink != null) {
        _handleCheckinDeepLink(initialLink);
      }
    });
    // ウォームスタート時のリンクストリームを監視
    _deepLinkService.listenCheckinLinks((link) {
      if (!mounted) return;
      _handleCheckinDeepLink(link);
    });
  }

  // NFC チェックイン Deep Link を処理
  // → クーポン選択画面に遷移し、ユーザーがクーポンを選択後にチェックイン実行
  Future<void> _handleCheckinDeepLink(CheckinDeepLink link) async {
    final checkinKey = link.dedupeKey;
    final now = DateTime.now();

    // 同じチェックイン画面が既に開いている場合は重複遷移させない
    if (_activeCheckinKey == checkinKey) {
      debugPrint(
          'NFC checkin dedupe: active key is already open ($checkinKey)');
      return;
    }

    // 初期リンク + ストリームの連続受信を5秒間抑止
    if (_lastHandledCheckinKey == checkinKey &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) <= _checkinDedupeWindow) {
      debugPrint(
          'NFC checkin dedupe: ignored duplicate key within 5s ($checkinKey)');
      return;
    }

    if (_isProcessingCheckin) return;
    _isProcessingCheckin = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('チェックインにはログインが必要です'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;

      _activeCheckinKey = checkinKey;
      _lastHandledCheckinKey = checkinKey;
      _lastHandledAt = now;

      // クーポン選択画面へ遷移（チェックイン処理はこの画面内で実行される）
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => NfcCouponSelectView(
            storeId: link.storeId,
            tagSecret: link.tagSecret,
          ),
        ),
      )
          .whenComplete(() {
        if (!mounted) return;
        if (_activeCheckinKey == checkinKey) {
          _activeCheckinKey = null;
        }
      });
    } catch (e) {
      if (_activeCheckinKey == checkinKey) {
        _activeCheckinKey = null;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('チェックインの準備に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('NFC checkin deep link error: $e');
    } finally {
      _isProcessingCheckin = false;
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
    final placeholderIndex =
        showPlaceholder ? _placeholderIndexFor(bottomTabs) : -1;
    final bottomTabIndex =
        _bottomTabIndexForVisualIndex(bottomIndex, placeholderIndex);
    if (bottomTabIndex == null) {
      return;
    }
    final nextTab = bottomTabs[bottomTabIndex];

    // ウォークスルー中はステップに応じたタブのみ許可
    final wState = ref.read(walkthroughProvider);
    if (wState.isActive) {
      final allowed = _walkthroughAllowedTab(wState.step);
      if (allowed != null && nextTab != allowed) return;

      // ウォークスルーステップを進行
      if (wState.step == WalkthroughStep.tapMapTab && nextTab == _MainTab.map) {
        ref.read(walkthroughProvider.notifier).nextStep();
      } else if (wState.step == WalkthroughStep.tapHomeTab &&
          nextTab == _MainTab.home) {
        ref.read(walkthroughProvider.notifier).nextStep();
      }
    }

    final previousTab = tabs[_currentIndex];
    final nextIndex = tabs.indexOf(nextTab);
    setState(() {
      _setCurrentTab(nextIndex, tabs);
    });

    // ホームタブに切り替わった時はバッジポップアップフラグをリセット
    if (nextTab == _MainTab.home && previousTab != _MainTab.home) {
      _badgePopupShown = false;
      final authState = ref.read(authStateProvider);
      final user = authState.maybeWhen(data: (u) => u, orElse: () => null);
      if (user != null) {
        _checkBadgesOnHomeView(user.uid);
      }
    }

    // タブに応じて必要なデータを読み込み
    await _loadTabSpecificData(nextTab);
  }

  Future<void> _switchToTab(_MainTab tab) async {
    final authState = ref.read(authStateProvider);
    final user = authState.maybeWhen(data: (user) => user, orElse: () => null);
    final tabs = _tabsForUser(user);
    if (!tabs.contains(tab)) {
      return;
    }
    final previousTab = tabs[_currentIndex];
    final nextIndex = tabs.indexOf(tab);
    setState(() {
      _setCurrentTab(nextIndex, tabs);
    });

    await _loadTabSpecificData(tab);
  }

  // ウォークスルーステップに応じて許可するタブを返す（nullは制限なし）
  _MainTab? _walkthroughAllowedTab(WalkthroughStep step) {
    switch (step) {
      case WalkthroughStep.tapMapTab:
        return _MainTab.map;
      case WalkthroughStep.tapHomeTab:
        return _MainTab.home;
      case WalkthroughStep.tapMissionFab:
      case WalkthroughStep.tapCoinExchange:
        return _MainTab.home;
      default:
        return null;
    }
  }

  // BottomNavigationBar内のタブ位置をRectで計算
  Rect _calcTabRect(int tabVisualIndex, int totalVisualItems) {
    final renderBox =
        _bottomNavKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return Rect.zero;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final tabWidth = size.width / totalVisualItems;
    return Rect.fromLTWH(
      position.dx + tabWidth * tabVisualIndex,
      position.dy,
      tabWidth,
      size.height,
    );
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
            await _loadPostsData();
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

  Future<void> _loadPostsData() async {
    try {
      ref.invalidate(instagramSearchPostsProvider);
    } catch (e) {
      debugPrint('投稿データ読み込みエラー: $e');
    }
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
    return bottomTabIndex >= placeholderIndex
        ? bottomTabIndex + 1
        : bottomTabIndex;
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
    final placeholderIndex =
        showPlaceholder ? _placeholderIndexFor(bottomTabs) : -1;
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
          return const PostsView();
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
            label: '投稿',
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
    _deepLinkService.dispose();
    super.dispose();
  }

  void _startPointRequestListener(String userId) {
    _stopPointRequestListener();
    _storesSub = FirebaseFirestore.instance
        .collection('stores')
        .snapshots()
        .listen((storesSnap) {
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
          if (_isNavigatingToPointDetail ||
              _lastHandledRequestId == combinedRequestId) return;

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
    final referrerPopupShown =
        userData['friendReferralPopupReferrerShown'] == true;
    final referrerPopupData = userData['friendReferralPopupReferrer'];

    if (!inviteePopupShown && inviteePopupData is Map) {
      _showInviteeReferralPopup(userId, inviteePopupData);
      return;
    }
    if (!referrerPopupShown && referrerPopupData is Map) {
      _showReferrerReferralPopup(userId, referrerPopupData);
    }
  }

  /// lastLoginAtを画面を開くたびに確実に更新（.set merge: trueで無条件書き込み）
  /// fcmToken保存と同じ方式で、.get()不要・キャッシュの影響を受けない。
  Future<void> _updateLastLoginAt(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('lastLoginAt更新エラー: $e');
    }
  }

  /// 本日初ログイン時の統計・ミッション処理（daily_login_stats・デイリーミッション）
  /// lastLoginDate（yyyy-MM-dd文字列）で判定し、Timestampキャッシュ問題を回避。
  Future<void> _recordDailyLoginIfNeeded(String userId) async {
    if (_dailyLoginRecorded) return;
    // 同時呼び出し防止用（awaitの間に再入するケースを防ぐ）
    _dailyLoginRecorded = true;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = doc.data();
      if (userData == null) return;

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // lastLoginDate（yyyy-MM-dd文字列）で本日初回かを判定
      final lastLoginDate = userData['lastLoginDate'] as String?;
      if (lastLoginDate == todayStr) return;

      _wasFirstLoginToday = true;

      // daily_login_stats のインクリメント
      FirebaseFirestore.instance
          .collection('daily_login_stats')
          .doc(todayStr)
          .set({
        'loginCount': FieldValue.increment(1),
        'date': todayStr,
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('daily_login_stats更新エラー: $e');
      });

      // デイリーミッション: 新規登録ミッション完了済みの場合のみ実行
      final missionService = MissionService();
      final regComplete = await missionService.isRegistrationComplete(userId);
      if (regComplete) {
        missionService.markDailyMission(userId, 'app_open');
        missionService.updateLoginStreak(userId);
      }
    } catch (e) {
      debugPrint('日次ログイン記録エラー: $e');
      // 失敗時はフラグをリセットして次回リスナー発火時にリトライ可能にする
      _dailyLoginRecorded = false;
    }
  }

  /// フォールバック: authリスナー経由でuserDataSubscriptionが作成されなかった場合に
  /// 直接Firestoreからユーザーデータを取得してウォークスルー条件をチェックする。
  /// YamaGoパターン: リスナーに依存せず、addPostFrameCallbackで初期状態を明示チェック。
  Future<void> _ensureWalkthroughIfNeeded() async {
    // 既にウォークスルーが開始済み or userDataSubscriptionが作成済みなら不要
    if (_walkthroughStarted) return;
    if (_userDataSubscription != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint(
        '[Walkthrough] フォールバック: userDataSubscription未作成のためFirestoreを直接チェック');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final userData = doc.data();
      if (userData == null) return;

      // ウォークスルー条件チェック（_maybeShowDailyRecommendationのPath2と同等）
      if (!_walkthroughStarted &&
          userData['walkthroughCompleted'] != true &&
          userData['showTutorial'] != true) {
        _walkthroughStarted = true;
        debugPrint('[Walkthrough] フォールバック経由でウォークスルー開始');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(walkthroughProvider.notifier).startWalkthrough(user.uid);
          }
        });
      }

      // チュートリアル表示チェック（Path1と同等）
      if (!_tutorialShown && userData['showTutorial'] == true) {
        _tutorialShown = true;
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => TutorialView(userId: user.uid),
          ),
        );
        if (!mounted) return;
        if (!_walkthroughStarted) {
          _walkthroughStarted = true;
          debugPrint('[Walkthrough] フォールバック: チュートリアル完了後にウォークスルー開始');
          ref.read(walkthroughProvider.notifier).startWalkthrough(user.uid);
        }
      }
    } catch (e) {
      debugPrint('[Walkthrough] フォールバックエラー: $e');
    }
  }

  Future<void> _maybeShowDailyRecommendation(
      String userId, Map<String, dynamic> userData) async {
    debugPrint(
        '[Walkthrough] _maybeShowDailyRecommendation called: showTutorial=${userData['showTutorial']}, walkthroughCompleted=${userData['walkthroughCompleted']}, _tutorialShown=$_tutorialShown, _walkthroughStarted=$_walkthroughStarted');

    // このウィジェットのルートが最前面でなければチュートリアル/ウォークスルーを表示しない
    // AuthWrapperがオンボーディング完了前にMainNavigationViewを作成した場合の防御
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      debugPrint('[Walkthrough] ルートが最前面でないためチュートリアル/ウォークスルーをスキップ');
      return;
    }

    // チュートリアル: 新規ユーザーの初回のみ最優先で表示
    if (!_tutorialShown && userData['showTutorial'] == true) {
      _tutorialShown = true;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => TutorialView(userId: userId),
        ),
      );
      if (!mounted) return;

      // ウォークスルー開始（チュートリアル完了直後）
      if (!_walkthroughStarted) {
        _walkthroughStarted = true;
        debugPrint('[Walkthrough] ウォークスルー開始（チュートリアル完了後）');
        ref.read(walkthroughProvider.notifier).startWalkthrough(userId);
      }
    }

    // チュートリアル未表示でも、walkthroughCompleted==false ならウォークスルー開始
    if (!_walkthroughStarted &&
        userData['walkthroughCompleted'] != true &&
        userData['showTutorial'] != true) {
      _walkthroughStarted = true;
      debugPrint('[Walkthrough] ウォークスルー開始（Path2: walkthroughCompleted==false）');
      // BottomNavigationBar のレイアウト完了後にウォークスルーを開始
      // Chrome ではキャッシュデータが initState 中に同期的に返されるため、
      // 直接呼ぶと _calcTabRect() が Rect.zero を返す
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(walkthroughProvider.notifier).startWalkthrough(userId);
        }
      });
    }

    if (_dailyRecommendationShown) return;

    // 本日初ログインでなければバッジチェックのみ
    if (_dailyLoginRecorded && !_wasFirstLoginToday) {
      _checkBadgesOnHomeView(userId);
      return;
    }

    // まだ日次ログイン判定が完了していない場合はスキップ（次回のリスナー発火を待つ）
    if (!_dailyLoginRecorded) return;

    // ポップアップ表示済みなら終了（前のウィジェットで表示完了していた場合）
    if (_dailyLoginProcessed) {
      _checkBadgesOnHomeView(userId);
      return;
    }

    _dailyRecommendationShown = true;

    // 包括バッジチェックをバックグラウンドで開始
    Future<List<Map<String, dynamic>>>? badgeFuture;
    if (!_dailyBadgeCheckDone) {
      _dailyBadgeCheckDone = true;
      final badgeService = ref.read(badgeProvider);
      badgeFuture = badgeService.runComprehensiveBadgeCheck(userId);
    }

    // ホーム画面に一定期間いた後にポップアップを表示
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) {
      debugPrint('レコメンドポップアップ: mounted=false のため表示スキップ（新ウィジェットで再試行されます）');
      return;
    }

    // ポップアップ表示確定
    _dailyLoginProcessed = true;

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DailyRecommendationView(),
        ),
      );
    } catch (e) {
      debugPrint('レコメンドポップアップ表示エラー: $e');
    }

    // レコメンド閉じた後、バッジポップアップ表示
    if (badgeFuture != null) {
      await _showBadgePopupAfterDelay(userId, badgeFuture);
    } else {
      // 包括チェック済みの場合、軽量チェック
      await _showBadgePopupAfterDelay(userId, null);
    }
  }

  // 前のウィジェットでmounted=falseにより失敗したレコメンドポップアップのリトライ
  Future<void> _retryPendingDailyRecommendation() async {
    _dailyRecommendationShown = true;

    // 包括バッジチェックをバックグラウンドで開始
    final authState = ref.read(authStateProvider);
    final user = authState.maybeWhen(data: (u) => u, orElse: () => null);
    Future<List<Map<String, dynamic>>>? badgeFuture;
    if (user != null && !_dailyBadgeCheckDone) {
      _dailyBadgeCheckDone = true;
      final badgeService = ref.read(badgeProvider);
      badgeFuture = badgeService.runComprehensiveBadgeCheck(user.uid);
    }

    // ホーム画面が安定するまで待機
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _dailyLoginProcessed) return;

    _dailyLoginProcessed = true;

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DailyRecommendationView(),
        ),
      );
    } catch (e) {
      debugPrint('レコメンドポップアップ表示エラー（リトライ）: $e');
    }

    // レコメンド閉じた後、バッジポップアップ表示
    if (user != null) {
      await _showBadgePopupAfterDelay(user.uid, badgeFuture);
    }
  }

  // バッジポップアップ表示（レコメンド後 or 直接表示）
  Future<void> _showBadgePopupAfterDelay(String userId,
      Future<List<Map<String, dynamic>>>? comprehensiveFuture) async {
    if (_badgePopupShown) return;
    _badgePopupShown = true;

    // 包括チェック結果がある場合はそれを待つ、なければ軽量チェック
    List<Map<String, dynamic>> newBadges;
    if (comprehensiveFuture != null) {
      newBadges = await comprehensiveFuture;
    } else {
      final badgeService = ref.read(badgeProvider);
      newBadges = await badgeService.getNewBadges(userId);
    }

    // セッション内で表示済みのバッジを除外
    newBadges.removeWhere(
        (b) => _shownBadgeIds.contains(b['badgeId']?.toString() ?? ''));
    if (newBadges.isEmpty || !mounted) return;

    // 2秒待機
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 表示前にバッジIDを記録（重複表示防止）
    final badgeIds = newBadges
        .map((b) => (b['badgeId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    _shownBadgeIds.addAll(badgeIds);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BadgeAwardedView(
            badges: newBadges,
            sourceStoreId: null,
          ),
        ),
      );
    } catch (e) {
      debugPrint('バッジポップアップ表示エラー: $e');
    }

    // isNewフラグをクリア
    if (badgeIds.isNotEmpty) {
      final badgeService = ref.read(badgeProvider);
      await badgeService.markBadgesAsSeen(userId, badgeIds);
    }
  }

  // ホーム画面表示時の軽量バッジチェック（2回目以降のホーム表示用）
  Future<void> _checkBadgesOnHomeView(String userId) async {
    if (_badgePopupShown) return;
    _badgePopupShown = true;

    final badgeService = ref.read(badgeProvider);
    final newBadges = await badgeService.getNewBadges(userId);
    // セッション内で表示済みのバッジを除外
    newBadges.removeWhere(
        (b) => _shownBadgeIds.contains(b['badgeId']?.toString() ?? ''));
    if (newBadges.isEmpty || !mounted) return;

    // 2秒待機
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 表示前にバッジIDを記録（重複表示防止）
    final badgeIds = newBadges
        .map((b) => (b['badgeId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    _shownBadgeIds.addAll(badgeIds);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BadgeAwardedView(
            badges: newBadges,
            sourceStoreId: null,
          ),
        ),
      );
    } catch (e) {
      debugPrint('バッジポップアップ表示エラー: $e');
    }

    // isNewフラグをクリア
    if (badgeIds.isNotEmpty) {
      await badgeService.markBadgesAsSeen(userId, badgeIds);
    }
  }

  void _showInviteeReferralPopup(
      String userId, Map<dynamic, dynamic> popupData) {
    final pointsRaw = popupData['points'];
    final referrerNameRaw = popupData['referrerName'];
    final points = pointsRaw is int
        ? pointsRaw
        : pointsRaw is num
            ? pointsRaw.toInt()
            : int.tryParse('$pointsRaw') ?? 0;
    final referrerName =
        (referrerNameRaw is String && referrerNameRaw.trim().isNotEmpty)
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

  void _showReferrerReferralPopup(
      String userId, Map<dynamic, dynamic> popupData) {
    final pointsRaw = popupData['points'];
    final referredNameRaw = popupData['referredName'];
    final points = pointsRaw is int
        ? pointsRaw
        : pointsRaw is num
            ? pointsRaw.toInt()
            : int.tryParse('$pointsRaw') ?? 0;
    final referredName =
        (referredNameRaw is String && referredNameRaw.trim().isNotEmpty)
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
        final placeholderIndex =
            showPlaceholder ? _placeholderIndexFor(bottomTabs) : -1;
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
                ? _visualIndexForBottomTabIndex(
                    _safeBottomIndex(bottomTabs), placeholderIndex)
                : _visualIndexForBottomTabIndex(
                    bottomTabs
                        .indexOf(currentTab)
                        .clamp(0, bottomTabs.length - 1),
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
    final walkthroughState = ref.watch(walkthroughProvider);

    final scaffold = Scaffold(
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
        key: _bottomNavKey,
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

    // ウォークスルーステップ1・4のオーバーレイ
    final showTabOverlay = walkthroughState.isActive &&
        (walkthroughState.step == WalkthroughStep.tapMapTab ||
            walkthroughState.step == WalkthroughStep.tapHomeTab);

    if (!showTabOverlay) return scaffold;

    return Stack(
      children: [
        scaffold,
        _buildNavTabWalkthroughOverlay(walkthroughState, tabs, items.length),
      ],
    );
  }

  Widget _buildNavTabWalkthroughOverlay(
    WalkthroughState wState,
    List<_MainTab> tabs,
    int totalVisualItems,
  ) {
    final bottomTabs = _bottomTabsFor(tabs);
    final showPlaceholder = tabs.contains(_MainTab.qr);
    final placeholderIndex =
        showPlaceholder ? _placeholderIndexFor(bottomTabs) : -1;

    // ターゲットタブのビジュアルインデックスを計算
    final targetTab =
        wState.step == WalkthroughStep.tapMapTab ? _MainTab.map : _MainTab.home;
    final bottomTabIndex = bottomTabs.indexOf(targetTab);
    if (bottomTabIndex < 0) return const SizedBox.shrink();
    final visualIndex =
        _visualIndexForBottomTabIndex(bottomTabIndex, placeholderIndex);

    final config = walkthroughStepConfigs[wState.step];

    return LayoutBuilder(
      builder: (context, constraints) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final rect = _calcTabRect(visualIndex, totalVisualItems);
            // BottomNavigationBar 未レイアウト時は Rect.zero → null に変換
            final validRect = rect == Rect.zero ? null : rect;

            if (validRect == null) {
              // フレーム後に再計算をスケジュール（初回ビルド前に呼ばれた場合）
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setLocalState(() {});
              });
            }

            return WalkthroughOverlay(
              targetRect: validRect,
              message: config?.message ?? '',
              messagePosition:
                  config?.messagePosition ?? MessagePosition.center,
              allowTapThrough: true,
              onTargetTap: () {
                _onBottomTabChanged(visualIndex, tabs);
              },
              onSkip: () {
                ref.read(walkthroughProvider.notifier).skipWalkthrough();
              },
            );
          },
        );
      },
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
    return DateTime(
        date.year, date.month, date.day, parsed.hour, parsed.minute);
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
    return start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
  }

  Map<String, dynamic> _resolveCurrentSettings(
      Map<String, dynamic>? ownerSettings) {
    final rawCurrent = ownerSettings?['current'];
    if (rawCurrent is Map<String, dynamic>) {
      return rawCurrent;
    }
    return ownerSettings ?? <String, dynamic>{};
  }
}
