import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/point_provider.dart';
import '../../services/qr_service.dart';
import '../../widgets/custom_button.dart';
import 'qr_generator_view.dart';

class QRScannerView extends ConsumerStatefulWidget {
  const QRScannerView({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends ConsumerState<QRScannerView> {
  MobileScannerController? _scannerController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              _showGenerateQR(context, ref);
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

          return _buildQRContent(context, ref, user.uid);
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

  Widget _buildQRContent(BuildContext context, WidgetRef ref, String userId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // QRコードスキャンエリア
          Expanded(
            child: Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isScanning
                    ? _buildScannerView(context, ref, userId)
                    : _buildScannerPlaceholder(context, ref, userId),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // アクションボタン
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _isScanning ? 'スキャンを停止' : 'スキャンを開始',
                  onPressed: () {
                    if (_isScanning) {
                      _stopScanning();
                    } else {
                      _startScanning();
                    }
                  },
                  backgroundColor: _isScanning ? Colors.red : Colors.blue,
                  icon: Icon(
                    _isScanning ? Icons.stop : Icons.camera_alt,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'QRコードを生成',
                  onPressed: () {
                    _showGenerateQR(context, ref);
                  },
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.qr_code, size: 20),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 履歴ボタン
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: '使用履歴を見る',
              onPressed: () {
                _showQRHistory(context, ref, userId);
              },
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.history, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerPlaceholder(BuildContext context, WidgetRef ref, String userId) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.qr_code_scanner,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Text(
          'QRコードをスキャン',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'カメラをQRコードに向けてください',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerView(BuildContext context, WidgetRef ref, String userId) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _handleQRCodeDetected(context, ref, userId, code);
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

  void _handleQRCodeDetected(BuildContext context, WidgetRef ref, String userId, String code) {
    _stopScanning();
    _processQRCode(context, ref, userId, code);
  }

  Future<void> _processQRCode(BuildContext context, WidgetRef ref, String userId, String code) async {
    try {
      final qrService = QRService();
      final validationResult = await qrService.validateQRCode(code);
      
      if (!validationResult.isValid) {
        if (context.mounted) {
          _showErrorDialog(context, validationResult.error ?? 'QRコードの検証に失敗しました');
        }
        return;
      }
      
      final qrCodeData = validationResult.qrCodeData!;
      
      if (context.mounted) {
        _showQRCodeConfirmation(context, ref, userId, qrCodeData);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'QRコードの処理中にエラーが発生しました: $e');
      }
    }
  }

  void _showQRCodeConfirmation(BuildContext context, WidgetRef ref, String userId, QRCodeData qrCodeData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコード確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              '${qrCodeData.points}ポイントを獲得します',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '店舗ID: ${qrCodeData.storeId}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (qrCodeData.description != null) ...[
              const SizedBox(height: 4),
              Text(
                qrCodeData.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _useQRCode(context, ref, userId, qrCodeData);
            },
            child: const Text('使用する'),
          ),
        ],
      ),
    );
  }

  Future<void> _useQRCode(BuildContext context, WidgetRef ref, String userId, QRCodeData qrCodeData) async {
    try {
      final qrService = QRService();
      final pointProcessor = ref.read(pointProcessorProvider);
      
      // QRコードを使用済みにマーク
      await qrService.useQRCode(
        qrCodeId: qrCodeData.qrCodeId,
        userId: userId,
      );
      
      // ポイントを獲得
      await pointProcessor.earnPoints(
        userId: userId,
        storeId: qrCodeData.storeId,
        points: qrCodeData.points,
        description: qrCodeData.description ?? 'QRコード使用',
        qrCodeId: qrCodeData.qrCodeId,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${qrCodeData.points}ポイントを獲得しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'QRコード使用に失敗しました: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showGenerateQR(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRGeneratorView(),
      ),
    );
  }

  void _showQRHistory(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコード使用履歴'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<QRCodeData>>(
            future: QRService().getQRCodeHistory(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('エラー: ${snapshot.error}'),
                );
              }
              
              final qrCodes = snapshot.data ?? [];
              
              if (qrCodes.isEmpty) {
                return const Center(
                  child: Text('QRコード使用履歴がありません'),
                );
              }
              
              return ListView.builder(
                itemCount: qrCodes.length,
                itemBuilder: (context, index) {
                  final qrCode = qrCodes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.qr_code,
                        color: Colors.green,
                      ),
                      title: Text('${qrCode.points}ポイント獲得'),
                      subtitle: Text(
                        '店舗ID: ${qrCode.storeId}\n'
                        '使用日時: ${_formatDateTime(qrCode.usedAt ?? qrCode.createdAt)}',
                      ),
                      trailing: Text(
                        '+${qrCode.points}pt',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
