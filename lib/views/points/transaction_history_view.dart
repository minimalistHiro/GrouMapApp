import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stamps/stamp_punch_view.dart';
import '../../providers/auth_provider.dart';
import '../../providers/point_provider.dart';
import '../../models/point_transaction_model.dart';

class TransactionHistoryView extends ConsumerWidget {
  const TransactionHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('取引履歴'),
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

          return _buildTransactionHistory(context, ref, user.uid);
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

  Widget _buildTransactionHistory(BuildContext context, WidgetRef ref, String userId) {
    final transactions = ref.watch(userPointTransactionsProvider(userId));

    return transactions.when(
      data: (transactionList) {
        if (transactionList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '取引履歴がありません',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: transactionList.length,
          itemBuilder: (context, index) {
            final transaction = transactionList[index];
            return _buildTransactionItem(context, transaction);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(userPointTransactionsProvider(userId));
              },
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, PointTransactionModel transaction) {
    final isEarned = transaction.amount > 0;
    // final isUsed = transaction.amount < 0; // 現状未使用
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEarned ? Colors.green : Colors.red,
          child: Icon(
            isEarned ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.description ?? '取引',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '店舗ID: ${transaction.storeId}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              '${transaction.createdAt.month}/${transaction.createdAt.day} '
              '${transaction.createdAt.hour.toString().padLeft(2, '0')}:'
              '${transaction.createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (transaction.qrCode != null) ...[
              Text(
                'QRコード: ${transaction.qrCode}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isEarned ? '+' : ''}${transaction.amount}pt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.green : Colors.red,
              ),
            ),
            Text(
              isEarned ? '獲得' : '使用',
              style: TextStyle(
                fontSize: 12,
                color: isEarned ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            if (isEarned && transaction.storeId.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StampPunchView(storeId: transaction.storeId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('受け取る'),
              ),
          ],
        ),
        onTap: () {
          _showTransactionDetails(context, transaction);
        },
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, PointTransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取引詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('説明', transaction.description ?? ''),
            _buildDetailRow('ポイント', '${transaction.amount}pt'),
            _buildDetailRow('店舗ID', transaction.storeId),
            _buildDetailRow('日時', _formatDateTime(transaction.createdAt)),
            if (transaction.qrCode != null)
              _buildDetailRow('QRコードID', transaction.qrCode!),
            _buildDetailRow('取引ID', transaction.transactionId),
            _buildDetailRow('状態', transaction.status),
          ],
        ),
        actions: [
          if (transaction.amount > 0 && transaction.storeId.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => StampPunchView(storeId: transaction.storeId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('受け取る'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
