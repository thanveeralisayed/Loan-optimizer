import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../../models/amortization_schedule.dart';
import '../../../models/loan_config.dart';
import '../../../models/prepayment_plan.dart';
import '../../../providers/loan_provider.dart';
import '../../../services/loan_calculator_engine.dart';
import 'save_strategy_dialog.dart';

enum StrategyTab {
  system,
  saved,
}

class StrategyPresetSelector extends ConsumerStatefulWidget {
  final VoidCallback? onStrategyChanged;

  const StrategyPresetSelector({
    super.key,
    this.onStrategyChanged,
  });

  @override
  ConsumerState<StrategyPresetSelector> createState() =>
      _StrategyPresetSelectorState();
}

class _StrategyPresetSelectorState
    extends ConsumerState<StrategyPresetSelector> {
  StrategyTab _currentTab = StrategyTab.system;

  @override
  Widget build(BuildContext context) {
    final loanConfig = ref.watch(loanConfigProvider);
    final currentPlan = ref.watch(prepaymentPlanProvider);
    final activeId = ref.watch(activeBlueprintIdProvider);
    final savedStrategies = ref.watch(savedStrategiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Accelerated Payoff Strategy',
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.bolt,
                        color: AppColors.tertiary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select an automated pre-payment roadmap',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // + Save Custom Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final savedName = await SaveStrategyDialog.show(context);
                  if (savedName != null && mounted) {
                    setState(() {
                      _currentTab = StrategyTab.saved;
                    });
                    widget.onStrategyChanged?.call();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Blueprint "$savedName" saved!'),
                        backgroundColor: AppColors.surfaceContainerHighest,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle,
                        color: AppColors.tertiary,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+ Save Custom',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Segmented Switcher: System Presets vs My Saved
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
                child: _buildTabButton(
                  title: 'System Presets',
                  icon: Icons.auto_awesome,
                  isActive: _currentTab == StrategyTab.system,
                  onTap: () {
                    setState(() {
                      _currentTab = StrategyTab.system;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTabButton(
                  title: 'My Saved (${savedStrategies.length})',
                  icon: Icons.bookmark,
                  isActive: _currentTab == StrategyTab.saved,
                  onTap: () {
                    setState(() {
                      _currentTab = StrategyTab.saved;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Content
        if (_currentTab == StrategyTab.system)
          _buildSystemPresets(loanConfig, currentPlan, activeId)
        else
          _buildSavedBlueprints(loanConfig, currentPlan, activeId, savedStrategies),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.surfaceContainerHigh
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.tertiary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemPresets(
    LoanConfig loanConfig,
    PrepaymentPlan currentPlan,
    String? activeId,
  ) {
    final systemPresets = StrategyBlueprint.systemPresets();

    return Column(
      children: systemPresets.map((preset) {
        final isSelected = activeId == preset.id;
        final result = LoanCalculatorEngine.calculate(
          config: loanConfig,
          plan: preset.plan,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildPresetCard(
            preset: preset,
            isSelected: isSelected,
            result: result,
            onTap: () {
              ref
                  .read(prepaymentPlanProvider.notifier)
                  .applyPlan(preset.plan);
              ref
                  .read(activeBlueprintIdProvider.notifier)
                  .setActive(preset.id);
              widget.onStrategyChanged?.call();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPresetCard({
    required StrategyBlueprint preset,
    required bool isSelected,
    required LoanAmortizationResult result,
    required VoidCallback onTap,
  }) {
    final emoji = _getPresetEmoji(preset.iconKey);
    final yearsDrop = (result.monthsSaved / 12).toStringAsFixed(1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.tertiary.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
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
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preset.name,
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.tertiary
                        : AppColors.surfaceContainerHighest,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.onTertiary,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              preset.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (preset.plan.strategyMode == StrategyMode.reduceTenure) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timelapse,
                        size: 14,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Drops $yearsDrop Yrs',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.savings,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Save ${IndianCurrencyFormatter.formatCompact(result.totalInterestSaved)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_down,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reduces EMI',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Steady Tenure',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedBlueprints(
    LoanConfig loanConfig,
    PrepaymentPlan currentPlan,
    String? activeId,
    List<StrategyBlueprint> savedList,
  ) {
    if (savedList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 32,
              color: AppColors.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No Saved Blueprints Yet',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customize your accelerators and save them here.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final savedName = await SaveStrategyDialog.show(context);
                if (savedName != null && mounted) {
                  widget.onStrategyChanged?.call();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Blueprint "$savedName" saved!'),
                      backgroundColor: AppColors.surfaceContainerHighest,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Save Current Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.folder_special,
                  size: 16,
                  color: AppColors.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Saved Custom Blueprints',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${savedList.length} Saved',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Tap to review',
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: savedList.map((blueprint) {
            final isApplied = activeId == blueprint.id;
            final result = LoanCalculatorEngine.calculate(
              config: loanConfig,
              plan: blueprint.plan,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSavedBlueprintCard(
                blueprint: blueprint,
                isApplied: isApplied,
                result: result,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSavedBlueprintCard({
    required StrategyBlueprint blueprint,
    required bool isApplied,
    required LoanAmortizationResult result,
  }) {
    final yearsDrop = (result.monthsSaved / 12).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApplied
              ? AppColors.tertiary.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
          width: isApplied ? 1.5 : 1,
        ),
        boxShadow: isApplied
            ? [
                BoxShadow(
                  color: AppColors.tertiary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Title + Tags
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 18,
                  color: AppColors.tertiary,
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
                            blueprint.name,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CUSTOM',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.tertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blueprint.description,
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                blueprint.versionTag,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metrics row
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timelapse,
                    size: 13,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '-$yearsDrop Yrs',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.savings,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Save ${IndianCurrencyFormatter.formatCompact(result.totalInterestSaved)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_repeat,
                    size: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    blueprint.plan.strategyMode == StrategyMode.reduceTenure
                        ? 'Tenure Cut'
                        : 'EMI Relief',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 8),

          // Action buttons: Apply Blueprint | Rename | Delete
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(prepaymentPlanProvider.notifier)
                        .applyPlan(blueprint.plan);
                    ref
                        .read(activeBlueprintIdProvider.notifier)
                        .setActive(blueprint.id);
                    widget.onStrategyChanged?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Applied "${blueprint.name}" blueprint!'),
                        backgroundColor: AppColors.surfaceContainerHighest,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    isApplied ? Icons.check : Icons.check_circle_outline,
                    size: 15,
                  ),
                  label: Text(
                    isApplied ? 'Applied' : 'Apply Blueprint',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApplied
                        ? AppColors.tertiaryContainer
                        : AppColors.secondaryContainer,
                    foregroundColor: isApplied
                        ? AppColors.onTertiaryContainer
                        : AppColors.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Rename',
                onPressed: () => _showRenameDialog(blueprint),
                icon: const Icon(Icons.edit, size: 16),
                color: AppColors.onSurfaceVariant,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Delete',
                onPressed: () {
                  ref
                      .read(savedStrategiesProvider.notifier)
                      .deleteStrategy(blueprint.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted "${blueprint.name}"'),
                      backgroundColor: AppColors.surfaceContainerHighest,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                color: AppColors.error,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(StrategyBlueprint blueprint) {
    final controller = TextEditingController(text: blueprint.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(
          'Rename Blueprint',
          style: AppTypography.headlineSmall,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
          decoration: const InputDecoration(
            hintText: 'Blueprint name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(savedStrategiesProvider.notifier).updateStrategy(
                      id: blueprint.id,
                      name: newName,
                    );
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentIndigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getPresetEmoji(String iconKey) {
    switch (iconKey) {
      case 'rocket':
        return '🚀';
      case 'scale':
        return '⚖️';
      case 'shield':
        return '🛡️';
      case 'savings':
        return '💰';
      default:
        return '📈';
    }
  }
}
