import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StampPunchView extends StatefulWidget {
  final String storeId;

  const StampPunchView({Key? key, required this.storeId}) : super(key: key);

  @override
  State<StampPunchView> createState() => _StampPunchViewState();
}

class _StampPunchViewState extends State<StampPunchView>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  // Store data
  String _storeName = '店舗名';
  String _storeCategory = 'その他';
  String? _iconImageUrl;

  // User stamp data
  int _stamps = 0;
  static const int _maxStamps = 10;

  // Animation
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  int? _punchIndex; // 追加されたスタンプのインデックス

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.2, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_animController);
    _initialize();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'ログインが必要です';
          _loading = false;
        });
        return;
      }

      // 店舗情報取得
      final storeSnap = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();
      if (storeSnap.exists) {
        final s = storeSnap.data() as Map<String, dynamic>;
        _storeName = (s['name'] as String?) ?? _storeName;
        _storeCategory = (s['category'] as String?) ?? _storeCategory;
        _iconImageUrl = s['iconImageUrl'] as String?;
      }

      // ユーザーのスタンプ情報取得（users/{uid}/stores/{storeId}）
      final userStoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId);
      final userStoreSnap = await userStoreRef.get();
      if (userStoreSnap.exists) {
        final d = userStoreSnap.data() as Map<String, dynamic>;
        _stamps = (d['stamps'] as int?) ?? 0;
      } else {
        // 初期作成
        await userStoreRef.set({
          'stamps': 0,
          'lastVisited': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _stamps = 0;
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      // 自動で1つ押印
      await _punchOneStamp();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _punchOneStamp() async {
    if (_stamps >= _maxStamps) return; // 既に満了
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userStoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.storeId);

      // Firestoreを先に更新
      await userStoreRef.update({
        'stamps': FieldValue.increment(1),
        'lastVisited': FieldValue.serverTimestamp(),
      });

      final newIndex = _stamps; // 新規に増える場所
      setState(() {
        _stamps = _stamps + 1;
        _punchIndex = newIndex;
      });

      // アニメーション
      await _animController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _punchIndex = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('スタンプ押印に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('スタンプ押印'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _stamps < _maxStamps ? _punchOneStamp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('もう一つ押印'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text('エラー: $_error'),
      );
    }

    final progress = _stamps / _maxStamps;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCategoryColor(_storeCategory).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_storeCategory).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getCategoryColor(_storeCategory).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: _buildStoreIcon(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _storeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(_storeCategory).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _storeCategory,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(_storeCategory),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_stamps/$_maxStamps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(_storeCategory),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _maxStamps,
                    itemBuilder: (context, index) {
                      final hasStamp = index < _stamps;
                      final isPunched = _punchIndex != null && index == _punchIndex;
                      final base = Container(
                        decoration: BoxDecoration(
                          color: hasStamp
                              ? _getCategoryColor(_storeCategory)
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasStamp
                                ? _getCategoryColor(_storeCategory).withOpacity(0.7)
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: hasStamp
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
                        ),
                      );

                      if (isPunched) {
                        return ScaleTransition(scale: _scaleAnim, child: base);
                      }
                      return base;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreIcon() {
    if (_iconImageUrl != null && _iconImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _iconImageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getCategoryIcon(_storeCategory),
              color: _getCategoryColor(_storeCategory),
              size: 25,
            );
          },
        ),
      );
    }
    return Icon(
      _getCategoryIcon(_storeCategory),
      color: _getCategoryColor(_storeCategory),
      size: 25,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'レストラン':
        return Colors.red;
      case 'カフェ':
        return Colors.brown;
      case 'ショップ':
        return Colors.blue;
      case '美容院':
        return Colors.pink;
      case '薬局':
        return Colors.green;
      case 'コンビニ':
        return Colors.orange;
      case 'スーパー':
        return Colors.lightGreen;
      case '書店':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'レストラン':
        return Icons.restaurant;
      case 'カフェ':
        return Icons.local_cafe;
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
}


