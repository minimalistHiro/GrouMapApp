import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../payment/point_payment_detail_view.dart';

class PointUsageWaitingView extends StatefulWidget {
  final String storeId;
  final String storeName;

  const PointUsageWaitingView({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<PointUsageWaitingView> createState() => _PointUsageWaitingViewState();
}

class _PointUsageWaitingViewState extends State<PointUsageWaitingView> {
  bool _didNavigate = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }

    final requestRef = FirebaseFirestore.instance
        .collection('point_requests')
        .doc(widget.storeId)
        .collection(user.uid)
        .doc('usage_request');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('店舗側の入力待ち'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: requestRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('リクエストが見つかりません'));
          }

          final data = snapshot.data!.data() ?? const <String, dynamic>{};
          final status = (data['status'] ?? '').toString();

          if (status == 'accepted' && !_didNavigate) {
            _didNavigate = true;
            final points = _parseInt(data['userPoints']);
            final amount = _parseInt(data['amount']);
            final usedPoints = _parseInt(data['usedPoints']);
            final usedCouponIds = _parseCouponIds(data['selectedCouponIds']);
            requestRef.update({
              'userNotified': true,
              'userNotifiedAt': FieldValue.serverTimestamp(),
            }).catchError((_) {});
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PointPaymentDetailView(
                    storeId: widget.storeId,
                    paid: amount,
                    pointsAwarded: points,
                    pointsUsed: usedPoints,
                    usedCouponIds: usedCouponIds,
                  ),
                ),
              );
            });
          }

          if (status == 'rejected') {
            return const Center(child: Text('リクエストがキャンセルされました'));
          }

          return _buildWaitingContent(status);
        },
      ),
    );
  }

  Widget _buildWaitingContent(String status) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
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
            child: const Text(
              '店舗側の入力を待機しています',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<String> _parseCouponIds(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }
}
