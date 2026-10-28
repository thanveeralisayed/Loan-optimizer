import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? rateTag;
  final String? subtitle;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    this.title = 'LoanOpt',
    this.rateTag,
    this.subtitle,
    this.showLogo = true,
    this.actions,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
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
                        onPressed: onNotificationsTap ?? () {},
                        icon: const Icon(
                          Icons.notifications_none,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        tooltip: 'Notifications',
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onProfileTap ?? () {},
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceContainerHigh,
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
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
}
