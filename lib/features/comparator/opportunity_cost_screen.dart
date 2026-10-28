import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/indian_currency_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../models/opportunity_cost_models.dart';
import '../../providers/loan_provider.dart';

class OpportunityCostScreen extends ConsumerWidget {
  const OpportunityCostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanConfig = ref.watch(loanConfigProvider);
    final params = ref.watch(opportunityCostParamsProvider);
    final paramsNotifier = ref.read(opportunityCostParamsProvider.notifier);
    final result = ref.watch(opportunityCostResultProvider);

    final horizonYears = params.horizonMonths ~/ 12;
    final isPrepayWinner = result.verdict == PrepayVerdict.prepayLoan;

    // Relative bar widths for comparative graphic
    final maxMetric = (result.loanInterestSaved > result.netInvestmentProfit
            ? result.loanInterestSaved
            : result.netInvestmentProfit)
        .clamp(1.0, double.infinity);
    final prepayWidthPct = (result.loanInterestSaved / maxMetric).clamp(0.05, 1.0);
    final investWidthPct = (result.netInvestmentProfit / maxMetric).clamp(0.05, 1.0);

    return Scaffold(
      appBar: AppHeader(
        title: 'LoanOpt',
        rateTag: '${loanConfig.annualInterestRate.toStringAsFixed(2)}% Floating',
        subtitle: 'Compare',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dilemma Intro Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'QUANT DECISION MATRIX',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Post-Tax Adjusted',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The Big Financial Dilemma: Prepay ${loanConfig.annualInterestRate.toStringAsFixed(1)}% Loan or Invest in Nifty 50?',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Capital Pool Pill
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Allocated Surplus Pool',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${IndianCurrencyFormatter.format(params.lumpSumSurplus)} + ${IndianCurrencyFormatter.format(params.monthlySipSurplus)}/mo',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$horizonYears-Yr Horizon',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Compounded',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.outline,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // The Algorithmic Verdict Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPrepayWinner
                      ? AppColors.tertiary.withValues(alpha: 0.3)
                      : AppColors.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isPrepayWinner
                                  ? AppColors.tertiary
                                  : AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MATHEMATICAL VERDICT',
                            style: AppTypography.labelSmall.copyWith(
                              color: isPrepayWinner
                                  ? AppColors.tertiary
                                  : AppColors.secondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Delta: +${result.alphaPercentage.toStringAsFixed(1)}% Alpha',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isPrepayWinner ? '🚀 ' : '📈 ',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                Flexible(
                                  child: Text(
                                    result.verdict.title,
                                    style: AppTypography.headlineMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '+${IndianCurrencyFormatter.format(result.netAdvantage)}',
                                  style: AppTypography.metricCurrency.copyWith(
                                    color: isPrepayWinner
                                        ? AppColors.tertiary
                                        : AppColors.secondary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Net True Advantage',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isPrepayWinner
                                        ? AppColors.tertiary
                                        : AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPrepayWinner
                              ? AppColors.tertiaryContainer
                              : AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPrepayWinner ? Icons.shield_outlined : Icons.trending_up,
                          color: isPrepayWinner
                              ? AppColors.tertiary
                              : AppColors.secondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.insights,
                          size: 16,
                          color: isPrepayWinner
                              ? AppColors.tertiary
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.explanation,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              height: 1.4,
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

            // Side-by-Side Visualizer Bar Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCENARIO BREAKDOWN',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 0.6,
                              color: AppColors.outline,
                            ),
                          ),
                          Text('Risk-Adjusted Value',
                              style: AppTypography.headlineSmall),
                        ],
                      ),
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
                          const SizedBox(width: 4),
                          Text('Loan Saved', style: AppTypography.labelSmall),
                          const SizedBox(width: 10),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Post-Tax MF', style: AppTypography.labelSmall),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Option A: Guaranteed Savings
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Option A: Guaranteed Savings',
                                style: AppTypography.labelMedium),
                            Text(
                              IndianCurrencyFormatter.format(result.loanInterestSaved),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 8,
                            width: double.infinity,
                            color: AppColors.surfaceContainerHigh,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: prepayWidthPct,
                              child: Container(color: AppColors.tertiary),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Option B: Post-Tax Equity Corpus
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Option B: Post-Tax Equity Profit',
                                style: AppTypography.labelMedium),
                            Text(
                              IndianCurrencyFormatter.format(
                                  result.netInvestmentProfit),
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 8,
                            width: double.infinity,
                            color: AppColors.surfaceContainerHigh,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: investWidthPct,
                              child: Container(color: AppColors.secondary),
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

            // Interactive Assumption Sliders
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Expected Market Return',
                          style: AppTypography.labelLarge),
                      Text(
                        '${params.expectedAnnualReturn.toStringAsFixed(1)}% CAGR',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.secondary,
                      inactiveTrackColor: AppColors.surfaceContainerHighest,
                      thumbColor: AppColors.secondary,
                    ),
                    child: Slider(
                      value: params.expectedAnnualReturn,
                      min: 8.0,
                      max: 20.0,
                      divisions: 12,
                      onChanged: (val) {
                        paramsNotifier.updateExpectedReturn(val);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Investment Horizon',
                          style: AppTypography.labelLarge),
                      Text(
                        '$horizonYears Years (${params.horizonMonths} Months)',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.tertiary,
                      inactiveTrackColor: AppColors.surfaceContainerHighest,
                      thumbColor: AppColors.tertiary,
                    ),
                    child: Slider(
                      value: params.horizonMonths.toDouble(),
                      min: 12.0,
                      max: 240.0,
                      divisions: 19,
                      onChanged: (val) {
                        paramsNotifier.updateHorizonMonths(val.round());
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
