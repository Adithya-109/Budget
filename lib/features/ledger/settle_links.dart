import '../../core/money.dart';

enum PaymentRail { upi, venmo }

/// Payment deep links with the exact amount and receiver pre-filled
/// (CLAUDE.md §4 Feature 5).
abstract final class SettleLinks {
  static final RegExp _upiId = RegExp(
    r'^[\w.\-]{2,256}@[a-zA-Z][\w.\-]{1,64}$',
  );
  static final RegExp _venmoHandle = RegExp(r'^@?[A-Za-z0-9_\-]{5,30}$');

  /// `name@okaxis` → UPI; `@alex-doe` / `alex-doe` → Venmo; otherwise null.
  static PaymentRail? railOf(String? handle) {
    final h = handle?.trim() ?? '';
    if (_upiId.hasMatch(h)) return PaymentRail.upi;
    if (_venmoHandle.hasMatch(h)) return PaymentRail.venmo;
    return null;
  }

  /// `upi://pay?pa={vpa}&pn={name}&am={amount}&cu=INR&tn=SplitBurn%20Settlement`
  static Uri upi({
    required String payeeVpa,
    required String payeeName,
    required int amountMinor,
    String note = 'SplitBurn Settlement',
  }) {
    _requirePositive(amountMinor);
    return Uri.parse(
      'upi://pay?pa=${_enc(payeeVpa.trim())}&pn=${_enc(payeeName.trim())}'
      '&am=${Money.toPlainDecimal(amountMinor)}&cu=INR&tn=${_enc(note)}',
    );
  }

  /// `venmo://paycharge?txn=pay&recipients={handle}&amount={amount}&note=SplitBurn`
  static Uri venmo({
    required String handle,
    required int amountMinor,
    String note = 'SplitBurn',
  }) {
    _requirePositive(amountMinor);
    final recipient = handle.trim().replaceFirst(RegExp('^@'), '');
    return Uri.parse(
      'venmo://paycharge?txn=pay&recipients=${_enc(recipient)}'
      '&amount=${Money.toPlainDecimal(amountMinor)}&note=${_enc(note)}',
    );
  }

  /// The right link for [handle], or null when it isn't a UPI ID or Venmo
  /// handle.
  static Uri? forHandle({
    required String? handle,
    required String payeeName,
    required int amountMinor,
  }) {
    return switch (railOf(handle)) {
      PaymentRail.upi => upi(
        payeeVpa: handle!,
        payeeName: payeeName,
        amountMinor: amountMinor,
      ),
      PaymentRail.venmo => venmo(handle: handle!, amountMinor: amountMinor),
      null => null,
    };
  }

  /// Percent-encodes a query value but keeps `@` readable, the way UPI apps
  /// print payee addresses.
  static String _enc(String value) =>
      Uri.encodeComponent(value).replaceAll('%40', '@');

  static void _requirePositive(int amountMinor) {
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be positive');
    }
  }
}
