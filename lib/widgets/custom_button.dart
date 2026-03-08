import 'package:flutter/material.dart';

import '../theme/app_ui.dart';
import 'custom_loading_indicator.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final Widget? icon;
  final double? width;
  final double? height;
  final double? borderRadius;
  final TextStyle? textStyle;
  final Gradient? gradient;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.width,
    this.height,
    this.borderRadius,
    this.textStyle,
    this.gradient,
  }) : super(key: key);

  // グラデーションなし（solid color / outline）にしたいときに明示的に渡す
  static const Gradient defaultGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
  );

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 999.0;
    final effectiveTextColor = textColor ?? Colors.white;

    // backgroundColor も borderColor も指定されていなければデフォルトグラデーション
    final effectiveGradient = gradient ??
        (backgroundColor == null && borderColor == null
            ? defaultGradient
            : null);

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CustomLoadingIndicator.inline(
              size: 20,
              padding: 3,
              primaryColor: textColor ?? textStyle?.color ?? Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: (textStyle ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ))
                    .copyWith(color: effectiveTextColor),
              ),
            ],
          );

    if (effectiveGradient != null) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 48,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: Ink(
              decoration: BoxDecoration(
                gradient:
                    (isLoading || onPressed == null) ? null : effectiveGradient,
                color: (isLoading || onPressed == null)
                    ? Colors.grey.shade300
                    : null,
                borderRadius: BorderRadius.circular(radius),
                border: borderColor != null
                    ? Border.all(color: borderColor!)
                    : null,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppUi.primary,
          foregroundColor: effectiveTextColor,
          side: borderColor != null ? BorderSide(color: borderColor!) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
