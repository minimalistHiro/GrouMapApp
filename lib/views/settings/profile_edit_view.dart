import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';

class ProfileEditView extends ConsumerStatefulWidget {
  const ProfileEditView({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends ConsumerState<ProfileEditView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _friendCodeController = TextEditingController();
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // 画像関連
  XFile? _selectedImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  // ユーザー情報
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedPrefecture;
  String? _selectedCity;
  List<String> _cities = [];

  final List<String> _genders = ['男性', '女性', 'その他', '回答しない'];
  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final authService = ref.read(authServiceProvider);
      final doc = await authService.getUserInfo();
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _displayNameController.text = (data['displayName'] ?? '').toString();
        _friendCodeController.text = (data['friendCode'] ?? data['friendcode'] ?? '').toString();
        _profileImageUrl = (data['profileImageUrl'] ?? '').toString();

        final birthDate = data['birthDate'];
        if (birthDate != null) {
          if (birthDate is Timestamp) {
            _selectedDate = birthDate.toDate();
          } else if (birthDate is DateTime) {
            _selectedDate = birthDate;
          } else if (birthDate is String) {
            try {
              _selectedDate = DateTime.tryParse(birthDate);
            } catch (_) {}
          }
        }

        _selectedGender = (data['gender'] as String?)?.isNotEmpty == true ? data['gender'] : null;
        _selectedPrefecture = (data['prefecture'] as String?)?.isNotEmpty == true ? data['prefecture'] : null;
        _selectedCity = (data['city'] as String?)?.isNotEmpty == true ? data['city'] : null;

        if (_selectedPrefecture != null) {
          await _loadCitiesForPrefecture(_selectedPrefecture!);
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final newDisplayName = _displayNameController.text.trim();
      final friendCode = _friendCodeController.text.trim();

      final updateData = <String, dynamic>{
        'displayName': newDisplayName,
        'birthDate': _selectedDate,
        'gender': _selectedGender,
        'prefecture': _selectedPrefecture,
        'city': _selectedCity,
        'profileImageUrl': _profileImageUrl,
        'friendCode': friendCode,
        'friendcode': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await ref.read(authServiceProvider).updateUserInfo(updateData);

      final user = ref.read(authServiceProvider).currentUser;
      await user?.updateDisplayName(newDisplayName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('プロフィールを更新しました'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 画像表示
  Widget _buildProfileImageWidget() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildSelectedImageWidget();
        },
      );
    }
    return _buildSelectedImageWidget();
  }

  Widget _buildSelectedImageWidget() {
    if (_selectedImage == null) {
      return Container(
        width: 120,
        height: 120,
        color: Colors.grey[300],
        child: const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    }
    return FutureBuilder<Uint8List>(
      future: _selectedImage!.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          );
        }
        if (snapshot.hasError) {
          return Container(
            width: 120,
            height: 120,
            color: Colors.grey[300],
            child: const Icon(Icons.person, size: 60, color: Colors.grey),
          );
        }
        return Container(
          width: 120,
          height: 120,
          color: Colors.grey[300],
          child: const CircularProgressIndicator(color: Color(0xFFFF6B35)),
        );
      },
    );
  }

  // 画像選択/アップロード
  Future<void> _selectProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        await _uploadImageToFirebase(image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadImageToFirebase(XFile imageFile) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final bytes = await imageFile.readAsBytes();
      final snapshot = await storageRef.putData(bytes);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像のアップロードに失敗しました: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 生年月日選択
  Future<void> _selectDate(BuildContext context) async {
    final DateTime initial = _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 20));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ja', 'JP'),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ja', 'JP'),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFF6B35),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 市区町村ロード（簡易）
  Future<void> _loadCitiesForPrefecture(String prefecture) async {
    setState(() {
      _cities = [];
    });
    _loadFallbackCities(prefecture);
  }

  void _loadFallbackCities(String prefecture) {
    List<String> cities = [];
    switch (prefecture) {
      case '東京都':
        cities = ['千代田区', '中央区', '港区', '新宿区', '渋谷区', '豊島区', '世田谷区'];
        break;
      case '大阪府':
        cities = ['大阪市', '堺市', '豊中市', '吹田市', '高槻市', '東大阪市'];
        break;
      case '埼玉県':
        cities = ['さいたま市', '川越市', '川口市', '所沢市', '越谷市'];
        break;
      default:
        cities = ['市区町村を選択'];
    }
    setState(() {
      _cities = cities;
      if (_selectedCity == null || !_cities.contains(_selectedCity)) {
        _selectedCity = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '表示名',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _displayNameController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: '表示名を入力',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                    ),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return '表示名を入力してください';
                    if (value.length < 2) return '2文字以上で入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 生年月日
                const Text('生年月日', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.year}年${_selectedDate!.month}月${_selectedDate!.day}日'
                              : '生年月日を選択',
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.black : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 性別
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: '性別',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: _genders.map((g) => DropdownMenuItem<String>(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 16),

                // 都道府県
                DropdownButtonFormField<String>(
                  value: _selectedPrefecture,
                  decoration: InputDecoration(
                    labelText: '都道府県',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: _prefectures.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
                  onChanged: (v) async {
                    setState(() {
                      _selectedPrefecture = v;
                      _selectedCity = null;
                    });
                    if (v != null) await _loadCitiesForPrefecture(v);
                  },
                ),
                const SizedBox(height: 16),

                // 市区町村
                if (_selectedPrefecture != null)
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: InputDecoration(
                      labelText: '市区町村',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _cities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCity = v),
                  ),
                if (_selectedPrefecture != null) const SizedBox(height: 16),

                // 紹介コード
                TextFormField(
                  controller: _friendCodeController,
                  decoration: InputDecoration(
                    labelText: '友だち紹介コード（任意）',
                    hintText: '紹介コードがあれば入力',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // プロフィール画像
                const Text('プロフィール画像（任意）', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _selectProfileImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: _isUploadingImage
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                          : ClipOval(child: _buildProfileImageWidget()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '保存',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F7F7),
    );
  }
}

// 画像/日付/住所補助メソッド（削除済み拡張）


