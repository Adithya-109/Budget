/// Enumerations persisted as the exact TEXT codes in CLAUDE.md §3. Native
/// writers (Swift / Kotlin) insert the same codes, so the code strings are a
/// cross-language contract: never rename them.
library;

enum TxnCategory {
  food('Food'),
  groceries('Groceries'),
  transit('Transit'),
  utilities('Utilities'),
  fun('Fun'),
  other('Other');

  const TxnCategory(this.code);

  final String code;

  /// Case-insensitive lookup. Unknown codes (e.g. a category a newer native
  /// build wrote) read as [other] so one odd row never breaks a stream.
  static TxnCategory fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final value in values) {
      if (value.code.toLowerCase() == normalized) return value;
    }
    return other;
  }
}

enum TxnSource {
  app('APP'),
  applePayShortcut('APPLE_PAY_SHORTCUT'),
  voiceIntent('VOICE_INTENT'),
  androidUpiAuto('ANDROID_UPI_AUTO'),
  ocr('OCR'),
  subscription('SUBSCRIPTION');

  const TxnSource(this.code);

  final String code;

  static TxnSource fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final value in values) {
      if (value.code == normalized) return value;
    }
    return app;
  }

  /// Rows written while the Flutter engine was not running.
  bool get isBackgroundCapture =>
      this == applePayShortcut || this == voiceIntent || this == androidUpiAuto;
}

enum SplitDirection {
  /// Receivable: the friend owes the user.
  owesMe('OWES_ME'),

  /// Payable: the user owes the friend.
  iOwe('I_OWE');

  const SplitDirection(this.code);

  final String code;

  /// Unlike categories there is no safe default: guessing the direction of a
  /// debt would silently corrupt balances, so unknown codes throw.
  static SplitDirection fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final value in values) {
      if (value.code == normalized) return value;
    }
    throw FormatException('Unknown split direction', code);
  }
}
