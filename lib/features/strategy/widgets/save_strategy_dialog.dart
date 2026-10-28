import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../../core/widgets/currency_input_field.dart';
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
  late final TextEditingController _lumpSumController;
  late double _steppedEmiPercent;
  late bool _enable13thEmi;
  late StrategyMode _strategyMode;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final PrepaymentPlan plan =
        widget.initialPlan ?? ref.read(prepaymentPlanProvider);
    _nameController = TextEditingController(text: 'My Custom Strategy');
    _descController = TextEditingController();

    final lumpSum = plan.lumpSums.isNotEmpty ? plan.lumpSums.first.amount : 0.0;
    _lumpSumController = TextEditingController(
      text: lumpSum > 0 ? IndianCurrencyFormatter.formatWithoutSymbol(lumpSum) : '',
    );
    _steppedEmiPercent = plan.steppedEmiPercentage;
    _enable13thEmi = plan.enableExtraAnnualEmi;
    _strategyMode = plan.strategyMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _lumpSumController.dispose();
    super.dispose();
  }

  PrepaymentPlan _buildCurrentPlan() {
    final lump = IndianCurrencyFormatter.parse(_lumpSumController.text);
    return PrepaymentPlan(
      lumpSums: lump > 0
          ? [LumpSumPrepayment(monthIndex: 12, amount: lump, note: 'Annual Prepayment')]
          : [],
      steppedEmiPercentage: _steppedEmiPercent,
      enableExtraAnnualEmi: _enable13thEmi,
      strategyMode: _strategyMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final config = ref.watch(loanConfigProvider);

    final currentPlan = _buildCurrentPlan();
    final result = LoanCalculatorEngine.calculate(config: config, plan: currentPlan);

    final lumpSumTotal = currentPlan.lumpSums.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
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
                      Icons.tune,
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
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Save current accelerators to reuse anytime',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Strategy Name Field
              Text(
                'Blueprint Name',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 12),

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

              // Goal Segmented Toggle
              Text(
                'Accelerator Payoff Goal',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _strategyMode = StrategyMode.reduceTenure),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _strategyMode == StrategyMode.reduceTenure
                                ? AppColors.tertiaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Reduce Tenure',
                            style: AppTypography.labelSmall.copyWith(
                              color: _strategyMode == StrategyMode.reduceTenure
                                  ? AppColors.onTertiaryContainer
                                  : AppColors.onSurfaceVariant,
                              fontWeight: _strategyMode == StrategyMode.reduceTenure
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _strategyMode = StrategyMode.reduceEmi),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _strategyMode == StrategyMode.reduceEmi
                                ? AppColors.tertiaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Reduce Monthly EMI',
                            style: AppTypography.labelSmall.copyWith(
                              color: _strategyMode == StrategyMode.reduceEmi
                                  ? AppColors.onTertiaryContainer
                                  : AppColors.onSurfaceVariant,
                              fontWeight: _strategyMode == StrategyMode.reduceEmi
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Knob 1: Annual Lump Sum Prepayment
              Text(
                'Annual Lump Sum Prepayment',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              CurrencyInputField(
                controller: _lumpSumController,
                label: 'Lump Sum Amount',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  {'label': '₹0', 'amount': 0},
                  {'label': '₹50,000', 'amount': 50000},
                  {'label': '₹1,00,000', 'amount': 100000},
                  {'label': '₹2,00,000', 'amount': 200000},
                  {'label': '₹5,00,000', 'amount': 500000},
                ].map((item) {
                  final amt = item['amount'] as int;
                  final lbl = item['label'] as String;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _lumpSumController.text = amt > 0
                            ? IndianCurrencyFormatter.formatWithoutSymbol(
                                amt.toDouble())
                            : '';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        lbl,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Knob 2: Annual EMI Step-Up Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Annual EMI Step-Up',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '+${_steppedEmiPercent.toStringAsFixed(0)}% / yr',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.tertiary,
                  inactiveTrackColor: AppColors.surfaceContainerHighest,
                  thumbColor: AppColors.tertiary,
                  overlayColor: AppColors.tertiary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _steppedEmiPercent.clamp(0.0, 25.0),
                  min: 0.0,
                  max: 25.0,
                  divisions: 25,
                  onChanged: (val) {
                    setState(() => _steppedEmiPercent = val);
                  },
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [0.0, 5.0, 7.0, 10.0, 15.0].map((pct) {
                  final isSel = _steppedEmiPercent.round() == pct.round();
                  return InkWell(
                    onTap: () => setState(() => _steppedEmiPercent = pct),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.tertiaryContainer
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel
                              ? AppColors.tertiary
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        '${pct.toInt()}%',
                        style: AppTypography.labelSmall.copyWith(
                          color: isSel
                              ? AppColors.onTertiaryContainer
                              : AppColors.onSurfaceVariant,
                          fontWeight:
                              isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Knob 3: 13th Extra Annual EMI Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '13th Annual EMI (December)',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Prepay 1 extra EMI every year to shred principal',
                            style:
                                AppTypography.bodySmall.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enable13thEmi,
                      activeThumbColor: AppColors.tertiary,
                      onChanged: (val) => setState(() => _enable13thEmi = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Configuration Summary Preview Card (LIVE REAL-TIME ENGINE CALCULATION)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.3),
                  ),
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
                            color: AppColors.tertiary,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentPlan.strategyMode.displayName,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onTertiaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                          label: '+${currentPlan.steppedEmiPercentage.toStringAsFixed(0)}% Step-Up/Yr',
                          active: currentPlan.steppedEmiPercentage > 0,
                        ),
                        _buildChip(
                          icon: Icons.savings,
                          label: lumpSumTotal > 0
                              ? 'Lump: ${IndianCurrencyFormatter.formatCompact(lumpSumTotal)}'
                              : 'No Lump Sum',
                          active: lumpSumTotal > 0,
                        ),
                        _buildChip(
                          icon: Icons.event_repeat,
                          label: currentPlan.enableExtraAnnualEmi
                              ? '13th EMI'
                              : 'No 13th EMI',
                          active: currentPlan.enableExtraAnnualEmi,
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
                          'Projected Savings:',
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
                    if (result.monthsSaved > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Debt-Free By:',
                            style: AppTypography.bodySmall,
                          ),
                          Text(
                            DateFormat('MMM yyyy').format(result.optimizedEndDate),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions: Cancel & Save Blueprint
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
                        final blueprintPlan = _buildCurrentPlan();

                        final savedBlueprint = ref
                            .read(savedStrategiesProvider.notifier)
                            .saveStrategy(
                              name: name,
                              description: desc.isNotEmpty ? desc : null,
                              plan: blueprintPlan,
                            );

                        // Set as active blueprint and apply plan
                        ref
                            .read(activeBlueprintIdProvider.notifier)
                            .setActive(savedBlueprint.id);
                        ref
                            .read(prepaymentPlanProvider.notifier)
                            .applyPlan(blueprintPlan);

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
