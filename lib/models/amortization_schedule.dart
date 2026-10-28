class AmortizationRow {
  final int monthIndex; // 1-based index from start
  final int yearIndex; // 1-based year (1, 2, 3...)
  final DateTime date;
  final double openingBalance;
  final double emi;
  final double principalPaid;
  final double interestPaid;
  final double extraPrepayment;
  final double closingBalance;

  const AmortizationRow({
    required this.monthIndex,
    required this.yearIndex,
    required this.date,
    required this.openingBalance,
    required this.emi,
    required this.principalPaid,
    required this.interestPaid,
    required this.extraPrepayment,
    required this.closingBalance,
  });

  double get totalPrincipalComponent => principalPaid + extraPrepayment;
  double get totalOutflow => emi + extraPrepayment;
}

class YearlyAmortizationSummary {
  final int yearIndex; // 1, 2, 3...
  final int yearNumber; // e.g. 2022
  final double openingBalance;
  final double totalEmiPaid;
  final double totalPrincipalPaid;
  final double totalInterestPaid;
  final double totalPrepaymentPaid;
  final double closingBalance;
  final bool isCompleted;
  final List<AmortizationRow> monthlyRows;

  const YearlyAmortizationSummary({
    required this.yearIndex,
    required this.yearNumber,
    required this.openingBalance,
    required this.totalEmiPaid,
    required this.totalPrincipalPaid,
    required this.totalInterestPaid,
    required this.totalPrepaymentPaid,
    required this.closingBalance,
    required this.isCompleted,
    required this.monthlyRows,
  });

  double get totalOutflow => totalEmiPaid + totalPrepaymentPaid;
  double get totalPrincipalReduced => totalPrincipalPaid + totalPrepaymentPaid;
}

class LoanAmortizationResult {
  final List<AmortizationRow> baseSchedule;
  final List<AmortizationRow> optimizedSchedule;
  final List<YearlyAmortizationSummary> yearlySummaries;
  final double baseMonthlyEmi;
  final double totalPrincipal;
  final double baseTotalInterest;
  final double optimizedTotalInterest;
  final double totalInterestSaved;
  final int originalTenureMonths;
  final int optimizedTenureMonths;
  final int monthsSaved;
  final DateTime originalEndDate;
  final DateTime optimizedEndDate;
  final double savingsPercentage;

  const LoanAmortizationResult({
    required this.baseSchedule,
    required this.optimizedSchedule,
    required this.yearlySummaries,
    required this.baseMonthlyEmi,
    required this.totalPrincipal,
    required this.baseTotalInterest,
    required this.optimizedTotalInterest,
    required this.totalInterestSaved,
    required this.originalTenureMonths,
    required this.optimizedTenureMonths,
    required this.monthsSaved,
    required this.originalEndDate,
    required this.optimizedEndDate,
    required this.savingsPercentage,
  });

  double get baseTotalOutflow => totalPrincipal + baseTotalInterest;
  double get optimizedTotalOutflow => totalPrincipal + optimizedTotalInterest;
}
