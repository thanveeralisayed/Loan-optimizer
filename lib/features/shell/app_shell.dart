import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../comparator/opportunity_cost_screen.dart';
import '../dashboard/loan_overview_screen.dart';
import '../loan_setup/loan_setup_screen.dart';
import '../schedule/amortization_schedule_screen.dart';
import '../simulator/prepayment_strategy_simulator_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      LoanOverviewScreen(
        onNavigateToSimulator: () => _navigateToTab(1),
        onNavigateToComparator: () => _navigateToTab(2),
        onNavigateToSchedule: () => _navigateToTab(3),
      ),
      PrepaymentStrategySimulatorScreen(
        onApply: () => _navigateToTab(0),
      ),
      const OpportunityCostScreen(),
      const AmortizationScheduleScreen(),
      LoanSetupScreen(
        onSaved: () => _navigateToTab(0),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          backgroundColor: AppColors.surfaceContainerLowest,
          selectedItemColor: AppColors.tertiary,
          unselectedItemColor: AppColors.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          unselectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Simulator',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Compare',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'Setup',
            ),
          ],
        ),
      ),
    );
  }
}

