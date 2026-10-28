import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../../models/prepayment_plan.dart';
import '../../../providers/loan_provider.dart';
import '../../../services/loan_calculator_engine.dart';

class SaveStrategyDialog extends ConsumerStatefulWidget {
  final PrepaymentPlan? initialPlan;

  const SaveStrategyDialog({super.key, this.initialPlan});

  static Future<String?> show(
    BuildContext context, {
    PrepaymentPlan? initialPlan,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SaveStrategyDialog(initialPlan: initialPlan),
    );
  }

  @override
  ConsumerState<SaveStrategyDialog> createState() => _SaveStrategyDialogState();
}

class _SaveStrategyDialogState extends ConsumerState<SaveStrategyDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'My Custom Strategy');
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final PrepaymentPlan plan =
        widget.initialPlan ?? ref.watch(prepaymentPlanProvider);
    final config = ref.watch(loanConfigProvider);
    final result = LoanCalculatorEngine.calculate(config: config, plan: plan);

    final lumpSumTotal = plan.lumpSums.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bookmark_add,
                      color: AppColors.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save Payoff Blueprint',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Save current accelerators to reuse anytime',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Strategy Name Field
              Text(
                'Blueprint Name',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Diwali Bonus + 7% Step-Up',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.outline,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tertiary),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name for your strategy blueprint';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description Field
              Text(
                'Description (Optional)',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                ),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Optimized for annual appraisals and festive bonuses',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.outline,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tertiary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Configuration Summary Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INCLUDED CONFIGURATION',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          plan.strategyMode.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildChip(
                          icon: Icons.trending_up,
                          label: '+${plan.steppedEmiPercentage.toStringAsFixed(0)}% Step-Up/Yr',
                          active: plan.steppedEmiPercentage > 0,
                        ),
                        _buildChip(
                          icon: Icons.savings,
                          label: lumpSumTotal > 0
                              ? 'Lump Sum: ${IndianCurrencyFormatter.formatCompact(lumpSumTotal)}'
                              : 'No Lump Sum',
                          active: lumpSumTotal > 0,
                        ),
                        _buildChip(
                          icon: Icons.event_repeat,
                          label: plan.enableExtraAnnualEmi
                              ? '13th EMI (Dec)'
                              : 'No 13th EMI',
                          active: plan.enableExtraAnnualEmi,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Projected Impact:',
                          style: AppTypography.bodySmall,
                        ),
                        Text(
                          'Saves ${IndianCurrencyFormatter.formatCompact(result.totalInterestSaved)} • -${(result.monthsSaved / 12).toStringAsFixed(1)} Yrs',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final name = _nameController.text.trim();
                        final desc = _descController.text.trim();
                        ref.read(savedStrategiesProvider.notifier).saveStrategy(
                              name: name,
                              description: desc.isNotEmpty ? desc : null,
                              plan: plan,
                            );
                        Navigator.of(context).pop(name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'Save Blueprint',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.tertiary.withValues(alpha: 0.12)
            : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? AppColors.tertiary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? AppColors.tertiary : AppColors.outline,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: active ? AppColors.tertiary : AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
