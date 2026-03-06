import 'package:flutter/material.dart';

import '../theme/app_ui.dart';
import 'custom_button.dart';

// ダイアログのアクション定義
class GameDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;

  const GameDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.color,
  });
}

// ゲーム風ダイアログを表示するヘルパー関数
Future<void> showGameDialog({
  required BuildContext context,
  required String title,
  required String message,
  required List<GameDialogAction> actions,
  IconData icon = Icons.info_outline,
  Color headerColor = AppUi.primary,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => GameDialog(
      title: title,
      message: message,
      actions: actions,
      icon: icon,
      headerColor: headerColor,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class GameDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color headerColor;
  final List<GameDialogAction> actions;

  const GameDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.icon = Icons.info_outline,
    this.headerColor = AppUi.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: headerColor.withOpacity(0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 2.0,
            ),
          ),
          child: Icon(
            icon,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B6B),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ...actions.asMap().entries.map((entry) {
            final idx = entry.key;
            final action = entry.value;
            final isLast = idx == actions.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: CustomButton(
                text: action.label,
                onPressed: action.onPressed,
                backgroundColor: action.isPrimary
                    ? (action.color ?? headerColor)
                    : Colors.white,
                textColor: action.isPrimary
                    ? Colors.white
                    : (action.color ?? headerColor),
                borderColor:
                    action.isPrimary ? null : (action.color ?? headerColor),
              ),
            );
          }),
        ],
      ),
    );
  }
}
