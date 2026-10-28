import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/models/loan_config.dart';
import 'package:loan_optimizer/models/opportunity_cost_models.dart';
import 'package:loan_optimizer/services/opportunity_cost_engine.dart';

void main() {
  group('OpportunityCostEngine Tests', () {
    final loanConfig = LoanConfig.defaultHomeLoan(); // 8.5% interest

    test('High loan interest vs modest market return favors prepaying loan', () {
      final highRateLoan = loanConfig.copyWith(annualInterestRate: 14.0); // 14% personal/car loan
      const params = OpportunityCostParams(
        expectedAnnualReturn: 9.0, // 9% market return
        horizonMonths: 60,
        lumpSumSurplus: 200000,
        monthlySipSurplus: 0,
      );

      final result = OpportunityCostEngine.evaluate(
        loanConfig: highRateLoan,
        params: params,
      );

      expect(result.verdict, PrepayVerdict.prepayLoan);
      expect(result.netAdvantage, greaterThan(0));
      expect(result.loanInterestSaved, greaterThan(result.netInvestmentProfit));
    });

    test('LTCG Tax Calculation with exemption limit', () {
      const params = OpportunityCostParams(
        expectedAnnualReturn: 15.0,
        horizonMonths: 120, // 10 years
        lumpSumSurplus: 500000,
        monthlySipSurplus: 10000,
        ltcgTaxRate: 12.5,
        ltcgExemptionAmount: 125000,
      );

      final result = OpportunityCostEngine.evaluate(
        loanConfig: loanConfig,
        params: params,
      );

      expect(result.totalGains, greaterThan(params.ltcgExemptionAmount));
      expect(result.ltcgTax, greaterThan(0));
      expect(result.netFutureValue, lessThan(result.grossFutureValue));
      expect(result.netInvestmentProfit, equals(result.netFutureValue - result.investedPrincipal));
    });

    test('Extremely high market return with low loan interest favors investing', () {
      final lowRateLoan = loanConfig.copyWith(annualInterestRate: 6.0);
      const params = OpportunityCostParams(
        expectedAnnualReturn: 22.0, // High CAGR equity
        horizonMonths: 60,
        lumpSumSurplus: 100000,
        monthlySipSurplus: 10000,
      );

      final result = OpportunityCostEngine.evaluate(
        loanConfig: lowRateLoan,
        params: params,
      );

      expect(result.verdict, PrepayVerdict.investMarket);
      expect(result.netInvestmentProfit, greaterThan(result.loanInterestSaved));
    });

    test('Zero surplus edge case', () {
      const params = OpportunityCostParams(
        expectedAnnualReturn: 12.0,
        horizonMonths: 60,
        lumpSumSurplus: 0,
        monthlySipSurplus: 0,
      );

      final result = OpportunityCostEngine.evaluate(
        loanConfig: loanConfig,
        params: params,
      );

      expect(result.investedPrincipal, 0.0);
      expect(result.grossFutureValue, 0.0);
      expect(result.netInvestmentProfit, 0.0);
    });
  });
}
