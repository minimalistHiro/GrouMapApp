import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/store_detail_view.dart';
import '../../widgets/custom_button.dart';

class _MarkerVisual {
  final Color color;
  final IconData iconData;
  final bool useImage;
  final Color? iconColor;

  const _MarkerVisual({
    required this.color,
    required this.iconData,
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

class _MapViewState extends ConsumerState<MapView> {
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

  // データベースから取得した店舗データ
  List<Map<String, dynamic>> _stores = [];

  // ユーザーのスタンプ状況
  Map<String, Map<String, dynamic>> _userStamps = {};

  // 拡大されたマーカーのID
  String _expandedMarkerId = '';

  // 店舗情報表示フラグ
  bool _isShowStoreInfo = false;
  String _selectedStoreUid = '';

  // フィルタ/表示モード
  bool _showOpenNowOnly = false; // 「営業中のみ」表示
  bool _categoryMode = false; // 「ジャンル別」表示（カテゴリーごとにアイコン）
  bool _pioneerMode = false; // 「開拓」表示（未開拓/開拓/常連 のスタンプ状況）
  String _selectedMode = 'none'; // 'none' | 'category' | 'pioneer'

  // デフォルトの座標（東京駅周辺）
  static const LatLng _defaultLocation = LatLng(35.6812, 139.7671);
  static const String _lastLocationLatKey = 'map_last_location_lat';
  static const String _lastLocationLngKey = 'map_last_location_lng';

  // 位置情報取得の試行回数
  int _locationRetryCount = 0;
  static const int _maxLocationRetries = 3;

  @override
  void initState() {
    super.initState();
    _currentCenter = _defaultLocation;
    _loadLastLocationFromPrefs();
    _initializeMapData();
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
    // 店舗データを先に読み込む
    await _loadStoresFromDatabase();

    // 位置情報の取得を試行（失敗してもアプリは動作する）
    try {
      await _getCurrentLocation();
    } catch (e) {
      print('初期位置情報取得に失敗しましたが、アプリは継続します: $e');
    }

    // 特定の店舗が選択されている場合、その店舗を選択状態にする
    if (widget.selectedStoreId != null) {
      await _selectStoreOnMap(widget.selectedStoreId!);
    }
  }

  // データベースから店舗を読み込む
  Future<void> _loadStoresFromDatabase() async {
    try {
      print('店舗データの読み込みを開始...');
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('stores').get();
      print('取得したドキュメント数: ${snapshot.docs.length}');

      final List<Map<String, dynamic>> stores = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            '店舗データ: ${doc.id} - isActive: ${data['isActive']}, isApproved: ${data['isApproved']}');

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
              'location': normalizedLocation, // 位置情報
              'socialMedia': socialMedia,
              'tags': tags,
              'isActive': data['isActive'] ?? false,
              'isApproved': data['isApproved'] ?? false,
              'createdAt': data['createdAt'],
              'updatedAt': data['updatedAt'],
              'isVisited': false,
              'flowerType': 'unvisited',
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

  // 位置情報エラーダイアログを表示
  void _showLocationErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('位置情報エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            if (message.contains('永続的に拒否'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                },
                child: const Text('設定を開く'),
              ),
          ],
        );
      },
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

  _MarkerVisual _resolveMarkerVisual({
    required String flowerType,
    required String category,
    required String storeIconUrl,
  }) {
    if (_pioneerMode) {
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

    if (_categoryMode) {
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
        final BitmapDescriptor icon = await _buildMarkerBitmap(
          size: size,
          fillColor: fillColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          iconData: image == null ? iconData : null,
          iconColor: iconColor,
          image: image,
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        );
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

  Future<BitmapDescriptor> _buildMarkerBitmap({
    required double size,
    required Color fillColor,
    required Color borderColor,
    required double borderWidth,
    required IconData? iconData,
    required Color? iconColor,
    required ui.Image? image,
    required double devicePixelRatio,
  }) async {
    const double pinHeightScale = 1.4;
    const Color grouMapOrange = Color(0xFFFF6B35);
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

    final Paint triangleFillPaint = Paint()..color = grouMapOrange;
    canvas.drawPath(trianglePath, triangleFillPaint);
    if (borderWidth > 0) {
      final Paint triangleBorderPaint = Paint()
        ..color = grouMapOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = triangleBorderWidth;
      canvas.drawPath(trianglePath, triangleBorderPaint);
    }

    // Draw the circle last so it fully covers the triangle overlap.
    final Paint circleFillPaint = Paint()..color = fillColor;
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
      final Rect srcRect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      canvas.restore();
    }

    if (borderWidth > 0) {
      final Paint circleBorderPaint = Paint()
        ..color = grouMapOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = circleBorderWidth;
      canvas.drawPath(circlePath, circleBorderPaint);
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
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // マーカーを作成
  Future<void> _createMarkers() async {
    final int buildToken = ++_markerBuildToken;
    final Set<Marker> markers = {};

    // 現在地は Google Map の標準の青丸表示を使うため、独自マーカーは追加しない

    // 店舗マーカー
    for (final store in _stores) {
      // 「営業中のみ」モード時のフィルタ
      if (_showOpenNowOnly && !_isStoreOpenNow(store)) {
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
      );
      final double size = isExpanded ? 80.0 : 40.0;
      final double borderWidth = isExpanded ? 2.4 : 1.2;
      final Color borderColor = visual.useImage ? Colors.black : Colors.white70;
      final Color iconColor = visual.iconColor ??
          (visual.useImage ? Colors.grey[700]! : Colors.white);
      final String cacheKey =
          '${_selectedMode}|$flowerType|$category|$isExpanded|$storeIconUrl';
      final BitmapDescriptor markerIcon = await _getMarkerIcon(
        cacheKey: cacheKey,
        size: size,
        fillColor: visual.color,
        borderColor: borderColor,
        borderWidth: borderWidth,
        iconData: visual.iconData,
        iconColor: iconColor,
        storeIconUrl: visual.useImage ? storeIconUrl : '',
      );

      markers.add(
        Marker(
          markerId: MarkerId(storeId),
          position: store['position'],
          icon: markerIcon,
          anchor: const Offset(0.5, 1.0),
          onTap: () async {
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
  }

  // 「営業中」かどうかを判定
  bool _isStoreOpenNow(Map<String, dynamic> store) {
    try {
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
      final now = DateTime.now();
      // Dartのweekdayは 1=Mon..7=Sun → 0=Mon..6=Sun に変換
      final int mondayFirstIndex = now.weekday == 7 ? 6 : now.weekday - 1;
      final String keyToday = days[mondayFirstIndex];
      final Map<String, dynamic>? today =
          (businessHours[keyToday] as Map?)?.cast<String, dynamic>();
      if (today == null) return false;

      final bool isOpenFlag = today['isOpen'] == true;
      if (!isOpenFlag) return false;

      final String openStr = (today['open'] ?? '').toString();
      final String closeStr = (today['close'] ?? '').toString();
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
        // 同日内
        return nowM >= openM && nowM < closeM;
      } else {
        // 深夜跨ぎ（例: 20:00〜02:00）
        return nowM >= openM || nowM < closeM;
      }
    } catch (_) {
      return false;
    }
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
            markers: _markers,
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

          // 検索バー
          _buildSearchBar(),

          // 拡大されたマーカーオーバーレイ
          if (_isShowStoreInfo) _buildStoreInfoCard(),

          // 地図コントロールボタン
          _buildMapControls(),
        ],
      ),
    );
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

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 店舗イメージ画像セクション
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.grey[300],
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
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    _getDefaultStoreIcon(category),
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        // ジャンルバッジ
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              categoryDisplay,
                              style: const TextStyle(
                                fontSize: 12,
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
                // テキスト情報セクション
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 店舗名
                      Text(
                        selectedStore['name'] ?? '店舗名なし',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 営業時間バッジ + カテゴリ/サブカテゴリ
                      Row(
                        children: [
                          // 営業状況バッジ
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isOpenNow
                                      ? Colors.green[600]!
                                      : Colors.grey[600]!)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: (isOpenNow
                                          ? Colors.green[600]!
                                          : Colors.grey[600]!)
                                      .withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOpenNow
                                      ? Icons.schedule
                                      : Icons.schedule_outlined,
                                  color: isOpenNow
                                      ? Colors.green[600]
                                      : Colors.grey[600],
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpenNow ? '営業中' : '営業時間外',
                                  style: TextStyle(
                                    color: isOpenNow
                                        ? Colors.green[600]
                                        : Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // カテゴリ/サブカテゴリ
                          Expanded(
                            child: Text(
                              categoryDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // スタンプ進捗インジケータ
                      SizedBox(
                        height: 18,
                        child: Row(
                          children: List.generate(10, (index) {
                            final isActive = index < stamps;
                            return Container(
                              width: 16,
                              height: 16,
                              margin: EdgeInsets.only(
                                  right: index == 9 ? 0 : 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? const Color(0xFFFF6B35)
                                        .withOpacity(0.2)
                                    : Colors.grey[200],
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFFFF6B35)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: isActive
                                  ? const Icon(
                                      Icons.check,
                                      size: 11,
                                      color: Color(0xFFFF6B35),
                                    )
                                  : null,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 詳細を見るボタン
                      CustomButton(
                        text: '詳細を見る',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  StoreDetailView(store: selectedStore),
                            ),
                          );
                        },
                        height: 44,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 閉じるボタン（視認性向上のため白背景追加）
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  _isShowStoreInfo = false;
                  _expandedMarkerId = '';
                });
                await _createMarkers();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double searchTopOffset = 4;
    return Positioned(
      top: topPadding + searchTopOffset,
      left: 20,
      right: 20,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: '店舗名を入力してください',
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.grey,
              size: 24,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // 検索バー下にフィルタ用のチップを表示
  Widget _buildFilterChips() {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double searchTopOffset = 4;
    const double searchHeight = 50;
    const double chipsTopGap = 6;
    final double topY =
        topPadding + searchTopOffset + searchHeight + chipsTopGap;
    return Positioned(
      top: topY,
      left: 20,
      right: 90, // 右側は現在位置ボタンと重ならないよう余白
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('営業中'),
              selected: _showOpenNowOnly,
              onSelected: (val) async {
                setState(() {
                  _showOpenNowOnly = val;
                });
                await _createMarkers();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('ジャンル別'),
              selected: _selectedMode == 'category',
              onSelected: (val) async {
                setState(() {
                  if (val) {
                    _selectedMode = 'category';
                    _categoryMode = true;
                    _pioneerMode = false;
                  } else {
                    _selectedMode = 'none';
                    _categoryMode = false;
                    _pioneerMode = false;
                  }
                });
                await _createMarkers();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('開拓'),
              selected: _selectedMode == 'pioneer',
              onSelected: (val) async {
                setState(() {
                  if (val) {
                    _selectedMode = 'pioneer';
                    _pioneerMode = true;
                    _categoryMode = false;
                  } else {
                    _selectedMode = 'none';
                    _pioneerMode = false;
                    _categoryMode = false;
                  }
                });
                await _createMarkers();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double searchTopOffset = 4;
    const double searchHeight = 50;
    const double chipsTopGap = 6;
    const double chipsHeight = 36;
    const double controlsTopGap = 8;
    final double topY = topPadding +
        searchTopOffset +
        searchHeight +
        chipsTopGap +
        chipsHeight +
        controlsTopGap;

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
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
        ],
      ),
    );
  }
}
