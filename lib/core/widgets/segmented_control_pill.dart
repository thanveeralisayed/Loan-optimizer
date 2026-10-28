import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SegmentOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? badge;

  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
  });
}

class SegmentedControlPill<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const SegmentedControlPill({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option.value == selectedValue;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: AppColors.borderLight, width: 1)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (option.icon != null) ...[
                      Icon(
                        option.icon,
                        size: 16,
                        color: isSelected
                            ? AppColors.tertiary
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        option.label,
                        style: isSelected
                            ? AppTypography.labelLarge.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              )
                            : AppTypography.labelMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (option.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          option.badge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.tertiary,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
