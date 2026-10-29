import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/app.dart';
import 'package:splitburn/core/database/app_database.dart';
import 'package:splitburn/core/providers/database_providers.dart';
import 'package:splitburn/core/providers/engine_providers.dart';
import 'package:splitburn/features/bills/trial_reminders.dart';

import 'test_database.dart';

/// Drives the real app on a phone-sized screen against an in-memory ledger.
class AppHarness {
  AppHarness(this.tester, this.db);

  final WidgetTester tester;
  final AppDatabase db;
  final reminders = FakeTrialReminders();

  static Future<AppHarness> start(
    WidgetTester tester, {
    DateTime? now,
    Future<void> Function(AppDatabase db)? seed,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = openTestDatabase();
    final harness = AppHarness(tester, db);
    if (seed != null) await tester.runAsync(() => seed(db));
    final clock = now ?? DateTime(2026, 10, 28, 15);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => clock),
          trialReminderSchedulerProvider.overrideWithValue(harness.reminders),
        ],
        child: const SplitBurnApp(),
      ),
    );
    await harness.settle(
      () => find.byKey(const Key('safe-to-spend-card')).evaluate().isNotEmpty,
    );
    return harness;
  }

  /// Lets Drift's real async work run and rebuilds, until [done] (or ~2 s of
  /// frames). pumpAndSettle can't be used: spinners never settle.
  Future<void> settle([bool Function()? done]) async {
    for (var i = 0; i < 120 && !(done?.call() ?? false); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Text of the widget with [key], or the first Text inside it.
  String? text(String key) {
    final keyed = find.byKey(Key(key));
    if (keyed.evaluate().isEmpty) return null;
    final widget = keyed.evaluate().first.widget;
    if (widget is Text) return widget.data;
    final inner = find.descendant(of: keyed, matching: find.byType(Text));
    if (inner.evaluate().isEmpty) return null;
    return (inner.evaluate().first.widget as Text).data;
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await settle();
  }

  Future<void> enter(Finder finder, String value) async {
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await settle();
  }

  /// Unmounts the app and closes the database in the fake-async zone.
  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox());
    var closed = false;
    unawaited(db.close().then((_) => closed = true));
    for (var i = 0; i < 50 && !closed; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(closed, isTrue);
  }
}

/// Records Free Trial Shield calls instead of touching the plugin.
class FakeTrialReminders extends TrialReminderScheduler {
  final scheduled = <String>[];
  final cancelled = <String>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(
    Subscription sub, {
    required DateTime now,
    required String symbol,
  }) async {
    if (sub.isActive && sub.isFreeTrial) scheduled.add(sub.name);
  }

  @override
  Future<void> cancel(String subscriptionId) async =>
      cancelled.add(subscriptionId);

  @override
  Future<void> resync(
    List<Subscription> subscriptions, {
    required DateTime now,
    required String symbol,
  }) async {
    for (final s in subscriptions) {
      await schedule(s, now: now, symbol: symbol);
    }
  }
}
