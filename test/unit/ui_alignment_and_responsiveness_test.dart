import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loan_optimizer/features/loan_setup/loan_setup_screen.dart';
import 'package:loan_optimizer/features/dashboard/loan_overview_screen.dart';
import 'package:loan_optimizer/features/simulator/prepayment_strategy_simulator_screen.dart';
import 'package:loan_optimizer/features/comparator/opportunity_cost_screen.dart';
import 'package:loan_optimizer/features/schedule/amortization_schedule_screen.dart';
import 'package:loan_optimizer/features/shell/app_shell.dart';
import 'package:loan_optimizer/core/theme/app_theme.dart';

Widget createTestWidget({
  required Widget child,
  Size size = const Size(390, 844),
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  group('UI Alignment & Small Screen Responsiveness Tests (320px narrow constraint)', () {
    testWidgets('LoanSetupScreen renders cleanly on 320x568 narrow viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(320, 568),
          child: const LoanSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configure Loan & Targets'), findsOneWidget);
      expect(find.text('Loan Type'), findsOneWidget);
      expect(find.text('Principal Loan Amount'), findsOneWidget);
      expect(find.text('Interest Rate (% p.a.)'), findsOneWidget);
      expect(find.text('Loan Tenure'), findsOneWidget);
      expect(find.text('Save & View Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoanOverviewScreen renders cleanly on 320x568 narrow viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(320, 568),
          child: const LoanOverviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);
      expect(find.text('Sanctioned'), findsOneWidget);
      expect(find.text('Interest Rate'), findsOneWidget);
      expect(find.text('Tenure'), findsOneWidget);
      expect(find.text('Upcoming EMI (Auto-Debit)'), findsOneWidget);
      expect(find.text('Debt Decay Trajectory'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'PrepaymentStrategySimulatorScreen renders cleanly on 320x568 narrow viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(320, 568),
          child: const PrepaymentStrategySimulatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROJECTED TOTAL SAVINGS'), findsOneWidget);
      expect(find.text('Tenure Accelerated By'), findsOneWidget);
      expect(find.text('Freedom Milestone'), findsOneWidget);
      expect(find.text('Reduce Tenure'), findsOneWidget);
      expect(find.text('Reduce Monthly EMI'), findsOneWidget);
      expect(find.text('Active Accelerators'), findsOneWidget);
      expect(find.text('One-Time Lump Sum'), findsOneWidget);
      expect(find.text('Stepped EMI Step-up'), findsOneWidget);
      expect(find.text('13th Annual EMI Payoff'), findsOneWidget);
      expect(find.text('Apply Strategy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'OpportunityCostScreen renders cleanly on 320x568 narrow viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(320, 568),
          child: const OpportunityCostScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUANT DECISION MATRIX'), findsOneWidget);
      expect(find.text('Allocated Surplus Pool'), findsOneWidget);
      expect(find.text('MATHEMATICAL VERDICT'), findsOneWidget);
      expect(find.text('Net True Advantage'), findsOneWidget);
      expect(find.text('SCENARIO BREAKDOWN'), findsOneWidget);
      expect(find.text('Option A: Guaranteed Savings'), findsOneWidget);
      expect(find.text('Option B: Post-Tax Equity Profit'), findsOneWidget);
      expect(find.text('Expected Market Return'), findsOneWidget);
      expect(find.text('Investment Horizon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AmortizationScheduleScreen renders both Yearly and Monthly views on 320x568 narrow viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(320, 568),
          child: const AmortizationScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Yearly View
      expect(find.text('Yearly View (Summary)'), findsOneWidget);
      expect(find.text('Monthly Breakdown'), findsOneWidget);
      expect(find.text('LIFECYCLE JOURNEY'), findsOneWidget);
      expect(find.text('PRINCIPAL'), findsOneWidget);
      expect(find.text('TOTAL INTEREST'), findsOneWidget);
      expect(find.text('TOTAL OUTFLOW'), findsOneWidget);
      expect(find.text('Schedule Trajectory'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switch to Monthly Breakdown
      await tester.tap(find.text('Monthly Breakdown'));
      await tester.pumpAndSettle();

      expect(find.text('Month 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AppShell navigation works seamlessly on 320x568 narrow viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(320, 568),
          child: const AppShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(BottomNavigationBar, 'Overview'), findsOneWidget);
      expect(find.widgetWithText(BottomNavigationBar, 'Simulator'), findsOneWidget);
      expect(find.widgetWithText(BottomNavigationBar, 'Compare'), findsOneWidget);
      expect(find.widgetWithText(BottomNavigationBar, 'Schedule'), findsOneWidget);
      expect(find.widgetWithText(BottomNavigationBar, 'Setup'), findsOneWidget);

      // Tap through all 5 tabs
      await tester.tap(find.byIcon(Icons.bolt_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.dashboard_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Standard & Wide Viewport UI Tests (390x844 and 768x1024)', () {
    testWidgets('LoanOverviewScreen renders cleanly on standard 390x844 viewport',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(390, 844),
          child: const LoanOverviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PrepaymentStrategySimulatorScreen renders cleanly on wide 768x1024 tablet viewport',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          size: const Size(768, 1024),
          child: const PrepaymentStrategySimulatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROJECTED TOTAL SAVINGS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
