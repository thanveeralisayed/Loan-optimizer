import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/models/prepayment_plan.dart';
import 'package:loan_optimizer/models/opportunity_cost_models.dart';
import 'package:loan_optimizer/services/loan_calculator_engine.dart';
import 'package:loan_optimizer/services/opportunity_cost_engine.dart';
import 'package:loan_optimizer/core/utils/indian_currency_formatter.dart';
import 'package:loan_optimizer/services/export_service.dart';

void main() {
  group('LoanCalculatorEngine Comprehensive Edge Cases', () {
    test('calculateEmi handles zero principal and non-positive tenure gracefully', () {
      expect(LoanCalculatorEngine.calculateEmi(principal: 0, annualRate: 8.5, tenureMonths: 240), 0.0);
      expect(LoanCalculatorEngine.calculateEmi(principal: -500000, annualRate: 8.5, tenureMonths: 240), 0.0);
      expect(LoanCalculatorEngine.calculateEmi(principal: 5000000, annualRate: 8.5, tenureMonths: 0), 0.0);
      expect(LoanCalculatorEngine.calculateEmi(principal: 5000000, annualRate: 8.5, tenureMonths: -12), 0.0);
    });

    test('calculateEmi handles zero or negative interest rate (0% financing)', () {
      final emiZero = LoanCalculatorEngine.calculateEmi(principal: 120000, annualRate: 0.0, tenureMonths: 12);
      expect(emiZero, 10000.0);

      final emiNegative = LoanCalculatorEngine.calculateEmi(principal: 120000, annualRate: -5.0, tenureMonths: 12);
      expect(emiNegative, 10000.0);
    });

    test('calculateEmi for single month tenure (minimum possible duration)', () {
      final emi = LoanCalculatorEngine.calculateEmi(principal: 100000, annualRate: 12.0, tenureMonths: 1);
      // 1 month at 1% per month = 100000 * 1.01 = 101000
      expect(emi, closeTo(101000.0, 1.0));
    });

    test('calculate handles extremely large loan amount (₹100 Crores) without NaN or overflow', () {
      const largePrincipal = 1000000000.0; // ₹100 Crores
      final config = LoanConfig(
        principal: largePrincipal,
        annualInterestRate: 9.0,
        tenureMonths: 360,
      );

      final result = LoanCalculatorEngine.calculate(config: config);
      expect(result.baseMonthlyEmi.isFinite, isTrue);
      expect(result.baseMonthlyEmi.isNaN, isFalse);
      expect(result.baseMonthlyEmi, greaterThan(8000000.0)); // > 80 Lakhs/mo
      expect(result.baseSchedule.length, 360);
      expect(result.baseSchedule.last.closingBalance, closeTo(0.0, 1.0));
    });

    test('calculate handles high interest rate (e.g. 50% p.a.) without instability', () {
      final config = LoanConfig(
        principal: 500000,
        annualInterestRate: 50.0,
        tenureMonths: 24,
      );

      final result = LoanCalculatorEngine.calculate(config: config);
      expect(result.baseSchedule.length, 24);
      expect(result.baseSchedule.last.closingBalance, closeTo(0.0, 1.0));
      expect(result.baseTotalInterest, greaterThan(200000.0));
    });

    test('Prepayment in Month 1 exceeding remaining balance cleanly pays off loan in 1 month', () {
      final config = LoanConfig(
        principal: 5000000,
        annualInterestRate: 8.5,
        tenureMonths: 240,
      );
      final plan = PrepaymentPlan(
        lumpSums: const [
          LumpSumPrepayment(monthIndex: 1, amount: 6000000), // Exceeds 50 Lakhs
        ],
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);
      expect(result.optimizedSchedule.length, 1);
      expect(result.optimizedSchedule.first.closingBalance, 0.0);
      expect(result.monthsSaved, 239);
      expect(result.totalInterestSaved, greaterThan(4000000.0));
      expect(result.optimizedSchedule.first.extraPrepayment, lessThanOrEqualTo(5000000.0)); // Clamped
    });

    test('Prepayment on final month finishes loan cleanly', () {
      final config = LoanConfig(
        principal: 1000000,
        annualInterestRate: 10.0,
        tenureMonths: 12,
      );
      final plan = PrepaymentPlan(
        lumpSums: const [
          LumpSumPrepayment(monthIndex: 12, amount: 500000),
        ],
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);
      expect(result.optimizedSchedule.length, 12);
      expect(result.optimizedSchedule.last.closingBalance, 0.0);
    });

    test('Prepayment on non-existent month (e.g. month 500 on 120 mo loan) is safely ignored', () {
      final config = LoanConfig(
        principal: 1000000,
        annualInterestRate: 10.0,
        tenureMonths: 120,
      );
      final plan = PrepaymentPlan(
        lumpSums: const [
          LumpSumPrepayment(monthIndex: 500, amount: 200000),
        ],
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);
      expect(result.optimizedSchedule.length, 120);
      expect(result.monthsSaved, 0);
      expect(result.totalInterestSaved, 0.0);
    });

    test('Multiple lump sums on the identical month are combined and applied properly', () {
      final config = LoanConfig(
        principal: 3000000,
        annualInterestRate: 9.0,
        tenureMonths: 120,
      );
      final plan = PrepaymentPlan(
        lumpSums: const [
          LumpSumPrepayment(monthIndex: 12, amount: 200000),
          LumpSumPrepayment(monthIndex: 12, amount: 300000),
        ],
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);
      final row12 = result.optimizedSchedule.firstWhere((r) => r.monthIndex == 12);
      expect(row12.extraPrepayment, 500000.0);
      expect(result.monthsSaved, greaterThan(0));
    });

    test('Consecutive monthly lump sums throughout year 1', () {
      final config = LoanConfig(
        principal: 2000000,
        annualInterestRate: 8.5,
        tenureMonths: 120,
      );
      final plan = PrepaymentPlan(
        lumpSums: const [
          LumpSumPrepayment(monthIndex: 1, amount: 50000),
          LumpSumPrepayment(monthIndex: 2, amount: 50000),
          LumpSumPrepayment(monthIndex: 3, amount: 50000),
        ],
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);
      expect(result.optimizedSchedule.length, lessThan(120));
      expect(result.monthsSaved, greaterThan(0));
    });

    test('Stepped EMI + 13th EMI under reduceEmi mode decreases subsequent monthly EMIs', () {
      final config = LoanConfig(
        principal: 5000000,
        annualInterestRate: 8.5,
        tenureMonths: 240,
      );
      final plan = PrepaymentPlan(
        strategyMode: StrategyMode.reduceEmi,
        lumpSums: const [
          LumpSumPrepayment(monthIndex: 12, amount: 1000000),
        ],
      );

      final result = LoanCalculatorEngine.calculate(config: config, plan: plan);
      // Under reduceEmi, tenure remains full 240 months, but EMI after month 12 drops
      expect(result.optimizedSchedule.length, 240);
      final emiMonth10 = result.optimizedSchedule[9].emi;
      final emiMonth14 = result.optimizedSchedule[13].emi;
      expect(emiMonth14, lessThan(emiMonth10));
    });

    test('Date rollover handles leap year (Feb 29) start dates and year turnovers', () {
      final leapConfig = LoanConfig(
        principal: 1000000,
        annualInterestRate: 8.0,
        tenureMonths: 48,
        startDate: DateTime(2024, 2, 29), // Leap day
      );

      final result = LoanCalculatorEngine.calculate(config: leapConfig);
      expect(result.baseSchedule.length, 48);

      // Month 1: Feb 29, 2024
      expect(result.baseSchedule[0].date, DateTime(2024, 2, 29));
      // Month 13: Feb 28, 2025 (clamped because 2025 is not a leap year)
      expect(result.baseSchedule[12].date, DateTime(2025, 2, 28));
      // Month 49: Feb 29, 2028 (leap year)
      expect(result.baseSchedule[47].date.month, 1); // Month 48 is Jan 2028
    });

    test('Date rollover handles Dec 31 start date through months with 30 and 28 days', () {
      final config = LoanConfig(
        principal: 500000,
        annualInterestRate: 8.0,
        tenureMonths: 12,
        startDate: DateTime(2025, 12, 31),
      );

      final result = LoanCalculatorEngine.calculate(config: config);
      expect(result.baseSchedule[0].date, DateTime(2025, 12, 31));
      expect(result.baseSchedule[1].date, DateTime(2026, 1, 31));
      expect(result.baseSchedule[2].date, DateTime(2026, 2, 28)); // Clamped to 28
      expect(result.baseSchedule[3].date, DateTime(2026, 3, 31));
      expect(result.baseSchedule[4].date, DateTime(2026, 4, 30)); // Clamped to 30
    });
  });

  group('OpportunityCostEngine Comprehensive Edge Cases', () {
    test('Non-positive horizon months triggers assertion error and 1 month horizon functions cleanly', () {
      expect(
        () => OpportunityCostParams(
          lumpSumSurplus: 500000,
          monthlySipSurplus: 0,
          expectedAnnualReturn: 12.0,
          horizonMonths: 0,
        ),
        throwsA(isA<AssertionError>()),
      );

      final loanConfig = LoanConfig(principal: 5000000, annualInterestRate: 8.5, tenureMonths: 240);
      final params1m = OpportunityCostParams(
        lumpSumSurplus: 500000,
        monthlySipSurplus: 0,
        expectedAnnualReturn: 12.0,
        horizonMonths: 1,
      );

      final result = OpportunityCostEngine.evaluate(loanConfig: loanConfig, params: params1m);
      expect(result.investedPrincipal, 500000.0);
      expect(result.grossFutureValue, greaterThan(500000.0));
      expect(result.verdict, isNotNull);
    });

    test('Zero surplus amounts returns neutral verdict without errors', () {
      final loanConfig = LoanConfig(principal: 5000000, annualInterestRate: 8.5, tenureMonths: 240);
      final params = OpportunityCostParams(
        lumpSumSurplus: 0,
        monthlySipSurplus: 0,
        expectedAnnualReturn: 12.0,
        horizonMonths: 60,
      );

      final result = OpportunityCostEngine.evaluate(loanConfig: loanConfig, params: params);
      expect(result.investedPrincipal, 0.0);
      expect(result.grossFutureValue, 0.0);
      expect(result.verdict, PrepayVerdict.neutral);
    });

    test('Zero market return (0% CAGR) guarantees prepay loan verdict', () {
      final loanConfig = LoanConfig(principal: 5000000, annualInterestRate: 8.5, tenureMonths: 240);
      final params = OpportunityCostParams(
        lumpSumSurplus: 500000,
        monthlySipSurplus: 10000,
        expectedAnnualReturn: 0.0,
        horizonMonths: 60,
      );

      final result = OpportunityCostEngine.evaluate(loanConfig: loanConfig, params: params);
      expect(result.netInvestmentProfit, 0.0);
      expect(result.verdict, PrepayVerdict.prepayLoan);
    });

    test('LTCG Tax Exemption threshold: gains <= ₹1.25L incur zero tax', () {
      final loanConfig = LoanConfig(principal: 5000000, annualInterestRate: 8.5, tenureMonths: 240);
      // Small investment with gain < 1.25L
      final params = OpportunityCostParams(
        lumpSumSurplus: 100000,
        monthlySipSurplus: 0,
        expectedAnnualReturn: 10.0,
        horizonMonths: 12,
        ltcgExemptionAmount: 125000,
        ltcgTaxRate: 12.5,
      );

      final result = OpportunityCostEngine.evaluate(loanConfig: loanConfig, params: params);
      expect(result.totalGains, lessThan(125000.0));
      expect(result.ltcgTax, 0.0);
    });

    test('LTCG Tax Exemption threshold: gains > ₹1.25L are taxed only on the excess', () {
      final loanConfig = LoanConfig(principal: 5000000, annualInterestRate: 8.5, tenureMonths: 240);
      final params = OpportunityCostParams(
        lumpSumSurplus: 1000000,
        monthlySipSurplus: 0,
        expectedAnnualReturn: 20.0,
        horizonMonths: 60,
        ltcgExemptionAmount: 125000,
        ltcgTaxRate: 12.5,
      );

      final result = OpportunityCostEngine.evaluate(loanConfig: loanConfig, params: params);
      expect(result.totalGains, greaterThan(125000.0));
      final expectedTax = (result.totalGains - 125000.0) * 0.125;
      expect(result.ltcgTax, closeTo(expectedTax, 0.01));
    });

    test('High loan interest rate (15%) vs low market return (8%) favors prepaying loan', () {
      final loanConfig = LoanConfig(principal: 5000000, annualInterestRate: 15.0, tenureMonths: 240);
      final params = OpportunityCostParams(
        lumpSumSurplus: 500000,
        monthlySipSurplus: 0,
        expectedAnnualReturn: 8.0,
        horizonMonths: 60,
      );

      final result = OpportunityCostEngine.evaluate(loanConfig: loanConfig, params: params);
      expect(result.verdict, PrepayVerdict.prepayLoan);
      expect(result.explanation, contains('15.00%'));
    });

    test('High market return (22%) vs low loan rate (7%) favors investing in market', () {
      final loanConfig = LoanConfig(principal: 5000000, annualInterestRate: 7.0, tenureMonths: 240);
      final params = OpportunityCostParams(
        lumpSumSurplus: 500000,
        monthlySipSurplus: 20000,
        expectedAnnualReturn: 22.0,
        horizonMonths: 120,
      );

      final result = OpportunityCostEngine.evaluate(loanConfig: loanConfig, params: params);
      expect(result.verdict, PrepayVerdict.investMarket);
    });
  });

  group('IndianCurrencyFormatter Comprehensive Edge Cases', () {
    test('format formats zero, negatives, and decimals accurately', () {
      expect(IndianCurrencyFormatter.format(0), '₹0');
      expect(IndianCurrencyFormatter.format(-50000), '-₹50,000');
      expect(IndianCurrencyFormatter.format(43391.75, includeDecimals: true), '₹43,391.75');
      expect(IndianCurrencyFormatter.format(5000000), '₹50,00,000');
    });

    test('formatCompact formats across all magnitude thresholds', () {
      expect(IndianCurrencyFormatter.formatCompact(0), '₹0');
      expect(IndianCurrencyFormatter.formatCompact(750), '₹750');
      expect(IndianCurrencyFormatter.formatCompact(43391), '₹43.4K');
      expect(IndianCurrencyFormatter.formatCompact(100000), '₹1.00L');
      expect(IndianCurrencyFormatter.formatCompact(5000000), '₹50.00L');
      expect(IndianCurrencyFormatter.formatCompact(10000000), '₹1.00Cr');
      expect(IndianCurrencyFormatter.formatCompact(1000000000), '₹100.00Cr');
      expect(IndianCurrencyFormatter.formatCompact(-5000000), '-₹50.00L');
      expect(IndianCurrencyFormatter.formatCompact(5000000, includeSymbol: false), '50.00L');
    });

    test('parse parses varied Indian currency formats and edge cases', () {
      expect(IndianCurrencyFormatter.parse('₹50,00,000'), 5000000.0);
      expect(IndianCurrencyFormatter.parse('Rs. 50,00,000'), 5000000.0);
      expect(IndianCurrencyFormatter.parse('INR 50,00,000'), 5000000.0);
      expect(IndianCurrencyFormatter.parse('  ₹ 50,00,000.50  '), 5000000.50);
      expect(IndianCurrencyFormatter.parse(''), 0.0);
      expect(IndianCurrencyFormatter.parse('   '), 0.0);
      expect(IndianCurrencyFormatter.parse('not_a_number'), 0.0);
    });

    test('toWords handles 0, negatives, Lakhs, Crores, and hundreds of Crores', () {
      expect(IndianCurrencyFormatter.toWords(0), 'Zero Rupees');
      expect(IndianCurrencyFormatter.toWords(-5000000), 'Minus Fifty Lakhs Rupees');
      expect(IndianCurrencyFormatter.toWords(5), 'Five Rupees');
      expect(IndianCurrencyFormatter.toWords(18), 'Eighteen Rupees');
      expect(IndianCurrencyFormatter.toWords(72), 'Seventy Two Rupees');
      expect(IndianCurrencyFormatter.toWords(350), 'Three Hundred Fifty Rupees');
      expect(IndianCurrencyFormatter.toWords(5000), 'Five Thousand Rupees');
      expect(IndianCurrencyFormatter.toWords(5000000), 'Fifty Lakhs Rupees');
      expect(IndianCurrencyFormatter.toWords(10000000), 'One Crore Rupees');
      expect(IndianCurrencyFormatter.toWords(25000000), 'Two Crores Fifty Lakhs Rupees');
      // Crores >= 100 test
      expect(IndianCurrencyFormatter.toWords(1000000000), 'One Hundred Crores Rupees');
      expect(IndianCurrencyFormatter.toWords(2500000000), 'Two Hundred Fifty Crores Rupees');
    });
  });

  group('ExportService Comprehensive Edge Cases', () {
    test('generateCsv and generatePdf handle single month loan schedule', () async {
      final config = LoanConfig(
        principal: 100000,
        annualInterestRate: 10.0,
        tenureMonths: 1,
      );
      final result = LoanCalculatorEngine.calculate(config: config);

      final csvContent = ExportService.generateCsv(result);
      expect(csvContent, isNotEmpty);
      expect(csvContent, contains('Month,Year,Date,Opening Balance (INR)'));
      expect(csvContent, contains('Closing Balance (INR)'));
      expect(csvContent, contains('1,1,'));

      final pdfBytes = await ExportService.generatePdf(config: config, result: result);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('generateCsv and generatePdf handle 30-year (360 months) loan schedule', () async {
      final config = LoanConfig(
        principal: 7500000,
        annualInterestRate: 8.5,
        tenureMonths: 360,
      );
      final result = LoanCalculatorEngine.calculate(config: config);

      final csvContent = ExportService.generateCsv(result);
      expect(csvContent, isNotEmpty);
      expect(csvContent, contains('360,'));

      final pdfBytes = await ExportService.generatePdf(config: config, result: result);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
