import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/qr_token_provider.dart';
import '../../widgets/custom_button.dart';
import '../payment/point_payment_view.dart';

class QRGeneratorView extends ConsumerStatefulWidget {
  const QRGeneratorView({Key? key}) : super(key: key);

  @override
  ConsumerState<QRGeneratorView> createState() => _QRGeneratorViewState();
}

class _QRGeneratorViewState extends ConsumerState<QRGeneratorView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _scannerController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController();
    
    // タブ変更を監視して、QRコードを読み取るタブが選択された時にカメラを開始
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _startScanning();
      } else {
        _stopScanning();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード'),
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildQRCodeList(context),
              _buildQRScanner(context),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error'),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFF6B35),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code),
              text: 'QRコード',
            ),
            Tab(
              icon: Icon(Icons.qr_code_scanner),
              text: 'QRコードを読み取る',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeList(BuildContext context) {
    final qrTokenState = ref.watch(qrTokenProvider);
    
    // デバッグログ
    print('QRGeneratorView: QRTokenState - isLoading: ${qrTokenState.isLoading}, hasToken: ${qrTokenState.hasToken}, error: ${qrTokenState.error}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QRコード表示
          _buildQRCodeDisplay(context, qrTokenState),
        ],
      ),
    );
  }

  Widget _buildQRCodeDisplay(BuildContext context, QRTokenState qrTokenState) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 残り時間表示
            if (qrTokenState.hasToken) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: qrTokenState.remainingSeconds > 10 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: qrTokenState.remainingSeconds > 10 
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: qrTokenState.remainingSeconds > 10 ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '更新まで ${qrTokenState.remainingSeconds} 秒',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: qrTokenState.remainingSeconds > 10 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // QRコード画像
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildQRCodeContent(qrTokenState),
            ),
            const SizedBox(height: 16),
            
            // エラー表示
            if (qrTokenState.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        qrTokenState.error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(qrTokenProvider.notifier).clearError();
                        ref.read(qrTokenProvider.notifier).refreshToken();
                      },
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 説明テキスト
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFFF6B35),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'このQRコードは60秒ごとに自動更新されます。店舗でスキャンしてもらうとポイントが付与されます。',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeContent(QRTokenState qrTokenState) {
    if (qrTokenState.isLoading) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('トークンを生成中...'),
            ],
          ),
        ),
      );
    }

    if (!qrTokenState.hasToken) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('トークンを取得できませんでした'),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        QrImageView(
          data: qrTokenState.token!,
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QRコード文字列:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                qrTokenState.token!,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildQRScanner(BuildContext context) {
    if (!_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: Color(0xFFFF6B35),
            ),
            const SizedBox(height: 24),
            const Text(
              'QRコードをスキャン',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'カメラをQRコードに向けて\nスキャンしてください',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'スキャンを開始',
              onPressed: () {
                _startScanning();
              },
              backgroundColor: const Color(0xFFFF6B35),
              icon: const Icon(Icons.qr_code_scanner, size: 20),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _showManualInputDialog(context);
              },
              child: const Text(
                '手動でQRコードを入力',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _handleQRCodeDetected(context, code);
              }
            }
          },
        ),
        // スキャンエリアのオーバーレイ
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'QRコードをここに合わせてください',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        // 停止ボタン
        Positioned(
          top: 50,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              _stopScanning();
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  void _handleQRCodeDetected(BuildContext context, String code) {
    _stopScanning();
    _processQRCode(context, code);
  }

  void _showManualInputDialog(BuildContext context) {
    final TextEditingController qrCodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコードを手動入力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('QRコードの内容を入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: qrCodeController,
              decoration: const InputDecoration(
                labelText: 'QRコード',
                hintText: 'store001',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final qrCode = qrCodeController.text.trim();
              Navigator.of(context).pop();
              if (qrCode.isNotEmpty) {
                _processQRCode(context, qrCode);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QRコードを入力してください'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('処理'),
          ),
        ],
      ),
    );
  }

  void _processQRCode(BuildContext context, String qrCode) async {
    print('QRコード処理開始: $qrCode');
    
    if (qrCode.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QRコードを入力してください'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // QRコードの形式をチェック（店舗IDかどうか）
    final isStoreId = _isStoreId(qrCode);
    print('店舗ID判定結果: $isStoreId');
    
    if (isStoreId) {
      print('店舗IDとして処理: $qrCode');
      // 店舗IDの場合、存在確認してからポイント支払い画面に遷移
      await _validateStoreAndNavigate(context, qrCode);
    } else {
      print('その他のQRコードとして処理: $qrCode');
      // その他のQRコードの場合、従来の処理
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('QRコード処理完了'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text('QRコード: $qrCode'),
                const SizedBox(height: 8),
                const Text('10ポイントを獲得しました！'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // 店舗の存在確認とナビゲーション
  Future<void> _validateStoreAndNavigate(BuildContext context, String storeId) async {
    print('店舗存在確認開始: $storeId');
    
    // ローディング表示
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      ),
    );
    
    try {
      print('Firestoreで店舗を検索中: $storeId');
      // 店舗の存在確認
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      print('店舗ドキュメント取得完了: ${doc.exists}');

      // ローディングを必ず閉じる
      if (context.mounted) {
        Navigator.of(context).pop(); // ローディングダイアログを閉じる
      }

      if (!doc.exists) {
        print('店舗が存在しません: $storeId');
        // 店舗が存在しない場合
        if (context.mounted) {
          _showErrorDialog(
            context,
            'この店舗は存在しません',
            '店舗ID: $storeId',
          );
        }
        return;
      }

      print('店舗が存在します。ポイント支払い画面に遷移: $storeId');
      // 店舗が存在する場合、ポイント支払い画面に遷移
      if (context.mounted) {
        print('Navigator.push開始');
        try {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                print('PointPaymentView作成開始');
                return PointPaymentView(storeId: storeId);
              },
            ),
          );
          print('ポイント支払い画面への遷移完了');
        } catch (e) {
          print('画面遷移エラー: $e');
          if (context.mounted) {
            _showErrorDialog(
              context,
              '画面遷移に失敗しました',
              'エラー: $e',
            );
          }
        }
      }
    } catch (e) {
      print('店舗存在確認エラー: $e');
      // エラーが発生した場合
      if (context.mounted) {
        // ローディングを必ず閉じる
        Navigator.of(context).pop(); // ローディングダイアログを閉じる
        
        _showErrorDialog(
          context,
          '店舗情報の確認中にエラーが発生しました',
          'エラー: $e',
        );
      }
    }
  }

  // エラーダイアログを表示する共通メソッド
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 店舗IDかどうかを判定する関数
  bool _isStoreId(String qrCode) {
    // より柔軟な店舗ID判定
    // 5文字以上の英数字で、特殊文字を含まない場合を店舗IDと判定
    if (qrCode.length >= 5) {
      // 英数字のみかチェック
      return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(qrCode);
    }
    return false;
  }

}
