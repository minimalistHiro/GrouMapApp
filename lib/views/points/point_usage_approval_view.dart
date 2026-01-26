import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointUsageApprovalView extends StatefulWidget {
  final String storeId;
  final String storeName;

  const PointUsageApprovalView({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<PointUsageApprovalView> createState() => _PointUsageApprovalViewState();
}

class _PointUsageApprovalViewState extends State<PointUsageApprovalView> {
  bool _isProcessing = false;
  bool _didMarkExpired = false;

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
      appBar: AppBar(
        title: const Text('ポイント利用確認'),
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
          final usedPoints = _parseInt(data['usedPoints']);
          final storeName = (data['storeName'] ?? widget.storeName).toString();
          final isExpired = status == 'usage_expired' || _isExpired(data);

          if (status == 'usage_pending_user_approval' && isExpired && !_didMarkExpired) {
            _didMarkExpired = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _markExpired(requestRef);
            });
          }

          if (status != 'usage_pending_user_approval') {
            return _buildResultView(status);
          }

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('店舗', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('利用ポイント', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '$usedPoints pt',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _updateStatus(requestRef, 'usage_approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
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
                        : const Text('承認する'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _updateStatus(requestRef, 'usage_rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('拒否する'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(DocumentReference<Map<String, dynamic>> requestRef, String status) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await requestRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'usage_approved') 'usageApprovedAt': FieldValue.serverTimestamp(),
        if (status == 'usage_rejected') 'usageRejectedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
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

  Future<void> _markExpired(DocumentReference<Map<String, dynamic>> requestRef) async {
    try {
      await requestRef.update({
        'status': 'usage_expired',
        'usageExpiredAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Widget _buildResultView(String status) {
    String message = 'このリクエストは処理済みです';
    if (status == 'usage_approved') {
      message = '承認しました';
    } else if (status == 'usage_rejected') {
      message = '拒否しました';
    } else if (status == 'usage_expired') {
      message = '承認期限が切れました';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isExpired(Map<String, dynamic> data) {
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

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
