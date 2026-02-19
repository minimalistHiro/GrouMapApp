import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_navigation_view.dart';
import '../../widgets/stamp_card_widget.dart';

class PointPaymentDetailView extends StatefulWidget {
  final String storeId;
  final int paid;
  final int pointsAwarded;
  final int pointsUsed;
  final List<String> usedCouponIds;
  final int? normalPointsAwarded;
  final int? specialPointsAwarded;
  final bool popOnComplete;

  const PointPaymentDetailView({
    Key? key,
    required this.storeId,
    required this.paid,
    required this.pointsAwarded,
    required this.pointsUsed,
    this.normalPointsAwarded,
    this.specialPointsAwarded,
    this.usedCouponIds = const [],
    this.popOnComplete = false,
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
  bool _isLoadingCoupons = false;
  List<String> _usedCouponTitles = [];
  String? _transactionId;
  bool _isLoadingTransactionId = true;
  static const int _maxStamps = 10;
  List<Map<String, dynamic>> _availableCoupons = [];
  bool _couponsLoading = true;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _shineController;
  late final Animation<double> _shineAnim;
  int? _punchIndex;
  bool _shouldAnimatePunch = false;
  bool _coinBonusAwarded = false;
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
    _loadUsedCouponTitles();
    _loadTransactionId();
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
      _loadCoupons();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadCoupons() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();

      final couponsSnapshot = await FirebaseFirestore.instance
          .collection('public_coupons')
          .where('storeId', isEqualTo: widget.storeId)
          .where('isActive', isEqualTo: true)
          .get();

      final usedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('used_coupons')
          .get();

      final usedIds = <String>{};
      for (final doc in usedSnapshot.docs) {
        final data = doc.data();
        final usedStoreId = data['storeId'] as String?;
        if (usedStoreId != widget.storeId) continue;
        final couponId = (data['couponId'] as String?) ?? doc.id;
        if (couponId.isNotEmpty) {
          usedIds.add(couponId);
        }
      }

      final available = couponsSnapshot.docs.where((doc) {
        final data = doc.data();
        final couponId = doc.id;
        if (couponId.isEmpty) return false;
        if (usedIds.contains(couponId)) return false;

        final validUntil = _parseValidUntil(data['validUntil']);
        final noExpiry = data['noExpiry'] == true;
        final isNoExpiry = noExpiry || (validUntil != null && validUntil.year >= 2100);
        if (!isNoExpiry && (validUntil == null || !validUntil.isAfter(now))) {
          return false;
        }

        final usedCount = _parseInt(data['usedCount']);
        final usageLimit = _parseInt(data['usageLimit']);
        if (usageLimit > 0 && usedCount >= usageLimit) return false;

        return true;
      }).map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _availableCoupons = available;
          _couponsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _couponsLoading = false;
        });
      }
    }
  }

  DateTime? _parseValidUntil(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _isNoExpiryCoupon(Map<String, dynamic> coupon, DateTime? validUntil) {
    if (coupon['noExpiry'] == true) return true;
    return validUntil != null && validUntil.year >= 2100;
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

  Future<void> _loadUsedCouponTitles() async {
    if (widget.usedCouponIds.isEmpty) return;
    setState(() {
      _isLoadingCoupons = true;
    });
    try {
      final futures = widget.usedCouponIds.map((couponId) async {
        final doc = await FirebaseFirestore.instance
            .collection('coupons')
            .doc(widget.storeId)
            .collection('coupons')
            .doc(couponId)
            .get();
        final data = doc.data();
        final title = data?['title'] as String?;
        return (title == null || title.isEmpty) ? couponId : title;
      }).toList();
      final titles = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _usedCouponTitles = titles;
        _isLoadingCoupons = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _usedCouponTitles = widget.usedCouponIds;
        _isLoadingCoupons = false;
      });
    }
  }

  Future<void> _loadTransactionId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingTransactionId = false;
        });
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('point_transactions')
          .doc(widget.storeId)
          .collection(user.uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      String? matchId;
      for (final doc in snap.docs) {
        final data = doc.data();
        final amount = _parseInt(data['amount']);
        final paymentAmount = _parseInt(data['paymentAmount']);
        if (amount == widget.pointsAwarded && paymentAmount == widget.paid) {
          matchId = doc.id;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _transactionId = matchId;
        _isLoadingTransactionId = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTransactionId = false;
      });
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _loadPunchAnimationState(String userId) async {
    try {
      final eventsSnap = await FirebaseFirestore.instance
          .collection('user_achievement_events')
          .doc(userId)
          .collection('events')
          .where('type', whereIn: ['point_award', 'stamp_punch'])
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

      // 来店ボーナス: +1コイン付与（二重付与防止）
      await _awardVisitCoinBonus(userId, eventsSnap.docs.first);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _awardVisitCoinBonus(
    String userId,
    DocumentSnapshot<Map<String, dynamic>> eventDoc,
  ) async {
    try {
      final data = eventDoc.data();
      if (data == null) return;
      if (data['coinBonusAwarded'] == true) return;

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(userId);
      final eventRef = firestore
          .collection('user_achievement_events')
          .doc(userId)
          .collection('events')
          .doc(eventDoc.id);

      await firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final eventSnap = await transaction.get(eventRef);

        // 二重付与チェック
        if (eventSnap.data()?['coinBonusAwarded'] == true) return;

        final currentCoins =
            (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;
        transaction.update(userRef, {'coins': currentCoins + 1});
        transaction.update(eventRef, {'coinBonusAwarded': true});
      });

      _coinBonusAwarded = true;
    } catch (e) {
      debugPrint('来店ボーナス付与エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('スタンプ押印画面'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'スタンプ獲得',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUsedCouponsSection(),
                  const SizedBox(height: 12),
                  _buildStampCard(),
                  if (_coinBonusAwarded) ...[
                    const SizedBox(height: 12),
                    _buildCoinBonusBanner(),
                  ],
                  const SizedBox(height: 24),
                  _buildCouponSection(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.popOnComplete) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationView(),
                      ),
                      (route) => false,
                    );
                  }
                },
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
          ),
        ],
      ),
    );
  }

  Widget _buildCoinBonusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B35), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on, color: Colors.amber[700], size: 24),
          const SizedBox(width: 8),
          const Text(
            '来店ボーナス',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '+1 コイン',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    if (_couponsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF6B35),
            ),
          ),
        ),
      );
    }

    if (_availableCoupons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '使えるクーポン',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableCoupons.length,
          itemBuilder: (context, index) {
            return _buildCouponCard(_availableCoupons[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final title = (coupon['title'] as String?) ?? 'タイトルなし';
    final description = (coupon['description'] as String?) ?? '';
    final validUntil = _parseValidUntil(coupon['validUntil']);
    final usageLimit = _parseInt(coupon['usageLimit']);
    final usedCount = _parseInt(coupon['usedCount']);
    final remaining = usageLimit - usedCount;
    final requiredStampCount = _parseInt(coupon['requiredStampCount']);
    final needsStamps = requiredStampCount > 0 && _stamps < requiredStampCount;
    final remainingStamps = requiredStampCount - _stamps;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: needsStamps ? Colors.grey[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCouponImage(coupon['imageUrl'] as String?),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: needsStamps ? Colors.grey[600] : Colors.black,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: needsStamps ? Colors.grey[500] : Colors.grey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '残り$remaining枚',
                            style: TextStyle(
                              fontSize: 12,
                              color: needsStamps ? Colors.grey[500] : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (validUntil != null)
                            Text(
                              _isNoExpiryCoupon(coupon, validUntil)
                                  ? '期限: 無期限'
                                  : '期限: ${validUntil.month}/${validUntil.day} ${validUntil.hour.toString().padLeft(2, '0')}:${validUntil.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: needsStamps ? Colors.grey[500] : Colors.grey,
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
          if (needsStamps)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'あと$remainingStampsスタンプ',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCouponImage(String? imageUrl) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.local_offer,
                      color: Color(0xFFFF6B35),
                      size: 28,
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: Icon(
                Icons.local_offer,
                color: Color(0xFFFF6B35),
                size: 28,
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


  Widget _buildDetailRowMultiline(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildUsedCouponsSection() {
    if (widget.usedCouponIds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '今回使用したクーポン',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingCoupons)
            const Text(
              '読み込み中...',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _usedCouponTitles.isNotEmpty
                  ? _usedCouponTitles
                      .map((title) => _buildCouponChip(title))
                      .toList()
                  : widget.usedCouponIds
                      .map((id) => _buildCouponChip(id))
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCouponChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF6B35), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B35)),
      ),
    );
  }

  Widget _buildStampCard() {
    return StampCardWidget(
      storeName: _storeName,
      storeCategory: _storeCategory,
      iconImageUrl: _iconImageUrl,
      stamps: _stamps,
      maxStamps: _maxStamps,
      displayStamps: _displayStamps,
      isLoading: _loading,
      isSyncing: _isSyncing,
      errorMessage: _error,
      punchIndex: _shouldAnimatePunch ? _punchIndex : null,
      scaleAnimation: _scaleAnim,
      shineAnimation: _displayStamps >= _maxStamps ? _shineAnim : null,
    );
  }
}
