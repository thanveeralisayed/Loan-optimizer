import 'dart:math';
import '../models/loan_config.dart';
import '../models/opportunity_cost_models.dart';
import '../models/prepayment_plan.dart';
import 'loan_calculator_engine.dart';

class OpportunityCostEngine {
  /// Evaluates whether the borrower should prepay their loan or invest surplus capital in equity/index fund
  static OpportunityCostResult evaluate({
    required LoanConfig loanConfig,
    required OpportunityCostParams params,
  }) {
    final int horizonMonths = params.horizonMonths;
    final double horizonYears = horizonMonths / 12.0;

    // 1. Calculate Investment Returns (Equity / Nifty 50)
    final double annualReturnRate = params.expectedAnnualReturn / 100.0;
    final double monthlyReturnRate = annualReturnRate / 12.0;

    // Lump sum growth
    final double lumpSumPrincipal = params.lumpSumSurplus;
    final double lumpSumFv = lumpSumPrincipal * pow(1 + annualReturnRate, horizonYears);

    // Monthly SIP growth
    final double monthlySipPrincipal = params.monthlySipSurplus;
    double sipFv = 0.0;
    if (monthlySipPrincipal > 0 && monthlyReturnRate > 0) {
      sipFv = monthlySipPrincipal *
          (pow(1 + monthlyReturnRate, horizonMonths) - 1) /
          monthlyReturnRate *
          (1 + monthlyReturnRate);
    } else if (monthlySipPrincipal > 0) {
      sipFv = monthlySipPrincipal * horizonMonths;
    }

    final double totalInvestedPrincipal =
        lumpSumPrincipal + (monthlySipPrincipal * horizonMonths);
    final double grossFutureValue = lumpSumFv + sipFv;
    final double totalGains = max(0.0, grossFutureValue - totalInvestedPrincipal);

    // Indian LTCG Tax Calculation (12.5% on gains exceeding exemption limit)
    final double taxableGains = max(0.0, totalGains - params.ltcgExemptionAmount);
    final double ltcgTax = taxableGains * (params.ltcgTaxRate / 100.0);
    final double netFutureValue = grossFutureValue - ltcgTax;
    final double netInvestmentProfit = max(0.0, netFutureValue - totalInvestedPrincipal);

    // 2. Calculate Exact Loan Interest Saved via Prepayment
    // Simulate loan without prepayment vs with this surplus injected as prepayment
    final planWithSurplus = PrepaymentPlan(
      lumpSums: [
        if (lumpSumPrincipal > 0)
          LumpSumPrepayment(monthIndex: 1, amount: lumpSumPrincipal),
      ],
      // If there's a monthly SIP surplus, we can approximate its loan tenure reduction or compare directly
      strategyMode: StrategyMode.reduceTenure,
    );

    final loanResult = LoanCalculatorEngine.calculate(
      config: loanConfig,
      plan: planWithSurplus,
    );

    // Interest saved by prepaying the lump sum
    double loanInterestSaved = loanResult.totalInterestSaved;

    // If lump sum alone is small or horizon is shorter than loan, calculate horizon-based interest savings
    if (loanInterestSaved <= 0 && lumpSumPrincipal > 0) {
      // Compounded interest saving estimation over horizon
      final monthlyLoanRate = loanConfig.annualInterestRate / (12 * 100);
      loanInterestSaved = lumpSumPrincipal * (pow(1 + monthlyLoanRate, horizonMonths) - 1);
    }

    // 3. Comparison & Mathematical Verdict
    // Prepaying loan saves guaranteed post-tax interest (risk-free).
    // Market investment is volatile and subject to sequence-of-returns risk.
    // Net advantage = Loan Interest Saved vs Net Investment Profit
    final double delta = loanInterestSaved - netInvestmentProfit;
    final double netAdvantage = delta.abs();

    PrepayVerdict verdict;
    String explanation;
    double alphaPercentage;

    if (loanInterestSaved > netInvestmentProfit) {
      verdict = PrepayVerdict.prepayLoan;
      alphaPercentage = netInvestmentProfit > 0
          ? ((loanInterestSaved - netInvestmentProfit) / netInvestmentProfit) * 100
          : 100.0;
      explanation =
          'Guaranteed ${loanConfig.annualInterestRate.toStringAsFixed(2)}% tax-free '
          'interest saving mathematically beats a volatile ${params.expectedAnnualReturn.toStringAsFixed(2)}% CAGR '
          'after applying the mandatory ${params.ltcgTaxRate.toStringAsFixed(1)}% LTCG tax drag '
          '& sequence-of-returns risk over $horizonMonths months.';
    } else if (netInvestmentProfit > loanInterestSaved * 1.15) {
      // Margin of at least 15% to compensate for equity market risk
      verdict = PrepayVerdict.investMarket;
      alphaPercentage = loanInterestSaved > 0
          ? ((netInvestmentProfit - loanInterestSaved) / loanInterestSaved) * 100
          : 100.0;
      explanation =
          'Expected market returns at ${params.expectedAnnualReturn.toStringAsFixed(2)}% CAGR generate a net wealth '
          'delta that exceeds loan savings by +${alphaPercentage.toStringAsFixed(1)}% even after 12.5% LTCG tax.';
    } else {
      verdict = PrepayVerdict.neutral;
      alphaPercentage = 0.0;
      explanation =
          'Loan interest savings and post-tax equity corpus are nearly identical within risk tolerance margins. '
          'Consider splitting surplus 50/50 between debt reduction and equity SIP.';
    }

    return OpportunityCostResult(
      investedPrincipal: totalInvestedPrincipal,
      grossFutureValue: grossFutureValue,
      totalGains: totalGains,
      ltcgTax: ltcgTax,
      netFutureValue: netFutureValue,
      netInvestmentProfit: netInvestmentProfit,
      loanInterestSaved: loanInterestSaved,
      netAdvantage: netAdvantage,
      verdict: verdict,
      alphaPercentage: alphaPercentage,
      explanation: explanation,
    );
  }
}

