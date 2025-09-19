import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoogleMapsView extends ConsumerStatefulWidget {
  final String? selectedStoreId;
  
  const GoogleMapsView({
    super.key,
    this.selectedStoreId,
  });

  @override
  ConsumerState<GoogleMapsView> createState() => _GoogleMapsViewState();
}

class _GoogleMapsViewState extends ConsumerState<GoogleMapsView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
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
  
  // デフォルトの座標（東京駅周辺）
  static const LatLng _defaultLocation = LatLng(35.6812, 139.7671);

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }
  
  // 初期データ読み込み
  Future<void> _initializeMapData() async {
    await Future.wait([
      _getCurrentLocation(),
      _loadStoresFromDatabase(),
    ]);
    
    // 特定の店舗が選択されている場合、その店舗を選択状態にする
    if (widget.selectedStoreId != null) {
      _selectStoreOnMap(widget.selectedStoreId!);
    }
  }
  
  // データベースから店舗を読み込む
  Future<void> _loadStoresFromDatabase() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('stores').get();
      final List<Map<String, dynamic>> stores = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isActive'] == true && data['isApproved'] == true) {
          // 位置情報がある場合のみ追加
          if (data['location'] != null && 
              data['location']['latitude'] != null && 
              data['location']['longitude'] != null) {
            stores.add({
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
              'isVisited': false,
              'flowerType': 'unvisited',
            });
          }
        }
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

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('user_stamps')
          .where('userId', isEqualTo: user.uid)
          .get();

      final Map<String, Map<String, dynamic>> userStamps = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final storeId = data['storeId'] as String;
        userStamps[storeId] = {
          'goldStamps': data['goldStamps'] ?? 0,
          'regularStamps': data['regularStamps'] ?? 0,
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
        final goldStamps = userStamp['goldStamps'] ?? 0;
        
        if (goldStamps > 0) {
          _stores[i]['flowerType'] = 'gold';
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
      // 位置情報の権限を確認
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      
      // 現在地を取得
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        // 地図を現在地に移動
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_currentLocation!),
          );
        }
      }
    } catch (e) {
      print('現在地の取得に失敗しました: $e');
    }
  }

  // カスタムマーカーアイコンを作成
  Future<BitmapDescriptor> _createCustomMarkerIcon(String flowerType, bool isExpanded) async {
    // カスタムアイコンの色とスタイルを決定
    Color markerColor;
    
    switch (flowerType) {
      case 'gold':
        markerColor = Colors.amber;
        break;
      case 'unvisited':
        markerColor = Colors.grey;
        break;
      default:
        markerColor = Colors.grey;
    }
    
    // カスタムマーカーを作成（実際の実装では、より詳細なカスタムアイコンを作成できます）
    return BitmapDescriptor.defaultMarkerWithHue(
      markerColor == Colors.amber ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueBlue,
    );
  }

  // マーカーを作成
  Future<void> _createMarkers() async {
    final Set<Marker> markers = {};
    
    // 現在地マーカー（青い円）
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: '現在地'),
        ),
      );
    }

    // 店舗マーカー
    for (final store in _stores) {
      final bool isExpanded = _expandedMarkerId == store['id'];
      final String storeId = store['id'];
      final String flowerType = store['flowerType'];
      
      // カスタムアイコンを作成
      final BitmapDescriptor customIcon = await _createCustomMarkerIcon(flowerType, isExpanded);
      
      markers.add(
        Marker(
          markerId: MarkerId(storeId),
          position: store['position'],
          icon: customIcon,
          infoWindow: InfoWindow(
            title: store['name'],
            snippet: store['category'],
          ),
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
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(store['position'], 16.0),
      );
      
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
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              await _getCurrentLocation();
              setState(() {
                _expandedMarkerId = '';
                _isShowStoreInfo = false;
              });
              await _loadUserStamps();
              _createMarkers();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? _defaultLocation,
              zoom: 15.0,
            ),
            markers: _markers,
            onTap: (LatLng position) async {
              setState(() {
                _isShowStoreInfo = false;
                _expandedMarkerId = '';
              });
              await _loadUserStamps();
              _createMarkers();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
          ),
          
          // 検索バー
          _buildSearchBar(),
          
          // 店舗アイコン
          _buildStoreIcon(),
          
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
    final goldStamps = userStamp?['goldStamps'] ?? 0;
    
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
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
                      // スタンプ状況表示
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[700],
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ゴールドスタンプ: $goldStamps/1',
                              style: TextStyle(
                                color: Colors.amber[700],
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
                          // TODO: 店舗詳細画面へ遷移
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('店舗詳細画面は今後実装予定です')),
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
            // 閉じるボタン
            GestureDetector(
              onTap: () {
                setState(() {
                  _isShowStoreInfo = false;
                });
              },
              child: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 80,
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoreIcon() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 20,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.store,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Widget _buildMapControls() {
    return Positioned(
      bottom: 150,
      right: 20,
      child: Column(
        children: [
          // 現在位置ボタン
          GestureDetector(
            onTap: () async {
              await _getCurrentLocation();
              setState(() {
                _expandedMarkerId = '';
                _isShowStoreInfo = false;
              });
              await _loadUserStamps();
              _createMarkers();
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
          // 閉じるボタン
          GestureDetector(
            onTap: () async {
              setState(() {
                _expandedMarkerId = '';
                _isShowStoreInfo = false;
              });
              await _loadUserStamps();
              _createMarkers();
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
                Icons.close,
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
