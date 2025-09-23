import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/store_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart' as model;

class PointRequestConfirmationView extends ConsumerStatefulWidget {
  final String requestId;

  const PointRequestConfirmationView({Key? key, required this.requestId}) : super(key: key);

  @override
  ConsumerState<PointRequestConfirmationView> createState() => _PointRequestConfirmationViewState();
}

class _PointRequestConfirmationViewState extends ConsumerState<PointRequestConfirmationView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント付与リクエスト確認'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('point_requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('リクエストが見つかりません'));
          }

          final data = snapshot.data!.data()!;
          final String storeId = (data['storeId'] ?? '').toString();
          final int points = (data['points'] is int) ? data['points'] as int : int.tryParse('${data['points']}') ?? 0;
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
    final String storeId = (requestData['storeId'] ?? '').toString();
    final int points = (requestData['points'] is int) ? requestData['points'] as int : int.tryParse('${requestData['points']}') ?? 0;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }

      await FirebaseFirestore.instance.collection('point_requests').doc(requestId).update({
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': user.uid,
      });

      // 店舗側へ通知
      try {
        final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
        final ownerId = (storeDoc.data() ?? const {})['createdBy']?.toString();
        if (ownerId != null && ownerId.isNotEmpty) {
          final notifier = ref.read(notificationProvider);
          await notifier.createNotification(
            userId: ownerId,
            title: accept ? 'ポイント付与が承認されました' : 'ポイント付与が拒否されました',
            body: accept ? '${points}ポイントの付与がユーザーにより承認されました' : 'ユーザーがポイント付与を拒否しました',
            type: model.NotificationType.system,
            data: {
              'requestId': requestId,
              'storeId': storeId,
              'userId': user.uid,
              'status': accept ? 'accepted' : 'rejected',
            },
          );
        }
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'ポイント付与を承認しました' : 'ポイント付与を拒否しました'),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
        );
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


