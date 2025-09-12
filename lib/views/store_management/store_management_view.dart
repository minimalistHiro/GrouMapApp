import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_management_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/store_management_model.dart' as model;
import '../../widgets/custom_button.dart';

class StoreManagementView extends ConsumerWidget {
  const StoreManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗管理'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateStoreDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalyticsDialog(context, ref),
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
          return _buildStoreManagementContent(context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildStoreManagementContent(BuildContext context, WidgetRef ref) {
    final storeManagementList = ref.watch(storeManagementListProvider);

    return storeManagementList.when(
      data: (stores) {
        if (stores.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('管理している店舗がありません'),
                SizedBox(height: 8),
                Text('新しい店舗を登録してみましょう！'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return _buildStoreCard(context, ref, store);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラーが発生しました: $error'),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(storeManagementListProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, WidgetRef ref, model.StoreManagement store) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showStoreDetails(context, ref, store),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.store,
                    color: _getStatusColor(store.status),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          store.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(store.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(store.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    store.phoneNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    store.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem('訪問者', store.totalVisitors.toString()),
                  const SizedBox(width: 16),
                  _buildStatItem('ポイント付与', store.totalPointsAwarded.toString()),
                  const SizedBox(width: 16),
                  _buildStatItem('クーポン発行', store.totalCouponsIssued.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(model.StoreStatus status) {
    switch (status) {
      case model.StoreStatus.active:
        return Colors.green;
      case model.StoreStatus.inactive:
        return Colors.grey;
      case model.StoreStatus.pending:
        return Colors.orange;
      case model.StoreStatus.suspended:
        return Colors.red;
    }
  }

  String _getStatusText(model.StoreStatus status) {
    switch (status) {
      case model.StoreStatus.active:
        return 'アクティブ';
      case model.StoreStatus.inactive:
        return '非アクティブ';
      case model.StoreStatus.pending:
        return '承認待ち';
      case model.StoreStatus.suspended:
        return '停止中';
    }
  }

  void _showCreateStoreDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しい店舗を登録'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '店舗名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: '住所',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: '電話番号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  addressController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                ref.read(storeManagementProvider).createStoreManagement(
                  storeId: 'store_${DateTime.now().millisecondsSinceEpoch}',
                  managerId: 'current_user_id', // 実際のユーザーID
                  storeName: nameController.text,
                  description: descriptionController.text,
                  address: addressController.text,
                  latitude: 35.6762, // 実際の緯度
                  longitude: 139.6503, // 実際の経度
                  phoneNumber: phoneController.text,
                  email: emailController.text,
                );

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('店舗を登録しました')),
                );
              }
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  void _showStoreDetails(BuildContext context, WidgetRef ref, model.StoreManagement store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store.storeName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('説明: ${store.description}'),
              const SizedBox(height: 8),
              Text('住所: ${store.address}'),
              const SizedBox(height: 8),
              Text('電話: ${store.phoneNumber}'),
              const SizedBox(height: 8),
              Text('メール: ${store.email}'),
              const SizedBox(height: 8),
              Text('ステータス: ${_getStatusText(store.status)}'),
              const SizedBox(height: 8),
              Text('訪問者数: ${store.totalVisitors}'),
              const SizedBox(height: 8),
              Text('ポイント付与数: ${store.totalPointsAwarded}'),
              const SizedBox(height: 8),
              Text('クーポン発行数: ${store.totalCouponsIssued}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditStoreDialog(context, ref, store);
            },
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }

  void _showEditStoreDialog(BuildContext context, WidgetRef ref, model.StoreManagement store) {
    final nameController = TextEditingController(text: store.storeName);
    final descriptionController = TextEditingController(text: store.description);
    final addressController = TextEditingController(text: store.address);
    final phoneController = TextEditingController(text: store.phoneNumber);
    final emailController = TextEditingController(text: store.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗情報を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '店舗名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: '住所',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: '電話番号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(storeManagementProvider).updateStoreManagement(
                storeId: store.id,
                storeName: nameController.text,
                description: descriptionController.text,
                address: addressController.text,
                phoneNumber: phoneController.text,
                email: emailController.text,
              );

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('店舗情報を更新しました')),
              );
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗分析'),
        content: const Text('店舗分析機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}