import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/loan_config.dart';
import '../../providers/loan_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/indian_currency_formatter.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String? rateTag;
  final String? subtitle;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onNotificationsTap;
  final double? upcomingEmi;

  const AppHeader({
    super.key,
    this.title = 'LoanOpt',
    this.rateTag,
    this.subtitle,
    this.showLogo = true,
    this.actions,
    this.onNotificationsTap,
    this.upcomingEmi,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(amortizationResultProvider);
    final config = ref.watch(loanConfigProvider);
    final emiValue = upcomingEmi ?? result.baseMonthlyEmi;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Logo & Title
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showLogo) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontSize: 16,
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (rateTag != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      rateTag!,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.tertiary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (subtitle != null) ...[
                              Text(
                                subtitle!,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 10,
                                  letterSpacing: 0.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right: Actions
                if (actions != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onNotificationsTap ??
                            () => _showNotificationsSheet(
                                  context,
                                  emiValue,
                                  config,
                                ),
                        icon: const Icon(
                          Icons.notifications_none,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        tooltip: 'Notifications',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(
    BuildContext context,
    double emiAmount,
    LoanConfig config,
  ) {
    final formattedEmi = IndianCurrencyFormatter.format(emiAmount);
    final formattedRate = config.annualInterestRate.toStringAsFixed(2);
    final rateTypeLabel =
        config.rateType == RateType.floating ? 'floating' : 'fixed';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.borderLight, width: 1),
              left: BorderSide(color: AppColors.borderLight, width: 1),
              right: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.tertiary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Notifications & Alerts',
                            style: AppTypography.headlineSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.tertiary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '3 New',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationCard(
                    icon: Icons.event_available_rounded,
                    iconColor: AppColors.primary,
                    title: 'Upcoming EMI ($formattedEmi)',
                    subtitle:
                        'Scheduled for auto-debit on 5th next month from primary bank account.',
                    tag: 'Due in 6 days',
                    tagColor: AppColors.errorCoral,
                  ),
                  const SizedBox(height: 10),
                  _buildNotificationCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.tertiary,
                    title: 'Accelerate Debt Freedom',
                    subtitle:
                        'A bonus prepayment this quarter will save substantial lifetime interest and reduce years off your loan.',
                    tag: 'Opportunity',
                    tagColor: AppColors.tertiary,
                  ),
                  const SizedBox(height: 10),
                  _buildNotificationCard(
                    icon: Icons.account_balance_outlined,
                    iconColor: AppColors.secondary,
                    title: 'RBI Repo Rate Policy',
                    subtitle:
                        'Monetary Policy Committee held the benchmark repo rate at 6.50%. Your $rateTypeLabel loan facility is currently modeled at $formattedRate% p.a.',
                    tag: 'Macro Update',
                    tagColor: AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Dismiss',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.labelSmall.copyWith(
                          color: tagColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
