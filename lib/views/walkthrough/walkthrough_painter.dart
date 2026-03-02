import 'package:flutter/material.dart';

/// 画面全体をグレーアウトし、ハイライト対象部分に穴を開けるペインター
class WalkthroughPainter extends CustomPainter {
  final Rect? highlightRect;
  final double borderRadius;
  final Color overlayColor;

  WalkthroughPainter({
    this.highlightRect,
    this.borderRadius = 12.0,
    this.overlayColor = const Color(0x99000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (highlightRect != null) {
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            highlightRect!.inflate(8),
            Radius.circular(borderRadius),
          ),
        );
      final combinedPath =
          Path.combine(PathOperation.difference, fullPath, holePath);
      canvas.drawPath(combinedPath, paint);
    } else {
      canvas.drawPath(fullPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WalkthroughPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}
