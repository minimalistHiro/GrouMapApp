import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/store_provider.dart';
import '../../widgets/custom_button.dart';
import 'store_detail_view.dart';

class StoreListView extends ConsumerStatefulWidget {
  const StoreListView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreListView> createState() => _StoreListViewState();
}

class _StoreListViewState extends ConsumerState<StoreListView> {
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  // データベースから店舗を読み込む
  Future<void> _loadStores() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('店舗一覧の読み込みを開始...');
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('stores').get();
      print('取得したドキュメント数: ${snapshot.docs.length}');
      
      final List<Map<String, dynamic>> stores = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('店舗データ: ${doc.id} - isActive: ${data['isActive']}, isApproved: ${data['isApproved']}');
        
        // 実際のデータベースから店舗を取得
        stores.add({
          'id': doc.id,
          'name': data['name'] ?? '店舗名なし',
          'category': data['category'] ?? 'その他',
          'description': data['description'] ?? '',
          'address': data['address'] ?? '',
          'iconImageUrl': data['iconImageUrl'],
          'backgroundImageUrl': data['backgroundImageUrl'],
          'phoneNumber': data['phoneNumber'] ?? '',
          'businessHours': data['businessHours'] ?? '',
          'isActive': data['isActive'] ?? false,
          'isApproved': data['isApproved'] ?? false,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'isVisited': false,
        });
        print('店舗を追加: ${data['name']}');
      }
      
      print('読み込んだ店舗数: ${stores.length}');
      
      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('店舗データの読み込みに失敗しました: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('店舗一覧'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStores,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
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
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '再試行',
              onPressed: _loadStores,
            ),
          ],
        ),
      );
    }

    if (_stores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '店舗が見つかりませんでした',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4列
          childAspectRatio: 0.8, // 縦長の比率
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _stores.length,
        itemBuilder: (context, index) {
          final store = _stores[index];
          return _buildStoreCard(store);
        },
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoreDetailView(store: store),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 店舗アイコン
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCategoryColor(store['category']).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getCategoryColor(store['category']).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: store['iconImageUrl']?.isNotEmpty == true
                  ? ClipOval(
                      child: Image.network(
                        store['iconImageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getCategoryIcon(store['category']),
                            color: _getCategoryColor(store['category']),
                            size: 30,
                          );
                        },
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(store['category']),
                      color: _getCategoryColor(store['category']),
                      size: 30,
                    ),
            ),
            
            const SizedBox(height: 8),
            
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                store['name'] ?? '店舗名なし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // カテゴリ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getCategoryColor(store['category']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getCategoryColor(store['category']).withOpacity(0.3),
                ),
              ),
              child: Text(
                store['category'] ?? 'その他',
                style: TextStyle(
                  fontSize: 8,
                  color: _getCategoryColor(store['category']),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // カテゴリに応じた色を取得
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'レストラン':
        return Colors.red;
      case 'カフェ':
        return Colors.brown;
      case 'ショップ':
        return Colors.blue;
      case '美容院':
        return Colors.pink;
      case '薬局':
        return Colors.green;
      case 'コンビニ':
        return Colors.orange;
      case 'スーパー':
        return Colors.lightGreen;
      case '書店':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // カテゴリに応じたアイコンを取得
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'レストラン':
        return Icons.restaurant;
      case 'カフェ':
        return Icons.local_cafe;
      case 'ショップ':
        return Icons.shopping_bag;
      case '美容院':
        return Icons.content_cut;
      case '薬局':
        return Icons.local_pharmacy;
      case 'コンビニ':
        return Icons.store;
      case 'スーパー':
        return Icons.shopping_cart;
      case '書店':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }

}
