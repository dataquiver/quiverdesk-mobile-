import 'package:flutter/material.dart';
import '../../app/design_system/design_system.dart';
import 'qd_button.dart';

class QDError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const QDError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: QDPalette.errorBg,
                borderRadius: BorderRadius.circular(QDRadius.full),
              ),
              child: const Icon(Icons.error_outline_rounded, color: QDPalette.error500, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: QDPalette.neutral800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: QDPalette.neutral400,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              QDButton(label: 'Try Again', onPressed: onRetry, icon: Icons.refresh_rounded),
            ],
          ],
        ),
      ),
    );
  }
}
