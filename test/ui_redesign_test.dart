import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/domain/expense_draft.dart';
import 'package:splitburn/ui/theme.dart';
import 'package:splitburn/ui/theme_mode.dart';

import 'support/app_harness.dart';

const rahul = FriendRef(id: 'f-rahul', name: 'Rahul');
const priya = FriendRef(id: 'f-priya', name: 'Priya');

Finder _nav(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Rahul owes me ₹300 (dinner), I owe Rahul ₹100 (auto), Priya owes ₹300.
Future<void> _crossDebts(AppDatabase db) async {
  await db.ledgerDao.logExpense(
    ExpenseDraft.equalSplit(
      merchant: 'Pizza',
      totalMinor: 90000,
      friends: const [rahul, priya],
      category: TxnCategory.food,
      createdAt: DateTime(2026, 10, 27, 20),
    ),
  );
  await db.ledgerDao.logExpense(
    ExpenseDraft.equalSplit(
      merchant: 'Auto',
      totalMinor: 20000,
      friends: const [rahul],
      payer: const PaidByFriend(rahul),
      category: TxnCategory.transit,
      createdAt: DateTime(2026, 10, 27, 22),
    ),
  );
}

void main() {
  group('design tokens', () {
    for (final (name, t) in [
      ('dark', SplitBurnTokens.dark),
      ('light', SplitBurnTokens.light),
    ]) {
      test('$name mode text and actions meet WCAG AA', () {
        expect(_contrast(t.textPrimary, t.canvas), greaterThanOrEqualTo(7));
        expect(_contrast(t.textPrimary, t.surfacePrimary), greaterThan(7));
        expect(_contrast(t.textSecondary, t.canvas), greaterThan(4.5));
        expect(_contrast(t.textSecondary, t.surfacePrimary), greaterThan(4.5));
        expect(_contrast(t.onAccent, t.accent), greaterThan(3));
        for (final c in [t.owedToMe, t.iOwe, t.survivalMagma]) {
          expect(_contrast(c, t.surfacePrimary), greaterThan(3));
        }
        expect(
          _contrast(SplitBurnTokens.thermalInk, t.thermalPaper),
          greaterThan(12),
        );
      });
    }

    test('lerp lands on each end and copyWith overrides one token', () {
      const d = SplitBurnTokens.dark;
      const l = SplitBurnTokens.light;
      expect(d.lerp(l, 0).canvas, d.canvas);
      expect(d.lerp(l, 1).canvas, l.canvas);
      expect(d.lerp(l, 1).nudgeViolet, l.nudgeViolet);
      expect(d.copyWith(accent: l.accent).accent, l.accent);
      expect(d.copyWith(accent: l.accent).canvas, d.canvas);
    });

    test('both themes carry the tokens and the bundled fonts', () {
      for (final b in Brightness.values) {
        final theme = buildSplitBurnTheme(b);
        expect(theme.brightness, b);
        expect(theme.extension<SplitBurnTokens>(), isNotNull);
        expect(theme.textTheme.bodyMedium!.fontFamily, SbType.ui);
      }
      expect(SbType.receipt.fontFamilyFallback, contains(SbType.ui));
    });
  });

  group('theme mode', () {
    test('saved choice is restored and new choices are saved', () async {
      SharedPreferences.setMockInitialValues({AppThemeMode.prefsKey: 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(appThemeModeProvider), ThemeMode.dark);

      await container
          .read(appThemeModeProvider.notifier)
          .toggleFrom(Brightness.dark);
      expect(container.read(appThemeModeProvider), ThemeMode.light);
      expect(prefs.getString(AppThemeMode.prefsKey), 'light');
    });

    test('no preferences (tests, plugin missing): follows the system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(appThemeModeProvider), ThemeMode.system);
    });

    testWidgets('header toggle flips light ↔ dark; settings goes back', (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      expect(_brightness(tester), Brightness.light, reason: 'follows system');

      await app.tap(find.byKey(const Key('theme-toggle')));
      await app.settle(() => _brightness(tester) == Brightness.dark);
      expect(_brightness(tester), Brightness.dark);
      expect(tester.takeException(), isNull);

      await app.tap(_nav('Settings'));
      await app.tap(find.text('System'));
      await app.settle(() => _brightness(tester) == Brightness.light);
      expect(_brightness(tester), Brightness.light);
      await app.dispose();
    });
  });

  testWidgets('dark mode: every tab renders at phone width', (tester) async {
    final app = await AppHarness.start(
      tester,
      seed: _crossDebts,
      brightness: Brightness.dark,
    );
    expect(_brightness(tester), Brightness.dark);
    for (final tab in ['Friends', 'Bills', 'Settings', 'Today']) {
      await app.tap(_nav(tab));
      expect(tester.takeException(), isNull, reason: tab);
    }
    await app.dispose();
  });

  testWidgets('friends: debt graph, Simplify collapses IOUs, settle queue', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, seed: _crossDebts);
    await app.tap(_nav('Friends'));
    await app.settle(
      () => find.byKey(const Key('debt-graph')).evaluate().isNotEmpty,
    );
    // Rahul→You ₹300 and You→Rahul ₹100 net to one ₹200 transfer.
    expect(
      app.text('collapse-summary'),
      'Collapsing 3 raw IOUs into 2 direct transfers',
    );
    await app.tap(find.byKey(const Key('simplify-toggle')));
    expect(app.text('collapse-summary'), startsWith('3 raw IOUs'));
    expect(tester.takeException(), isNull, reason: 'collapse animation');
    await app.tap(find.byKey(const Key('simplify-toggle')));
    expect(app.text('collapse-summary'), startsWith('Collapsing'));

    await app.reveal(find.byKey(const Key('settle-Rahul')));
    expect(
      find.descendant(
        of: find.byKey(const Key('settle-Rahul')),
        matching: find.text('₹200'),
      ),
      findsOneWidget,
    );
    await app.dispose();
  });

  testWidgets('nudge receipt prints a UPI QR when the user has a UPI ID', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      seed: (db) async {
        await _crossDebts(db);
        await db.budgetDao.updateOwner(
          name: 'Adithya',
          paymentHandle: 'adithya@okaxis',
        );
      },
    );
    await app.tap(_nav('Friends'));
    await app.reveal(find.byKey(const Key('friend-Priya')));
    await app.tap(find.byKey(const Key('friend-Priya')));
    await app.tap(find.byKey(const Key('open-nudge')));
    await app.tap(find.text('Broke meme'));
    expect(find.text('Nutrition Facts'), findsOneWidget);
    expect(find.text('SCAN TO PAY (UPI)'), findsOneWidget);
    expect(find.text('SURVIVAL DEFICIT'), findsOneWidget);
    await app.dispose();
  });

  testWidgets('bills: a trial under 48h gets the shield banner; bury it', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      seed: (db) => db.subscriptionsDao.addSubscription(
        name: 'Cloud GPU Pro',
        amountMinor: 420000,
        myShareMinor: 420000,
        // 18 h after the harness clock (28 Oct 15:00).
        billingDate: DateTime(2026, 10, 29, 9),
        isFreeTrial: true,
      ),
    );
    await app.tap(_nav('Bills'));
    await app.settle(
      () =>
          find.text('48-HOUR SHIELD ALERT').evaluate().isNotEmpty ||
          find.text('48-hour shield alert').evaluate().isNotEmpty,
    );
    expect(tester.takeException(), isNull, reason: 'banner lays out');
    expect(app.text('countdown-Cloud GPU Pro'), 'Charges in 18h 0m');
    expect(app.text('saved-so-far'), 'Saved so far ₹0');

    await app.tap(find.byKey(const Key('buried-Cloud GPU Pro')));
    await app.settle(() => app.text('saved-so-far') == 'Saved so far ₹4,200');
    expect(app.text('saved-so-far'), 'Saved so far ₹4,200');
    expect(find.text('R.I.P. Cloud GPU Pro'), findsOneWidget);
    await app.dispose();
  });

  testWidgets('bills: tapping a flatmate marks them away and moves shares', (
    tester,
  ) async {
    final app = await AppHarness.start(
      tester,
      seed: (db) => db.subscriptionsDao.addSubscription(
        name: 'Wi-Fi',
        amountMinor: 90000,
        myShareMinor: 30000,
        billingDate: DateTime(2026, 11, 1, 9),
        splitGroup: const [
          SplitGroupMember(friendId: 'k', friendName: 'Kabir'),
          SplitGroupMember(friendId: 'm', friendName: 'Meera'),
        ],
      ),
    );
    await app.tap(_nav('Bills'));
    final kabir = find.byKey(const Key('member-Wi-Fi-Kabir'));
    await app.reveal(kabir);
    expect(find.textContaining('Your share ₹300'), findsOneWidget);

    await app.tap(kabir);
    await app.settle(
      () => find.textContaining('Your share ₹450').evaluate().isNotEmpty,
    );
    expect(
      find.descendant(of: kabir, matching: find.text('away')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('member-Wi-Fi-Meera')),
        matching: find.text('₹450'),
      ),
      findsOneWidget,
    );
    final sub = (await tester.runAsync(
      () => app.db.select(app.db.subscriptions).getSingle(),
    ))!;
    expect(sub.autoSplitGroupJson!.first.away, isTrue);
    await app.dispose();
  });
}
