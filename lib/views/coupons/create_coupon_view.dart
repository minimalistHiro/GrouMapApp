import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateCouponView extends StatefulWidget {
  const CreateCouponView({super.key});

  @override
  State<CreateCouponView> createState() => _CreateCouponViewState();
}

class _CreateCouponViewState extends State<CreateCouponView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _conditionsController = TextEditingController();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  File? _couponImage;
  Uint8List? _webImageBytes;
  String _discountType = '割引率';
  String? _selectedStoreId;
  String? _selectedStoreName;
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = false;
  int _maxUsagePerUser = 1; // 1ユーザーあたりの最大使用回数

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // Web用：バイトデータとして読み込み
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _couponImage = null;
          });
        } else {
          // モバイル用：Fileとして保存
          setState(() {
            _couponImage = File(image.path);
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '選択してください';
    return '${date.year}年${date.month}月${date.day}日';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '選択してください';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 店舗一覧を読み込み
  Future<void> _loadStores() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final storesSnapshot = await _firestore
          .collection('stores')
          .where('createdBy', isEqualTo: user.uid)
          .get();
      
      if (mounted) {
        setState(() {
          _stores = storesSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'name': doc.data()['name'] ?? '店舗名なし',
                  })
              .toList();
        });
      }
    } catch (e) {
      print('店舗読み込みエラー: $e');
    }
  }

  Future<void> _createCoupon() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('開始日、終了日、終了時刻を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }

      String? imageUrl;
      
      // 画像が選択されている場合はアップロード
      if (_couponImage != null || _webImageBytes != null) {
        try {
          // クーポンIDを先に生成
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          
          if (kIsWeb && _webImageBytes != null) {
            // Web用：バイトデータからアップロード
            imageUrl = await _uploadCouponImageBytes(_webImageBytes!, tempId);
          } else if (_couponImage != null) {
            // モバイル用：Fileからアップロード
            imageUrl = await _uploadCouponImage(_couponImage!, tempId);
          }
        } catch (e) {
          throw Exception('画像のアップロードに失敗しました: $e');
        }
      }

      // クーポンをFirestoreに保存
      final couponId = await _addCoupon(
        userId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue: _discountController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        endTime: _endTime!,
        conditions: _conditionsController.text.trim(),
        imageUrl: imageUrl,
        storeId: _selectedStoreId,
        storeName: _selectedStoreName,
        maxUsagePerUser: _maxUsagePerUser,
      );

      // 画像がアップロードされている場合は、実際のクーポンIDで再アップロード
      if ((_couponImage != null || _webImageBytes != null) && imageUrl != null) {
        try {
          // 一時的な画像を削除
          await _deleteImage(imageUrl);
          
          // 実際のクーポンIDで画像をアップロード
          String finalImageUrl;
          if (kIsWeb && _webImageBytes != null) {
            finalImageUrl = await _uploadCouponImageBytes(_webImageBytes!, couponId);
          } else if (_couponImage != null) {
            finalImageUrl = await _uploadCouponImage(_couponImage!, couponId);
          } else {
            return; // 画像が存在しない場合はスキップ
          }
          
          // Firestoreの画像URLを更新
          await _updateCouponImage(couponId, finalImageUrl);
        } catch (e) {
          // 画像の再アップロードに失敗しても、クーポン作成は成功とする
          print('画像の再アップロードに失敗しました: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('クーポンが作成されました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('クーポン作成に失敗しました: $e'),
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

  // クーポン画像をアップロード（バイトデータ）
  Future<String> _uploadCouponImageBytes(Uint8List imageBytes, String couponId) async {
    final user = _auth.currentUser!;
    final storageRef = _storage
        .ref()
        .child('coupons')
        .child('${user.uid}_$couponId.jpg');
    
    final uploadTask = storageRef.putData(imageBytes);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // クーポン画像をアップロード（File）
  Future<String> _uploadCouponImage(File imageFile, String couponId) async {
    final user = _auth.currentUser!;
    final storageRef = _storage
        .ref()
        .child('coupons')
        .child('${user.uid}_$couponId.jpg');
    
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // 画像を削除
  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('画像削除エラー: $e');
    }
  }

  // クーポンをFirestoreに追加
  Future<String> _addCoupon({
    required String userId,
    required String title,
    required String description,
    required String discountType,
    required String discountValue,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay endTime,
    required String conditions,
    String? imageUrl,
    String? storeId,
    String? storeName,
    required int maxUsagePerUser,
  }) async {
    final couponId = _firestore.collection('coupons').doc().id;
    
    // 終了日時を結合
    final endDateTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    await _firestore.collection('coupons').doc(couponId).set({
      'couponId': couponId,
      'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDateTime),
      'conditions': conditions,
      'imageUrl': imageUrl,
      'storeId': storeId,
      'storeName': storeName,
      'maxUsagePerUser': maxUsagePerUser,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'usageCount': 0,
      'totalUsageCount': 0,
    });

    return couponId;
  }

  // クーポンの画像URLを更新
  Future<void> _updateCouponImage(String couponId, String imageUrl) async {
    await _firestore.collection('coupons').doc(couponId).update({
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '新規クーポン作成',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // クーポン画像
                    _buildImageSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 基本情報
                    _buildBasicInfoSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 有効期限
                    _buildValiditySection(),
                    
                    const SizedBox(height: 24),
                    
                    // 利用条件
                    _buildConditionsSection(),
                    
                    const SizedBox(height: 40),
                    
                    // 作成ボタン
                    _buildCreateButton(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'クーポン画像',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: (_couponImage != null || _webImageBytes != null)
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb && _webImageBytes != null
                              ? Image.memory(
                                  _webImageBytes!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.error,
                                        size: 60,
                                        color: Colors.red,
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  _couponImage!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.error,
                                        size: 60,
                                        color: Colors.red,
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _couponImage = null;
                                _webImageBytes = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '画像を選択',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'タップして画像を選択',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // タイトル
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'クーポンタイトル *',
              hintText: '例：カレーケサディーヤ25%OFF',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF8F9FA),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'タイトルを入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 説明
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'クーポン説明 *',
              hintText: 'クーポンの詳細な説明を入力してください',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF8F9FA),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '説明を入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 割引タイプと値
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _discountType,
                  decoration: const InputDecoration(
                    labelText: '割引タイプ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                  ),
                  items: const [
                    DropdownMenuItem(value: '割引率', child: Text('割引率')),
                    DropdownMenuItem(value: '割引額', child: Text('割引額')),
                    DropdownMenuItem(value: '固定価格', child: Text('固定価格')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _discountType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _discountType == '割引率' ? '%' : '円',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '値を入力してください';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 店舗選択
          DropdownButtonFormField<String>(
            value: _selectedStoreId,
            decoration: const InputDecoration(
              labelText: '店舗を選択',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF8F9FA),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('店舗を選択してください'),
              ),
              ..._stores.map((store) => DropdownMenuItem(
                value: store['id'],
                child: Text(store['name'] ?? '店舗名なし'),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStoreId = value;
                _selectedStoreName = value != null 
                    ? _stores.firstWhere((store) => store['id'] == value)['name']
                    : null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValiditySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '有効期限',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // 開始日
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('開始日'),
            subtitle: Text(_formatDate(_startDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectStartDate,
          ),
          
          const Divider(),
          
          // 終了日
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('終了日'),
            subtitle: Text(_formatDate(_endDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectEndDate,
          ),
          
          const Divider(),
          
          // 終了時刻
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('終了時刻'),
            subtitle: Text(_formatTime(_endTime)),
            trailing: const Icon(Icons.access_time),
            onTap: _selectEndTime,
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '利用条件',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _conditionsController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '利用条件・注意事項',
              hintText: '例：\n・他のクーポンとの併用はできません\n・1回のご注文につき1枚までご利用いただけます\n・予告なく終了する場合があります',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF8F9FA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _createCoupon,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'クーポンを作成',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
