import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CurrencyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? subtitle;
  final ValueChanged<String>? onChanged;
  final IconData? suffixIcon;
  final bool readOnly;

  const CurrencyInputField({
    super.key,
    required this.controller,
    required this.label,
    this.subtitle,
    this.onChanged,
    this.suffixIcon = Icons.account_balance_wallet_outlined,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.tertiary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Row(
            children: [
              Text(
                '₹',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  style: AppTypography.metricCurrency.copyWith(
                    fontSize: 24,
                    color: AppColors.onSurface,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.outline),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (suffixIcon != null)
                Icon(
                  suffixIcon,
                  color: AppColors.onSurfaceVariant,
                  size: 22,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

