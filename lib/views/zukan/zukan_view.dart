import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/zukan_provider.dart';
import '../../theme/app_ui.dart';
import '../../widgets/common_header.dart';
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
      appBar: CommonHeader(
        title: const Text('図鑑'),
        showBack: false,
      ),
      body: zukanAsync.when(
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
          child: CircularProgressIndicator(color: AppUi.primary),
        ),
        error: (e, _) => Center(
          child: Text('読み込みエラー: $e',
              style: const TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(List<ZukanStoreItem> items, bool isLoggedIn) {
    final discovered = items.where((i) => i.isDiscovered).length;
    final total = items.length;
    final rate = total == 0 ? 0.0 : discovered / total;

    return Container(
      color: Colors.white,
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
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.60,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ZukanCardWidget(
          item: item,
          index: index + 1,
          onTap: item.isDiscovered
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoreDetailView(store: item.store),
                    ),
                  );
                }
              : () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('まだ未発見のお店です'),
                      content: const Text(
                        'お店に来店してNFCタッチすると、このカードを発見できます。',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
