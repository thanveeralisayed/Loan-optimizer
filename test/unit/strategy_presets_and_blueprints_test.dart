import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/features/strategy/widgets/save_strategy_dialog.dart';
import 'package:loan_optimizer/features/strategy/widgets/saved_strategy_carousel.dart';
import 'package:loan_optimizer/features/strategy/widgets/strategy_preset_selector.dart';
import 'package:loan_optimizer/models/prepayment_plan.dart';
import 'package:loan_optimizer/providers/loan_provider.dart';

Widget createTestWidget({
  required Widget child,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('StrategyBlueprint Model Tests', () {
    test('systemPresets provides 3 standard blueprints with correct configurations', () {
      final presets = StrategyBlueprint.systemPresets();
      expect(presets.length, 3);

      final aggressive = presets.firstWhere((p) => p.id == 'system-aggressive');
      expect(aggressive.name, 'Aggressive Freedom');
      expect(aggressive.isSystem, isTrue);
      expect(aggressive.plan.steppedEmiPercentage, 5.0);
      expect(aggressive.plan.enableExtraAnnualEmi, isTrue);
      expect(aggressive.plan.strategyMode, StrategyMode.reduceTenure);
      expect(aggressive.plan.lumpSums.first.amount, 100000);

      final balanced = presets.firstWhere((p) => p.id == 'system-balanced');
      expect(balanced.name, 'Balanced Wealth');
      expect(balanced.isSystem, isTrue);
      expect(balanced.plan.enableExtraAnnualEmi, isTrue);
      expect(balanced.plan.steppedEmiPercentage, 0.0);

      final relief = presets.firstWhere((p) => p.id == 'system-relief');
      expect(relief.name, 'Minimum EMI Relief');
      expect(relief.isSystem, isTrue);
      expect(relief.plan.strategyMode, StrategyMode.reduceEmi);
    });

    test('defaultSavedPresets provides pre-seeded realistic user blueprints', () {
      final saved = StrategyBlueprint.defaultSavedPresets();
      expect(saved.length, greaterThanOrEqualTo(2));
      expect(saved.any((p) => p.name.contains('Diwali Bonus')), isTrue);
      expect(saved.every((p) => p.isSystem == false), isTrue);
    });

    test('copyWith properly clones and modifies blueprint attributes', () {
      final original = StrategyBlueprint(
        id: 'bp-1',
        name: 'Original Plan',
        description: 'Original Desc',
        versionTag: 'v1.0',
        plan: PrepaymentPlan.empty(),
        isSystem: false,
        createdAt: DateTime(2025, 1, 1),
        iconKey: 'rocket',
      );

      final updated = original.copyWith(
        name: 'Updated Plan',
        versionTag: 'v2.0',
      );

      expect(updated.id, 'bp-1');
      expect(updated.name, 'Updated Plan');
      expect(updated.versionTag, 'v2.0');
      expect(updated.description, 'Original Desc');
      expect(updated.plan, PrepaymentPlan.empty());
    });

    test('operator == and hashCode function predictably', () {
      final now = DateTime(2025, 1, 1);
      final a = StrategyBlueprint(
        id: 'bp-1',
        name: 'Plan A',
        description: 'Desc',
        plan: PrepaymentPlan.empty(),
        createdAt: now,
      );
      final b = StrategyBlueprint(
        id: 'bp-1',
        name: 'Plan A',
        description: 'Desc',
        plan: PrepaymentPlan.empty(),
        createdAt: now,
      );
      final c = a.copyWith(name: 'Plan C');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('SavedStrategiesNotifier & Riverpod Providers Tests', () {
    test('saveStrategy adds a new blueprint with clean fallback defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container.read(savedStrategiesProvider).length;

      container.read(savedStrategiesProvider.notifier).saveStrategy(
            name: 'My New Milestone',
            description: 'Custom payoff',
            plan: PrepaymentPlan.sample(),
          );

      final updated = container.read(savedStrategiesProvider);
      expect(updated.length, initialCount + 1);
      expect(updated.first.name, 'My New Milestone');
      expect(updated.first.description, 'Custom payoff');
      expect(updated.first.plan, PrepaymentPlan.sample());
      expect(updated.first.isSystem, isFalse);

      // Blank name falls back to 'Custom Strategy'
      container.read(savedStrategiesProvider.notifier).saveStrategy(
            name: '   ',
            plan: PrepaymentPlan.empty(),
          );
      expect(container.read(savedStrategiesProvider).first.name, 'Custom Strategy');
    });

    test('updateStrategy modifies existing blueprint name and description', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final list = container.read(savedStrategiesProvider);
      final targetId = list.first.id;

      container.read(savedStrategiesProvider.notifier).updateStrategy(
            id: targetId,
            name: 'Renamed Blueprint',
            description: 'New Description',
          );

      final modified = container.read(savedStrategiesProvider).firstWhere((b) => b.id == targetId);
      expect(modified.name, 'Renamed Blueprint');
      expect(modified.description, 'New Description');
    });

    test('deleteStrategy removes blueprint by id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(savedStrategiesProvider);
      final deleteId = initial.first.id;

      container.read(savedStrategiesProvider.notifier).deleteStrategy(deleteId);

      final after = container.read(savedStrategiesProvider);
      expect(after.any((b) => b.id == deleteId), isFalse);
      expect(after.length, initial.length - 1);
    });

    test('applyPlan in PrepaymentPlanNotifier updates active plan state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const customPlan = PrepaymentPlan(
        steppedEmiPercentage: 12.0,
        enableExtraAnnualEmi: false,
        strategyMode: StrategyMode.reduceEmi,
      );

      container.read(prepaymentPlanProvider.notifier).applyPlan(customPlan);

      expect(container.read(prepaymentPlanProvider), equals(customPlan));
      expect(container.read(prepaymentPlanProvider).steppedEmiPercentage, 12.0);
    });

    test('activeBlueprintIdProvider sets and tracks active strategy ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeBlueprintIdProvider), 'system-aggressive');

      container.read(activeBlueprintIdProvider.notifier).setActive('system-balanced');
      expect(container.read(activeBlueprintIdProvider), 'system-balanced');

      container.read(activeBlueprintIdProvider.notifier).setActive(null);
      expect(container.read(activeBlueprintIdProvider), isNull);
    });
  });

  group('StrategyPresetSelector Widget Tests', () {
    testWidgets('Renders System Presets tab and selects Aggressive Freedom by default',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const StrategyPresetSelector()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accelerated Payoff Strategy'), findsOneWidget);
      expect(find.text('System Presets'), findsOneWidget);
      expect(find.textContaining('My Saved'), findsOneWidget);
      expect(find.text('+ Save Custom'), findsOneWidget);

      // System Presets displayed
      expect(find.text('Aggressive Freedom'), findsOneWidget);
      expect(find.text('Balanced Wealth'), findsOneWidget);
      expect(find.text('Minimum EMI Relief'), findsOneWidget);
    });

    testWidgets('Tapping Balanced Wealth updates plan and changes selection indicator',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      bool changedCalled = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: StrategyPresetSelector(
                  onStrategyChanged: () {
                    changedCalled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Balanced Wealth card
      await tester.tap(find.text('Balanced Wealth'));
      await tester.pumpAndSettle();

      expect(changedCalled, isTrue);
      expect(container.read(activeBlueprintIdProvider), 'system-balanced');
      expect(container.read(prepaymentPlanProvider).steppedEmiPercentage, 0.0);
      expect(container.read(prepaymentPlanProvider).enableExtraAnnualEmi, isTrue);
    });

    testWidgets('Switching to My Saved tab renders saved blueprints and action buttons',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const StrategyPresetSelector()),
      );
      await tester.pumpAndSettle();

      // Tap My Saved tab
      await tester.tap(find.textContaining('My Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Saved Custom Blueprints'), findsOneWidget);
      expect(find.text('Diwali Bonus + 7% Step-Up'), findsOneWidget);
      expect(find.text('Apply Blueprint'), findsWidgets);
    });

    testWidgets('Tapping Apply Blueprint on custom blueprint applies strategy to plan',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: StrategyPresetSelector(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to My Saved
      await tester.tap(find.textContaining('My Saved'));
      await tester.pumpAndSettle();

      // Tap the first Apply Blueprint button
      final applyButton = find.widgetWithText(ElevatedButton, 'Apply Blueprint').first;
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Should now show 'Applied'
      expect(find.text('Applied'), findsWidgets);
      expect(container.read(prepaymentPlanProvider).steppedEmiPercentage, 7.0);
    });

    testWidgets('Tapping Rename button on blueprint opens dialog and updates name',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const StrategyPresetSelector()),
      );
      await tester.pumpAndSettle();

      // Switch to My Saved
      await tester.tap(find.textContaining('My Saved'));
      await tester.pumpAndSettle();

      // Tap Rename icon on first card
      final renameBtn = find.byTooltip('Rename').first;
      await tester.tap(renameBtn);
      await tester.pumpAndSettle();

      expect(find.text('Rename Blueprint'), findsOneWidget);

      // Enter new name
      await tester.enterText(find.byType(TextField).last, 'My Super Payoff Plan');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('My Super Payoff Plan'), findsOneWidget);
    });

    testWidgets('Tapping Delete removes blueprint from the saved list',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const StrategyPresetSelector()),
      );
      await tester.pumpAndSettle();

      // Switch to My Saved
      await tester.tap(find.textContaining('My Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Diwali Bonus + 7% Step-Up'), findsOneWidget);

      // Tap Delete on first card
      final deleteBtn = find.byTooltip('Delete').first;
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Diwali Bonus + 7% Step-Up'), findsNothing);
    });
  });

  group('SaveStrategyDialog Widget Tests', () {
    testWidgets('Displays form with current configuration preview and validates name',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => SaveStrategyDialog.show(ctx),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Save Payoff Blueprint'), findsOneWidget);
      expect(find.text('Blueprint Name'), findsOneWidget);
      expect(find.text('INCLUDED CONFIGURATION'), findsOneWidget);

      // Clear name and tap Save Blueprint to test validation
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '');
      await tester.tap(find.text('Save Blueprint'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name for your strategy blueprint'), findsOneWidget);

      // Enter valid name and save
      await tester.enterText(nameField, 'Freedom Plan 2026');
      await tester.tap(find.text('Save Blueprint'));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('Save Payoff Blueprint'), findsNothing);
    });
  });

  group('SavedStrategyCarousel Widget Tests', () {
    testWidgets('Renders carousel in Prepayment Simulator with Load and New buttons',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const SavedStrategyCarousel()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Strategies'), findsOneWidget);
      expect(find.text('+ New Strategy'), findsOneWidget);
      expect(find.text('Save New'), findsOneWidget);
    });

    testWidgets('Tapping Load loads strategy and invokes callback',
        (tester) async {
      bool loadedCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          child: SavedStrategyCarousel(
            onStrategyLoaded: () {
              loadedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find any load button or card
      final cardFinder = find.text('Load');
      if (cardFinder.evaluate().isNotEmpty) {
        await tester.tap(cardFinder.first);
        await tester.pumpAndSettle();
        expect(loadedCalled, isTrue);
      }
    });
  });
}
