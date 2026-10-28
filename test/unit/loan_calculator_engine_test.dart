import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/models/prepayment_plan.dart';
import 'package:loan_optimizer/services/loan_calculator_engine.dart';

void main() {
  group('LoanCalculatorEngine EMI Calculations', () {
    test('Calculates benchmark 50L 8.5% 20Y home loan EMI correctly', () {
      final emi = LoanCalculatorEngine.calculateEmi(
        principal: 5000000,
        annualRate: 8.5,
        tenureMonths: 240,
      );
      // Expected EMI: ~43,391.14
      expect(emi.round(), 43391);
    });

    test('Zero interest rate edge case (0% loan)', () {
      final emi = LoanCalculatorEngine.calculateEmi(
        principal: 120000,
        annualRate: 0.0,
        tenureMonths: 12,
      );
      expect(emi, 10000.0);
    });

    test('Zero principal returns 0 EMI', () {
      final emi = LoanCalculatorEngine.calculateEmi(
        principal: 0,
        annualRate: 8.5,
        tenureMonths: 240,
      );
      expect(emi, 0.0);
    });

    test('Zero tenure returns 0 EMI', () {
      final emi = LoanCalculatorEngine.calculateEmi(
        principal: 5000000,
        annualRate: 8.5,
        tenureMonths: 0,
      );
      expect(emi, 0.0);
    });

    test('Short tenure: 1 month loan', () {
      final emi = LoanCalculatorEngine.calculateEmi(
        principal: 100000,
        annualRate: 12.0,
        tenureMonths: 1,
      );
      // Monthly interest = 1% = 1000. Total = 101,000.
      expect(emi.round(), 101000);
    });
  });

  group('LoanCalculatorEngine Base Amortization Schedule', () {
    final config = LoanConfig.defaultHomeLoan(); // 50L, 8.5%, 240 months

    test('Base schedule has 240 rows and pays off down to 0', () {
      final result = LoanCalculatorEngine.calculate(config: config);

      expect(result.baseSchedule.length, 240);
      expect(result.originalTenureMonths, 240);
      expect(result.baseSchedule.first.openingBalance, 5000000);
      expect(result.baseSchedule.last.closingBalance, 0.0);

      // Check total interest is approx 54.14 Lakhs
      expect(result.baseTotalInterest.round(), closeTo(5413874, 500));
      // Total outflow approx 1.04 Crores
      expect(result.baseTotalOutflow.round(), closeTo(10413874, 500));
    });

    test('Yearly summaries group rows properly', () {
      final result = LoanCalculatorEngine.calculate(config: config);

      expect(result.yearlySummaries.length, 20); // 20 years
      expect(result.yearlySummaries.first.yearIndex, 1);
      expect(result.yearlySummaries.first.monthlyRows.length, 12);
      expect(result.yearlySummaries.last.closingBalance, 0.0);
    });
  });

  group('LoanCalculatorEngine Prepayment Strategies', () {
    final config = LoanConfig.defaultHomeLoan();

    test('One-time lump sum prepayment reduces tenure and saves interest', () {
      const plan = PrepaymentPlan(
        lumpSums: [
          LumpSumPrepayment(monthIndex: 12, amount: 500000), // 5 Lakhs prepay at 1 year
        ],
        strategyMode: StrategyMode.reduceTenure,
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);

      expect(result.optimizedTenureMonths, lessThan(240));
      expect(result.monthsSaved, greaterThan(0));
      expect(result.totalInterestSaved, greaterThan(0));
      expect(result.optimizedTotalInterest, lessThan(result.baseTotalInterest));
      expect(result.optimizedSchedule.last.closingBalance, 0.0);
    });

    test('Stepped EMI (5% annual increase) accelerates payoff', () {
      const plan = PrepaymentPlan(
        steppedEmiPercentage: 5.0,
        strategyMode: StrategyMode.reduceTenure,
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);

      // Stepping up EMI by 5% every year should shave off over 5 years (60+ months)
      expect(result.monthsSaved, greaterThan(60));
      expect(result.totalInterestSaved, greaterThan(1000000)); // > 10 Lakhs saved
    });

    test('13th Extra Annual EMI reduces tenure', () {
      const plan = PrepaymentPlan(
        enableExtraAnnualEmi: true,
        extraAnnualEmiMonth: 12,
        strategyMode: StrategyMode.reduceTenure,
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);

      expect(result.monthsSaved, greaterThan(30)); // typically 3-4 years saved
      expect(result.totalInterestSaved, greaterThan(800000));
    });

    test('Prepayment exceeding remaining balance caps and terminates cleanly', () {
      const plan = PrepaymentPlan(
        lumpSums: [
          LumpSumPrepayment(monthIndex: 2, amount: 6000000), // Exceeds 50L
        ],
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);

      // Loan should finish at Month 2
      expect(result.optimizedTenureMonths, 2);
      expect(result.optimizedSchedule.last.closingBalance, 0.0);
      expect(result.optimizedSchedule[1].extraPrepayment, lessThanOrEqualTo(5000000));
    });

    test('Reduce EMI mode keeps tenure while reducing monthly payment', () {
      const plan = PrepaymentPlan(
        lumpSums: [
          LumpSumPrepayment(monthIndex: 12, amount: 1000000), // 10 Lakhs lump sum
        ],
        strategyMode: StrategyMode.reduceEmi,
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);

      // Tenure should still run 240 months
      expect(result.optimizedTenureMonths, 240);
      // Later EMI should be noticeably smaller than base EMI
      final emiAfterPrepayment = result.optimizedSchedule[13].emi;
      expect(emiAfterPrepayment, lessThan(result.baseMonthlyEmi));
      expect(result.totalInterestSaved, greaterThan(0));
    });
  });
}

