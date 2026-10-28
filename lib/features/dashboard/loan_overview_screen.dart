import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/indian_currency_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dual_tone_progress_bar.dart';
import '../../providers/loan_provider.dart';

class LoanOverviewScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToSimulator;
  final VoidCallback? onNavigateToSchedule;
  final VoidCallback? onNavigateToComparator;

  const LoanOverviewScreen({
    super.key,
    this.onNavigateToSimulator,
    this.onNavigateToSchedule,
    this.onNavigateToComparator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(loanConfigProvider);
    final result = ref.watch(amortizationResultProvider);

    // Current mock snapshot: Year 3 progress
    final int currentMonthIndex = 36.clamp(1, result.baseSchedule.length);
    final currentRow = result.baseSchedule.isNotEmpty
        ? result.baseSchedule[currentMonthIndex - 1]
        : null;

    final outstandingBalance =
        currentRow?.closingBalance ?? (config.principal * 0.85);
    final principalPaid = config.principal - outstandingBalance;
    final interestPaidSoFar = result.baseSchedule
        .take(currentMonthIndex)
        .fold(0.0, (sum, r) => sum + r.interestPaid);

    final progressPct = config.principal > 0
        ? ((principalPaid / config.principal) * 100).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      appBar: const AppHeader(
        title: 'LoanOpt',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          config.name,
                                          style: AppTypography.headlineSmall.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '•••• ${config.loanNumber}',
                                          style: AppTypography.labelSmall.copyWith(
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${config.loanType.displayName} • ${config.rateType.displayName}',
                                    style: AppTypography.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.tertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Outstanding Balance
                  Text(
                    'OUTSTANDING BALANCE',
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
                        IndianCurrencyFormatter.format(outstandingBalance),
                        style: AppTypography.metricCurrency.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_down,
                            size: 14,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '-${progressPct.toStringAsFixed(1)}%',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3 Specs Grid
                  Row(
                    children: [
                      _buildSpecItem(
                        'Sanctioned',
                        IndianCurrencyFormatter.formatCompact(config.principal),
                      ),
                      const SizedBox(width: 8),
                      _buildSpecItem(
                        'Interest Rate',
                        '${config.annualInterestRate.toStringAsFixed(2)}% p.a.',
                      ),
                      const SizedBox(width: 8),
                      _buildSpecItem(
                        'Tenure',
                        '${config.tenureMonths} Mo',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // EMI Due Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upcoming EMI (Auto-Debit)',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      IndianCurrencyFormatter.format(result.baseMonthlyEmi),
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Due in 6 days',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onErrorContainer,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '5th Next Month',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
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

            const SizedBox(height: 20),

            // Debt Decay Trajectory Card
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Debt Decay Trajectory',
                              style: AppTypography.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Amortization progress • Year ${(currentMonthIndex ~/ 12) + 1} of ${config.tenureMonths ~/ 12}',
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.query_stats,
                              size: 14,
                              color: AppColors.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${progressPct.toStringAsFixed(0)}% Paid',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Split Dual-Tone Progress Visualizer
                  DualToneProgressBar(
                    principalPaid: principalPaid,
                    interestPaid: interestPaidSoFar,
                    height: 10,
                  ),

                  const SizedBox(height: 18),

                  // Trajectory Chart using fl_chart
                  SizedBox(
                    height: 160,
                    child: _buildTrajectoryChart(result.baseSchedule),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Quick Links
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Simulator',
                    subtitle: 'Save Lakhs early',
                    icon: Icons.bolt,
                    iconColor: AppColors.tertiary,
                    onTap: onNavigateToSimulator ?? () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionCard(
                    title: 'Nifty 50 vs Loan',
                    subtitle: 'Opportunity cost',
                    icon: Icons.insights,
                    iconColor: AppColors.secondary,
                    onTap: onNavigateToComparator ?? () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              title: 'Full Amortization Schedule',
              subtitle: 'Yearly breakdown & PDF/CSV export',
              icon: Icons.calendar_month,
              iconColor: AppColors.primary,
              onTap: onNavigateToSchedule ?? () {},
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrajectoryChart(List<dynamic> schedule) {
    if (schedule.isEmpty) return const SizedBox();

    final spots = <FlSpot>[];
    final step = (schedule.length / 20).ceil();
    for (int i = 0; i < schedule.length; i += step) {
      final row = schedule[i];
      spots.add(FlSpot((i / 12).toDouble(), row.closingBalance / 100000));
    }
    final lastRow = schedule.last;
    spots.add(FlSpot((schedule.length / 12).toDouble(), lastRow.closingBalance / 100000));

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.surfaceContainerHigh,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipBorder: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipMargin: 12,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final year = spot.x.round();
                final balanceLakhs = spot.y;
                final balanceFormatted = balanceLakhs >= 100
                    ? '₹${(balanceLakhs / 100).toStringAsFixed(2)} Cr'
                    : '₹${balanceLakhs.toStringAsFixed(2)} L';

                return LineTooltipItem(
                  'Year $year\n',
                  const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: balanceFormatted,
                      style: const TextStyle(
                        color: AppColors.tertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: AppColors.tertiary.withValues(alpha: 0.5),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.tertiary,
                    strokeWidth: 2,
                    strokeColor: AppColors.surface,
                  ),
                ),
              );
            }).toList();
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.borderSubtle,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (val, meta) => Text(
                '₹${val.toInt()}L',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (val, meta) => Text(
                'Y${val.toInt()}',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF818CF8), // Vibrant Indigo
                AppColors.secondary, // Crisp Lavender
              ],
            ),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF818CF8).withValues(alpha: 0.25),
                  const Color(0xFF818CF8).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

