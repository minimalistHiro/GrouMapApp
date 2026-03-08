import 'package:flutter/material.dart';
import '../providers/zukan_provider.dart';
import 'zukan_card_face_widget.dart';

class ZukanCardWidget extends StatelessWidget {
  final ZukanStoreItem item;
  final VoidCallback? onTap;
  final int? index;

  static const double _borderPadding = 3.0;

  const ZukanCardWidget({super.key, required this.item, this.onTap, this.index});

  @override
  Widget build(BuildContext context) {
    return item.isDiscovered ? _buildDiscoveredCard() : _buildUndiscoveredCard();
  }

  Widget _buildDiscoveredCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ZukanCardFaceWidget(item: item),
      ),
    );
  }

  Widget _buildUndiscoveredCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade400,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_borderPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 上部: ??? + 空星
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '???',
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
                          color: Colors.grey.shade500,
                          fontSize: 5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // 中央: グレー背景 + ??? マーク
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        color: Colors.grey.shade300,
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
                  ),
                ),
                // 下部: 説明テキスト
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Text(
                      _truncateDescription(item.description),
                      style: TextStyle(
                        color: Colors.grey.shade500,
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
      ),
    );
  }

  String _truncateDescription(String? description) {
    if (description == null || description.isEmpty) return '';
    return description.length > 40 ? description.substring(0, 40) : description;
  }
}
