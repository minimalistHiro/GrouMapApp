import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import '../../widgets/common_header.dart';
import '../../widgets/dismiss_keyboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart' as model;
import '../../widgets/custom_button.dart';
import '../../widgets/floating_list_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ユーザーデータプロバイダー（usersコレクションから直接取得）
final userDataProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      return Stream.value(null);
    }
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

// 統合通知アイテム
class _UnifiedNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime dateTime;
  final bool isRead;
  // 元データへの参照（詳細遷移用）
  final Map<String, dynamic>? announcementData;
  final model.NotificationModel? notificationData;

  _UnifiedNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.dateTime,
    required this.isRead,
    this.announcementData,
    this.notificationData,
  });

  bool get isAnnouncement => announcementData != null;
}

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(announcementsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: CommonHeader(
        title: const Text('お知らせ'),
      ),
      body: DismissKeyboard(
          child: authState.when(
        data: (user) {
          if (user != null) {
            return _buildUnifiedList(context, ref, user.uid);
          } else {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }
        },
        loading: () => const Center(
          child: CustomLoadingIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error'),
        ),
      )),
    );
  }

  Widget _buildUnifiedList(BuildContext context, WidgetRef ref, String userId) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider(userId));
    final userDataAsync = ref.watch(userDataProvider(userId));

    // 両方のデータがロード中の場合
    if (announcementsAsync.isLoading && notificationsAsync.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomLoadingIndicator(),
            SizedBox(height: 16),
            Text('読み込み中...'),
          ],
        ),
      );
    }

    // エラーチェック（両方エラーの場合のみエラー表示）
    if (announcementsAsync.hasError && notificationsAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '読み込めませんでした',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(announcementsProvider);
                ref.invalidate(userNotificationsProvider(userId));
              },
            ),
          ],
        ),
      );
    }

    final announcements = announcementsAsync.valueOrNull ?? [];
    final notifications = notificationsAsync.valueOrNull ?? [];
    final readNotifications = List<String>.from(
      userDataAsync.valueOrNull?['readNotifications'] ?? [],
    );

    // 統合リストを構築
    final unifiedItems = <_UnifiedNotificationItem>[];

    // お知らせを変換
    for (final announcement in announcements) {
      final publishedAt = announcement['publishedAt'];
      DateTime dateTime;
      if (publishedAt is Timestamp) {
        dateTime = publishedAt.toDate();
      } else {
        dateTime = DateTime.now();
      }

      unifiedItems.add(_UnifiedNotificationItem(
        id: announcement['id'] ?? '',
        title: announcement['title'] ?? 'タイトルなし',
        body: announcement['content'] ?? '',
        dateTime: dateTime,
        isRead: readNotifications.contains(announcement['id']),
        announcementData: announcement,
      ));
    }

    // 通知を変換
    for (final notification in notifications) {
      unifiedItems.add(_UnifiedNotificationItem(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        dateTime: notification.createdAt,
        isRead: notification.isRead,
        notificationData: notification,
      ));
    }

    // 日時で降順ソート
    unifiedItems.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (unifiedItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('お知らせはありません'),
            SizedBox(height: 8),
            Text(
              '新しいお知らせがあるとここに表示されます',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: unifiedItems.length + 1,
      itemBuilder: (context, index) {
        if (index == unifiedItems.length) return const SizedBox(height: 16);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildListItem(context, unifiedItems[index]),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, _UnifiedNotificationItem item) {
    return FloatingListItem(
      title: item.title,
      subtitle: item.body,
      trailingText: _formatDate(item.dateTime),
      isUnread: !item.isRead,
      onTap: () {
        if (item.isAnnouncement) {
          _showAnnouncementDetailPopup(context, item.announcementData!);
        } else {
          _showNotificationDetailPopup(context, item.notificationData!);
        }
      },
    );
  }

  void _showAnnouncementDetailPopup(
      BuildContext context, Map<String, dynamic> announcement) {
    _markAnnouncementAsRead(announcement);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => _buildAnnouncementPopup(ctx, announcement),
      transitionBuilder: (ctx, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  void _showNotificationDetailPopup(
      BuildContext context, model.NotificationModel notification) {
    _markNotificationAsRead(notification);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => _buildNotificationPopup(ctx, notification),
      transitionBuilder: (ctx, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  Future<void> _markAnnouncementAsRead(
      Map<String, dynamic> announcement) async {
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      final announcementId = announcement['id'] as String?;
      if (announcementId == null) return;
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final readList = List<String>.from(data['readNotifications'] ?? []);
        if (!readList.contains(announcementId)) {
          readList.add(announcementId);
          await userDoc.update({'readNotifications': readList});
        }
      }
    } catch (e) {
      debugPrint('既読処理エラー: $e');
    }
  }

  void _markNotificationAsRead(model.NotificationModel notification) {
    if (notification.isRead) return;
    final source = notification.data?['source'] as String?;
    ref
        .read(notificationProvider)
        .markAsRead(notification.userId, notification.id, source: source);
  }

  Widget _buildAnnouncementPopup(
      BuildContext context, Map<String, dynamic> announcement) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Text(
                      'お知らせ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // コンテンツ（スクロール可能）
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // バッジ行
                      Row(
                        children: [
                          if (announcement['category'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _announcementCategoryColor(
                                    announcement['category']),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                announcement['category'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (announcement['priority'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _announcementPriorityColor(
                                    announcement['priority']),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                announcement['priority'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            _formatAnnouncementDateTime(
                                announcement['publishedAt']),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // タイトル
                      Text(
                        announcement['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 14),
                      // 本文
                      Text(
                        announcement['content'] ?? '',
                        style: const TextStyle(
                            fontSize: 15, height: 1.6, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationPopup(
      BuildContext context, model.NotificationModel notification) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Text(
                      '通知',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // コンテンツ（スクロール可能）
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイプバッジ + 日時
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _notificationTypeColor(notification.type),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              notification.type.displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatNotificationDateTime(notification.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // タイトル
                      Text(
                        notification.title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      // 本文
                      Text(
                        notification.body,
                        style: const TextStyle(
                            fontSize: 15, height: 1.6, color: Colors.black87),
                      ),
                      if (notification.imageUrl != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(notification.imageUrl!),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _announcementCategoryColor(String category) {
    switch (category) {
      case 'システム':
        return Colors.grey;
      case 'メンテナンス':
        return Colors.orange;
      case 'キャンペーン':
        return Colors.pink;
      case 'アップデート':
        return Colors.green;
      case 'その他':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Color _announcementPriorityColor(String priority) {
    switch (priority) {
      case '低':
        return Colors.grey;
      case '高':
        return Colors.orange;
      case '緊急':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _notificationTypeColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.ranking:
        return Colors.amber;
      case model.NotificationType.badge:
        return Colors.orange;
      case model.NotificationType.levelUp:
        return Colors.green;
      case model.NotificationType.pointEarned:
        return Colors.teal;
      case model.NotificationType.social:
        return Colors.blue;
      case model.NotificationType.marketing:
        return Colors.purple;
      case model.NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatAnnouncementDateTime(dynamic timestamp) {
    if (timestamp == null) return '日時不明';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '日時不明';
    }
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatNotificationDateTime(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
