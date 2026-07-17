import 'package:flutter/material.dart';
import 'rarity_gradient.dart';

/// レア度グラデーション枠を持つ汎用コンテナウィジェット。
///
/// [rarityLevel] に応じたシルバー/ゴールドのグラデーション枠と
/// グロー影を自動で適用する。図鑑カード・バッジ・その他カードUIなど
/// あらゆる場面で共通のレア度演出を再利用できる。
///
/// 使用例:
/// ```dart
/// RarityGradientContainer(
///   rarityLevel: item.rarityLevel,
///   child: YourContentWidget(),
/// )
/// ```
///
/// グラデーション色の定義は [RarityGradient] を参照。
class RarityGradientContainer extends StatelessWidget {
  final int rarityLevel;
  final Widget child;

  /// 枠の角丸半径（デフォルト 10）
  final double borderRadius;

  /// 枠の内側パディング（デフォルト EdgeInsets.all(5)）
  final EdgeInsetsGeometry padding;

  /// グロー影の不透明度（デフォルト 0.35）
  final double glowOpacity;

  const RarityGradientContainer({
    super.key,
    required this.rarityLevel,
    required this.child,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.all(5),
    this.glowOpacity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: RarityGradient.borderGradient(rarityLevel),
        boxShadow: [
          RarityGradient.glowBoxShadow(rarityLevel, opacity: glowOpacity),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
