import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreDetailView extends StatefulWidget {
  final Map<String, dynamic> store;
  
  const StoreDetailView({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends State<StoreDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userStamps;
  bool _isLoadingStamps = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserStamps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ユーザーのスタンプ状況を読み込む
  Future<void> _loadUserStamps() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 新しい構造: users/{userId}/stores/{storeId}
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.store['id'])
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _userStamps = {
            'stamps': data['stamps'] ?? 0,
            'lastVisited': data['lastVisited'],
            'totalSpending': data['totalSpending'] ?? 0.0,
          };
        });
      } else {
        setState(() {
          _userStamps = {
            'stamps': 0,
            'lastVisited': null,
            'totalSpending': 0.0,
          };
        });
      }
    } catch (e) {
      print('ユーザースタンプデータの読み込みに失敗しました: $e');
      setState(() {
        _userStamps = {
          'stamps': 0,
          'lastVisited': null,
          'totalSpending': 0.0,
        };
      });
    } finally {
      setState(() {
        _isLoadingStamps = false;
      });
    }
  }

  // スタンプ数を更新する
  Future<void> _updateStamps(int newStampCount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // スタンプ数を0-10の範囲に制限
      final clampedStamps = newStampCount.clamp(0, 10);
      
      // 新しい構造: users/{userId}/stores/{storeId} に保存
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stores')
          .doc(widget.store['id'])
          .set({
        'stamps': clampedStamps,
        'lastVisited': DateTime.now(),
        'totalSpending': _userStamps?['totalSpending'] ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
        'storeId': widget.store['id'],
        'storeName': widget.store['name'],
      }, SetOptions(merge: true));

      // ローカル状態を更新
      setState(() {
        _userStamps = {
          'stamps': clampedStamps,
          'lastVisited': DateTime.now(),
          'totalSpending': _userStamps?['totalSpending'] ?? 0.0,
        };
      });

      // スタンプカード完成時の通知
      if (clampedStamps >= 10) {
        _showStampCompletionDialog();
      }

    } catch (e) {
      print('スタンプ数の更新に失敗しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('スタンプの更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // スタンプカード完成ダイアログを表示
  void _showStampCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('スタンプカード完成！'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'おめでとうございます！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'スタンプカードが完成しました。\n特典を受け取ることができます！',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 店舗背景画像
          _buildStoreHeader(),
          
          // 店舗基本情報
          _buildStoreInfo(),
          
          // スタンプカード
          _buildStampCard(),
          
          // タブバー
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF6B35),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF6B35),
                tabs: const [
                  Tab(text: '投稿'),
                  Tab(text: 'メニュー'),
                  Tab(text: '店舗詳細'),
                ],
              ),
            ),
          ),
          
          // タブコンテンツ
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildMenuTab(),
                _buildStoreDetailsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFFFF6B35),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildStoreBackground(),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // 店舗背景画像を構築
  Widget _buildStoreBackground() {
    // 両方のフィールド名をサポート
    final backgroundImageUrl = _getStringValue(widget.store['backgroundImageUrl'], '');
    final storeImageUrl = _getStringValue(widget.store['storeImageUrl'], '');
    final imageUrl = backgroundImageUrl.isNotEmpty ? backgroundImageUrl : storeImageUrl;
    
    print('店舗背景画像URL (backgroundImageUrl): $backgroundImageUrl');
    print('店舗背景画像URL (storeImageUrl): $storeImageUrl');
    print('使用する画像URL: $imageUrl');
    print('URLが空でないか: ${imageUrl.isNotEmpty}');
    
    if (imageUrl.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          // 画像読み込みの設定
          isAntiAlias: true,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, child, loadingProgress) {
            print('背景画像読み込み中...');
            if (loadingProgress == null) {
              print('背景画像読み込み完了');
              return child;
            }
            return Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFFF6B35),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('店舗背景画像の読み込みエラー: $error');
            print('スタックトレース: $stackTrace');
            return Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFFF6B35),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '画像読み込みエラー',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      print('背景画像URLが空です');
      // 背景画像がない場合の表示
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF6B35),
              const Color(0xFFFF6B35).withOpacity(0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                '背景画像なし',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStoreInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 店舗アイコン
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _buildStoreIcon(),
            ),
            
            const SizedBox(width: 16),
            
            // 店舗名とカテゴリ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStringValue(widget.store['name'], '店舗名なし'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStringValue(widget.store['category'], 'その他'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCategoryColor(_getStringValue(widget.store['category'], 'その他')),
                        fontWeight: FontWeight.w500,
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

  Widget _buildStampCard() {
    if (_isLoadingStamps) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
          ),
        ),
      );
    }

    final stamps = _userStamps?['stamps'] ?? 0;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'スタンプカード',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // 開発用テスター表示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'テストモード',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // スタンプ表示（5x2のグリッド）
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                final hasStamp = index < stamps;
                
                return Container(
                  decoration: BoxDecoration(
                    color: hasStamp ? Colors.blue : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasStamp ? Colors.blue[700]! : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: hasStamp
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.grey,
                            size: 20,
                          ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // スタンプ状況テキスト
            Center(
              child: Text(
                'スタンプ: $stamps/10',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // スタンプカード完成通知
            if (stamps >= 10)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'おめでとうございます！スタンプカードが完成しました！',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // スタンプ増減テスター
            _buildStampTester(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          '投稿機能は今後実装予定です',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'メニュー機能は今後実装予定です',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStoreDetailsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 説明
          if (_getStringValue(widget.store['description'], '').isNotEmpty) ...[
            const Text(
              '店舗説明',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStringValue(widget.store['description'], ''),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
          
          // 住所
          if (_getStringValue(widget.store['address'], '').isNotEmpty) ...[
            const Text(
              '住所',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStringValue(widget.store['address'], ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 電話番号
          if (_getStringValue(widget.store['phone'], '').isNotEmpty) ...[
            const Text(
              '電話番号',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getStringValue(widget.store['phone'], ''),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // 営業時間
          if (widget.store['businessHours'] != null) ...[
            const Text(
              '営業時間',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildBusinessHoursDisplay(),
            const SizedBox(height: 16),
          ],
          
          // タグ
          if (widget.store['tags'] != null && (widget.store['tags'] as List).isNotEmpty) ...[
            const Text(
              'タグ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (widget.store['tags'] as List).map<Widget>((tag) => Chip(
                label: Text(tag.toString()),
                backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
                labelStyle: const TextStyle(fontSize: 12),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // SNS・ウェブサイト
          if (_hasSocialMedia()) ...[
            const Text(
              'SNS・ウェブサイト',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildSocialMediaDisplay(),
            const SizedBox(height: 16),
          ],
          
          // 位置情報
          if (widget.store['location'] != null) ...[
            const Text(
              '位置情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildLocationDisplay(),
            const SizedBox(height: 16),
          ],
          
          // ステータス
          const Text(
            'ステータス',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBoolValue(widget.store['isActive'], false)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBoolValue(widget.store['isActive'], false)
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getBoolValue(widget.store['isActive'], false) ? '営業中' : '休業中',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getBoolValue(widget.store['isActive'], false)
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBoolValue(widget.store['isApproved'], false)
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBoolValue(widget.store['isApproved'], false)
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getBoolValue(widget.store['isApproved'], false) ? '承認済み' : '承認待ち',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getBoolValue(widget.store['isApproved'], false)
                        ? Colors.blue[700]
                        : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 安全にStringを取得するヘルパーメソッド
  String _getStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) return value.toString();
    return value.toString();
  }

  // 安全にboolを取得するヘルパーメソッド
  bool _getBoolValue(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
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

  // 店舗アイコンを構築
  Widget _buildStoreIcon() {
    final iconImageUrl = _getStringValue(widget.store['iconImageUrl'], '');
    final category = _getStringValue(widget.store['category'], 'その他');
    
    if (iconImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          iconImageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          // CORSエラーを回避する設定
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET',
            'Access-Control-Allow-Headers': 'Content-Type',
          },
          // 画像読み込みの設定
          isAntiAlias: true,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: _getCategoryColor(category),
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('店舗アイコン画像の読み込みエラー: $error');
            return Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 40,
            );
          },
        ),
      );
    } else {
      return Icon(
        _getCategoryIcon(category),
        color: _getCategoryColor(category),
        size: 40,
      );
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

  // 営業時間表示を構築
  Widget _buildBusinessHoursDisplay() {
    final businessHours = widget.store['businessHours'] as Map<String, dynamic>?;
    if (businessHours == null) return const SizedBox.shrink();

    final dayNames = {
      'monday': '月',
      'tuesday': '火',
      'wednesday': '水',
      'thursday': '木',
      'friday': '金',
      'saturday': '土',
      'sunday': '日',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: dayNames.entries.map((entry) {
          final dayKey = entry.key;
          final dayName = entry.value;
          final dayData = businessHours[dayKey] as Map<String, dynamic>?;
          
          if (dayData == null) return const SizedBox.shrink();
          
          final isOpen = _getBoolValue(dayData['isOpen'], false);
          final openTime = _getStringValue(dayData['open'], '');
          final closeTime = _getStringValue(dayData['close'], '');
          
          // 今日の曜日をハイライト
          final now = DateTime.now();
          final todayIndex = now.weekday - 1; // Monday = 0, Sunday = 6
          final dayIndex = dayNames.keys.toList().indexOf(dayKey);
          final isToday = dayIndex == todayIndex;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFF6B35).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // 曜日表示
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday 
                        ? const Color(0xFFFF6B35)
                        : isOpen 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday 
                          ? const Color(0xFFFF6B35)
                          : isOpen 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isToday 
                            ? Colors.white
                            : isOpen 
                                ? Colors.green[700]
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 営業時間表示
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isOpen ? Icons.access_time : Icons.close,
                        color: isOpen ? Colors.green[600] : Colors.red[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOpen ? '$openTime - $closeTime' : '定休日',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isOpen ? Colors.black87 : Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 今日のマーク
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '今日',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // SNS・ウェブサイト表示を構築
  Widget _buildSocialMediaDisplay() {
    final socialMedia = widget.store['socialMedia'] as Map<String, dynamic>?;
    if (socialMedia == null) return const SizedBox.shrink();

    final List<Widget> socialItems = [];

    if (_getStringValue(socialMedia['website'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('ウェブサイト', socialMedia['website'], Icons.language));
    }
    if (_getStringValue(socialMedia['instagram'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('Instagram', socialMedia['instagram'], Icons.camera_alt));
    }
    if (_getStringValue(socialMedia['x'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('X (Twitter)', socialMedia['x'], Icons.flutter_dash));
    }
    if (_getStringValue(socialMedia['facebook'], '').isNotEmpty) {
      socialItems.add(_buildSocialItem('Facebook', socialMedia['facebook'], Icons.facebook));
    }

    return Column(
      children: socialItems,
    );
  }

  Widget _buildSocialItem(String label, String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // URLを開く処理（実装が必要）
              },
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 位置情報表示を構築
  Widget _buildLocationDisplay() {
    final location = widget.store['location'] as Map<String, dynamic>?;
    if (location == null) return const SizedBox.shrink();

    final latitude = location['latitude'] as double? ?? 0.0;
    final longitude = location['longitude'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Text('位置情報', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '緯度: ${latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12, color: Colors.blue, fontFamily: 'monospace'),
          ),
          Text(
            '経度: ${longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12, color: Colors.blue, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  // SNS・ウェブサイトがあるかチェック
  bool _hasSocialMedia() {
    final socialMedia = widget.store['socialMedia'] as Map<String, dynamic>?;
    if (socialMedia == null) return false;

    return _getStringValue(socialMedia['website'], '').isNotEmpty ||
           _getStringValue(socialMedia['instagram'], '').isNotEmpty ||
           _getStringValue(socialMedia['x'], '').isNotEmpty ||
           _getStringValue(socialMedia['facebook'], '').isNotEmpty;
  }

  // スタンプ増減テスターを構築
  Widget _buildStampTester() {
    final currentStamps = _userStamps?['stamps'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'スタンプテスター',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '開発用：スタンプ数をテストできます',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          
          // スタンプ増減ボタン
          Row(
            children: [
              // スタンプ減算ボタン
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentStamps > 0 ? () => _updateStamps(currentStamps - 1) : null,
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('スタンプ-1'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[700],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // スタンプ加算ボタン
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentStamps < 10 ? () => _updateStamps(currentStamps + 1) : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('スタンプ+1'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.green[700],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // クイック設定ボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStamps(0),
                  child: const Text('リセット'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStamps(5),
                  child: const Text('5個'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStamps(10),
                  child: const Text('完成'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[600],
                    side: BorderSide(color: Colors.orange[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
