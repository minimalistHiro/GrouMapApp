import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/store_detail_view.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rarity_gradient.dart';
import '../../widgets/compact_toggle_bar.dart';
import '../../theme/app_ui.dart';
import '../../models/map_filter_model.dart';
import '../../services/map_filter_service.dart';
import 'filter_settings_view.dart';
import '../../services/mission_service.dart';
import '../../providers/badge_provider.dart';
import '../../providers/walkthrough_provider.dart';
import '../walkthrough/walkthrough_overlay.dart';
import '../walkthrough/walkthrough_step_config.dart';
import '../../widgets/game_dialog.dart';

class _MarkerVisual {
  final Color color;
  final IconData? iconData;
  final bool useImage;
  final Color? iconColor;

  const _MarkerVisual({
    required this.color,
    this.iconData,
    required this.useImage,
    this.iconColor,
  });
}

class MapView extends ConsumerStatefulWidget {
  final String? selectedStoreId;

  const MapView({
    super.key,
    this.selectedStoreId,
  });

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;
  LatLng _currentCenter = _defaultLocation;
  double _currentZoom = 15.0;
  double _currentBearing = 0.0;
  bool _didRestoreLastLocation = false;
  int _markerBuildToken = 0;
  final Map<String, Future<BitmapDescriptor>> _markerIconFutureCache = {};
  final Map<String, ui.Image> _markerImageCache = {};
  // Y軸スピンアニメーション用
  final Map<String, Uint8List> _markerBytesCache = {};
  final Map<String, String> _markerIdToCacheKey = {};
  final Map<String, BitmapDescriptor> _markerSpinIcons = {};
  final Map<String, Timer> _markerSpinTimers = {};

  // データベースから取得した店舗データ
  List<Map<String, dynamic>> _stores = [];

  // ユーザーのスタンプ状況
  Map<String, Map<String, dynamic>> _userStamps = {};

  // 拡大されたマーカーのID
  String _expandedMarkerId = '';

  // 店舗情報表示フラグ
  bool _isShowStoreInfo = false;
  String _selectedStoreUid = '';

  // ウォークスルー用GlobalKey
  final GlobalKey _closeBtnKey = GlobalKey();
  final GlobalKey _mapAreaKey = GlobalKey();

  // マップモード: 'normal' | 'personal' | 'community'
  String _mapMode = 'normal';
  bool _personalMapMode = false;
  bool _communityMapMode = false;
  String _communitySubMode = 'exploration'; // 'exploration' | 'activity'

  // 凡例カードの表示状態
  bool _isLegendVisible = true;

  // 詳細フィルター
  MapFilterModel _mapFilter = const MapFilterModel();
  List<String> _favoriteStoreIds = [];
  Map<String, List<Map<String, dynamic>>> _storeCoupons = {};
  bool _filterDataLoaded = false;

  // エリアオーバーレイ
  Set<Circle> _areaCircles = {};

  // 検索
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  // ゲームUIカラー定数
  static const Color _gameBackground = Color(0xE6101E2E);
  static const Color _gameBorder = Color(0xFF00E5FF);
  static const Color _gameOpenColor = Color(0xFF00E676);

  // ゲームマップスタイル（ダークブルー系）
  static const String _gameMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3a4a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2a4a6a"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9ec3b9"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#c4d8dd"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a3a52"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0d2a3a"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#7ea3b9"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e4a6e"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#0d2a3a"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#a0c8d8"}]},
  {"featureType":"transit","stylers":[{"visibility":"simplified"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#7ea3b9"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a2030"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]''';

  // レーダーアニメーション
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  // 選択リングアニメーション
  late AnimationController _selectionRingController;
  Offset? _selectedMarkerScreenPos;
  bool _showSelectionRing = false;

  // ピンアニメーション（ふわふわ）
  late AnimationController _pinFloatController;

  // プレイヤーHUD統計
  int _playerDiscoveredCount = 0;
  int _playerBadgeCount = 0;
  int _playerRank = 0;

  // デフォルトの座標（東京駅周辺）
  static const LatLng _defaultLocation = LatLng(35.6812, 139.7671);
  static const String _lastLocationLatKey = 'map_last_location_lat';
  static const String _lastLocationLngKey = 'map_last_location_lng';

  // 位置情報取得の試行回数
  int _locationRetryCount = 0;
  static const int _maxLocationRetries = 3;

  // 近接自動フォーカス
  StreamSubscription<Position>? _positionStreamSubscription;
  final Set<String> _proximityTriggeredStoreIds = {}; // 既にフォーカスを発火した店舗ID
  static const double _proximityRadiusMeters = 50.0; // 50m以内でフォーカス
  static const double _proximityResetRadiusMeters = 100.0; // 100m以上離れるとリセット

  @override
  void initState() {
    super.initState();
    _currentCenter = _defaultLocation;

    // レーダーアニメーション
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOut,
    );
    _radarController.addListener(() {
      if (mounted) setState(() {});
    });

    // 選択リングアニメーション
    _selectionRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _selectionRingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showSelectionRing = false);
      }
    });

    // ピンふわふわアニメーション（2.5秒周期で上下）
    _pinFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pinFloatController.addListener(() {
      if (mounted) setState(() {});
    });


    _loadLastLocationFromPrefs();
    _initializeMapData();
    _markMapMissions();
  }

  void _markMapMissions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    unawaited(_grantMapOpenReward(user.uid));
  }

  Future<void> _grantMapOpenReward(String userId) async {
    final missionService = MissionService();
    final shouldGrant =
        await missionService.acquireDailyActionRewardSlot(userId, 'map_open');
    if (!shouldGrant) return;

    await missionService.markRegistrationMission(userId, 'first_map');

    // バッジカウンター: マップ画面表示（1日1回）
    await BadgeService().incrementBadgeCounter(userId, 'mapOpened');
  }

  @override
  void dispose() {
    _radarController.dispose();
    _selectionRingController.dispose();
    _pinFloatController.dispose();
    for (final Timer t in _markerSpinTimers.values) {
      t.cancel();
    }
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLastLocationFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble(_lastLocationLatKey);
    final double? lng = prefs.getDouble(_lastLocationLngKey);
    if (lat == null || lng == null) return;
    if (!mounted) return;
    setState(() {
      final LatLng savedLocation = LatLng(lat, lng);
      _currentLocation = savedLocation;
      _currentCenter = savedLocation;
      _didRestoreLastLocation = true;
    });
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentCenter,
          zoom: _currentZoom,
          bearing: _currentBearing,
        ),
      ),
    );
  }

  Future<void> _saveLastLocationToPrefs(LatLng location) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastLocationLatKey, location.latitude);
    await prefs.setDouble(_lastLocationLngKey, location.longitude);
  }

  // 初期データ読み込み
  Future<void> _initializeMapData() async {
    // フィルター設定・お気に入り・エリアデータを並行読み込み
    await Future.wait([
      _loadFilterSettings(),
      _loadFavoriteStoreIds(),
      _loadAreas(),
    ]);

    // 店舗データを先に読み込む
    await _loadStoresFromDatabase();

    // 位置情報の取得を試行（失敗してもアプリは動作する）
    try {
      await _getCurrentLocation();
    } catch (e) {
      print('初期位置情報取得に失敗しましたが、アプリは継続します: $e');
    }

    // フィルターにクーポン条件がある場合、クーポンデータを読み込む
    if (_mapFilter.hasCoupon || _mapFilter.hasAvailableCoupon) {
      await _loadStoreCoupons();
    }

    // プレイヤー統計を読み込む
    unawaited(_loadPlayerStats());

    _filterDataLoaded = true;

    // 特定の店舗が選択されている場合、その店舗を選択状態にする
    if (widget.selectedStoreId != null) {
      await _selectStoreOnMap(widget.selectedStoreId!);
    }
  }

  // フィルター設定を読み込む
  Future<void> _loadFilterSettings() async {
    try {
      final filter = await MapFilterService.loadFilter();
      if (mounted) {
        setState(() {
          _mapFilter = filter;
        });
      }
    } catch (e) {
      print('フィルター設定の読み込みに失敗しました: $e');
    }
  }

  // お気に入り店舗IDを読み込む
  Future<void> _loadFavoriteStoreIds() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final favorites = (data['favoriteStoreIds'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        if (mounted) {
          setState(() {
            _favoriteStoreIds = favorites;
          });
        }
      }
    } catch (e) {
      print('お気に入り店舗の読み込みに失敗しました: $e');
    }
  }

  // エリア情報を読み込む
  Future<void> _loadAreas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('areas')
          .where('isActive', isEqualTo: true)
          .get();
      final areas = snapshot.docs.map((doc) {
        final data = doc.data();
        data['areaId'] = doc.id;
        return data;
      }).toList();
      if (mounted) {
        setState(() {
          _areaCircles = _buildAreaCircles(areas);
        });
      }
    } catch (e) {
      debugPrint('エリア情報の読み込みに失敗しました: $e');
    }
  }

  // エリアの Circle セットを生成する
  Set<Circle> _buildAreaCircles(List<Map<String, dynamic>> areas) {
    final circles = <Circle>{};
    for (final area in areas) {
      if (area['isActive'] != true) continue;
      final lat = area['center']?['latitude'] as double?;
      final lng = area['center']?['longitude'] as double?;
      if (lat == null || lng == null) continue;
      final radius = (area['radiusMeters'] as num?)?.toDouble() ?? 500.0;
      final colorHex = area['color'] as String?;
      final baseColor =
          _parseHexColor(colorHex, defaultColor: const Color(0xFFFF6B35));
      circles.add(Circle(
        circleId: CircleId(area['areaId'] as String),
        center: LatLng(lat, lng),
        radius: radius,
        fillColor: baseColor.withOpacity(0.15),
        strokeColor: baseColor.withOpacity(0.6),
        strokeWidth: 2,
      ));
    }
    return circles;
  }

  // 賑わい度のサークルオーバーレイを生成する
  Set<Circle> _buildActivityCircles() {
    final circles = <Circle>{};
    for (final store in _stores) {
      final totalVisitCount =
          (store['totalVisitCount'] as num?)?.toInt() ?? 0;
      if (totalVisitCount == 0) continue;

      final lat = store['location']?['latitude'] as double?;
      final lng = store['location']?['longitude'] as double?;
      if (lat == null || lng == null) continue;
      final storeId = store['id'] as String;

      Color fillColor;
      double radius;
      if (totalVisitCount <= 10) {
        fillColor = const Color(0x1A29B6F6);
        radius = 40;
      } else if (totalVisitCount <= 30) {
        fillColor = const Color(0x3366BB6A);
        radius = 60;
      } else if (totalVisitCount <= 100) {
        fillColor = const Color(0x4DFB8C00);
        radius = 80;
      } else {
        fillColor = const Color(0x66FFB300);
        radius = 100;
      }

      circles.add(Circle(
        circleId: CircleId('activity_$storeId'),
        center: LatLng(lat, lng),
        radius: radius,
        fillColor: fillColor,
        strokeWidth: 0,
      ));
    }
    return circles;
  }

  // アクティブなサークルセットを返す
  Set<Circle> _getActiveCircles() {
    Set<Circle> result = {};
    if (_communityMapMode) {
      if (_communitySubMode == 'exploration') {
        result = {..._areaCircles};
      } else {
        result = {..._buildActivityCircles()};
      }
    }
    result.addAll(_buildRadarCircles());
    return result;
  }

  Set<Circle> _buildRadarCircles() {
    if (_currentLocation == null) return {};
    final t = _radarAnimation.value;
    final circles = <Circle>{};
    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = 20.0 + phase * 180.0;
      final opacity = (1.0 - phase) * 0.5;
      circles.add(Circle(
        circleId: CircleId('radar_$i'),
        center: _currentLocation!,
        radius: radius,
        fillColor: _gameBorder.withOpacity(opacity * 0.3),
        strokeColor: _gameBorder.withOpacity(opacity),
        strokeWidth: 2,
      ));
    }
    return circles;
  }

  // マップモードを切り替えるメソッド（normal / personal / community）
  void _setMapMode(String mode) {
    setState(() {
      _mapMode = mode;
      _personalMapMode = mode == 'personal';
      _communityMapMode = mode == 'community';
      if (mode != 'community') {
        _communitySubMode = 'exploration'; // リセット
      }
      _isLegendVisible = true; // モード切り替え時に凡例を再表示
    });
    _markerIconFutureCache.clear();
    _createMarkers();
  }

  // hex 文字列を Color に変換するヘルパー
  Color _parseHexColor(String? hexColor, {required Color defaultColor}) {
    if (hexColor == null || hexColor.isEmpty) return defaultColor;
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return defaultColor;
  }

  // 店舗のクーポンデータを読み込む
  Future<void> _loadStoreCoupons() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('public_coupons')
          .where('isActive', isEqualTo: true)
          .get();
      final Map<String, List<Map<String, dynamic>>> coupons = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final storeId = data['storeId'] as String?;
        if (storeId == null) continue;
        // 有効期限チェック
        final validUntil = data['validUntil'];
        final noExpiry = data['noExpiry'] as bool? ?? false;
        if (!noExpiry && validUntil != null) {
          final DateTime expiry = (validUntil as Timestamp).toDate();
          if (expiry.isBefore(DateTime.now())) continue;
        }
        coupons.putIfAbsent(storeId, () => []);
        coupons[storeId]!.add(data);
      }
      if (mounted) {
        setState(() {
          _storeCoupons = coupons;
        });
      }
    } catch (e) {
      print('クーポンデータの読み込みに失敗しました: $e');
    }
  }

  // データベースから店舗を読み込む
  Future<void> _loadStoresFromDatabase() async {
    try {
      print('店舗データの読み込みを開始...');
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('isActive', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();
      print('取得したドキュメント数: ${snapshot.docs.length}');

      final List<Map<String, dynamic>> stores = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // isOwner店舗を除外（店舗ドキュメントのフラグで判定）
        final rawIsOwner = data['isOwner'];
        final isOwnerStore = rawIsOwner == true ||
            rawIsOwner?.toString().toLowerCase() == 'true';
        if (isOwnerStore) {
          print('isOwner=true のため除外: ${doc.id}');
          continue;
        }

        // 条件を緩和してテスト用の店舗も表示
        if (data['isActive'] == true && data['isApproved'] == true) {
          final rawLocation = data['location'];
          double? latitude;
          double? longitude;
          Map<String, dynamic>? normalizedLocation;
          if (rawLocation is GeoPoint) {
            latitude = rawLocation.latitude;
            longitude = rawLocation.longitude;
            normalizedLocation = {
              'latitude': latitude,
              'longitude': longitude,
            };
          } else if (rawLocation is Map) {
            final locationMap = Map<String, dynamic>.from(rawLocation);
            final latValue = locationMap['latitude'];
            final lngValue = locationMap['longitude'];
            if (latValue is num && lngValue is num) {
              latitude = latValue.toDouble();
              longitude = lngValue.toDouble();
              normalizedLocation = locationMap;
            }
          }

          final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
          final phoneNumber =
              (data['phoneNumber'] ?? data['phone'] ?? '').toString();
          final businessHours = data['businessHours'] is Map
              ? Map<String, dynamic>.from(data['businessHours'] as Map)
              : null;
          final scheduleOverrides = data['scheduleOverrides'] is Map
              ? Map<String, dynamic>.from(data['scheduleOverrides'] as Map)
              : null;
          final socialMedia = data['socialMedia'] is Map
              ? Map<String, dynamic>.from(data['socialMedia'] as Map)
              : <String, dynamic>{};
          final tags = data['tags'] is List
              ? (data['tags'] as List).map((tag) => tag.toString()).toList()
              : <String>[];

          // 位置情報がある場合のみ追加
          if (latitude != null && longitude != null) {
            final storeData = {
              'id': doc.id,
              'name': data['name'] ?? '店舗名なし',
              'position': LatLng(
                latitude,
                longitude,
              ),
              'category': data['category'] ?? 'その他',
              'subCategory': data['subCategory'] ?? '',
              'description': data['description'] ?? '',
              'address': data['address'] ?? '',
              'iconImageUrl': data['iconImageUrl'],
              'storeImageUrl': data['storeImageUrl'], // 店舗詳細画面で使用
              'backgroundImageUrl': data['backgroundImageUrl'], // 店舗一覧画面で使用
              'phoneNumber': phoneNumber,
              'phone': phone, // store_detail_view.dartで使用
              'businessHours': businessHours,
              'scheduleOverrides': scheduleOverrides,
              'isRegularHoliday': data['isRegularHoliday'] ?? false,
              'location': normalizedLocation, // 位置情報
              'socialMedia': socialMedia,
              'tags': tags,
              'paymentMethods': data['paymentMethods'],
              'facilityInfo': data['facilityInfo'],
              'isActive': data['isActive'] ?? false,
              'isApproved': data['isApproved'] ?? false,
              'createdAt': data['createdAt'],
              'updatedAt': data['updatedAt'],
              'isVisited': false,
              'flowerType': 'unvisited',
              'areaId': data['areaId'], // エリアID（null = 秘境スポット）
              'discoveredCount': data['discoveredCount'],
              'rarityOverride': data['rarityOverride'],
            };
            stores.add(storeData);
            print('店舗を追加: ${storeData['name']} at ${storeData['position']}');
          } else {
            print('位置情報なし: ${doc.id}');
          }
        } else {
          print('条件に合わない: ${doc.id}');
        }
      }

      print('読み込んだ店舗数: ${stores.length}');

      // テスト用のサンプル店舗を追加（データベースに店舗がない場合）
      if (stores.isEmpty) {
        print('データベースに店舗がないため、テスト用のサンプル店舗を追加します');
        stores.addAll([
          {
            'id': 'sample_store_1',
            'name': 'サンプル店舗1',
            'position': const LatLng(35.6812, 139.7671), // 東京駅
            'category': 'レストラン',
            'subCategory': '',
            'description': 'テスト用のサンプル店舗です',
            'address': '東京都千代田区丸の内1-1-1',
            'iconImageUrl': null,
            'storeImageUrl': null,
            'backgroundImageUrl': null,
            'phoneNumber': '03-1234-5678',
            'phone': '03-1234-5678',
            'businessHours': {
              'monday': {'isOpen': true, 'open': '09:00', 'close': '21:00'},
              'tuesday': {'isOpen': true, 'open': '09:00', 'close': '21:00'},
              'wednesday': {'isOpen': true, 'open': '09:00', 'close': '21:00'},
              'thursday': {'isOpen': true, 'open': '09:00', 'close': '21:00'},
              'friday': {'isOpen': true, 'open': '09:00', 'close': '21:00'},
              'saturday': {'isOpen': true, 'open': '10:00', 'close': '20:00'},
              'sunday': {'isOpen': false, 'open': '', 'close': ''},
            },
            'location': {
              'latitude': 35.6812,
              'longitude': 139.7671,
            },
            'socialMedia': {},
            'tags': ['人気', 'おすすめ'],
            'isActive': true,
            'isApproved': true,
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
            'isVisited': false,
            'flowerType': 'unvisited',
          },
          {
            'id': 'sample_store_2',
            'name': 'サンプル店舗2',
            'position': const LatLng(35.6762, 139.6503), // 渋谷駅
            'category': 'カフェ',
            'subCategory': '',
            'description': 'テスト用のサンプル店舗です',
            'address': '東京都渋谷区道玄坂1-1-1',
            'iconImageUrl': null,
            'storeImageUrl': null,
            'backgroundImageUrl': null,
            'phoneNumber': '03-2345-6789',
            'phone': '03-2345-6789',
            'businessHours': {
              'monday': {'isOpen': true, 'open': '08:00', 'close': '22:00'},
              'tuesday': {'isOpen': true, 'open': '08:00', 'close': '22:00'},
              'wednesday': {'isOpen': true, 'open': '08:00', 'close': '22:00'},
              'thursday': {'isOpen': true, 'open': '08:00', 'close': '22:00'},
              'friday': {'isOpen': true, 'open': '08:00', 'close': '22:00'},
              'saturday': {'isOpen': true, 'open': '09:00', 'close': '21:00'},
              'sunday': {'isOpen': true, 'open': '09:00', 'close': '21:00'},
            },
            'location': {
              'latitude': 35.6762,
              'longitude': 139.6503,
            },
            'socialMedia': {},
            'tags': ['コーヒー', '落ち着く'],
            'isActive': true,
            'isApproved': true,
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
            'isVisited': false,
            'flowerType': 'unvisited',
          },
          {
            'id': 'sample_store_3',
            'name': 'サンプル店舗3',
            'position': const LatLng(35.6581, 139.7016), // 新宿駅
            'category': 'ショップ',
            'subCategory': '',
            'description': 'テスト用のサンプル店舗です',
            'address': '東京都新宿区新宿3-1-1',
            'iconImageUrl': null,
            'storeImageUrl': null,
            'backgroundImageUrl': null,
            'phoneNumber': '03-3456-7890',
            'phone': '03-3456-7890',
            'businessHours': {
              'monday': {'isOpen': true, 'open': '10:00', 'close': '20:00'},
              'tuesday': {'isOpen': true, 'open': '10:00', 'close': '20:00'},
              'wednesday': {'isOpen': true, 'open': '10:00', 'close': '20:00'},
              'thursday': {'isOpen': true, 'open': '10:00', 'close': '20:00'},
              'friday': {'isOpen': true, 'open': '10:00', 'close': '20:00'},
              'saturday': {'isOpen': true, 'open': '10:00', 'close': '19:00'},
              'sunday': {'isOpen': false, 'open': '', 'close': ''},
            },
            'location': {
              'latitude': 35.6581,
              'longitude': 139.7016,
            },
            'socialMedia': {},
            'tags': ['ファッション', 'トレンド'],
            'isActive': true,
            'isApproved': true,
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
            'isVisited': false,
            'flowerType': 'unvisited',
          },
        ]);
        print('サンプル店舗を追加しました。総数: ${stores.length}');
      }

      if (mounted) {
        setState(() {
          _stores = stores;
        });
      }

      // 店舗データ読み込み後にユーザーのスタンプ状況を読み込む
      await _loadUserStamps();
      await _createMarkers();
    } catch (e) {
      print('店舗データの読み込みに失敗しました: $e');
    }
  }

  // ユーザーのスタンプ状況を読み込む
  Future<void> _loadUserStamps() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 新しいデータ構造: users/{userId}/stores/{storeId}
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .get();

      final Map<String, Map<String, dynamic>> userStamps = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final storeId = doc.id; // ドキュメントIDがstoreId
        userStamps[storeId] = {
          'stamps': data['stamps'] ?? 0,
          'lastVisited': data['lastVisited'],
          'totalSpending': data['totalSpending'] ?? 0.0,
        };
      }

      if (mounted) {
        setState(() {
          _userStamps = userStamps;
        });
      }

      // 店舗の花アイコンの種類を更新
      _updateStoreFlowerTypes();
    } catch (e) {
      print('ユーザースタンプデータの読み込みに失敗しました: $e');
    }
  }

  // 店舗の花アイコンの種類を更新
  void _updateStoreFlowerTypes() {
    for (int i = 0; i < _stores.length; i++) {
      final storeId = _stores[i]['id'];
      final userStamp = _userStamps[storeId];

      if (userStamp != null) {
        final stamps = userStamp['stamps'] ?? 0; // 新しい構造に合わせて'stamps'フィールドを使用

        if (stamps == 0) {
          _stores[i]['flowerType'] = 'unvisited'; // 未開拓
          _stores[i]['isVisited'] = false;
        } else if (stamps >= 1 && stamps <= 9) {
          _stores[i]['flowerType'] = 'visited'; // 開拓中
          _stores[i]['isVisited'] = true;
        } else if (stamps >= 10) {
          _stores[i]['flowerType'] = 'regular'; // 常連
          _stores[i]['isVisited'] = true;
        } else {
          _stores[i]['flowerType'] = 'unvisited';
          _stores[i]['isVisited'] = false;
        }
      } else {
        _stores[i]['flowerType'] = 'unvisited';
        _stores[i]['isVisited'] = false;
      }
    }
  }

  // 現在地を取得
  Future<void> _getCurrentLocation() async {
    try {
      // 位置情報サービスが有効かチェック
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('位置情報サービスが無効です');
        if (_locationRetryCount < _maxLocationRetries) {
          _locationRetryCount++;
          print(
              '位置情報サービスが無効です。リトライします ($_locationRetryCount/$_maxLocationRetries)');
          await Future.delayed(const Duration(seconds: 2));
          return _getCurrentLocation();
        } else {
          _showLocationErrorDialog('位置情報サービスが無効です。設定から位置情報を有効にしてください。');
          return;
        }
      }

      // 位置情報の権限を確認
      LocationPermission permission = await Geolocator.checkPermission();
      print('現在の位置情報権限: $permission');

      if (permission == LocationPermission.denied) {
        print('位置情報権限が拒否されています。権限を要求します。');
        permission = await Geolocator.requestPermission();
        print('権限要求後の状態: $permission');

        if (permission == LocationPermission.denied) {
          print('位置情報権限が拒否されました');
          if (_locationRetryCount < _maxLocationRetries) {
            _locationRetryCount++;
            print(
                '位置情報権限が拒否されました。リトライします ($_locationRetryCount/$_maxLocationRetries)');
            await Future.delayed(const Duration(seconds: 2));
            return _getCurrentLocation();
          } else {
            _showLocationErrorDialog('位置情報の権限が必要です。設定から位置情報の権限を許可してください。');
            return;
          }
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('位置情報権限が永続的に拒否されています');
        _showLocationErrorDialog('位置情報の権限が永続的に拒否されています。設定アプリから手動で権限を許可してください。');
        return;
      }

      print('位置情報権限が許可されました。現在地を取得します。');

      // 現在地を取得（タイムアウトを設定）
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('現在地を取得しました: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        final LatLng latestLocation =
            LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = latestLocation;
          _locationRetryCount = 0; // 成功したらリトライカウントをリセット
        });
        await _saveLastLocationToPrefs(latestLocation);

        // 地図を現在地に移動
        _currentCenter = latestLocation;
        _currentZoom = 15.0;
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentCenter,
              zoom: _currentZoom,
              bearing: _currentBearing,
            ),
          ),
        );
        print('地図を現在地に移動しました');

        // 位置ストリームがまだ開始されていなければ開始
        _startProximityMonitoring();
      }
    } catch (e) {
      print('現在地の取得に失敗しました: $e');
      if (_locationRetryCount < _maxLocationRetries) {
        _locationRetryCount++;
        print(
            '現在地取得に失敗しました。リトライします ($_locationRetryCount/$_maxLocationRetries)');
        await Future.delayed(const Duration(seconds: 2));
        return _getCurrentLocation();
      } else {
        _showLocationErrorDialog('現在地の取得に失敗しました。位置情報の設定を確認してください。');
      }
    }
  }

  // 近接監視ストリームを開始
  void _startProximityMonitoring() {
    if (_positionStreamSubscription != null) return; // 既に開始済み

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 5m移動ごとに更新
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (!mounted) return;
      final LatLng userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = userLatLng;
      });
      _checkProximityToStores(userLatLng);
    });
  }

  // ユーザーの現在地と各店舗の距離をチェックし、50m以内ならフォーカスを当てる
  void _checkProximityToStores(LatLng userLatLng) {
    // リセット処理: 100m以上離れた店舗は triggered セットから除外
    _proximityTriggeredStoreIds.removeWhere((storeId) {
      final store = _stores.firstWhere(
        (s) => s['id'] == storeId,
        orElse: () => {},
      );
      if (store.isEmpty) return true;
      final LatLng storePos = store['position'] as LatLng;
      final double distance = Geolocator.distanceBetween(
        userLatLng.latitude,
        userLatLng.longitude,
        storePos.latitude,
        storePos.longitude,
      );
      return distance > _proximityResetRadiusMeters;
    });

    // 近接チェック: 50m以内でまだ発火していない店舗を探す
    for (final store in _stores) {
      final String storeId = store['id'] as String;
      if (_proximityTriggeredStoreIds.contains(storeId)) continue;

      final LatLng storePos = store['position'] as LatLng;
      final double distance = Geolocator.distanceBetween(
        userLatLng.latitude,
        userLatLng.longitude,
        storePos.latitude,
        storePos.longitude,
      );

      if (distance <= _proximityRadiusMeters) {
        _proximityTriggeredStoreIds.add(storeId);
        _onProximityFocus(storeId);
        break; // 一度に1店舗だけフォーカス
      }
    }
  }

  // 近接フォーカスの実行（ピンタップと同じ挙動 + バイブレーション）
  Future<void> _onProximityFocus(String storeId) async {
    if (!mounted) return;
    // すでにこの店舗が選択中なら何もしない
    if (_expandedMarkerId == storeId) return;

    // 軽くバイブレーション
    HapticFeedback.mediumImpact();

    setState(() {
      _expandedMarkerId = storeId;
      _isShowStoreInfo = true;
      _selectedStoreUid = storeId;
    });

    // 地図をその店舗の位置に移動
    final store = _stores.firstWhere(
      (s) => s['id'] == storeId,
      orElse: () => {},
    );
    if (store.isNotEmpty) {
      final LatLng storePos = store['position'] as LatLng;
      _currentCenter = storePos;
      _currentZoom = 16.0;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentCenter,
            zoom: _currentZoom,
            bearing: _currentBearing,
          ),
        ),
      );
    }

    await _createMarkers();
  }

  // 位置情報エラーダイアログを表示
  void _showLocationErrorDialog(String message) {
    if (!mounted) return;

    final bool needsSettings = message.contains('永続的に拒否');

    showGameDialog(
      context: context,
      title: '位置情報エラー',
      message: message,
      icon: Icons.location_off_rounded,
      actions: [
        if (needsSettings)
          GameDialogAction(
            label: '設定を開く',
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            isPrimary: true,
          ),
        GameDialogAction(
          label: 'OK',
          onPressed: () => Navigator.of(context).pop(),
          isPrimary: !needsSettings,
        ),
      ],
    );
  }

  // スタンプ状況に応じた色を取得
  Color _getDefaultStoreColor(String category) {
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

  IconData _getDefaultStoreIcon(String category) {
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

  // 個人マップの5段階ステータス判定
  String _getPersonalMapStatus(int totalVisits) {
    if (totalVisits == 0) return 'undiscovered';
    if (totalVisits == 1) return 'discovered';
    if (totalVisits <= 4) return 'exploring';
    if (totalVisits <= 9) return 'regular';
    return 'legend';
  }

  Color _getPersonalMapColor(String status) {
    switch (status) {
      case 'undiscovered':
        return const Color(0xFFBDBDBD);
      case 'discovered':
        return const Color(0xFF29B6F6);
      case 'exploring':
        return const Color(0xFF66BB6A);
      case 'regular':
        return const Color(0xFFFB8C00);
      case 'legend':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  IconData _getPersonalMapIcon(String status) {
    switch (status) {
      case 'undiscovered':
        return Icons.radio_button_unchecked;
      case 'discovered':
        return Icons.explore;
      case 'exploring':
        return Icons.directions_walk;
      case 'regular':
        return Icons.radio_button_checked;
      case 'legend':
        return Icons.star;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  _MarkerVisual _resolveMarkerVisual({
    required String flowerType,
    required String category,
    required String storeIconUrl,
    String storeId = '',
  }) {
    // 個人マップモード（最優先）: 常に店舗アイコン画像を表示
    if (_personalMapMode) {
      final bool canUseImage = storeIconUrl.isNotEmpty;
      return _MarkerVisual(
        color: Colors.white,
        iconData: canUseImage ? null : _getDefaultStoreIcon(category),
        useImage: canUseImage,
        iconColor: canUseImage ? null : const Color(0xFF9E9E9E),
      );
    }

    if (_mapFilter.pioneerMode) {
      switch (flowerType) {
        case 'unvisited':
          return const _MarkerVisual(
            color: Colors.white,
            iconData: Icons.radio_button_unchecked,
            useImage: false,
            iconColor: Color(0xFFBDBDBD),
          );
        case 'visited':
          return const _MarkerVisual(
            color: Colors.white,
            iconData: Icons.radio_button_checked,
            useImage: false,
            iconColor: Color(0xFFFB8C00),
          );
        case 'regular':
          return const _MarkerVisual(
            color: Colors.white,
            iconData: Icons.star,
            useImage: false,
            iconColor: Color(0xFFFFB300),
          );
        default:
          return const _MarkerVisual(
            color: Colors.white,
            iconData: Icons.help_outline,
            useImage: false,
            iconColor: Color(0xFFBDBDBD),
          );
      }
    }

    if (_mapFilter.categoryMode) {
      final Color baseColor = _getDefaultStoreColor(category);
      return _MarkerVisual(
        color: Colors.white,
        iconData: _getDefaultStoreIcon(category),
        useImage: false,
        iconColor: baseColor,
      );
    }

    final bool canUseImage = storeIconUrl.isNotEmpty;
    return _MarkerVisual(
      color: Colors.white,
      iconData: _getDefaultStoreIcon(category),
      useImage: canUseImage,
      iconColor: canUseImage ? null : _getDefaultStoreColor(category),
    );
  }

  Future<BitmapDescriptor> _getMarkerIcon({
    required String cacheKey,
    required double size,
    required Color fillColor,
    required Color borderColor,
    required double borderWidth,
    required IconData? iconData,
    required Color? iconColor,
    required String storeIconUrl,
    Color pinAccentColor = const Color(0xFFFF6B35),
    bool isLegend = false,
    bool isGrayPin = false,
    bool isGreenPin = false,
  }) {
    final cachedFuture = _markerIconFutureCache[cacheKey];
    if (cachedFuture != null) {
      return cachedFuture;
    }

    final completer = Completer<BitmapDescriptor>();
    _markerIconFutureCache[cacheKey] = completer.future;

    () async {
      try {
        final ui.Image? image = storeIconUrl.isNotEmpty
            ? await _loadMarkerImage(storeIconUrl)
            : null;
        final (BitmapDescriptor icon, Uint8List bytes) = await _buildMarkerBitmap(
          size: size,
          fillColor: fillColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          iconData: image == null ? iconData : null,
          iconColor: iconColor,
          image: image,
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
          pinAccentColor: pinAccentColor,
          isLegend: isLegend,
          isGrayPin: isGrayPin,
          isGreenPin: isGreenPin,
        );
        _markerBytesCache[cacheKey] = bytes;
        completer.complete(icon);
      } catch (_) {
        _markerIconFutureCache.remove(cacheKey);
        completer.complete(BitmapDescriptor.defaultMarker);
      }
    }();

    return completer.future;
  }

  Future<ui.Image?> _loadMarkerImage(String url) async {
    final cached = _markerImageCache[url];
    if (cached != null) {
      return cached;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }
      final Uint8List bytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      _markerImageCache[url] = frameInfo.image;
      return frameInfo.image;
    } catch (_) {
      return null;
    }
  }

  Future<(BitmapDescriptor, Uint8List)> _buildMarkerBitmap({
    required double size,
    required Color fillColor,
    required Color borderColor,
    required double borderWidth,
    required IconData? iconData,
    required Color? iconColor,
    required ui.Image? image,
    required double devicePixelRatio,
    Color pinAccentColor = const Color(0xFFFF6B35),
    bool isLegend = false,
    bool isGrayPin = false,
    bool isGreenPin = false,
  }) async {
    const double pinHeightScale = 1.4;
    final double scaledSize = size * devicePixelRatio;
    final double scaledHeight = scaledSize * pinHeightScale;
    final double circleBorderWidth = borderWidth * devicePixelRatio * 2.4;
    final double triangleBorderWidth = borderWidth * devicePixelRatio;
    double inset = circleBorderWidth / 2;
    final double minInset = 2 * devicePixelRatio;
    if (inset < minInset) {
      inset = minInset;
    }
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double radius = (scaledSize / 2) - inset;
    final Offset circleCenter = Offset(scaledSize / 2, inset + radius);

    final Path circlePath = Path()
      ..addOval(Rect.fromCircle(center: circleCenter, radius: radius));
    final double baseY = circleCenter.dy + radius * 0.45;
    final double baseHalfWidth = radius * 0.95;
    final Offset tip = Offset(circleCenter.dx, scaledHeight);
    final Offset leftBase = Offset(circleCenter.dx - baseHalfWidth, baseY);
    final Offset rightBase = Offset(circleCenter.dx + baseHalfWidth, baseY);
    final Offset triCenter =
        Offset(circleCenter.dx, (scaledHeight + baseY) / 2);
    final Path trianglePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..quadraticBezierTo(
        triCenter.dx - baseHalfWidth * 0.25,
        triCenter.dy,
        leftBase.dx,
        leftBase.dy,
      )
      ..quadraticBezierTo(
        triCenter.dx,
        triCenter.dy + radius * 0.15,
        rightBase.dx,
        rightBase.dy,
      )
      ..quadraticBezierTo(
        triCenter.dx + baseHalfWidth * 0.25,
        triCenter.dy,
        tip.dx,
        tip.dy,
      )
      ..close();
    final Path pinPath = Path()
      ..addPath(circlePath, Offset.zero)
      ..addPath(trianglePath, Offset.zero);
    canvas.drawShadow(
        pinPath, Colors.black.withOpacity(0.25), 4 * devicePixelRatio, true);

    // legendのときはゴールドグラデーションを使用
    if (isLegend) {
      final Rect gradientRect = Rect.fromLTWH(
        0,
        circleCenter.dy - radius,
        scaledSize,
        scaledHeight - (circleCenter.dy - radius),
      );
      final ui.Gradient goldGradient = RarityGradient.canvasFillGradient(
        4,
        Offset(scaledSize / 2, circleCenter.dy - radius),
        Offset(scaledSize / 2, scaledHeight),
      );
      final Paint legendTrianglePaint = Paint()
        ..shader = goldGradient;
      canvas.drawPath(trianglePath, legendTrianglePaint);

      // Draw the circle last so it fully covers the triangle overlap.
      final Paint circleFillPaint = Paint()
        ..shader = RarityGradient.canvasFillGradient(
          4,
          Offset(scaledSize / 2, circleCenter.dy - radius),
          Offset(scaledSize / 2, circleCenter.dy + radius),
        );
      canvas.drawPath(circlePath, circleFillPaint);

      if (image != null) {
        canvas.save();
        canvas.clipPath(circlePath);
        final Rect dstRect = Rect.fromLTWH(
          circleCenter.dx - radius,
          circleCenter.dy - radius,
          radius * 2,
          radius * 2,
        );
        final Rect srcRect = Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());
        canvas.drawImageRect(image, srcRect, dstRect, Paint());
        canvas.restore();
      }

      if (borderWidth > 0) {
        final Paint legendCircleBorderPaint = Paint()
          ..shader = gradientRect.isEmpty
              ? null
              : RarityGradient.canvasBorderGradient(
                  4,
                  Offset(scaledSize / 2, circleCenter.dy - radius),
                  Offset(scaledSize / 2, circleCenter.dy + radius),
                )
          ..style = PaintingStyle.stroke
          ..strokeWidth = circleBorderWidth;
        canvas.drawPath(circlePath, legendCircleBorderPaint);
      }
    } else {
      if (isGrayPin) {
        // グレーピン: 上から下へ明→暗のグラデーション
        final Rect grayGradientRect = Rect.fromLTWH(
          0,
          circleCenter.dy - radius,
          scaledSize,
          scaledHeight - (circleCenter.dy - radius),
        );
        final ui.Gradient grayGradient = RarityGradient.canvasFillGradient(
          1,
          Offset(scaledSize / 2, circleCenter.dy - radius),
          Offset(scaledSize / 2, scaledHeight),
        );
        final Paint triangleFillPaint = Paint()..shader = grayGradient;
        canvas.drawPath(trianglePath, triangleFillPaint);
        if (borderWidth > 0) {
          final Paint triangleBorderPaint = Paint()
            ..shader = grayGradient
            ..style = PaintingStyle.stroke
            ..strokeWidth = triangleBorderWidth;
          canvas.drawPath(trianglePath, triangleBorderPaint);
        }

        // Draw the circle last so it fully covers the triangle overlap.
        final Paint circleFillPaint = Paint()
          ..shader = RarityGradient.canvasFillGradient(
            1,
            Offset(scaledSize / 2, circleCenter.dy - radius),
            Offset(scaledSize / 2, circleCenter.dy + radius),
          );
        canvas.drawPath(circlePath, circleFillPaint);

        if (image != null) {
          canvas.save();
          canvas.clipPath(circlePath);
          final Rect dstRect = Rect.fromLTWH(
            circleCenter.dx - radius,
            circleCenter.dy - radius,
            radius * 2,
            radius * 2,
          );
          final Rect srcRect = Rect.fromLTWH(
              0, 0, image.width.toDouble(), image.height.toDouble());
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
          canvas.restore();
        }

        if (borderWidth > 0) {
          final ui.Gradient circleBorderGradient =
              RarityGradient.canvasBorderGradient(
            1,
            Offset(scaledSize / 2, circleCenter.dy - radius),
            Offset(scaledSize / 2, circleCenter.dy + radius),
          );
          final Paint circleBorderPaint = Paint()
            ..shader = grayGradientRect.isEmpty ? null : circleBorderGradient
            ..style = PaintingStyle.stroke
            ..strokeWidth = circleBorderWidth;
          canvas.drawPath(circlePath, circleBorderPaint);
        }
      } else if (isGreenPin) {
        // 緑ピン: RarityGradient.canvasGreenFillGradient を使用
        final ui.Gradient greenGradient = RarityGradient.canvasGreenFillGradient(
          Offset(scaledSize / 2, circleCenter.dy - radius),
          Offset(scaledSize / 2, scaledHeight),
        );
        final Paint triangleFillPaint = Paint()..shader = greenGradient;
        canvas.drawPath(trianglePath, triangleFillPaint);
        if (borderWidth > 0) {
          final Paint triangleBorderPaint = Paint()
            ..shader = greenGradient
            ..style = PaintingStyle.stroke
            ..strokeWidth = triangleBorderWidth;
          canvas.drawPath(trianglePath, triangleBorderPaint);
        }

        // Draw the circle last so it fully covers the triangle overlap.
        final Paint circleFillPaint = Paint()
          ..shader = RarityGradient.canvasGreenFillGradient(
            Offset(scaledSize / 2, circleCenter.dy - radius),
            Offset(scaledSize / 2, circleCenter.dy + radius),
          );
        canvas.drawPath(circlePath, circleFillPaint);

        if (image != null) {
          canvas.save();
          canvas.clipPath(circlePath);
          final Rect dstRect = Rect.fromLTWH(
            circleCenter.dx - radius,
            circleCenter.dy - radius,
            radius * 2,
            radius * 2,
          );
          final Rect srcRect = Rect.fromLTWH(
              0, 0, image.width.toDouble(), image.height.toDouble());
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
          canvas.restore();
        }

        if (borderWidth > 0) {
          final Paint circleBorderPaint = Paint()
            ..shader = RarityGradient.canvasGreenFillGradient(
              Offset(scaledSize / 2, circleCenter.dy - radius),
              Offset(scaledSize / 2, circleCenter.dy + radius),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = circleBorderWidth;
          canvas.drawPath(circlePath, circleBorderPaint);
        }
      } else {
        // 通常ピン: RarityGradient.canvasColorFillGradient を使用
        final ui.Gradient accentFillGradient = RarityGradient.canvasColorBorderGradient(
          pinAccentColor,
          Offset(scaledSize / 2, circleCenter.dy - radius),
          Offset(scaledSize / 2, scaledHeight),
        );
        final Paint triangleFillPaint = Paint()..shader = accentFillGradient;
        canvas.drawPath(trianglePath, triangleFillPaint);
        if (borderWidth > 0) {
          final Paint triangleBorderPaint = Paint()
            ..shader = accentFillGradient
            ..style = PaintingStyle.stroke
            ..strokeWidth = triangleBorderWidth;
          canvas.drawPath(trianglePath, triangleBorderPaint);
        }

        // Draw the circle last so it fully covers the triangle overlap.
        final Paint circleFillPaint = Paint()
          ..shader = RarityGradient.canvasColorFillGradient(
            fillColor,
            Offset(scaledSize / 2, circleCenter.dy - radius),
            Offset(scaledSize / 2, circleCenter.dy + radius),
          );
        canvas.drawPath(circlePath, circleFillPaint);

        if (image != null) {
          canvas.save();
          canvas.clipPath(circlePath);
          final Rect dstRect = Rect.fromLTWH(
            circleCenter.dx - radius,
            circleCenter.dy - radius,
            radius * 2,
            radius * 2,
          );
          final Rect srcRect = Rect.fromLTWH(
              0, 0, image.width.toDouble(), image.height.toDouble());
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
          canvas.restore();
        }

        if (borderWidth > 0) {
          final Paint circleBorderPaint = Paint()
            ..shader = RarityGradient.canvasColorBorderGradient(
              pinAccentColor,
              Offset(scaledSize / 2, circleCenter.dy - radius),
              Offset(scaledSize / 2, circleCenter.dy + radius),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = circleBorderWidth;
          canvas.drawPath(circlePath, circleBorderPaint);
        }
      }
    }

    if (iconData != null) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: scaledSize * 0.6,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: iconColor ?? Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(
        canvas,
        circleCenter - Offset(painter.width / 2, painter.height / 2),
      );
    }

    final ui.Image renderedImage = await recorder
        .endRecording()
        .toImage(scaledSize.toInt(), scaledHeight.toInt());
    final ByteData? byteData =
        await renderedImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();
    return (BitmapDescriptor.fromBytes(bytes), bytes);
  }

  // ピンアニメーションを適用したマーカーセットを返す
  Set<Marker> _getAnimatedMarkers() {
    // ふわふわ: easeInOut カーブで anchor.dy を 1.0 〜 1.12 に揺らす
    final double t = CurvedAnimation(
      parent: _pinFloatController,
      curve: Curves.easeInOut,
    ).value;
    final double floatAnchorDy = 1.0 + sin(t * pi) * 0.12;

    if (floatAnchorDy == 1.0 && _markerSpinIcons.isEmpty) return _markers;

    return _markers.map((marker) {
      final String id = marker.markerId.value;
      final BitmapDescriptor? spinIcon = _markerSpinIcons[id];
      if (spinIcon != null) {
        return marker.copyWith(
          anchorParam: Offset(0.5, floatAnchorDy),
          iconParam: spinIcon,
        );
      }
      return marker.copyWith(
        anchorParam: Offset(0.5, floatAnchorDy),
      );
    }).toSet();
  }

  // Y軸スピン用: PNG画像をX方向にスケールして新しいビットマップを生成
  Future<Uint8List> _buildScaledImage(ui.Image src, double scaleX) async {
    final double w = src.width.toDouble();
    final double h = src.height.toDouble();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    // 縦軸中心でX方向スケール（Y軸スピンのシミュレーション）
    canvas.translate(w / 2, 0);
    canvas.scale(scaleX, 1.0);
    canvas.translate(-w / 2, 0);
    canvas.drawImage(src, Offset.zero, Paint());
    final ui.Image img =
        await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  // 指定マーカーのY軸スピンアニメーションを実行
  Future<void> _spinMarker(String markerId) async {
    final String? cacheKey = _markerIdToCacheKey[markerId];
    if (cacheKey == null) return;
    final Uint8List? bytes = _markerBytesCache[cacheKey];
    if (bytes == null) return;

    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image srcImage = frame.image;

    // 5〜6回転、cubic ease-out（最初は速く重力の法則で減速）
    final int rotations = 5 + Random().nextInt(2); // 5 or 6
    final double totalAngle = rotations * 2 * pi;
    const int totalDurationMs = 2000;
    const int frameIntervalMs = 50;
    const int totalFrames = totalDurationMs ~/ frameIntervalMs; // 40フレーム

    for (int i = 1; i <= totalFrames; i++) {
      await Future.delayed(const Duration(milliseconds: frameIntervalMs));
      if (!mounted) return;

      final double t = i / totalFrames;
      // cubic ease-out: 1 - (1-t)^3 → 最初速く、末端で急減速
      final double easedT = 1.0 - pow(1.0 - t, 3).toDouble();
      final double angle = totalAngle * easedT;
      // Y軸スピンをX方向スケールで擬似表現（対称なので絶対値）
      final double scaleX = cos(angle).abs();

      if (i == totalFrames) {
        setState(() => _markerSpinIcons.remove(markerId));
      } else if (scaleX > 0.98) {
        // 正面向きのときは元画像をそのまま表示
        setState(() => _markerSpinIcons.remove(markerId));
      } else {
        final Uint8List scaledBytes = await _buildScaledImage(srcImage, scaleX);
        if (!mounted) return;
        setState(() {
          _markerSpinIcons[markerId] = BitmapDescriptor.fromBytes(scaledBytes);
        });
      }
    }
  }

  // 指定マーカーの次のスピンをランダム間隔でスケジュール
  void _scheduleMarkerSpin(String markerId) {
    _markerSpinTimers[markerId]?.cancel();
    if (!mounted) return;
    final int delayMs = 5000 + Random().nextInt(7000); // 5〜12秒
    _markerSpinTimers[markerId] = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _spinMarker(markerId).then((_) => _scheduleMarkerSpin(markerId));
      }
    });
  }

  // 全マーカーのランダムスピンスケジュールを初期化
  void _scheduleRandomSpins() {
    for (final Timer t in _markerSpinTimers.values) {
      t.cancel();
    }
    _markerSpinTimers.clear();
    _markerSpinIcons.clear();

    final Random random = Random();
    for (final Marker marker in _markers) {
      final String markerId = marker.markerId.value;
      final int initialDelay = random.nextInt(8000); // 0〜8秒のランダム初期遅延
      _markerSpinTimers[markerId] = Timer(Duration(milliseconds: initialDelay), () {
        if (mounted) {
          _spinMarker(markerId).then((_) => _scheduleMarkerSpin(markerId));
        }
      });
    }
  }

  // マーカーを作成
  Future<void> _createMarkers() async {
    final int buildToken = ++_markerBuildToken;
    final Set<Marker> markers = {};

    // 現在地は Google Map の標準の青丸表示を使うため、独自マーカーは追加しない

    // 店舗マーカー
    for (final store in _stores) {
      // 「営業中のみ」モード時のフィルタ
      if (_mapFilter.showOpenNowOnly && !_isStoreOpenNow(store)) {
        continue;
      }
      // 詳細フィルターの適用
      if (!_passesFilter(store)) {
        continue;
      }
      final bool isExpanded = _expandedMarkerId == store['id'];
      final String storeId = store['id'];
      final String flowerType = store['flowerType'];
      final String category = (store['category'] ?? 'その他').toString();
      final String storeIconUrl = (store['iconImageUrl'] as String?) ?? '';
      final _MarkerVisual visual = _resolveMarkerVisual(
        flowerType: flowerType,
        category: category,
        storeIconUrl: storeIconUrl,
        storeId: storeId,
      );
      final double size = isExpanded ? 116.0 : 58.0;
      final double borderWidth = isExpanded ? 2.4 : 1.2;
      final Color borderColor = visual.useImage ? Colors.black : Colors.white70;
      final Color iconColor = visual.iconColor ??
          (visual.useImage ? Colors.grey[700]! : Colors.white);

      // ピンアクセント色の決定
      Color pinAccentColor = const Color(0xFFFF6B35);
      bool isLegend = false;
      bool isGrayPin = false;
      bool isGreenPin = false;

      if (_personalMapMode) {
        // 個人モード: 来店回数に応じたステータス色
        final totalVisits =
            (_userStamps[storeId]?['totalVisits'] as num?)?.toInt() ?? 0;
        final status = _getPersonalMapStatus(totalVisits);
        pinAccentColor = _getPersonalMapColor(status);
        isLegend = status == 'legend';
        isGrayPin = status == 'undiscovered';
      } else if (_mapFilter.pioneerMode) {
        // 開拓モード: スタンプ数で色分け
        final stamps = _userStamps[storeId]?['stamps'] ?? 0;
        if (stamps >= 1) {
          pinAccentColor = const Color(0xFF2196F3); // 開拓済み = 青
        } else {
          pinAccentColor = const Color(0xFFBDBDBD); // 未開拓 = グレー
          isGrayPin = true;
        }
      } else {
        // 通常モード: 営業中=緑、営業時間外=グレー
        final isOpen = _isStoreOpenNow(store);
        if (isOpen) {
          pinAccentColor = const Color(0xFF43A047);
          isGreenPin = true;
        } else {
          pinAccentColor = const Color(0xFFBDBDBD);
          isGrayPin = true;
        }
      }

      final String cacheKey = _personalMapMode
          ? 'personal|${(_userStamps[storeId]?['totalVisits'] as num?)?.toInt() ?? 0}|$isExpanded|$storeIconUrl|$flowerType|$category'
          : '${_mapMode}|${_mapFilter.categoryMode}|${_mapFilter.pioneerMode}|$flowerType|$category|$isExpanded|$storeIconUrl|${pinAccentColor.value}';
      _markerIdToCacheKey[storeId] = cacheKey;
      final BitmapDescriptor markerIcon = await _getMarkerIcon(
        cacheKey: cacheKey,
        size: size,
        fillColor: visual.color,
        borderColor: borderColor,
        borderWidth: borderWidth,
        iconData: visual.iconData,
        iconColor: iconColor,
        storeIconUrl: visual.useImage ? storeIconUrl : '',
        pinAccentColor: pinAccentColor,
        isLegend: isLegend,
        isGrayPin: isGrayPin,
        isGreenPin: isGreenPin,
      );

      markers.add(
        Marker(
          markerId: MarkerId(storeId),
          position: store['position'],
          icon: markerIcon,
          anchor: const Offset(0.5, 1.0),
          onTap: () async {
            HapticFeedback.mediumImpact();
            setState(() {
              if (_expandedMarkerId == storeId) {
                _expandedMarkerId = '';
                _isShowStoreInfo = false;
              } else {
                _expandedMarkerId = storeId;
                _isShowStoreInfo = true;
                _selectedStoreUid = storeId;
              }
            });
            // 選択リングアニメーション
            if (_isShowStoreInfo) {
              final screenPos = await _mapController
                  ?.getScreenCoordinate(store['position'] as LatLng);
              if (screenPos != null && mounted) {
                setState(() {
                  _selectedMarkerScreenPos = Offset(
                    screenPos.x.toDouble(),
                    screenPos.y.toDouble(),
                  );
                  _showSelectionRing = true;
                });
                _selectionRingController
                  ..reset()
                  ..forward();
              }
            }
            // ウォークスルーステップ2 → 3に進行
            final wState = ref.read(walkthroughProvider);
            if (wState.isActive && wState.step == WalkthroughStep.tapMarker && _isShowStoreInfo) {
              ref.read(walkthroughProvider.notifier).nextStep();
            }
            await _createMarkers();
          },
        ),
      );
    }

    if (!mounted || buildToken != _markerBuildToken) {
      return;
    }

    setState(() {
      _markers = markers;
    });
    _scheduleRandomSpins();
  }

  // 「営業中」かどうかを判定（scheduleOverrides優先）
  bool _isStoreOpenNow(Map<String, dynamic> store) {
    try {
      final now = DateTime.now();

      // scheduleOverrides を最優先でチェック
      final rawOverrides = store['scheduleOverrides'];
      if (rawOverrides is Map) {
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        final override = rawOverrides[todayKey];
        if (override is Map) {
          final type = (override['type'] as String?) ?? '';
          if (type == 'closed') return false;
          if (type == 'open' || type == 'special_hours') {
            final openStr = (override['open'] as String?) ?? '';
            final closeStr = (override['close'] as String?) ?? '';
            return _isWithinTimeRange(openStr, closeStr, now);
          }
        }
      }

      // 不定休チェック
      if (store['isRegularHoliday'] == true) return false;

      // 通常の businessHours で判定
      final businessHours = store['businessHours'];
      if (businessHours == null || businessHours is! Map) return false;

      // 曜日キーを取得（monday..sunday）
      const days = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      // Dartのweekdayは 1=Mon..7=Sun → 0=Mon..6=Sun に変換
      final int mondayFirstIndex = now.weekday == 7 ? 6 : now.weekday - 1;
      final String keyToday = days[mondayFirstIndex];
      final Map<String, dynamic>? today =
          (businessHours[keyToday] as Map?)?.cast<String, dynamic>();
      if (today == null) return false;

      final bool isOpenFlag = today['isOpen'] == true;
      if (!isOpenFlag) return false;

      // 複数時間帯対応: periodsがあればいずれかの時間帯で判定
      final periods = today['periods'];
      if (periods is List && periods.isNotEmpty) {
        return periods.any((p) {
          if (p is! Map) return false;
          final openStr = (p['open'] ?? '').toString();
          final closeStr = (p['close'] ?? '').toString();
          return _isWithinTimeRange(openStr, closeStr, now);
        });
      }

      // フォールバック: 従来のopen/closeで判定
      final String openStr = (today['open'] ?? '').toString();
      final String closeStr = (today['close'] ?? '').toString();
      return _isWithinTimeRange(openStr, closeStr, now);
    } catch (_) {
      return false;
    }
  }

  // 時間範囲内かを判定するヘルパー（深夜跨ぎ対応）
  bool _isWithinTimeRange(String openStr, String closeStr, DateTime now) {
    if (openStr.isEmpty || closeStr.isEmpty) return false;

    int toMinutes(String hhmm) {
      final parts = hhmm.split(':');
      if (parts.length != 2) return -1;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }

    final int openM = toMinutes(openStr);
    final int closeM = toMinutes(closeStr);
    if (openM < 0 || closeM < 0) return false;

    final int nowM = now.hour * 60 + now.minute;
    if (openM <= closeM) {
      return nowM >= openM && nowM < closeM;
    } else {
      // 深夜跨ぎ（例: 20:00〜02:00）
      return nowM >= openM || nowM < closeM;
    }
  }

  // 今日の営業時間文字列を返す（scheduleOverrides優先）
  String _getTodayHours(Map<String, dynamic> store) {
    final now = DateTime.now();

    // scheduleOverrides を最優先でチェック
    final rawOverrides = store['scheduleOverrides'];
    if (rawOverrides is Map) {
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final override = rawOverrides[todayKey];
      if (override is Map) {
        final type = (override['type'] as String?) ?? '';
        final open = (override['open'] as String?) ?? '';
        final close = (override['close'] as String?) ?? '';
        if (type == 'closed') return '臨時休業';
        if ((type == 'open' || type == 'special_hours') &&
            open.isNotEmpty &&
            close.isNotEmpty) {
          return '$open〜$close';
        }
      }
    }

    // 不定休で scheduleOverride なし → 定休日として表示
    if (store['isRegularHoliday'] == true) return '定休日';

    // businessHours フォールバック
    final businessHours = store['businessHours'];
    if (businessHours is! Map) return '';

    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final int mondayFirstIndex = now.weekday == 7 ? 6 : now.weekday - 1;
    final dayData =
        (businessHours[days[mondayFirstIndex]] as Map?)
            ?.cast<String, dynamic>();
    if (dayData == null) return '';

    final isOpen = dayData['isOpen'] == true;
    if (!isOpen) return '定休日';

    // 複数時間帯対応: periodsがあれば全時間帯を結合表示
    final periods = dayData['periods'];
    if (periods is List && periods.isNotEmpty) {
      final parts = <String>[];
      for (final p in periods) {
        if (p is! Map) continue;
        final open = (p['open'] ?? '').toString();
        final close = (p['close'] ?? '').toString();
        if (open.isNotEmpty && close.isNotEmpty) {
          parts.add('$open〜$close');
        }
      }
      if (parts.isNotEmpty) return parts.join(' / ');
    }

    // フォールバック: 従来のopen/close
    final openStr = (dayData['open'] ?? '').toString();
    final closeStr = (dayData['close'] ?? '').toString();
    if (openStr.isEmpty || closeStr.isEmpty) return '';
    return '$openStr〜$closeStr';
  }

  // 詳細フィルターの適用チェック
  bool _passesFilter(Map<String, dynamic> store) {
    final filter = _mapFilter;

    // フィルターが無効なら全て通過
    if (!filter.isActive) return true;

    final String storeId = store['id'] ?? '';

    // カテゴリフィルター
    if (filter.selectedCategories.isNotEmpty) {
      final String category = (store['category'] ?? 'その他').toString();
      if (!filter.selectedCategories.contains(category)) return false;
    }

    // 開拓状態フィルター
    if (filter.explorationStatus.isNotEmpty) {
      final String flowerType = (store['flowerType'] ?? 'unvisited').toString();
      // flowerType: 'unvisited', 'visited'(exploring), 'regular'
      final String status =
          flowerType == 'visited' ? 'exploring' : flowerType;
      if (!filter.explorationStatus.contains(status)) return false;
    }

    // お気に入りフィルター
    if (filter.favoritesOnly) {
      if (!_favoriteStoreIds.contains(storeId)) return false;
    }

    // 決済方法フィルター
    if (filter.paymentMethodCategories.isNotEmpty) {
      final paymentMethods = store['paymentMethods'];
      if (paymentMethods == null || paymentMethods is! Map) return false;
      bool hasAny = false;
      for (final category in filter.paymentMethodCategories) {
        final categoryData = paymentMethods[category];
        if (categoryData is Map) {
          for (final entry in categoryData.entries) {
            if (entry.value == true) {
              hasAny = true;
              break;
            }
          }
        }
        if (hasAny) break;
      }
      if (!hasAny) return false;
    }

    // クーポンフィルター
    if (filter.hasCoupon) {
      final coupons = _storeCoupons[storeId];
      if (coupons == null || coupons.isEmpty) return false;

      // 利用可能クーポンフィルター
      if (filter.hasAvailableCoupon) {
        final userStamp = _userStamps[storeId];
        final int stamps = (userStamp?['stamps'] as int?) ?? 0;
        final hasAvailable = coupons.any((coupon) {
          final requiredStamps =
              (coupon['requiredStampCount'] as int?) ?? 0;
          return stamps >= requiredStamps;
        });
        if (!hasAvailable) return false;
      }
    }

    // 距離フィルター
    if (filter.maxDistanceKm != null && _currentLocation != null) {
      final LatLng storePos = store['position'] as LatLng;
      final double distanceM = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        storePos.latitude,
        storePos.longitude,
      );
      final double distanceKm = distanceM / 1000.0;
      if (distanceKm > filter.maxDistanceKm!) return false;
    }

    return true;
  }

  // 特定の店舗を地図上で選択状態にする
  Future<void> _selectStoreOnMap(String storeId) async {
    final store = _stores.firstWhere(
      (store) => store['id'] == storeId,
      orElse: () => {},
    );

    if (store.isNotEmpty) {
      setState(() {
        _selectedStoreUid = storeId;
        _isShowStoreInfo = true;
        _expandedMarkerId = storeId;
      });

      // 地図をその店舗の位置に移動
      _currentCenter = store['position'];
      _currentZoom = 16.0;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentCenter,
            zoom: _currentZoom,
            bearing: _currentBearing,
          ),
        ),
      );

      // マーカーを再作成してサイズを更新
      await _createMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            style: _gameMapStyle,
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: _currentZoom,
              bearing: _currentBearing,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_didRestoreLastLocation && _currentLocation != null) {
                _mapController?.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentCenter,
                      zoom: _currentZoom,
                      bearing: _currentBearing,
                    ),
                  ),
                );
              }
            },
            markers: _getAnimatedMarkers(),
            circles: _getActiveCircles(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (point) async {
              setState(() {
                _isShowStoreInfo = false;
                _expandedMarkerId = '';
              });
              await _loadUserStamps();
              await _createMarkers();
            },
            onCameraMove: (position) {
              _currentCenter = position.target;
              _currentZoom = position.zoom;
              _currentBearing = position.bearing;
            },
          ),

          // モードトグル（通常 / 個人 / コミュニティ）
          if (!_isSearchExpanded) _buildModeToggle(),

          // コミュニティモード サブモードトグル（開拓率 / 賑わい度）
          _buildCommunitySubModeToggle(),

          // 通常モード 凡例カード
          if (_mapMode == 'normal') _buildNormalModeLegend(),

          // 個人モード 凡例カード
          _buildPersonalModeLegend(),

          // コミュニティモード 凡例カード
          _buildCommunityModeLegend(),

          // 検索フォーカス時のグレーアウトオーバーレイ（タブ・凡例カードの上、検索バーの下）
          if (_isSearchExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _isSearchExpanded = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

          // 検索バー
          _buildSearchBar(),

          // 検索結果リスト
          if (_searchQuery.isNotEmpty) _buildSearchResults(),

          // 地図コントロールボタン（詳細カードの下に描画）
          _buildMapControls(),

          // 拡大されたマーカーオーバーレイ（最前面）
          if (_isShowStoreInfo) _buildStoreInfoCard(),

          // 選択リングアニメーション
          if (_showSelectionRing && _selectedMarkerScreenPos != null)
            Positioned(
              left: _selectedMarkerScreenPos!.dx - 60,
              top: _selectedMarkerScreenPos!.dy - 60,
              child: AnimatedBuilder(
                animation: _selectionRingController,
                builder: (context, child) {
                  final t = _selectionRingController.value;
                  final size = 120.0 * (0.5 + t * 0.5);
                  return Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppUi.primary,
                          width: 2.0 * (1.0 - t),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ウォークスルーオーバーレイ（ステップ2: マーカータップ誘導）
          _buildMapWalkthroughOverlay(),
        ],
      ),
    );
  }

  Widget _buildMapWalkthroughOverlay() {
    final wState = ref.watch(walkthroughProvider);
    if (!wState.isActive) return const SizedBox.shrink();

    if (wState.step == WalkthroughStep.tapMarker) {
      final config = walkthroughStepConfigs[WalkthroughStep.tapMarker];
      final safeTop = MediaQuery.of(context).padding.top;

      return Stack(
        children: [
          // 中央を透明に・端を暗くする放射グラデーション（ピンが目立つように）
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // メッセージバナー（マップへのタップは透過）
          Positioned(
            top: safeTop + 60,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      config?.message ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    if (config?.subMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        config!.subMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // スキップボタン（タップ可能）
          Positioned(
            top: safeTop + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => ref.read(walkthroughProvider.notifier).skipWalkthrough(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'スキップ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStoreInfoCard() {
    // 選択された店舗の情報を取得
    final selectedStore = _stores.firstWhere(
      (store) => store['id'] == _selectedStoreUid,
      orElse: () => {},
    );

    if (selectedStore.isEmpty) return const SizedBox.shrink();

    // ユーザーのスタンプ状況を取得
    final userStamp = _userStamps[_selectedStoreUid];
    final stamps = userStamp?['stamps'] ?? 0;
    final bool isOpenNow = _isStoreOpenNow(selectedStore);
    final String category = (selectedStore['category'] ?? 'その他').toString();

    final String categoryText = (selectedStore['category'] ?? 'その他').toString();
    final String subCategoryText =
        (selectedStore['subCategory'] ?? '').toString();
    final String categoryDisplay =
        (subCategoryText.isNotEmpty && subCategoryText != categoryText)
            ? '$categoryText / $subCategoryText'
            : categoryText;

    final totalVisits = (userStamp?['totalVisits'] as num?)?.toInt() ?? 0;
    final status = _getPersonalMapStatus(totalVisits);

    final double bottomNavBarHeight = MediaQuery.of(context).padding.bottom + 90;

    return Positioned(
      bottom: bottomNavBarHeight,
      left: 20,
      right: 20,
      child: Container(
            decoration: BoxDecoration(
              color: _gameBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _gameBorder.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gameBorder.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 店舗画像セクション
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF0D1B2A),
                          child: selectedStore['storeImageUrl'] != null &&
                                  (selectedStore['storeImageUrl'] as String).isNotEmpty
                              ? Image.network(
                                  selectedStore['storeImageUrl'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        _getDefaultStoreIcon(category),
                                        size: 40,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    _getDefaultStoreIcon(category),
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                        // グラデーションオーバーレイ
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(0x80101E2E),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // 営業状況バッジ（右上）
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOpenNow
                                  ? _gameOpenColor.withOpacity(0.9)
                                  : Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isOpenNow ? _gameOpenColor : Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isOpenNow ? Colors.white : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpenNow ? '営業中' : '営業時間外',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOpenNow ? Colors.white : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ジャンルバッジ（左上）
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppUi.primary.withOpacity(0.7),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              categoryDisplay,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ゲーム風情報セクション
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 店舗名 + 来店ステータスバッジ
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedStore['name'] ?? '店舗名なし',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildVisitStatusBadge(status, totalVisits),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // スタンプ数 + 営業時間
                      Row(
                        children: [
                          Icon(Icons.stars_rounded, color: AppUi.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'スタンプ $stamps 個',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.schedule, color: Colors.grey[500], size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              () {
                                final hours = _getTodayHours(selectedStore);
                                return hours.isNotEmpty ? hours : '---';
                              }(),
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 区切り線
                      Container(
                        height: 1,
                        color: _gameBorder.withOpacity(0.2),
                      ),
                      const SizedBox(height: 12),
                      // ゲーム風アクションボタン
                      CustomButton(
                        text: '詳細を見る',
                        height: 44,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 14,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  StoreDetailView(store: selectedStore),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // 閉じるボタン（×）
                      Center(
                        child: GestureDetector(
                          key: _closeBtnKey,
                          onTap: () async {
                            setState(() {
                              _isShowStoreInfo = false;
                              _expandedMarkerId = '';
                            });
                            await _createMarkers();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2A3A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _gameBorder.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildVisitStatusBadge(String status, int totalVisits) {
    final color = _getPersonalMapColor(status);
    final label = switch (status) {
      'undiscovered' => '未発見',
      'discovered' => '初発見',
      'exploring' => '探索中',
      'regular' => '常連',
      'legend' => 'レジェンド',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // フィルター設定画面への遷移
  Future<void> _openFilterSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ログインが必要です'),
          content: const Text('フィルター機能を使用するにはログインしてください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<MapFilterModel>(
      MaterialPageRoute(
        builder: (context) =>
            FilterSettingsView(initialFilter: _mapFilter),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _mapFilter = result;
      });

      // クーポンフィルターが有効な場合はクーポンデータを再読み込み
      if (result.hasCoupon || result.hasAvailableCoupon) {
        await _loadStoreCoupons();
      }

      // お気に入りフィルターが有効な場合はお気に入りを再読み込み
      if (result.favoritesOnly) {
        await _loadFavoriteStoreIds();
      }

      await _createMarkers();
    }
  }

  Widget _buildSearchBar() {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double searchTopOffset = 4;

    // ゲーム風シャドウ装飾
    final boxShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];

    // フィルターボタン（常に表示）
    Widget filterButton = GestureDetector(
      onTap: _openFilterSettings,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _mapFilter.isActive ? const Color(0xFFFF6B35) : _gameBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: _mapFilter.isActive
                ? AppUi.primary.withOpacity(0.6)
                : _gameBorder.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: boxShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune,
              color: _mapFilter.isActive ? Colors.white : Colors.grey[400],
              size: 24,
            ),
            if (_mapFilter.isActive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!_isSearchExpanded) {
      // 折りたたみ状態: 左に検索アイコン、右にフィルターボタン
      return Positioned(
        top: topPadding + searchTopOffset,
        left: 20,
        right: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _isSearchExpanded = true);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _gameBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gameBorder.withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: boxShadow,
                ),
                child: Icon(Icons.search, color: Colors.grey[400], size: 24),
              ),
            ),
            filterButton,
          ],
        ),
      );
    }

    // 展開状態: 左に戻るボタン、中央に検索フィールド
    return Positioned(
      top: topPadding + searchTopOffset,
      left: 20,
      right: 20,
      child: Row(
        children: [
          // 閉じるボタン
          GestureDetector(
            onTap: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _isSearchExpanded = false;
              });
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _gameBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gameBorder.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: boxShadow,
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey[400], size: 24),
            ),
          ),
          const SizedBox(width: 8),
          // 検索フィールド
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _gameBackground,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _gameBorder.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: boxShadow,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: '店舗名を入力してください',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ひらがなをカタカナに変換して検索用に正規化する
  String _normalizeForSearch(String text) {
    final buffer = StringBuffer();
    for (final codeUnit in text.toLowerCase().runes) {
      // ひらがな（U+3041〜U+3096）→ カタカナ（U+30A1〜U+30F6）に変換
      if (codeUnit >= 0x3041 && codeUnit <= 0x3096) {
        buffer.writeCharCode(codeUnit + 0x60);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  Widget _buildSearchResults() {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double searchTopOffset = 4;
    const double searchHeight = 50;
    const double resultsTopGap = 4;

    final query = _normalizeForSearch(_searchQuery);
    final matchedStores = _stores.where((store) {
      final isActive = store['isActive'] == true;
      final isApproved = store['isApproved'] == true;
      if (!isActive || !isApproved) return false;
      final name = _normalizeForSearch((store['name'] ?? '').toString());
      return name.contains(query);
    }).take(5).toList();

    if (matchedStores.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: topPadding + searchTopOffset + searchHeight + resultsTopGap,
      left: 20,
      right: 78, // フィルターボタン分の余白
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: matchedStores.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: Colors.grey[200],
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final store = matchedStores[index];
            return InkWell(
              borderRadius: index == 0
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : index == matchedStores.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(12))
                      : BorderRadius.zero,
              onTap: () {
                FocusScope.of(context).unfocus();
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                // カメラ移動のみ（ピン拡大・ポップアップなし）
                final storeData = _stores.firstWhere(
                  (s) => s['id'] == store['id'],
                  orElse: () => {},
                );
                if (storeData.isNotEmpty) {
                  _currentCenter = storeData['position'] as LatLng;
                  _currentZoom = 16.0;
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentCenter,
                        zoom: _currentZoom,
                        bearing: _currentBearing,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  store['name'] ?? '',
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 上部モードトグル（通常 / 個人 / コミュニティ）
  Widget _buildModeToggle() {
    const modes = ['normal', 'personal', 'community'];
    final double topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 16,
      left: 78,
      right: 78,
      child: Center(
        child: CompactToggleBar(
          labels: const ['通常', '個人', 'コミュニティ'],
          selectedIndex: modes.indexOf(_mapMode).clamp(0, 2),
          onChanged: (index) => _setMapMode(modes[index]),
        ),
      ),
    );
  }

  // 凡例カードの共通アコーディオンウィジェット（くの字矢印で開閉）
  Widget _buildLegendCard({required String title, required List<Widget> items}) {
    final BoxDecoration cardDecoration = BoxDecoration(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
    return GestureDetector(
      onTap: () => setState(() => _isLegendVisible = !_isLegendVisible),
      child: Container(
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー行（常に表示）
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _isLegendVisible ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            // 展開時のみアイテムを表示
            if (_isLegendVisible) ...[
              Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: items,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 凡例の1行アイテム（丸ドット＋ラベル）
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  // 凡例の1行アイテム（丸ドット＋ラベル＋サブラベル）
  Widget _buildLegendItemWithSub(Color color, String label, String subLabel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        const SizedBox(width: 4),
        Text(
          subLabel,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }

  // 通常モード用 凡例カード（営業時間内/外の色説明）
  Widget _buildNormalModeLegend() {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double topY = topPadding + 62;
    return Positioned(
      top: topY,
      left: 20,
      child: _buildLegendCard(
        title: '凡例',
        items: [
          _buildLegendItem(const Color(0xFF43A047), '営業中'),
          const SizedBox(height: 5),
          _buildLegendItem(const Color(0xFFBDBDBD), '営業時間外'),
        ],
      ),
    );
  }

  // 個人モード用 凡例カード（5段階ステータス）
  Widget _buildPersonalModeLegend() {
    if (_mapMode != 'personal') return const SizedBox.shrink();
    final double topPadding = MediaQuery.of(context).padding.top;
    final double topY = topPadding + 62;
    return Positioned(
      top: topY,
      left: 20,
      child: _buildLegendCard(
        title: '凡例',
        items: [
          _buildLegendItemWithSub(const Color(0xFFBDBDBD), '未発見', '0回'),
          const SizedBox(height: 5),
          _buildLegendItemWithSub(const Color(0xFF29B6F6), '初発見', '1回'),
          const SizedBox(height: 5),
          _buildLegendItemWithSub(const Color(0xFF66BB6A), '探索中', '2〜4回'),
          const SizedBox(height: 5),
          _buildLegendItemWithSub(const Color(0xFFFB8C00), '常連', '5〜9回'),
          const SizedBox(height: 5),
          _buildLegendItemWithSub(const Color(0xFFFFB300), 'レジェンド', '10回〜'),
        ],
      ),
    );
  }

  // コミュニティモード用 凡例カード
  Widget _buildCommunityModeLegend() {
    if (!_communityMapMode) return const SizedBox.shrink();
    final double topPadding = MediaQuery.of(context).padding.top;
    // サブモードトグル(34px程度) + gap(8)
    final double topY = topPadding + 62 + 42;

    final List<Widget> legendItems = _communitySubMode == 'exploration'
        ? [_buildLegendItem(const Color(0xFFFF6B35), 'エリア境界')]
        : [
            _buildLegendItem(const Color(0xFF29B6F6), '1〜10人'),
            const SizedBox(height: 5),
            _buildLegendItem(const Color(0xFF66BB6A), '11〜30人'),
            const SizedBox(height: 5),
            _buildLegendItem(const Color(0xFFFB8C00), '31〜100人'),
            const SizedBox(height: 5),
            _buildLegendItem(const Color(0xFFFFB300), '100人以上'),
          ];

    return Positioned(
      top: topY,
      left: 20,
      child: _buildLegendCard(title: '凡例', items: legendItems),
    );
  }

  // コミュニティモード時のサブモードトグル（開拓率 / 賑わい度）
  Widget _buildCommunitySubModeToggle() {
    if (!_communityMapMode) return const SizedBox.shrink();
    final double topPadding = MediaQuery.of(context).padding.top;
    // modeToggle(44) と search(50) が同じ高さ(top+4)、gap(8)
    final double topY = topPadding + 62;
    return Positioned(
      top: topY,
      left: 20,
      child: CompactToggleBar(
        labels: const ['開拓率', '賑わい度'],
        selectedIndex: _communitySubMode == 'exploration' ? 0 : 1,
        onChanged: (index) {
          setState(() {
            _communitySubMode = index == 0 ? 'exploration' : 'activity';
          });
        },
      ),
    );
  }

  Future<void> _loadPlayerStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      final discoveredCount =
          (data['discoveredStoreCount'] as num?)?.toInt() ?? 0;
      final badgeCount = (data['badgeCount'] as num?)?.toInt() ?? 0;

      // ランキング順位を取得（自分より発見数が多いユーザー数 + 1）
      int rank = 0;
      try {
        final countSnapshot = await FirebaseFirestore.instance
            .collection('ranking_scores')
            .doc('all_time')
            .collection('users')
            .where('discoveredStoreCount', isGreaterThan: discoveredCount)
            .count()
            .get();
        rank = (countSnapshot.count ?? 0) + 1;
      } catch (e) {
        debugPrint('ランキング順位の取得失敗: $e');
      }

      if (!mounted) return;
      setState(() {
        _playerDiscoveredCount = discoveredCount;
        _playerBadgeCount = badgeCount;
        _playerRank = rank;
      });
    } catch (e) {
      debugPrint('プレイヤー統計の読み込み失敗: $e');
    }
  }

  Widget _buildMapControls() {
    final double topPadding = MediaQuery.of(context).padding.top;
    // modeToggle と search が同じ高さ(top+4+50)、gap(8)
    final double topY = topPadding + 62;

    return Positioned(
      top: topY,
      right: 20,
      child: Column(
        children: [
          // 現在位置ボタン
          GestureDetector(
            onTap: () async {
              try {
                await _getCurrentLocation();
                setState(() {
                  _expandedMarkerId = '';
                  _isShowStoreInfo = false;
                });
                await _loadUserStamps();
                await _createMarkers();
              } catch (e) {
                print('現在位置ボタンタップ時のエラー: $e');
                // エラーが発生してもマーカーは更新する
                await _loadUserStamps();
                await _createMarkers();
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gameBorder.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 北向きに揃えるボタン
          GestureDetector(
            onTap: () {
              _currentBearing = 0.0;
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _currentCenter,
                    zoom: _currentZoom,
                    bearing: _currentBearing,
                  ),
                ),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gameBorder.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 発見数
          GestureDetector(
            onTap: () => showGameDialog(
              context: context,
              title: '発見した店舗数',
              message:
                  'これまでに発見（訪問）した店舗の総数です。\n新しいお店を訪れると数が増えていきます！\n\n現在: $_playerDiscoveredCount 店舗',
              icon: Icons.search_rounded,
              headerColor: const Color(0xFF29B6F6),
              actions: [
                GameDialogAction(
                  label: '閉じる',
                  onPressed: () => Navigator.of(context).pop(),
                  isPrimary: true,
                ),
              ],
            ),
            child: _buildStatCircle(
              icon: Icons.search_rounded,
              iconColor: const Color(0xFF29B6F6),
              value: '$_playerDiscoveredCount',
            ),
          ),
          const SizedBox(height: 10),
          // バッジ数
          GestureDetector(
            onTap: () => showGameDialog(
              context: context,
              title: '獲得バッジ数',
              message:
                  'これまでに獲得したバッジの総数です。\nミッションをクリアしてバッジを集めよう！\n\n現在: $_playerBadgeCount 個',
              icon: Icons.military_tech_rounded,
              headerColor: const Color(0xFFB97CF0),
              actions: [
                GameDialogAction(
                  label: '閉じる',
                  onPressed: () => Navigator.of(context).pop(),
                  isPrimary: true,
                ),
              ],
            ),
            child: _buildStatCircle(
              icon: Icons.military_tech_rounded,
              iconColor: const Color(0xFFB97CF0),
              value: '$_playerBadgeCount',
            ),
          ),
          const SizedBox(height: 10),
          // 順位
          GestureDetector(
            onTap: () => showGameDialog(
              context: context,
              title: 'ランキング順位',
              message:
                  '発見した店舗数に基づくランキングの順位です。\nより多くの店舗を発見して上位を目指そう！\n\n現在: ${_playerRank > 0 ? '$_playerRank 位' : '集計中'}',
              icon: Icons.leaderboard_rounded,
              headerColor: const Color(0xFFFFB300),
              actions: [
                GameDialogAction(
                  label: '閉じる',
                  onPressed: () => Navigator.of(context).pop(),
                  isPrimary: true,
                ),
              ],
            ),
            child: _buildStatCircle(
              icon: Icons.leaderboard_rounded,
              iconColor: const Color(0xFFFFB300),
              value: _playerRank > 0 ? '$_playerRank' : '-',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircle({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        shape: BoxShape.circle,
        border: Border.all(
          color: _gameBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
