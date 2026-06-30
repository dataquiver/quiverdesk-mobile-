import 'package:flutter/material.dart';
import '../../app/themes.dart';
import 'qd_button.dart';

class QDError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const QDError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: QDColors.errorLight,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.error_outline_rounded, color: QDColors.error, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: QDColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: QDColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              QDButton(label: 'Try Again', onPressed: onRetry, icon: Icons.refresh),
            ],
          ],
        ),
      ),
    );
  }
}
