import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendReferralView extends StatefulWidget {
  const FriendReferralView({Key? key}) : super(key: key);

  @override
  State<FriendReferralView> createState() => _FriendReferralViewState();
}

class _FriendReferralViewState extends State<FriendReferralView> {
  String? _referralCode;
  bool _isLoading = true;
  String? _error;
  int _referralCount = 0;
  int _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  // 友達紹介データを読み込む
  Future<void> _loadReferralData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'ログインが必要です';
          _isLoading = false;
        });
        return;
      }

      // ユーザーデータを取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _referralCode = userData['referralCode'] ?? _generateReferralCode(user.uid);
          _referralCount = userData['referralCount'] ?? 0;
          _totalEarnings = (userData['referralEarnings'] ?? 0) * 100; // ポイントに変換
          _isLoading = false;
        });
      } else {
        // ユーザーデータが存在しない場合は新しい紹介コードを生成
        setState(() {
          _referralCode = _generateReferralCode(user.uid);
          _referralCount = 0;
          _totalEarnings = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('友達紹介データの読み込みに失敗しました: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 紹介コードを生成
  String _generateReferralCode(String userId) {
    // ユーザーIDの最初の8文字を大文字に変換して紹介コードとして使用
    return userId.substring(0, 8).toUpperCase();
  }

  // 紹介コードをクリップボードにコピー
  Future<void> _copyReferralCode() async {
    if (_referralCode != null) {
      await Clipboard.setData(ClipboardData(text: _referralCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('紹介コードをコピーしました'),
            backgroundColor: Color(0xFFFF6B35),
          ),
        );
      }
    }
  }

  // 友達を招待
  Future<void> _inviteFriend() async {
    if (_referralCode != null) {
      // 実際の実装では、SNSやメールでの招待機能を実装
      await Clipboard.setData(ClipboardData(text: 'GrouMapアプリで友達紹介コード「$_referralCode」を使って登録してください！'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待メッセージをコピーしました'),
            backgroundColor: Color(0xFFFF6B35),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('友達紹介'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
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
            ElevatedButton(
              onPressed: _loadReferralData,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // 紹介コードカード
          _buildReferralCodeCard(),
          
          const SizedBox(height: 24),
          
          // 統計情報
          _buildStatsCard(),
          
          const SizedBox(height: 24),
          
          // 招待方法ガイド
          _buildInviteGuide(),
          
          const SizedBox(height: 24),
          
          // 特典情報
          _buildRewardsInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(
            Icons.people,
            color: Colors.white,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            '友達を招待してポイント獲得',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '友達が紹介コードで登録すると、\nあなたも友達もポイントがもらえます',
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

  Widget _buildReferralCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'あなたの紹介コード',
            style: TextStyle(
              fontSize: 16,
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
                Text(
                  _referralCode ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'このコードを友達に教えてください',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // アクションボタン
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyReferralCode,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('コピー'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _inviteFriend,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('招待'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF6B35),
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'あなたの実績',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  label: '招待した友達',
                  value: '$_referralCount人',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.monetization_on,
                  label: '獲得ポイント',
                  value: '${_totalEarnings}pt',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '友達の招待方法',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildGuideStep(
            step: 1,
            title: '紹介コードをコピー',
            description: '上記の紹介コードをコピーして友達に送信します',
            icon: Icons.copy,
          ),
          
          _buildGuideStep(
            step: 2,
            title: '友達にアプリをダウンロードしてもらう',
            description: '友達にGrouMapアプリをダウンロードしてもらいます',
            icon: Icons.download,
          ),
          
          _buildGuideStep(
            step: 3,
            title: '紹介コードで登録',
            description: '友達がアプリで紹介コードを使って登録します',
            icon: Icons.person_add,
          ),
          
          _buildGuideStep(
            step: 4,
            title: 'ポイントを獲得',
            description: '登録完了後、あなたも友達もポイントがもらえます！',
            icon: Icons.card_giftcard,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required int step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
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
                step.toString(),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6B35),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // テキスト
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '特典内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildRewardItem(
            title: 'あなたの特典',
            description: '友達1人につき100ポイント獲得',
            icon: Icons.stars,
            color: Colors.amber,
          ),
          
          const SizedBox(height: 12),
          
          _buildRewardItem(
            title: '友達の特典',
            description: '登録時に100ポイントをプレゼント',
            icon: Icons.card_giftcard,
            color: Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF6B35).withOpacity(0.3),
              ),
            ),
            child: const Text(
              '※ 特典は友達がアプリで初回利用後に付与されます',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
