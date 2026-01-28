import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';

class StampPunchView extends StatefulWidget {
  final String storeId;
  final int? paid; // 支払額（ExperienceGainedView へ受け渡し）
  final int? pointsAwarded; // ポイント付与によるXP表示用（付与済み）

  const StampPunchView({Key? key, required this.storeId, this.paid, this.pointsAwarded}) : super(key: key);

  @override
  State<StampPunchView> createState() => _StampPunchViewState();
}

class _StampPunchViewState extends State<StampPunchView>
    with TickerProviderStateMixin {
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
  // Shine effect for “スタンプコンプリート”
  late final AnimationController _shineController;
  late final Animation<double> _shineAnim;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shineController, curve: Curves.linear));
    _initialize();
  }

  @override
  void dispose() {
    _shineController.dispose();
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

      // ignore: avoid_print
      print('[StampPunchDebug] _initialize: uid=${user.uid}, storeId=${widget.storeId}');

      // 店舗情報取得
      // ignore: avoid_print
      print('[StampPunchDebug] fetch store doc: stores/${widget.storeId}');
      final storeSnap = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();
      // ignore: avoid_print
      print('[StampPunchDebug] store exists=${storeSnap.exists}');
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
      // ignore: avoid_print
      print('[StampPunchDebug] fetch user store doc: users/${user.uid}/stores/${widget.storeId}');
      final userStoreSnap = await userStoreRef.get();
      if (userStoreSnap.exists) {
        final d = userStoreSnap.data() as Map<String, dynamic>;
        _stamps = (d['stamps'] as int?) ?? 0;
        // ignore: avoid_print
        print('[StampPunchDebug] current stamps=$_stamps');
      } else {
        // 初期作成
        try {
          await userStoreRef.set({
            'stamps': 0,
            'lastVisited': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          // ignore: avoid_print
          print('[StampPunchDebug] initialized user store doc with stamps=0');
        } on FirebaseException catch (fe) {
          // ignore: avoid_print
          print('[StampPunchDebug][ERROR] init user store set failed code=${fe.code} message=${fe.message}');
          rethrow;
        }
        _stamps = 0;
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
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
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: '閉じる',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
      child: Stack(
        children: [
          Container(
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

                          return base;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_stamps >= _maxStamps)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shineAnim,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Color(0xFF9C27B0),
                              Color(0xFFFFD54F),
                              Color(0xFF9C27B0),
                            ],
                            stops: [
                              (_shineAnim.value - 0.2).clamp(0.0, 1.0),
                              (_shineAnim.value).clamp(0.0, 1.0),
                              (_shineAnim.value + 0.2).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: const Text(
                          'スタンプコンプリート',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
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
