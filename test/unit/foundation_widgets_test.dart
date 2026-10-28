import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/theme/app_colors.dart';
import 'package:loan_optimizer/core/theme/app_theme.dart';
import 'package:loan_optimizer/core/widgets/app_header.dart';
import 'package:loan_optimizer/core/widgets/dual_tone_progress_bar.dart';
import 'package:loan_optimizer/core/widgets/metric_tile.dart';
import 'package:loan_optimizer/core/widgets/quick_amount_chip.dart';
import 'package:loan_optimizer/core/widgets/segmented_control_pill.dart';
import 'package:loan_optimizer/core/widgets/sticky_bottom_dock.dart';
import 'package:loan_optimizer/providers/loan_provider.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
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

    testWidgets(
        'AppHeader notifications sheet matches dynamic EMI for configured loan amount (e.g. ₹5L loan)',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set loan principal to ₹5,00,000 (as in user screenshot)
      container.read(loanConfigProvider.notifier).updatePrincipal(500000);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: AppHeader(title: 'LoanOpt')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();

      // Dynamic EMI is ₹4,339, matching the main card on dashboard
      expect(find.text('Upcoming EMI (₹4,339)'), findsOneWidget);
    });

    testWidgets('AppHeader has no profile icon and displays notification bell only',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const AppHeader(title: 'LoanOpt'),
      ));

      expect(find.byIcon(Icons.person), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('AppHeader invokes custom notifications callback when provided',
        (tester) async {
      var notifTapped = false;

      await tester.pumpWidget(wrapWidget(
        AppHeader(
          title: 'LoanOpt',
          onNotificationsTap: () => notifTapped = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pump();
      expect(notifTapped, isTrue);
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

