import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  testWidgets(
    'root widget re-reads the ledger when the app returns to the foreground',
    (tester) async {
      final app = await AppHarness.start(tester);
      expect(app.text('true-spendable'), '₹15,000');
      final limitBefore = app.text('safe-today');

      // An iOS App Intent logs ₹450 while the app sits in the background.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.runAsync(() async {
        await app.db.customStatement(
          "INSERT INTO transactions VALUES ('t-intent', 'Domino''s', 450.0, "
          "450.0, 'Food', 1, 'VOICE_INTENT', NULL, ?)",
          [DateTime(2026, 10, 28, 14).millisecondsSinceEpoch ~/ 1000],
        );
        await app.db.customStatement(
          'UPDATE budget_config SET current_bank_balance = '
          'current_bank_balance - 450 WHERE id = 1',
        );
      });
      await app.settle();
      expect(app.text('true-spendable'), '₹15,000', reason: 'not synced yet');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await app.settle(() => app.text('true-spendable') == '₹14,550');

      expect(app.text('true-spendable'), '₹14,550');
      await app.settle(() => app.text('safe-today') != limitBefore);
      expect(app.text('safe-today'), isNot(limitBefore));
      await tester.scrollUntilVisible(
        find.text("Domino's"),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text("Domino's"), findsOneWidget, reason: 'shows in Recent');
      expect(find.text('VOICE'), findsOneWidget);

      await app.dispose();
    },
  );
}
