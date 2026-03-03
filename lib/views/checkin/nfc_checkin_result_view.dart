import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common_header.dart';
import '../../widgets/stamp_card_widget.dart';
import '../../services/nfc_checkin_service.dart';
import '../../theme/app_ui.dart';
import '../main_navigation_view.dart';

class NfcCheckinResultView extends StatefulWidget {
  final NfcCheckinResult result;
  final String storeId;
  final List<Map<String, dynamic>> usedCoupons;

  const NfcCheckinResultView({
    super.key,
    required this.result,
    required this.storeId,
    this.usedCoupons = const [],
  });

  @override
  State<NfcCheckinResultView> createState() => _NfcCheckinResultViewState();
}

class _NfcCheckinResultViewState extends State<NfcCheckinResultView>
    with TickerProviderStateMixin {
  bool _loading = true;
  String _storeCategory = 'その他';
  String? _iconImageUrl;
  int _completedCards = 0;
  static const int _maxStamps = 10;
  List<Map<String, dynamic>> _availableCoupons = [];
  bool _couponsLoading = true;

  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _shineController;
  late final Animation<double> _shineAnim;

  int? _punchIndex;

  // 目視確認用のリアルタイム時刻
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

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
    );
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shineController, curve: Curves.linear));

    // クーポン利用時はリアルタイム時計を起動
    if (_hasUsedCoupons) {
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _currentTime = DateTime.now());
      });
    }

    _loadStoreDetails();
  }

  bool get _hasUsedCoupons =>
      widget.usedCoupons.isNotEmpty || widget.result.usedCoupons.isNotEmpty;

  List<Map<String, dynamic>> get _allUsedCoupons {
    if (widget.usedCoupons.isNotEmpty) return widget.usedCoupons;
    return widget.result.usedCoupons;
  }

  @override
  void dispose() {
    _animController.dispose();
    _shineController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStoreDetails() async {
    try {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();
      final storeData = storeDoc.data() ?? {};
      final category = storeData['category'] as String? ?? 'その他';
      final iconUrl = storeData['iconImageUrl'] as String?;

      // 完了済みカード数を取得
      final userId = FirebaseAuth.instance.currentUser?.uid;
      int completedCards = 0;
      if (userId != null) {
        final userStoreDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('stores')
            .doc(widget.storeId)
            .get();
        final data = userStoreDoc.data() ?? {};
        completedCards = (data['completedCards'] as num?)?.toInt() ?? 0;
      }

      // 利用可能クーポンを取得
      await _loadAvailableCoupons();

      if (!mounted) return;
      setState(() {
        _storeCategory = category;
        _iconImageUrl = iconUrl;
        _completedCards = completedCards;
        _loading = false;
      });

      // スタンプ演出を開始
      final displayStamps = widget.result.stampsAfter % _maxStamps;
      final effectiveDisplay = displayStamps == 0 && widget.result.cardCompleted
          ? _maxStamps
          : displayStamps;
      if (effectiveDisplay > 0) {
        _punchIndex = effectiveDisplay - 1;
      }
      _animController.forward();
      if (widget.result.cardCompleted) {
        _shineController.repeat();
      }
    } catch (e) {
      debugPrint('店舗情報読み込みエラー: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _animController.forward();
    }
  }

  Future<void> _loadAvailableCoupons() async {
    try {
      final couponsSnap = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .get();
      if (!mounted) return;
      setState(() {
        _availableCoupons = couponsSnap.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList();
        _couponsLoading = false;
      });
    } catch (e) {
      debugPrint('クーポン読み込みエラー: $e');
      if (!mounted) return;
      setState(() {
        _couponsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayStamps = widget.result.stampsAfter % _maxStamps;
    final effectiveDisplay = displayStamps == 0 && widget.result.cardCompleted
        ? _maxStamps
        : displayStamps;

    return Scaffold(
      backgroundColor: AppUi.surface,
      appBar: CommonHeader(title: const Text('チェックイン完了')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // タイトル
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 56),
                  const SizedBox(height: 8),
                  const Text(
                    'チェックイン成功！',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppUi.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.result.storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // クーポン利用確認セクション（スタッフ目視確認用）
                  if (_hasUsedCoupons) ...[
                    _buildUsedCouponsVerification(),
                    const SizedBox(height: 20),
                  ],

                  // スタンプカード
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppUi.primary),
                      ),
                    )
                  else
                    StampCardWidget(
                      storeName: widget.result.storeName,
                      storeCategory: _storeCategory,
                      iconImageUrl: _iconImageUrl,
                      stamps: widget.result.stampsAfter,
                      displayStamps: effectiveDisplay,
                      completedCards: _completedCards,
                      punchIndex: _punchIndex,
                      scaleAnimation: _scaleAnim,
                      shineAnimation: widget.result.cardCompleted ? _shineAnim : null,
                    ),
                  const SizedBox(height: 16),

                  // 来店ボーナス表示
                  if (widget.result.coinsAdded > 0) _buildCoinBonusBanner(),

                  // 獲得クーポン表示
                  if (widget.result.awardedCoupons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAwardedCouponsSection(),
                  ],

                  // 利用可能クーポン
                  if (!_couponsLoading && _availableCoupons.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildAvailableCouponsSection(effectiveDisplay),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // 完了ボタン
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppUi.primary,
                    foregroundColor: AppUi.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppUi.controlRadius),
                    ),
                  ),
                  child: const Text(
                    '完了',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// クーポン利用確認セクション（スタッフへの目視確認用）
  Widget _buildUsedCouponsVerification() {
    final verificationCode = widget.result.usageVerificationCode ?? '------';
    final timeStr =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
    final dateStr =
        '${_currentTime.year}/${_currentTime.month.toString().padLeft(2, '0')}/${_currentTime.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.cardRadius),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'クーポン利用済み',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 利用したクーポン一覧
          ..._allUsedCoupons.map((coupon) {
            final title = coupon['title'] as String? ?? 'クーポン';
            final discountValue = (coupon['discountValue'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (discountValue > 0)
                    Text(
                      '${discountValue}円引き',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppUi.primary,
                      ),
                    ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          // 確認コードとリアルタイム時計
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '確認コード',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    verificationCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'この画面をスタッフにお見せください',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinBonusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EC),
        borderRadius: BorderRadius.circular(AppUi.controlRadius),
        border: Border.all(color: AppUi.primary, width: 1.5),
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
              color: AppUi.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppUi.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${widget.result.coinsAdded} コイン',
              style: const TextStyle(
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

  Widget _buildAwardedCouponsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.cardRadius),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          const Text(
            'クーポン獲得！',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.result.awardedCoupons.map((coupon) {
              final title = coupon['title'] as String? ?? 'クーポン';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppUi.primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard, size: 16, color: AppUi.primary),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: AppUi.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCouponsSection(int currentStamps) {
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
        ...(_availableCoupons.map((coupon) {
          final title = coupon['title'] as String? ?? '';
          final description = coupon['description'] as String? ?? '';
          final requiredStamps = (coupon['requiredStamps'] as num?)?.toInt() ?? 0;
          final needsMore = requiredStamps > 0 && currentStamps < requiredStamps;
          final remaining = requiredStamps - currentStamps;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: needsMore ? Colors.grey[100] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppUi.controlRadius),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: needsMore
                              ? Colors.grey[300]
                              : AppUi.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: needsMore ? Colors.grey : AppUi.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: needsMore ? Colors.grey[600] : Colors.black,
                              ),
                            ),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: needsMore ? Colors.grey[500] : Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (needsMore)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(AppUi.controlRadius),
                      ),
                      child: Center(
                        child: Text(
                          'あと$remainingスタンプ',
                          style: const TextStyle(
                            fontSize: 22,
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
        }).toList()),
      ],
    );
  }

  void _onComplete() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainNavigationView(),
      ),
      (route) => false,
    );
  }
}
