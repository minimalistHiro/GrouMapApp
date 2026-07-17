import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/nfc_checkin_service.dart';
import '../../theme/app_ui.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_dialog.dart';
import 'nfc_checkin_result_view.dart';

/// NFCチェックイン時のクーポン利用選択画面
/// NFCタッチ → この画面（クーポン選択） → チェックイン + クーポン利用 → 結果画面
class NfcCouponSelectView extends StatefulWidget {
  final String storeId;
  final String sessionToken;

  const NfcCouponSelectView({
    super.key,
    required this.storeId,
    required this.sessionToken,
  });

  @override
  State<NfcCouponSelectView> createState() => _NfcCouponSelectViewState();
}

class _NfcCouponSelectViewState extends State<NfcCouponSelectView> {
  bool _loading = true;
  bool _processing = false;
  String _storeName = '';
  String? _storeIconUrl;

  /// user_coupons から取得した利用可能クーポン
  List<Map<String, dynamic>> _availableCoupons = [];

  /// 選択されたクーポンのドキュメントID
  final Set<String> _selectedCouponIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      // 店舗情報を取得
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();
      final storeData = storeDoc.data() ?? {};
      final storeName = storeData['name'] as String? ?? '';
      final iconUrl = storeData['iconImageUrl'] as String?;

      // ユーザーの利用可能クーポンを取得（この店舗用、未使用）
      final couponSnap = await FirebaseFirestore.instance
          .collection('user_coupons')
          .where('userId', isEqualTo: userId)
          .where('storeId', isEqualTo: widget.storeId)
          .where('isUsed', isEqualTo: false)
          .get();

      final coupons = <Map<String, dynamic>>[];
      final now = DateTime.now();
      for (final doc in couponSnap.docs) {
        final data = doc.data();
        // 有効期限チェック
        final validUntil = data['validUntil'];
        if (validUntil != null) {
          DateTime? expiry;
          if (validUntil is Timestamp) {
            expiry = validUntil.toDate();
          } else if (validUntil is String) {
            expiry = DateTime.tryParse(validUntil);
          }
          if (expiry != null && expiry.isBefore(now)) continue;
        }
        coupons.add({...data, 'docId': doc.id});
      }

      if (!mounted) return;
      setState(() {
        _storeName = storeName;
        _storeIconUrl = iconUrl;
        _availableCoupons = coupons;
        _loading = false;
      });
    } catch (e) {
      debugPrint('クーポン読み込みエラー: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _doCheckin() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      // 位置情報の権限チェックと取得
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        await showGameDialog(
          context: context,
          title: '位置情報が必要です',
          message: 'チェックインには位置情報の許可が必要です。設定から位置情報を許可してください。',
          icon: Icons.location_off,
          headerColor: Colors.red,
          actions: [
            GameDialogAction(
              label: 'OK',
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('位置情報取得エラー: $e');
        if (!mounted) return;
        await showGameDialog(
          context: context,
          title: '位置情報の取得に失敗しました',
          message: 'しばらく待ってから再度お試しください。',
          icon: Icons.location_searching,
          headerColor: Colors.orange,
          actions: [
            GameDialogAction(
              label: 'OK',
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
        return;
      }

      final service = NfcCheckinService();
      final result = await service.checkin(
        sessionToken: widget.sessionToken,
        userLat: position.latitude,
        userLng: position.longitude,
        selectedUserCouponIds: _selectedCouponIds.toList(),
      );

      if (!mounted) return;

      // 使用したクーポン情報を収集
      final usedCoupons = _availableCoupons
          .where((c) => _selectedCouponIds.contains(c['docId']))
          .toList();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NfcCheckinResultView(
            result: result,
            storeId: widget.storeId,
            usedCoupons: usedCoupons,
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      String title = 'エラー';
      String message;
      IconData icon = Icons.error_outline;
      Color headerColor = Colors.red;
      switch (e.code) {
        case 'already-exists':
          message = '本日はすでに発見済みです';
          icon = Icons.check_circle_outline;
          headerColor = AppUi.primary;
          break;
        case 'not-found':
          message = '無効なNFCタグです';
          break;
        case 'permission-denied':
          if (e.message != null && e.message!.contains('Too far')) {
            title = '店舗から離れています';
            message = '店舗から200m以内でチェックインしてください。店舗の近くに移動してから再度お試しください。';
            icon = Icons.location_off;
          } else {
            message = 'この店舗は現在利用できません';
          }
          break;
        case 'deadline-exceeded':
          title = 'セッション期限切れ';
          message = 'チェックイン画面を開いてから10分が経過しました。再度NFCにタッチしてチェックインしてください。';
          icon = Icons.timer_off;
          headerColor = Colors.orange;
          break;
        case 'unauthenticated':
          message = '発見にはログインが必要です';
          break;
        default:
          message = '発見に失敗しました。もう一度お試しください。';
      }
      debugPrint('NFC checkin error (Functions): ${e.code} ${e.message}');
      await showGameDialog(
        context: context,
        title: title,
        message: message,
        icon: icon,
        headerColor: headerColor,
        actions: [
          GameDialogAction(
            label: 'OK',
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('NFC checkin error: $e');
      await showGameDialog(
        context: context,
        title: 'エラー',
        message: '発見に失敗しました。もう一度お試しください。',
        actions: [
          GameDialogAction(
            label: 'OK',
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUi.surface,
      appBar: CommonHeader(title: const Text('お店を発見'), showBack: false),
      body: _loading
          ? const Center(
              child: CustomLoadingIndicator(primaryColor: AppUi.primary),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 店舗情報
                        _buildStoreHeader(),
                        const SizedBox(height: 24),
                        // クーポン選択セクション
                        if (_availableCoupons.isEmpty)
                          _buildNoCouponsMessage()
                        else ...[
                          const Text(
                            '利用するクーポンを選択',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'クーポンを選択してチェックインすると、そのままクーポンが利用されます',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._availableCoupons.map(_buildCouponCard),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // 発見ボタン
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      children: [
                        if (_selectedCouponIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${_selectedCouponIds.length}件のクーポンを利用して発見する',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppUi.primary,
                              ),
                            ),
                          ),
                        CustomButton(
                          text: _selectedCouponIds.isEmpty
                              ? 'クーポンを使わずに発見する'
                              : '発見する',
                          onPressed: _processing ? null : _doCheckin,
                          isLoading: _processing,
                          height: 52,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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

  Widget _buildStoreHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.cardRadius),
      ),
      child: Row(
        children: [
          // 店舗アイコン
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppUi.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _storeIconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _storeIconUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store,
                        color: AppUi.primary,
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(Icons.store, color: AppUi.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _storeName.isNotEmpty ? _storeName : '店舗',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.nfc, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'NFCタッチで発見',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCouponsMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.cardRadius),
        border: Border.all(color: AppUi.border),
      ),
      child: Column(
        children: [
          Icon(Icons.card_giftcard, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            '利用可能なクーポンはありません',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'このままお店を発見しましょう',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final docId = coupon['docId'] as String;
    final title = coupon['title'] as String? ?? 'クーポン';
    final type = coupon['couponType'] as String? ?? 'discount';
    final discountValue = (coupon['discountValue'] as num?)?.toInt() ?? 0;
    final discountType = coupon['discountType'] as String? ?? 'fixed_amount';
    final isSelected = _selectedCouponIds.contains(docId);

    // 有効期限の表示
    String? expiryText;
    final validUntil = coupon['validUntil'];
    if (validUntil != null) {
      DateTime? expiry;
      if (validUntil is Timestamp) {
        expiry = validUntil.toDate();
      } else if (validUntil is String) {
        expiry = DateTime.tryParse(validUntil);
      }
      if (expiry != null) {
        expiryText =
            '有効期限: ${expiry.year}/${expiry.month.toString().padLeft(2, '0')}/${expiry.day.toString().padLeft(2, '0')}';
      }
    }
    if (coupon['noExpiry'] == true) {
      expiryText = '有効期限なし';
    }

    // 割引表示テキスト
    String discountText = '';
    if (type == 'discount') {
      if (discountType == 'percentage') {
        discountText = '$discountValue%OFF';
      } else {
        discountText = '${discountValue}円引き';
      }
    } else if (type == 'gift') {
      discountText = 'プレゼント';
    } else if (type == 'special_offer') {
      discountText = '特別オファー';
    }

    // クーポンの取得元
    final couponSource = coupon['type'] as String? ?? '';
    String sourceLabel = '';
    if (couponSource == 'stamp_reward') {
      sourceLabel = 'スタンプ特典';
    } else if (couponSource == 'coin_exchange') {
      sourceLabel = 'コイン交換';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCouponIds.remove(docId);
          } else {
            _selectedCouponIds.add(docId);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppUi.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(AppUi.controlRadius),
          border: Border.all(
            color: isSelected ? AppUi.primary : AppUi.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // チェックボックス
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? AppUi.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppUi.primary : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            // クーポンアイコン
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppUi.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: AppUi.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            // クーポン情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (discountText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        discountText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppUi.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (sourceLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sourceLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      if (sourceLabel.isNotEmpty && expiryText != null)
                        const SizedBox(width: 6),
                      if (expiryText != null)
                        Text(
                          expiryText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
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
    );
  }
}
