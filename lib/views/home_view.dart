import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/owner_settings_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/store_provider.dart';
import '../providers/level_provider.dart';
import '../models/coupon_model.dart' as model;
import '../widgets/custom_button.dart';
import 'notifications/notifications_view.dart' hide userDataProvider;
import 'points/points_view.dart';
import 'ranking/leaderboard_view.dart';
import 'stores/store_list_view.dart';
import 'referral/friend_referral_view.dart';
import 'referral/store_referral_view.dart' hide userDataProvider;
import 'posts/post_detail_view.dart';
import 'coupons/coupon_detail_view.dart';
import 'coupons/coupons_view.dart';
import 'badges/badges_view.dart';

// ユーザーが所持しているバッジ数
final userBadgeCountProvider = StreamProvider.family<int, String>((ref, userId) {
  try {
    return FirebaseFirestore.instance
        .collection('user_badges')
        .doc(userId)
        .collection('badges')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      debugPrint('Error fetching user badge count: $error');
      return 0;
    });
  } catch (e) {
    debugPrint('Error creating user badge count stream: $e');
    return Stream.value(0);
  }
});


class HomeView extends ConsumerStatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late final PageController _referralPageController;
  Timer? _referralTimer;
  int _referralPageIndex = 0;
  int _referralPageCount = 0;

  Future<void> _openCouponDetail(BuildContext context, dynamic coupon) async {
    final storeId = coupon.storeId as String?;
    final couponId = coupon.id as String?;
    if (storeId != null && storeId.isNotEmpty && couponId != null && couponId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('coupons')
            .doc(storeId)
            .collection('coupons')
            .doc(couponId)
            .get();
        if (doc.exists && doc.data() != null) {
          final storeCoupon = model.Coupon.fromFirestore(doc.data()!, doc.id);
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CouponDetailView(coupon: storeCoupon),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error loading store coupon: $e');
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CouponDetailView(coupon: coupon),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _referralPageController = PageController(initialPage: 0);
    _referralTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_referralPageController.hasClients) {
        return;
      }
      if (_referralPageCount <= 1) {
        return;
      }
      final nextPage = (_referralPageIndex + 1) % _referralPageCount;
      _referralPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _referralTimer?.cancel();
    _referralPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        return _buildHomeContent(context, ref, user);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
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
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(authStateProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, WidgetRef ref, User? user) {
    final maintenanceGate = _buildMaintenanceGate(context, ref, user);
    if (maintenanceGate != null) {
      return maintenanceGate;
    }

    final isLoggedIn = user != null;
    final userId = user?.uid ?? 'guest';
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(announcementsProvider);
            ref.invalidate(allPostsProvider);
            ref.invalidate(ownerSettingsProvider);
            ref.invalidate(availableCouponsProvider(userId));
            if (isLoggedIn) {
              ref.invalidate(userDataProvider(userId));
              ref.invalidate(userBadgeCountProvider(userId));
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ヘッダー部分
                isLoggedIn
                    ? _buildHeader(context, ref, user!)
                    : _buildGuestHeader(context),

                _buildMaintenanceNoticeBar(context, ref),
                
                const SizedBox(height: 24),
                
                // カード部分
                isLoggedIn
                    ? _buildStatsCard(context, ref, userId)
                    : _buildGuestStatsCard(context),
                
                _buildReferralSection(context, ref),
                
                // その他のコンテンツ
                _buildAdditionalContent(context, ref, isLoggedIn, userId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Image.asset(
                  'assets/images/groumap_icon.png',
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.location_on, size: 30, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GrouMap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 18, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              const Text(
                'ゲスト',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestStatsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
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
          const Center(
            child: Text(
              'ポイントを確認するにはログイン',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              CustomButton(
                text: 'ログイン',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signin');
                },
                backgroundColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: '新規アカウント作成',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signup');
                },
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildHeader(BuildContext context, WidgetRef ref, User user) {
    final userId = user.uid;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 左側：アプリアイコン&サービス名（固定幅）
          SizedBox(
            width: 120, // 固定幅を設定
            child: Row(
              children: [
                Image.asset(
                  'assets/images/groumap_icon.png',
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.location_on, size: 30, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GrouMap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // 中央：ユーザーアイコンと円形経験値バー
          Expanded(
            child: Center(
              child: ref.watch(userDataProvider(userId)).when(
                data: (userData) {
                  if (userData == null) {
                    return const SizedBox.shrink();
                  }
                  
                  final levelService = LevelService();
                  final level = (userData['level'] is num) ? (userData['level'] as num).toInt() : 1;
                  final experience = (userData['experience'] is num) ? (userData['experience'] as num).toInt() : 0;
                  final profileImageUrl = userData['profileImageUrl'] as String?;
                  final authPhotoUrl = user.photoURL;
                  final resolvedImageUrl = (profileImageUrl != null && profileImageUrl.isNotEmpty)
                      ? profileImageUrl
                      : (authPhotoUrl != null && authPhotoUrl.isNotEmpty ? authPhotoUrl : null);
                  
                  // 現在のレベルの経験値計算
                  final levelBaseExp = levelService.totalExperienceToReachLevel(level);
                  final currentLevelRequiredExp = levelService.requiredExperienceForLevel(level);
                  final progressValue = currentLevelRequiredExp == 0
                      ? 1.0
                      : ((experience - levelBaseExp) / currentLevelRequiredExp).clamp(0.0, 1.0);
                  
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // 円形の経験値バー（周囲に余白を確保）
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: progressValue.clamp(0.0, 1.0),
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                          ),
                        ),
                        // ユーザーアイコン
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF6B35),
                              width: 2,
                            ),
                          ),
                          child: resolvedImageUrl != null
                              ? ClipOval(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: Image.network(
                                      resolvedImageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              : ClipOval(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                        // レベル表示（はみ出しを許容してクリップしない）
                        Positioned(
                          bottom: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Lv.$level',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                    strokeWidth: 2,
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          
          // 右側：お知らせのベルボタン（固定幅）
          SizedBox(
            width: 60, // 固定幅を設定
            child: IconButton(
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 28,
                    color: Colors.black87,
                  ),
                  // 未読通知のバッジ（readNotificationsフィールドと比較）
                  ref.watch(userDataProvider(userId)).when(
                    data: (userData) {
                      if (userData == null) return const SizedBox.shrink();
                      
                      final readNotifications = List<String>.from(userData['readNotifications'] ?? []);
                      
                      final unreadAnnouncements = ref.watch(announcementsProvider).maybeWhen(
                            data: (announcements) => announcements
                                .where((announcement) => !readNotifications.contains(announcement['id']))
                                .length,
                            orElse: () => 0,
                          );
                      final unreadNotifications = ref
                          .watch(unreadNotificationCountProvider(userId))
                          .maybeWhen(data: (count) => count, orElse: () => 0);
                      final totalUnread = unreadAnnouncements + unreadNotifications;

                      if (totalUnread > 0) {
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              totalUnread > 99 ? '99+' : totalUnread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsView(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceNoticeBar(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(ownerSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final currentSettings = _resolveCurrentSettings(settings);
        final startDate = _parseDate(currentSettings['maintenanceStartDate']);
        final startTime = _parseString(currentSettings['maintenanceStartTime']);
        final startAt = _combineDateTime(startDate, startTime);
        if (startAt == null) {
          return const SizedBox.shrink();
        }
        final now = DateTime.now();
        final oneWeekBefore = startAt.subtract(const Duration(days: 7));
        final shouldShow = !now.isBefore(oneWeekBefore) && !now.isAfter(startAt);
        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        final endDate = _parseDate(currentSettings['maintenanceEndDate']);
        final endTime = _parseString(currentSettings['maintenanceEndTime']);
        final endAt = _combineDateTime(endDate, endTime);
        final displayText = endAt == null
            ? 'メンテナンスのお知らせ: ${_formatDateTime(startAt)}'
            : _isSameDate(startAt, endAt)
                ? 'メンテナンスのお知らせ: ${_formatDate(startAt)} ${_formatTime(startAt)}〜${_formatTime(endAt)}'
                : 'メンテナンスのお知らせ: ${_formatDateTime(startAt)} 〜 ${_formatDateTime(endAt)}';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget? _buildMaintenanceGate(BuildContext context, WidgetRef ref, User? user) {
    final settings = ref.watch(ownerSettingsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (settings == null) {
      return null;
    }
    final currentSettings = _resolveCurrentSettings(settings);
    final startDate = _parseDate(currentSettings['maintenanceStartDate']);
    final startTime = _parseString(currentSettings['maintenanceStartTime']);
    final endDate = _parseDate(currentSettings['maintenanceEndDate']);
    final endTime = _parseString(currentSettings['maintenanceEndTime']);
    final startAt = _combineDateTime(startDate, startTime);
    final endAt = _combineDateTime(endDate, endTime);
    if (startAt == null || endAt == null) {
      return null;
    }
    final now = DateTime.now();
    if (now.isBefore(startAt) || now.isAfter(endAt)) {
      return null;
    }
    final userId = user?.uid;
    if (userId == null) {
      return _buildMaintenanceScreen(context, startAt, endAt);
    }
    final userData = ref.watch(userDataProvider(userId)).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (userData == null) {
      return null;
    }
    final isOwner = userData['isOwner'] == true;
    if (isOwner) {
      return null;
    }
    return _buildMaintenanceScreen(context, startAt, endAt);
  }

  Widget _buildMaintenanceScreen(
    BuildContext context,
    DateTime startAt,
    DateTime endAt,
  ) {
    final displayText = _isSameDate(startAt, endAt)
        ? '${_formatDate(startAt)} ${_formatTime(startAt)}〜${_formatTime(endAt)}'
        : '${_formatDateTime(startAt)} 〜 ${_formatDateTime(endAt)}';
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.build_circle_outlined,
                  size: 72,
                  color: Color(0xFF1E88E5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'メンテナンス中',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '現在メンテナンスを実施しています。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E88E5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _parseString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  DateTime? _combineDateTime(DateTime? date, String? time) {
    if (date == null || time == null || time.trim().isEmpty) {
      return null;
    }
    final parsed = _parseTime(time);
    if (parsed == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _parsePoints(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _isSameDate(DateTime start, DateTime end) {
    return start.year == end.year && start.month == end.month && start.day == end.day;
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, String userId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
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
          // 獲得ポイント（画像のような表記に変更）
          ref.watch(userDataProvider(userId)).when(
            data: (userData) {
              if (userData != null) {
                final points = _parsePoints(userData['points']);
                final specialPoints = _parsePoints(userData['specialPoints']);
                final totalPoints = points + specialPoints;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '獲得ポイント',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: '$totalPoints',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.0,
                                ),
                                children: const [
                                  TextSpan(
                                    text: '  pt',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '特別ポイント: $specialPoints pt',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          const SizedBox(height: 16),
          
          // ポイント、バッジ、総支払額のカード
          ref.watch(userDataProvider(userId)).when(
            data: (userData) {
              if (userData != null) {
                final dynamic paidRaw = userData['paid'];
                final num paidNum = paidRaw is num ? paidRaw : num.tryParse('$paidRaw') ?? 0;
                final String paidFormatted = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0).format(paidNum);
                
                return Row(
                  children: [
                    // 中：バッジ（少し小さく）
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/badge_icon.PNG',
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.military_tech, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ref.watch(userBadgeCountProvider(userId)).when(
                                data: (badgeCount) => Text(
                                  '$badgeCount',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                loading: () => const Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                error: (_, __) => const Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              const Text(
                                'バッジ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 仕切り
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    
                    // 右：総支払額（少し小さく）
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/bills_icon.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.receipt_long, size: 20, color: Colors.green),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                paidFormatted,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                '総支払額',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(BuildContext context, WidgetRef ref) {
    return ref.watch(ownerSettingsProvider).when(
      data: (ownerSettings) {
        final currentSettings = _resolveCurrentSettings(ownerSettings);
        final isFriendActive = _isCampaignActive(
          currentSettings,
          'friendCampaignStartDate',
          'friendCampaignEndDate',
        );
        final isStoreActive = _isCampaignActive(
          currentSettings,
          'storeCampaignStartDate',
          'storeCampaignEndDate',
        );

        if (!isFriendActive && !isStoreActive) {
          _scheduleReferralPageCountUpdate(0);
          return const SizedBox(height: 12);
        }

        final referralItems = <Widget>[
          if (isStoreActive)
            _buildReferralImageButton(
              context: context,
              label: '店舗紹介',
              imagePath: 'assets/images/store_icon.png',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StoreReferralView(),
                  ),
                );
              },
            ),
          if (isFriendActive)
            _buildReferralImageButton(
              context: context,
              label: '友達紹介',
              imagePath: 'assets/images/friend_intro_icon.png',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FriendReferralView(),
                  ),
                );
              },
            ),
        ];

        _scheduleReferralPageCountUpdate(referralItems.length);

        return Column(
          children: [
            const SizedBox(height: 12),
            _buildReferralCarousel(context, referralItems),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Map<String, dynamic> _resolveCurrentSettings(Map<String, dynamic>? ownerSettings) {
    final rawCurrent = ownerSettings?['current'];
    if (rawCurrent is Map<String, dynamic>) {
      return rawCurrent;
    }
    return ownerSettings ?? <String, dynamic>{};
  }

  bool _isCampaignActive(
    Map<String, dynamic> settings,
    String startKey,
    String endKey,
  ) {
    final start = _parseDate(settings[startKey]);
    final end = _parseDate(settings[endKey]);
    if (start == null || end == null) {
      return false;
    }
    final now = DateTime.now();
    return !now.isBefore(start) && !now.isAfter(end);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _scheduleReferralPageCountUpdate(int count) {
    if (_referralPageCount == count) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _referralPageCount = count;
        if (_referralPageCount == 0) {
          _referralPageIndex = 0;
          return;
        }
        if (_referralPageIndex >= _referralPageCount) {
          _referralPageIndex = _referralPageCount - 1;
        }
        if (_referralPageController.hasClients) {
          _referralPageController.jumpToPage(_referralPageIndex);
        }
      });
    });
  }

  Widget _buildReferralCarousel(BuildContext context, List<Widget> referralItems) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 96,
      width: double.infinity,
      child: PageView(
        controller: _referralPageController,
        onPageChanged: (index) {
          if (!mounted) {
            return;
          }
          setState(() {
            _referralPageIndex = index;
          });
        },
        children: referralItems,
      ),
    );
  }

  Widget _buildReferralImageButton({
    required BuildContext context,
    required String label,
    required String imagePath,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFFF6B35),
                );
              },
            ),
            Container(
              color: Colors.black.withOpacity(0.25),
            ),
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalContent(
    BuildContext context,
    WidgetRef ref,
    bool isLoggedIn,
    String userId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // メニューグリッド
          _buildMenuGrid(context, ref, isLoggedIn),
          
          const SizedBox(height: 20),
          
          // クーポンセクション
          _buildCouponSection(context, ref, userId),
          
          const SizedBox(height: 20),
          
          // 投稿セクション
          _buildPostSection(context, ref, userId),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, WidgetRef ref, bool isLoggedIn) {
    final menuItems = [
      {'icon': Icons.monetization_on, 'label': 'ポイント'},
      {'icon': Icons.military_tech, 'label': 'バッジ'},
      {'icon': Icons.store, 'label': '店舗一覧'},
      {'icon': Icons.emoji_events, 'label': 'ランキング'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: menuItems.map((item) {
                return Expanded(
                  child: _buildMenuButton(
                    context,
                    item['label'] as String,
                    item['icon'] as IconData,
                    true,
                    iconSize: 32.0,
                    fontSize: 12.0,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context, WidgetRef ref, String userId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                'クーポン',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // クーポン一覧画面に遷移
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CouponsView(
                        initialTopTabIndex: 1,
                        initialCouponTabIndex: 0,
                      ),
                    ),
                  );
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: ref.watch(availableCouponsProvider(userId)).when(
            data: (coupons) {
              if (coupons.isEmpty) {
                return const Center(
                  child: Text(
                    '利用可能なクーポンがありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  return _buildCouponCard(context, ref, coupon);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
            error: (error, _) => const Center(
              child: Text(
                'クーポンの取得に失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostSection(BuildContext context, WidgetRef ref, String userId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                '投稿',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // 投稿一覧画面に遷移
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CouponsView(
                        initialTopTabIndex: 0,
                        initialCouponTabIndex: 0,
                      ),
                    ),
                  );
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: ref.watch(allPostsProvider).when(
            data: (posts) {
              if (posts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        '投稿がありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostCard(context, post);
                },
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '投稿を読み込み中...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    '投稿の取得に失敗しました',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'データが存在しない可能性があります',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(BuildContext context, WidgetRef ref, dynamic coupon) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon.validUntil;
      if (endDate == null) return '期限不明';
      
      try {
        final date = endDate is DateTime ? endDate : endDate.toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(date.year, date.month, date.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${date.month}月${date.day}日';
        }
        
        return '$dateText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon.discountType ?? 'percentage';
      final discountValue = coupon.discountValue ?? 0.0;
      
      if (discountType == 'percentage') {
        return '${discountValue.toInt()}%OFF';
      } else if (discountType == 'fixed_amount') {
        return '${discountValue.toInt()}円OFF';
      } else if (discountType == 'fixed_price') {
        return '${discountValue.toInt()}円';
      }
      return '特典あり';
    }

    return GestureDetector(
      onTap: () => _openCouponDetail(context, coupon),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 270,
          width: 170,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
            // 画像
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: coupon.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        coupon.imageUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            
            // 期限
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                formatEndDate(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                coupon.title ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 割引情報
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                getDiscountText(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 4),
            const Divider(height: 1),
            
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ref.watch(storeNameProvider(coupon.storeId)).when(
                data: (storeName) => Text(
                  storeName ?? '店舗名なし',
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const Text(
                  '読み込み中...',
                  style: TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                ),
                error: (_, __) => Text(
                  coupon.storeId ?? '店舗名なし',
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
              const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    // 作成日の表示用フォーマット
    String formatDate() {
      try {
        final date = post.createdAt;
        final now = DateTime.now();
        final difference = now.difference(date).inDays;
        
        if (difference == 0) return '今日';
        if (difference == 1) return '昨日';
        if (difference < 7) return '${difference}日前';
        
        return '${date.month}月${date.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    return GestureDetector(
      onTap: () async {
        final storeId = post.storeId;
        if (storeId != null && storeId.isNotEmpty) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('posts')
                .doc(storeId)
                .collection('posts')
                .doc(post.id)
                .get();
            if (doc.exists && doc.data() != null) {
              final storePost = PostModel.fromMap(doc.data()!, doc.id);
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailView(post: storePost),
                ),
              );
              return;
            }
          } catch (e) {
            debugPrint('Error loading store post: $e');
          }
        }

        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailView(post: post),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // 画像
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: post.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        post.imageUrls[0],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            
            // カテゴリバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                post.category ?? 'お知らせ',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 5),
            
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            const Divider(),
            
            // 店舗名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post.storeName ?? '店舗名なし',
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 5),
            
            // 投稿日
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatDate(),
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    dynamic icon,
    bool isLogin, {
    bool isImage = false,
    double? iconSize,
    double? fontSize,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isLogin) {
          // ログインしていない場合はログイン画面に遷移
          Navigator.of(context).pushNamed('/signin');
          return;
        }

        if (title == 'ポイント' || title == 'ポイント履歴') {
          // ポイント履歴画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PointsView(),
            ),
          );
        } else if (title == 'バッジ') {
          // バッジ一覧画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BadgesView(),
            ),
          );
        } else if (title == '店舗一覧') {
          // 店舗一覧画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StoreListView(),
            ),
          );
        } else if (title == 'ランキング') {
          // ランキング画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LeaderboardView(),
            ),
          );
        } else if (title == '友達紹介') {
          // 友達紹介画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FriendReferralView(),
            ),
          );
        } else if (title == '店舗紹介') {
          // 店舗紹介画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const StoreReferralView(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: iconSize ?? 24,
              width: iconSize ?? 24,
              child: isImage
                  ? Image.asset(
                      icon as String,
                      width: iconSize ?? 24,
                      height: iconSize ?? 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.monetization_on,
                          size: iconSize ?? 24,
                          color: isLogin ? Colors.white : Colors.grey,
                        );
                      },
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      size: iconSize ?? 24,
                      color: isLogin ? Colors.white : Colors.grey,
                    ),
            ),
            SizedBox(height: (iconSize ?? 24) * 0.2),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize ?? 10,
                fontWeight: FontWeight.bold,
                color: isLogin ? Colors.white : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotLoggedInView(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴ
            Image.asset(
              'assets/images/groumap_icon.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.location_on, size: 200, color: Colors.blue),
            ),
            
            const SizedBox(height: 32),
            
            // アプリ名
            const Text(
              'GrouMap',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // サブタイトル
            const Text(
              '近くの店舗を見つけて、ポイントを獲得しよう！',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // 機能説明
            _buildFeatureCard(
              icon: Icons.map,
              title: '地図で店舗検索',
              description: '現在地から近くの店舗を簡単に見つけられます',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.qr_code,
              title: 'QRコードでポイント獲得',
              description: '店舗でQRコードをスキャンしてポイントを獲得',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.card_giftcard,
              title: 'ポイントでお得に',
              description: '獲得したポイントで商品を割引価格で購入',
            ),
            
            const SizedBox(height: 48),
            
            // ログインボタン
            CustomButton(
              text: 'ログイン',
              onPressed: () {
                Navigator.of(context).pushNamed('/signin');
              },
            ),
            
            const SizedBox(height: 16),
            
            // 新規登録ボタン
            CustomButton(
              text: '新規登録',
              onPressed: () {
                Navigator.of(context).pushNamed('/signup');
              },
              backgroundColor: Colors.white,
              textColor: Colors.blue,
              borderColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
}
