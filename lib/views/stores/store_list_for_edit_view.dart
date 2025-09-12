import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_store_view.dart';

class StoreListForEditView extends StatefulWidget {
  const StoreListForEditView({super.key});

  @override
  State<StoreListForEditView> createState() => _StoreListForEditViewState();
}

class _StoreListForEditViewState extends State<StoreListForEditView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadUserStores();
  }

  Future<void> _loadUserStores() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _stores = storesSnapshot.docs
              .map((doc) => {
                    'storeId': doc.id,
                    'name': doc.data()['name'] ?? '店舗名なし',
                    'address': doc.data()['address'] ?? '',
                    'category': doc.data()['category'] ?? 'カフェ',
                    'iconImageUrl': doc.data()['iconImageUrl'],
                    'isActive': doc.data()['isActive'] ?? false,
                    'isApproved': doc.data()['isApproved'] ?? false,
                    'createdAt': doc.data()['createdAt'],
                  })
              .toList();
          
          // クライアント側で作成日時順にソート（新しい順）
          _stores.sort((a, b) {
            final aCreatedAt = a['createdAt'] as Timestamp?;
            final bCreatedAt = b['createdAt'] as Timestamp?;
            if (aCreatedAt == null && bCreatedAt == null) return 0;
            if (aCreatedAt == null) return 1;
            if (bCreatedAt == null) return -1;
            return bCreatedAt.compareTo(aCreatedAt);
          });
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗一覧の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editStore(String storeId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditStoreView(storeId: storeId),
      ),
    );

    if (result == true) {
      // 店舗情報が更新された場合、一覧を再読み込み
      _loadUserStores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '店舗情報変更',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '作成した店舗がありません',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '先に店舗を作成してください',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stores.length,
                  itemBuilder: (context, index) {
                    final store = _stores[index];
                    return _buildStoreCard(store);
                  },
                ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[200],
          backgroundImage: store['iconImageUrl'] != null
              ? NetworkImage(store['iconImageUrl'])
              : null,
          child: store['iconImageUrl'] == null
              ? const Icon(Icons.store, size: 30, color: Colors.grey)
              : null,
        ),
        title: Text(
          store['name'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              store['address'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(store['category']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    store['category'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (store['isApproved'])
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '承認済み',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '審査中',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () => _editStore(store['storeId']),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'カフェ':
        return Colors.brown;
      case 'レストラン':
        return Colors.red;
      case '居酒屋':
        return Colors.orange;
      case 'ファストフード':
        return Colors.yellow[700]!;
      case 'スイーツ':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
