import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../models/badge_model.dart';

class BadgesView extends ConsumerStatefulWidget {
  const BadgesView({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgesView> createState() => _BadgesViewState();
}

class _BadgesViewState extends ConsumerState<BadgesView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('ログインが必要です')),
          );
        }
        return _buildBadgesView(user.uid);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildBadgesView(String userId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('バッジ'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '獲得済み', icon: Icon(Icons.check_circle)),
            Tab(text: '未獲得', icon: Icon(Icons.lock)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnlockedBadges(userId),
          _buildLockedBadges(userId),
        ],
      ),
    );
  }

  Widget _buildUnlockedBadges(String userId) {
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));

    return userBadgesAsync.when(
      data: (badges) {
        if (badges.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'まだバッジを獲得していません',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'ポイントを獲得してバッジを手に入れましょう！',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final userBadge = badges[index];
            return _buildBadgeCard(userBadge, isUnlocked: true);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildLockedBadges(String userId) {
    final availableBadgesAsync = ref.watch(availableBadgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));

    return availableBadgesAsync.when(
      data: (allBadges) {
        return userBadgesAsync.when(
          data: (userBadges) {
            final unlockedBadgeIds = userBadges.map((b) => b.badgeId).toSet();
            final lockedBadges = allBadges.where((b) => !unlockedBadgeIds.contains(b.badgeId)).toList();

            if (lockedBadges.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'すべてのバッジを獲得しました！',
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'おめでとうございます！',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lockedBadges.length,
              itemBuilder: (context, index) {
                final badge = lockedBadges[index];
                return _buildBadgeCard(badge, isUnlocked: false);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('エラー: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildBadgeCard(dynamic badge, {required bool isUnlocked}) {
    final isUserBadge = badge is UserBadgeModel;
    final badgeModel = isUserBadge ? null : badge as BadgeModel;
    final userBadge = isUserBadge ? badge as UserBadgeModel : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    _getRarityColor(badgeModel?.rarity ?? BadgeRarity.common).withOpacity(0.1),
                    _getRarityColor(badgeModel?.rarity ?? BadgeRarity.common).withOpacity(0.05),
                  ],
                )
              : null,
        ),
        child: ListTile(
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? _getRarityColor(badgeModel?.rarity ?? BadgeRarity.common)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _getRarityColor(badgeModel?.rarity ?? BadgeRarity.common),
                width: 2,
              ),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              color: isUnlocked ? Colors.white : Colors.grey.shade600,
              size: 30,
            ),
          ),
          title: Text(
            isUserBadge ? 'バッジID: ${userBadge!.badgeId}' : badgeModel!.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black : Colors.grey.shade600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUserBadge ? '獲得済み' : badgeModel!.description,
                style: TextStyle(
                  color: isUnlocked ? Colors.grey.shade700 : Colors.grey.shade500,
                ),
              ),
              if (isUserBadge) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: userBadge!.progress / userBadge.requiredValue,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getRarityColor(badgeModel?.rarity ?? BadgeRarity.common),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userBadge.progress} / ${userBadge.requiredValue}',
                  style: const TextStyle(fontSize: 12),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRarityColor(badgeModel!.rarity).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeModel.rarity.displayName,
                    style: TextStyle(
                      color: _getRarityColor(badgeModel.rarity),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: isUnlocked && isUserBadge
              ? Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                )
              : Icon(
                  Icons.lock,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
        ),
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    return Color(int.parse(rarity.colorHex.replaceFirst('#', '0xFF')));
  }
}
