import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import '../../widgets/common_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../services/coin_service.dart';
import '../../services/mission_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/walkthrough_provider.dart';
import '../../widgets/error_dialog.dart';
import '../walkthrough/walkthrough_overlay.dart';
import '../walkthrough/walkthrough_step_config.dart';

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

class MissionsView extends ConsumerStatefulWidget {
  final bool showCoinExchange;
  const MissionsView({super.key, this.showCoinExchange = false});

  @override
  ConsumerState<MissionsView> createState() => _MissionsViewState();
}

class _MissionsViewState extends ConsumerState<MissionsView> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  int _userCoins = 0;
  bool _isClaiming = false;
  DateTime? _coinExpiresAt;
  bool _isCoinExpired = false;

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
  // コイン交換済み店舗IDのローカルキャッシュ（_loadAllMissionData 後の復活防止用）
  final Set<String> _exchangedStoreIds = {};

  // 週次ミッション進捗
  int _newStoresThisWeek = 0;
  int _totalVisitsThisWeek = 0;
  bool _weeklyMissionAchievedThisWeek = false;
  int _weeklyMissionTotalCount = 0;
  bool _isCheckingWeeklyMission = false;

  // ウォークスルー用GlobalKey
  final GlobalKey _firstMapClaimKey = GlobalKey();

  /// 新規登録ミッションがすべて達成済み（claimed）かどうか
  bool get _isRegistrationComplete {
    const ids = [
      'profile_completed',
      'first_map',
      'first_favorite',
      'first_store_detail',
      'first_stamp',
    ];
    return ids.every((id) => _missionProgress['${id}_claimed'] == true);
  }

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
        _missionService.getCoinStatus(user.uid),
        _loadUnvisitedStores(user.uid),
        _loadWeeklyMissionData(user.uid),
      ]);

      if (!mounted) return;
      final coinStatus = results[3] as CoinStatus;
      final weeklyData = results[5] as Map<String, dynamic>;
      setState(() {
        _dailyMissionData = results[0] as Map<String, dynamic>;
        _loginStreak = results[1] as int;
        _missionProgress = results[2] as Map<String, dynamic>;
        _userCoins = coinStatus.availableCoins;
        _coinExpiresAt = coinStatus.expiresAt;
        _isCoinExpired = coinStatus.isExpired;
        // コイン交換済み店舗はローカルキャッシュで除外（_loadAllMissionData 後の復活防止）
        _unvisitedStores = (results[4] as List<Map<String, dynamic>>)
            .where((s) => !_exchangedStoreIds.contains(s['storeId']))
            .toList();
        _newStoresThisWeek = weeklyData['newStoresThisWeek'] as int? ?? 0;
        _totalVisitsThisWeek = weeklyData['totalVisitsThisWeek'] as int? ?? 0;
        _weeklyMissionAchievedThisWeek =
            weeklyData['achievedThisWeek'] as bool? ?? false;
        _weeklyMissionTotalCount =
            weeklyData['totalAchievedCount'] as int? ?? 0;
        _isLoading = false;
        // 新規登録ミッション未達成なら「新規登録」タブを初期選択
        if (!_isRegistrationComplete && _selectedTabIndex == 0) {
          _selectedTabIndex = 2;
        }
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

      // コイン交換済み店舗IDを取得（アプリ再起動後も正しく除外するための永続化対応）
      final exchangedSnap = await firestore
          .collection('user_coupons')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'coin_exchange')
          .get();
      final exchangedStoreIds = exchangedSnap.docs
          .map((doc) => doc.data()['storeId'] as String)
          .toSet();

      // 差分が未訪問かつコイン交換未済みの店舗
      final unvisited = <Map<String, dynamic>>[];
      for (final doc in storesSnap.docs) {
        final data = doc.data();
        // isActiveもチェック（他の画面と同様）
        if (data['isActive'] != true) continue;
        // isOwner店舗はユーザー向け一覧に表示しない（FIRESTORE.mdの表示ルール）
        if (data['isOwner'] == true) continue;
        if (!visitedIds.contains(doc.id) &&
            !exchangedStoreIds.contains(doc.id)) {
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

  /// 週次ミッション進捗を取得
  Future<Map<String, dynamic>> _loadWeeklyMissionData(String userId) async {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday; // 1=月曜, 7=日曜
      final weekStart =
          DateTime(now.year, now.month, now.day - (dayOfWeek - 1));

      // 週IDを計算
      final jan1 = DateTime(weekStart.year, 1, 1);
      final weekNum =
          ((weekStart.difference(jan1).inDays + jan1.weekday - 1) / 7).ceil() +
              1;
      final weekId = '${weekStart.year}-W${weekNum.toString().padLeft(2, '0')}';

      final firestore = FirebaseFirestore.instance;

      // weekly_mission_progress/{userId} を取得
      final progressDoc = await firestore
          .collection('weekly_mission_progress')
          .doc(userId)
          .get();
      final progressData = progressDoc.data() ?? {};
      final achievedWeeks =
          List<String>.from(progressData['achievedWeeks'] as List? ?? []);
      final totalAchievedCount =
          (progressData['totalAchievedCount'] as num?)?.toInt() ?? 0;
      final achievedThisWeek = achievedWeeks.contains(weekId);

      // 今週の来店データを集計
      final userStoresSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('stores')
          .get();

      int newStoresThisWeek = 0;
      int totalVisitsThisWeek = 0;

      for (final storeDoc in userStoresSnap.docs) {
        final sd = storeDoc.data();
        final lastVisited = (sd['lastVisited'] as Timestamp?)?.toDate();
        if (lastVisited != null &&
            lastVisited
                .isAfter(weekStart.subtract(const Duration(seconds: 1)))) {
          totalVisitsThisWeek++;
          // 初回来店チェック
          final storeUserSnap = await firestore
              .collection('store_users')
              .doc(storeDoc.id)
              .collection('users')
              .doc(userId)
              .get();
          if (storeUserSnap.exists) {
            final firstVisitAt =
                (storeUserSnap.data()!['firstVisitAt'] as Timestamp?)?.toDate();
            if (firstVisitAt != null &&
                firstVisitAt
                    .isAfter(weekStart.subtract(const Duration(seconds: 1)))) {
              newStoresThisWeek++;
            }
          }
        }
      }

      return {
        'newStoresThisWeek': newStoresThisWeek,
        'totalVisitsThisWeek': totalVisitsThisWeek,
        'achievedThisWeek': achievedThisWeek,
        'totalAchievedCount': totalAchievedCount,
      };
    } catch (e) {
      debugPrint('週次ミッションデータ取得エラー: $e');
      return {
        'newStoresThisWeek': 0,
        'totalVisitsThisWeek': 0,
        'achievedThisWeek': false,
        'totalAchievedCount': 0,
      };
    }
  }

  // ========== デイリーミッション生成 ==========

  List<_MissionItem> get _dailyMissions {
    return [
      _buildDailyMission(
          'app_open', 'アプリを開く', '今日アプリを起動する', 1, Icons.phone_android),
      _buildDailyMission('recommendation_view', 'レコメンドを見る', '今日のおすすめ店舗を確認する', 1,
          Icons.recommend),
      _buildDailyMission(
          'feed_view', '投稿を1件見る', '投稿の詳細を1件閲覧する', 1, Icons.article),
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
      _buildLoginMission(
          'login_3', '3日連続ログイン', '3日間連続でアプリにログイン', 2, 3, Icons.calendar_today),
      _buildLoginMission(
          'login_7', '7日連続ログイン', '7日間連続でアプリにログイン', 5, 7, Icons.date_range),
      _buildLoginMission('login_30', '30日連続ログイン', '30日間連続でアプリにログイン', 10, 30,
          Icons.event_available),
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
      _buildRegistrationMission(
          'profile_completed', 'プロフィール完成', 'プロフィール情報をすべて入力する', 3, Icons.person),
      _buildRegistrationMission(
          'first_map', 'マップ初利用', '初めてマップ画面を開く', 10, Icons.explore),
      _buildRegistrationMission(
          'first_favorite', 'お気に入り登録', '初めて店舗をお気に入りに追加', 2, Icons.favorite),
      _buildRegistrationMission(
          'first_store_detail', '店舗詳細閲覧', '初めて店舗詳細画面を表示', 1, Icons.storefront),
      _buildRegistrationMission(
          'first_stamp', 'スタンプ初獲得', 'お店に行ってスタンプを1つ獲得する', 3, Icons.approval),
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
        return '初回限定・合計最大10コイン';
      case 3:
        return '7日間で未訪問1件 + 合計3回来店で達成';
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
          _coinExpiresAt = CoinService.calculateExpiryDate(DateTime.now());
          _isCoinExpired = false;
        });
        _showCoinRewardPopup(mission);
      }
    } else {
      if (mounted) {
        ErrorDialog.showError(
          context,
          title: '受け取りに失敗しました',
          message: '報酬を受け取れませんでした。時間をおいて再度お試しください。',
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
                Image.asset(
                  'assets/images/icon_coin.png',
                  width: 72,
                  height: 72,
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
                      Image.asset('assets/images/icon_coin.png',
                          width: 28, height: 28),
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
                        colors: [Color(0xFFFFA000), Color(0xFFFFC107)],
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

  Widget _buildCoinBalanceCard() {
    final expiryText = _buildCoinExpiryText();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/icon_coin.png', width: 28, height: 28),
              const SizedBox(width: 8),
              Text(
                '所持コイン: $_userCoins',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (expiryText != null) ...[
            const SizedBox(height: 6),
            Text(
              expiryText,
              style: TextStyle(
                fontSize: 12,
                color:
                    _isCoinExpired ? const Color(0xFFD32F2F) : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ]
        ],
      ),
    );
  }

  String? _buildCoinExpiryText() {
    if (_coinExpiresAt == null) {
      return _userCoins > 0 ? '有効期限: 未設定' : null;
    }
    final dateText =
        '${_coinExpiresAt!.year}/${_coinExpiresAt!.month.toString().padLeft(2, '0')}/${_coinExpiresAt!.day.toString().padLeft(2, '0')}';
    if (_isCoinExpired) {
      return '有効期限: $dateText（期限切れ）';
    }
    return '有効期限: $dateText まで';
  }

  bool get _isCoinExchangeMode => widget.showCoinExchange;

  @override
  Widget build(BuildContext context) {
    final wState = ref.watch(walkthroughProvider);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFFBF6F2),
          appBar: CommonHeader(
            title: Text(_isCoinExchangeMode ? 'コイン交換' : 'ミッション'),
          ),
          body: _isLoading
              ? const Center(
                  child: CustomLoadingIndicator(),
                )
              : _isCoinExchangeMode
                  ? Column(
                      children: [
                        _buildCoinBalanceCard(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadAllMissionData,
                            child: _buildCoinExchangeTab(),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildCoinBalanceCard(),
                        const SizedBox(height: 12),
                        // タブバー
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PillTabBar(
                            labels: const ['デイリー', 'ログイン', '新規登録', '週次'],
                            selectedIndex: _selectedTabIndex,
                            onChanged: (index) {
                              setState(() {
                                _selectedTabIndex = index;
                              });
                            },
                            activeColor: const Color(0xFFFF8F00),
                            disabledIndices: _isRegistrationComplete
                                ? const {}
                                : const {0, 1, 3},
                          ),
                        ),
                        const SizedBox(height: 8),
                        // タブ説明
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _currentTabDescription,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadAllMissionData,
                            child: _selectedTabIndex == 3
                                ? _buildWeeklyMissionTab()
                                : ListView(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    children: [
                                      // 新規登録タブ＆未達成時のガイドメッセージ
                                      if (_selectedTabIndex == 2 &&
                                          !_isRegistrationComplete)
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF6B35),
                                                Color(0xFFFF8F00)
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.flag,
                                                  color: Colors.white,
                                                  size: 28),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'まずは新規登録ミッションを完了しよう!',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'すべてのミッションを達成すると、デイリーミッションやログインボーナスが解放されます',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ..._currentMissions
                                          .map(_buildMissionCard),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
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
      key: mission.id == 'first_map' ? _firstMapClaimKey : null,
      onTap: _isClaiming ? null : () => _claimReward(mission),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA000).withOpacity(0.28),
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
                  Image.asset('assets/images/icon_coin.png',
                      width: 18, height: 18),
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
            const Color(0xFFFF8F00).withOpacity(0.55),
            const Color(0xFFFFB300).withOpacity(0.55),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/icon_coin.png',
                    width: 18, height: 18),
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

  // ========== 週次ミッションタブ ==========

  Widget _buildWeeklyMissionTab() {
    final condition1Met = _newStoresThisWeek >= 1;
    final condition2Met = _totalVisitsThisWeek >= 3;
    final missionMet = condition1Met && condition2Met;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // 今週のミッションカード
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flag,
                        color: Color(0xFFFF6B35), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今週のミッション',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '毎週月曜日リセット',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (_weeklyMissionAchievedThisWeek)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '達成済み',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 条件1
              _buildWeeklyConditionRow(
                icon: Icons.explore,
                label: '未訪問の店舗に来店',
                current: _newStoresThisWeek,
                required: 1,
                met: condition1Met,
              ),
              const SizedBox(height: 10),
              // 条件2
              _buildWeeklyConditionRow(
                icon: Icons.storefront,
                label: '今週の来店合計',
                current: _totalVisitsThisWeek,
                required: 3,
                met: condition2Met,
              ),
              if (missionMet && !_weeklyMissionAchievedThisWeek) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isCheckingWeeklyMission ? null : _claimWeeklyMission,
                    icon: _isCheckingWeeklyMission
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CustomLoadingIndicator.inline(
                              size: 18,
                              padding: 3,
                              primaryColor: Colors.white,
                            ),
                          )
                        : const Icon(Icons.emoji_events, size: 18),
                    label: Text(_isCheckingWeeklyMission
                        ? '確認中...'
                        : 'ミッション達成！バッジを受け取る'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 達成報酬説明
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFC107), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Color(0xFFFF8F00), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '達成報酬',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFFF8F00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• 週次ミッション限定バッジ（累計達成回数に応じて解放）',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              const Text(
                '• 発見ヒント通知（近くのレジェンド店舗のヒント）',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 累計達成バッジ進捗
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '累計達成: $_weeklyMissionTotalCount 回',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildWeeklyBadgeProgress(1, '初めての週次ミッション', 'common'),
              _buildWeeklyBadgeProgress(5, 'ミッション常連', 'rare'),
              _buildWeeklyBadgeProgress(10, 'ミッションファイター', 'epic'),
              _buildWeeklyBadgeProgress(25, 'ミッションレジェンド', 'legendary'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyConditionRow({
    required IconData icon,
    required String label,
    required int current,
    required int required,
    required bool met,
  }) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: met ? const Color(0xFF4CAF50) : Colors.grey[400],
          size: 22,
        ),
        const SizedBox(width: 10),
        Icon(icon,
            color: met ? const Color(0xFF4CAF50) : Colors.grey[500], size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: met ? Colors.black87 : Colors.black54,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '$current / $required',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: met ? const Color(0xFF4CAF50) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBadgeProgress(int threshold, String name, String rarity) {
    final unlocked = _weeklyMissionTotalCount >= threshold;
    final Color rarityColor = switch (rarity) {
      'common' => Colors.grey,
      'rare' => const Color(0xFF2196F3),
      'epic' => const Color(0xFF9C27B0),
      'legendary' => const Color(0xFFFF8F00),
      _ => Colors.grey,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events : Icons.lock_outline,
            color: unlocked ? rarityColor : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: unlocked ? Colors.black87 : Colors.grey[500],
                fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$threshold回達成',
            style: TextStyle(
              fontSize: 12,
              color: unlocked ? rarityColor : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 週次ミッション達成をCloudFunctionに送信してバッジを付与
  Future<void> _claimWeeklyMission() async {
    if (_isCheckingWeeklyMission) return;
    setState(() => _isCheckingWeeklyMission = true);

    try {
      final functions =
          FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final result = await functions.httpsCallable('checkWeeklyMission').call();
      final data = Map<String, dynamic>.from(result.data as Map);

      if (!mounted) return;

      final newlyAchieved = data['newlyAchieved'] as bool? ?? false;
      final newBadges = List<String>.from(data['newBadges'] as List? ?? []);
      final totalCount = (data['weeklyMissionCount'] as num?)?.toInt() ??
          _weeklyMissionTotalCount;

      setState(() {
        _weeklyMissionAchievedThisWeek = true;
        _weeklyMissionTotalCount = totalCount;
        _isCheckingWeeklyMission = false;
      });

      if (newlyAchieved && mounted) {
        _showWeeklyMissionAchievedDialog(newBadges);
      }
    } catch (e) {
      debugPrint('週次ミッションチェックエラー: $e');
      if (mounted) setState(() => _isCheckingWeeklyMission = false);
      if (mounted) {
        ErrorDialog.showError(
          context,
          title: '確認に失敗しました',
          message: 'ミッション達成状況を確認できませんでした。時間をおいて再度お試しください。',
        );
      }
    }
  }

  void _showWeeklyMissionAchievedDialog(List<String> newBadges) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events,
                    size: 64, color: Color(0xFFFF8F00)),
                const SizedBox(height: 16),
                const Text(
                  '週次ミッション達成！',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '発見ヒントが通知で届きました。\nマップを開いて確認しましょう！',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '新バッジを獲得！',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF8F00)),
                        ),
                        const SizedBox(height: 4),
                        ...newBadges.map((b) => Text(
                              b,
                              style: const TextStyle(fontSize: 13),
                            )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('OK',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey[300]),
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
            child: store['iconImageUrl'] != null &&
                    (store['iconImageUrl'] as String).isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      store['iconImageUrl'] as String,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.storefront,
                          color: Color(0xFFFF6B35), size: 24),
                    ),
                  )
                : const Icon(Icons.storefront,
                    color: Color(0xFFFF6B35), size: 24),
          ),
          const SizedBox(width: 12),
          // 店舗情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['storeName'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/icon_coin.png',
                      width: 20, height: 20),
                  const SizedBox(width: 6),
                  const Text(
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
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
      // ローカル状態を即時更新（Firestore再取得のキャッシュ遅延を回避）
      if (mounted) {
        setState(() {
          _userCoins -= 10;
          _exchangedStoreIds.add(store['storeId'] as String);
          _unvisitedStores.removeWhere((s) => s['storeId'] == store['storeId']);
        });
      }
      if (mounted) {
        _showCouponObtainedPopup(store['storeName'] as String);
      }
    } else {
      if (mounted) {
        ErrorDialog.showError(
          context,
          title: '交換に失敗しました',
          message: 'クーポンを交換できませんでした。時間をおいて再度お試しください。',
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
                child: const Icon(Icons.local_offer,
                    color: Colors.white, size: 40),
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
