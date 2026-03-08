import 'package:flutter/material.dart';
import 'package:groumapapp/widgets/custom_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/area_provider.dart';
import '../../theme/app_ui.dart';
import '../../widgets/common_header.dart';

/// エリア開拓率一覧画面
/// 各エリアの個人開拓率・コミュニティ開拓率をプログレスバーで表示する
class AreaExplorationView extends ConsumerStatefulWidget {
  const AreaExplorationView({super.key});

  @override
  ConsumerState<AreaExplorationView> createState() =>
      _AreaExplorationViewState();
}

class _AreaExplorationViewState extends ConsumerState<AreaExplorationView> {
  /// true = 個人開拓率、false = みんなの開拓率
  bool _showMyRate = true;

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(areaExplorationRateProvider);

    return Scaffold(
      appBar: CommonHeader(title: 'エリア開拓率'),
      backgroundColor: AppUi.surface,
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: ratesAsync.when(
              data: (rates) => _buildAreaList(rates),
              loading: () => const Center(child: CustomLoadingIndicator()),
              error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton('マイ開拓率', true),
          const SizedBox(width: 8),
          _buildToggleButton('みんなの開拓率', false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isMyRate) {
    final isSelected = _showMyRate == isMyRate;
    return GestureDetector(
      onTap: () => setState(() => _showMyRate = isMyRate),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppUi.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppUi.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppUi.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAreaList(List<AreaExplorationRate> rates) {
    if (rates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'エリアが設定されていません',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: rates.length,
      itemBuilder: (context, index) => _buildAreaCard(rates[index]),
    );
  }

  Widget _buildAreaCard(AreaExplorationRate rate) {
    final progress = _showMyRate ? rate.myRate : rate.communityRate;
    final visitedCount =
        _showMyRate ? rate.myVisitedStores : rate.communityDiscoveredStores;
    final percent = (progress * 100).toInt();
    final areaColor = rate.area.displayColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUi.cardRadius),
      ),
      elevation: 2,
      color: AppUi.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: areaColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rate.area.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: areaColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(areaColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$visitedCount / ${rate.totalStores} 店舗',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (rate.area.description != null &&
                    rate.area.description!.isNotEmpty)
                  Flexible(
                    child: Text(
                      rate.area.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
