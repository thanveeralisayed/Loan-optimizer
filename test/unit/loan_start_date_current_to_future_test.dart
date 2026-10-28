import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:loan_optimizer/core/theme/app_theme.dart';
import 'package:loan_optimizer/features/dashboard/loan_overview_screen.dart';
import 'package:loan_optimizer/features/schedule/amortization_schedule_screen.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/models/prepayment_plan.dart';
import 'package:loan_optimizer/providers/loan_provider.dart';
import 'package:loan_optimizer/services/loan_calculator_engine.dart';

void main() {
  group('Loan Calculation Starting From Current Date To Future Tests', () {
    test('LoanConfig.defaultHomeLoan starts from current date/month, not 2022', () {
      final config = LoanConfig.defaultHomeLoan();
      final now = DateTime.now();

      expect(config.startDate.year, equals(now.year));
      expect(config.startDate.month, equals(now.month));
      expect(config.startDate.day, equals(1));
      expect(config.startDate.year, isNot(equals(2022)));
    });

    test('LoanConfig default constructor without startDate defaults to current month/year', () {
      final config = LoanConfig(
        principal: 2500000,
        annualInterestRate: 9.0,
        tenureMonths: 120,
      );
      final now = DateTime.now();

      expect(config.startDate.year, equals(now.year));
      expect(config.startDate.month, equals(now.month));
      expect(config.startDate.year, greaterThanOrEqualTo(2026));
      expect(config.startDate.year, isNot(equals(2022)));
    });

    test('Amortization schedule dates strictly progress from current date into the future', () {
      final config = LoanConfig.defaultHomeLoan();
      final result = LoanCalculatorEngine.calculate(config: config);
      final now = DateTime.now();

      expect(result.baseSchedule, isNotEmpty);
      expect(result.optimizedSchedule, isNotEmpty);

      // Row 1 starts at the current month & year
      final firstRow = result.baseSchedule.first;
      expect(firstRow.date.year, equals(now.year));
      expect(firstRow.date.month, equals(now.month));

      // Row 2 is exactly 1 month after
      final secondRow = result.baseSchedule[1];
      final expectedSecondMonth = (now.month % 12) + 1;
      final expectedSecondYear = now.month == 12 ? now.year + 1 : now.year;
      expect(secondRow.date.month, equals(expectedSecondMonth));
      expect(secondRow.date.year, equals(expectedSecondYear));

      // End dates are far in the future (~20 years out)
      expect(result.originalEndDate.year, equals(now.year + 20));
      expect(result.originalEndDate.isAfter(now), isTrue);
      expect(result.optimizedEndDate.isAfter(now), isTrue);

      // All schedule rows have dates >= startDate
      for (final row in result.baseSchedule) {
        expect(row.date.isBefore(config.startDate), isFalse);
      }

      // Yearly summaries start at current year and increment into the future
      expect(result.yearlySummaries, isNotEmpty);
      expect(result.yearlySummaries.first.yearNumber, equals(now.year));
      expect(result.yearlySummaries.first.yearIndex, equals(1));

      for (int i = 0; i < result.yearlySummaries.length; i++) {
        expect(result.yearlySummaries[i].yearNumber, equals(now.year + i));
      }
    });

    testWidgets('AmortizationScheduleScreen displays current year (not 2022) in yearly accordion',
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

      final currentYear = DateTime.now().year;
      final currentMonthName = DateFormat('MMM').format(DateTime.now());

      // Must find current year in Year 1 header, and never 2022
      expect(find.text('Year 1 ($currentYear)'), findsOneWidget);
      expect(find.text('Year 1 (2022)'), findsNothing);

      // Month 1 must display current month name (e.g. M1 (Oct))
      expect(find.text('M1 ($currentMonthName)'), findsOneWidget);
    });

    testWidgets(
        'LoanOverviewScreen models current loan from day 1 with full principal and future auto-debit',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: LoanOverviewScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand new loan starting from current date:
      // Outstanding balance must be full ₹50,00,000, 0% paid, no mock 3-year reduction from 2022
      expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);
      expect(find.text('₹50,00,000'), findsOneWidget);
      expect(find.text('0% Paid'), findsOneWidget);

      // Next EMI date label is dynamically computed from current date to future
      final now = DateTime.now();
      final emiDay = 1; // startDate is 1st of month
      final DateTime nextEmiDate;
      if (now.day < emiDay) {
        nextEmiDate = DateTime(now.year, now.month, emiDay);
      } else {
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        final daysInNextMonth = DateUtils.getDaysInMonth(nextYear, nextMonth);
        nextEmiDate = DateTime(nextYear, nextMonth, emiDay.clamp(1, daysInNextMonth));
      }
      final expectedMonthName = DateFormat('MMM').format(nextEmiDate);
      expect(find.textContaining(expectedMonthName), findsWidgets);

      // Ensure hardcoded mock string from 2022 ("5th Next Month") is gone
      expect(find.text('5th Next Month'), findsNothing);
    });

    testWidgets(
        'LoanOverviewScreen displays Year 1 of tenure progress when no prepayment plan is active',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Clear any prepayment plan so monthsSaved == 0
      container.read(prepaymentPlanProvider.notifier).applyPlan(const PrepaymentPlan());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: LoanOverviewScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Amortization progress • Year 1 of 20'), findsOneWidget);
    });
  });
}

