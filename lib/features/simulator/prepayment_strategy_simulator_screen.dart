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
import '../../core/widgets/sticky_bottom_dock.dart';
import '../../models/prepayment_plan.dart';
import '../../providers/loan_provider.dart';
import '../strategy/widgets/save_strategy_dialog.dart';
import '../strategy/widgets/saved_strategy_carousel.dart';

class PrepaymentStrategySimulatorScreen extends ConsumerStatefulWidget {
  final VoidCallback? onApply;

  const PrepaymentStrategySimulatorScreen({super.key, this.onApply});

  @override
  ConsumerState<PrepaymentStrategySimulatorScreen> createState() =>
      _PrepaymentStrategySimulatorScreenState();
}

class _PrepaymentStrategySimulatorScreenState
    extends ConsumerState<PrepaymentStrategySimulatorScreen> {
  late TextEditingController _lumpSumController;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(prepaymentPlanProvider);
    final lumpSum = plan.lumpSums.isNotEmpty ? plan.lumpSums.first.amount : 0.0;
    _lumpSumController = TextEditingController(
      text: lumpSum > 0 ? IndianCurrencyFormatter.formatWithoutSymbol(lumpSum) : '',
    );
  }

  @override
  void dispose() {
    _lumpSumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(prepaymentPlanProvider);
    final planNotifier = ref.read(prepaymentPlanProvider.notifier);
    final result = ref.watch(amortizationResultProvider);

    final originalEndFormat = DateFormat('MMM yyyy').format(result.originalEndDate);
    final optimizedEndFormat = DateFormat('MMM yyyy').format(result.optimizedEndDate);

    final yearsSaved = result.monthsSaved ~/ 12;
    final monthsRemainder = result.monthsSaved % 12;
    final tenureSavedText = yearsSaved > 0
        ? '${yearsSaved}y ${monthsRemainder}m'
        : '${monthsRemainder}m';

    final double payoffPct = result.originalTenureMonths > 0
        ? ((result.optimizedTenureMonths / result.originalTenureMonths) * 100)
            .clamp(0.0, 100.0)
        : 100.0;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Prepayment Simulator',
        showLogo: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Impact Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub-header Pill Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.tertiary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'ALGORITHMIC OPTIMIZATION',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.tertiary,
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 14,
                                color: AppColors.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live Recalculation',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Highlight Stat: Projected Savings
                      Text(
                        'PROJECTED TOTAL SAVINGS',
                        style: AppTypography.labelSmall.copyWith(
                          letterSpacing: 0.8,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            IndianCurrencyFormatter.format(result.totalInterestSaved),
                            style: AppTypography.metricCurrency.copyWith(
                              color: AppColors.tertiary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${result.savingsPercentage.toStringAsFixed(1)}% Off Total Interest)',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Metric Split Tiles
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tenure Accelerated By',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.fast_forward,
                                        size: 16,
                                        color: AppColors.tertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          tenureSavedText,
                                          style: AppTypography.headlineSmall.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '-${result.monthsSaved} Months Early',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Freedom Milestone',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          optimizedEndFormat,
                                          style: AppTypography.headlineSmall.copyWith(
                                            fontSize: 18,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    originalEndFormat,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.outline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Payoff Trajectory Mini Graphic
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Payoff Trajectory',
                              style: AppTypography.labelSmall.copyWith(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${payoffPct.toStringAsFixed(1)}% of original time',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          color: AppColors.surfaceContainerLowest,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (payoffPct / 100.0).clamp(0.01, 1.0),
                            child: Container(color: AppColors.tertiary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Strategy Segmented Control (Reduce Tenure vs Reduce EMI)
                SegmentedControlPill<StrategyMode>(
                  options: const [
                    SegmentOption(
                      value: StrategyMode.reduceTenure,
                      label: 'Reduce Tenure',
                      icon: Icons.hourglass_bottom,
                      badge: 'OPTIMAL',
                    ),
                    SegmentOption(
                      value: StrategyMode.reduceEmi,
                      label: 'Reduce Monthly EMI',
                      icon: Icons.payments,
                    ),
                  ],
                  selectedValue: plan.strategyMode,
                  onSelected: (mode) => planNotifier.setStrategyMode(mode),
                ),

                const SizedBox(height: 10),

                // Micro insight advisory card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            children: const [
                              TextSpan(
                                text: 'Fintech Insight: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'Keeping EMI constant saves 4.2x more lifetime interest than cash-flow easing via lower monthly payments.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Saved Strategies Horizontal Carousel (Stitch Design)
                SavedStrategyCarousel(
                  onStrategyLoaded: () {
                    final current = ref.read(prepaymentPlanProvider);
                    final lump = current.lumpSums.isNotEmpty
                        ? current.lumpSums.first.amount
                        : 0.0;
                    _lumpSumController.text = lump > 0
                        ? IndianCurrencyFormatter.formatWithoutSymbol(lump)
                        : '';
                  },
                ),

                const SizedBox(height: 24),

                // Section Title: Active Accelerators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Active Accelerators',
                        style: AppTypography.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '3 Knobs Engaged',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Knob 1: One-Time Lump Sum Prepayment Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.savings,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('One-Time Lump Sum',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                                Text('Inject surplus liquidity (e.g. bonus)',
                                    style: AppTypography.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CurrencyInputField(
                        controller: _lumpSumController,
                        label: 'Prepayment Amount',
                        onChanged: (val) {
                          final parsed = IndianCurrencyFormatter.parse(val);
                          planNotifier.setLumpSumAmount(parsed, monthIndex: 12);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          QuickAmountChip(
                            label: '+ ₹1L',
                            onTap: () {
                              final current = IndianCurrencyFormatter.parse(
                                  _lumpSumController.text);
                              final updated = current + 100000;
                              planNotifier.setLumpSumAmount(updated,
                                  monthIndex: 12);
                              _lumpSumController.text =
                                  IndianCurrencyFormatter.formatWithoutSymbol(
                                      updated);
                            },
                          ),
                          const SizedBox(width: 8),
                          QuickAmountChip(
                            label: '+ ₹2.5L',
                            onTap: () {
                              final current = IndianCurrencyFormatter.parse(
                                  _lumpSumController.text);
                              final updated = current + 250000;
                              planNotifier.setLumpSumAmount(updated,
                                  monthIndex: 12);
                              _lumpSumController.text =
                                  IndianCurrencyFormatter.formatWithoutSymbol(
                                      updated);
                            },
                          ),
                          const SizedBox(width: 8),
                          QuickAmountChip(
                            label: '+ ₹5L',
                            onTap: () {
                              final current = IndianCurrencyFormatter.parse(
                                  _lumpSumController.text);
                              final updated = current + 500000;
                              planNotifier.setLumpSumAmount(updated,
                                  monthIndex: 12);
                              _lumpSumController.text =
                                  IndianCurrencyFormatter.formatWithoutSymbol(
                                      updated);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Knob 2: Stepped EMI Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.trending_up,
                                    color: AppColors.tertiary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Stepped EMI Step-up',
                                          style: AppTypography.labelLarge.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis),
                                      Text('Annual increase with salary hike',
                                          style: AppTypography.bodySmall,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${plan.steppedEmiPercentage.toStringAsFixed(0)}% / yr',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.tertiary,
                          inactiveTrackColor: AppColors.surfaceContainerHighest,
                          thumbColor: AppColors.tertiary,
                          overlayColor: AppColors.tertiary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: plan.steppedEmiPercentage,
                          min: 0.0,
                          max: 20.0,
                          divisions: 4, // 0%, 5%, 10%, 15%, 20%
                          label: '${plan.steppedEmiPercentage.toInt()}%',
                          onChanged: (val) {
                            planNotifier.setSteppedEmiPercentage(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Knob 3: 13th Annual EMI Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.event_repeat,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('13th Annual EMI Payoff',
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                            Text('Pay 1 additional EMI every December',
                                style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      Switch(
                        value: plan.enableExtraAnnualEmi,
                        activeThumbColor: AppColors.tertiary,
                        activeTrackColor: AppColors.tertiaryContainer,
                        inactiveThumbColor: AppColors.outline,
                        inactiveTrackColor: AppColors.surfaceContainerHighest,
                        onChanged: (val) {
                          planNotifier.toggleExtraAnnualEmi(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Save Current Strategy Action Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bookmark_add,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Save Current Strategy',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Save these accelerator settings to reuse anytime',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final name = await SaveStrategyDialog.show(context);
                          if (name != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Strategy "$name" saved!'),
                                backgroundColor: AppColors.surfaceContainerHighest,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.bookmark_add, size: 14),
                        label: const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Execution Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StickyBottomDock(
              label: 'Total Accelerated Impact',
              value:
                  'Saves ${result.monthsSaved} Mo (${IndianCurrencyFormatter.formatCompact(result.totalInterestSaved)})',
              buttonText: 'Apply Strategy',
              buttonIcon: Icons.check,
              onButtonPressed: widget.onApply ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}
