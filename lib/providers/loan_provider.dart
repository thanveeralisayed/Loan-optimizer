import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_config.dart';
import '../models/prepayment_plan.dart';
import '../models/amortization_schedule.dart';
import '../models/opportunity_cost_models.dart';
import '../services/loan_calculator_engine.dart';
import '../services/opportunity_cost_engine.dart';

class LoanConfigNotifier extends Notifier<LoanConfig> {
  @override
  LoanConfig build() {
    return LoanConfig.defaultHomeLoan();
  }

  void updatePrincipal(double amount) {
    if (amount < 0) return;
    state = state.copyWith(principal: amount);
  }

  void adjustPrincipal(double delta) {
    final newAmount = (state.principal + delta).clamp(0.0, 1000000000.0);
    state = state.copyWith(principal: newAmount);
  }

  void updateRate(double rate) {
    if (rate < 0) return;
    state = state.copyWith(annualInterestRate: rate);
  }

  void updateTenureMonths(int months) {
    if (months <= 0) return;
    state = state.copyWith(tenureMonths: months);
  }

  void adjustTenureYears(int deltaYears) {
    final newTenure = (state.tenureMonths + (deltaYears * 12)).clamp(12, 600);
    state = state.copyWith(tenureMonths: newTenure);
  }

  void updateLoanType(LoanType type) {
    state = state.copyWith(loanType: type);
  }

  void updateRateType(RateType type) {
    state = state.copyWith(rateType: type);
  }
}

final loanConfigProvider =
    NotifierProvider<LoanConfigNotifier, LoanConfig>(LoanConfigNotifier.new);

class PrepaymentPlanNotifier extends Notifier<PrepaymentPlan> {
  @override
  PrepaymentPlan build() {
    // Default with common real-life parameters from Stitch design
    return const PrepaymentPlan(
      lumpSums: [
        LumpSumPrepayment(monthIndex: 12, amount: 100000, note: 'Annual Bonus'),
      ],
      steppedEmiPercentage: 5.0,
      enableExtraAnnualEmi: true,
      strategyMode: StrategyMode.reduceTenure,
    );
  }

  void setLumpSumAmount(double amount, {int monthIndex = 12}) {
    final updated = List<LumpSumPrepayment>.from(state.lumpSums);
    updated.removeWhere((l) => l.monthIndex == monthIndex);
    if (amount > 0) {
      updated.add(LumpSumPrepayment(monthIndex: monthIndex, amount: amount));
    }
    state = state.copyWith(lumpSums: updated);
  }

  void setSteppedEmiPercentage(double percent) {
    state = state.copyWith(steppedEmiPercentage: percent.clamp(0.0, 50.0));
  }

  void toggleExtraAnnualEmi(bool enable) {
    state = state.copyWith(enableExtraAnnualEmi: enable);
  }

  void setStrategyMode(StrategyMode mode) {
    state = state.copyWith(strategyMode: mode);
  }
}

final prepaymentPlanProvider =
    NotifierProvider<PrepaymentPlanNotifier, PrepaymentPlan>(
        PrepaymentPlanNotifier.new);

final amortizationResultProvider = Provider<LoanAmortizationResult>((ref) {
  final config = ref.watch(loanConfigProvider);
  final plan = ref.watch(prepaymentPlanProvider);
  return LoanCalculatorEngine.calculate(config: config, plan: plan);
});

class OpportunityCostParamsNotifier extends Notifier<OpportunityCostParams> {
  @override
  OpportunityCostParams build() {
    return const OpportunityCostParams(
      expectedAnnualReturn: 12.0,
      ltcgTaxRate: 12.5,
      ltcgExemptionAmount: 125000.0,
      lumpSumSurplus: 200000.0,
      monthlySipSurplus: 5000.0,
      horizonMonths: 60,
    );
  }

  void updateExpectedReturn(double rate) {
    state = state.copyWith(expectedAnnualReturn: rate);
  }

  void updateSurplus({double? lumpSum, double? monthlySip}) {
    state = state.copyWith(
      lumpSumSurplus: lumpSum ?? state.lumpSumSurplus,
      monthlySipSurplus: monthlySip ?? state.monthlySipSurplus,
    );
  }

  void updateHorizonMonths(int months) {
    state = state.copyWith(horizonMonths: months);
  }
}

final opportunityCostParamsProvider =
    NotifierProvider<OpportunityCostParamsNotifier, OpportunityCostParams>(
        OpportunityCostParamsNotifier.new);

final opportunityCostResultProvider = Provider<OpportunityCostResult>((ref) {
  final config = ref.watch(loanConfigProvider);
  final params = ref.watch(opportunityCostParamsProvider);
  return OpportunityCostEngine.evaluate(loanConfig: config, params: params);
});
