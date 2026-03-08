import 'package:flutter/material.dart';
import '../providers/zukan_provider.dart';
import 'rarity_gradient_container.dart';
import 'stamp_card_widget.dart';

/// カード背景のテクスチャ（グラデーション＋シミ感）を描画するパインター
class _CardTexturePainter extends CustomPainter {
  final Color baseColor;
  final Color accentColor;

  _CardTexturePainter({required this.baseColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. ベースグラデーション（上部明るく・下部やや深く）
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(baseColor, Colors.white, 0.30)!,
          baseColor,
          Color.lerp(baseColor, accentColor, 0.18)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // 2. テクスチャスポット（ポケモンカード風のシミ・ボケ光）
    // (x比率, y比率, radius比率, opacity, isLight)
    const spots = [
      (0.22, 0.15, 0.38, 0.26, true),   // 左上：明るいふわっとした光
      (0.80, 0.28, 0.30, 0.20, true),   // 右中上：小さめ輝き
      (0.55, 0.50, 0.50, 0.12, true),   // 中央：大きなぼんやり光
      (0.12, 0.70, 0.25, 0.18, false),  // 左下：やや暗めのシミ
      (0.72, 0.80, 0.35, 0.20, true),   // 右下：明るいスポット
      (0.45, 0.88, 0.20, 0.15, false),  // 下中央：暗めのアクセント
    ];

    for (final (xRatio, yRatio, rRatio, opacity, isLight) in spots) {
      final cx = size.width * xRatio;
      final cy = size.height * yRatio;
      final r = size.width * rRatio;

      final spotColor = isLight
          ? Color.lerp(Colors.white, accentColor, 0.08)!
          : Color.lerp(accentColor, Colors.black, 0.12)!;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            spotColor.withOpacity(opacity),
            spotColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_CardTexturePainter old) =>
      old.baseColor != baseColor || old.accentColor != accentColor;
}

/// 図鑑カードの表面UIウィジェット（ポケモンカード風）
///
/// サイズに応じてフォント・パディングが自動スケールする。
/// GridViewの小カード・NFCチェックイン結果・カード拡大表示など
/// あらゆる場面で統一されたカードUIを提供する。
class ZukanCardFaceWidget extends StatelessWidget {
  final ZukanStoreItem item;

  static const double _borderPadding = 3.0;

  const ZukanCardFaceWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final categoryColor = StampCardWidget.getCategoryColor(item.category);
    final categoryIcon = StampCardWidget.getCategoryIcon(item.category);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final nameFontSize = (w * 0.075).clamp(4.0, 13.0);
        final starFontSize = (w * 0.065).clamp(4.0, 11.0);
        final descFontSize = (w * 0.055).clamp(3.5, 9.0);
        final hPad = (w * 0.055).clamp(3.0, 12.0);
        final vPad = (w * 0.045).clamp(2.0, 10.0);

        return RarityGradientContainer(
          rarityLevel: item.rarityLevel,
          borderRadius: 10,
          padding: const EdgeInsets.all(_borderPadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: CustomPaint(
              painter: _CardTexturePainter(
                baseColor: Color.lerp(Colors.white, categoryColor, 0.22)!,
                accentColor: categoryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 上部: 店舗名 + レア度星
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad * 0.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: hPad * 0.4),
                        Text(
                          item.rarityStars,
                          style: TextStyle(
                            color: item.rarityColor,
                            fontSize: starFontSize,
                            height: 1.0,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 中央: 画像（左右余白でフレーム感を演出）
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: _buildImageContent(categoryColor, categoryIcon),
                      ),
                    ),
                  ),
                  // 下部: 説明テキスト
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(hPad),
                      child: Text(
                        item.description ?? '',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: descFontSize,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageContent(Color categoryColor, IconData categoryIcon) {
    final imageUrl = item.firstImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _buildIconFallback(categoryColor, categoryIcon),
      );
    }
    return _buildIconFallback(categoryColor, categoryIcon);
  }

  Widget _buildIconFallback(Color categoryColor, IconData categoryIcon) {
    return Container(
      color: categoryColor.withOpacity(0.25),
      child: Center(
        child: Icon(categoryIcon, color: categoryColor),
      ),
    );
  }

}
