import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/store_provider.dart';
import '../../services/point_transaction_service.dart';
import '../stamps/stamp_punch_view.dart';

class PointRequestConfirmationView extends ConsumerStatefulWidget {
  final String requestId;

  const PointRequestConfirmationView({Key? key, required this.requestId}) : super(key: key);

  @override
  ConsumerState<PointRequestConfirmationView> createState() => _PointRequestConfirmationViewState();
}

class _PointRequestConfirmationViewState extends ConsumerState<PointRequestConfirmationView> {
  bool _isProcessing = false;

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
          final int points = (data['userPoints'] is int) ? data['userPoints'] as int : int.tryParse('${data['userPoints']}') ?? 0;
          final num amountNum = (data['amount'] is num) ? data['amount'] as num : num.tryParse('${data['amount']}') ?? 0;
          final String status = (data['status'] ?? '').toString();

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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : () => _handleDecision(accept: false, requestData: data),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('拒否'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _handleDecision(accept: true, requestData: data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isProcessing
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('受け入れる'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDecision({required bool accept, required Map<String, dynamic> requestData}) async {
    setState(() {
      _isProcessing = true;
    });

    final String requestId = widget.requestId;
    final int points = (requestData['userPoints'] is int) ? requestData['userPoints'] as int : int.tryParse('${requestData['userPoints']}') ?? 0;
    final num amountNum = (requestData['amount'] is num) ? requestData['amount'] as num : num.tryParse('${requestData['amount']}') ?? 0;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }

      // 新しい構造に対応：requestIdの形式: "storeId_userId"
      final parts = requestId.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid request ID format');
      }
      
      final storeId = parts[0];
      final userId = parts[1];
      
      // リクエスト更新とユーザーポイント加算を同一トランザクションで実行
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final requestRef = db
          .collection('point_requests')
          .doc(storeId)
          .collection(userId)
          .doc('request');
      final userRef = db.collection('users').doc(user.uid);

      await db.runTransaction((txn) async {
        final reqSnap = await txn.get(requestRef);
        if (!reqSnap.exists) {
          throw Exception('リクエストが存在しません');
        }

        final current = (reqSnap.data() ?? const {}) as Map<String, dynamic>;
        final currentStatus = (current['status'] ?? '').toString();

        // 既に処理済みならスキップ
        if (currentStatus != 'pending') {
          return;
        }

        // リクエストの状態を更新
        txn.update(requestRef, {
          'status': accept ? 'accepted' : 'rejected',
          'respondedAt': FieldValue.serverTimestamp(),
          'respondedBy': user.uid,
        });

        // 承認時のみポイント加算（users/{userId}.points）
        if (accept) {
          txn.update(userRef, {
            'points': FieldValue.increment(points),
            'paid': FieldValue.increment(amountNum), // 総支払額に今回の支払額を加算
          });
        }
      });

      // 承認時はポイント付与履歴を保存: point_transactions/{storeId}/{userId}/{transactionId}
      if (accept) {
        try {
          final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
          final storeName = (storeDoc.data() ?? const {})['name']?.toString() ?? '店舗';
          await PointTransactionService.createTransaction(
            storeId: storeId,
            storeName: storeName,
            amount: points,
            description: 'ポイント付与',
          );
        } catch (_) {}
      }

          if (mounted) {
        final message = accept ? 'ポイント付与を承認しました' : 'ポイント付与を拒否しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: accept ? Colors.green : Colors.red),
        );
        if (accept) {
          Navigator.of(context).push(
            MaterialPageRoute(
                  builder: (_) => StampPunchView(
                    storeId: storeId,
                    paid: (amountNum is int) ? amountNum : amountNum.toInt(),
                  ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('処理に失敗しました: $e'), backgroundColor: Colors.red),
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

