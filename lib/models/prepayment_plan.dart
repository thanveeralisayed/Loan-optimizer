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

class StrategyBlueprint {
  final String id;
  final String name;
  final String description;
  final String versionTag;
  final PrepaymentPlan plan;
  final bool isSystem;
  final DateTime createdAt;
  final String iconKey;

  const StrategyBlueprint({
    required this.id,
    required this.name,
    required this.description,
    this.versionTag = 'v1.0',
    required this.plan,
    this.isSystem = false,
    required this.createdAt,
    this.iconKey = 'trending_up',
  });

  StrategyBlueprint copyWith({
    String? id,
    String? name,
    String? description,
    String? versionTag,
    PrepaymentPlan? plan,
    bool? isSystem,
    DateTime? createdAt,
    String? iconKey,
  }) {
    return StrategyBlueprint(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      versionTag: versionTag ?? this.versionTag,
      plan: plan ?? this.plan,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  static List<StrategyBlueprint> systemPresets() {
    final now = DateTime(2025, 1, 1);
    return [
      StrategyBlueprint(
        id: 'system-aggressive',
        name: 'Aggressive Freedom',
        description:
            'Save maximum interest by 5% annual step-up + ₹1,00,000 yearly bonus prepayment.',
        versionTag: 'v1.0',
        isSystem: true,
        createdAt: now,
        iconKey: 'rocket',
        plan: const PrepaymentPlan(
          lumpSums: [
            LumpSumPrepayment(
                monthIndex: 12, amount: 100000, note: 'Annual Bonus'),
          ],
          steppedEmiPercentage: 5.0,
          enableExtraAnnualEmi: true,
          strategyMode: StrategyMode.reduceTenure,
        ),
      ),
      StrategyBlueprint(
        id: 'system-balanced',
        name: 'Balanced Wealth',
        description:
            'Prepay 1 extra EMI every year; invest remaining monthly surplus in disciplined equity funds.',
        versionTag: 'v1.0',
        isSystem: true,
        createdAt: now,
        iconKey: 'scale',
        plan: const PrepaymentPlan(
          lumpSums: [],
          steppedEmiPercentage: 0.0,
          enableExtraAnnualEmi: true,
          strategyMode: StrategyMode.reduceTenure,
        ),
      ),
      StrategyBlueprint(
        id: 'system-relief',
        name: 'Minimum EMI Relief',
        description:
            'Protect cash flow: recalibrate monthly burden lower whenever unscheduled prepayments clear.',
        versionTag: 'v1.0',
        isSystem: true,
        createdAt: now,
        iconKey: 'shield',
        plan: const PrepaymentPlan(
          lumpSums: [
            LumpSumPrepayment(
                monthIndex: 12, amount: 100000, note: 'Prepayment'),
          ],
          steppedEmiPercentage: 0.0,
          enableExtraAnnualEmi: false,
          strategyMode: StrategyMode.reduceEmi,
        ),
      ),
    ];
  }

  static List<StrategyBlueprint> defaultSavedPresets() {
    final now = DateTime(2025, 1, 1);
    return [
      StrategyBlueprint(
        id: 'saved-diwali-7pct',
        name: 'Diwali Bonus + 7% Step-Up',
        description:
            'Configured for Home Loan • ₹1.5L annual lump sum + 7% step-up',
        versionTag: 'v2.1',
        isSystem: false,
        createdAt: now,
        iconKey: 'trending_up',
        plan: const PrepaymentPlan(
          lumpSums: [
            LumpSumPrepayment(
                monthIndex: 12, amount: 150000, note: 'Diwali Bonus'),
          ],
          steppedEmiPercentage: 7.0,
          enableExtraAnnualEmi: true,
          strategyMode: StrategyMode.reduceTenure,
        ),
      ),
      StrategyBlueprint(
        id: 'saved-biannual-surplus',
        name: 'Bi-Annual Surplus Payoff',
        description:
            '₹1.0L prepayment every 6 months • 5% step-up',
        versionTag: 'v1.4',
        isSystem: false,
        createdAt: now,
        iconKey: 'savings',
        plan: const PrepaymentPlan(
          lumpSums: [
            LumpSumPrepayment(
                monthIndex: 6, amount: 100000, note: 'Mid-year'),
            LumpSumPrepayment(
                monthIndex: 12, amount: 100000, note: 'Year-end'),
          ],
          steppedEmiPercentage: 5.0,
          enableExtraAnnualEmi: false,
          strategyMode: StrategyMode.reduceTenure,
        ),
      ),
      StrategyBlueprint(
        id: 'saved-conservative-step',
        name: 'Conservative Step-Up Only',
        description:
            'No lump sum withdrawals • Consistent 5% annual EMI elevation',
        versionTag: 'v1.0',
        isSystem: false,
        createdAt: now,
        iconKey: 'tune',
        plan: const PrepaymentPlan(
          lumpSums: [],
          steppedEmiPercentage: 5.0,
          enableExtraAnnualEmi: false,
          strategyMode: StrategyMode.reduceTenure,
        ),
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrategyBlueprint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          versionTag == other.versionTag &&
          plan == other.plan &&
          isSystem == other.isSystem &&
          iconKey == other.iconKey;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      versionTag.hashCode ^
      plan.hashCode ^
      isSystem.hashCode ^
      iconKey.hashCode;
}

