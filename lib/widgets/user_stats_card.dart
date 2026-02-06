import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStoreProgress {
  const UserStoreProgress({
    required this.newPioneerCount,
    required this.stamp10StoreCount,
  });

  final int newPioneerCount;
  final int stamp10StoreCount;
}

int _parseStampCount(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// ユーザーが所持しているスタンプ合計数
final userTotalStampsProvider = StreamProvider.autoDispose.family<int, String>((ref, userId) {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      return Stream.value(0);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('stores')
        .snapshots()
        .map((snapshot) {
          var total = 0;
          for (final doc in snapshot.docs) {
            total += _parseStampCount(doc.data()['stamps']);
          }
          return total;
        })
        .handleError((error) {
          debugPrint('Error fetching user total stamps: $error');
          return 0;
        });
  } catch (e) {
    debugPrint('Error creating user total stamps stream: $e');
    return Stream.value(0);
  }
});

// ユーザーの新規開拓数・スタンプ10個店舗数
final userStoreProgressProvider = StreamProvider.autoDispose.family<UserStoreProgress, String>((ref, userId) {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      return Stream.value(const UserStoreProgress(
        newPioneerCount: 0,
        stamp10StoreCount: 0,
      ));
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('stores')
        .snapshots()
        .map((snapshot) {
          var newPioneerCount = 0;
          var stamp10StoreCount = 0;
          for (final doc in snapshot.docs) {
            final stamps = _parseStampCount(doc.data()['stamps']);
            if (stamps >= 1 && stamps <= 9) {
              newPioneerCount++;
            } else if (stamps >= 10) {
              stamp10StoreCount++;
            }
          }
          return UserStoreProgress(
            newPioneerCount: newPioneerCount,
            stamp10StoreCount: stamp10StoreCount,
          );
        })
        .handleError((error) {
          debugPrint('Error fetching user store stats: $error');
          return const UserStoreProgress(
            newPioneerCount: 0,
            stamp10StoreCount: 0,
          );
        });
  } catch (e) {
    debugPrint('Error creating user store stats stream: $e');
    return Stream.value(const UserStoreProgress(
      newPioneerCount: 0,
      stamp10StoreCount: 0,
    ));
  }
});

// 全店舗数
final totalStoreCountProvider = StreamProvider<int>((ref) {
  try {
    return FirebaseFirestore.instance
        .collection('stores')
        .snapshots()
        .map((snapshot) {
          var activeCount = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (data['isActive'] == true) {
              activeCount++;
            }
          }
          return activeCount;
        })
        .handleError((error) {
          debugPrint('Error fetching total store count: $error');
          return 0;
        });
  } catch (e) {
    debugPrint('Error creating total store count stream: $e');
    return Stream.value(0);
  }
});

class UserStatsCard extends ConsumerWidget {
  const UserStatsCard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 全店舗合計スタンプに対する保有スタンプの進捗
          ref.watch(userTotalStampsProvider(userId)).when(
            data: (totalStamps) {
              final totalStoreCount = ref.watch(totalStoreCountProvider).maybeWhen(
                    data: (count) => count,
                    orElse: () => 0,
                  );
              final totalStampCapacity = totalStoreCount * 10;
              final progressValue = totalStampCapacity > 0
                  ? (totalStamps / totalStampCapacity).clamp(0.0, 1.0)
                  : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '全店舗スタンプ進捗',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$totalStamps/$totalStampCapacity',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 14,
                      backgroundColor: const Color(0xFFEAEAEA),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '全店舗合計スタンプ数のうち、保有スタンプ数',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // 開拓済み・スタンプ10個店舗数
          ref.watch(userStoreProgressProvider(userId)).when(
            data: (stats) {
              Widget buildDivider() => Container(width: 1, height: 36, color: Colors.grey[300]);
              Widget buildStatItem(String label, int value) {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  buildStatItem('開拓済み', stats.newPioneerCount),
                  buildDivider(),
                  buildStatItem('スタンプ満了', stats.stamp10StoreCount),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
