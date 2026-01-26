import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointPaymentDetailView extends StatefulWidget {
  final String storeId;
  final int paid;
  final int pointsAwarded;
  final int pointsUsed;

  const PointPaymentDetailView({
    Key? key,
    required this.storeId,
    required this.paid,
    required this.pointsAwarded,
    required this.pointsUsed,
  }) : super(key: key);

  @override
  State<PointPaymentDetailView> createState() => _PointPaymentDetailViewState();
}

class _PointPaymentDetailViewState extends State<PointPaymentDetailView>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  String _storeName = '店舗名';
  String _storeCategory = 'その他';
  String? _iconImageUrl;
  int _stamps = 0;
  int _displayStamps = 0;
  bool _isSyncing = false;
  static const int _maxStamps = 10;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _shineController;
  late final Animation<double> _shineAnim;
  int? _punchIndex;
  bool _shouldAnimatePunch = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userStoreSub;

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
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shineController, curve: Curves.linear));
    _loadStampData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _shineController.dispose();
    _userStoreSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStampData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'ログインが必要です';
          _loading = false;
        });
        return;
      }

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
        await userStoreRef.set({
          'stamps': 0,
          'lastVisited': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _stamps = 0;
      }
      _displayStamps = _stamps;

      await _loadPunchAnimationState(user.uid);
      _startUserStoreListener(user.uid);

      if (mounted) {
        setState(() {
          _loading = false;
        });
        if (_shouldAnimatePunch && _punchIndex != null) {
          await _animController.forward(from: 0.0);
        }
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

  void _startUserStoreListener(String userId) {
    _userStoreSub?.cancel();
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('stores')
        .doc(widget.storeId);
    _userStoreSub = ref.snapshots().listen((snap) {
      if (!mounted || !snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final actual = (data['stamps'] as int?) ?? 0;
      setState(() {
        _stamps = actual;
        if (_displayStamps < actual) {
          _displayStamps = actual;
        }
        if (_isSyncing && actual >= _displayStamps) {
          _isSyncing = false;
        }
      });
    });
  }

  Future<void> _loadPunchAnimationState(String userId) async {
    try {
      final eventsSnap = await FirebaseFirestore.instance
          .collection('user_achievement_events')
          .doc(userId)
          .collection('events')
          .where('type', isEqualTo: 'point_award')
          .where('storeId', isEqualTo: widget.storeId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (eventsSnap.docs.isEmpty) return;

      final data = eventsSnap.docs.first.data();
      final stampsAdded = (data['stampsAdded'] is num) ? (data['stampsAdded'] as num).toInt() : 0;
      final stampsAfter = (data['stampsAfter'] is num) ? (data['stampsAfter'] as num).toInt() : _stamps;
      if (stampsAdded <= 0) return;
      if (stampsAfter <= 0) return;

      _displayStamps = stampsAfter;
      _isSyncing = stampsAfter > _stamps;
      _punchIndex = (stampsAfter - 1).clamp(0, _maxStamps - 1);
      _shouldAnimatePunch = true;
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('お支払いの詳細'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ご利用内容',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('利用ポイント', '${widget.pointsUsed}pt'),
                  const SizedBox(height: 12),
                  _buildDetailRow('獲得ポイント', '${widget.pointsAwarded}pt'),
                  const SizedBox(height: 12),
                  _buildDetailRow('支払い金額', '${widget.paid}円'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStampCard(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  '完了',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStampCard() {
    if (_loading) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('スタンプ取得に失敗しました: $_error'),
        ),
      );
    }

    final progress = _stamps / _maxStamps;
    final displayProgress = _displayStamps / _maxStamps;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              Row(
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
                        if (_isSyncing) ...[
                          const SizedBox(height: 4),
                          const Text(
                            '更新中...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                      '$_displayStamps/$_maxStamps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: displayProgress,
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
                  final hasStamp = index < _displayStamps;
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
                  final isPunched = _shouldAnimatePunch && _punchIndex == index;
                  if (isPunched) {
                    return ScaleTransition(scale: _scaleAnim, child: base);
                  }
                  return base;
                },
              ),
            ],
          ),
        ),
        if (_displayStamps >= _maxStamps)
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
