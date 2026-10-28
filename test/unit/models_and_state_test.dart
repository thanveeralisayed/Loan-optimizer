import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/models/amortization_schedule.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/models/opportunity_cost_models.dart';
import 'package:loan_optimizer/models/prepayment_plan.dart';

void main() {
  group('Models and Domain State Comprehensive Unit Tests', () {
    test('PrepayVerdict titles and short verdicts', () {
      expect(PrepayVerdict.prepayLoan.title, 'Prepay the Loan First');
      expect(PrepayVerdict.prepayLoan.shortVerdict, 'Prepay');

      expect(PrepayVerdict.investMarket.title, 'Invest Surplus in Market');
      expect(PrepayVerdict.investMarket.shortVerdict, 'Invest');

      expect(PrepayVerdict.neutral.title, 'Mathematically Equivalent');
      expect(PrepayVerdict.neutral.shortVerdict, 'Neutral');
    });

    test('OpportunityCostParams copyWith, defaults, and validation assertions', () {
      const defaultParams = OpportunityCostParams();
      expect(defaultParams.expectedAnnualReturn, 12.0);
      expect(defaultParams.ltcgTaxRate, 12.5);
      expect(defaultParams.ltcgExemptionAmount, 125000.0);
      expect(defaultParams.lumpSumSurplus, 200000.0);
      expect(defaultParams.monthlySipSurplus, 5000.0);
      expect(defaultParams.horizonMonths, 60);

      final modified = defaultParams.copyWith(
        expectedAnnualReturn: 14.5,
        ltcgTaxRate: 15.0,
        ltcgExemptionAmount: 100000.0,
        lumpSumSurplus: 300000.0,
        monthlySipSurplus: 10000.0,
        horizonMonths: 120,
      );

      expect(modified.expectedAnnualReturn, 14.5);
      expect(modified.ltcgTaxRate, 15.0);
      expect(modified.ltcgExemptionAmount, 100000.0);
      expect(modified.lumpSumSurplus, 300000.0);
      expect(modified.monthlySipSurplus, 10000.0);
      expect(modified.horizonMonths, 120);

      // Verify assert guards
      expect(() => OpportunityCostParams(expectedAnnualReturn: -1), throwsAssertionError);
      expect(() => OpportunityCostParams(ltcgTaxRate: -0.5), throwsAssertionError);
      expect(() => OpportunityCostParams(horizonMonths: 0), throwsAssertionError);
    });

    test('LumpSumPrepayment copyWith, equality, hashCode, and assertions', () {
      const lumpSum1 = LumpSumPrepayment(monthIndex: 6, amount: 50000, note: 'Bonus');
      const lumpSum2 = LumpSumPrepayment(monthIndex: 6, amount: 50000, note: 'Bonus');
      const lumpSum3 = LumpSumPrepayment(monthIndex: 12, amount: 50000, note: 'Bonus');

      expect(lumpSum1, equals(lumpSum2));
      expect(lumpSum1.hashCode, equals(lumpSum2.hashCode));
      expect(lumpSum1 == lumpSum3, isFalse);

      final copied = lumpSum1.copyWith(
        monthIndex: 12,
        amount: 75000,
        note: 'Annual Bonus',
      );
      expect(copied.monthIndex, 12);
      expect(copied.amount, 75000);
      expect(copied.note, 'Annual Bonus');

      // Assert validation guards
      expect(() => LumpSumPrepayment(monthIndex: 0, amount: 100), throwsAssertionError);
      expect(() => LumpSumPrepayment(monthIndex: 1, amount: -10), throwsAssertionError);
    });

    test('PrepaymentPlan factory constructors, copyWith, equality, and validation', () {
      final emptyPlan = PrepaymentPlan.empty();
      expect(emptyPlan.lumpSums, isEmpty);
      expect(emptyPlan.steppedEmiPercentage, 0.0);
      expect(emptyPlan.enableExtraAnnualEmi, isFalse);
      expect(emptyPlan.extraAnnualEmiMonth, 12);
      expect(emptyPlan.strategyMode, StrategyMode.reduceTenure);

      final samplePlan = PrepaymentPlan.sample();
      expect(samplePlan.lumpSums.length, 1);
      expect(samplePlan.steppedEmiPercentage, 5.0);
      expect(samplePlan.enableExtraAnnualEmi, isTrue);

      final copied = emptyPlan.copyWith(
        lumpSums: [const LumpSumPrepayment(monthIndex: 3, amount: 25000)],
        steppedEmiPercentage: 8.0,
        enableExtraAnnualEmi: true,
        extraAnnualEmiMonth: 6,
        strategyMode: StrategyMode.reduceEmi,
      );
      expect(copied.lumpSums.length, 1);
      expect(copied.steppedEmiPercentage, 8.0);
      expect(copied.enableExtraAnnualEmi, isTrue);
      expect(copied.extraAnnualEmiMonth, 6);
      expect(copied.strategyMode, StrategyMode.reduceEmi);

      // Equality and hashcode
      final copied2 = copied.copyWith();
      expect(copied, equals(copied2));
      expect(copied.hashCode, equals(copied2.hashCode));

      // Assert validation guards
      expect(() => PrepaymentPlan(steppedEmiPercentage: -1), throwsAssertionError);
      expect(() => PrepaymentPlan(extraAnnualEmiMonth: 0), throwsAssertionError);
      expect(() => PrepaymentPlan(extraAnnualEmiMonth: 13), throwsAssertionError);
    });

    test('StrategyMode and LoanType/RateType display names', () {
      expect(StrategyMode.reduceTenure.displayName, 'Reduce Tenure');
      expect(StrategyMode.reduceEmi.displayName, 'Reduce Monthly EMI');

      expect(LoanType.home.displayName, 'Home Loan');
      expect(LoanType.car.displayName, 'Car Loan');
      expect(LoanType.personal.displayName, 'Personal Loan');
      expect(LoanType.education.displayName, 'Education Loan');

      expect(RateType.floating.displayName, 'Floating');
      expect(RateType.fixed.displayName, 'Fixed');
    });

    test('AmortizationRow and Summary calculated helper getters', () {
      final row = AmortizationRow(
        monthIndex: 1,
        yearIndex: 1,
        date: DateTime(2023, 1, 1),
        openingBalance: 5000000,
        emi: 43391,
        principalPaid: 8000,
        interestPaid: 35391,
        extraPrepayment: 20000,
        closingBalance: 4972000,
      );

      expect(row.totalPrincipalComponent, 28000);
      expect(row.totalOutflow, 63391);

      final summary = YearlyAmortizationSummary(
        yearIndex: 1,
        yearNumber: 2023,
        openingBalance: 5000000,
        totalEmiPaid: 520692,
        totalPrincipalPaid: 100000,
        totalInterestPaid: 420692,
        totalPrepaymentPaid: 150000,
        closingBalance: 4750000,
        isCompleted: false,
        monthlyRows: [row],
      );

      expect(summary.totalOutflow, 670692);
      expect(summary.totalPrincipalReduced, 250000);

      final result = LoanAmortizationResult(
        baseSchedule: [row],
        optimizedSchedule: [row],
        yearlySummaries: [summary],
        baseMonthlyEmi: 43391,
        totalPrincipal: 5000000,
        baseTotalInterest: 5413800,
        optimizedTotalInterest: 3200000,
        totalInterestSaved: 2213800,
        originalTenureMonths: 240,
        optimizedTenureMonths: 156,
        monthsSaved: 84,
        originalEndDate: DateTime(2043, 1, 1),
        optimizedEndDate: DateTime(2036, 1, 1),
        savingsPercentage: 40.89,
      );

      expect(result.baseTotalOutflow, 10413800);
      expect(result.optimizedTotalOutflow, 8200000);
    });

    test('LoanConfig copyWith, equality, hashCode, and assert validation', () {
      final config1 = LoanConfig.defaultHomeLoan();
      final config2 = LoanConfig.defaultHomeLoan();

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));

      final modified = config1.copyWith(
        principal: 6000000,
        annualInterestRate: 9.25,
        tenureMonths: 180,
        startDate: DateTime(2025, 6, 1),
        loanType: LoanType.car,
        rateType: RateType.fixed,
        name: 'Electric Car Loan',
        loanNumber: '7777',
      );

      expect(modified.principal, 6000000);
      expect(modified.annualInterestRate, 9.25);
      expect(modified.tenureMonths, 180);
      expect(modified.startDate, DateTime(2025, 6, 1));
      expect(modified.loanType, LoanType.car);
      expect(modified.rateType, RateType.fixed);
      expect(modified.name, 'Electric Car Loan');
      expect(modified.loanNumber, '7777');
      expect(config1 == modified, isFalse);

      // Assert validations
      expect(() => LoanConfig(principal: -1, annualInterestRate: 8, tenureMonths: 120),
          throwsAssertionError);
      expect(() => LoanConfig(principal: 100000, annualInterestRate: -0.1, tenureMonths: 120),
          throwsAssertionError);
      expect(() => LoanConfig(principal: 100000, annualInterestRate: 8, tenureMonths: -1),
          throwsAssertionError);
    });
  });
}
