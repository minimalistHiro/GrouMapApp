import 'package:flutter/material.dart';

import '../theme/app_ui.dart';

class CustomTopTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTopTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.backgroundColor = AppUi.primary,
    this.labelColor = AppUi.onPrimary,
    this.unselectedLabelColor = AppUi.onPrimary,
    this.indicatorColor = AppUi.onPrimary,
  });

  final List<Tab> tabs;
  final TabController? controller;
  final Color backgroundColor;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Color indicatorColor;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: TabBar(
        controller: controller,
        tabs: tabs,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        indicatorColor: indicatorColor,
      ),
    );
  }
}
