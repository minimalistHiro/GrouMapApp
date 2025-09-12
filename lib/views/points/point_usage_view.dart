import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/point_provider.dart';
import '../../models/point_transaction_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PointUsageView extends ConsumerStatefulWidget {
  const PointUsageView({Key? key}) : super(key: key);

  @override
  ConsumerState<PointUsageView> createState() => _PointUsageViewState();
}

class _PointUsageViewState extends ConsumerState<PointUsageView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _storeIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _storeIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイントを使用'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }

          return _buildContent(context, user.uid);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String userId) {
    final pointBalance = ref.watch(userPointBalanceProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 現在のポイント残高
          _buildBalanceCard(context, pointBalance),
          const SizedBox(height: 24),
          
          // ポイント使用フォーム
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ポイント使用情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 店舗ID
                    CustomTextField(
                      controller: _storeIdController,
                      labelText: '店舗ID',
                      hintText: 'store_001',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '店舗IDを入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 使用ポイント数
                    CustomTextField(
                      controller: _amountController,
                      labelText: '使用ポイント数',
                      hintText: '100',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '使用ポイント数を入力してください';
                        }
                        final points = int.tryParse(value);
                        if (points == null || points <= 0) {
                          return '有効なポイント数を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 説明
                    CustomTextField(
                      controller: _descriptionController,
                      labelText: '使用理由（任意）',
                      hintText: '商品購入',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // 使用ボタン
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isProcessing ? '処理中...' : 'ポイントを使用',
                        onPressed: _isProcessing ? null : () => _usePoints(context, userId),
                        backgroundColor: const Color(0xFFFF6B35),
                        icon: const Icon(Icons.shopping_cart, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, AsyncValue<dynamic> pointBalance) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              '現在のポイント残高',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            pointBalance.when(
              data: (balance) {
                if (balance == null) {
                  return const Text(
                    '0',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  );
                }
                return Text(
                  '${balance.availablePoints}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text(
                'エラー',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            pointBalance.when(
              data: (balance) {
                if (balance == null) return const SizedBox.shrink();
                return Text(
                  '総獲得: ${balance.totalPoints}pt | 使用済み: ${balance.usedPoints}pt',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _usePoints(BuildContext context, String userId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final pointProcessor = ref.read(pointProcessorProvider);
      final points = int.parse(_amountController.text);
      
      await pointProcessor.usePoints(
        userId: userId,
        storeId: _storeIdController.text,
        points: points,
        description: _descriptionController.text.isEmpty 
            ? 'ポイント使用' 
            : _descriptionController.text,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$pointsポイントを使用しました'),
            backgroundColor: const Color(0xFFFF6B35),
          ),
        );
        
        // フォームをリセット
        _formKey.currentState?.reset();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ポイント使用に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
