import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart' as model;
import '../../widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _buildAnnouncementsList(context, ref),
    );
  }

  Widget _buildAnnouncementsList(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return announcementsAsync.when(
      data: (announcements) {
        debugPrint('Announcements loaded: ${announcements.length} items');
        if (announcements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.announcement, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('お知らせがありません'),
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
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return _buildAnnouncementItem(context, ref, announcement);
          },
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('お知らせを読み込み中...'),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'お知らせを読み込めませんでした',
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, WidgetRef ref, String userId) {
    final notificationsAsync = ref.watch(userNotificationsProvider(userId));

    return notificationsAsync.when(
      data: (notifications) {
        debugPrint('Notifications loaded: ${notifications.length} items');
        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('通知がありません'),
                SizedBox(height: 8),
                Text(
                  '新しい通知があるとここに表示されます',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationItem(context, ref, notification);
          },
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('通知を読み込み中...'),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '通知を読み込めませんでした',
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
                ref.invalidate(userNotificationsProvider(userId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(BuildContext context, WidgetRef ref, Map<String, dynamic> announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAnnouncementDetails(context, ref, announcement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(announcement['category']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      announcement['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(announcement['priority']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      announcement['priority'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(announcement['publishedAt']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                announcement['content'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.visibility,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${announcement['totalViews']} 回閲覧',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${announcement['readCount']} 人が既読',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, model.NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Text(
            notification.type.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatDate(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  notification.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getNotificationColor(notification.type),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: notification.isRead
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteNotification(context, ref, notification.id),
              )
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => _markAsRead(context, ref, notification.id),
              ),
        onTap: () => _showNotificationDetails(context, notification),
      ),
    );
  }

  void _showAnnouncementDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> announcement) {
    // 閲覧数を更新
    ref.read(announcementProvider).updateViewCount(announcement['id']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(announcement['category']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                announcement['category'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(announcement['title'])),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement['content'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('カテゴリ:', announcement['category']),
              _buildDetailRow('優先度:', announcement['priority']),
              _buildDetailRow('公開日時:', _formatDateTime(announcement['publishedAt'])),
              _buildDetailRow('閲覧数:', '${announcement['totalViews']} 回'),
              _buildDetailRow('既読数:', '${announcement['readCount']} 人'),
              if (announcement['tags'] != null && (announcement['tags'] as List).isNotEmpty)
                _buildDetailRow('タグ:', (announcement['tags'] as List).join(', ')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 既読数を更新
              ref.read(announcementProvider).updateReadCount(announcement['id']);
              Navigator.of(context).pop();
            },
            child: const Text('既読にする'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(BuildContext context, model.NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(notification.type.icon),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            if (notification.imageUrl != null) ...[
              const SizedBox(height: 16),
              Image.network(notification.imageUrl!),
            ],
            const SizedBox(height: 16),
            _buildDetailRow('タイプ:', notification.type.displayName),
            _buildDetailRow('作成日時:', _formatDateTime(notification.createdAt)),
            _buildDetailRow('既読:', notification.isRead ? 'はい' : 'いいえ'),
            if (notification.tags.isNotEmpty)
              _buildDetailRow('タグ:', notification.tags.join(', ')),
          ],
        ),
        actions: [
          if (notification.actionUrl != null)
            TextButton(
              onPressed: () {
                // TODO: アクションURLを開く
                Navigator.of(context).pop();
              },
              child: const Text('アクション'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _markAsRead(BuildContext context, WidgetRef ref, String notificationId) {
    ref.read(notificationProvider).markAsRead(notificationId);
  }

  void _markAllAsRead(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    authState.whenData((user) {
      if (user != null) {
        ref.read(notificationProvider).markAllAsRead(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('すべての通知を既読にしました')),
        );
      }
    });
  }

  void _deleteNotification(BuildContext context, WidgetRef ref, String notificationId) {
    ref.read(notificationProvider).deleteNotification(notificationId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('通知を削除しました')),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '一般':
        return Colors.blue;
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case '低':
        return Colors.grey;
      case '通常':
        return Colors.blue;
      case '高':
        return Colors.orange;
      case '緊急':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getNotificationColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.ranking:
        return Colors.purple;
      case model.NotificationType.badge:
        return Colors.amber;
      case model.NotificationType.levelUp:
        return Colors.green;
      case model.NotificationType.pointEarned:
        return Colors.blue;
      case model.NotificationType.social:
        return Colors.pink;
      case model.NotificationType.marketing:
        return Colors.orange;
      case model.NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '日時不明';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '日時不明';
    }
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

  String _formatDateTime(dynamic timestamp) {
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
}
