import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/design_system/design_system.dart';

class QDLoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const QDLoadingShimmer({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: QDPalette.neutral100,
      highlightColor: QDPalette.neutral50,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: QDPalette.neutral100,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class QDLoadingCard extends StatelessWidget {
  const QDLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: QDSpace.screenPad, vertical: 6),
      padding: const EdgeInsets.all(QDSpace.cardPad),
      decoration: BoxDecoration(
        color: QDPalette.surfaceCard,
        borderRadius: BorderRadius.circular(QDRadius.card),
        border: Border.all(color: QDPalette.neutral100),
        boxShadow: QDShadow.card,
      ),
      child: Shimmer.fromColors(
        baseColor: QDPalette.neutral100,
        highlightColor: QDPalette.neutral50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: QDPalette.neutral100,
                  borderRadius: BorderRadius.circular(QDRadius.card),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 14, decoration: BoxDecoration(color: QDPalette.neutral100, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 120, decoration: BoxDecoration(color: QDPalette.neutral100, borderRadius: BorderRadius.circular(4))),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Container(height: 12, decoration: BoxDecoration(color: QDPalette.neutral100, borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }
}

class QDLoading extends StatelessWidget {
  final String? message;
  const QDLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: QDPalette.primary500,
            strokeWidth: 2.5,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(color: QDPalette.neutral400, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
