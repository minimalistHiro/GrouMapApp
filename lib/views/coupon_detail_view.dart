import 'package:flutter/material.dart';

class CouponDetailView extends StatelessWidget {
  final String couponId;
  const CouponDetailView({super.key, required this.couponId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クーポン詳細'),
      ),
      body: const Center(
        child: Text('クーポン詳細（開発中）'),
      ),
    );
  }
}
