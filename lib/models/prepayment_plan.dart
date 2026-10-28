enum StrategyMode {
  reduceTenure,
  reduceEmi;

  String get displayName {
    switch (this) {
      case StrategyMode.reduceTenure:
        return 'Reduce Tenure';
      case StrategyMode.reduceEmi:
        return 'Reduce Monthly EMI';
    }
  }
}

class LumpSumPrepayment {
  final int monthIndex; // 1-based index from start
  final double amount;
  final String note;

  const LumpSumPrepayment({
    required this.monthIndex,
    required this.amount,
    this.note = '',
  })  : assert(monthIndex >= 1, 'Month index must be >= 1'),
        assert(amount >= 0, 'Amount must be >= 0');

  LumpSumPrepayment copyWith({
    int? monthIndex,
    double? amount,
    String? note,
  }) {
    return LumpSumPrepayment(
      monthIndex: monthIndex ?? this.monthIndex,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LumpSumPrepayment &&
          runtimeType == other.runtimeType &&
          monthIndex == other.monthIndex &&
          amount == other.amount &&
          note == other.note;

  @override
  int get hashCode => monthIndex.hashCode ^ amount.hashCode ^ note.hashCode;
}

class PrepaymentPlan {
  final List<LumpSumPrepayment> lumpSums;
  final double steppedEmiPercentage; // e.g., 5.0 for 5% annual step-up
  final bool enableExtraAnnualEmi; // 13th EMI payoff
  final int extraAnnualEmiMonth; // Month in which 13th EMI is paid (1 to 12, default 12)
  final StrategyMode strategyMode;

  const PrepaymentPlan({
    this.lumpSums = const [],
    this.steppedEmiPercentage = 0.0,
    this.enableExtraAnnualEmi = false,
    this.extraAnnualEmiMonth = 12,
    this.strategyMode = StrategyMode.reduceTenure,
  })  : assert(steppedEmiPercentage >= 0, 'Stepped EMI % cannot be negative'),
        assert(extraAnnualEmiMonth >= 1 && extraAnnualEmiMonth <= 12,
            'Extra EMI month must be between 1 and 12');

  factory PrepaymentPlan.empty() {
    return const PrepaymentPlan();
  }

  factory PrepaymentPlan.sample() {
    return const PrepaymentPlan(
      lumpSums: [
        LumpSumPrepayment(monthIndex: 12, amount: 100000, note: 'Diwali Bonus'),
      ],
      steppedEmiPercentage: 5.0,
      enableExtraAnnualEmi: true,
      strategyMode: StrategyMode.reduceTenure,
    );
  }

  PrepaymentPlan copyWith({
    List<LumpSumPrepayment>? lumpSums,
    double? steppedEmiPercentage,
    bool? enableExtraAnnualEmi,
    int? extraAnnualEmiMonth,
    StrategyMode? strategyMode,
  }) {
    return PrepaymentPlan(
      lumpSums: lumpSums ?? this.lumpSums,
      steppedEmiPercentage: steppedEmiPercentage ?? this.steppedEmiPercentage,
      enableExtraAnnualEmi:
          enableExtraAnnualEmi ?? this.enableExtraAnnualEmi,
      extraAnnualEmiMonth:
          extraAnnualEmiMonth ?? this.extraAnnualEmiMonth,
      strategyMode: strategyMode ?? this.strategyMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrepaymentPlan &&
          runtimeType == other.runtimeType &&
          lumpSums == other.lumpSums &&
          steppedEmiPercentage == other.steppedEmiPercentage &&
          enableExtraAnnualEmi == other.enableExtraAnnualEmi &&
          extraAnnualEmiMonth == other.extraAnnualEmiMonth &&
          strategyMode == other.strategyMode;

  @override
  int get hashCode =>
      lumpSums.hashCode ^
      steppedEmiPercentage.hashCode ^
      enableExtraAnnualEmi.hashCode ^
      extraAnnualEmiMonth.hashCode ^
      strategyMode.hashCode;
}

