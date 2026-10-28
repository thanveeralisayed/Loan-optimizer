import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/models/prepayment_plan.dart';
import 'package:loan_optimizer/providers/loan_provider.dart';

void main() {
  group('Loan Providers & Notifiers Comprehensive Unit Tests', () {
    test('LoanConfigNotifier updates principal and enforces boundary constraints', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanConfigProvider.notifier);
      expect(container.read(loanConfigProvider).principal, 5000000);

      // Valid update
      notifier.updatePrincipal(7500000);
      expect(container.read(loanConfigProvider).principal, 7500000);

      // Negative value is ignored
      notifier.updatePrincipal(-100);
      expect(container.read(loanConfigProvider).principal, 7500000);

      // Adjust principal with delta
      notifier.adjustPrincipal(500000);
      expect(container.read(loanConfigProvider).principal, 8000000);

      // Adjust principal clamping to 0 floor
      notifier.adjustPrincipal(-999999999);
      expect(container.read(loanConfigProvider).principal, 0.0);

      // Adjust principal clamping to 1 Billion ceiling
      notifier.adjustPrincipal(2000000000);
      expect(container.read(loanConfigProvider).principal, 1000000000.0);
    });

    test('LoanConfigNotifier updates rate and tenure with boundary guards', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanConfigProvider.notifier);

      // Update rate
      notifier.updateRate(9.75);
      expect(container.read(loanConfigProvider).annualInterestRate, 9.75);

      // Negative rate is ignored
      notifier.updateRate(-5.0);
      expect(container.read(loanConfigProvider).annualInterestRate, 9.75);

      // Update tenure months
      notifier.updateTenureMonths(180);
      expect(container.read(loanConfigProvider).tenureMonths, 180);

      // Non-positive tenure is ignored
      notifier.updateTenureMonths(0);
      expect(container.read(loanConfigProvider).tenureMonths, 180);
      notifier.updateTenureMonths(-12);
      expect(container.read(loanConfigProvider).tenureMonths, 180);

      // Adjust tenure years with clamping
      notifier.adjustTenureYears(2); // +24 months -> 204
      expect(container.read(loanConfigProvider).tenureMonths, 204);

      // Clamping to 12 months floor
      notifier.adjustTenureYears(-50);
      expect(container.read(loanConfigProvider).tenureMonths, 12);

      // Clamping to 600 months ceiling (50 years)
      notifier.adjustTenureYears(100);
      expect(container.read(loanConfigProvider).tenureMonths, 600);
    });

    test('LoanConfigNotifier updates loan category and rate type', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanConfigProvider.notifier);

      notifier.updateLoanType(LoanType.car);
      expect(container.read(loanConfigProvider).loanType, LoanType.car);
      expect(container.read(loanConfigProvider).name, 'Car Loan');

      notifier.updateRateType(RateType.fixed);
      expect(container.read(loanConfigProvider).rateType, RateType.fixed);
    });

    test('PrepaymentPlanNotifier manages lump sums, step-up, and strategy mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(prepaymentPlanProvider.notifier);

      // Initial has 1 lump sum
      expect(container.read(prepaymentPlanProvider).lumpSums.length, 1);

      // Update existing lump sum
      notifier.setLumpSumAmount(250000, monthIndex: 12);
      expect(container.read(prepaymentPlanProvider).lumpSums.first.amount, 250000);

      // Add a second lump sum on month 24
      notifier.setLumpSumAmount(150000, monthIndex: 24);
      expect(container.read(prepaymentPlanProvider).lumpSums.length, 2);

      // Setting amount <= 0 removes the lump sum
      notifier.setLumpSumAmount(0, monthIndex: 24);
      expect(container.read(prepaymentPlanProvider).lumpSums.length, 1);
      expect(container.read(prepaymentPlanProvider).lumpSums.any((l) => l.monthIndex == 24), isFalse);

      // Stepped EMI percentage with clamping (0% to 50%)
      notifier.setSteppedEmiPercentage(10.0);
      expect(container.read(prepaymentPlanProvider).steppedEmiPercentage, 10.0);
      notifier.setSteppedEmiPercentage(-5.0);
      expect(container.read(prepaymentPlanProvider).steppedEmiPercentage, 0.0);
      notifier.setSteppedEmiPercentage(75.0);
      expect(container.read(prepaymentPlanProvider).steppedEmiPercentage, 50.0);

      // Toggle extra annual EMI
      notifier.toggleExtraAnnualEmi(false);
      expect(container.read(prepaymentPlanProvider).enableExtraAnnualEmi, isFalse);
      notifier.toggleExtraAnnualEmi(true);
      expect(container.read(prepaymentPlanProvider).enableExtraAnnualEmi, isTrue);

      // Strategy mode
      notifier.setStrategyMode(StrategyMode.reduceEmi);
      expect(container.read(prepaymentPlanProvider).strategyMode, StrategyMode.reduceEmi);
    });

    test('OpportunityCostParamsNotifier updates return, surplus, and horizon', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(opportunityCostParamsProvider.notifier);

      notifier.updateExpectedReturn(15.0);
      expect(container.read(opportunityCostParamsProvider).expectedAnnualReturn, 15.0);

      notifier.updateSurplus(lumpSum: 500000, monthlySip: 15000);
      expect(container.read(opportunityCostParamsProvider).lumpSumSurplus, 500000);
      expect(container.read(opportunityCostParamsProvider).monthlySipSurplus, 15000);

      notifier.updateHorizonMonths(120);
      expect(container.read(opportunityCostParamsProvider).horizonMonths, 120);
    });

    test('Riverpod dependent providers re-evaluate when dependencies change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial calculations
      final initialAmortization = container.read(amortizationResultProvider);
      final initialOpportunityCost = container.read(opportunityCostResultProvider);

      expect(initialAmortization.baseMonthlyEmi, greaterThan(0));
      expect(initialOpportunityCost.investedPrincipal, greaterThan(0));

      // Mutate loan config
      container.read(loanConfigProvider.notifier).updatePrincipal(6000000);
      final updatedAmortization = container.read(amortizationResultProvider);
      expect(updatedAmortization.baseMonthlyEmi, greaterThan(initialAmortization.baseMonthlyEmi));

      // Mutate opportunity cost params
      container.read(opportunityCostParamsProvider.notifier).updateExpectedReturn(18.0);
      final updatedOpportunityCost = container.read(opportunityCostResultProvider);
      expect(updatedOpportunityCost.grossFutureValue,
          greaterThan(initialOpportunityCost.grossFutureValue));
    });
  });
}
