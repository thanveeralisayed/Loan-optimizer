import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/indian_currency_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/currency_input_field.dart';
import '../../core/widgets/quick_amount_chip.dart';
import '../../core/widgets/segmented_control_pill.dart';
import '../../models/amortization_schedule.dart';
import '../../models/loan_config.dart';
import '../../models/prepayment_plan.dart';
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
    final result = ref.watch(amortizationResultProvider);
    final activeId = ref.watch(activeBlueprintIdProvider);
    final savedStrategies = ref.watch(savedStrategiesProvider);
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

            const SizedBox(height: 16),

            // Real-Time Strategy Impact Preview Card
            _buildLiveImpactPreviewCard(
              result: result,
              activeId: activeId,
              savedList: savedStrategies,
            ),

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

  Widget _buildLiveImpactPreviewCard({
    required LoanAmortizationResult result,
    required String? activeId,
    required List<StrategyBlueprint> savedList,
  }) {
    String activeName = 'Aggressive Freedom';
    final systemPresets = StrategyBlueprint.systemPresets();
    final sysMatch = systemPresets.where((p) => p.id == activeId);
    if (sysMatch.isNotEmpty) {
      activeName = sysMatch.first.name;
    } else {
      final customMatch = savedList.where((b) => b.id == activeId);
      if (customMatch.isNotEmpty) {
        activeName = customMatch.first.name;
      }
    }

    final yearsSaved = (result.monthsSaved / 12).toStringAsFixed(1);
    final endYearStandard =
        DateFormat('MMM yyyy').format(result.originalEndDate);
    final endYearOptimized =
        DateFormat('MMM yyyy').format(result.optimizedEndDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_graph,
                size: 15,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'REAL-TIME STRATEGY IMPACT',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activeName,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildImpactChip(
                icon: Icons.savings,
                label: 'Interest Saved',
                value:
                    'Save ${IndianCurrencyFormatter.formatCompact(result.totalInterestSaved)}',
                color: AppColors.tertiary,
              ),
              _buildImpactChip(
                icon: Icons.timelapse,
                label: 'Tenure Cut',
                value: result.monthsSaved > 0 ? '-$yearsSaved Yrs' : '0 Yrs',
                color: AppColors.primary,
              ),
              _buildImpactChip(
                icon: Icons.event_available,
                label: 'Debt-Free',
                value: endYearOptimized,
                color: AppColors.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.monthsSaved > 0
                ? 'Standard payoff was $endYearStandard • Applying this strategy finishes loan $yearsSaved years earlier.'
                : 'Baseline schedule completes by $endYearStandard without extra prepayments.',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 9,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

