#!/usr/bin/env bash
# Every check that runs without a phone: analysis, formatting, the Dart suite
# (also under DST-heavy time zones), web parity in Chrome, and the Kotlin
# UPI parser tests. iOS tests need Xcode: see the `ios` job in
# .github/workflows/ci.yml.
#
#   tool/test_all.sh            # everything available on this machine
#   tool/test_all.sh --quick    # analysis + Dart suite only
#
# Chrome: set CHROME_EXECUTABLE, or have google-chrome / chromium on PATH.
# Kotlin: needs an Android SDK (ANDROID_HOME or android/local.properties).
set -euo pipefail
cd "$(dirname "$0")/.."

quick=false
[[ "${1:-}" == "--quick" ]] && quick=true
skipped=()

step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
skip() {
  printf '   skipped: %s\n' "$2"
  skipped+=("$1 ($2)")
}

step 'Static analysis'
flutter analyze

step 'Formatting'
dart format --output=none --set-exit-if-changed lib test

step 'Dart tests'
flutter test

if $quick; then
  printf '\nQuick checks passed.\n'
  exit 0
fi

# Budget cycles, "today", the midnight timer and SQL day buckets must count
# calendar days. These zones have 23/25 h days, DST at midnight (Santiago),
# a 30-minute DST shift (Lord Howe) and a half-hour offset (Kolkata).
step 'Calendar math under other time zones'
for tz in America/New_York America/Santiago Australia/Lord_Howe Asia/Kolkata; do
  echo "-- TZ=$tz"
  TZ=$tz flutter test --reporter=compact test/domain test/providers test/database
done

# The web viewer decodes shared links in JavaScript, where ints are doubles.
step 'Web parity (Chrome)'
chrome="${CHROME_EXECUTABLE:-}"
if [[ -z "$chrome" ]]; then
  chrome="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
fi
if [[ -n "$chrome" ]]; then
  CHROME_EXECUTABLE="$chrome" flutter test --platform chrome \
    test/features/feature_logic_test.dart \
    test/domain/budget_cycle_test.dart \
    test/domain/split_calculator_test.dart \
    test/domain/debt_simplifier_test.dart \
    test/domain/invariants_test.dart
else
  skip chrome 'no Chrome found; set CHROME_EXECUTABLE'
fi

step 'Kotlin UPI parser (JVM)'
if [[ -n "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ]] ||
  grep -qs '^sdk.dir=' android/local.properties; then
  (cd android && ./gradlew --quiet :app:testDebugUnitTest)
else
  skip kotlin 'no Android SDK; set ANDROID_HOME'
fi

if ((${#skipped[@]})); then
  printf '\nPassed, but skipped: %s\n' "${skipped[*]}"
else
  printf '\nAll checks passed.\n'
fi
