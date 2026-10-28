import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/main.dart';

void main() {
  testWidgets('LoanOpt app root launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LoanOptimizerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LoanOpt'), findsWidgets);
    expect(find.text('Prime Home Loan'), findsOneWidget);
    expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);
  });
}
