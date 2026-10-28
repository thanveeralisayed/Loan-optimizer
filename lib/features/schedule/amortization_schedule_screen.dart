import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/indian_currency_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/segmented_control_pill.dart';
import '../../models/amortization_schedule.dart';
import '../../providers/loan_provider.dart';
import '../../services/export_service.dart';

enum ScheduleViewMode {
  yearly,
  monthly;

  String get displayName {
    switch (this) {
      case ScheduleViewMode.yearly:
        return 'Yearly View (Summary)';
      case ScheduleViewMode.monthly:
        return 'Monthly Breakdown';
    }
  }
}

class AmortizationScheduleScreen extends ConsumerStatefulWidget {
  const AmortizationScheduleScreen({super.key});

  @override
  ConsumerState<AmortizationScheduleScreen> createState() =>
      _AmortizationScheduleScreenState();
}

class _AmortizationScheduleScreenState
    extends ConsumerState<AmortizationScheduleScreen> {
  ScheduleViewMode _viewMode = ScheduleViewMode.yearly;
  final Set<int> _expandedYears = {1}; // Expand year 1 by default

  void _exportCsv(LoanAmortizationResult result) {
    ExportService.generateCsv(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        content: Text(
          'CSV Generated (${result.optimizedSchedule.length} rows ready for export)',
          style: const TextStyle(color: AppColors.onSurface),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportPdf(LoanAmortizationResult result) async {
    final config = ref.read(loanConfigProvider);
    final pdfBytes = await ExportService.generatePdf(
      config: config,
      result: result,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        content: Text(
          'PDF Statement Generated (${(pdfBytes.length / 1024).toStringAsFixed(1)} KB)',
          style: const TextStyle(color: AppColors.onSurface),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(loanConfigProvider);
    final result = ref.watch(amortizationResultProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Amortization Schedule',
        subtitle:
            '${config.tenureMonths ~/ 12}-Year Term • ${config.rateType.displayName} ${config.annualInterestRate.toStringAsFixed(2)}%',
        showLogo: false,
        actions: [
          _buildExportPill(
            label: 'CSV',
            icon: Icons.table_chart_outlined,
            onTap: () => _exportCsv(result),
          ),
          const SizedBox(width: 6),
          _buildExportPill(
            label: 'PDF',
            icon: Icons.picture_as_pdf_outlined,
            onTap: () => _exportPdf(result),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Tab Bar (Yearly vs Monthly)
            SegmentedControlPill<ScheduleViewMode>(
              options: const [
                SegmentOption(
                  value: ScheduleViewMode.yearly,
                  label: 'Yearly View (Summary)',
                ),
                SegmentOption(
                  value: ScheduleViewMode.monthly,
                  label: 'Monthly Breakdown',
                ),
              ],
              selectedValue: _viewMode,
              onSelected: (mode) => setState(() => _viewMode = mode),
            ),

            const SizedBox(height: 16),

            // Loan Lifecycle Snapshot Card
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
                      Row(
                        children: [
                          const Icon(
                            Icons.timelapse,
                            size: 16,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIFECYCLE JOURNEY',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${result.optimizedTenureMonths} Months (${result.monthsSaved} Saved)',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Macro Metrics 3-Col Array
                  Row(
                    children: [
                      _buildSummaryItem(
                        'Principal',
                        IndianCurrencyFormatter.formatCompact(result.totalPrincipal),
                        AppColors.onSurface,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryItem(
                        'Total Interest',
                        IndianCurrencyFormatter.formatCompact(
                            result.optimizedTotalInterest),
                        AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryItem(
                        'Total Outflow',
                        IndianCurrencyFormatter.formatCompact(
                            result.optimizedTotalOutflow),
                        AppColors.tertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Schedule Trajectory Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedule Trajectory',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _viewMode == ScheduleViewMode.yearly
                      ? 'Tap row to expand months'
                      : '${result.optimizedSchedule.length} Payments',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Schedule View: Yearly Accordion or Monthly List
            if (_viewMode == ScheduleViewMode.yearly)
              ...result.yearlySummaries.map((yearSummary) {
                final isExpanded = _expandedYears.contains(yearSummary.yearIndex);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedYears.remove(yearSummary.yearIndex);
                            } else {
                              _expandedYears.add(yearSummary.yearIndex);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      yearSummary.isCompleted
                                          ? Icons.check_circle
                                          : Icons.schedule,
                                      size: 16,
                                      color: yearSummary.isCompleted
                                          ? AppColors.tertiary
                                          : AppColors.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Year ${yearSummary.yearIndex}',
                                            style: AppTypography.headlineSmall
                                                .copyWith(fontSize: 16),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(${yearSummary.yearNumber})',
                                            style: AppTypography.labelSmall,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Principal: ${IndianCurrencyFormatter.formatCompact(yearSummary.totalPrincipalPaid)} • Int: ${IndianCurrencyFormatter.formatCompact(yearSummary.totalInterestPaid)}',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Closing Balance',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 9,
                                        ),
                                      ),
                                      Text(
                                        IndianCurrencyFormatter.formatCompact(
                                            yearSummary.closingBalance),
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: AppColors.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1, color: AppColors.borderSubtle),
                        Container(
                          color: AppColors.surfaceContainerLowest,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            children: [
                              // Fixed column header
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6, top: 2),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 82,
                                      child: Text(
                                        'MONTH',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 9,
                                          letterSpacing: 0.8,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          'EMI PAYMENT',
                                          style: AppTypography.labelSmall.copyWith(
                                            fontSize: 9,
                                            letterSpacing: 0.8,
                                            color: AppColors.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'BALANCE',
                                        textAlign: TextAlign.right,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 9,
                                          letterSpacing: 0.8,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...yearSummary.monthlyRows.map((row) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 82,
                                        child: Text(
                                          'M${row.monthIndex} (${DateFormat('MMM').format(row.date)})',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            'EMI: ${IndianCurrencyFormatter.format(row.emi)}',
                                            style: AppTypography.bodySmall.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          'Bal: ${IndianCurrencyFormatter.formatCompact(row.closingBalance)}',
                                          textAlign: TextAlign.right,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              })
            else
              // Monthly Breakdown Virtualized Table
              ...result.optimizedSchedule.map((row) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Month ${row.monthIndex}',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              DateFormat('MMM yyyy').format(row.date),
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Principal: ${IndianCurrencyFormatter.format(row.principalPaid)}',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.tertiary,
                              ),
                            ),
                            Text(
                              'Interest: ${IndianCurrencyFormatter.format(row.interestPaid)}',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Balance',
                              style: AppTypography.labelSmall.copyWith(fontSize: 9),
                            ),
                            Text(
                              IndianCurrencyFormatter.formatCompact(row.closingBalance),
                              textAlign: TextAlign.right,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExportPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.onSurface),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.headlineSmall.copyWith(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
