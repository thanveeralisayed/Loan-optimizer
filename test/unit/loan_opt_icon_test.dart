import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/widgets/app_header.dart';
import 'package:loan_optimizer/core/widgets/loan_opt_icon.dart';

void main() {
  group('LoanOptAppIcon & LoanOptMonochromePainter Tests', () {
    testWidgets('renders default 28px LoanOptAppIcon without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoanOptAppIcon(),
            ),
          ),
        ),
      );

      expect(find.byType(LoanOptAppIcon), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.bySemanticsLabel('LoanOpt'), findsOneWidget);

      final iconBox = tester.renderObject(find.byType(LoanOptAppIcon)) as RenderBox;
      expect(iconBox.size, equals(const Size(28, 28)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders across various sizes (20, 28, 48, 64, 128, 512) cleanly', (tester) async {
      const sizes = [20.0, 28.0, 48.0, 64.0, 128.0, 512.0];

      for (final s in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: LoanOptAppIcon(size: s),
              ),
            ),
          ),
        );

        expect(find.byType(LoanOptAppIcon), findsOneWidget);
        final box = tester.renderObject(find.byType(LoanOptAppIcon)) as RenderBox;
        expect(box.size, equals(Size(s, s)));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('supports customization: backgroundColor, foregroundColor, showBorder, borderWidth', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoanOptAppIcon(
                size: 56,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                showBorder: false,
                borderWidth: 2.0,
                semanticLabel: 'Custom Brand Icon',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LoanOptAppIcon), findsOneWidget);
      expect(find.bySemanticsLabel('Custom Brand Icon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('LoanOptMonochromePainter shouldRepaint contracts', () {
      const p1 = LoanOptMonochromePainter();
      const p2 = LoanOptMonochromePainter();
      expect(p1.shouldRepaint(p2), isFalse);

      const p3 = LoanOptMonochromePainter(borderWidth: 4.0);
      expect(p1.shouldRepaint(p3), isTrue);

      const p4 = LoanOptMonochromePainter(showBorder: false);
      expect(p1.shouldRepaint(p4), isTrue);

      const p5 = LoanOptMonochromePainter(backgroundColor: Colors.red);
      expect(p1.shouldRepaint(p5), isTrue);

      const p6 = LoanOptMonochromePainter(foregroundColor: Colors.blue);
      expect(p1.shouldRepaint(p6), isTrue);
    });

    testWidgets('AppHeader displays LoanOptAppIcon when showLogo is true', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppHeader(
                title: 'LoanOpt',
                showLogo: true,
              ),
              body: SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(LoanOptAppIcon), findsOneWidget);
      expect(find.text('LoanOpt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppHeader hides LoanOptAppIcon when showLogo is false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppHeader(
                title: 'LoanOpt',
                showLogo: false,
              ),
              body: SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(LoanOptAppIcon), findsNothing);
      expect(find.text('LoanOpt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

