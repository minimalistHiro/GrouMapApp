import 'package:flutter/material.dart';
import '../../widgets/pill_tab_bar.dart';

class _MissionItem {
  final String title;
  final String description;
  final int coinReward;
  final bool isCompleted;
  final IconData icon;

  const _MissionItem({
    required this.title,
    required this.description,
    required this.coinReward,
    required this.isCompleted,
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

  static const _dailyMissions = [
    _MissionItem(
      title: 'アプリを開く',
      description: '今日アプリを起動する',
      coinReward: 1,
      isCompleted: true,
      icon: Icons.phone_android,
    ),
    _MissionItem(
      title: 'レコメンドを見る',
      description: '今日のおすすめ店舗を確認する',
      coinReward: 1,
      isCompleted: false,
      icon: Icons.recommend,
    ),
    _MissionItem(
      title: 'マップを開く',
      description: 'マップ画面を表示する',
      coinReward: 1,
      isCompleted: false,
      icon: Icons.map,
    ),
  ];

  static const _loginBonusMissions = [
    _MissionItem(
      title: '3日連続ログイン',
      description: '3日間連続でアプリにログイン',
      coinReward: 2,
      isCompleted: true,
      icon: Icons.calendar_today,
    ),
    _MissionItem(
      title: '7日連続ログイン',
      description: '7日間連続でアプリにログイン',
      coinReward: 5,
      isCompleted: false,
      icon: Icons.date_range,
    ),
    _MissionItem(
      title: '30日連続ログイン',
      description: '30日間連続でアプリにログイン',
      coinReward: 10,
      isCompleted: false,
      icon: Icons.event_available,
    ),
  ];

  static const _registrationMissions = [
    _MissionItem(
      title: 'プロフィール完成',
      description: 'プロフィール情報をすべて入力する',
      coinReward: 5,
      isCompleted: true,
      icon: Icons.person,
    ),
    _MissionItem(
      title: 'マップ初利用',
      description: '初めてマップ画面を開く',
      coinReward: 3,
      isCompleted: true,
      icon: Icons.explore,
    ),
    _MissionItem(
      title: 'お気に入り登録',
      description: '初めて店舗をお気に入りに追加',
      coinReward: 3,
      isCompleted: false,
      icon: Icons.favorite,
    ),
    _MissionItem(
      title: '店舗詳細閲覧',
      description: '初めて店舗詳細画面を表示',
      coinReward: 2,
      isCompleted: false,
      icon: Icons.storefront,
    ),
    _MissionItem(
      title: 'スロット初挑戦',
      description: '初めてスロットを回す',
      coinReward: 2,
      isCompleted: false,
      icon: Icons.casino,
    ),
  ];

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 28),
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
                      '受け取る',
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
      body: Column(
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
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _currentMissions.length,
              itemBuilder: (context, index) {
                return _buildMissionCard(_currentMissions[index]);
              },
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 28),
          SizedBox(width: 8),
          Text(
            '所持コイン: 5',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(_MissionItem mission) {
    if (mission.isCompleted) {
      return _buildCompletedCard(mission);
    }
    return _buildIncompleteCard(mission);
  }

  /// 達成済み = 活性化（グラデーション背景、タップでコイン獲得ポップアップ）
  Widget _buildCompletedCard(_MissionItem mission) {
    return GestureDetector(
      onTap: () => _showCoinRewardPopup(mission),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 18),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 18),
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
