import 'package:intl/intl.dart';

/// Money is computed in integer minor units (paise / cents) everywhere in the
/// domain layer so splits never leak fractions of a paisa. The database stores
/// major units as `REAL` (see CLAUDE.md §3); convert only at that boundary.
abstract final class Money {
  static const int minorPerMajor = 100;

  /// Converts a major-unit amount (e.g. `12.345`) to minor units, rounding half
  /// away from zero.
  static int toMinor(double major) {
    if (major.isNaN || major.isInfinite) {
      throw ArgumentError.value(major, 'major', 'must be a finite amount');
    }
    return (major * minorPerMajor).round();
  }

  static double toMajor(int minor) => minor / minorPerMajor;

  /// Rounds a major-unit amount to 2 decimal places. Use before persisting any
  /// value that came from arithmetic on doubles.
  static double round2(double major) => toMajor(toMinor(major));

  /// Formats [minor] for display, e.g. `₹1,20,000` / `$1,200.50`.
  ///
  /// Whole amounts drop the decimals because students read "₹450", not
  /// "₹450.00". Rupee amounts use Indian digit grouping.
  static String format(int minor, {String symbol = '₹'}) {
    final locale = symbol == '₹' ? 'en_IN' : 'en_US';
    final decimals = minor % minorPerMajor == 0 ? 0 : 2;
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimals,
    ).format(toMajor(minor));
  }

  /// Formats an amount for payment deep links (`am=` / `amount=`), which want a
  /// plain dot-separated decimal with exactly two places and no grouping.
  static String toPlainDecimal(int minor) {
    final sign = minor < 0 ? '-' : '';
    final abs = minor.abs();
    final major = abs ~/ minorPerMajor;
    final cents = (abs % minorPerMajor).toString().padLeft(2, '0');
    return '$sign$major.$cents';
  }
}
