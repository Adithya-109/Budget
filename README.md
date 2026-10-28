# SplitBurn

Multiplayer personal finance and bill-splitting for students: one ledger that
knows the difference between what you **paid** and what you **spent**, so a
₹1,200 dinner you fronted for four friends costs your food budget ₹300, not
₹1,200, and their repayments never show up as fake income.

Flutter (Dart) for ~90% of the app, with thin native bridges: iOS App Intents
and WidgetKit over a shared App Group SQLite file, and an Android notification
listener for automatic UPI capture.

The full product spec, architecture rules, and phase plan live in
[`CLAUDE.md`](CLAUDE.md).

## Status

Phase 1 (project scaffold and shared SQLite core) is done:

- Drift schema for `budget_config`, `transactions`, `split_entries`,
  `subscriptions` and `financial_summary_view`, with WAL, `busy_timeout` and
  foreign keys on every connection.
- Net-share ledger writes and queries: log, re-split, settle, unsettle, settle
  all with a friend, delete with full reversal, per-cycle and per-category
  personal spend, daily burn series, friend balances, and open IOUs.
- Recurring flatmate bills that auto-charge and bill flatmates, plus the free
  trial graveyard.
- Split math (equal, exact, percentage, itemized receipts with proportional
  tax and tip) in integer paise.
- Min-cash-flow debt simplification: exact minimum number of transfers for
  groups of up to 15 people, heuristic above that.
- `schema/finance_schema.sql`: the exact DDL for the Swift and Kotlin bridges,
  kept in sync with Drift by a snapshot test.

## Development

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter test
```
