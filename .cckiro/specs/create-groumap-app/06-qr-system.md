# QRコード機能設計

## 6. セキュアQRコード機能設計

### 6.1 JWT ベース時間制限付きQRコード
```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SecureQRService {
  // JWTシークレット（Firebase Functions環境変数から取得）
  static const String _jwtSecret = 'your-super-secure-jwt-secret-key-here';
  
  // QRコードの有効期限（60秒）
  static const int _qrValiditySeconds = 60;
  
  // 時間窓の間隔（60秒）
  static const int _timeWindowSeconds = 60;

  /// セキュアなユーザー用QRコード生成（ポイント獲得用）
  static String generateSecureUserQRCode(String userId) {
    final currentTimeWindow = _getCurrentTimeWindow();
    
    final payload = {
      'type': 'user_point_earn',
      'userId': userId,
      'timeWindow': currentTimeWindow,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000, // issued at
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + _qrValiditySeconds, // expires
      'nonce': _generateNonce(), // 重複防止のランダム値
    };
    
    final jwt = _generateJWT(payload);
    return jwt;
  }
  
  /// セキュアな店舗用QRコード生成（ポイント利用用）
  static String generateSecureStoreQRCode(String storeId) {
    final currentTimeWindow = _getCurrentTimeWindow();
    
    final payload = {
      'type': 'store_point_use',
      'storeId': storeId,
      'timeWindow': currentTimeWindow,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + _qrValiditySeconds,
      'nonce': _generateNonce(),
    };
    
    final jwt = _generateJWT(payload);
    return jwt;
  }

  /// QRコード検証・処理
  static Future<QRResult> processSecureQRCode(String jwtToken, String readerId) async {
    try {
      // JWTの基本検証
      if (!_isJWTValid(jwtToken)) {
        return QRResult.error('無効なQRコードです');
      }
      
      // トークンをデコード
      final payload = _decodeJWT(jwtToken);
      if (payload == null) {
        return QRResult.error('QRコードの解析に失敗しました');
      }
      
      // 有効期限チェック
      final exp = payload['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime > exp) {
        return QRResult.error('QRコードの有効期限が切れています');
      }
      
      // 時間窓の検証
      final qrTimeWindow = payload['timeWindow'] as int;
      final currentTimeWindow = _getCurrentTimeWindow();
      
      // 現在の時間窓または直前の時間窓のみ有効（60秒の猶予）
      if (qrTimeWindow != currentTimeWindow && qrTimeWindow != (currentTimeWindow - 1)) {
        return QRResult.error('QRコードの有効期限が切れています');
      }
      
      // 重複使用チェック（Firebase Functionsで実装）
      final nonce = payload['nonce'] as String;
      final isUsed = await _checkQRUsage(nonce, readerId);
      if (isUsed) {
        return QRResult.error('既に使用されたQRコードです');
      }
      
      // QRコードタイプに基づく処理
      switch (payload['type']) {
        case 'user_point_earn':
          // 使用履歴を記録
          await _recordQRUsage(nonce, readerId, payload['userId']);
          return QRResult.userPointEarn(payload['userId']);
          
        case 'store_point_use':
          // 使用履歴を記録
          await _recordQRUsage(nonce, readerId, payload['storeId']);
          return QRResult.storePointUse(payload['storeId']);
          
        default:
          return QRResult.error('未知のQRコードタイプです');
      }
      
    } catch (e) {
      return QRResult.error('QRコードの処理中にエラーが発生しました: $e');
    }
  }

  /// 現在の時間窓を取得（60秒単位）
  static int _getCurrentTimeWindow() {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return currentTime ~/ _timeWindowSeconds;
  }

  /// ランダムなnonce値を生成
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// JWT生成
  static String _generateJWT(Map<String, dynamic> payload) {
    // ヘッダー
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };
    
    // Base64エンコード
    final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
    final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
    
    // 署名生成
    final signatureInput = '$encodedHeader.$encodedPayload';
    final signature = _generateSignature(signatureInput);
    
    return '$encodedHeader.$encodedPayload.$signature';
  }

  /// JWT検証
  static bool _isJWTValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      // 署名検証
      final signatureInput = '${parts[0]}.${parts[1]}';
      final expectedSignature = _generateSignature(signatureInput);
      
      return parts[2] == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  /// JWTデコード
  static Map<String, dynamic>? _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payloadJson = utf8.decode(base64Url.decode(parts[1]));
      return jsonDecode(payloadJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// HMAC署名生成
  static String _generateSignature(String input) {
    final key = utf8.encode(_jwtSecret);
    final bytes = utf8.encode(input);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  /// QRコード使用履歴チェック（Firebase Functions）
  static Future<bool> _checkQRUsage(String nonce, String readerId) async {
    // Firebase Functions呼び出し
    try {
      final response = await _callFirebaseFunction('checkQRUsage', {
        'nonce': nonce,
        'readerId': readerId,
      });
      
      return response['used'] as bool? ?? false;
    } catch (e) {
      // エラーの場合は安全側に倒して使用済みとして扱う
      return true;
    }
  }

  /// QRコード使用履歴記録（Firebase Functions）
  static Future<void> _recordQRUsage(String nonce, String readerId, String targetId) async {
    try {
      await _callFirebaseFunction('recordQRUsage', {
        'nonce': nonce,
        'readerId': readerId,
        'targetId': targetId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // ログ記録失敗は処理を継続
      print('QR使用履歴の記録に失敗: $e');
    }
  }

  /// Firebase Functions呼び出しヘルパー
  static Future<Map<String, dynamic>> _callFirebaseFunction(String functionName, Map<String, dynamic> data) async {
    // Firebase Functions への HTTP リクエスト実装
    // 実際の実装では firebase_functions パッケージまたは http パッケージを使用
    throw UnimplementedError('Firebase Functions呼び出しの実装が必要');
  }
}

/// QRコード結果クラス
class QRResult {
  final QRResultType type;
  final String? targetId;
  final String? error;

  QRResult._(this.type, this.targetId, this.error);

  factory QRResult.userPointEarn(String userId) => QRResult._(QRResultType.userPointEarn, userId, null);
  factory QRResult.storePointUse(String storeId) => QRResult._(QRResultType.storePointUse, storeId, null);
  factory QRResult.error(String message) => QRResult._(QRResultType.error, null, message);

  bool get isSuccess => type != QRResultType.error;
  bool get isError => type == QRResultType.error;
}

enum QRResultType {
  userPointEarn,
  storePointUse,
  error,
}
```

### 6.2 動的QRコード表示Widget
```dart
class DynamicQRCodeWidget extends StatefulWidget {
  final String userId;
  final String storeId;
  final QRCodeType qrType;

  const DynamicQRCodeWidget({
    Key? key,
    required this.qrType,
    this.userId = '',
    this.storeId = '',
  }) : super(key: key);

  @override
  _DynamicQRCodeWidgetState createState() => _DynamicQRCodeWidgetState();
}

class _DynamicQRCodeWidgetState extends State<DynamicQRCodeWidget> {
  Timer? _refreshTimer;
  String _currentQRData = '';
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateQRCode() {
    switch (widget.qrType) {
      case QRCodeType.userPointEarn:
        _currentQRData = SecureQRService.generateSecureUserQRCode(widget.userId);
        break;
      case QRCodeType.storePointUse:
        _currentQRData = SecureQRService.generateSecureStoreQRCode(widget.storeId);
        break;
    }
    
    // カウントダウンリセット
    setState(() {
      _countdown = 60;
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        _generateQRCode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QRコード表示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: _currentQRData,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // カウントダウンタイマー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _countdown <= 10 ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _countdown <= 10 ? Colors.red : Colors.blue,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: _countdown <= 10 ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'あと ${_countdown}秒で更新',
                style: TextStyle(
                  fontSize: 14,
                  color: _countdown <= 10 ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // セキュリティ説明
        Text(
          'セキュリティのため60秒ごとにQRコードが自動更新されます',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        
        // 手動更新ボタン
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _generateQRCode,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('手動更新'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

enum QRCodeType {
  userPointEarn,
  storePointUse,
}
```

### 6.3 Firebase Functions（サーバーサイド検証）
```typescript
// Firebase Functions での QR コード検証
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';

const JWT_SECRET = functions.config().security.jwt_secret;

// QRコード使用履歴チェック
export const checkQRUsage = functions.https.onCall(async (data, context) => {
  const { nonce, readerId } = data;
  
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ユーザー認証が必要です');
  }
  
  try {
    // Firestore でnonce の使用履歴をチェック
    const usageDoc = await admin.firestore()
      .collection('qr_usage_history')
      .doc(`${nonce}_${readerId}`)
      .get();
    
    return { used: usageDoc.exists };
  } catch (error) {
    console.error('QR使用履歴チェックエラー:', error);
    throw new functions.https.HttpsError('internal', 'サーバーエラーが発生しました');
  }
});

// QRコード使用履歴記録
export const recordQRUsage = functions.https.onCall(async (data, context) => {
  const { nonce, readerId, targetId, timestamp } = data;
  
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ユーザー認証が必要です');
  }
  
  try {
    // 使用履歴を記録
    await admin.firestore()
      .collection('qr_usage_history')
      .doc(`${nonce}_${readerId}`)
      .set({
        nonce,
        readerId,
        targetId,
        timestamp,
        userId: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    
    return { success: true };
  } catch (error) {
    console.error('QR使用履歴記録エラー:', error);
    throw new functions.https.HttpsError('internal', 'サーバーエラーが発生しました');
  }
});

// QRコード検証（サーバーサイド）
export const verifySecureQR = functions.https.onCall(async (data, context) => {
  const { token, readerId } = data;
  
  try {
    // JWT検証
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    
    // 有効期限チェック（追加の安全策）
    const currentTime = Math.floor(Date.now() / 1000);
    if (currentTime > decoded.exp) {
      throw new Error('QRコードの有効期限が切れています');
    }
    
    // 時間窓チェック
    const currentTimeWindow = Math.floor(currentTime / 60);
    if (decoded.timeWindow !== currentTimeWindow && decoded.timeWindow !== (currentTimeWindow - 1)) {
      throw new Error('QRコードの有効期限が切れています');
    }
    
    // 重複使用チェック
    const usageDoc = await admin.firestore()
      .collection('qr_usage_history')
      .doc(`${decoded.nonce}_${readerId}`)
      .get();
    
    if (usageDoc.exists) {
      throw new Error('既に使用されたQRコードです');
    }
    
    return {
      valid: true,
      type: decoded.type,
      targetId: decoded.type === 'user_point_earn' ? decoded.userId : decoded.storeId,
      nonce: decoded.nonce,
    };
    
  } catch (error) {
    console.error('QR検証エラー:', error);
    throw new functions.https.HttpsError('invalid-argument', error.message || 'QRコードが無効です');
  }
});
```

### 6.4 QRコード読み取りフロー詳細設計

#### 6.4.1 店舗用アプリ - 支払い金額入力画面
```dart
class PaymentAmountInputScreen extends ConsumerStatefulWidget {
  final String scannedUserId;
  
  const PaymentAmountInputScreen({
    Key? key,
    required this.scannedUserId,
  }) : super(key: key);

  @override
  ConsumerState<PaymentAmountInputScreen> createState() => _PaymentAmountInputScreenState();
}

class _PaymentAmountInputScreenState extends ConsumerState<PaymentAmountInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0.0;
  int _calculatedPoints = 0;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(currentStoreProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('支払い金額入力'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // お客様情報表示
            _buildCustomerInfo(),
            const SizedBox(height: 32),
            
            // 支払い金額入力
            _buildAmountInput(),
            const SizedBox(height: 24),
            
            // 獲得ポイント表示
            _buildPointsPreview(),
            const SizedBox(height: 32),
            
            // 確定ボタン
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'お客様',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'ユーザーID: ${widget.scannedUserId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '支払い金額',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixText: '¥ ',
            prefixStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _amount = double.tryParse(value) ?? 0.0;
              _calculatedPoints = (_amount ~/ 100); // 100円 = 1ポイント
            });
          },
        ),
      ],
    );
  }

  Widget _buildPointsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '獲得予定ポイント',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_calculatedPoints}P',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _amount > 0 ? _onConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '確定',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    // ユーザーアプリに獲得ポイント確認画面を表示させるため、
    // Firebase Functions を通じて通知を送信
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PointAwardConfirmationScreen(
          userId: widget.scannedUserId,
          amount: _amount,
          points: _calculatedPoints,
        ),
      ),
    );
  }
}
```

#### 6.4.2 ユーザーアプリ - 獲得ポイント確認画面
```dart
class PointEarnConfirmationScreen extends ConsumerStatefulWidget {
  final double amount;
  final int points;
  final String storeId;
  
  const PointEarnConfirmationScreen({
    Key? key,
    required this.amount,
    required this.points,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<PointEarnConfirmationScreen> createState() => _PointEarnConfirmationScreenState();
}

class _PointEarnConfirmationScreenState extends ConsumerState<PointEarnConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider(widget.storeId));
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ポイント獲得確認'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 店舗情報
                  store.when(
                    data: (storeData) => _buildStoreInfo(storeData),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => const Text('店舗情報の取得に失敗しました'),
                  ),
                  const SizedBox(height: 32),
                  
                  // 支払い金額
                  _buildAmountInfo(),
                  const SizedBox(height: 24),
                  
                  // 獲得ポイント
                  _buildPointsInfo(),
                  const SizedBox(height: 32),
                  
                  // 説明テキスト
                  Text(
                    'ポイントを獲得しますか？',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // ボタン
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo(StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              store.images.isNotEmpty ? store.images.first : '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.store),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  store.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'お支払い金額',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '¥${NumberFormat('#,###').format(widget.amount)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '獲得ポイント',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.card_giftcard,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.points}P',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _onDecline,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '辞退',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '獲得',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onDecline() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _onAccept() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PointEarnAnimationScreen(
          amount: widget.amount,
          points: widget.points,
          storeId: widget.storeId,
        ),
      ),
    );
  }
}
```

#### 6.4.3 ポイント獲得アニメーション画面
```dart
class PointEarnAnimationScreen extends ConsumerStatefulWidget {
  final double amount;
  final int points;
  final String storeId;
  
  const PointEarnAnimationScreen({
    Key? key,
    required this.amount,
    required this.points,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<PointEarnAnimationScreen> createState() => _PointEarnAnimationScreenState();
}

class _PointEarnAnimationScreenState extends ConsumerState<PointEarnAnimationScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pointsAnimationController;
  late AnimationController _totalPointsAnimationController;
  late Animation<double> _pointsScaleAnimation;
  late Animation<int> _totalPointsCountAnimation;
  
  int _previousTotalPoints = 0;
  int _newTotalPoints = 0;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserPoints();
    _performPointsTransaction();
  }

  void _setupAnimations() {
    _pointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _totalPointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pointsScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pointsAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _loadUserPoints() async {
    final user = ref.read(userProvider);
    if (user != null) {
      setState(() {
        _previousTotalPoints = user.totalPoints;
        _newTotalPoints = _previousTotalPoints + widget.points;
      });

      _totalPointsCountAnimation = IntTween(
        begin: _previousTotalPoints,
        end: _newTotalPoints,
      ).animate(CurvedAnimation(
        parent: _totalPointsAnimationController,
        curve: Curves.easeOutCubic,
      ));
    }
  }

  void _performPointsTransaction() async {
    // ポイント獲得処理をFirebase Functionsで実行
    try {
      await ref.read(pointServiceProvider).awardPoints(
        userId: ref.read(userProvider)!.userId,
        storeId: widget.storeId,
        points: widget.points,
        amount: widget.amount,
      );

      // アニメーション開始
      _pointsAnimationController.forward();
      
      Timer(const Duration(milliseconds: 800), () {
        _totalPointsAnimationController.forward().then((_) {
          setState(() {
            _animationCompleted = true;
          });
        });
      });

    } catch (e) {
      // エラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ポイント獲得に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ポイント獲得表示
                    AnimatedBuilder(
                      animation: _pointsScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pointsScaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '+${widget.points}P',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text(
                                  '獲得！',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // 総ポイント数アニメーション
                    AnimatedBuilder(
                      animation: _totalPointsCountAnimation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            const Text(
                              '総ポイント',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${NumberFormat('#,###').format(_totalPointsCountAnimation.value)}P',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // 次へボタン
              if (_animationCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToStampScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '次へ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToStampScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => StampPresentationScreen(storeId: widget.storeId),
      ),
    );
  }

  @override
  void dispose() {
    _pointsAnimationController.dispose();
    _totalPointsAnimationController.dispose();
    super.dispose();
  }
}
```

#### 6.4.4 スタンプ押印画面
```dart
class StampPresentationScreen extends ConsumerStatefulWidget {
  final String storeId;
  
  const StampPresentationScreen({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<StampPresentationScreen> createState() => _StampPresentationScreenState();
}

class _StampPresentationScreenState extends ConsumerState<StampPresentationScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _stampAnimationController;
  late Animation<double> _stampScaleAnimation;
  late Animation<double> _stampOpacityAnimation;
  bool _stampCompleted = false;

  @override
  void initState() {
    super.initState();
    _setupStampAnimation();
    _performStamping();
  }

  void _setupStampAnimation() {
    _stampAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _stampScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stampAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _stampOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stampAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
  }

  void _performStamping() async {
    try {
      // スタンプ記録処理
      await ref.read(stampServiceProvider).addStamp(
        userId: ref.read(userProvider)!.userId,
        storeId: widget.storeId,
      );

      // アニメーション開始
      _stampAnimationController.forward().then((_) {
        setState(() {
          _stampCompleted = true;
        });
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('スタンプの記録に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider(widget.storeId));
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 店舗情報
                    store.when(
                      data: (storeData) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              storeData.images.isNotEmpty ? storeData.images.first : '',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.store, size: 60),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            storeData.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => const Text('店舗情報の取得に失敗しました'),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // スタンプ押印アニメーション
                    AnimatedBuilder(
                      animation: _stampAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _stampOpacityAnimation.value,
                          child: Transform.scale(
                            scale: _stampScaleAnimation.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 4,
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 60,
                                    color: AppColors.primary,
                                  ),
                                  Text(
                                    'スタンプ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      'スタンプを獲得しました！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 次へボタン
              if (_stampCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToBadgeScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '次へ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToBadgeScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BadgeAwardScreen(storeId: widget.storeId),
      ),
    );
  }

  @override
  void dispose() {
    _stampAnimationController.dispose();
    super.dispose();
  }
}
```

#### 6.4.5 バッジ獲得アニメーション画面
```dart
class BadgeAwardScreen extends ConsumerStatefulWidget {
  final String storeId;
  
  const BadgeAwardScreen({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<BadgeAwardScreen> createState() => _BadgeAwardScreenState();
}

class _BadgeAwardScreenState extends ConsumerState<BadgeAwardScreen>
    with TickerProviderStateMixin {
  
  List<BadgeModel> _newlyAwardedBadges = [];
  int _currentBadgeIndex = 0;
  late AnimationController _badgeAnimationController;
  late Animation<double> _badgeRotationAnimation;
  late Animation<double> _badgeScaleAnimation;
  bool _allBadgesShown = false;

  @override
  void initState() {
    super.initState();
    _setupBadgeAnimation();
    _checkAndAwardBadges();
  }

  void _setupBadgeAnimation() {
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _badgeRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _badgeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.bounceOut),
    ));
  }

  void _checkAndAwardBadges() async {
    try {
      // バッジ獲得条件チェック
      final badges = await ref.read(badgeServiceProvider).checkAndAwardBadges(
        userId: ref.read(userProvider)!.userId,
        storeId: widget.storeId,
      );

      setState(() {
        _newlyAwardedBadges = badges;
      });

      if (_newlyAwardedBadges.isNotEmpty) {
        _showNextBadge();
      } else {
        // バッジ獲得がない場合は直接ホームに遷移
        _goToHome();
      }

    } catch (e) {
      // エラーが発生してもホームに遷移
      _goToHome();
    }
  }

  void _showNextBadge() {
    if (_currentBadgeIndex < _newlyAwardedBadges.length) {
      _badgeAnimationController.reset();
      _badgeAnimationController.forward().then((_) {
        // 2秒後に次のバッジまたは完了画面
        Timer(const Duration(seconds: 2), () {
          setState(() {
            _currentBadgeIndex++;
          });
          
          if (_currentBadgeIndex < _newlyAwardedBadges.length) {
            _showNextBadge();
          } else {
            setState(() {
              _allBadgesShown = true;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_newlyAwardedBadges.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentBadge = _currentBadgeIndex < _newlyAwardedBadges.length
        ? _newlyAwardedBadges[_currentBadgeIndex]
        : _newlyAwardedBadges.last;

    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // バッジ獲得アニメーション
                    AnimatedBuilder(
                      animation: _badgeAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _badgeScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _badgeRotationAnimation.value * 3.14159,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getBadgeIcon(currentBadge.type),
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                  const Text(
                                    'バッジ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // バッジ名
                    Text(
                      currentBadge.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // バッジ説明
                    Text(
                      currentBadge.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 進行状況表示（複数バッジの場合）
                    if (_newlyAwardedBadges.length > 1)
                      Text(
                        '${_currentBadgeIndex + 1} / ${_newlyAwardedBadges.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              
              // 確認ボタン（全て表示完了後）
              if (_allBadgesShown)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '確認',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String badgeType) {
    switch (badgeType) {
      case 'first_visit':
        return Icons.star;
      case 'regular_customer':
        return Icons.favorite;
      case 'point_collector':
        return Icons.card_giftcard;
      case 'explorer':
        return Icons.explore;
      default:
        return Icons.emoji_events;
    }
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _badgeAnimationController.dispose();
    super.dispose();
  }
}
```

### 6.5 ポイント利用フロー詳細設計

#### 6.5.1 QRコード読み取り画面（カメラタブ）
```dart
class QRScanScreen extends ConsumerStatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends ConsumerState<QRScanScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  QRViewController? _qrController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'マイQRコード', icon: Icon(Icons.qr_code)),
            Tab(text: 'カメラで読み取り', icon: Icon(Icons.camera_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // マイQRコード表示画面
          _buildMyQRCodeTab(),
          
          // カメラで読み取り画面
          _buildCameraScanTab(),
        ],
      ),
    );
  }

  Widget _buildMyQRCodeTab() {
    // 既存のユーザーQRコード表示
    return const DynamicQRWidget(qrType: QRCodeType.userPointEarn);
  }

  Widget _buildCameraScanTab() {
    return Column(
      children: [
        Expanded(
          child: QRView(
            key: GlobalKey(debugLabel: 'QR'),
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColors.primary,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Column(
            children: [
              const Text(
                '店舗のQRコードを読み取ってください',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ポイント利用時は店頭のQRコードまたは店舗アプリのQRコードをスキャンしてください',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrController = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      _handleQRScanned(scanData);
    });
  }

  void _handleQRScanned(Barcode scanData) async {
    if (scanData.code == null) return;

    // QRコードの検証と処理
    try {
      final qrResult = await ref.read(secureQRServiceProvider)
          .processSecureQRCode(scanData.code!, 'user_scanner');

      if (qrResult.type == 'store_point_use') {
        // 店舗QRコード読み取り成功 → ポイント利用画面へ
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PointUsageInputScreen(
              storeId: qrResult.targetId,
            ),
          ),
        );
      } else {
        _showErrorDialog('このQRコードはポイント利用に使用できません');
      }

    } catch (e) {
      _showErrorDialog('QRコードの読み取りに失敗しました: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
```

#### 6.5.2 支払いポイント入力画面
```dart
class PointUsageInputScreen extends ConsumerStatefulWidget {
  final String storeId;
  
  const PointUsageInputScreen({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<PointUsageInputScreen> createState() => _PointUsageInputScreenState();
}

class _PointUsageInputScreenState extends ConsumerState<PointUsageInputScreen> {
  final TextEditingController _pointsController = TextEditingController();
  int _pointsToUse = 0;
  bool _isRotated = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final store = ref.watch(storeProvider(widget.storeId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント利用'),
        backgroundColor: AppColors.primary,
      ),
      body: user == null 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 店舗情報
                store.when(
                  data: (storeData) => _buildStoreInfo(storeData),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => const Text('店舗情報の取得に失敗しました'),
                ),
                const SizedBox(height: 24),
                
                // 利用可能ポイント表示
                _buildAvailablePoints(user.availablePoints),
                const SizedBox(height: 32),
                
                // ポイント入力フィールド
                _buildPointsInput(),
                const SizedBox(height: 32),
                
                // 確定ボタン
                _buildConfirmButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildStoreInfo(StoreModel store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              store.images.isNotEmpty ? store.images.first : '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.store),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  store.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePoints(int availablePoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '利用可能ポイント',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(availablePoints)}P',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '利用ポイント',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          transform: _isRotated 
            ? (Matrix4.identity()..rotateZ(3.14159)) // 180度回転
            : Matrix4.identity(),
          child: TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            textAlign: _isRotated ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontSize: _isRotated ? 48 : 24,
              fontWeight: FontWeight.bold,
              color: _isRotated ? Colors.red : AppColors.text,
            ),
            decoration: InputDecoration(
              suffixText: 'P',
              suffixStyle: TextStyle(
                fontSize: _isRotated ? 48 : 24,
                fontWeight: FontWeight.bold,
                color: _isRotated ? Colors.red : AppColors.primary,
              ),
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: _isRotated ? 48 : 24,
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: _isRotated ? 4 : 2,
                  color: _isRotated ? Colors.red : Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isRotated ? Colors.red : AppColors.primary,
                  width: _isRotated ? 4 : 2,
                ),
              ),
              contentPadding: EdgeInsets.all(_isRotated ? 24 : 16),
            ),
            enabled: !_isRotated,
            onChanged: (value) {
              setState(() {
                _pointsToUse = int.tryParse(value) ?? 0;
              });
            },
          ),
        ),
        if (_isRotated)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '店舗スタッフに画面をお見せください',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final user = ref.watch(userProvider);
    final canUsePoints = user != null && 
                        _pointsToUse > 0 && 
                        _pointsToUse <= user.availablePoints;

    if (_isRotated) {
      // 回転後は店舗スタッフ用の確定ボタン
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _executePointUsage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ポイント利用実行',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isRotated = false;
              });
            },
            child: const Text(
              '戻る',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      );
    } else {
      // 通常の確定ボタン
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canUsePoints ? _confirmPointUsage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '確定',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  void _confirmPointUsage() {
    setState(() {
      _isRotated = true;
    });
  }

  void _executePointUsage() async {
    try {
      final user = ref.read(userProvider)!;
      
      // Firebase Functionsでポイント利用処理
      await ref.read(pointServiceProvider).usePoints(
        userId: user.userId,
        storeId: widget.storeId,
        points: _pointsToUse,
      );

      // 成功ダイアログ表示後、ホームに戻る
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('ポイント利用完了'),
          content: Text('${_pointsToUse}ポイントを利用しました。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ポイント利用に失敗しました: $e')),
      );
      setState(() {
        _isRotated = false;
      });
    }
  }
}
```

#### 6.5.3 ポイント利用履歴データモデル
```dart
// ユーザー側のポイント利用履歴
class UserPointUsageHistory {
  final String usageId;
  final String userId;
  final String storeId;
  final String storeName;
  final int pointsUsed;
  final DateTime usedAt;
  final String status; // 'completed', 'pending', 'failed'

  const UserPointUsageHistory({
    required this.usageId,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.pointsUsed,
    required this.usedAt,
    required this.status,
  });

  factory UserPointUsageHistory.fromJson(Map<String, dynamic> json) {
    return UserPointUsageHistory(
      usageId: json['usageId'],
      userId: json['userId'],
      storeId: json['storeId'],
      storeName: json['storeName'],
      pointsUsed: json['pointsUsed'],
      usedAt: (json['usedAt'] as Timestamp).toDate(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usageId': usageId,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'pointsUsed': pointsUsed,
      'usedAt': Timestamp.fromDate(usedAt),
      'status': status,
    };
  }
}

// 店舗側のポイント利用履歴
class StorePointUsageHistory {
  final String usageId;
  final String storeId;
  final String userId;
  final String? userName; // ユーザー名（取得可能な場合）
  final int pointsUsed;
  final DateTime usedAt;
  final String status;
  final double? equivalentAmount; // ポイントの金額換算値

  const StorePointUsageHistory({
    required this.usageId,
    required this.storeId,
    required this.userId,
    this.userName,
    required this.pointsUsed,
    required this.usedAt,
    required this.status,
    this.equivalentAmount,
  });

  factory StorePointUsageHistory.fromJson(Map<String, dynamic> json) {
    return StorePointUsageHistory(
      usageId: json['usageId'],
      storeId: json['storeId'],
      userId: json['userId'],
      userName: json['userName'],
      pointsUsed: json['pointsUsed'],
      usedAt: (json['usedAt'] as Timestamp).toDate(),
      status: json['status'],
      equivalentAmount: json['equivalentAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usageId': usageId,
      'storeId': storeId,
      'userId': userId,
      'userName': userName,
      'pointsUsed': pointsUsed,
      'usedAt': Timestamp.fromDate(usedAt),
      'status': status,
      'equivalentAmount': equivalentAmount,
    };
  }
}
```

#### 6.5.4 ポイント利用処理サービス
```dart
class PointUsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> usePoints({
    required String userId,
    required String storeId,
    required int points,
  }) async {
    final usageId = _firestore.collection('user_point_usage').doc().id;
    final now = Timestamp.now();

    try {
      await _firestore.runTransaction((transaction) async {
        // ユーザーの利用可能ポイントを確認・減算
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('ユーザーが見つかりません');
        }

        final userData = userDoc.data()!;
        final availablePoints = userData['availablePoints'] as int;

        if (availablePoints < points) {
          throw Exception('利用可能ポイントが不足しています');
        }

        // ユーザーのポイントを減算
        transaction.update(userRef, {
          'availablePoints': availablePoints - points,
          'updatedAt': now,
        });

        // 店舗情報を取得
        final storeRef = _firestore.collection('stores').doc(storeId);
        final storeDoc = await transaction.get(storeRef);
        final storeName = storeDoc.exists ? storeDoc.data()!['name'] : 'Unknown Store';

        // ユーザー側のポイント利用履歴を記録
        final userUsageRef = _firestore.collection('user_point_usage').doc(usageId);
        transaction.set(userUsageRef, {
          'usageId': usageId,
          'userId': userId,
          'storeId': storeId,
          'storeName': storeName,
          'pointsUsed': points,
          'usedAt': now,
          'status': 'completed',
        });

        // 店舗側のポイント利用履歴を記録
        final storeUsageRef = _firestore.collection('store_point_usage').doc(usageId);
        transaction.set(storeUsageRef, {
          'usageId': usageId,
          'storeId': storeId,
          'userId': userId,
          'userName': userData['displayName'], // 取得可能な場合
          'pointsUsed': points,
          'usedAt': now,
          'status': 'completed',
          'equivalentAmount': points.toDouble(), // 1ポイント = 1円として換算
        });

        // 取引履歴に記録
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'storeId': storeId,
          'points': points,
          'type': 'redeem',
          'createdAt': now,
        });
      });

    } catch (e) {
      print('ポイント利用エラー: $e');
      rethrow;
    }
  }

  // ユーザー側のポイント利用履歴取得
  Stream<List<UserPointUsageHistory>> getUserPointUsageHistory(String userId) {
    return _firestore
        .collection('user_point_usage')
        .where('userId', isEqualTo: userId)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserPointUsageHistory.fromJson(doc.data()))
            .toList());
  }

  // 店舗側のポイント利用履歴取得
  Stream<List<StorePointUsageHistory>> getStorePointUsageHistory(String storeId) {
    return _firestore
        .collection('store_point_usage')
        .where('storeId', isEqualTo: storeId)
        .orderBy('usedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StorePointUsageHistory.fromJson(doc.data()))
            .toList());
  }
}
```

#### 6.5.5 Riverpodプロバイダー
```dart
// ポイント利用サービスプロバイダー
final pointUsageServiceProvider = Provider<PointUsageService>((ref) {
  return PointUsageService();
});

// ユーザー側ポイント利用履歴プロバイダー
final userPointUsageHistoryProvider = StreamProvider.family<List<UserPointUsageHistory>, String>((ref, userId) {
  return ref.watch(pointUsageServiceProvider).getUserPointUsageHistory(userId);
});

// 店舗側ポイント利用履歴プロバイダー
final storePointUsageHistoryProvider = StreamProvider.family<List<StorePointUsageHistory>, String>((ref, storeId) {
  return ref.watch(pointUsageServiceProvider).getStorePointUsageHistory(storeId);
});
```