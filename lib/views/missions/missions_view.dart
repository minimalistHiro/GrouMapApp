import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../services/mission_service.dart';

/// ミッションの状態
enum MissionStatus {
  /// 未達成（グレイアウト）
  incomplete,

  /// 達成済み・未受取（グリーン、タップで受取可能）
  completedUnclaimed,

  /// 受取済み（グリーン + チェックマーク）
  claimed,
}

class _MissionItem {
  final String id;
  final String title;
  final String description;
  final int coinReward;
  final MissionStatus status;
  final IconData icon;

  const _MissionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.coinReward,
    required this.status,
    required this.icon,
  });
}

class MissionsView extends StatefulWidget {
  const MissionsView({super.key});

  @override
  State<MissionsView> createState() => _MissionsViewState();
}

class _MissionsViewState extends State<MissionsView> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  int _userCoins = 0;
  bool _isClaiming = false;

  final MissionService _missionService = MissionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // デイリーミッション状態
  Map<String, dynamic> _dailyMissionData = {};

  // ログインストリーク
  int _loginStreak = 0;

  // ミッション進捗（新規登録 + ログインボーナス受取状態）
  Map<String, dynamic> _missionProgress = {};

  // コイン交換用: 未訪問店舗リスト
  List<Map<String, dynamic>> _unvisitedStores = [];
  bool _isExchanging = false;

  @override
  void initState() {
    super.initState();
    _loadAllMissionData();
  }

  Future<void> _loadAllMissionData() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _missionService.getDailyMissions(user.uid),
        _missionService.getLoginStreak(user.uid),
        _missionService.getMissionProgress(user.uid),
        _missionService.getUserCoins(user.uid),
        _loadUnvisitedStores(user.uid),
      ]);

      if (!mounted) return;
      setState(() {
        _dailyMissionData = results[0] as Map<String, dynamic>;
        _loginStreak = results[1] as int;
        _missionProgress = results[2] as Map<String, dynamic>;
        _userCoins = results[3] as int;
        _unvisitedStores = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ミッションデータ読み込みエラー: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 未訪問店舗リストを取得
  Future<List<Map<String, dynamic>>> _loadUnvisitedStores(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // アクティブかつ承認済みの店舗を取得
      final storesSnap = await firestore
          .collection('stores')
          .where('isApproved', isEqualTo: true)
          .get();

      // 訪問済み店舗IDを取得
      final visitedIds = await _missionService.getVisitedStoreIds(userId);

      // 差分が未訪問店舗
      final unvisited = <Map<String, dynamic>>[];
      for (final doc in storesSnap.docs) {
        final data = doc.data();
        // isActiveもチェック（他の画面と同様）
        if (data['isActive'] != true) continue;
        if (!visitedIds.contains(doc.id)) {
          unvisited.add({
            'storeId': doc.id,
            'storeName': data['name'] ?? '不明な店舗',
            'category': data['category'] ?? '',
            'iconImageUrl': data['iconImageUrl'] ?? '',
          });
        }
      }
      return unvisited;
    } catch (e) {
      debugPrint('未訪問店舗取得エラー: $e');
      return [];
    }
  }

  // ========== デイリーミッション生成 ==========

  List<_MissionItem> get _dailyMissions {
    return [
      _buildDailyMission('app_open', 'アプリを開く', '今日アプリを起動する', 1, Icons.phone_android),
      _buildDailyMission('recommendation_view', 'レコメンドを見る', '今日のおすすめ店舗を確認する', 1, Icons.recommend),
      _buildDailyMission('map_open', 'マップを開く', 'マップ画面を表示する', 1, Icons.map),
    ];
  }

  _MissionItem _buildDailyMission(
      String id, String title, String description, int reward, IconData icon) {
    final completed = _dailyMissionData[id] == true;
    final claimed = _dailyMissionData['${id}_claimed'] == true;

    MissionStatus status;
    if (claimed) {
      status = MissionStatus.claimed;
    } else if (completed) {
      status = MissionStatus.completedUnclaimed;
    } else {
      status = MissionStatus.incomplete;
    }

    return _MissionItem(
      id: id,
      title: title,
      description: description,
      coinReward: reward,
      status: status,
      icon: icon,
    );
  }

  // ========== ログインボーナス生成 ==========

  List<_MissionItem> get _loginBonusMissions {
    return [
      _buildLoginMission('login_3', '3日連続ログイン', '3日間連続でアプリにログイン', 2, 3, Icons.calendar_today),
      _buildLoginMission('login_7', '7日連続ログイン', '7日間連続でアプリにログイン', 5, 7, Icons.date_range),
      _buildLoginMission('login_30', '30日連続ログイン', '30日間連続でアプリにログイン', 10, 30, Icons.event_available),
    ];
  }

  _MissionItem _buildLoginMission(String id, String title, String description,
      int reward, int requiredDays, IconData icon) {
    final claimed = _missionProgress['${id}_claimed'] == true;
    final completed = _loginStreak >= requiredDays;

    MissionStatus status;
    if (claimed) {
      status = MissionStatus.claimed;
    } else if (completed) {
      status = MissionStatus.completedUnclaimed;
    } else {
      status = MissionStatus.incomplete;
    }

    return _MissionItem(
      id: id,
      title: title,
      description: '$description（現在: $_loginStreak日）',
      coinReward: reward,
      status: status,
      icon: icon,
    );
  }

  // ========== 新規登録ミッション生成 ==========

  List<_MissionItem> get _registrationMissions {
    return [
      _buildRegistrationMission('profile_completed', 'プロフィール完成', 'プロフィール情報をすべて入力する', 5, Icons.person),
      _buildRegistrationMission('first_map', 'マップ初利用', '初めてマップ画面を開く', 3, Icons.explore),
      _buildRegistrationMission('first_favorite', 'お気に入り登録', '初めて店舗をお気に入りに追加', 3, Icons.favorite),
      _buildRegistrationMission('first_store_detail', '店舗詳細閲覧', '初めて店舗詳細画面を表示', 2, Icons.storefront),
      _buildRegistrationMission('first_slot', 'スロット初挑戦', '初めてスロットを回す', 2, Icons.casino),
    ];
  }

  _MissionItem _buildRegistrationMission(
      String id, String title, String description, int reward, IconData icon) {
    final completed = _missionProgress[id] == true;
    final claimed = _missionProgress['${id}_claimed'] == true;

    MissionStatus status;
    if (claimed) {
      status = MissionStatus.claimed;
    } else if (completed) {
      status = MissionStatus.completedUnclaimed;
    } else {
      status = MissionStatus.incomplete;
    }

    return _MissionItem(
      id: id,
      title: title,
      description: description,
      coinReward: reward,
      status: status,
      icon: icon,
    );
  }

  // ========== 現在のタブのミッション一覧 ==========

  List<_MissionItem> get _currentMissions {
    switch (_selectedTabIndex) {
      case 0:
        return _dailyMissions;
      case 1:
        return _loginBonusMissions;
      case 2:
        return _registrationMissions;
      case 3:
        return []; // コイン交換タブは別UIを使用
      default:
        return _dailyMissions;
    }
  }

  String get _currentTabDescription {
    switch (_selectedTabIndex) {
      case 0:
        return '毎日リセット・1日最大3コイン';
      case 1:
        return '連続ログインでボーナスコインを獲得';
      case 2:
        return '初回限定・合計最大15コイン';
      case 3:
        return '10コインで未訪問店舗の100円引きクーポンを取得';
      default:
        return '';
    }
  }

  // ========== コイン報酬受取 ==========

  Future<void> _claimReward(_MissionItem mission) async {
    if (_isClaiming) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isClaiming = true);

    bool success = false;

    switch (_selectedTabIndex) {
      case 0: // デイリー
        success = await _missionService.claimDailyMission(
          user.uid,
          mission.id,
          mission.coinReward,
        );
        break;
      case 1: // ログインボーナス
        success = await _missionService.claimLoginBonus(
          user.uid,
          mission.id,
          mission.coinReward,
        );
        break;
      case 2: // 新規登録
        success = await _missionService.claimRegistrationMission(
          user.uid,
          mission.id,
          mission.coinReward,
        );
        break;
    }

    if (success) {
      // ローカル状態を即時更新（Firestore再取得のキャッシュ遅延を回避）
      if (mounted) {
        setState(() {
          switch (_selectedTabIndex) {
            case 0: // デイリー
              _dailyMissionData['${mission.id}_claimed'] = true;
              break;
            case 1: // ログインボーナス
            case 2: // 新規登録
              _missionProgress['${mission.id}_claimed'] = true;
              break;
          }
          _userCoins += mission.coinReward;
        });
        _showCoinRewardPopup(mission);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('報酬の受け取りに失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isClaiming = false);
  }

  void _showCoinRewardPopup(_MissionItem mission) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2A8B8B), Color(0xFF4DB6AC)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'コイン獲得!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '「${mission.title}」を達成しました',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: const Color(0xFFFFC107), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          color: Color(0xFFFFC107), size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '+${mission.coinReward} コイン',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8F00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A8B8B), Color(0xFF4DB6AC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'OK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        title: const Text('ミッション'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCoinBalanceCard(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PillTabBar(
                    labels: const ['デイリー', 'ログイン', '新規登録', 'コイン交換'],
                    selectedIndex: _selectedTabIndex,
                    onChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    activeColor: const Color(0xFF2A8B8B),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _currentTabDescription,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllMissionData,
                    child: _selectedTabIndex == 3
                        ? _buildCoinExchangeTab()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: _currentMissions.length,
                            itemBuilder: (context, index) {
                              return _buildMissionCard(_currentMissions[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCoinBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monetization_on,
              color: Color(0xFFFFC107), size: 28),
          const SizedBox(width: 8),
          Text(
            '所持コイン: $_userCoins',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(_MissionItem mission) {
    switch (mission.status) {
      case MissionStatus.completedUnclaimed:
        return _buildCompletedUnclaimedCard(mission);
      case MissionStatus.claimed:
        return _buildClaimedCard(mission);
      case MissionStatus.incomplete:
        return _buildIncompleteCard(mission);
    }
  }

  /// 達成済み・未受取 = 活性化（グラデーション背景、タップで報酬受取）
  Widget _buildCompletedUnclaimedCard(_MissionItem mission) {
    return GestureDetector(
      onTap: _isClaiming ? null : () => _claimReward(mission),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A8B8B), Color(0xFF4DB6AC)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A8B8B).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(mission.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFFFC107), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '+${mission.coinReward}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  /// 受取済み = グラデーション背景 + チェックマーク
  Widget _buildClaimedCard(_MissionItem mission) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A8B8B).withOpacity(0.5),
            const Color(0xFF4DB6AC).withOpacity(0.5),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '受取済み',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  '完了',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 未達成 = グレイアウト
  Widget _buildIncompleteCard(_MissionItem mission) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(mission.icon, color: Colors.grey[500], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: Color(0xFFFFC107), size: 18),
                const SizedBox(width: 4),
                Text(
                  '+${mission.coinReward}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== コイン交換タブ ==========

  Widget _buildCoinExchangeTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // 交換レート説明
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFC107), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, color: Color(0xFFFF8F00), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '10コイン = 100円引きクーポン',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFFFF8F00),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'まだ行ったことのない店舗のクーポンと交換できます（有効期限30日）',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 未訪問店舗リスト
        if (_unvisitedStores.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'すべての店舗を訪問済みです',
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                ],
              ),
            ),
          )
        else
          ..._unvisitedStores.map((store) => _buildStoreExchangeCard(store)),
      ],
    );
  }

  Widget _buildStoreExchangeCard(Map<String, dynamic> store) {
    final canExchange = _userCoins >= 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 店舗アイコン
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: store['iconImageUrl'] != null && (store['iconImageUrl'] as String).isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      store['iconImageUrl'] as String,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.storefront, color: Color(0xFFFF6B35), size: 24),
                    ),
                  )
                : const Icon(Icons.storefront, color: Color(0xFFFF6B35), size: 24),
          ),
          const SizedBox(width: 12),
          // 店舗情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['storeName'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((store['category'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    store['category'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 交換ボタン
          GestureDetector(
            onTap: canExchange && !_isExchanging
                ? () => _showExchangeConfirmDialog(store)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: canExchange
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8F00)],
                      )
                    : null,
                color: canExchange ? null : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '交換する',
                style: TextStyle(
                  color: canExchange ? Colors.white : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExchangeConfirmDialog(Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('コイン交換'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('「${store['storeName']}」の100円引きクーポンと交換しますか？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 20),
                  SizedBox(width: 6),
                  Text(
                    '-10 コイン',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8F00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _executeExchange(store);
            },
            child: const Text('交換する'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeExchange(Map<String, dynamic> store) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isExchanging = true);

    final success = await _missionService.exchangeCoinForCoupon(
      user.uid,
      store['storeId'] as String,
      store['storeName'] as String,
    );

    if (success) {
      await _loadAllMissionData();
      if (mounted) {
        _showCouponObtainedPopup(store['storeName'] as String);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('クーポンの交換に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isExchanging = false);
  }

  void _showCouponObtainedPopup(String storeName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8F00)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'クーポン獲得!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '「$storeName」の\n100円引きクーポンを獲得しました',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                '有効期限: 30日間',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8F00)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'OK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
}
