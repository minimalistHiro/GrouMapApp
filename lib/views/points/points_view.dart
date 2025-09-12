import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/point_provider.dart';
import '../../models/point_transaction_model.dart';
import '../../widgets/custom_button.dart';
import 'point_usage_view.dart';
import 'transaction_history_view.dart';

class PointsView extends ConsumerWidget {
  const PointsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showTransactionHistory(context, ref);
            },
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }

          return _buildPointsContent(context, ref, user.uid);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'データの取得に失敗しました',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ネットワーク接続を確認してください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsContent(BuildContext context, WidgetRef ref, String userId) {
    final pointBalance = ref.watch(userPointBalanceProvider(userId));
    final transactions = ref.watch(userPointTransactionsProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ポイント残高カード
          _buildBalanceCard(context, pointBalance),
          
          const SizedBox(height: 24),
          
          // アクションボタン
          _buildActionButtons(context, ref, userId),
          
          const SizedBox(height: 24),
          
          // 最近の取引履歴
          _buildRecentTransactions(context, transactions),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, AsyncValue<UserPointBalance?> pointBalance) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'ポイント残高',
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
                  return const Column(
                    children: [
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ポイントがありません',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
              error: (error, _) => const Column(
                children: [
                  Text(
                    '0',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ポイントの取得に失敗しました',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, String userId) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'QRコードをスキャン',
            onPressed: () {
              _showQRScanner(context, ref, userId);
            },
            icon: const Icon(Icons.qr_code_scanner, size: 20),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'ポイントを使用',
            onPressed: () {
              _showUsePoints(context, ref, userId);
            },
            backgroundColor: Colors.green,
            icon: const Icon(Icons.shopping_cart, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, AsyncValue<List<PointTransactionModel>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近の取引',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        transactions.when(
          data: (transactionList) {
            if (transactionList.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    '取引履歴がありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactionList.length > 5 ? 5 : transactionList.length,
              itemBuilder: (context, index) {
                final transaction = transactionList[index];
                return _buildTransactionItem(transaction);
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'エラー: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(PointTransactionModel transaction) {
    final isEarned = transaction.points > 0;
    final isUsed = transaction.points < 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          isEarned ? Icons.add_circle : Icons.remove_circle,
          color: isEarned ? Colors.green : Colors.red,
        ),
        title: Text(transaction.description),
        subtitle: Text(
          '${transaction.timestamp.month}/${transaction.timestamp.day} ${transaction.timestamp.hour}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
        ),
        trailing: Text(
          '${isEarned ? '+' : ''}${transaction.points}pt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEarned ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  void _showQRScanner(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコードスキャン'),
        content: const Text('QRコードスキャン機能は準備中です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showUsePoints(BuildContext context, WidgetRef ref, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PointUsageView(),
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryView(),
      ),
    );
  }
}
