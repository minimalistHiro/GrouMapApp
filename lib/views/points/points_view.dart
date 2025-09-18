import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/point_provider.dart';
import '../../models/point_transaction_model.dart';
import '../../models/user_point_balance_model.dart';

class PointsView extends ConsumerStatefulWidget {
  const PointsView({Key? key}) : super(key: key);

  @override
  ConsumerState<PointsView> createState() => _PointsViewState();
}

class _PointsViewState extends ConsumerState<PointsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '全て'),
            Tab(text: '利用履歴'),
            Tab(text: '獲得履歴'),
          ],
        ),
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

    return Column(
      children: [
        // ポイント残高カード
        Container(
          padding: const EdgeInsets.all(16.0),
          child: _buildBalanceCard(context, pointBalance),
        ),
        
        // タブコンテンツ
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllTransactions(context, transactions),
              _buildUsedTransactions(context, transactions),
              _buildEarnedTransactions(context, transactions),
            ],
          ),
        ),
      ],
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


  Widget _buildAllTransactions(BuildContext context, AsyncValue<List<PointTransactionModel>> transactions) {
    return _buildTransactionList(context, transactions, null);
  }

  Widget _buildUsedTransactions(BuildContext context, AsyncValue<List<PointTransactionModel>> transactions) {
    return _buildTransactionList(context, transactions, false);
  }

  Widget _buildEarnedTransactions(BuildContext context, AsyncValue<List<PointTransactionModel>> transactions) {
    return _buildTransactionList(context, transactions, true);
  }

  Widget _buildTransactionList(BuildContext context, AsyncValue<List<PointTransactionModel>> transactions, bool? isEarned) {
    return transactions.when(
      data: (transactionList) {
        // フィルタリング
        List<PointTransactionModel> filteredList = transactionList;
        if (isEarned != null) {
          filteredList = transactionList.where((transaction) {
            if (isEarned) {
              return transaction.amount > 0; // 獲得履歴
            } else {
              return transaction.amount < 0; // 利用履歴
            }
          }).toList();
        }

        if (filteredList.isEmpty) {
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
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final transaction = filteredList[index];
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
    );
  }

  Widget _buildTransactionItem(PointTransactionModel transaction) {
    final isEarned = transaction.amount > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          isEarned ? Icons.add_circle : Icons.remove_circle,
          color: isEarned ? Colors.green : Colors.red,
        ),
        title: Text(transaction.description ?? 'ポイント取引'),
        subtitle: Text(
          '${transaction.createdAt.month}/${transaction.createdAt.day} ${transaction.createdAt.hour}:${transaction.createdAt.minute.toString().padLeft(2, '0')}',
        ),
        trailing: Text(
          '${isEarned ? '+' : ''}${transaction.amount}pt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEarned ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

}
