import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/indian_currency_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/currency_input_field.dart';
import '../../core/widgets/quick_amount_chip.dart';
import '../../core/widgets/segmented_control_pill.dart';
import '../../models/loan_config.dart';
import '../../providers/loan_provider.dart';
import '../strategy/widgets/strategy_preset_selector.dart';

class LoanSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSaved;

  const LoanSetupScreen({super.key, this.onSaved});

  @override
  ConsumerState<LoanSetupScreen> createState() => _LoanSetupScreenState();
}

class _LoanSetupScreenState extends ConsumerState<LoanSetupScreen> {
  late TextEditingController _principalController;
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(loanConfigProvider);
    _principalController = TextEditingController(
      text: IndianCurrencyFormatter.formatWithoutSymbol(config.principal),
    );
    _rateController = TextEditingController(
      text: config.annualInterestRate.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(loanConfigProvider);
    final notifier = ref.read(loanConfigProvider.notifier);
    final years = config.tenureMonths ~/ 12;
    final monthsRemainder = config.tenureMonths % 12;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Configure Loan',
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Local & Offline Engine Privacy Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 14,
                      color: AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOCAL & OFFLINE ENGINE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.tertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All calculations computed 100% offline on your device for absolute privacy.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Header Title
            Text(
              'Configure Loan & Targets',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Input your borrowing parameters to instantly model repayment trajectories and savings.',
              style: AppTypography.bodySmall,
            ),

            const SizedBox(height: 20),

            // Loan Category Selector
            Text('Loan Type', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: LoanType.values.map((type) {
                  final isSelected = config.loanType == type;
                  IconData icon;
                  switch (type) {
                    case LoanType.home:
                      icon = Icons.home;
                      break;
                    case LoanType.car:
                      icon = Icons.directions_car;
                      break;
                    case LoanType.personal:
                      icon = Icons.person;
                      break;
                    case LoanType.education:
                      icon = Icons.school;
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => notifier.updateLoanType(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondaryContainer
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.borderSubtle,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondaryContainer
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: isSelected
                                  ? AppColors.onSecondaryContainer
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type.displayName,
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.onSecondaryContainer
                                    : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Principal Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CurrencyInputField(
                    controller: _principalController,
                    label: 'Principal Loan Amount',
                    subtitle: IndianCurrencyFormatter.toWords(config.principal),
                    onChanged: (val) {
                      final parsed = IndianCurrencyFormatter.parse(val);
                      notifier.updatePrincipal(parsed);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Quick Addition Chips
                  Row(
                    children: [
                      QuickAmountChip(
                        label: '+ ₹5L',
                        onTap: () {
                          notifier.adjustPrincipal(500000);
                          _principalController.text =
                              IndianCurrencyFormatter.formatWithoutSymbol(
                                  ref.read(loanConfigProvider).principal);
                        },
                      ),
                      const SizedBox(width: 8),
                      QuickAmountChip(
                        label: '+ ₹10L',
                        onTap: () {
                          notifier.adjustPrincipal(1000000);
                          _principalController.text =
                              IndianCurrencyFormatter.formatWithoutSymbol(
                                  ref.read(loanConfigProvider).principal);
                        },
                      ),
                      const SizedBox(width: 8),
                      QuickAmountChip(
                        label: '+ ₹25L',
                        onTap: () {
                          notifier.adjustPrincipal(2500000);
                          _principalController.text =
                              IndianCurrencyFormatter.formatWithoutSymbol(
                                  ref.read(loanConfigProvider).principal);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Interest Rate & Mode Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Interest Rate (% p.a.)',
                          style: AppTypography.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Floating / Fixed Toggle
                      SizedBox(
                        width: 155,
                        child: SegmentedControlPill<RateType>(
                          options: const [
                            SegmentOption(
                              value: RateType.floating,
                              label: 'Floating',
                            ),
                            SegmentOption(
                              value: RateType.fixed,
                              label: 'Fixed',
                            ),
                          ],
                          selectedValue: config.rateType,
                          onSelected: (mode) => notifier.updateRateType(mode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 75,
                              child: TextField(
                                controller: _rateController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                style: AppTypography.headlineMedium,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onChanged: (val) {
                                  final r = double.tryParse(val) ?? 0.0;
                                  notifier.updateRate(r);
                                },
                              ),
                            ),
                            Text('%', style: AppTypography.headlineMedium),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              config.rateType == RateType.floating
                                  ? 'Repo-linked (RBI + 2.0%)'
                                  : 'Fixed Lock-in',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.tertiary,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tenure Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Loan Tenure',
                          style: AppTypography.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          monthsRemainder == 0
                              ? '$years Years (${config.tenureMonths} Mo)'
                              : '$years Y $monthsRemainder M (${config.tenureMonths} Mo)',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => notifier.adjustTenureYears(-1),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.onSurfaceVariant,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.accentIndigo,
                            inactiveTrackColor: AppColors.surfaceContainerHighest,
                            thumbColor: AppColors.accentIndigo,
                            overlayColor: AppColors.accentIndigo.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: config.tenureMonths.toDouble().clamp(12.0, 360.0),
                            min: 12.0,
                            max: 360.0,
                            divisions: 29, // each step is 1 year
                            onChanged: (val) {
                              notifier.updateTenureMonths(val.round());
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => notifier.adjustTenureYears(1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Accelerated Payoff Strategy & Blueprint Presets (Stitch Design)
            const StrategyPresetSelector(),

            const SizedBox(height: 24),

            // Save / Proceed Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onSaved ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save & View Dashboard',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

