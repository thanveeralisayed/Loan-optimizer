enum PrepayVerdict {
  prepayLoan,
  investMarket,
  neutral;

  String get title {
    switch (this) {
      case PrepayVerdict.prepayLoan:
        return 'Prepay the Loan First';
      case PrepayVerdict.investMarket:
        return 'Invest Surplus in Market';
      case PrepayVerdict.neutral:
        return 'Mathematically Equivalent';
    }
  }

  String get shortVerdict {
    switch (this) {
      case PrepayVerdict.prepayLoan:
        return 'Prepay';
      case PrepayVerdict.investMarket:
        return 'Invest';
      case PrepayVerdict.neutral:
        return 'Neutral';
    }
  }
}

class OpportunityCostParams {
  final double expectedAnnualReturn; // e.g. 12.0%
  final double ltcgTaxRate; // e.g. 12.5%
  final double ltcgExemptionAmount; // e.g. ₹1,25,000
  final double lumpSumSurplus; // e.g. ₹2,00,000
  final double monthlySipSurplus; // e.g. ₹5,000/mo
  final int horizonMonths; // e.g. 60 or 240

  const OpportunityCostParams({
    this.expectedAnnualReturn = 12.0,
    this.ltcgTaxRate = 12.5,
    this.ltcgExemptionAmount = 125000.0,
    this.lumpSumSurplus = 200000.0,
    this.monthlySipSurplus = 5000.0,
    this.horizonMonths = 60,
  })  : assert(expectedAnnualReturn >= 0, 'Return rate cannot be negative'),
        assert(ltcgTaxRate >= 0, 'LTCG tax rate cannot be negative'),
        assert(horizonMonths > 0, 'Horizon months must be > 0');

  OpportunityCostParams copyWith({
    double? expectedAnnualReturn,
    double? ltcgTaxRate,
    double? ltcgExemptionAmount,
    double? lumpSumSurplus,
    double? monthlySipSurplus,
    int? horizonMonths,
  }) {
    return OpportunityCostParams(
      expectedAnnualReturn: expectedAnnualReturn ?? this.expectedAnnualReturn,
      ltcgTaxRate: ltcgTaxRate ?? this.ltcgTaxRate,
      ltcgExemptionAmount:
          ltcgExemptionAmount ?? this.ltcgExemptionAmount,
      lumpSumSurplus: lumpSumSurplus ?? this.lumpSumSurplus,
      monthlySipSurplus: monthlySipSurplus ?? this.monthlySipSurplus,
      horizonMonths: horizonMonths ?? this.horizonMonths,
    );
  }
}

class OpportunityCostResult {
  final double investedPrincipal;
  final double grossFutureValue;
  final double totalGains;
  final double ltcgTax;
  final double netFutureValue;
  final double netInvestmentProfit;
  final double loanInterestSaved;
  final double netAdvantage; // Positive if Prepay wins, Negative if Invest wins
  final PrepayVerdict verdict;
  final double alphaPercentage;
  final String explanation;

  const OpportunityCostResult({
    required this.investedPrincipal,
    required this.grossFutureValue,
    required this.totalGains,
    required this.ltcgTax,
    required this.netFutureValue,
    required this.netInvestmentProfit,
    required this.loanInterestSaved,
    required this.netAdvantage,
    required this.verdict,
    required this.alphaPercentage,
    required this.explanation,
  });
}
