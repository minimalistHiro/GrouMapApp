import 'package:flutter/material.dart';

/// コンパクトなピル型トグルバー
///
/// マップ画面のフローティングトグル（開拓率 / 賑わい度 など）に使用する
/// テキストラベル切り替え型のトグルウィジェット。
///
/// [labels] にタブのラベル一覧、[selectedIndex] に現在の選択位置、
/// [onChanged] で選択変更を通知する。
class CompactToggleBar extends StatelessWidget {
  const CompactToggleBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.activeColor,
    this.activeTextColor = Colors.white,
    this.inactiveTextColor = Colors.black87,
    this.backgroundColor = Colors.white,
    this.fontSize = 12,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color? activeColor;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final Color backgroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final Color active =
        activeColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? active : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isSelected ? activeTextColor : inactiveTextColor,
                    fontSize: fontSize,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
