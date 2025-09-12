import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/qr_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class QRGeneratorView extends ConsumerStatefulWidget {
  const QRGeneratorView({Key? key}) : super(key: key);

  @override
  ConsumerState<QRGeneratorView> createState() => _QRGeneratorViewState();
}

class _QRGeneratorViewState extends ConsumerState<QRGeneratorView> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storeIdController = TextEditingController();
  
  QRCodeData? _generatedQRCode;
  bool _isGenerating = false;

  @override
  void dispose() {
    _pointsController.dispose();
    _descriptionController.dispose();
    _storeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード生成'),
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

          return _buildContent(context, user.uid);
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

  Widget _buildContent(BuildContext context, String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 生成されたQRコード表示
          if (_generatedQRCode != null) ...[
            _buildGeneratedQRCode(context),
            const SizedBox(height: 24),
          ],
          
          // QRコード生成フォーム
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QRコード情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 店舗ID
                    CustomTextField(
                      controller: _storeIdController,
                      labelText: '店舗ID',
                      hintText: 'store_001',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '店舗IDを入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // ポイント数
                    CustomTextField(
                      controller: _pointsController,
                      labelText: 'ポイント数',
                      hintText: '10',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ポイント数を入力してください';
                        }
                        final points = int.tryParse(value);
                        if (points == null || points <= 0) {
                          return '有効なポイント数を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 説明
                    CustomTextField(
                      controller: _descriptionController,
                      labelText: '説明（任意）',
                      hintText: 'お得なキャンペーン',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // 生成ボタン
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isGenerating ? '生成中...' : 'QRコードを生成',
                        onPressed: _isGenerating ? null : () => _generateQRCode(context, userId),
                        backgroundColor: const Color(0xFFFF6B35),
                        icon: const Icon(Icons.qr_code, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedQRCode(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '生成されたQRコード',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // QRコード画像
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: _generatedQRCode!.token,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            
            // QRコード情報
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ポイント: ${_generatedQRCode!.points}pt',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('店舗ID: ${_generatedQRCode!.storeId}'),
                  Text('有効期限: ${_formatDateTime(_generatedQRCode!.expiresAt)}'),
                  if (_generatedQRCode!.description != null) ...[
                    const SizedBox(height: 4),
                    Text('説明: ${_generatedQRCode!.description}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: '新しいQRコード',
                    onPressed: () {
                      setState(() {
                        _generatedQRCode = null;
                        _formKey.currentState?.reset();
                      });
                    },
                    backgroundColor: Colors.blue,
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: '共有',
                    onPressed: () {
                      _shareQRCode(context);
                    },
                    backgroundColor: Colors.orange,
                    icon: const Icon(Icons.share, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQRCode(BuildContext context, String userId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final qrService = QRService();
      final points = int.parse(_pointsController.text);
      
      final qrCode = await qrService.generateQRCode(
        storeId: _storeIdController.text,
        points: points,
        createdBy: userId,
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        expiresIn: const Duration(hours: 24),
      );

      setState(() {
        _generatedQRCode = qrCode;
        _isGenerating = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QRコードが生成されました'),
            backgroundColor: const Color(0xFFFF6B35),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QRコード生成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareQRCode(BuildContext context) {
    // TODO: 実際の共有機能を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('共有機能は準備中です'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
