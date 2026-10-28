# ROLE & OBJECTIVE
You are a Staff Full-Stack Mobile Architect and Founding Engineer. Your task is to architect and build **"SplitBurn"** (working title)—a cross-platform **Multiplayer Personal Finance & Social Bill-Splitting App** built with a **90% Flutter (Dart) + 10% Native Bridge (Swift & Kotlin)** hybrid architecture.

Do not build a generic CRUD expense tracker. Every architectural decision, database query, and UI component must directly solve the core market pain points outlined below.

---

# 1. PRODUCT CONTEXT, TARGET MARKET & PAIN POINTS

## Target Demographic
- **Primary Market:** College students, hostel residents, and young flatmates/roommates operating on irregular monthly allowances, stipends, or pocket money rather than steady 9-to-5 salaries.
- **Core Metric:** Students do not care about "Net Worth" or complex accounting spreadsheets. Their #1 daily question is: **"How much is safe to spend today without going broke before the 1st of next month?"**

## The 5 Market Pain Points We Are Solving
1. **The Disconnected Ledger Flaw:** When a student fronts ₹1,200 ($40) for a group dinner of 4, traditional budgeting apps log ₹1,200 as personal food spending (ruining monthly food budgets) and treat later friend repayments as "new income." Conversely, Splitwise tracks the ₹900 owed by friends in a vacuum without connecting it to the user's daily spending limit.
2. **The Splitwise Paywall & Friction:** Competitors restrict daily entries, inject cooldown timers, and lock receipt scanning behind expensive subscriptions.
3. **iOS Privacy Sandboxing vs. Automation:** Android apps can read bank/UPI notifications automatically, but iOS strictly blocks SMS/notification reading. iOS users are stuck doing tedious manual entry unless we leverage native iOS `AppIntents` (Apple Pay / Action Button shortcuts) and `WidgetKit`.
4. **Cross-Platform Friend Group Friction:** Friend groups are always a mix of iOS and Android users. Requiring every casual friend to install an app just to view or settle a bill kills adoption.
5. **Social Awkwardness of Micro-Debts:** Asking a friend for ₹50 for a shared auto ride or coffee feels petty, so students let micro-debts slide and lose thousands over a semester.

---

# 2. SYSTEM ARCHITECTURE (90% FLUTTER + 10% NATIVE BRIDGE)

## Tech Stack
- **Framework:** Flutter (Dart 3.5+, Impeller rendering engine enabled for 120Hz charts/animations).
- **State Management:** `flutter_riverpod` (v3.0+ with code generation & reactive caching).
- **Local Database (Single Source of Truth):** `drift` + `drift_flutter` (SQLite with **Write-Ahead Logging `PRAGMA journal_mode=WAL`** enabled).
- **Receipt OCR & Voice Parsing:** `google_mlkit_text_recognition` (bridges to Apple Vision on iOS and ML Kit on Android) + on-device natural language parsing.
- **Native iOS Bridges (`ios/`):**
  - **Shared App Group Container (`group.com.splitburn.app`):** Houses the single `finance.sqlite` database file accessed by Flutter, `AppIntents`, and `WidgetKit`.
  - **`AppIntents` (Swift, iOS 16+):** Background shortcut execution (`openAppWhenRun = false`) for Apple Pay automation triggers and iPhone Action Button voice/quick logging without booting the Flutter engine.
  - **`WidgetKit` (SwiftUI):** Home Screen and Lock Screen widgets reading directly from the shared SQLite file in `SQLITE_OPEN_READONLY` mode.
  - **`SharedSQLiteManager.swift`:** Zero-dependency C-API `SQLite3` helper compiled into both `Runner` and `BalanceWidgetExtension` targets.
- **Native Android Bridge (`android/`):**
  - **`NotificationListenerService` (Kotlin):** Background service that parses incoming UPI/bank payment notifications (GPay, PhonePe, Paytm, bank alerts) via Regex and writes directly to the shared SQLite database.

## Critical Concurrency & Lifecycle Rules
1. **Shared App Group Path Resolution:** Never store `finance.sqlite` in Flutter's default sandbox on iOS. Expose a `MethodChannel('com.splitburn.app/storage')` in `AppDelegate.swift` returning `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.splitburn.app")?.path`.
2. **WAL Concurrency:** Both Dart (`Drift`) and Swift (`SharedSQLiteManager`) MUST execute `PRAGMA journal_mode = WAL;` and `PRAGMA busy_timeout = 5000;` on every connection so background shortcuts, widgets, and the main UI never throw `SQLITE_BUSY` lock errors.
3. **Foreground Resume Sync:** Implement `WidgetsBindingObserver` in the root Flutter widget. Whenever `AppLifecycleState.resumed` fires, call `database.markTablesUpdated([database.transactions, database.splitEntries, database.subscriptions])` so Drift streams immediately reflect transactions logged in the background by iOS `AppIntents` or Android `NotificationListenerService`.

---

# 3. DATABASE SCHEMA (`finance.sqlite`)

Implement the following core tables and SQL views in both `Drift` (Dart) and `SharedSQLiteManager` (Swift):

```sql
PRAGMA journal_mode = WAL;
PRAGMA busy_timeout = 5000;
PRAGMA foreign_keys = ON;

-- 1. User Budget Settings
CREATE TABLE IF NOT EXISTS budget_config (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    monthly_allowance REAL NOT NULL DEFAULT 15000.0,
    current_bank_balance REAL NOT NULL DEFAULT 15000.0,
    cycle_reset_day INTEGER NOT NULL DEFAULT 1, -- Day of month allowance hits
    currency_symbol TEXT NOT NULL DEFAULT '₹'
);

-- 2. Core Transactions (Separates Total Cash Outflow from Personal Budget Share)
CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    merchant TEXT NOT NULL,
    total_paid REAL NOT NULL,        -- Actual cash deducted from bank (e.g., 1200.0)
    my_share REAL NOT NULL,          -- Only the user's personal cut (e.g., 300.0)
    category TEXT NOT NULL,          -- 'Food', 'Groceries', 'Transit', 'Utilities', 'Fun'
    paid_by_me INTEGER NOT NULL,     -- 1 = User fronted the bill, 0 = Friend paid
    source TEXT NOT NULL,            -- 'APP', 'APPLE_PAY_SHORTCUT', 'VOICE_INTENT', 'ANDROID_UPI_AUTO', 'OCR'
    receipt_image_path TEXT,
    created_at INTEGER NOT NULL      -- Unix epoch seconds
);

-- 3. Social Split & IOU Ledger
CREATE TABLE IF NOT EXISTS split_entries (
    id TEXT PRIMARY KEY,
    transaction_id TEXT NOT NULL,
    friend_id TEXT NOT NULL,
    friend_name TEXT NOT NULL,
    friend_payment_handle TEXT,      -- UPI ID (e.g. name@okaxis) or Venmo/CashApp handle
    amount REAL NOT NULL,
    direction TEXT NOT NULL,         -- 'OWES_ME' (Receivable) or 'I_OWE' (Payable)
    is_settled INTEGER DEFAULT 0,    -- 0 = Pending, 1 = Settled
    settled_at INTEGER,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

-- 4. Recurring Roommate Bills & Free Trial Graveyard
CREATE TABLE IF NOT EXISTS subscriptions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,              -- e.g., 'Wi-Fi', 'Spotify Duo', 'Apple Music Free Trial'
    amount REAL NOT NULL,
    my_share REAL NOT NULL,
    billing_date INTEGER NOT NULL,   -- Next Unix timestamp of charge
    is_free_trial INTEGER DEFAULT 0, -- 1 = Alert 48h before charge so student can cancel
    auto_split_group_json TEXT,      -- JSON array of friends to auto-bill on the 1st
    is_active INTEGER DEFAULT 1
);

-- 5. Fast Read View for WidgetKit & Burn Rate Engine
CREATE VIEW IF NOT EXISTS financial_summary_view AS
SELECT
    (SELECT monthly_allowance FROM budget_config WHERE id = 1) AS monthly_allowance,
    (SELECT current_bank_balance FROM budget_config WHERE id = 1) AS bank_balance,
    COALESCE((SELECT SUM(my_share) FROM transactions), 0.0) AS total_personal_spend,
    COALESCE((SELECT SUM(amount) FROM split_entries WHERE direction = 'OWES_ME' AND is_settled = 0), 0.0) AS total_owed_to_me,
    COALESCE((SELECT SUM(amount) FROM split_entries WHERE direction = 'I_OWE' AND is_settled = 0), 0.0) AS total_i_owe;
```

---

# 4. CORE & QUIRKY STUDENT FEATURES TO IMPLEMENT

## Feature 1: True "Net-Share" Accounting & "True Liquid Balance"
- When a user logs a ₹1,200 dinner split among 4 people (`total_paid = 1200`, `my_share = 300`):
  - Deduct only ₹300 from their personal "Food" budget and daily burn rate.
  - Place the remaining ₹900 into a "Fronted Cash / Floating Receivables" bucket.
- When a friend settles their ₹300 IOU, mark `is_settled = 1` and reconcile the receivable without inflating personal income or distorting spending analytics.
- Display the True Liquid Balance formula prominently on the Home Dashboard and Lock Screen Widget: `True Spendable Cash = Actual Bank Balance - Money I Owe Friends` (with a secondary green badge for `+ Money Friends Owe Me`).

## Feature 2: Dynamic "Burn Rate" & "Days-Until-Broke" Meter
- Build a real-time engine calculating:
  1. **Safe-to-Spend Today:** `(Monthly Allowance - Total Personal Spend This Cycle) / Days Remaining in Cycle`.
  2. **Dynamic Recalibration:** If a student's daily safe limit is ₹400 and they spend ₹650 today, visually animate tomorrow's safe daily limit dropping to compensate.
  3. **Days-Until-Broke Velocity:** Calculate the user's rolling 7-day average personal burn rate (`avg_daily_burn`). Compute `Days Until Broke = True Spendable Cash / avg_daily_burn`. If `Days Until Broke < Days Left in Month`, switch the dashboard gauge to "Survival Mode" (Magma Orange/Red) and tell the user the exact date they will hit ₹0 at their current pace.

## Feature 3: Zero-Friction Logging (Action Button, Apple Pay & Natural Language)
- **iOS `LogSplitExpenseIntent` (`AppIntents`):** Allow users to bind an iOS Shortcut to their Apple Pay transaction trigger or iPhone Action Button. Support both structured parameters (`amount`, `merchant`, `friendsCsv`) AND natural language voice input (e.g., "Spent 450 on Domino's with Rahul and Priya").
- **Natural Language Parser (Dart & Swift):** Regex + lightweight token parser that extracts amount (`450`), merchant (`Domino's`), and friend names (`Rahul`, `Priya`), automatically calculating `450 / 3 = 150` per person and inserting the `transactions` row and two `split_entries` rows.
- **Camera Receipt Itemizer:** Use `google_mlkit_text_recognition` to scan restaurant receipts into selectable line items so friends can tap what they ate, automatically splitting tax/tip proportionally.

## Feature 4: "The Nudge Bot" (Passive-Aggressive-Free Debt Reminders)
- Students hate texting friends to ask for ₹60 back. Build a "Nudge Generator" sheet with 3 tone modes:
  1. **Polite & Casual** ("Hey! Settling up this week's food tab whenever you're free")
  2. **Broke College Student Meme Card** (Generates a shareable image card using Flutter's `RepaintBoundary` showing an itemized receipt styled like a dramatic "Survival Fund" notice or nutrition label)
  3. **1st-of-the-Month Auto-Digest** (Bundles all micro-debts from the month—₹40 auto, ₹120 coffee, ₹300 pizza—into one clean summary card so the user isn't nagging for single small amounts).
- Include a one-tap **Share via WhatsApp / iMessage** action using `share_plus`.

## Feature 5: Zero-Install Web Ledgers & Deep-Link Settlement (UPI / Venmo / Apple Cash)
- Never force a friend to download the app to view or pay a split.
- Generate a compact, URL-safe Base64 or signed JSON payload embedded in a shareable link (plus a companion lightweight web viewer route in Flutter Web) showing the itemized bill, who owes what, and a one-tap "Settle Now" button.
- Clicking "Settle Now" triggers a native payment deep-link with the exact amount and receiver ID pre-filled:
  - **UPI Deep Link:** `upi://pay?pa={friend_upi_id}&pn={name}&am={exact_amount}&cu=INR&tn=SplitBurn%20Settlement`
  - **Venmo Deep Link:** `venmo://paycharge?txn=pay&recipients={handle}&amount={exact_amount}&note=SplitBurn`

## Feature 6: Subscription & "Free Trial Graveyard" Tracker
- Dedicated tab for recurring flatmate bills (Wi-Fi, electricity, maid/cook, shared Netflix/Spotify) that automatically generates split entries on the 1st of the month.
- **"Free Trial Shield":** When logging a free trial (e.g., 30-day software tool or streaming trial), schedule a high-priority local notification (`flutter_local_notifications`) 48 hours and 12 hours before expiration with a direct link to cancel before their student debit card gets wiped out.

---

# 5. STEP-BY-STEP IMPLEMENTATION EXECUTION PLAN
Execute this project in 5 sequential phases. Complete and verify all files in a phase before moving to the next:

- **Phase 1: Project Scaffolding & Shared SQLite Core**
  - Initialize the Flutter project, `pubspec.yaml` dependencies (`drift`, `sqlite3_flutter_libs`, `flutter_riverpod`, `home_widget`, `google_mlkit_text_recognition`, `flutter_local_notifications`, `share_plus`, `fl_chart`), and build the complete `Drift` schema, WAL setup, Net-Share queries, and Graph Debt Simplification algorithm (minimizing total transactions among a friend group).
- **Phase 2: Native iOS & Android Bridges**
  - Write `ios/SharedStorage/SharedSQLiteManager.swift`, `ios/Runner/AppDelegate.swift` (App Group `MethodChannel`), `ios/Runner/QuickLogIntent.swift` (`AppIntents` with natural language parsing), `ios/BalanceWidgetExtension/BalanceWidget.swift` (`WidgetKit` Lock/Home Screen UI), and `android/.../UpiNotificationListener.kt`.
- **Phase 3: Core Engines (Burn Rate, Days-Until-Broke & Resume Sync)**
  - Implement the Riverpod providers for the Burn Rate calculator, Days-Until-Broke velocity meter, True Liquid Balance reconciler, and the `WidgetsBindingObserver` lifecycle listener.
- **Phase 4: UI Screens & Quirky Student Features**
  - Build a dark-mode-first, high-contrast Neobrutalist / Neo-banking UI featuring:
    1. **Dashboard:** Safe-to-Spend Hero Card, Survival Mode Meter, True Liquid Balance pill, and quick natural-language command bar.
    2. **Split & Receipt Scanner Modal:** Equal, exact, percentage, and OCR receipt line-item tapping.
    3. **Social Ledger & Nudge Bot Studio:** Friend balances, graph-simplified group settlements, meme receipt card renderer (`RepaintBoundary`), and UPI/Venmo deep-link generators.
    4. **Trial Graveyard & Flatmate Recurring Hub:** Countdown timers for active free trials and recurring roommate splits.
- **Phase 5: Verification & Testing**
  - Write unit tests for the Net-Share accounting math, Burn Rate recalibration, natural language expense parser, and Min-Cash-Flow debt simplification graph algorithm.

Output full, production-ready, modular code without placeholders or `// TODO` stubs.

---

# 6. IMPLEMENTATION NOTES (kept current as phases land)

## Phase status
- [x] Phase 1: Project scaffolding & shared SQLite core
- [x] Phase 2: Native iOS & Android bridges (Kotlin compile-checked + JVM-tested; Swift not compiled yet, see below)
- [x] Phase 3: Core engines (burn rate, Days-Until-Broke, True Liquid Balance reconciler, resume sync)
- [ ] Phase 4: UI screens
- [ ] Phase 5: Verification & testing (Phases 1–3 already ship tests for their own code)

## Git
- Commit as the repository owner only. Do **not** add `Co-Authored-By`, `Claude-Session` or any other attribution trailers to commit messages.

## Commands
```bash
flutter pub get
dart run build_runner build   # regenerate *.drift.dart (Drift) and *.g.dart (Riverpod)
flutter analyze
flutter test
UPDATE_SCHEMA=1 flutter test test/database/schema_snapshot_test.dart  # refresh the SQL / Swift / Kotlin schema files
ruby tool/ios/configure_xcode_project.rb   # (gem install xcodeproj) re-wire native targets into Runner.xcodeproj
cd android && ./gradlew :app:testDebugUnitTest   # Kotlin UPI parser tests
# iOS: open ios/Runner.xcworkspace and run the RunnerTests scheme (parser parity + SQLite manager tests)
```

## One-time manual setup (cannot be done from source files)
1. Open `ios/Runner.xcworkspace` in Xcode, pick your **Team** under *Signing & Capabilities* for **Runner** and **BalanceWidgetExtension**.
2. Both targets already carry `group.com.splitburn.app` in their `.entitlements`; under *Signing & Capabilities → App Groups* tick that group so Xcode registers it with your developer account.
3. Android: in the app, the user grants *Notification access* to "SplitBurn UPI auto-capture" (the Dart `NativeBridge.openUpiCaptureSettings()` opens the right screen).

## Decisions that deviate from / refine the spec
- **`sqlite3_flutter_libs` is not a dependency.** With `sqlite3` 3.x the native library ships via build hooks and `sqlite3_flutter_libs` 0.6.0 is an empty end-of-life shim; depending on `sqlite3` directly is the supported setup.
- **Bundle / application ID is `com.splitburn.app`** on both platforms, matching the App Group `group.com.splitburn.app` and the storage channel name.
- **Android database location** is `context.filesDir/finance.sqlite` (what `getApplicationSupportDirectory()` returns), so the Kotlin `NotificationListenerService` opens the same file with no channel round-trip. iOS resolves the App Group path through `MethodChannel('com.splitburn.app/storage')`, method `getAppGroupPath`, and refuses to fall back to the sandbox.
- **Extra columns / values** (additive, nullable or defaulted, so native writers that follow §3 stay valid):
  - `subscriptions.cancel_url TEXT` for the Free Trial Shield's "cancel now" link.
  - `transactions.category` also accepts `'Other'`; `transactions.source` also accepts `'SUBSCRIPTION'` (auto-generated recurring bills). Unknown codes written by native code read back as `Other` / `APP` rather than crashing the stream.
- **Drift generates standalone `*.drift.dart` parts** (`drift_dev:not_shared` in `build.yaml`) and runs before `riverpod_generator`, so providers can return Drift row types. Generated files are committed.
- **The Drift schema is rendered into `schema/finance_schema.sql`, `ios/SharedStorage/FinanceSchema.swift` and `android/.../capture/FinanceSchema.kt`** by `test/database/schema_snapshot_test.dart`, which fails when any of them is stale. Never edit those three by hand.
- **Drift owns `PRAGMA user_version`.** Native code never writes it and only runs the idempotent generated DDL. Drift's `onCreate` tolerates a schema a native writer created first (`test/database/native_writer_contract_test.dart`).
- **One SQLite copy per process.** Two SQLite libraries in one process break POSIX locks and can corrupt the file. iOS: `pubspec.yaml` sets `sqlite3` `source: ios: process`, so Dart uses the system SQLite that Runner links (`-lsqlite3`) for the App Intents. Android: Dart bundles its own SQLite, so the notification listener runs in a separate `:capture` process.
- **iOS App Intents live in Runner** and run without booting Flutter: the template's UIScene lifecycle only creates the implicit engine when a scene shows the UI, which background intent launches never do.
- **Widget** bundle ID `com.splitburn.app.BalanceWidget`, deployment target iOS 16 (whole project). Its version comes from Flutter's `Generated.xcconfig` via `BalanceWidget.xcconfig`. Deep link `splitburn://dashboard` is registered in Runner's Info.plist (routing lands in Phase 4).
- **Storage channel** `com.splitburn.app/storage`: `getAppGroupPath` (String or nil) and `reloadWidgets`. **Capture channel** `com.splitburn.app/capture` (Android): `isUpiCaptureEnabled`, `openUpiCaptureSettings`. Dart wraps both in `lib/core/native/native_bridge.dart`.
- **`home_widget` is not used**: the widget reads SQLite directly and the app reloads it through the storage channel.
- **UPI auto-capture** logs only clear, completed debits from an allow-list of UPI/bank apps (bank SMS must also look like an account alert). It skips credits, refunds, collect requests, failures, pending payments, reminders and OTP texts. Duplicates are dropped by UPI reference (last 200 kept in the `:capture` process's SharedPreferences) and by "same amount from `ANDROID_UPI_AUTO` within ±180 s" (GPay + bank SMS for one payment). Rows are solo expenses (`my_share = total_paid`); the user splits them later via `LedgerDao.resplitTransaction`.

## Write contract for every writer (Dart, Swift, Kotlin)
All money is `REAL` in major units (₹), rounded to 2 dp. Domain code computes in integer minor units (paise) and converts at the DB boundary.

| Event | `transactions` | `split_entries` | `budget_config.current_bank_balance` |
|---|---|---|---|
| I paid a bill | `paid_by_me = 1`, `total_paid` = bill, `my_share` = my cut | one `OWES_ME` row per friend with their share | `-= total_paid` |
| Friend paid a bill | `paid_by_me = 0`, `total_paid` = bill, `my_share` = my cut | one `I_OWE` row to the payer for `my_share` | unchanged |
| Friend settles an `OWES_ME` row | — | `is_settled = 1`, `settled_at = now` | `+= amount` (not income, not spend) |
| I settle an `I_OWE` row | — | `is_settled = 1`, `settled_at = now` | `-= amount` |
| Transaction deleted | row removed (splits cascade) | — | every delta above for that transaction is reversed |

Each event is one SQL transaction. Balance updates are relative (`SET current_bank_balance = current_bank_balance - ?`) so concurrent writers never lose updates.

## Engine formulas (Dart `BurnRateMetrics` = Swift `BurnRateMetrics`; `test/fixtures/burn_rate_cases.json` checks both)
All in minor units with integer (truncating) division; "today" is the local calendar day; days remaining counts today.
- `trueSpendable = bankBalance − iOwe`
- `dailyLimit = max(0, allowance − personalSpendThisCycleBeforeToday) / daysRemaining`
- `leftToday = dailyLimit − personalSpendToday` (negative = over)
- `tomorrowLimit = max(0, allowance − personalSpendThisCycleIncludingToday) / (daysRemaining − 1)` (none on the last day): the "recalibration" number
- `avgDailyBurn = personalSpend(7 days ending today, today included) / 7`
- `daysUntilBroke = max(0, trueSpendable) / avgDailyBurn` (none when `avgDailyBurn = 0`); `brokeDate = today + daysUntilBroke`
- Survival Mode when `daysUntilBroke < daysRemaining`

## Natural-language phrase parser (Dart `ExpensePhraseParser` = Swift `ExpensePhraseParser`)
Rules are documented on the Dart class. `test/fixtures/expense_phrases.json` is the contract: the Dart test and `ios/RunnerTests` both run it, so add a fixture for every behaviour change and update both ports. The category keyword lists exist in Dart, Swift and Kotlin and must stay identical.

## Code map (Phase 1)
- `lib/core/database/` – Drift tables, converters, the `financial_summary_view`, DAOs (`LedgerDao`, `BudgetDao`, `SubscriptionsDao`), WAL connection setup, App Group path resolution.
- `lib/core/money.dart` – minor-unit conversion and currency formatting.
- `lib/core/providers/` – Riverpod (codegen) providers for the database and DAOs.
- `lib/domain/` – pure Dart: `BudgetCycle`, `SplitCalculator` (equal / exact / percentage / itemized with proportional tax & tip), `ExpenseDraft`, `DebtSimplifier` (exact minimum-transaction settlement for groups up to 15 people, greedy min-cash-flow above that).

## Code map (Phase 2)
- `ios/SharedStorage/` (Runner + widget): `SharedSQLiteManager.swift` (C-API SQLite, WAL, write contract, snapshot reads), `FinanceSchema.swift` (generated), `BudgetMath.swift` (cycle, burn-rate metrics, money formatting).
- `ios/Runner/`: `AppDelegate.swift` (storage channel), `QuickLogIntent.swift` (`LogSplitExpenseIntent`, App Shortcuts), `ExpensePhraseParser.swift`, `Runner.entitlements`.
- `ios/BalanceWidgetExtension/`: `BalanceWidget.swift` (small / medium / Lock Screen rectangular, circular, inline), `Info.plist`, entitlements, xcconfig.
- `ios/RunnerTests/RunnerTests.swift`: parser parity against the shared fixtures, SQLite manager and burn-rate tests.
- `tool/ios/configure_xcode_project.rb`: idempotent Xcode project wiring.
- `android/app/src/main/kotlin/com/splitburn/app/`: `MainActivity.kt` (capture channel); `capture/` `UpiNotificationListener.kt`, `UpiNotificationParser.kt`, `FinanceStore.kt`, `CategoryClassifier.kt`, `FinanceSchema.kt` (generated). Tests in `android/app/src/test/`.
- `lib/domain/expense_phrase_parser.dart`, `lib/domain/category_classifier.dart`, `lib/core/native/native_bridge.dart`, `lib/core/providers/native_providers.dart`.

## Code map (Phase 3)
- `lib/domain/burn_rate.dart`: `LedgerSnapshot`, `BurnRateMetrics` (safe-to-spend, `tomorrowLimitMinor` + `recalibrationDeltaMinor` for the recalibration animation, 7-day burn, Days-Until-Broke, Survival Mode), `TrueLiquidBalance`.
- `LedgerDao.watchLedgerSnapshot` reads every engine input in one SQL statement (consistent numbers, one stream). `LedgerDao.reconcileBankBalance` is the True Liquid Balance reconciler: a shortfall versus the real bank balance becomes an "Untracked spending" expense (or a plain correction), extra money just sets the balance, all in one transaction.
- `lib/core/providers/engine_providers.dart`: `clockProvider` (override in tests), `currentDayProvider` (re-emits at local midnight), `currentCycleProvider` (rebuilds only on day / reset-day changes via `selectAsync`), `ledgerSnapshotProvider`, `burnRateProvider`, `trueLiquidBalanceProvider`, `cycleCategorySpendProvider`, `cycleDailySpendProvider`, `BalanceReconciler` notifier.
- `lib/core/sync/ledger_sync.dart`: `LedgerSync.onForeground()` (markTablesUpdated via `syncExternalWrites`, re-read the day, charge due recurring bills, re-check UPI access) and `widgetRefresherProvider` (debounced WidgetKit reload whenever the ledger changes).
- `lib/app.dart`: the root `SplitBurnApp` is the `WidgetsBindingObserver`; it syncs after the first frame and on every `AppLifecycleState.resumed`.

## Riverpod / testing notes
- UI must render `asyncValue.value` when present, not only `AsyncData`: the resume sync invalidates the day, so providers briefly refresh and a pure `AsyncData` match would flash a spinner on every resume.
- Riverpod 3 pauses or disposes unlistened providers: tests must `container.listen` before reading (see `nextValue` in `test/providers/engine_providers_test.dart`).
- Widget tests that touch Drift: don't `pumpAndSettle` (loading spinners never settle) and close the database inside the test's fake-async zone while pumping (see `test/app_lifecycle_test.dart`).
