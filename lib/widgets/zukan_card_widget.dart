import 'package:flutter/material.dart';
import '../providers/zukan_provider.dart';
import 'stamp_card_widget.dart';

class ZukanCardWidget extends StatelessWidget {
  final ZukanStoreItem item;
  final VoidCallback? onTap;
  final int? index;

  static const double _topStripHeight = 14.0;

  const ZukanCardWidget({super.key, required this.item, this.onTap, this.index});

  @override
  Widget build(BuildContext context) {
    return item.isDiscovered ? _buildDiscoveredCard() : _buildUndiscoveredCard();
  }

  Widget _buildDiscoveredCard() {
    final categoryColor = StampCardWidget.getCategoryColor(item.category);
    final categoryIcon = StampCardWidget.getCategoryIcon(item.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: _rarityGradient(item.rarityLevel),
        ),
        padding: const EdgeInsets.all(3.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 上部: 固定高さ帯 + 店舗名 + レア度星
              SizedBox(
                height: _topStripHeight,
                child: Container(
                  color: categoryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 5,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 1)],
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.rarityStars,
                        style: TextStyle(
                          color: item.rarityColor,
                          fontSize: 5,
                          height: 1.0,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 中央: 1:1 正方形アイコン・画像（幅に合わせて高さが自動決定）
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRect(
                  child: _buildImageContent(categoryColor, categoryIcon),
                ),
              ),
              // 下部: 説明テキスト（余白付き）
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _truncateDescription(item.description),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 4,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUndiscoveredCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade400, width: 2.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 上部: 固定高さ帯 + ??? + 空星
              SizedBox(
                height: _topStripHeight,
                child: Container(
                  color: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '???',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 5,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '☆☆☆☆',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 中央: 1:1 正方形グレー背景 + ??? マーク
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // 下部: 説明テキスト（余白付き）
              Expanded(
                child: Container(
                  color: Colors.grey.shade300,
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _truncateDescription(item.description),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 4,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(Color categoryColor, IconData categoryIcon) {
    final imageUrl = item.firstImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIconFallback(categoryColor, categoryIcon),
      );
    }
    return _buildIconFallback(categoryColor, categoryIcon);
  }

  Widget _buildIconFallback(Color categoryColor, IconData categoryIcon) {
    return Container(
      color: categoryColor.withOpacity(0.25),
      child: Center(
        child: Icon(
          categoryIcon,
          color: categoryColor,
          size: 22,
        ),
      ),
    );
  }

  // レア度に応じたグラデーション（星1〜3: シルバー、星4: ゴールド）
  LinearGradient _rarityGradient(int rarityLevel) {
    if (rarityLevel == 4) {
      // ゴールドグラデーション
      return const LinearGradient(
        colors: [
          Color(0xFFB8860B),
          Color(0xFFFFD700),
          Color(0xFFDAA520),
          Color(0xFFB8860B),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // シルバーグラデーション（星1〜3共通）
    return const LinearGradient(
      colors: [
        Color(0xFF9E9E9E),
        Color(0xFFE8E8E8),
        Color(0xFFBDBDBD),
        Color(0xFF9E9E9E),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _truncateDescription(String? description) {
    if (description == null || description.isEmpty) return '';
    return description.length > 40 ? description.substring(0, 40) : description;
  }
}
