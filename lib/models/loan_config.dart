enum LoanType {
  home,
  car,
  personal,
  education;

  String get displayName {
    switch (this) {
      case LoanType.home:
        return 'Home Loan';
      case LoanType.car:
        return 'Car Loan';
      case LoanType.personal:
        return 'Personal Loan';
      case LoanType.education:
        return 'Education Loan';
    }
  }
}

enum RateType {
  floating,
  fixed;

  String get displayName {
    switch (this) {
      case RateType.floating:
        return 'Floating';
      case RateType.fixed:
        return 'Fixed';
    }
  }
}

class LoanConfig {
  final double principal;
  final double annualInterestRate;
  final int tenureMonths;
  final DateTime startDate;
  final LoanType loanType;
  final RateType rateType;
  final String name;
  final String loanNumber;

  LoanConfig({
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    DateTime? startDate,
    this.loanType = LoanType.home,
    this.rateType = RateType.floating,
    this.name = 'Prime Home Loan',
    this.loanNumber = '8492',
  })  : startDate = startDate ?? DateTime.now(),
        assert(principal >= 0, 'Principal cannot be negative'),
        assert(annualInterestRate >= 0, 'Interest rate cannot be negative'),
        assert(tenureMonths >= 0, 'Tenure months cannot be negative');

  factory LoanConfig.defaultHomeLoan() {
    return LoanConfig(
      principal: 5000000, // ₹50 Lakhs
      annualInterestRate: 8.5, // 8.5%
      tenureMonths: 240, // 20 years
      startDate: DateTime(2022, 1, 1),
      loanType: LoanType.home,
      rateType: RateType.floating,
      name: 'Prime Home Loan',
      loanNumber: '8492',
    );
  }

  LoanConfig copyWith({
    double? principal,
    double? annualInterestRate,
    int? tenureMonths,
    DateTime? startDate,
    LoanType? loanType,
    RateType? rateType,
    String? name,
    String? loanNumber,
  }) {
    return LoanConfig(
      principal: principal ?? this.principal,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      startDate: startDate ?? this.startDate,
      loanType: loanType ?? this.loanType,
      rateType: rateType ?? this.rateType,
      name: name ?? this.name,
      loanNumber: loanNumber ?? this.loanNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanConfig &&
          runtimeType == other.runtimeType &&
          principal == other.principal &&
          annualInterestRate == other.annualInterestRate &&
          tenureMonths == other.tenureMonths &&
          startDate == other.startDate &&
          loanType == other.loanType &&
          rateType == other.rateType &&
          name == other.name &&
          loanNumber == other.loanNumber;

  @override
  int get hashCode =>
      principal.hashCode ^
      annualInterestRate.hashCode ^
      tenureMonths.hashCode ^
      startDate.hashCode ^
      loanType.hashCode ^
      rateType.hashCode ^
      name.hashCode ^
      loanNumber.hashCode;
}

