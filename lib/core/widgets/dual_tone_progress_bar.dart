import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/indian_currency_formatter.dart';

class DualToneProgressBar extends StatelessWidget {
  final double principalPaid;
  final double interestPaid;
  final double height;
  final bool showLabels;

  const DualToneProgressBar({
    super.key,
    required this.principalPaid,
    required this.interestPaid,
    this.height = 10,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final total = principalPaid + interestPaid;
    final principalRatio = total > 0 ? (principalPaid / total).clamp(0.0, 1.0) : 0.5;
    final interestRatio = total > 0 ? (interestPaid / total).clamp(0.0, 1.0) : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            color: AppColors.surfaceContainerLowest,
            child: Row(
              children: [
                if (principalRatio > 0)
                  Expanded(
                    flex: (principalRatio * 1000).round(),
                    child: Container(
                      color: AppColors.tertiary,
                    ),
                  ),
                if (interestRatio > 0)
                  Expanded(
                    flex: (interestRatio * 1000).round(),
                    child: Container(
                      color: AppColors.errorCoral,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Principal: ',
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    IndianCurrencyFormatter.format(principalPaid),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.errorCoral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Interest: ',
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    IndianCurrencyFormatter.format(interestPaid),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
