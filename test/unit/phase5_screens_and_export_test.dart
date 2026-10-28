import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/theme/app_theme.dart';
import 'package:loan_optimizer/features/comparator/opportunity_cost_screen.dart';
import 'package:loan_optimizer/features/schedule/amortization_schedule_screen.dart';
import 'package:loan_optimizer/features/shell/app_shell.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/providers/loan_provider.dart';
import 'package:loan_optimizer/services/export_service.dart';
import 'package:loan_optimizer/services/loan_calculator_engine.dart';

void main() {
  group('Phase 5: ExportService Tests', () {
    final config = LoanConfig.defaultHomeLoan();
    final result = LoanCalculatorEngine.calculate(config: config);

    test('generateCsv outputs valid CSV with headers and all rows', () {
      final csv = ExportService.generateCsv(result);

      expect(csv, isNotEmpty);
      expect(csv, contains('Month'));
      expect(csv, contains('Opening Balance (INR)'));
      expect(csv, contains('EMI (INR)'));
      expect(csv, contains('Closing Balance (INR)'));

      // Check line count matches 240 rows + 1 header line
      final lines = csv.trim().split('\n');
      expect(lines.length, 241);
    });

    test('generatePdf builds valid non-empty PDF document', () async {
      final bytes = await ExportService.generatePdf(
        config: config,
        result: result,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000)); // Non-trivial PDF binary
    });
  });

  group('Phase 5: Screen 4 OpportunityCostScreen Tests', () {
    testWidgets('Renders Opportunity Cost Comparator with dilemma and verdict',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const OpportunityCostScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUANT DECISION MATRIX'), findsOneWidget);
      expect(find.text('Post-Tax Adjusted'), findsOneWidget);
      expect(find.text('MATHEMATICAL VERDICT'), findsOneWidget);
      expect(find.text('Net True Advantage'), findsOneWidget);
      expect(find.text('SCENARIO BREAKDOWN'), findsOneWidget);
      expect(find.text('Option A: Guaranteed Savings'), findsOneWidget);
      expect(find.text('Option B: Post-Tax Equity Profit'), findsOneWidget);
      expect(find.text('Expected Market Return'), findsOneWidget);
    });

    testWidgets('OpportunityCostScreen sliders and quick chips update state',
        (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const OpportunityCostScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sliders exist for Return and Horizon
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2));

      // Scroll to slider and drag
      await tester.ensureVisible(sliders.first);
      await tester.pumpAndSettle();
      await tester.drag(sliders.first, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(container.read(opportunityCostParamsProvider).expectedAnnualReturn,
          greaterThan(0));

      // Tap + ₹1L quick chip
      final chipFinder = find.text('+ ₹1L');
      if (chipFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(chipFinder.first);
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();
      }
    });
  });

  group('Phase 5: Screen 5 AmortizationScheduleScreen Tests', () {
    testWidgets('Renders Schedule screen with export pills, metrics and accordion',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AmortizationScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amortization Schedule'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('LIFECYCLE JOURNEY'), findsOneWidget);
      expect(find.text('PRINCIPAL'), findsOneWidget);
      expect(find.text('TOTAL INTEREST'), findsOneWidget);
      expect(find.text('TOTAL OUTFLOW'), findsOneWidget);
      expect(find.text('Schedule Trajectory'), findsOneWidget);
      expect(find.text('Year 1 (2022)'), findsOneWidget);
    });

    testWidgets('Tapping CSV export displays confirmation snackbar',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AmortizationScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CSV'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CSV Generated'), findsOneWidget);
    });

    testWidgets('Tapping PDF export displays confirmation snackbar',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AmortizationScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PDF Statement Generated'), findsOneWidget);
    });

    testWidgets('Tapping yearly accordion collapses and expands monthly breakdown',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AmortizationScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Year 1 is expanded by default - M1 is visible
      expect(find.text('M1 (Jan)'), findsOneWidget);

      // Tap Year 1 header to collapse it
      await tester.tap(find.text('Year 1 (2022)'));
      await tester.pumpAndSettle();

      // M1 is now collapsed
      expect(find.text('M1 (Jan)'), findsNothing);

      // Tap Year 1 again to expand it back
      await tester.tap(find.text('Year 1 (2022)'));
      await tester.pumpAndSettle();
      expect(find.text('M1 (Jan)'), findsOneWidget);
    });

    testWidgets('Switching to Monthly Breakdown renders monthly payment rows',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AmortizationScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monthly Breakdown'));
      await tester.pumpAndSettle();

      expect(find.text('Month 1'), findsOneWidget);
    });
  });

  group('Phase 5: AppShell Navigation Integration Tests', () {
    testWidgets('Bottom navigation switches between all 5 screens',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts at Overview
      expect(find.text('Home Loan'), findsOneWidget);

      // Tap Simulator via bottom bar
      await tester.tap(find.byIcon(Icons.bolt_outlined));
      await tester.pumpAndSettle();
      expect(find.text('PROJECTED TOTAL SAVINGS'), findsOneWidget);

      // Tap Compare via bottom bar
      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle();
      expect(find.text('QUANT DECISION MATRIX'), findsOneWidget);

      // Tap Schedule via bottom bar
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Amortization Schedule'), findsOneWidget);

      // Tap Setup via bottom bar
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Configure Loan & Targets'), findsOneWidget);
    });

    testWidgets('In-screen action buttons navigate between tabs in AppShell',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Simulator action card via its unique subtitle in Overview
      final simulatorCard = find.text('Save Lakhs early');
      await tester.ensureVisible(simulatorCard);
      await tester.pumpAndSettle();
      await tester.tap(simulatorCard);
      await tester.pumpAndSettle();

      // We are now in Simulator
      expect(find.text('PROJECTED TOTAL SAVINGS'), findsOneWidget);

      // Tap "Apply Strategy" button in bottom dock
      final applyButton = find.text('Apply Strategy');
      await tester.ensureVisible(applyButton);
      await tester.pumpAndSettle();
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // We are back in Overview
      expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);

      // Go to Setup via bottom bar
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Configure Loan & Targets'), findsOneWidget);

      // Tap "Save & View Dashboard" button
      final saveButton = find.text('Save & View Dashboard');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // We are back in Overview
      expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);
    });
  });
}
