import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/monthly_report_model.dart';
import '../../providers/monthly_report_provider.dart';
import '../../utils/share_text_generator.dart';

class MonthlyReportView extends ConsumerWidget {
  final String yearMonth;

  const MonthlyReportView({Key? key, required this.yearMonth})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(monthlyReportProvider(yearMonth));

    final year = yearMonth.substring(0, 4);
    final month = yearMonth.substring(5, 7);
    final title = '$year年${month}月の探検レポート';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        title: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          reportAsync.when(
            data: (report) => report != null
                ? IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFFFF6B35)),
                    tooltip: 'シェア',
                    onPressed: () => _copyToClipboard(context, report),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'まだレポートはありません',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'NFCチェックインして街を探検すると\n月末にレポートが届きます',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }
          return _ReportBody(report: report, yearMonth: yearMonth);
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (e, _) => Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, MonthlyReportModel report) {
    final text = ShareTextGenerator.generateMonthlyReport(report);
    Clipboard.setData(ClipboardData(text: text));
  }
}

class _ReportBody extends StatelessWidget {
  final MonthlyReportModel report;
  final String yearMonth;

  const _ReportBody({required this.report, required this.yearMonth});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // セクション1: 今月のハイライト
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今月のハイライト',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // 大きな数字
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${report.monthlyDiscoveredCount}',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                          height: 1.0,
                        ),
                      ),
                      const Text('店舗を発見',
                          style:
                              TextStyle(fontSize: 16, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        '累計 ${report.totalDiscoveredCount} 店舗を発見',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                // 最もよく行ったジャンル
                if (report.topGenre != null) ...[
                  _buildInfoRow(
                    icon: Icons.restaurant,
                    label: '今月のお気に入りジャンル',
                    value:
                        '${genreLabels[report.topGenre] ?? report.topGenre} (${report.topGenreCount}回)',
                  ),
                  const SizedBox(height: 8),
                ],
                // 訪問エリア
                if (report.visitedAreas.isNotEmpty) ...[
                  const Text('探検エリア',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: report.visitedAreas
                        .map((a) => Chip(
                              label:
                                  Text(a, style: const TextStyle(fontSize: 12)),
                              backgroundColor:
                                  const Color(0xFFFF6B35).withOpacity(0.12),
                              side: BorderSide.none,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                // レジェンド発見
                if (report.legendDiscoveredCount > 0)
                  _buildInfoRow(
                    icon: Icons.star,
                    label: 'レジェンド発見',
                    value: '${report.legendDiscoveredCount}店舗！',
                    valueColor: Colors.amber,
                  ),
                // 今月の賑わい貢献
                _buildInfoRow(
                  icon: Icons.local_fire_department,
                  label: '今月の来店回数',
                  value: '${report.totalVisitsThisMonth}回',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // セクション2: コミュニティへの貢献
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('コミュニティへの貢献',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.group,
                  label: 'コミュニティの発見に貢献',
                  value: '${report.communityContributionCount}店舗',
                ),
                if (report.hotStoresCount > 0)
                  _buildInfoRow(
                    icon: Icons.local_fire_department,
                    label: '炎マーク（常連）の店舗',
                    value: '${report.hotStoresCount}店舗',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // セクション3: 今月のコミュニティ全体
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今月のコミュニティ全体',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.explore,
                  label: '全体の発見店舗数',
                  value: '${report.communityDiscoveredCount}店舗',
                ),
                _buildInfoRow(
                  icon: Icons.add_business,
                  label: '今月の新規追加店舗',
                  value: '${report.newStoresAddedCount}店舗',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // セクション4: 来月のおすすめ
          if (report.recommendedStores.isNotEmpty) ...[
            _buildSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('来月のおすすめ',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.recommendedStores.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final s = report.recommendedStores[i];
                        return _RecommendedStoreCard(store: s);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // フッター: SNSシェアエリア
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('SNSシェア',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ShareTextGenerator.generateMonthlyReport(report),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final text =
                        ShareTextGenerator.generateMonthlyReport(report);
                    Clipboard.setData(ClipboardData(text: text));
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('コピーしてシェア'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF6B35)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedStoreCard extends StatelessWidget {
  final RecommendedStore store;

  const _RecommendedStoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final rarityLabel = store.rarity == 4 ? 'LEGEND' : 'EPIC';
    final rarityColor = store.rarity == 4 ? Colors.amber : Colors.purple;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: rarityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(rarityLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: rarityColor)),
          ),
          const SizedBox(height: 4),
          Text(
            store.storeName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(store.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }
}

/// 過去のレポート月一覧画面
class MonthlyReportListView extends ConsumerWidget {
  const MonthlyReportListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthsAsync = ref.watch(availableReportMonthsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        title: const Text('過去のレポート',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: monthsAsync.when(
        data: (months) {
          if (months.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('まだレポートはありません',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(
                      'NFCチェックインして街を探検すると\n月末にレポートが届きます',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: months.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final ym = months[i];
              final year = ym.substring(0, 4);
              final month = ym.substring(5, 7);
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.explore, color: Color(0xFFFF6B35)),
                ),
                title: Text('$year年${month}月の探検レポート',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(ym,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MonthlyReportView(yearMonth: ym)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (e, _) => Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }
}
