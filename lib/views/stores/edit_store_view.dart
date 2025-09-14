import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EditStoreView extends StatefulWidget {
  final String storeId;
  
  const EditStoreView({super.key, required this.storeId});

  @override
  State<EditStoreView> createState() => _EditStoreViewState();
}

class _EditStoreViewState extends State<EditStoreView> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _facebookController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String _selectedCategory = 'カフェ';
  bool _isLoading = false;
  bool _isLoadingStore = true;
  
  // 営業時間のコントローラー
  final Map<String, Map<String, TextEditingController>> _businessHoursControllers = {};
  final Map<String, bool> _businessDaysOpen = {};
  
  // タグのコントローラー
  final _tagsController = TextEditingController();
  List<String> _tags = [];
  
  // 店舗アイコン画像の状態
  File? _selectedIconImage;
  Uint8List? _webIconImageBytes;
  String? _iconImageUrl;
  
  // 店舗イメージ画像の状態
  File? _selectedStoreImage;
  Uint8List? _webStoreImageBytes;
  String? _storeImageUrl;
  
  // 位置情報の状態
  double? _selectedLatitude;
  double? _selectedLongitude;
  
  // 地図選択の状態
  LatLng? _selectedMapLocation;

  final List<String> _categories = [
    'カフェ',
    'レストラン',
    '居酒屋',
    'ファストフード',
    'スイーツ',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _initializeBusinessHoursControllers();
    _loadStoreData();
  }

  void _initializeBusinessHoursControllers() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (String day in days) {
      _businessHoursControllers[day] = {
        'open': TextEditingController(text: '09:00'),
        'close': TextEditingController(text: '18:00'),
      };
      _businessDaysOpen[day] = true;
    }
  }

  Future<void> _loadStoreData() async {
    try {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();
      
      if (storeDoc.exists) {
        final data = storeDoc.data()!;
        
        setState(() {
          _storeNameController.text = data['name'] ?? '';
          _addressController.text = data['address'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _selectedCategory = data['category'] ?? 'カフェ';
          _iconImageUrl = data['iconImageUrl'];
          _storeImageUrl = data['storeImageUrl'];
          _selectedLatitude = data['location']?['latitude'] ?? 35.6581;
          _selectedLongitude = data['location']?['longitude'] ?? 139.7017;
          _selectedMapLocation = LatLng(_selectedLatitude!, _selectedLongitude!);
          _tags = List<String>.from(data['tags'] ?? []);
          
          // 営業時間の設定
          final businessHours = data['businessHours'] ?? {};
          for (String day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']) {
            final dayData = businessHours[day] ?? {};
            _businessHoursControllers[day]!['open']!.text = dayData['open'] ?? '09:00';
            _businessHoursControllers[day]!['close']!.text = dayData['close'] ?? '18:00';
            _businessDaysOpen[day] = dayData['isOpen'] ?? true;
          }
          
          // SNS情報の設定
          final socialMedia = data['socialMedia'] ?? {};
          _websiteController.text = socialMedia['website'] ?? '';
          _instagramController.text = socialMedia['instagram'] ?? '';
          _xController.text = socialMedia['x'] ?? '';
          _facebookController.text = socialMedia['facebook'] ?? '';
          
          _updateLocationControllers();
          _isLoadingStore = false;
        });
      } else {
        setState(() {
          _isLoadingStore = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('店舗情報が見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingStore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗情報の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _updateLocationControllers() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      _latitudeController.text = _selectedLatitude!.toStringAsFixed(6);
      _longitudeController.text = _selectedLongitude!.toStringAsFixed(6);
    }
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // 地図から位置を選択するダイアログを表示
  Future<void> _showMapLocationPicker() async {
    final result = await showDialog<LatLng>(
      context: context,
      builder: (BuildContext context) {
        return MapLocationPickerDialog(
          initialLocation: _selectedMapLocation ?? const LatLng(35.6581, 139.7017),
        );
      },
    );
    
    if (result != null) {
      setState(() {
        _selectedMapLocation = result;
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;
        _updateLocationControllers();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('位置を選択しました: ${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // 店舗アイコン画像を選択
  Future<void> _pickIconImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webIconImageBytes = bytes;
            _selectedIconImage = null;
          });
        } else {
          setState(() {
            _selectedIconImage = File(image.path);
            _webIconImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 店舗イメージ画像を選択
  Future<void> _pickStoreImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webStoreImageBytes = bytes;
            _selectedStoreImage = null;
          });
        } else {
          setState(() {
            _selectedStoreImage = File(image.path);
            _webStoreImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗イメージ画像選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 店舗アイコン画像をアップロード
  Future<String?> _uploadIconImage() async {
    if (_selectedIconImage == null && _webIconImageBytes == null) return _iconImageUrl;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');
      
      String downloadUrl;
      
      if (kIsWeb && _webIconImageBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('store_icons')
            .child('${user.uid}_${widget.storeId}.jpg');
        
        final uploadTask = storageRef.putData(_webIconImageBytes!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else if (_selectedIconImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('store_icons')
            .child('${user.uid}_${widget.storeId}.jpg');
        
        final uploadTask = storageRef.putFile(_selectedIconImage!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        return _iconImageUrl;
      }
      
      setState(() {
        _iconImageUrl = downloadUrl;
      });
      
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像アップロードエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return _iconImageUrl;
    }
  }
  
  // 店舗イメージ画像をアップロード
  Future<String?> _uploadStoreImage() async {
    if (_selectedStoreImage == null && _webStoreImageBytes == null) return _storeImageUrl;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');
      
      String downloadUrl;
      
      if (kIsWeb && _webStoreImageBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('store_images')
            .child('${user.uid}_${widget.storeId}.jpg');
        
        final uploadTask = storageRef.putData(_webStoreImageBytes!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else if (_selectedStoreImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('store_images')
            .child('${user.uid}_${widget.storeId}.jpg');
        
        final uploadTask = storageRef.putFile(_selectedStoreImage!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        return _storeImageUrl;
      }
      
      setState(() {
        _storeImageUrl = downloadUrl;
      });
      
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗イメージ画像アップロードエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return _storeImageUrl;
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _facebookController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tagsController.dispose();
    
    for (var controllers in _businessHoursControllers.values) {
      controllers['open']?.dispose();
      controllers['close']?.dispose();
    }
    
    super.dispose();
  }

  Future<void> _updateStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 画像をアップロード
      final iconImageUrl = await _uploadIconImage();
      final storeImageUrl = await _uploadStoreImage();

      // Firestoreに店舗情報を更新
      await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).update({
        'name': _storeNameController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
        'iconImageUrl': iconImageUrl,
        'storeImageUrl': storeImageUrl,
        'location': {
          'latitude': _selectedLatitude ?? 0.0,
          'longitude': _selectedLongitude ?? 0.0,
        },
        'businessHours': {
          'monday': {
            'open': _businessHoursControllers['monday']!['open']!.text,
            'close': _businessHoursControllers['monday']!['close']!.text,
            'isOpen': _businessDaysOpen['monday'] ?? false
          },
          'tuesday': {
            'open': _businessHoursControllers['tuesday']!['open']!.text,
            'close': _businessHoursControllers['tuesday']!['close']!.text,
            'isOpen': _businessDaysOpen['tuesday'] ?? false
          },
          'wednesday': {
            'open': _businessHoursControllers['wednesday']!['open']!.text,
            'close': _businessHoursControllers['wednesday']!['close']!.text,
            'isOpen': _businessDaysOpen['wednesday'] ?? false
          },
          'thursday': {
            'open': _businessHoursControllers['thursday']!['open']!.text,
            'close': _businessHoursControllers['thursday']!['close']!.text,
            'isOpen': _businessDaysOpen['thursday'] ?? false
          },
          'friday': {
            'open': _businessHoursControllers['friday']!['open']!.text,
            'close': _businessHoursControllers['friday']!['close']!.text,
            'isOpen': _businessDaysOpen['friday'] ?? false
          },
          'saturday': {
            'open': _businessHoursControllers['saturday']!['open']!.text,
            'close': _businessHoursControllers['saturday']!['close']!.text,
            'isOpen': _businessDaysOpen['saturday'] ?? false
          },
          'sunday': {
            'open': _businessHoursControllers['sunday']!['open']!.text,
            'close': _businessHoursControllers['sunday']!['close']!.text,
            'isOpen': _businessDaysOpen['sunday'] ?? false
          },
        },
        'tags': _tags,
        'socialMedia': {
          'instagram': _instagramController.text.trim(),
          'x': _xController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'website': _websiteController.text.trim(),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('店舗情報を更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗情報の更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStore) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('店舗情報変更', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFFFF6B35),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('店舗情報変更', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(15)),
                child: const Column(
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text('店舗情報を変更', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('店舗情報を更新しましょう', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 店舗名
              _buildInputField(controller: _storeNameController, label: '店舗名 *', hint: '例：GrouMap店舗', icon: Icons.store, validator: (value) {
                if (value == null || value.trim().isEmpty) return '店舗名を入力してください';
                if (value.trim().length < 2) return '店舗名は2文字以上で入力してください';
                return null;
              }),
              
              const SizedBox(height: 20),
              
              // カテゴリ
              _buildCategoryDropdown(),
              
              const SizedBox(height: 20),
              
              // 店舗アイコン画像
              _buildIconImageSection(),
              
              const SizedBox(height: 20),
              
              // 店舗イメージ画像
              _buildStoreImageSection(),
              
              const SizedBox(height: 20),
              
              // 住所
              _buildInputField(controller: _addressController, label: '住所 *', hint: '例：埼玉県川口市芝5-5-13', icon: Icons.location_on, validator: (value) {
                if (value == null || value.trim().isEmpty) return '住所を入力してください';
                return null;
              }),
              
              const SizedBox(height: 20),
              
              // 電話番号
              _buildInputField(controller: _phoneController, label: '電話番号', hint: '例：03-1234-5678', icon: Icons.phone, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 20),
              
              // 店舗説明
              _buildInputField(controller: _descriptionController, label: '店舗説明', hint: '店舗の特徴や魅力を説明してください', icon: Icons.description, maxLines: 4),
              
              const SizedBox(height: 20),
              
              // 位置情報
              _buildLocationSection(),
              
              const SizedBox(height: 20),
              
              // 営業時間
              _buildBusinessHoursSection(),
              
              const SizedBox(height: 20),
              
              // タグ
              _buildTagsSection(),
              
              const SizedBox(height: 20),
              
              // SNS・ウェブサイト
              _buildSocialMediaSection(),
              
              const SizedBox(height: 32),
              
              // 更新ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateStore,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('店舗情報を更新', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String hint, required IconData icon, String? Function(String?)? validator, TextInputType? keyboardType, int maxLines = 1, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('カテゴリ *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              items: _categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _selectedCategory = newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('店舗アイコン画像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: Column(
            children: [
              if (_selectedIconImage != null || _webIconImageBytes != null || _iconImageUrl != null)
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(60), border: Border.all(color: Colors.grey[300]!)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: _selectedIconImage != null
                        ? (kIsWeb ? Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 40, color: Colors.grey)) : Image.file(_selectedIconImage!, fit: BoxFit.cover))
                        : _webIconImageBytes != null
                            ? Image.memory(_webIconImageBytes!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 40, color: Colors.grey)))
                            : _iconImageUrl != null
                                ? Image.network(_iconImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 40, color: Colors.grey)))
                                : null,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickIconImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('画像を選択'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              const SizedBox(height: 8),
              Text('推奨サイズ: 512x512px、JPG形式', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStoreImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('店舗イメージ画像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: Column(
            children: [
              if (_selectedStoreImage != null || _webStoreImageBytes != null || _storeImageUrl != null)
                Container(
                  width: 400,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedStoreImage != null
                        ? (kIsWeb ? Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 60, color: Colors.grey)) : Image.file(_selectedStoreImage!, fit: BoxFit.cover))
                        : _webStoreImageBytes != null
                            ? Image.memory(_webStoreImageBytes!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 60, color: Colors.grey)))
                            : _storeImageUrl != null
                                ? Image.network(_storeImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 60, color: Colors.grey)))
                                : null,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickStoreImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('店舗イメージ画像を選択'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              const SizedBox(height: 8),
              Text('推奨サイズ: 1600x800px（2:1比率）、JPG形式', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('位置情報', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildInputField(controller: _latitudeController, label: '緯度', hint: '例：35.6581', icon: Icons.location_on, keyboardType: TextInputType.number, readOnly: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField(controller: _longitudeController, label: '経度', hint: '例：139.7017', icon: Icons.location_on, keyboardType: TextInputType.number, readOnly: true)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showMapLocationPicker,
            icon: const Icon(Icons.map, size: 18),
            label: const Text('地図から読み取る'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        if (_selectedLatitude != null && _selectedLongitude != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withOpacity(0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 16), const SizedBox(width: 8), const Text('位置が設定されました', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))]),
                const SizedBox(height: 4),
                Text('緯度: ${_selectedLatitude!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontFamily: 'monospace')),
                Text('経度: ${_selectedLongitude!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('営業時間', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: Column(
            children: [
              _buildBusinessDayRow('月曜日', 'monday'),
              const Divider(),
              _buildBusinessDayRow('火曜日', 'tuesday'),
              const Divider(),
              _buildBusinessDayRow('水曜日', 'wednesday'),
              const Divider(),
              _buildBusinessDayRow('木曜日', 'thursday'),
              const Divider(),
              _buildBusinessDayRow('金曜日', 'friday'),
              const Divider(),
              _buildBusinessDayRow('土曜日', 'saturday'),
              const Divider(),
              _buildBusinessDayRow('日曜日', 'sunday'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessDayRow(String dayName, String dayKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(dayName, style: const TextStyle(fontSize: 14))),
          Switch(value: _businessDaysOpen[dayKey] ?? true, onChanged: (value) => setState(() => _businessDaysOpen[dayKey] = value), activeColor: const Color(0xFFFF6B35)),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTimePicker(controller: _businessHoursControllers[dayKey]!['open']!, enabled: _businessDaysOpen[dayKey] ?? true, label: '開店時間')),
                const SizedBox(width: 8),
                const Text('〜'),
                const SizedBox(width: 8),
                Expanded(child: _buildTimePicker(controller: _businessHoursControllers[dayKey]!['close']!, enabled: _businessDaysOpen[dayKey] ?? true, label: '閉店時間')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({required TextEditingController controller, required bool enabled, required String label}) {
    return GestureDetector(
      onTap: enabled ? () => _showTimePickerDialog(controller) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8), color: enabled ? Colors.white : Colors.grey[100]),
        child: Row(
          children: [
            Expanded(child: Text(controller.text.isEmpty ? '時間を選択' : controller.text, style: TextStyle(fontSize: 14, color: enabled ? Colors.black87 : Colors.grey[600]))),
            if (enabled) const Icon(Icons.access_time, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showTimePickerDialog(TextEditingController controller) {
    TimeOfDay currentTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2) {
          currentTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (e) {}
    }

    int selectedHour = currentTime.hour;
    int selectedMinute = currentTime.minute;
    selectedMinute = (selectedMinute / 5).round() * 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('時間を選択'),
              content: SizedBox(
                height: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        diameterRatio: 1.5,
                        controller: FixedExtentScrollController(initialItem: selectedHour),
                        onSelectedItemChanged: (index) => setDialogState(() => selectedHour = index),
                        children: List.generate(24, (index) => Center(
                          child: Text('${index.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 20, fontWeight: selectedHour == index ? FontWeight.bold : FontWeight.normal, color: selectedHour == index ? const Color(0xFFFF6B35) : Colors.black87)),
                        )),
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        diameterRatio: 1.5,
                        controller: FixedExtentScrollController(initialItem: selectedMinute ~/ 5),
                        onSelectedItemChanged: (index) => setDialogState(() => selectedMinute = index * 5),
                        children: List.generate(12, (index) {
                          final minute = index * 5;
                          return Center(
                            child: Text('${minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 20, fontWeight: selectedMinute == minute ? FontWeight.bold : FontWeight.normal, color: selectedMinute == minute ? const Color(0xFFFF6B35) : Colors.black87)),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
                TextButton(
                  onPressed: () {
                    final timeString = '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                    controller.text = timeString;
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('タグ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(hintText: '例：カフェ、本屋、Wi-Fi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('追加'),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeTag(tag),
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SNS・ウェブサイト', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        _buildInputField(controller: _websiteController, label: 'ウェブサイト', hint: '例：https://example.com', icon: Icons.language),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInputField(controller: _instagramController, label: 'Instagram', hint: '例：https://instagram.com/username', icon: Icons.camera_alt)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField(controller: _xController, label: 'X (Twitter)', hint: '例：https://x.com/username', icon: Icons.flutter_dash)),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField(controller: _facebookController, label: 'Facebook', hint: '例：https://facebook.com/page', icon: Icons.facebook),
      ],
    );
  }
}

// 地図位置選択ダイアログ
class MapLocationPickerDialog extends StatefulWidget {
  final LatLng initialLocation;
  
  const MapLocationPickerDialog({
    super.key,
    required this.initialLocation,
  });

  @override
  State<MapLocationPickerDialog> createState() => _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState extends State<MapLocationPickerDialog> {
  late MapController _mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '位置を選択してください',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // 地図
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? const LatLng(35.6581, 139.7017),
                  initialZoom: 15.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLocation = point;
                    });
                  },
                ),
                children: [
                  // タイルレイヤー
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.groumapapp',
                    additionalOptions: const {
                      'attribution': '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                    },
                  ),
                  
                  // マーカーレイヤー
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF6B35),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // 選択された位置情報表示
            if (_selectedLocation != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFFF6B35), size: 20),
                        const SizedBox(width: 8),
                        const Text('選択された位置:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '緯度: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '経度: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // ボタン
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedLocation != null
                          ? () => Navigator.of(context).pop(_selectedLocation)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('確定'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
