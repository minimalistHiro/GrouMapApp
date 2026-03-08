import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// レア度グラデーションの定義を一元管理するクラス。
///
/// Widget用（LinearGradient）と Canvas用（ui.Gradient）の両方を提供する。
/// - 星1〜3: シルバーグラデーション（白×グレーの交互）
/// - 星4:   ゴールドグラデーション（白×金の交互）
///
/// 使用箇所:
/// - 図鑑カード枠: [RarityGradientContainer] ウィジェット
/// - マップピン:   [canvasFillGradient] / [canvasBorderGradient]
class RarityGradient {
  RarityGradient._();

  // ─────────────────────────────────────────────────────────────────
  // 色定数
  // ─────────────────────────────────────────────────────────────────

  /// ゴールドグラデーション色リスト（Widget枠用・星4）
  static const List<Color> goldColors = [
    Color(0xFFB8860B), Color(0xFFFFFFFF), Color(0xFFFFD700),
    Color(0xFFFFFFFF), Color(0xFFDAA520), Color(0xFFFFFFFF),
    Color(0xFFB8860B), Color(0xFFFFFFFF), Color(0xFFFFD700),
  ];

  /// シルバーグラデーション色リスト（Widget枠用・星1〜3）
  static const List<Color> silverColors = [
    Color(0xFFAAAAAA), Color(0xFFFFFFFF), Color(0xFFCCCCCC),
    Color(0xFFFFFFFF), Color(0xFFB8B8B8), Color(0xFFFFFFFF),
    Color(0xFFAAAAAA), Color(0xFFFFFFFF), Color(0xFFCCCCCC),
  ];

  /// ゴールド塗りつぶし色リスト（Canvas用・マップピンなど）
  static const List<Color> goldPinColors = [
    Color(0xFFFFF9C4),
    Color(0xFFFFD700),
    Color(0xFFDAA520),
    Color(0xFFB8860B),
  ];

  /// シルバー塗りつぶし色リスト（Canvas用・マップピンなど）
  static const List<Color> silverPinColors = [
    Color(0xFFEEEEEE),
    Color(0xFFBDBDBD),
    Color(0xFF9E9E9E),
  ];

  /// 緑塗りつぶし色リスト（Canvas用・営業中ピンなど）
  static const List<Color> greenPinColors = [
    Color(0xFF81C784),
    Color(0xFF43A047),
    Color(0xFF2E7D32),
  ];

  // stops
  static const List<double> _borderStops = [
    0.0, 0.1, 0.22, 0.35, 0.5, 0.65, 0.78, 0.9, 1.0
  ];
  static const List<double> _goldPinStops = [0.0, 0.3, 0.65, 1.0];
  static const List<double> _silverPinStops = [0.0, 0.5, 1.0];

  // ─────────────────────────────────────────────────────────────────
  // Widget 用 API
  // ─────────────────────────────────────────────────────────────────

  /// レア度に応じたボーダー用 [LinearGradient] を返す。
  ///
  /// - [rarityLevel] == 4 → ゴールド
  /// - [rarityLevel] 1〜3 → シルバー
  static LinearGradient borderGradient(int rarityLevel) {
    return LinearGradient(
      colors: rarityLevel == 4 ? goldColors : silverColors,
      stops: _borderStops,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// レア度に応じたグロー発光色を返す。
  static Color glowColor(int rarityLevel) {
    return rarityLevel == 4
        ? const Color(0xFFFFD700)
        : const Color(0xFFBBBBBB);
  }

  /// レア度に応じた [BoxShadow]（グロー効果）を返す。
  static BoxShadow glowBoxShadow(int rarityLevel, {double opacity = 0.35}) {
    return BoxShadow(
      color: glowColor(rarityLevel).withOpacity(opacity),
      blurRadius: 6,
      spreadRadius: 1,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Canvas 用 API（BitmapDescriptor / マップピンなど）
  // ─────────────────────────────────────────────────────────────────

  /// レア度に応じた Canvas 塗りつぶし用 [ui.Gradient] を返す。
  ///
  /// [from] から [to] へのリニアグラデーション。
  /// - [rarityLevel] == 4 → ゴールド
  /// - [rarityLevel] 1〜3 → シルバー
  static ui.Gradient canvasFillGradient(
    int rarityLevel,
    Offset from,
    Offset to,
  ) {
    if (rarityLevel == 4) {
      return ui.Gradient.linear(from, to, goldPinColors, _goldPinStops);
    }
    return ui.Gradient.linear(from, to, silverPinColors, _silverPinStops);
  }

  /// レア度に応じた Canvas ボーダー用 [ui.Gradient] を返す。
  ///
  /// [from] から [to] へのリニアグラデーション。
  /// - [rarityLevel] == 4 → ゴールド3色
  /// - [rarityLevel] 1〜3 → シルバー3色
  static ui.Gradient canvasBorderGradient(
    int rarityLevel,
    Offset from,
    Offset to,
  ) {
    if (rarityLevel == 4) {
      return ui.Gradient.linear(
        from,
        to,
        const [Color(0xFFFFF9C4), Color(0xFFFFD700), Color(0xFFB8860B)],
        [0.0, 0.5, 1.0],
      );
    }
    return ui.Gradient.linear(
      from,
      to,
      const [Color(0xFFEEEEEE), Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
      [0.0, 0.5, 1.0],
    );
  }

  /// 緑ピン用 Canvas 塗りつぶし / ボーダー [ui.Gradient]（営業中ピンなど）。
  static ui.Gradient canvasGreenFillGradient(Offset from, Offset to) {
    return ui.Gradient.linear(from, to, greenPinColors, [0.0, 0.5, 1.0]);
  }

  /// 任意のベースカラーから明→暗の Canvas 塗りつぶし [ui.Gradient] を生成する。
  ///
  /// カテゴリ色など動的な色を持つ通常ピンの円塗りつぶしに使用する。
  static ui.Gradient canvasColorFillGradient(
    Color baseColor,
    Offset from,
    Offset to,
  ) {
    return ui.Gradient.linear(
      from,
      to,
      [
        Color.lerp(baseColor, const Color(0xFFFFFFFF), 0.35)!,
        baseColor,
        Color.lerp(baseColor, const Color(0xFF000000), 0.25)!,
      ],
      [0.0, 0.5, 1.0],
    );
  }

  /// 任意のベースカラーから明→暗の Canvas ボーダー [ui.Gradient] を生成する。
  static ui.Gradient canvasColorBorderGradient(
    Color baseColor,
    Offset from,
    Offset to,
  ) {
    return ui.Gradient.linear(
      from,
      to,
      [
        Color.lerp(baseColor, const Color(0xFFFFFFFF), 0.45)!,
        baseColor,
        Color.lerp(baseColor, const Color(0xFF000000), 0.30)!,
      ],
      [0.0, 0.5, 1.0],
    );
  }
}
