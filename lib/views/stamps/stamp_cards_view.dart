import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stamp_card_widget.dart';

class StampCardsView extends StatefulWidget {
  const StampCardsView({Key? key, this.showAppBar = true}) : super(key: key);

  final bool showAppBar;

  @override
  State<StampCardsView> createState() => _StampCardsViewState();
}

class _StampCardsViewState extends State<StampCardsView> {
  List<Map<String, dynamic>> _stampCards = [];
  bool _isLoading = true;
  String? _error;
  bool _needsAuth = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _needsAuth = true;
          _stampCards = [];
          _error = null;
          _isLoading = false;
        });
        return;
      }
      _needsAuth = false;
      _loadStampCards();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // スタンプカードデータを読み込む
  Future<void> _loadStampCards() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _needsAuth = false;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _needsAuth = true;
          _isLoading = false;
          _error = null;
        });
        return;
      }

      print('スタンプカードの読み込みを開始...');
      
      // 新しい構造: users/{userId}/stores から直接取得
      final QuerySnapshot userStoresSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .get();

      print('取得したユーザー店舗数: ${userStoresSnapshot.docs.length}');
      
      final List<Map<String, dynamic>> stampCards = [];
      
      for (final userStoreDoc in userStoresSnapshot.docs) {
        final userStoreData = userStoreDoc.data() as Map<String, dynamic>;
        final storeId = userStoreDoc.id;
        
        // 店舗の詳細情報を取得
        final storeDocSnapshot = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
        
        if (!storeDocSnapshot.exists) {
          print('店舗が見つかりません: $storeId');
          continue;
        }
        
        final storeData = storeDocSnapshot.data() as Map<String, dynamic>;
        
        // 店舗がアクティブで承認済みかチェック
        final isActive = storeData['isActive'] as bool? ?? false;
        final isApproved = storeData['isApproved'] as bool? ?? false;
        
        if (!isActive || !isApproved) {
          print('店舗がアクティブでないか承認されていません: $storeId');
          continue;
        }
        
        // ユーザーのスタンプデータを取得
        final stamps = userStoreData['stamps'] as int? ?? 0;
        final lastVisited = userStoreData['lastVisited'];
        final totalSpendingRaw = userStoreData['totalSpending'];
        final totalSpending = (totalSpendingRaw is num) ? totalSpendingRaw.toDouble() : 0.0;
        
        stampCards.add({
          'storeId': storeId,
          'storeName': storeData['name'] ?? '店舗名なし',
          'storeCategory': storeData['category'] ?? 'その他',
          'iconImageUrl': storeData['iconImageUrl'],
          'stamps': stamps,
          'lastVisited': lastVisited,
          'totalSpending': totalSpending,
          'isActive': isActive,
          'isApproved': isApproved,
        });
      }
      
      // スタンプ数が多い順にソート
      stampCards.sort((a, b) => (b['stamps'] as int).compareTo(a['stamps'] as int));
      
      print('読み込んだスタンプカード数: ${stampCards.length}');
      
      if (mounted) {
        setState(() {
          _stampCards = stampCards;
          _isLoading = false;
          _needsAuth = false;
        });
      }
    } catch (e) {
      print('スタンプカードデータの読み込みに失敗しました: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _needsAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (!widget.showAppBar) {
      return Container(
        color: Colors.grey[50],
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('スタンプカード'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_needsAuth) {
      return _buildAuthRequired(context);
    }

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
            ElevatedButton(
              onPressed: _loadStampCards,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_stampCards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'スタンプカードがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '店舗を訪れてスタンプを集めましょう！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStampCards,
      color: const Color(0xFFFF6B35),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stampCards.length,
        itemBuilder: (context, index) {
          final stampCard = _stampCards[index];
          return _buildStampCard(stampCard);
        },
      ),
    );
  }

  Widget _buildAuthRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ログインが必要です',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240,
              child: CustomButton(
                text: 'ログイン',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signin');
                },
                backgroundColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 240,
              child: CustomButton(
                text: '新規アカウント作成',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signup');
                },
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampCard(Map<String, dynamic> stampCard) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: StampCardWidget(
        storeName: stampCard['storeName'] as String,
        storeCategory: stampCard['storeCategory'] as String,
        iconImageUrl: stampCard['iconImageUrl'] as String?,
        stamps: stampCard['stamps'] as int,
        maxStamps: 10,
      ),
    );
  }
}
