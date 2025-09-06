import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapView extends StatefulWidget {
  final String? selectedStoreId;
  
  const MapView({
    super.key,
    this.selectedStoreId,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool _isShowStoreInfo = false;
  String _selectedStoreUid = '';
  final double _defaultButtonSize = 70;
  final double _buttonSize = 70;
  String _expandedMarkerId = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static final LatLng _defaultLocation = LatLng(35.6812, 139.7671);
  LatLng _currentLocation = _defaultLocation;
  
  List<Marker> _markers = [];
  final MapController _mapController = MapController();
  
  List<Map<String, dynamic>> _stores = [];
  
  Map<String, Map<String, dynamic>> _userStamps = {};

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }
  
  Future<void> _initializeMapData() async {
    await Future.wait([
      _getCurrentLocation(),
      _loadStoresFromDatabase(),
    ]);
    
    if (widget.selectedStoreId != null) {
      _selectStoreOnMap(widget.selectedStoreId!);
    }
  }
  
  Future<void> _loadStoresFromDatabase() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('stores').get();
      final List<Map<String, dynamic>> stores = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isActive'] == true && data['isApproved'] == true) {
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
      
      await _loadUserStamps();
      _createMarkers();
    } catch (e) {
      print('店舗データの読み込みに失敗しました: $e');
    }
  }

  Future<void> _loadUserStamps() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final QuerySnapshot snapshot = await _firestore
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
      
      _updateStoreFlowerTypes();
    } catch (e) {
      print('ユーザースタンプデータの読み込みに失敗しました: $e');
    }
  }

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

  Future<void> _getCurrentLocation() async {
    try {
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
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_currentLocation, 15.0);
        });
      }
    } catch (e) {
      print('現在地の取得に失敗しました: $e');
    }
  }
  
  Widget _buildCustomCoinIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowerMarker(Map<String, dynamic> store, bool isExpanded) {
    final String flowerType = store['flowerType'];
    
    Widget flowerIcon;
    Color flowerColor;
    String flowerLabel;
    
    switch (flowerType) {
      case 'gold':
        flowerIcon = _buildCustomCoinIcon(isExpanded ? 35 : 25);
        flowerColor = Colors.amber;
        flowerLabel = 'ゴールドスタンプ';
        break;
      case 'unvisited':
        flowerIcon = Icon(Icons.radio_button_unchecked, color: Colors.white, size: isExpanded ? 35 : 25);
        flowerColor = Colors.grey;
        flowerLabel = '未訪問';
        break;
      default:
        flowerIcon = Icon(Icons.help_outline, color: Colors.white, size: isExpanded ? 35 : 25);
        flowerColor = Colors.grey;
        flowerLabel = '不明';
    }
    
    return Container(
      width: isExpanded ? 80 : 50,
      height: isExpanded ? 80 : 50,
      decoration: BoxDecoration(
        color: flowerColor.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isExpanded ? 4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: flowerColor.withOpacity(0.4),
            blurRadius: isExpanded ? 15 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          flowerIcon,
          if (isExpanded) ...[
            const SizedBox(height: 2),
            Text(
              flowerLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _createMarkers() {
    _markers = [
      Marker(
        point: _currentLocation,
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
    ];

    for (final store in _stores) {
      final bool isExpanded = _expandedMarkerId == store['id'];
      final String storeId = store['id'];
      
      _markers.add(
        Marker(
          point: store['position'],
          width: isExpanded ? 80 : 50,
          height: isExpanded ? 80 : 50,
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
                _createMarkers();
              });
            },
            child: _buildFlowerMarker(store, isExpanded),
          ),
        ),
      );
    }
  }

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
      
      _mapController.move(store['position'], 16.0);
      
      _createMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              onTap: (_, __) async {
                setState(() {
                  _isShowStoreInfo = false;
                  _expandedMarkerId = '';
                });
                await _loadUserStamps();
                _createMarkers();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          
          _buildSearchBar(),
          
          _buildStoreIcon(),
          
          if (_isShowStoreInfo) _buildStoreInfoCard(),
          
          _buildMapControls(),
        ],
      ),
    );
  }

  Widget _buildStoreInfoCard() {
    final selectedStore = _stores.firstWhere(
      (store) => store['id'] == _selectedStoreUid,
      orElse: () => {},
    );
    
    if (selectedStore.isEmpty) return const SizedBox.shrink();
    
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
                  Row(
                    children: [
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
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
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
                      GestureDetector(
                        onTap: () {
                          print('店舗詳細に遷移: $_selectedStoreUid');
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