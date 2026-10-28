import 'dart:math';
import '../models/loan_config.dart';
import '../models/prepayment_plan.dart';
import '../models/amortization_schedule.dart';

class LoanCalculatorEngine {
  /// Calculates standard Monthly EMI
  /// P: Principal
  /// annualRate: Annual interest rate in percentage (e.g., 8.5 for 8.5%)
  /// tenureMonths: Total tenure in months
  static double calculateEmi({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return 0.0;
    if (annualRate <= 0) {
      // 0% interest rate loan
      return principal / tenureMonths;
    }

    final double monthlyRate = annualRate / (12 * 100);
    final double compoundFactor = pow(1 + monthlyRate, tenureMonths).toDouble();
    if (compoundFactor == 1.0) return principal / tenureMonths;

    final double emi = principal * monthlyRate * compoundFactor / (compoundFactor - 1);
    return emi;
  }

  /// Calculates total loan payoff result and amortization schedule
  static LoanAmortizationResult calculate({
    required LoanConfig config,
    PrepaymentPlan plan = const PrepaymentPlan(),
    DateTime? calculationDate,
  }) {
    final now = calculationDate ?? DateTime.now();

    // 1. Calculate Base Schedule (No Prepayments)
    final baseSchedule = _generateSchedule(
      principal: config.principal,
      annualRate: config.annualInterestRate,
      tenureMonths: config.tenureMonths,
      startDate: config.startDate,
      plan: const PrepaymentPlan(),
    );

    // 2. Calculate Optimized Schedule (With Prepayments)
    final optimizedSchedule = _generateSchedule(
      principal: config.principal,
      annualRate: config.annualInterestRate,
      tenureMonths: config.tenureMonths,
      startDate: config.startDate,
      plan: plan,
    );

    // Base Metrics
    final double baseMonthlyEmi = calculateEmi(
      principal: config.principal,
      annualRate: config.annualInterestRate,
      tenureMonths: config.tenureMonths,
    );

    final double baseTotalInterest = baseSchedule.fold<double>(
      0.0,
      (sum, row) => sum + row.interestPaid,
    );

    final double optimizedTotalInterest = optimizedSchedule.fold<double>(
      0.0,
      (sum, row) => sum + row.interestPaid,
    );

    final double totalInterestSaved = max(0.0, baseTotalInterest - optimizedTotalInterest);
    final int originalTenureMonths = baseSchedule.length;
    final int optimizedTenureMonths = optimizedSchedule.length;
    final int monthsSaved = max(0, originalTenureMonths - optimizedTenureMonths);

    final originalEndDate = baseSchedule.isNotEmpty
        ? baseSchedule.last.date
        : config.startDate;

    final optimizedEndDate = optimizedSchedule.isNotEmpty
        ? optimizedSchedule.last.date
        : config.startDate;

    final double savingsPercentage = baseTotalInterest > 0
        ? (totalInterestSaved / baseTotalInterest) * 100
        : 0.0;

    // 3. Generate Yearly Summaries for Optimized Schedule
    final yearlySummaries = _generateYearlySummaries(
      schedule: optimizedSchedule,
      currentDate: now,
    );

    return LoanAmortizationResult(
      baseSchedule: baseSchedule,
      optimizedSchedule: optimizedSchedule,
      yearlySummaries: yearlySummaries,
      baseMonthlyEmi: baseMonthlyEmi,
      totalPrincipal: config.principal,
      baseTotalInterest: baseTotalInterest,
      optimizedTotalInterest: optimizedTotalInterest,
      totalInterestSaved: totalInterestSaved,
      originalTenureMonths: originalTenureMonths,
      optimizedTenureMonths: optimizedTenureMonths,
      monthsSaved: monthsSaved,
      originalEndDate: originalEndDate,
      optimizedEndDate: optimizedEndDate,
      savingsPercentage: savingsPercentage,
    );
  }

  /// Internal schedule generator
  static List<AmortizationRow> _generateSchedule({
    required double principal,
    required double annualRate,
    required int tenureMonths,
    required DateTime startDate,
    required PrepaymentPlan plan,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return [];

    final double monthlyRate = annualRate / (12 * 100);
    double initialEmi = calculateEmi(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );

    // Map month index to lump sum amounts (aggregated if multiple for same month)
    final Map<int, double> lumpSumMap = {};
    for (final lump in plan.lumpSums) {
      if (lump.monthIndex > 0 && lump.amount > 0) {
        lumpSumMap[lump.monthIndex] = (lumpSumMap[lump.monthIndex] ?? 0.0) + lump.amount;
      }
    }

    final List<AmortizationRow> rows = [];
    double balance = principal;
    double currentEmi = initialEmi;

    // In reduceTenure mode, maximum iteration can't exceed original tenure.
    // In reduceEmi mode, iteration runs up to original tenure.
    final maxIterations = tenureMonths + 120; // safety ceiling

    for (int month = 1; month <= maxIterations && balance > 0.01; month++) {
      final rowDate = _addMonthsClamped(startDate, month - 1);
      final yearIndex = ((month - 1) ~/ 12) + 1;

      // Check stepped EMI (applied annually at month 13, 25, 37, ...)
      if (plan.steppedEmiPercentage > 0 && month > 1 && (month - 1) % 12 == 0) {
        currentEmi = currentEmi * (1 + plan.steppedEmiPercentage / 100);
      }

      final openingBalance = balance;
      final interest = monthlyRate > 0 ? openingBalance * monthlyRate : 0.0;

      // Regular EMI principal component
      double principalComponent = currentEmi - interest;
      double scheduledEmi = currentEmi;

      // Handle extra annual 13th EMI
      double extraAnnualEmi = 0.0;
      if (plan.enableExtraAnnualEmi && (month % 12 == plan.extraAnnualEmiMonth % 12)) {
        extraAnnualEmi = currentEmi;
      }

      // Handle lump-sum prepayment for this month
      final lumpSum = lumpSumMap[month] ?? 0.0;
      double totalExtraPrepayment = lumpSum + extraAnnualEmi;

      // Check if normal EMI alone exceeds or finishes remaining balance
      if (openingBalance + interest <= currentEmi) {
        // Last payment
        scheduledEmi = openingBalance + interest;
        principalComponent = openingBalance;
        totalExtraPrepayment = 0.0;
        balance = 0.0;
      } else {
        // Regular month
        balance = openingBalance - principalComponent;

        // Apply extra prepayment
        if (totalExtraPrepayment > balance) {
          totalExtraPrepayment = balance;
          balance = 0.0;
        } else {
          balance -= totalExtraPrepayment;
        }

        // If strategy is reduceEmi and a lump sum occurred, recalculate EMI for remaining months
        if (plan.strategyMode == StrategyMode.reduceEmi &&
            totalExtraPrepayment > 0 &&
            balance > 0.01) {
          final remainingTenure = tenureMonths - month;
          if (remainingTenure > 0) {
            currentEmi = calculateEmi(
              principal: balance,
              annualRate: annualRate,
              tenureMonths: remainingTenure,
            );
          }
        }
      }

      rows.add(AmortizationRow(
        monthIndex: month,
        yearIndex: yearIndex,
        date: rowDate,
        openingBalance: openingBalance,
        emi: scheduledEmi,
        principalPaid: principalComponent,
        interestPaid: interest,
        extraPrepayment: totalExtraPrepayment,
        closingBalance: max(0.0, balance),
      ));

      if (balance <= 0.01) break;
    }

    return rows;
  }

  /// Aggregates monthly rows into yearly summaries
  static List<YearlyAmortizationSummary> _generateYearlySummaries({
    required List<AmortizationRow> schedule,
    required DateTime currentDate,
  }) {
    if (schedule.isEmpty) return [];

    final Map<int, List<AmortizationRow>> yearGroups = {};
    for (final row in schedule) {
      yearGroups.putIfAbsent(row.yearIndex, () => []).add(row);
    }

    final List<YearlyAmortizationSummary> summaries = [];

    yearGroups.forEach((yearIndex, rows) {
      final firstRow = rows.first;
      final lastRow = rows.last;

      final double totalEmi = rows.fold(0.0, (sum, r) => sum + r.emi);
      final double totalPrincipal = rows.fold(0.0, (sum, r) => sum + r.principalPaid);
      final double totalInterest = rows.fold(0.0, (sum, r) => sum + r.interestPaid);
      final double totalPrepayment = rows.fold(0.0, (sum, r) => sum + r.extraPrepayment);

      final isCompleted = lastRow.date.isBefore(currentDate);

      summaries.add(YearlyAmortizationSummary(
        yearIndex: yearIndex,
        yearNumber: firstRow.date.year,
        openingBalance: firstRow.openingBalance,
        totalEmiPaid: totalEmi,
        totalPrincipalPaid: totalPrincipal,
        totalInterestPaid: totalInterest,
        totalPrepaymentPaid: totalPrepayment,
        closingBalance: lastRow.closingBalance,
        isCompleted: isCompleted,
        monthlyRows: rows,
      ));
    });

    return summaries;
  }

  /// Adds months to a DateTime without overflowing day of month
  static DateTime _addMonthsClamped(DateTime date, int monthsToAdd) {
    int year = date.year + (date.month - 1 + monthsToAdd) ~/ 12;
    int month = (date.month - 1 + monthsToAdd) % 12 + 1;
    int day = min(date.day, _daysInMonth(year, month));
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }

  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month];
  }
}

