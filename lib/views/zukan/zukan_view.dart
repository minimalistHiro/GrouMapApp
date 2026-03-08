import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/zukan_provider.dart';
import '../../theme/app_ui.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/zukan_card_face_widget.dart';
import '../../widgets/zukan_card_widget.dart';
import '../stores/store_detail_view.dart';

class ZukanView extends ConsumerStatefulWidget {
  const ZukanView({super.key});

  @override
  ConsumerState<ZukanView> createState() => _ZukanViewState();
}

class _ZukanViewState extends ConsumerState<ZukanView> {
  @override
  Widget build(BuildContext context) {
    final zukanAsync = ref.watch(zukanStoresProvider);
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null;

    return Scaffold(
      backgroundColor: AppUi.surface,
      body: SafeArea(
        bottom: false,
        child: zukanAsync.when(
          data: (allItems) {
            return Column(
              children: [
                // 開拓サマリーバー
                _buildSummaryBar(allItems, isLoggedIn),
                // グリッド
                Expanded(
                  child: allItems.isEmpty
                      ? _buildEmptyState()
                      : _buildFlatGrid(context, allItems),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CustomLoadingIndicator(primaryColor: AppUi.primary),
          ),
          error: (e, _) => Center(
            child: Text('読み込みエラー: $e',
                style: const TextStyle(color: Colors.black54)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(List<ZukanStoreItem> items, bool isLoggedIn) {
    final discovered = items.where((i) => i.isDiscovered).length;
    final total = items.length;
    final rate = total == 0 ? 0.0 : discovered / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLoggedIn
                    ? '発見済み $discovered店舗 / 全$total店舗'
                    : 'ログインして開拓率を確認しよう',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isLoggedIn)
                Text(
                  '${(rate * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppUi.primary,
                  ),
                ),
            ],
          ),
          if (isLoggedIn) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(AppUi.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlatGrid(BuildContext context, List<ZukanStoreItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.65,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ZukanCardWidget(
          item: item,
          index: index + 1,
          onTap: item.isDiscovered
              ? () => _showCardZoom(context, item)
              : () {
                  showGameDialog(
                    context: context,
                    title: 'まだ未発見のお店です',
                    message: 'お店に来店してNFCタッチすると、このカードを発見できます。',
                    icon: Icons.explore,
                    actions: [
                      GameDialogAction(
                        label: 'OK',
                        onPressed: () => Navigator.of(context).pop(),
                        isPrimary: true,
                      ),
                    ],
                  );
                },
        );
      },
    );
  }

  void _showCardZoom(BuildContext context, ZukanStoreItem item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.88),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拡大カード
                  SizedBox(
                    width: 240,
                    child: AspectRatio(
                      aspectRatio: 0.60,
                      child: ZukanCardFaceWidget(item: item),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 店舗詳細ボタン
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoreDetailView(store: item.store),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Text(
                        '店舗詳細を見る',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '店舗がありません',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
