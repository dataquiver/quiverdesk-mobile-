import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/design_system/design_system.dart';

class QDButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? color;
  final double? width;

  const QDButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.color,
    this.width,
  });

  const QDButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.width,
  }) : isOutlined = true;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? QDPalette.primary500;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isOutlined ? effectiveColor : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1),
              ),
            ],
          );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed?.call();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveColor, width: 1.5),
          minimumSize: Size(width ?? double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QDRadius.button),
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed?.call();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: QDPalette.primary200,
        minimumSize: Size(width ?? double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QDRadius.button),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: child,
    );
  }
}

class QDTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const QDTextButton({super.key, required this.label, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? QDPalette.primary600,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
