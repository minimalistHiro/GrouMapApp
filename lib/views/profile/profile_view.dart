import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/floating_menu_item.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/game_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_ui.dart';
import '../settings/profile_edit_view.dart';
import '../settings/interest_category_view.dart';
import '../settings/password_change_view.dart';
import '../settings/email_change_view.dart';
import '../settings/notification_settings_view.dart';
import '../legal/privacy_policy_view.dart';
import '../legal/terms_view.dart';
import '../support/help_view.dart';
import '../feedback/feedback_view.dart';
import '../settings/app_info_view.dart';
import '../auth/welcome_view.dart';
import '../badges/badges_view.dart';
import '../ranking/leaderboard_view.dart';
import '../notifications/notifications_view.dart';
import '../qr/qr_generator_view.dart';
import '../report/monthly_report_view.dart';
import '../stamps/stamp_cards_view.dart';

// ゲームランクデータ定義
class _RankData {
  final int level;
  final String name;
  final int minDisc;
  final int maxDisc;
  final Color color;
  final IconData icon;

  const _RankData({
    required this.level,
    required this.name,
    required this.minDisc,
    required this.maxDisc,
    required this.color,
    required this.icon,
  });
}

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;
  bool _hasStampCards = false;

  // プレイヤー統計
  int _playerDiscoveredCount = 0;
  int _playerBadgeCount = 0;
  int _playerRankPosition = 0;

  // ゲームカラー定数
  static const Color _gameBackground = Color(0xE6101E2E);
  static const Color _gameBorder = Color(0xFF00E5FF);

  // ランク定義
  static const List<_RankData> _ranks = [
    _RankData(
      level: 1,
      name: 'ルーキー',
      minDisc: 0,
      maxDisc: 5,
      color: Color(0xFFBDBDBD),
      icon: Icons.radio_button_unchecked,
    ),
    _RankData(
      level: 2,
      name: '探索者',
      minDisc: 5,
      maxDisc: 15,
      color: Color(0xFF29B6F6),
      icon: Icons.explore,
    ),
    _RankData(
      level: 3,
      name: '冒険家',
      minDisc: 15,
      maxDisc: 30,
      color: Color(0xFF66BB6A),
      icon: Icons.directions_walk,
    ),
    _RankData(
      level: 4,
      name: '開拓者',
      minDisc: 30,
      maxDisc: 50,
      color: Color(0xFFFB8C00),
      icon: Icons.flag,
    ),
    _RankData(
      level: 5,
      name: 'レジェンド',
      minDisc: 50,
      maxDisc: 999999,
      color: Color(0xFFFFB300),
      icon: Icons.star,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPlayerStats();
  }

  Future<void> _loadUserData() async {
    try {
      final authState = ref.read(authStateProvider);
      await authState.when(
        data: (user) async {
          if (user != null) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            final storesSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('stores')
                .get();
            final hasStamps = storesSnapshot.docs.any(
              (d) => (d.data()['stamps'] as int? ?? 0) > 0,
            );
            if (doc.exists) {
              final userData = doc.data();
              setState(() {
                _userData = userData;
                _hasStampCards = hasStamps;
                _isLoadingUserData = false;
              });
            } else {
              setState(() {
                _hasStampCards = hasStamps;
                _isLoadingUserData = false;
              });
            }
          } else {
            setState(() {
              _isLoadingUserData = false;
            });
          }
        },
        loading: () {},
        error: (_, __) {
          setState(() {
            _isLoadingUserData = false;
          });
        },
      );
    } catch (e) {
      debugPrint('ユーザーデータの読み込みエラー: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _loadPlayerStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;

      final discovered = (data['discoveredStoreCount'] as num?)?.toInt() ?? 0;
      final badgeCount = (data['badgeCount'] as num?)?.toInt() ?? 0;

      int rank = 0;
      try {
        final countSnap = await FirebaseFirestore.instance
            .collection('ranking_scores')
            .doc('all_time')
            .collection('users')
            .where('discoveredStoreCount', isGreaterThan: discovered)
            .count()
            .get();
        rank = (countSnap.count ?? 0) + 1;
      } catch (e) {
        debugPrint('ランキング順位取得失敗: $e');
      }

      if (!mounted) return;
      setState(() {
        _playerDiscoveredCount = discovered;
        _playerBadgeCount = badgeCount;
        _playerRankPosition = rank;
      });

    } catch (e) {
      debugPrint('プレイヤー統計読み込み失敗: $e');
    }
  }

  // ランク取得
  static _RankData _getCurrentRank(int discovered) {
    for (final rank in _ranks.reversed) {
      if (discovered >= rank.minDisc) return rank;
    }
    return _ranks.first;
  }

  // プロフィール完成度計算
  double _calcBasicProfileCompletion(Map<String, dynamic> data) {
    int filled = 0;
    const total = 6;
    if (data['displayName'] is String &&
        (data['displayName'] as String).trim().isNotEmpty) filled++;
    if (data['birthDate'] != null) filled++;
    if (data['gender'] is String && (data['gender'] as String).isNotEmpty) {
      filled++;
    }
    if (data['prefecture'] is String &&
        (data['prefecture'] as String).isNotEmpty) {
      filled++;
    }
    if (data['city'] is String && (data['city'] as String).isNotEmpty) {
      filled++;
    }
    if (data['occupation'] is String &&
        (data['occupation'] as String).isNotEmpty) {
      filled++;
    }
    return filled / total;
  }

  bool _isInterestCategorySet(Map<String, dynamic> data) {
    return data['interestCategories'] is List &&
        (data['interestCategories'] as List).isNotEmpty;
  }

  Widget _buildSimpleWebImage(String imageUrl, {double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: Colors.grey[300]),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person,
            color: Colors.grey,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, {double size = 80}) {
    if (kIsWeb) {
      return _buildSimpleWebImage(imageUrl, size: size);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CustomLoadingIndicator.inline(
          size: 28,
          padding: 4,
          primaryColor: AppUi.primary,
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }

  // ========== ビルドメソッド ==========

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: DismissKeyboard(
        child: SafeArea(
          bottom: false,
          child: authState.when(
            data: (user) {
              if (user == null) return _buildGuestView();
              if (_isLoadingUserData) {
                return const Center(
                  child: CustomLoadingIndicator(primaryColor: AppUi.primary),
                );
              }
              return _buildLoggedInView(user);
            },
            loading: () => const Center(
                child: CustomLoadingIndicator(primaryColor: AppUi.primary)),
            error: (error, _) => const Center(child: Text('エラーが発生しました')),
          ),
        ),
      ),
    );
  }

  // ゲスト画面
  Widget _buildGuestView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _gameBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _gameBorder.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gameBorder.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A2A3A),
                    border: Border.all(
                      color: _gameBorder.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child:
                      const Icon(Icons.person, size: 40, color: Colors.white54),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ゲストプレイヤー',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ログインして冒険を始めよう！',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'ログイン',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/signin'),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: '新規アカウント作成',
                  backgroundColor: Colors.transparent,
                  textColor: _gameBorder,
                  borderColor: _gameBorder.withOpacity(0.5),
                  onPressed: () => Navigator.of(context).pushNamed('/signup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ログイン済み画面
  Widget _buildLoggedInView(User user) {
    final canChangePassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プレイヤーカード（ダークネイビー）＋フローティングベルボタン
          Stack(
            children: [
              _buildPlayerCard(user),
              Positioned(
                top: 12,
                right: 16,
                child: _buildNotificationBell(context, user.uid),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // プロフィール完成度プロンプト
                if (_userData != null &&
                    _calcBasicProfileCompletion(_userData!) < 1.0) ...[
                  _buildProfileCompletionCard(context, _userData!),
                  const SizedBox(height: 24),
                ] else if (_userData != null &&
                    !_isInterestCategorySet(_userData!)) ...[
                  _buildInterestCategoryPromptCard(context),
                  const SizedBox(height: 24),
                ],

                // ゲームコンテンツ
                _buildSectionTitle('ゲームコンテンツ'),
                _buildSettingsMenuContainer([
                  _buildMenuItem(
                    icon: Icons.emoji_events,
                    title: 'バッジ一覧',
                    subtitle: '獲得バッジを確認',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BadgesView()),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.leaderboard,
                    title: 'ランキング',
                    subtitle: '探検家ランキング',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LeaderboardView()),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.bar_chart,
                    title: '月次レポート',
                    subtitle: '探検の記録を確認',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MonthlyReportListView()),
                    ),
                  ),
                  if (_hasStampCards)
                    _buildMenuItem(
                      icon: Icons.card_membership,
                      title: 'スタンプカード',
                      subtitle: 'お気に入り店舗のカード',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StampCardsView()),
                      ),
                    ),
                ]),
                const SizedBox(height: 24),

                // アカウント設定
                _buildSectionTitle('アカウント設定'),
                _buildSettingsMenuContainer([
                  if (_userData == null ||
                      _calcBasicProfileCompletion(_userData!) >= 1.0)
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'プロフィール編集',
                      subtitle: 'アイコンや表示名を変更',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileEditView()),
                        );
                        _loadUserData();
                        _loadPlayerStats();
                      },
                    ),
                  if (_userData != null &&
                      _calcBasicProfileCompletion(_userData!) >= 1.0)
                    _buildMenuItem(
                      icon: Icons.category,
                      title: '興味カテゴリ設定',
                      subtitle: 'あなたの興味のあるジャンルを設定',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const InterestCategoryView()),
                        );
                        _loadUserData();
                      },
                    ),
                  if (canChangePassword)
                    _buildMenuItem(
                      icon: Icons.lock,
                      title: 'パスワード変更',
                      subtitle: 'ログインパスワードを変更',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PasswordChangeView()),
                      ),
                    ),
                  if (canChangePassword)
                    _buildMenuItem(
                      icon: Icons.email,
                      title: 'メールアドレス変更',
                      subtitle: 'ログインメールアドレスを変更',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EmailChangeView()),
                      ),
                    ),
                ]),
                const SizedBox(height: 24),

                // サポート
                _buildSectionTitle('サポート'),
                _buildSettingsMenuContainer([
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: '通知設定',
                    subtitle: 'プッシュ通知の設定',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsView())),
                  ),
                  _buildMenuItem(
                    icon: Icons.help,
                    title: 'ヘルプ・サポート',
                    subtitle: 'よくある質問やサポート',
                    trailing: _buildLiveChatUnreadTrailing(),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const HelpView())),
                  ),
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'フィードバック',
                    subtitle: 'ご意見・不具合の報告',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const FeedbackView())),
                  ),
                  _buildMenuItem(
                    icon: Icons.description,
                    title: '利用規約',
                    subtitle: 'サービス利用規約を確認',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const TermsView())),
                  ),
                  _buildMenuItem(
                    icon: Icons.policy,
                    title: 'プライバシーポリシー',
                    subtitle: '個人情報の取り扱いについて',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyView())),
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'アプリについて',
                    subtitle: 'バージョン情報・開発者情報',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AppInfoView())),
                  ),
                ]),
                const SizedBox(height: 16),

                // QRコード
                Center(
                  child: CustomButton(
                    text: 'QRコードを表示する（NFC非対応端末向け）',
                    backgroundColor: Colors.transparent,
                    textColor: Colors.blue,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    height: 40,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const QRGeneratorView()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // アカウント（ログアウト）
                _buildSectionTitle('アカウント'),
                _buildSettingsMenuContainer([
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'ログアウト',
                    subtitle: 'アカウントからログアウト',
                    onTap: () => _showLogoutDialog(context, ref),
                    isDestructive: true,
                  ),
                ]),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== プレイヤーカード ==========

  Widget _buildPlayerCard(User user) {
    final displayName = (_userData?['displayName'] is String &&
            (_userData!['displayName'] as String).trim().isNotEmpty)
        ? (_userData!['displayName'] as String).trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'プレイヤー');

    final rank = _getCurrentRank(_playerDiscoveredCount);

    String? imageUrl;
    if (_userData != null &&
        _userData!['profileImageUrl'] != null &&
        _userData!['profileImageUrl'].toString().isNotEmpty) {
      imageUrl = _userData!['profileImageUrl'];
    } else if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      imageUrl = user.photoURL;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: BoxDecoration(
        color: _gameBackground,
        border: Border(
          bottom: BorderSide(color: _gameBorder.withOpacity(0.25), width: 1),
        ),
      ),
      child: Column(
        children: [
          // 大きなアバター（中央配置）
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _gameBorder.withOpacity(0.5),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9BB8D4).withOpacity(0.6),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? _buildImageWidget(imageUrl, size: 112)
                  : Container(
                      color: Colors.grey.withOpacity(0.15),
                      child: const Icon(
                        Icons.person,
                        size: 56,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ユーザー名（中央配置）
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // ランクバッジ（中央配置）
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(rank.icon, size: 13, color: rank.color),
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rank.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: rank.color.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Lv.${rank.level}  ${rank.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: rank.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 統計3つ（ポケGOエンブレムスタイル）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => showGameDialog(
                  context: context,
                  title: '発見した店舗数',
                  message:
                      'これまでに発見（訪問）した店舗の総数です。\n新しいお店を訪れると数が増えていきます！\n\n現在: $_playerDiscoveredCount 店舗',
                  icon: Icons.search_rounded,
                  headerColor: const Color(0xFF29B6F6),
                  actions: [
                    GameDialogAction(
                      label: '閉じる',
                      onPressed: () => Navigator.of(context).pop(),
                      isPrimary: true,
                    ),
                  ],
                ),
                child: _buildStatCircle(
                  icon: Icons.search_rounded,
                  iconColor: const Color(0xFF29B6F6),
                  value: '$_playerDiscoveredCount',
                  label: '発見店舗',
                ),
              ),
              GestureDetector(
                onTap: () => showGameDialog(
                  context: context,
                  title: '獲得バッジ数',
                  message:
                      'これまでに獲得したバッジの総数です。\nミッションをクリアしてバッジを集めよう！\n\n現在: $_playerBadgeCount 個',
                  icon: Icons.military_tech_rounded,
                  headerColor: const Color(0xFFB97CF0),
                  actions: [
                    GameDialogAction(
                      label: '閉じる',
                      onPressed: () => Navigator.of(context).pop(),
                      isPrimary: true,
                    ),
                  ],
                ),
                child: _buildStatCircle(
                  icon: Icons.military_tech_rounded,
                  iconColor: const Color(0xFFB97CF0),
                  value: '$_playerBadgeCount',
                  label: 'バッジ',
                ),
              ),
              GestureDetector(
                onTap: () => showGameDialog(
                  context: context,
                  title: 'ランキング順位',
                  message:
                      '発見した店舗数に基づくランキングの順位です。\nより多くの店舗を発見して上位を目指そう！\n\n現在: ${_playerRankPosition > 0 ? '$_playerRankPosition 位' : '集計中'}',
                  icon: Icons.leaderboard_rounded,
                  headerColor: const Color(0xFFFFB300),
                  actions: [
                    GameDialogAction(
                      label: '閉じる',
                      onPressed: () => Navigator.of(context).pop(),
                      isPrimary: true,
                    ),
                  ],
                ),
                child: _buildStatCircle(
                  icon: Icons.leaderboard_rounded,
                  iconColor: const Color(0xFFFFB300),
                  value:
                      _playerRankPosition > 0 ? '$_playerRankPosition 位' : '-',
                  label: 'ランキング',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircle({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0D1B2A),
            border: Border.all(
              color: iconColor.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
      ],
    );
  }

  // ========== プロフィール完成度カード ==========

  Widget _buildProfileCompletionCard(
      BuildContext context, Map<String, dynamic> data) {
    final completion = _calcBasicProfileCompletion(data);
    final percent = (completion * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'プロフィールを完成させよう！',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '完成させると「自己紹介マスター」バッジが獲得できる＆あなたに合ったお店が見つかりやすくなります',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'プロフィールを編集する',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProfileEditView(showNextButton: true)),
              );
              _loadUserData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestCategoryPromptCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '興味カテゴリを設定しよう！',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'あなたに合ったお店が見つかりやすくなります',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: '興味カテゴリを設定する',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InterestCategoryView()),
              );
              _loadUserData();
            },
          ),
        ],
      ),
    );
  }

  // ========== 設定メニューヘルパー ==========

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsMenuContainer(List<Widget> children) {
    final spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) spaced.add(const SizedBox(height: 10));
    }
    return Column(children: spaced);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return FloatingMenuItem(
      icon: icon,
      title: title,
      onTap: onTap,
      trailing: trailing,
      isDestructive: isDestructive,
    );
  }

  // ========== 通知ベル ==========

  Widget _buildNotificationBell(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsView()),
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Colors.black87, size: 22),
                if (unread > 0)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
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

  Widget _buildLiveChatUnreadTrailing() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final userId = authSnapshot.data?.uid;
        if (userId == null)
          return const Icon(Icons.chevron_right, color: Colors.grey);
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('messages')
              .where('userId', isEqualTo: userId)
              .where('senderRole', isEqualTo: 'owner')
              .where('readByUserAt', isNull: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Icon(Icons.chevron_right, color: Colors.grey);
            }
            final totalUnread = snapshot.data?.docs.length ?? 0;
            if (totalUnread <= 0) {
              return const Icon(Icons.chevron_right, color: Colors.grey);
            }
            final badgeText = totalUnread > 99 ? '99+' : totalUnread.toString();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            );
          },
        );
      },
    );
  }

  // ========== ログアウト ==========

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showGameDialog(
      context: context,
      title: 'ログアウト',
      message: 'ログアウトしますか？',
      icon: Icons.logout,
      headerColor: Colors.red,
      actions: [
        GameDialogAction(
          label: 'キャンセル',
          onPressed: () => Navigator.of(context).pop(),
          isPrimary: false,
        ),
        GameDialogAction(
          label: 'ログアウト',
          onPressed: () async {
            Navigator.of(context).pop();
            await _performLogout(context);
          },
          isPrimary: true,
          color: Colors.red,
        ),
      ],
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showGameDialog(
          context: context,
          title: 'ログアウト失敗',
          message: 'ログアウトに失敗しました。もう一度お試しください。',
          icon: Icons.error_outline,
          headerColor: Colors.red,
          actions: [
            GameDialogAction(
              label: '閉じる',
              onPressed: () => Navigator.of(context).pop(),
              isPrimary: true,
            ),
          ],
        );
      }
    }
  }
}
