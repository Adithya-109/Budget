import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/app.dart';
import 'package:splitburn/core/providers/database_providers.dart';
import 'package:splitburn/core/providers/engine_providers.dart';

import 'support/test_database.dart';

void main() {
  testWidgets(
    'root widget re-reads the ledger when the app returns to the foreground',
    (tester) async {
      final db = openTestDatabase();
      final now = DateTime(2026, 10, 28, 15);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => now),
          ],
          child: const SplitBurnApp(),
        ),
      );
      String? text(String key) {
        final found = find.byKey(Key(key)).evaluate();
        return found.isEmpty ? null : (found.single.widget as Text).data;
      }

      /// Drift does its work on real async; let it run, then rebuild. Stops
      /// as soon as [done] holds (pumpAndSettle would spin forever on the
      /// loading spinner).
      Future<void> settle(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      await settle(() => text('true-spendable') != null);
      expect(text('true-spendable'), '₹15,000');
      final limitBefore = text('safe-today');

      // An iOS App Intent logs ₹450 while the app sits in the background.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.runAsync(() async {
        await db.customStatement(
          "INSERT INTO transactions VALUES ('t-intent', 'Domino''s', 450.0, "
          "450.0, 'Food', 1, 'VOICE_INTENT', NULL, ?)",
          [DateTime(2026, 10, 28, 14).millisecondsSinceEpoch ~/ 1000],
        );
        await db.customStatement(
          'UPDATE budget_config SET current_bank_balance = '
          'current_bank_balance - 450 WHERE id = 1',
        );
      });
      await settle(() => false);
      expect(text('true-spendable'), '₹15,000', reason: 'not synced yet');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(
        () =>
            text('true-spendable') != null &&
            text('true-spendable') != '₹15,000',
      );

      expect(text('true-spendable'), '₹14,550');
      expect(text('safe-today'), isNot(limitBefore));

      // Unmount (disposes providers and cancels their timers), then close the
      // database in the same fake-async zone that opened it.
      await tester.pumpWidget(const SizedBox());
      var closed = false;
      unawaited(db.close().then((_) => closed = true));
      for (var i = 0; i < 50 && !closed; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(closed, isTrue);
    },
  );
}
