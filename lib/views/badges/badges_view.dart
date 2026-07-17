import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import '../../widgets/common_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../models/badge_model.dart';
import '../../data/badge_definitions.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_dialog.dart';

class BadgesView extends ConsumerStatefulWidget {
  const BadgesView({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgesView> createState() => _BadgesViewState();
}

class _BadgesViewState extends ConsumerState<BadgesView> {
  String _selectedCategory = 'すべて';

  List<String> _buildCategories(List<BadgeModel> badges) {
    final categorySet = <String>{'すべて'};
    for (final badge in badges) {
      categorySet.add(badge.category ?? '未分類');
    }
    return categorySet.toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: CommonHeader(
        title: const Text('バッジ一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return _buildAuthRequired(context);
          }
          return _buildBadgesContent(context, user.uid);
        },
        loading: () => const Center(
          child: CustomLoadingIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildBadgesContent(BuildContext context, String userId) {
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));

    return userBadgesAsync.when(
      data: (userBadges) {
        // 取得済みバッジIDのセット
        final earnedBadgeIds = userBadges.map((ub) => ub.badgeId).toSet();

        // カテゴリフィルター適用（全バッジ定義から）
        final filteredBadges = _selectedCategory == 'すべて'
            ? kBadgeDefinitions
            : kBadgeDefinitions
                .where((b) => (b.category ?? '未分類') == _selectedCategory)
                .toList();

        return _buildBadgeGrid(filteredBadges, earnedBadgeIds);
      },
      loading: () => const Center(
        child: CustomLoadingIndicator(),
      ),
      error: (error, _) => Center(
        child: Text('バッジの読み込みに失敗しました'),
      ),
    );
  }

  Widget _buildAuthRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ログインが必要です',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240,
              child: CustomButton(
                text: 'ログイン',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signin');
                },
                backgroundColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 240,
              child: CustomButton(
                text: '新規アカウント作成',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signup');
                },
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                borderRadius: 999,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<BadgeModel> badges, Set<String> earnedBadgeIds) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final isEarned = earnedBadgeIds.contains(badge.badgeId);
          return _buildBadgeCard(badge, isEarned: isEarned);
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, {required bool isEarned}) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge, isEarned: isEarned),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isEarned)
            SizedBox(
              width: 72,
              height: 72,
              child: _getBadgeIcon(badge.iconUrl, size: 72),
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF6F2),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(-3, -3),
                  ),
                  BoxShadow(
                    color: const Color(0xFFCFBFB5).withOpacity(0.8),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.question_mark,
                size: 32,
                color: Colors.grey[400],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isEarned ? Colors.black87 : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _getBadgeIcon(String iconPath, {double size = 24}) {
    if (iconPath.isEmpty) {
      return Icon(
        Icons.emoji_events,
        size: size,
        color: const Color(0xFFFF6B35),
      );
    }

    return Image.asset(
      'assets/images/badges/$iconPath',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.emoji_events,
          size: size,
          color: const Color(0xFFFF6B35),
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge,
      {required bool isEarned}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) =>
          _BadgeDetailDialog(badge: badge, isEarned: isEarned),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  // game_dialog import は残すが、フィルターダイアログのみ使用
  void _showFilterDialog(BuildContext context) {
    final categories = _buildCategories(kBadgeDefinitions);

    showGameDialog(
      context: context,
      title: 'カテゴリ選択',
      message: '表示するバッジのカテゴリを選んでください',
      icon: Icons.filter_list,
      actions: [
        ...categories.map(
          (category) => GameDialogAction(
            label: category,
            isPrimary: category == _selectedCategory,
            onPressed: () {
              setState(() {
                _selectedCategory = category;
              });
              Navigator.of(context).pop();
            },
          ),
        ),
        GameDialogAction(
          label: 'キャンセル',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────
// バッジ詳細ポップアップ（GameDialogと同一スタイル）
// ────────────────────────────────────────────
class _BadgeDetailDialog extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;

  const _BadgeDetailDialog({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // バッジ画像（大）
              if (isEarned) _buildEarnedBadge() else _buildUnearnedBadge(),

              const SizedBox(height: 16),

              // バッジ名
              Text(
                badge.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              // カテゴリピル
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isEarned
                      ? const Color(0xFFFF6B35).withOpacity(0.12)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge.category ?? '未分類',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEarned
                        ? const Color(0xFFFF6B35)
                        : Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 説明文
              Text(
                badge.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6B6B),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 閉じるボタン
              CustomButton(
                text: '閉じる',
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: const Color(0xFFF0F0F0),
                textColor: const Color(0xFF6B6B6B),
                borderRadius: 999,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarnedBadge() {
    final iconPath = badge.iconUrl;
    if (iconPath.isEmpty) {
      return const Icon(
        Icons.emoji_events,
        size: 120,
        color: Color(0xFFFF6B35),
      );
    }
    return Image.asset(
      'assets/images/badges/$iconPath',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.emoji_events,
        size: 120,
        color: Color(0xFFFF6B35),
      ),
    );
  }

  Widget _buildUnearnedBadge() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EC),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(-5, -5),
          ),
          BoxShadow(
            color: const Color(0xFFCFBFB5).withOpacity(0.8),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Icon(
        Icons.question_mark,
        size: 52,
        color: Colors.grey[400],
      ),
    );
  }
}
