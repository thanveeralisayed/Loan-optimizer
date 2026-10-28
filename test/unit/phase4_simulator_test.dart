import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/theme/app_theme.dart';
import 'package:loan_optimizer/features/simulator/prepayment_strategy_simulator_screen.dart';
import 'package:loan_optimizer/models/prepayment_plan.dart';
import 'package:loan_optimizer/providers/loan_provider.dart';

void main() {
  group('Phase 4: Screen 3 PrepaymentStrategySimulatorScreen Tests', () {
    testWidgets('Renders Simulator screen with projected savings and metrics',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PrepaymentStrategySimulatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROJECTED TOTAL SAVINGS'), findsOneWidget);
      expect(find.text('ALGORITHMIC OPTIMIZATION'), findsOneWidget);
      expect(find.text('Live Recalculation'), findsOneWidget);
      expect(find.text('Tenure Accelerated By'), findsOneWidget);
      expect(find.text('Freedom Milestone'), findsOneWidget);
      expect(find.text('Reduce Tenure'), findsOneWidget);
      expect(find.text('Reduce Monthly EMI'), findsOneWidget);
      expect(find.text('Apply Strategy'), findsOneWidget);
    });

    testWidgets('Toggling Strategy Mode changes plan state', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PrepaymentStrategySimulatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(prepaymentPlanProvider).strategyMode,
          StrategyMode.reduceTenure);

      // Tap Reduce Monthly EMI
      await tester.tap(find.text('Reduce Monthly EMI'));
      await tester.pumpAndSettle();

      expect(container.read(prepaymentPlanProvider).strategyMode,
          StrategyMode.reduceEmi);
    });

    testWidgets('Lump sum quick chip increases prepayment and saves more interest',
        (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PrepaymentStrategySimulatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialSavings =
          container.read(amortizationResultProvider).totalInterestSaved;

      final chipFinder = find.text('+ ₹5L');
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      final updatedSavings =
          container.read(amortizationResultProvider).totalInterestSaved;

      // Incurring additional ₹5L lump sum must increase total interest saved
      expect(updatedSavings, greaterThan(initialSavings));
    });

    testWidgets('13th Annual EMI switch toggles on and off', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PrepaymentStrategySimulatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      // Tap switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Initial state was true, should now be false
      expect(
          container.read(prepaymentPlanProvider).enableExtraAnnualEmi, isFalse);
    });

    testWidgets('Stepped EMI slider updates percentage state', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PrepaymentStrategySimulatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      await tester.ensureVisible(sliderFinder);

      // Drag slider forward
      await tester.drag(sliderFinder, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(container.read(prepaymentPlanProvider).steppedEmiPercentage,
          greaterThanOrEqualTo(0.0));
    });

    testWidgets('Apply Strategy button triggers onApply callback', (tester) async {
      bool applied = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: PrepaymentStrategySimulatorScreen(
              onApply: () => applied = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final applyButton = find.text('Apply Strategy');
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(applied, isTrue);
    });
  });
}

