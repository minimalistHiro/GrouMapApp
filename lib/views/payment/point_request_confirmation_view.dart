import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/store_provider.dart';
import '../stamps/stamp_punch_view.dart';

class PointRequestConfirmationView extends ConsumerStatefulWidget {
  final String requestId;

  const PointRequestConfirmationView({Key? key, required this.requestId}) : super(key: key);

  @override
  ConsumerState<PointRequestConfirmationView> createState() => _PointRequestConfirmationViewState();
}

class _PointRequestConfirmationViewState extends ConsumerState<PointRequestConfirmationView> {
  bool _isProcessing = false;
  bool _didNavigate = false;

  // 新しい構造に対応したリクエストストリームを取得
  Stream<DocumentSnapshot<Map<String, dynamic>>> _getRequestStream() {
    // requestIdの形式: "storeId_userId"
    final parts = widget.requestId.split('_');
    if (parts.length != 2) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    
    final storeId = parts[0];
    final userId = parts[1];
    
    return FirebaseFirestore.instance
        .collection('point_requests')
        .doc(storeId)
        .collection(userId)
        .doc('request')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント付与リクエスト確認'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _getRequestStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('リクエストが見つかりません'));
          }

          final data = snapshot.data!.data()!;
          final String storeId = (data['storeId'] ?? '').toString();
          final String userId = (data['userId'] ?? '').toString();
          final int points = (data['userPoints'] is int) ? data['userPoints'] as int : int.tryParse('${data['userPoints']}') ?? 0;
          final num amountNum = (data['amount'] is num) ? data['amount'] as num : num.tryParse('${data['amount']}') ?? 0;
          final String status = (data['status'] ?? '').toString();

          if (status == 'accepted') {
            if (!_didNavigate) {
              _didNavigate = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => StampPunchView(
                      storeId: storeId,
                      paid: amountNum.toInt(),
                      pointsAwarded: points,
                    ),
                  ),
                );
              });
            }
            return const Center(child: CircularProgressIndicator());
          }

          if (status != 'pending') {
            return const Center(child: Text('このリクエストは処理済みです'));
          }

          final storeAsync = ref.watch(storeProvider(storeId));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: storeAsync.when(
                    data: (store) {
                      final storeName = store?.name ?? '店舗名不明';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('店舗', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text('付与ポイント', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('$points ポイント', style: const TextStyle(fontSize: 18, color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text('支払い金額', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${amountNum.toString()} 円', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('店舗情報の取得に失敗しました: $e', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    '店舗側の承認待ちです',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _showCancelDialog(storeId: storeId, userId: userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('キャンセル'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 承認処理は店舗側アプリで実行する
  Future<void> _showCancelDialog({
    required String storeId,
    required String userId,
  }) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リクエストをキャンセルしますか？'),
        content: const Text('店舗側の承認待ちをキャンセルします。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await _cancelRequest(storeId: storeId, userId: userId);
    }
  }

  Future<void> _cancelRequest({
    required String storeId,
    required String userId,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ログインが必要です');
      }
      if (currentUser.uid != userId) {
        throw Exception('リクエストのユーザーが一致しません');
      }

      await FirebaseFirestore.instance
          .collection('point_requests')
          .doc(storeId)
          .collection(userId)
          .doc('request')
          .update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': currentUser.uid,
        'rejectionReason': 'ユーザーがキャンセル',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リクエストをキャンセルしました'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('キャンセルに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
