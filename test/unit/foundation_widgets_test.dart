import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/theme/app_colors.dart';
import 'package:loan_optimizer/core/theme/app_theme.dart';
import 'package:loan_optimizer/core/widgets/app_header.dart';
import 'package:loan_optimizer/core/widgets/dual_tone_progress_bar.dart';
import 'package:loan_optimizer/core/widgets/metric_tile.dart';
import 'package:loan_optimizer/core/widgets/quick_amount_chip.dart';
import 'package:loan_optimizer/core/widgets/segmented_control_pill.dart';
import 'package:loan_optimizer/core/widgets/sticky_bottom_dock.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('Foundation Widgets Tests', () {
    testWidgets('AppHeader displays title and rate tag', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const AppHeader(
          title: 'LoanOpt',
          rateTag: '8.50% Floating',
          subtitle: 'Dashboard',
        ),
      ));

      expect(find.text('LoanOpt'), findsOneWidget);
      expect(find.text('8.50% Floating'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('AppHeader notifications button opens notifications sheet by default',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const AppHeader(title: 'LoanOpt'),
      ));

      // Notification icon is present
      final notifFinder = find.byIcon(Icons.notifications_none);
      expect(notifFinder, findsOneWidget);

      // Tap notification bell
      await tester.tap(notifFinder);
      await tester.pumpAndSettle();

      // BottomSheet is displayed with alerts
      expect(find.text('Notifications & Alerts'), findsOneWidget);
      expect(find.text('Upcoming EMI (₹43,391)'), findsOneWidget);
      expect(find.text('Accelerate Debt Freedom'), findsOneWidget);
      expect(find.text('RBI Repo Rate Policy'), findsOneWidget);

      // Dismiss the sheet
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications & Alerts'), findsNothing);
    });

    testWidgets('AppHeader profile button opens profile sheet by default',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const AppHeader(title: 'LoanOpt'),
      ));

      // Profile icon is present
      final profileFinder = find.byIcon(Icons.person);
      expect(profileFinder, findsOneWidget);

      // Tap profile icon
      await tester.tap(profileFinder);
      await tester.pumpAndSettle();

      // Profile bottom sheet is displayed
      expect(find.text('Arjun Sharma'), findsOneWidget);
      expect(find.text('Active Facility'), findsOneWidget);
      expect(find.text('₹50,00,000'), findsOneWidget);
      expect(find.textContaining('100% Offline Engine'), findsOneWidget);

      // Close the sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Arjun Sharma'), findsNothing);
    });

    testWidgets('AppHeader invokes custom callbacks when provided',
        (tester) async {
      var notifTapped = false;
      var profileTapped = false;

      await tester.pumpWidget(wrapWidget(
        AppHeader(
          title: 'LoanOpt',
          onNotificationsTap: () => notifTapped = true,
          onProfileTap: () => profileTapped = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pump();
      expect(notifTapped, isTrue);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pump();
      expect(profileTapped, isTrue);
    });

    testWidgets('DualToneProgressBar renders principal and interest properly',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const DualToneProgressBar(
          principalPaid: 734600,
          interestPaid: 568200,
        ),
      ));

      expect(find.text('Principal: '), findsOneWidget);
      expect(find.text('Interest: '), findsOneWidget);
      expect(find.text('₹7,34,600'), findsOneWidget);
      expect(find.text('₹5,68,200'), findsOneWidget);
    });

    testWidgets('SegmentedControlPill allows selection and shows badges',
        (tester) async {
      String selected = 'tenure';
      await tester.pumpWidget(wrapWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return SegmentedControlPill<String>(
              options: const [
                SegmentOption(
                  value: 'tenure',
                  label: 'Reduce Tenure',
                  badge: 'OPTIMAL',
                ),
                SegmentOption(
                  value: 'emi',
                  label: 'Reduce Monthly EMI',
                ),
              ],
              selectedValue: selected,
              onSelected: (val) {
                setState(() => selected = val);
              },
            );
          },
        ),
      ));

      expect(find.text('Reduce Tenure'), findsOneWidget);
      expect(find.text('OPTIMAL'), findsOneWidget);
      expect(find.text('Reduce Monthly EMI'), findsOneWidget);

      await tester.tap(find.text('Reduce Monthly EMI'));
      await tester.pumpAndSettle();
      expect(selected, 'emi');
    });

    testWidgets('MetricTile displays value, label and variance delta badge',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const MetricTile(
          label: 'Projected Savings',
          value: '₹14,86,500',
          deltaBadge: '+27.4% Off',
          subtitle: 'Lifetime interest reduction',
        ),
      ));

      expect(find.text('PROJECTED SAVINGS'), findsOneWidget);
      expect(find.text('₹14,86,500'), findsOneWidget);
      expect(find.text('+27.4% Off'), findsOneWidget);
      expect(find.text('Lifetime interest reduction'), findsOneWidget);
    });

    testWidgets('QuickAmountChip fires tap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(wrapWidget(
        Row(
          children: [
            QuickAmountChip(
              label: '+ ₹5L',
              onTap: () => tapped = true,
            ),
          ],
        ),
      ));

      expect(find.text('+ ₹5L'), findsOneWidget);
      await tester.tap(find.text('+ ₹5L'));
      expect(tapped, isTrue);
    });

    testWidgets('StickyBottomDock renders summary and triggers button tap',
        (tester) async {
      bool tapped = false;
      await tester.pumpWidget(wrapWidget(
        StickyBottomDock(
          label: 'Impact Summary',
          value: 'Saves 64 Months',
          buttonText: 'Apply Strategy',
          onButtonPressed: () => tapped = true,
        ),
      ));

      expect(find.text('IMPACT SUMMARY'), findsOneWidget);
      expect(find.text('Saves 64 Months'), findsOneWidget);
      expect(find.text('Apply Strategy'), findsOneWidget);

      await tester.tap(find.text('Apply Strategy'));
      expect(tapped, isTrue);
    });

    test('AppColors verifies deep obsidian values', () {
      expect(AppColors.background, const Color(0xFF0D1320));
      expect(AppColors.tertiary, const Color(0xFF4EDEA3));
      expect(AppColors.accentIndigo, const Color(0xFF4F46E5));
    });
  });
}

