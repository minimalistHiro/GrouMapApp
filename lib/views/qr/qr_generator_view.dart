import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/qr_token_provider.dart';
import '../../widgets/custom_button.dart';
import '../payment/point_payment_view.dart';
import '../stamps/stamp_punch_view.dart';
import '../payment/point_payment_detail_view.dart';
import '../points/point_usage_approval_view.dart';

class QRGeneratorView extends ConsumerStatefulWidget {
  const QRGeneratorView({Key? key}) : super(key: key);

  @override
  ConsumerState<QRGeneratorView> createState() => _QRGeneratorViewState();
}

class _QRGeneratorViewState extends ConsumerState<QRGeneratorView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingRequestSub;
  String? _lastHandledRequestId;
  String? _lastHandledUsageRequestId;
  bool _isNavigatingToConfirmation = false;
  bool _isNavigatingToPayment = false;
  bool _isNavigatingToUsageInput = false;
  String? _listeningUserId;
  ProviderSubscription<dynamic>? _authStateSub; // 未使用化（下位互換のため保持）
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _storesSub;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _storeRequestDocSubs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController();
    // FirebaseAuth のストリームで認証変化を監視（ref.listenの制約を回避）
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user != null) {
        if (_listeningUserId != user.uid) {
          _listeningUserId = user.uid;
          print('PendingListener:init -> auth user=${user.uid}');
          _startPendingRequestListener(user.uid);
        }
      } else {
        if (_listeningUserId != null) {
          _listeningUserId = null;
          _cancelPendingRequestListener();
        }
      }
    });
    
    // タブ変更を監視して、QRコードを読み取るタブが選択された時にカメラを開始
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _startScanning();
      } else {
        _stopScanning();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    _cancelPendingRequestListener();
    _authStateSub?.close();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: authState.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('ログインが必要です'),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildQRCodeList(context, user),
                _buildQRScanner(context),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('エラー: $error'),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFF6B35),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code),
              text: 'QRコード',
            ),
            Tab(
              icon: Icon(Icons.qr_code_scanner),
              text: 'QRコードを読み取る',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeList(BuildContext context, User user) {
    final qrTokenState = ref.watch(qrTokenProvider);
    
    // デバッグログ
    print('QRGeneratorView: QRTokenState - isLoading: ${qrTokenState.isLoading}, hasToken: ${qrTokenState.hasToken}, error: ${qrTokenState.error}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QRコード表示
          _buildQRCodeDisplay(context, qrTokenState, user),
        ],
      ),
    );
  }

  Widget _buildQRCodeDisplay(BuildContext context, QRTokenState qrTokenState, User user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 残り時間表示
            if (qrTokenState.hasToken) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: qrTokenState.remainingSeconds > 10 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: qrTokenState.remainingSeconds > 10 
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: qrTokenState.remainingSeconds > 10 ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '更新まで ${qrTokenState.remainingSeconds} 秒',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: qrTokenState.remainingSeconds > 10 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // QRコード画像
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserHeader(user),
                  const SizedBox(height: 12),
                  _buildQRCodeContent(qrTokenState),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // エラー表示
            if (qrTokenState.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        qrTokenState.error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(qrTokenProvider.notifier).clearError();
                        ref.read(qrTokenProvider.notifier).refreshToken();
                      },
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeContent(QRTokenState qrTokenState) {
    if (qrTokenState.isLoading) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('トークンを生成中...'),
            ],
          ),
        ),
      );
    }

    if (!qrTokenState.hasToken) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('トークンを取得できませんでした'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        QrImageView(
          data: qrTokenState.token!,
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'QRコード文字列:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _copyToClipboard(context, qrTokenState.token!),
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'コピー',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                qrTokenState.token!,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader(User user) {
    final displayName = user.displayName?.trim();
    final photoUrl = user.photoURL;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Icon(Icons.person, color: Colors.grey.shade600)
              : null,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            displayName != null && displayName.isNotEmpty ? displayName : 'ユーザー',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  Widget _buildQRScanner(BuildContext context) {
    if (!_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: Color(0xFFFF6B35),
            ),
            const SizedBox(height: 24),
            const Text(
              'QRコードをスキャン',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'カメラをQRコードに向けて\nスキャンしてください',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'スキャンを開始',
              onPressed: () {
                _startScanning();
              },
              backgroundColor: const Color(0xFFFF6B35),
              icon: const Icon(Icons.qr_code_scanner, size: 20),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _showManualInputDialog(context);
              },
              child: const Text(
                '手動でQRコードを入力',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _handleQRCodeDetected(context, code);
              }
            }
          },
        ),
        // スキャンエリアのオーバーレイ
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'QRコードをここに合わせてください',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  // ユーザー宛の保留中リクエストをリアルタイム監視して自動遷移
  void _startPendingRequestListener(String userId) {
    // 既存の購読を解除して再作成
    _cancelPendingRequestListener();

    // インデックス不要のフォールバック監視に直接切り替え
    print('PendingListener:start -> userId=$userId');
    _startPendingRequestListenerFallback(userId);

    // 即時サーバー確認でラグを最小化（スナップショット待ちを回避）
    _checkPendingRequestOnce(userId);
  }

  int _parseRequestPoints(Map<String, dynamic> data) {
    final pointsValue = data['userPoints'] ?? data['pointsToAward'];
    if (pointsValue is int) return pointsValue;
    if (pointsValue is num) return pointsValue.toInt();
    return int.tryParse('$pointsValue') ?? 0;
  }

  int _parseRequestAmount(Map<String, dynamic> data) {
    final amountValue = data['amount'];
    if (amountValue is int) return amountValue;
    if (amountValue is num) return amountValue.toInt();
    return int.tryParse('$amountValue') ?? 0;
  }

  int _parseRequestUsedPoints(Map<String, dynamic> data) {
    final usedValue = data['usedPoints'];
    if (usedValue is int) return usedValue;
    if (usedValue is num) return usedValue.toInt();
    return int.tryParse('$usedValue') ?? 0;
  }

  bool _isRequestAlreadyNotified(Map<String, dynamic> data) {
    final notified = data['userNotified'];
    if (notified is bool && notified) return true;
    return data.containsKey('userNotifiedAt') && data['userNotifiedAt'] != null;
  }

  bool _isUsageApprovalAlreadyNotified(Map<String, dynamic> data) {
    final notified = data['usageApprovalNotified'] ?? data['usageInputNotified'];
    if (notified is bool && notified) return true;
    if (data.containsKey('usageApprovalNotifiedAt') && data['usageApprovalNotifiedAt'] != null) {
      return true;
    }
    return data.containsKey('usageInputNotifiedAt') && data['usageInputNotifiedAt'] != null;
  }

  Future<void> _markRequestNotified({
    required String storeId,
    required String userId,
  }) async {
    await FirebaseFirestore.instance
        .collection('point_requests')
        .doc(storeId)
        .collection(userId)
        .doc('award_request')
        .update({
      'userNotified': true,
      'userNotifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markUsageApprovalNotified({
    required String storeId,
    required String userId,
  }) async {
    await FirebaseFirestore.instance
        .collection('point_requests')
        .doc(storeId)
        .collection(userId)
        .doc('usage_request')
        .update({
      'usageApprovalNotified': true,
      'usageApprovalNotifiedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _isUsageRequestExpired(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp) {
      return DateTime.now().isAfter(expiresAt.toDate());
    }
    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) {
      return DateTime.now().difference(updatedAt.toDate()).inMinutes >= 5;
    }
    return false;
  }

  Future<void> _markUsageExpired({
    required String storeId,
    required String userId,
  }) async {
    await FirebaseFirestore.instance
        .collection('point_requests')
        .doc(storeId)
        .collection(userId)
        .doc('usage_request')
        .update({
      'status': 'usage_expired',
      'usageExpiredAt': FieldValue.serverTimestamp(),
    });
  }

  // 複合インデックス不要のフォールバック監視（stores/point_requests をリアルタイム購読し、
  // 各 store の user_requests/{userId} を直接監視）
  void _startPendingRequestListenerFallback(String userId) {
    // 既存購読の掃除
    _storesSub?.cancel();
    for (final sub in _storeRequestDocSubs.values) {
      sub.cancel();
    }
    _storeRequestDocSubs.clear();

    // stores の一覧をリアルタイム購読（親doc未作成でも storeId は取得できる）
    _storesSub = FirebaseFirestore.instance
        .collection('stores')
        .snapshots()
        .listen((storesSnap) {
      if (!mounted) return;
      print('PendingListener:stores snapshot -> count=${storesSnap.docs.length}');
      // 既に購読済みの storeId を維持しつつ、新規 storeId を追加監視
      final currentStoreIds =
          _storeRequestDocSubs.keys.map((key) => key.split(':').first).toSet();
      final incomingStoreIds = storesSnap.docs.map((d) => d.id).toSet();
      print('PendingListener:current=${currentStoreIds.toList()} incoming=${incomingStoreIds.toList()}');

      // 新規 storeId に対して購読を追加
      for (final storeId in incomingStoreIds.difference(currentStoreIds)) {
        final usageKey = '$storeId:usage';
        final usageRef = FirebaseFirestore.instance
            .collection('point_requests')
            .doc(storeId)
            .collection(userId)
            .doc('usage_request');
        print('PendingListener:attach usage sub -> path=point_requests/$storeId/$userId/usage_request');
        final usageSub = usageRef.snapshots().listen((doc) async {
          if (!mounted) return;
          print('PendingListener:usage snapshot -> storeId=$storeId exists=${doc.exists}');
          if (!doc.exists) return;
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString();
          final requestType = (data['requestType'] ?? '').toString();
          print('PendingListener:doc data -> status=$status');
          if (status == 'usage_pending_user_approval' && requestType == 'usage') {
            if (_isUsageRequestExpired(data)) {
              await _markUsageExpired(storeId: storeId, userId: userId);
              return;
            }
            if (_isUsageApprovalAlreadyNotified(data)) return;
            final combinedRequestId = '${storeId}_$userId';
            if (_isNavigatingToUsageInput || _lastHandledUsageRequestId == combinedRequestId) return;

            _isNavigatingToUsageInput = true;
            _lastHandledUsageRequestId = combinedRequestId;
            try {
              await _markUsageApprovalNotified(storeId: storeId, userId: userId);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PointUsageApprovalView(
                    storeId: storeId,
                    storeName: (data['storeName'] ?? '店舗') as String,
                  ),
                ),
              );
            } finally {
              if (mounted) {
                _isNavigatingToUsageInput = false;
              }
            }
            return;
          }
        });
        _storeRequestDocSubs[usageKey] = usageSub;

        final awardKey = '$storeId:award';
        final awardRef = FirebaseFirestore.instance
            .collection('point_requests')
            .doc(storeId)
            .collection(userId)
            .doc('award_request');
        print('PendingListener:attach award sub -> path=point_requests/$storeId/$userId/award_request');
        final awardSub = awardRef.snapshots().listen((doc) async {
          if (!mounted) return;
          print('PendingListener:award snapshot -> storeId=$storeId exists=${doc.exists}');
          if (!doc.exists) return;
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString();
          if (status != 'accepted') return;
          if (_isRequestAlreadyNotified(data)) return;
          final combinedRequestId = '${storeId}_$userId';
          if (_isNavigatingToConfirmation || _lastHandledRequestId == combinedRequestId) return;

          _isNavigatingToConfirmation = true;
          _lastHandledRequestId = combinedRequestId;
          try {
            final points = _parseRequestPoints(data);
            final amount = _parseRequestAmount(data);
            final usedPoints = _parseRequestUsedPoints(data);
            await _markRequestNotified(storeId: storeId, userId: userId);
            print('PendingListener:navigate accepted -> requestId=$combinedRequestId');
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PointPaymentDetailView(
                  storeId: storeId,
                  paid: amount,
                  pointsAwarded: points,
                  pointsUsed: usedPoints,
                ),
              ),
            );
          } catch (_) {
          } finally {
            if (mounted) {
              _isNavigatingToConfirmation = false;
            }
          }
        });
        _storeRequestDocSubs[awardKey] = awardSub;
      }

      // 無くなった storeId の購読を解除
      for (final removedId in currentStoreIds.difference(incomingStoreIds)) {
        _storeRequestDocSubs.remove('$removedId:usage')?.cancel();
        _storeRequestDocSubs.remove('$removedId:award')?.cancel();
      }
    }, onError: (_) {});
  }

  void _cancelPendingRequestListener() {
    _pendingRequestSub?.cancel();
    _pendingRequestSub = null;
    _storesSub?.cancel();
    _storesSub = null;
    for (final sub in _storeRequestDocSubs.values) {
      sub.cancel();
    }
    _storeRequestDocSubs.clear();
    print('PendingListener:cancelled all subscriptions');
  }

  Future<void> _checkPendingRequestOnce(String userId) async {
    if (_isNavigatingToConfirmation) return;
    try {
      // インデックス不要: すべての storeId を stores から取得し、各 {userId}/request を直接確認
      final storesSnap = await FirebaseFirestore.instance.collection('stores').get(const GetOptions(source: Source.server));
      print('PendingOnce:stores -> count=${storesSnap.docs.length}');
      for (final storeDoc in storesSnap.docs) {
        final storeId = storeDoc.id;
        final usageDoc = await FirebaseFirestore.instance
            .collection('point_requests')
            .doc(storeId)
            .collection(userId)
            .doc('usage_request')
            .get(const GetOptions(source: Source.server));
        print('PendingOnce:check usage -> storeId=$storeId exists=${usageDoc.exists}');
        if (usageDoc.exists) {
          final data = usageDoc.data() as Map<String, dynamic>;
          final combinedRequestId = '${storeId}_$userId';
          final status = (data['status'] ?? '').toString();
          final requestType = (data['requestType'] ?? '').toString();

          if (status == 'usage_pending_user_approval' && requestType == 'usage') {
            if (_isUsageRequestExpired(data)) {
              await _markUsageExpired(storeId: storeId, userId: userId);
              continue;
            }
            if (_isUsageApprovalAlreadyNotified(data)) continue;
            if (_isNavigatingToUsageInput || _lastHandledUsageRequestId == combinedRequestId) return;
            _isNavigatingToUsageInput = true;
            _lastHandledUsageRequestId = combinedRequestId;
            try {
              await _markUsageApprovalNotified(storeId: storeId, userId: userId);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PointUsageApprovalView(
                    storeId: storeId,
                    storeName: (data['storeName'] ?? '店舗') as String,
                  ),
                ),
              );
            } finally {
              _isNavigatingToUsageInput = false;
            }
            return;
          }
        }

        final awardDoc = await FirebaseFirestore.instance
            .collection('point_requests')
            .doc(storeId)
            .collection(userId)
            .doc('award_request')
            .get(const GetOptions(source: Source.server));
        print('PendingOnce:check award -> storeId=$storeId exists=${awardDoc.exists}');
        if (!awardDoc.exists) continue;
        final data = awardDoc.data() as Map<String, dynamic>;
        final combinedRequestId = '${storeId}_$userId';
        final status = (data['status'] ?? '').toString();
        if (status != 'accepted') continue;
        if (_isRequestAlreadyNotified(data)) continue;
        print('PendingOnce:found accepted -> requestId=$combinedRequestId');
        if (_lastHandledRequestId == combinedRequestId) return;
        _isNavigatingToConfirmation = true;
        _lastHandledRequestId = combinedRequestId;
        final points = _parseRequestPoints(data);
        final amount = _parseRequestAmount(data);
        final usedPoints = _parseRequestUsedPoints(data);
        await _markRequestNotified(storeId: storeId, userId: userId);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PointPaymentDetailView(
              storeId: storeId,
              paid: amount,
              pointsAwarded: points,
              pointsUsed: usedPoints,
            ),
          ),
        );
        return;
      }
    } finally {
      if (mounted) {
        _isNavigatingToConfirmation = false;
      }
    }
  }

  void _handleQRCodeDetected(BuildContext context, String code) {
    _stopScanning();
    _processQRCode(context, code);
  }

  void _showManualInputDialog(BuildContext context) {
    final TextEditingController qrCodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコードを手動入力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('QRコードの内容を入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: qrCodeController,
              decoration: const InputDecoration(
                labelText: 'QRコード',
                hintText: 'store001',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final qrCode = qrCodeController.text.trim();
              Navigator.of(context).pop();
              if (qrCode.isNotEmpty) {
                _processQRCode(context, qrCode);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QRコードを入力してください'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('処理'),
          ),
        ],
      ),
    );
  }

  void _processQRCode(BuildContext context, String qrCode) async {
    print('QRコード処理開始: $qrCode');
    
    if (qrCode.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QRコードを入力してください'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 1) まず、ユーザーに対する保留中のポイント付与リクエストがあるか確認
    try {
      final user = ref.read(authProvider).value;
      if (user != null) {
        if (context.mounted) {
          print('保留中リクエスト確認ダイアログを表示');
          _showLoadingDialog(context);
        }

        // この構造では storeId 未特定のため、ここでのクエリは行わない

        if (context.mounted) {
          print('保留中リクエスト確認ダイアログを閉じる');
          _closeLoadingDialog(context);
        }

        // ストア配下を直接確認して pending を検出（point_requests/{storeId}/{userId}/request）
        final storesSnap = await FirebaseFirestore.instance.collection('point_requests').get();
        for (final storeDoc in storesSnap.docs) {
          final storeId = storeDoc.id;
          final doc = await FirebaseFirestore.instance
              .collection('point_requests')
              .doc(storeId)
              .collection(user.uid)
              .doc('award_request')
              .get();
          if (!doc.exists) continue;
          final data = doc.data() as Map<String, dynamic>;
          if ((data['status'] ?? '').toString() == 'accepted') {
            if (_isRequestAlreadyNotified(data)) continue;
            final points = _parseRequestPoints(data);
            final amount = _parseRequestAmount(data);
            final usedPoints = _parseRequestUsedPoints(data);
            await _markRequestNotified(storeId: storeId, userId: user.uid);
            if (context.mounted) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PointPaymentDetailView(
                    storeId: storeId,
                    paid: amount,
                    pointsAwarded: points,
                    pointsUsed: usedPoints,
                  ),
                ),
              );
            }
            return;
          }
        }
      }
    } catch (e) {
      print('保留中リクエスト確認中にエラー: $e');
      // サイレントに続行（従来処理へ）
      if (context.mounted) {
        // 万が一ローディングが残っていれば閉じる
        _closeLoadingDialog(context);
      }
    }

    // QRコードの形式をチェック（店舗IDかどうか）
    final isStoreId = _isStoreId(qrCode);
    print('店舗ID判定結果: $isStoreId');
    
    if (isStoreId) {
      print('店舗IDとして処理: $qrCode');
      // 店舗IDの場合、存在確認してからポイント支払い画面に遷移
      await _validateStoreAndNavigate(context, qrCode);
    } else {
      print('その他のQRコードとして処理: $qrCode');
      // その他のQRコードの場合、従来の処理
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('QRコード処理完了'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text('QRコード: $qrCode'),
                const SizedBox(height: 8),
                const Text('10ポイントを獲得しました！'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // 店舗の存在確認とナビゲーション
  Future<void> _validateStoreAndNavigate(BuildContext context, String storeId) async {
    print('店舗存在確認開始: $storeId');
    
    // ローディング表示
    if (!context.mounted) return;
    
    if (_isNavigatingToPayment) {
      print('支払い画面への遷移は既に進行中のためスキップ');
      return;
    }
    _isNavigatingToPayment = true;
    _showLoadingDialog(context);
    
    // タイムアウト処理（10秒で強制終了）
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      print('店舗存在確認がタイムアウトしました');
      if (!mounted) return;
      _closeLoadingDialog(context);
      _showErrorDialog(
        context,
        'タイムアウト',
        '処理がタイムアウトしました。通信環境をご確認のうえ、もう一度お試しください。',
      );
    });
    
    try {
      print('Firestoreで店舗を検索中: $storeId');
      // 店舗の存在確認
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      print('店舗ドキュメント取得完了: ${doc.exists}');

      // ローディングを必ず閉じる
      timeoutTimer.cancel();
      _closeLoadingDialog(context);

      if (!doc.exists) {
        print('店舗が存在しません: $storeId');
        // 店舗が存在しない場合
        if (context.mounted) {
          _showErrorDialog(
            context,
            'この店舗は存在しません',
            '店舗ID: $storeId',
          );
        }
        _isNavigatingToPayment = false;
        return;
      }

      print('店舗が存在します。ポイント支払い画面に遷移: $storeId');
      // 店舗が存在する場合、ポイント支払い画面に遷移
      if (context.mounted) {
        try {
          timeoutTimer.cancel();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PointPaymentView(storeId: storeId),
            ),
          );
          print('ポイント支払い画面への遷移完了');
        } catch (e) {
          print('画面遷移エラー: $e');
          if (mounted) {
            _showErrorDialog(
              context,
              '画面遷移に失敗しました',
              'エラー: $e',
            );
          }
        }
      }
    } catch (e) {
      print('店舗存在確認エラー: $e');
      // エラーが発生した場合
      if (context.mounted) {
        // ローディングを必ず閉じる（タイマーも停止）
        timeoutTimer.cancel();
        _closeLoadingDialog(context);
        
        _showErrorDialog(
          context,
          '店舗情報の確認中にエラーが発生しました',
          'エラー: $e',
        );
      }
    }
    
    _isNavigatingToPayment = false;
  }

  // ローディングダイアログを安全に閉じる
  void _closeLoadingDialog(BuildContext context) {
    if (!mounted) return;
    if (context.mounted) {
      try {
        Navigator.of(context, rootNavigator: true).maybePop();
      } catch (_) {}
    }
  }

  // ローディングダイアログを安全に開く
  void _showLoadingDialog(BuildContext context) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    } catch (e) {
      print('ローディングダイアログ表示時のエラー: $e');
    }
  }

  // エラーダイアログを表示する共通メソッド
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 店舗IDかどうかを判定する関数
  bool _isStoreId(String qrCode) {
    // より柔軟な店舗ID判定（英数字・ハイフン・アンダースコアを許可、3文字以上）
    if (qrCode.length >= 3) {
      return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(qrCode);
    }
    return false;
  }

  // クリップボードにコピーする関数
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('QRコード文字列をコピーしました'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

}
