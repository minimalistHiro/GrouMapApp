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
                color: const Color(0xFF9BB8D4).withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 8,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final hasTwoActions = actions.length == 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B6B),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasTwoActions)
            Row(
              children: [
                Expanded(child: _buildButton(actions[0])),
                const SizedBox(width: 12),
                Expanded(child: _buildButton(actions[1])),
              ],
            )
          else
            ...actions.asMap().entries.map((entry) {
              final isLast = entry.key == actions.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: _buildButton(entry.value),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildButton(GameDialogAction action) {
    if (action.isPrimary) {
      return CustomButton(
        text: action.label,
        onPressed: action.onPressed,
        gradient: action.color != null
            ? LinearGradient(colors: [action.color!, action.color!])
            : null,
      );
    } else {
      return CustomButton(
        text: action.label,
        onPressed: action.onPressed,
        backgroundColor: const Color(0xFFF0F0F0),
        textColor: const Color(0xFF6B6B6B),
      );
    }
  }
}
