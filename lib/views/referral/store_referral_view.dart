import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class StoreReferralView extends ConsumerStatefulWidget {
  const StoreReferralView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreReferralView> createState() => _StoreReferralViewState();
}

class _StoreReferralViewState extends ConsumerState<StoreReferralView> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return _buildStoreReferralContent(context, ref, user.uid);
        } else {
          return _buildAuthRequiredScaffold(context);
        }
      },
      loading: () => _buildLoadingScaffold(),
      error: (error, _) => _buildErrorScaffold(error),
    );
  }

  Widget _buildAuthRequiredScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('店舗紹介'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildAuthRequired(context),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('店舗紹介'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScaffold(Object error) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('店舗紹介'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text('エラー: $error'),
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

  Widget _buildStoreReferralContent(BuildContext context, WidgetRef ref, String userId) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('店舗紹介'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーセクション
            _buildHeaderSection(),
            
            const SizedBox(height: 24),
            
            // 店舗紹介コードセクション
            _buildStoreReferralCodeSection(context, ref, userId),
            
            const SizedBox(height: 24),
            
            // 紹介方法セクション
            _buildReferralStepsSection(),
            
            const SizedBox(height: 24),
            
            // 注意事項セクション
            _buildNoticeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF8A65),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.store,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            '店舗紹介でポイント獲得',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'あなたの店舗紹介コードを友達に教えて、\nお互いにポイントを獲得しましょう！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreReferralCodeSection(BuildContext context, WidgetRef ref, String userId) {
    return ref.watch(userDataProvider(userId)).when(
      data: (userData) {
        final storeReferralCode = userData?['storeReferralCode'] ?? 'コードなし';
        final storeReferralCount = userData?['storeReferralCount'] ?? 0;
        final storeReferralEarnings = userData?['storeReferralEarnings'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'あなたの店舗紹介コード',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // 紹介コード表示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '店舗紹介コード',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      storeReferralCode,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(context, storeReferralCode),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('コピー'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 統計情報
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.store,
                      label: '紹介した店舗',
                      value: '$storeReferralCount店舗',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.monetization_on,
                      label: '獲得ポイント',
                      value: '${storeReferralEarnings}pt',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Text('エラー: $error'),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFFFF6B35)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? const Color(0xFFFF6B35)).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? const Color(0xFFFF6B35),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: (color ?? const Color(0xFFFF6B35)).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStepsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '店舗紹介の方法',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStepItem(
            stepNumber: 1,
            title: '店舗紹介コードをコピー',
            description: '上記の店舗紹介コードをコピーして、紹介したい店舗に送信します。',
            icon: Icons.copy,
          ),
          
          const SizedBox(height: 16),
          
          _buildStepItem(
            stepNumber: 2,
            title: '店舗にコードを送信',
            description: 'メール、SNS、または直接連絡して店舗紹介コードを共有します。',
            icon: Icons.send,
          ),
          
          const SizedBox(height: 16),
          
          _buildStepItem(
            stepNumber: 3,
            title: '店舗が登録',
            description: '店舗があなたの紹介コードを使って登録すると、お互いにポイントを獲得できます。',
            icon: Icons.store,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ステップ番号
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // アイコン
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF6B35),
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // テキスト
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '注意事項',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 店舗紹介コードは1つの店舗につき1回のみ使用できます\n'
            '• 紹介された店舗が登録を完了すると、お互いにポイントを獲得できます\n'
            '• 不正な使用が発覚した場合、アカウントが停止される場合があります\n'
            '• 紹介コードの有効期限は特にありません',
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('店舗紹介コードをコピーしました'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ユーザーデータプロバイダー（usersコレクションから直接取得）
final userDataProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  try {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).handleError((error) {
      debugPrint('Error fetching user data: $error');
      return null;
    });
  } catch (e) {
    debugPrint('Error creating user data stream: $e');
    return Stream.value(null);
  }
});
