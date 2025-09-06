import 'package:flutter/material.dart';

class SlotMachineView extends StatelessWidget {
  const SlotMachineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スロットマシン'),
      ),
      body: const Center(
        child: Text('スロットマシン（開発中）'),
      ),
    );
  }
}
