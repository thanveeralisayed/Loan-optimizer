import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/theme/app_theme.dart';
import 'package:loan_optimizer/features/dashboard/loan_overview_screen.dart';
import 'package:loan_optimizer/features/loan_setup/loan_setup_screen.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/providers/loan_provider.dart';

void main() {
  Widget wrapWithProvider(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('Phase 3: Screen 1 LoanSetupScreen Tests', () {
    testWidgets('Renders LoanSetupScreen with initial defaults',
        (tester) async {
      await tester.pumpWidget(wrapWithProvider(const LoanSetupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Configure Loan & Targets'), findsOneWidget);
      expect(find.text('LOCAL & OFFLINE ENGINE'), findsOneWidget);
      expect(find.text('Home Loan'), findsOneWidget);
      expect(find.text('Car Loan'), findsOneWidget);
      expect(find.text('Fifty Lakhs Rupees'), findsOneWidget);
      expect(find.text('+ ₹5L'), findsOneWidget);
      expect(find.text('+ ₹10L'), findsOneWidget);
      expect(find.text('+ ₹25L'), findsOneWidget);
    });

    testWidgets('Quick amount chips increment principal', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoanSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialPrincipal = container.read(loanConfigProvider).principal;
      expect(initialPrincipal, 5000000.0);

      // Tap + ₹5L
      await tester.tap(find.text('+ ₹5L'));
      await tester.pumpAndSettle();

      final updatedPrincipal = container.read(loanConfigProvider).principal;
      expect(updatedPrincipal, 5500000.0);
    });

    testWidgets('Switching loan type updates state', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoanSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Car Loan'));
      await tester.pumpAndSettle();

      expect(container.read(loanConfigProvider).loanType, LoanType.car);
    });
  });

  group('Phase 3: Screen 2 LoanOverviewScreen Tests', () {
    testWidgets('Renders LoanOverviewScreen with metrics and decay progress',
        (tester) async {
      await tester.pumpWidget(wrapWithProvider(const LoanOverviewScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Prime Home Loan'), findsOneWidget);
      expect(find.text('•••• 8492'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);
      expect(find.text('Upcoming EMI (Auto-Debit)'), findsOneWidget);
      expect(find.text('Due in 6 days'), findsOneWidget);
      expect(find.text('Debt Decay Trajectory'), findsOneWidget);
    });

    testWidgets('Action cards fire navigation callbacks', (tester) async {
      bool simulatorTapped = false;
      bool scheduleTapped = false;
      bool comparatorTapped = false;

      await tester.pumpWidget(wrapWithProvider(
        LoanOverviewScreen(
          onNavigateToSimulator: () => simulatorTapped = true,
          onNavigateToSchedule: () => scheduleTapped = true,
          onNavigateToComparator: () => comparatorTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      final simulatorFinder = find.text('Simulator');
      await tester.ensureVisible(simulatorFinder);
      await tester.pumpAndSettle();
      await tester.tap(simulatorFinder);
      expect(simulatorTapped, isTrue);

      final comparatorFinder = find.text('Nifty 50 vs Loan');
      await tester.ensureVisible(comparatorFinder);
      await tester.pumpAndSettle();
      await tester.tap(comparatorFinder);
      expect(comparatorTapped, isTrue);

      final scheduleFinder = find.text('Full Amortization Schedule');
      await tester.ensureVisible(scheduleFinder);
      await tester.pumpAndSettle();
      await tester.tap(scheduleFinder);
      expect(scheduleTapped, isTrue);
    });
  });
}
