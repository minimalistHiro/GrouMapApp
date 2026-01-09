import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/store_detail_view.dart';

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
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLng? _currentLocation;
  
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
  bool _categoryMode = false;    // 「ジャンル別」表示（カテゴリーごとにアイコン）
  bool _pioneerMode = false;     // 「開拓」表示（未開拓/開拓/常連 のスタンプ状況）
  String _selectedMode = 'none'; // 'none' | 'category' | 'pioneer'
  
  // デフォルトの座標（東京駅周辺）
  static const LatLng _defaultLocation = LatLng(35.6812, 139.7671);
  
  // 位置情報取得の試行回数
  int _locationRetryCount = 0;
  static const int _maxLocationRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
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
      _selectStoreOnMap(widget.selectedStoreId!);
    }
  }
  
  // データベースから店舗を読み込む
  Future<void> _loadStoresFromDatabase() async {
    try {
      print('店舗データの読み込みを開始...');
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('stores').get();
      print('取得したドキュメント数: ${snapshot.docs.length}');
      
      final List<Map<String, dynamic>> stores = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('店舗データ: ${doc.id} - isActive: ${data['isActive']}, isApproved: ${data['isApproved']}');
        
        // 条件を緩和してテスト用の店舗も表示
        if (data['isActive'] == true && data['isApproved'] == true) {
          // 位置情報がある場合のみ追加
          if (data['location'] != null && 
              data['location']['latitude'] != null && 
              data['location']['longitude'] != null) {
            final storeData = {
              'id': doc.id,
              'name': data['name'] ?? '店舗名なし',
              'position': LatLng(
                data['location']['latitude'].toDouble(),
                data['location']['longitude'].toDouble(),
              ),
              'category': data['category'] ?? 'その他',
              'description': data['description'] ?? '',
              'address': data['address'] ?? '',
              'iconImageUrl': data['iconImageUrl'],
              'storeImageUrl': data['storeImageUrl'], // 店舗詳細画面で使用
              'backgroundImageUrl': data['backgroundImageUrl'], // 店舗一覧画面で使用
              'phoneNumber': data['phoneNumber'] ?? '',
              'phone': data['phoneNumber'] ?? '', // store_detail_view.dartで使用
              'businessHours': data['businessHours'] ?? {},
              'location': data['location'], // 位置情報
              'socialMedia': data['socialMedia'] ?? {},
              'tags': data['tags'] ?? [],
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
      _createMarkers();
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
          print('位置情報サービスが無効です。リトライします ($_locationRetryCount/$_maxLocationRetries)');
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
            print('位置情報権限が拒否されました。リトライします ($_locationRetryCount/$_maxLocationRetries)');
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
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _locationRetryCount = 0; // 成功したらリトライカウントをリセット
        });
        
        // 地図を現在地に移動
        _mapController.move(_currentLocation!, 15.0);
        print('地図を現在地に移動しました');
      }
    } catch (e) {
      print('現在地の取得に失敗しました: $e');
      if (_locationRetryCount < _maxLocationRetries) {
        _locationRetryCount++;
        print('現在地取得に失敗しました。リトライします ($_locationRetryCount/$_maxLocationRetries)');
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
  Color _getStampStatusColor(int stamps) {
    if (stamps == 0) {
      return Colors.grey[400]!; // 未開拓
    } else if (stamps >= 1 && stamps <= 9) {
      return Colors.orange[600]!; // 開拓中
    } else if (stamps >= 10) {
      return Colors.amber[600]!; // 常連
    } else {
      return Colors.grey[400]!;
    }
  }

  // スタンプ状況に応じたアイコンを取得
  IconData _getStampStatusIcon(int stamps) {
    if (stamps == 0) {
      return Icons.radio_button_unchecked; // 未開拓
    } else if (stamps >= 1 && stamps <= 9) {
      return Icons.radio_button_checked; // 開拓中
    } else if (stamps >= 10) {
      return Icons.star; // 常連
    } else {
      return Icons.help_outline;
    }
  }

  // カスタムマーカーアイコンを作成
  Widget _createCustomMarkerIcon(String flowerType, bool isExpanded, {String? category, String? storeIconUrl}) {
    final double size = isExpanded ? 50.0 : 30.0;
    
    // カスタムアイコンの色とスタイルを決定
    Color markerColor;
    IconData iconData;

    if (_pioneerMode) {
      // 開拓モード（スタンプ状況）
      switch (flowerType) {
        case 'unvisited': // 未開拓（スタンプ0個）
          markerColor = Colors.grey[400]!;
          iconData = Icons.radio_button_unchecked;
          break;
        case 'visited': // 開拓中（スタンプ1-9個）
          markerColor = Colors.orange[600]!;
          iconData = Icons.radio_button_checked;
          break;
        case 'regular': // 常連（スタンプ10個以上）
          markerColor = Colors.amber[600]!;
          iconData = Icons.star;
          break;
        default:
          markerColor = Colors.grey[400]!;
          iconData = Icons.help_outline;
      }
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: isExpanded ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: markerColor.withOpacity(0.4),
              blurRadius: isExpanded ? 10 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          iconData,
          color: Colors.white,
          size: size * 0.6,
        ),
      );
    } else if (_categoryMode) {
      // ジャンル別（カテゴリー）モード
      final String cat = (category ?? '').toString();
      if (cat.contains('カフェ')) {
        markerColor = Colors.brown[400]!;
        iconData = Icons.local_cafe;
      } else if (cat.contains('レストラン') || cat.contains('食') || cat.contains('グルメ')) {
        markerColor = Colors.redAccent;
        iconData = Icons.restaurant;
      } else if (cat.contains('ショップ') || cat.contains('買') || cat.contains('物')) {
        markerColor = Colors.purple;
        iconData = Icons.shopping_bag;
      } else if (cat.contains('バー') || cat.contains('酒')) {
        markerColor = Colors.deepPurple;
        iconData = Icons.wine_bar;
      } else if (cat.contains('本') || cat.contains('書店') || cat.contains('ブック')) {
        markerColor = Colors.indigo;
        iconData = Icons.menu_book;
      } else if (cat.contains('サービス')) {
        markerColor = Colors.teal;
        iconData = Icons.build_circle;
      } else {
        markerColor = Colors.blueGrey;
        iconData = Icons.place;
      }
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: isExpanded ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: markerColor.withOpacity(0.4),
              blurRadius: isExpanded ? 10 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          iconData,
          color: Colors.white,
          size: size * 0.6,
        ),
      );
    } else {
      // モード未選択（店舗アイコン表示）
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black.withOpacity(0.2),
            width: isExpanded ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: isExpanded ? 10 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: (storeIconUrl != null && storeIconUrl.isNotEmpty)
              ? Image.network(
                  storeIconUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.store,
                    color: Colors.grey[700],
                    size: size * 0.6,
                  ),
                )
              : Icon(
                  Icons.store,
                  color: Colors.grey[700],
                  size: size * 0.6,
                ),
        ),
      );
    }
  }

  // マーカーを作成
  void _createMarkers() {
    final List<Marker> markers = [];
    
    // 現在地マーカー（青い円）
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }

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
      
      markers.add(
        Marker(
          point: store['position'],
          width: isExpanded ? 50 : 30,
          height: isExpanded ? 50 : 30,
          child: GestureDetector(
            onTap: () {
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
              _createMarkers(); // マーカーを再作成してサイズを更新
            },
            child: _createCustomMarkerIcon(
              flowerType,
              isExpanded,
              category: category,
              storeIconUrl: (store['iconImageUrl'] as String?) ?? '',
            ),
          ),
        ),
      );
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
      final Map<String, dynamic>? today = (businessHours[keyToday] as Map?)?.cast<String, dynamic>();
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
  void _selectStoreOnMap(String storeId) {
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
      _mapController.move(store['position'], 16.0);
      
      // マーカーを再作成してサイズを更新
      _createMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マップ'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: const [],
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _defaultLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, point) async {
                setState(() {
                  _isShowStoreInfo = false;
                  _expandedMarkerId = '';
                });
                await _loadUserStamps();
                _createMarkers();
              },
            ),
            children: [
              // OpenStreetMapタイルレイヤー（OpenStreetMap.de）
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.groumapapp',
                additionalOptions: const {
                  'attribution': '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                },
              ),
              // マーカーレイヤー
              MarkerLayer(markers: _markers),
            ],
          ),
          
          // 検索バー
          _buildSearchBar(),
          // フィルタチップ
          _buildFilterChips(),
          
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
    
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                // プロフィール画像
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: selectedStore['iconImageUrl']?.isNotEmpty == true
                        ? Image.network(
                            selectedStore['iconImageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  selectedStore['name']?.substring(0, 1) ?? '?',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              selectedStore['name']?.substring(0, 1) ?? '?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 15),
                // 店舗情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStore['name'] ?? '店舗名なし',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedStore['category'] ?? 'その他'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (selectedStore['description']?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedStore['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // スタンプ状況表示と店舗詳細ボタンを同じ行に配置
                      Row(
                        children: [
                          // 営業状況表示
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isOpenNow ? Colors.green[600]! : Colors.grey[600]!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: (isOpenNow ? Colors.green[600]! : Colors.grey[600]!).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOpenNow ? Icons.schedule : Icons.schedule_outlined,
                                  color: isOpenNow ? Colors.green[600] : Colors.grey[600],
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpenNow ? '営業中' : '営業時間外',
                                  style: TextStyle(
                                    color: isOpenNow ? Colors.green[600] : Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // スタンプ状況表示
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStampStatusColor(stamps).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStampStatusColor(stamps).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStampStatusIcon(stamps),
                                  color: _getStampStatusColor(stamps),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'スタンプ: $stamps/10',
                                  style: TextStyle(
                                    color: _getStampStatusColor(stamps),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // 店舗詳細ボタン
                          GestureDetector(
                            onTap: () {
                              // 店舗詳細画面へ遷移
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StoreDetailView(store: selectedStore),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '店舗詳細',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isShowStoreInfo = false;
                  _expandedMarkerId = '';
                });
                _createMarkers();
              },
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
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
        child: Row(
          children: [
            const SizedBox(width: 15),
            const Icon(
              Icons.search,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '店舗名を入力してください',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }
  
  // 検索バー下にフィルタ用のチップを表示
  Widget _buildFilterChips() {
    final double topY = MediaQuery.of(context).padding.top + 10 + 50 + 10;
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
              onSelected: (val) {
                setState(() {
                  _showOpenNowOnly = val;
                });
                _createMarkers();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('ジャンル別'),
              selected: _selectedMode == 'category',
              onSelected: (val) {
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
                _createMarkers();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('開拓'),
              selected: _selectedMode == 'pioneer',
              onSelected: (val) {
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
                _createMarkers();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildMapControls() {
    // 右下に現在位置ボタンを配置
    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: () async {
          try {
            await _getCurrentLocation();
            setState(() {
              _expandedMarkerId = '';
              _isShowStoreInfo = false;
            });
            await _loadUserStamps();
            _createMarkers();
          } catch (e) {
            print('現在位置ボタンタップ時のエラー: $e');
            // エラーが発生してもマーカーは更新する
            await _loadUserStamps();
            _createMarkers();
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
    );
  }
}
