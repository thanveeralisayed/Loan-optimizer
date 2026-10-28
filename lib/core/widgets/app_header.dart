import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? rateTag;
  final String subtitle;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    this.title = 'LoanOpt',
    this.rateTag = '8.50% Floating',
    this.subtitle = 'Dashboard',
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Logo & Title
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 16,
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (rateTag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rateTag!,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.tertiary,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Right: Actions
            Row(
              children: [
                IconButton(
                  onPressed: onNotificationsTap ?? () {},
                  icon: const Icon(
                    Icons.notifications_none,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  splashRadius: 20,
                  tooltip: 'Notifications',
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onProfileTap ?? () {},
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerHigh,
                      border: Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 18,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

