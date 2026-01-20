import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/store_provider.dart';
import '../../providers/qr_token_provider.dart';
import '../../models/store_model.dart';
import '../../models/point_transaction_model.dart';
import 'payment_success_view.dart';

class PointPaymentView extends ConsumerStatefulWidget {
  final String storeId;
  
  PointPaymentView({
    Key? key,
    required this.storeId,
  }) : super(key: key) {
    print('PointPaymentView: コンストラクタ呼び出し - storeId: $storeId');
  }

  @override
  ConsumerState<PointPaymentView> createState() => _PointPaymentViewState();
}

class _PointPaymentViewState extends ConsumerState<PointPaymentView> {
  String _amount = '0';
  bool _isProcessing = false;
  int? _currentPoints;

  @override
  void initState() {
    super.initState();
    print('PointPaymentView: 初期化完了 - storeId: ${widget.storeId}');
    _loadCurrentPoints();
  }

  Future<void> _loadCurrentPoints() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.value;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _currentPoints = (data?['points'] as int?) ?? 0;
        });
      }
    } catch (e) {
      print('現在ポイント取得エラー: $e');
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else {
        _amount += number;
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _amount = '0';
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _onPayPressed() {
    final amount = int.tryParse(_amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('有効な金額を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showPaymentConfirmation(amount);
  }

  void _showPaymentConfirmation(int amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支払い確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 64, color: Color(0xFFFF6B35)),
            const SizedBox(height: 16),
            Text('${amount.toString()}ポイントを支払いますか？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processPayment(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('支払う'),
          ),
        ],
      ),
    );
  }

  void _processPayment(int amount) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 現在のユーザーを取得
      final authState = ref.read(authProvider);
      final user = authState.value;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 店舗情報を取得
      final storeAsync = ref.read(storeProvider(widget.storeId));
      final store = await storeAsync.when(
        data: (store) {
          if (store == null) {
            throw Exception('店舗情報が取得できませんでした');
          }
          return store;
        },
        loading: () {
          throw Exception('店舗情報の読み込み中です');
        },
        error: (error, stackTrace) {
          throw Exception('店舗情報の取得に失敗しました: $error');
        },
      );

      // ポイント残高をチェック（usersコレクションから取得）
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('ユーザー情報が見つかりません');
      }

      final userData = userDoc.data()!;
      final userPoints = userData['points'] as int? ?? 0;

      // ポイント残高が足りないかチェック
      if (userPoints < amount) {
        throw Exception('ポイントが不足しています。現在の残高: ${userPoints}ポイント');
      }

      // ポイントを消費し、取引IDを取得（DBへ記録もここで実施）
      final transactionId = await _useUserPoints(
        userId: user.uid,
        storeId: widget.storeId,
        storeName: store.name,
        points: amount,
        description: 'ポイント支払い',
      );

      // 画面上の現在ポイントを更新
      if (mounted) {
        setState(() {
          if (_currentPoints != null) {
            _currentPoints = (_currentPoints! - amount).clamp(0, 1 << 31);
          }
        });
      }

      // 取引情報を取得
      final transactionDoc = await FirebaseFirestore.instance
          .collection('point_transactions')
          .doc(widget.storeId)
          .collection(user.uid)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        throw Exception('取引情報の取得に失敗しました');
      }

      final transaction = PointTransactionModel.fromJson({
        ...transactionDoc.data()!,
        'transactionId': transactionDoc.id,
      });

      print('ポイント支払い履歴を作成しました: $transactionId');

      // 支払い完了画面に遷移
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessView(
              store: store,
              transaction: transaction,
              amount: amount,
            ),
          ),
        );
      }
    } catch (e) {
      print('支払い処理エラー: $e');
      if (mounted) {
        String errorMessage = '支払い処理に失敗しました';
        
        if (e.toString().contains('ポイントが不足しています')) {
          errorMessage = e.toString();
        } else if (e.toString().contains('ポイント残高が見つかりません')) {
          errorMessage = e.toString();
        } else if (e.toString().contains('ユーザーがログインしていません')) {
          errorMessage = 'ログインが必要です';
        } else if (e.toString().contains('店舗情報が取得できませんでした')) {
          errorMessage = '店舗情報の取得に失敗しました';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ユーザーのポイントを消費するメソッド
  Future<String> _useUserPoints({
    required String userId,
    required String storeId,
    required String storeName,
    required int points,
    required String description,
  }) async {
    try {
      // 取引履歴を作成
      final transactionId = FirebaseFirestore.instance.collection('point_transactions').doc().id;
      final now = DateTime.now();
      
      final transaction = PointTransactionModel(
        transactionId: transactionId,
        userId: userId,
        storeId: storeId,
        storeName: storeName,
        amount: -points, // 負の値で使用を表現
        paymentAmount: null,
        status: 'completed',
        paymentMethod: 'points',
        createdAt: now,
        updatedAt: now,
        description: description,
      );

      // 取引を記録（ネスト構造） point_transactions/{storeId}/{userId}/{transactionId}
      final batch = FirebaseFirestore.instance.batch();
      final nestedRef = FirebaseFirestore.instance
          .collection('point_transactions')
          .doc(storeId)
          .collection(userId)
          .doc(transactionId);
      batch.set(nestedRef, transaction.toJson());
      await batch.commit();

      // ユーザーのポイントを更新
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'points': FieldValue.increment(-points),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('ユーザーのポイントを消費しました: $pointsポイント');
      return transactionId;
    } catch (e) {
      throw Exception('ポイント使用に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // FutureProviderを使って店舗情報を取得
    final storeAsync = ref.watch(storeProvider(widget.storeId));
    
    print('PointPaymentView: build - storeId: ${widget.storeId}');
    print('PointPaymentView: storeAsync状態: ${storeAsync.runtimeType}');
    
    if (storeAsync is AsyncLoading) {
      print('PointPaymentView: ローディング中');
    } else if (storeAsync is AsyncData) {
      print('PointPaymentView: データ取得成功 - store: ${storeAsync.value?.name}');
    } else if (storeAsync is AsyncError) {
      print('PointPaymentView: エラー - ${storeAsync.error}');
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ポイント支払い'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 店舗情報セクション
          _buildStoreInfo(storeAsync),
          
          // 金額表示セクション
          _buildAmountDisplay(),
          
          // 電卓セクション
          Expanded(
            child: _buildCalculator(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo(AsyncValue<StoreModel?> storeAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: storeAsync.when(
        data: (store) {
          if (store == null) {
            return const Center(
              child: Text('店舗情報が見つかりません'),
            );
          }
          
          return Row(
            children: [
              // 店舗アイコン
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: store.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          store.images.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                store.name.isNotEmpty 
                                    ? store.name.substring(0, 1).toUpperCase()
                                    : '店',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          store.name.isNotEmpty 
                              ? store.name.substring(0, 1).toUpperCase()
                              : '店',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // 店舗情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name.isNotEmpty ? store.name : '店舗名なし',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.description.isNotEmpty ? store.description : '説明なし',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.address.isNotEmpty ? store.address : '住所なし',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'エラー: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(storeProvider(widget.storeId));
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            '支払い金額',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_amount}ポイント',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          if (_currentPoints != null) ...[
            const SizedBox(height: 8),
            Text(
              '現在のポイント: $_currentPoints',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 数字ボタン行1
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('1'),
                _buildNumberButton('2'),
                _buildNumberButton('3'),
              ],
            ),
          ),
          // 数字ボタン行2
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('4'),
                _buildNumberButton('5'),
                _buildNumberButton('6'),
              ],
            ),
          ),
          // 数字ボタン行3
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('7'),
                _buildNumberButton('8'),
                _buildNumberButton('9'),
              ],
            ),
          ),
          // 数字ボタン行4
          Expanded(
            child: Row(
              children: [
                _buildActionButton('C', _onClearPressed, Colors.red),
                _buildNumberButton('0'),
                _buildActionButton('⌫', _onBackspacePressed, Colors.orange),
              ],
            ),
          ),
          // 支払いボタン
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _onPayPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '支払う',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _onNumberPressed(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
