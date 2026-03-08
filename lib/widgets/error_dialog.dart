import 'package:flutter/material.dart';

import '../theme/app_ui.dart';
import 'game_dialog.dart';

class ErrorDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    IconData icon = Icons.error_outline,
    Color headerColor = Colors.redAccent,
    String dismissLabel = '閉じる',
    String retryLabel = '再試行',
  }) {
    if (details != null && details.isNotEmpty) {
      debugPrint('$title: $details');
    }

    return showGameDialog(
      context: context,
      title: title,
      message: message,
      icon: icon,
      headerColor: headerColor,
      actions: [
        if (onRetry != null)
          GameDialogAction(
            label: dismissLabel,
            onPressed: onDismiss ?? () => Navigator.of(context).pop(),
          ),
        GameDialogAction(
          label: onRetry != null ? retryLabel : dismissLabel,
          onPressed: onRetry ?? onDismiss ?? () => Navigator.of(context).pop(),
          isPrimary: true,
          color: headerColor,
        ),
      ],
    );
  }

  static Future<void> showError(
    BuildContext context, {
    String title = 'エラー',
    required String message,
    String? details,
  }) {
    return show(
      context,
      title: title,
      message: message,
      details: details,
      icon: Icons.error_outline,
      headerColor: Colors.redAccent,
    );
  }

  static Future<void> showWarning(
    BuildContext context, {
    String title = '入力内容を確認してください',
    required String message,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      headerColor: Colors.orange,
    );
  }

  static Future<void> showNotice(
    BuildContext context, {
    String title = 'お知らせ',
    required String message,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline,
      headerColor: AppUi.primary,
    );
  }
}
