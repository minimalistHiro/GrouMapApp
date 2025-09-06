import 'package:flutter/material.dart';

class CreateCouponView extends StatelessWidget {
  const CreateCouponView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規クーポン作成'),
      ),
      body: const Center(
        child: Text('新規クーポン作成（開発中）'),
      ),
    );
  }
}
