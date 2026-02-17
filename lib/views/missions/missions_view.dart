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
      ]);

      if (!mounted) return;
      setState(() {
        _dailyMissionData = results[0] as Map<String, dynamic>;
        _loginStreak = results[1] as int;
        _missionProgress = results[2] as Map<String, dynamic>;
        _userCoins = results[3] as int;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ミッションデータ読み込みエラー: $e');
      if (mounted) setState(() => _isLoading = false);
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
      // コインとミッション状態を再読み込み
      await _loadAllMissionData();
      if (mounted) {
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
                    labels: const ['デイリー', 'ログイン', '新規登録'],
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
                    child: ListView.builder(
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
}
