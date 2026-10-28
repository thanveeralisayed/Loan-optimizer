import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../../models/amortization_schedule.dart';
import '../../../models/prepayment_plan.dart';
import '../../../providers/loan_provider.dart';
import '../../../services/loan_calculator_engine.dart';
import 'save_strategy_dialog.dart';

class SavedStrategyCarousel extends ConsumerWidget {
  final VoidCallback? onStrategyLoaded;

  const SavedStrategyCarousel({
    super.key,
    this.onStrategyLoaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedStrategies = ref.watch(savedStrategiesProvider);
    final activeId = ref.watch(activeBlueprintIdProvider);
    final currentPlan = ref.watch(prepaymentPlanProvider);
    final loanConfig = ref.watch(loanConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.bookmarks,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Saved Strategies',
                      style: AppTypography.headlineSmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${savedStrategies.length} Available',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
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
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Save New',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.tertiary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Carousel
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: savedStrategies.length + 1,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == savedStrategies.length) {
                // "+ New Strategy" dashed card
                return _buildAddStrategyCard(context, ref);
              }

              final blueprint = savedStrategies[index];
              final isApplied = activeId == blueprint.id ||
                  _isPlanMatching(currentPlan, blueprint.plan);
              final result = LoanCalculatorEngine.calculate(
                config: loanConfig,
                plan: blueprint.plan,
              );

              return _buildStrategyCard(
                context: context,
                ref: ref,
                blueprint: blueprint,
                isApplied: isApplied,
                result: result,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyCard({
    required BuildContext context,
    required WidgetRef ref,
    required StrategyBlueprint blueprint,
    required bool isApplied,
    required LoanAmortizationResult result,
  }) {
    final yearsDrop = (result.monthsSaved / 12).toStringAsFixed(1);

    return InkWell(
      onTap: () {
        ref.read(prepaymentPlanProvider.notifier).applyPlan(blueprint.plan);
        ref
            .read(activeBlueprintIdProvider.notifier)
            .setActive(blueprint.id);
        onStrategyLoaded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded strategy "${blueprint.name}"'),
            backgroundColor: AppColors.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 256,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isApplied
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isApplied
                ? AppColors.tertiary.withValues(alpha: 0.6)
                : AppColors.borderSubtle,
            width: isApplied ? 1.5 : 1,
          ),
          boxShadow: isApplied
              ? [
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    blueprint.name,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                if (isApplied)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Applied',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.tertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Load',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Middle Stats Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAVINGS',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.outline,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        IndianCurrencyFormatter.formatCompact(
                            result.totalInterestSaved),
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TENURE CUT',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.outline,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '-$yearsDrop Yrs',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom Description Pill
            Container(
              padding: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isApplied ? Icons.check : Icons.schedule,
                    size: 11,
                    color: isApplied ? AppColors.tertiary : AppColors.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      blueprint.description,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStrategyCard(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 18,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '+ New Strategy',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Save current',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPlanMatching(PrepaymentPlan a, PrepaymentPlan b) {
    if (a.steppedEmiPercentage != b.steppedEmiPercentage) return false;
    if (a.enableExtraAnnualEmi != b.enableExtraAnnualEmi) return false;
    if (a.strategyMode != b.strategyMode) return false;
    if (a.lumpSums.length != b.lumpSums.length) return false;
    for (int i = 0; i < a.lumpSums.length; i++) {
      if (a.lumpSums[i].amount != b.lumpSums[i].amount ||
          a.lumpSums[i].monthIndex != b.lumpSums[i].monthIndex) {
        return false;
      }
    }
    return true;
  }
}
