import 'dart:convert';

/// Where the Flutter Web build of the zero-install ledger viewer is hosted
/// (GitHub Pages by default, see `.github/workflows/web-ledger.yml`).
/// Override with `--dart-define=WEB_LEDGER_BASE_URL=https://…/`.
const kWebLedgerBaseUrl = String.fromEnvironment(
  'WEB_LEDGER_BASE_URL',
  defaultValue: 'https://adithya-109.github.io/Budget/',
);

/// One line of a shared tab ("Domino's · 28 Oct · ₹150").
class SharedLedgerLine {
  const SharedLedgerLine({
    required this.label,
    required this.amountMinor,
    required this.date,
  });

  final String label;
  final int amountMinor;

  /// Local calendar day the expense was logged.
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is SharedLedgerLine &&
      other.label == label &&
      other.amountMinor == amountMinor &&
      other.date == date;

  @override
  int get hashCode => Object.hash(label, amountMinor, date);
}

class SharedLedgerFormatException extends FormatException {
  const SharedLedgerFormatException(super.message);
}

/// What a friend sees without installing the app: who to pay, how much and
/// for what. Travels entirely inside the link's `#fragment`, so the static
/// web host never receives it.
///
/// Wire format: base64url (no padding) of compact JSON
/// `{"v":1,"t":title,"n":payeeName,"h":handle?,"c":symbol,
///   "l":[[label,amountMinor,yyyymmdd],…],"k":checksum}`.
/// The checksum (FNV-1a of the JSON without `k`) catches links that a chat
/// app truncated; it is not a signature.
class SharedLedger {
  const SharedLedger({
    required this.title,
    required this.payeeName,
    required this.payeeHandle,
    required this.currencySymbol,
    required this.lines,
  });

  static const version = 1;

  final String title;
  final String payeeName;
  final String? payeeHandle;
  final String currencySymbol;
  final List<SharedLedgerLine> lines;

  int get totalMinor => lines.fold(0, (sum, l) => sum + l.amountMinor);

  String encode() {
    final body = _body();
    final json = jsonEncode({...body, 'k': _checksum(jsonEncode(body))});
    return base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  }

  /// The shareable link, e.g. `https://…/Budget/#/l/eyJ2Ijox…`.
  Uri toUri({String baseUrl = kWebLedgerBaseUrl}) =>
      Uri.parse(baseUrl).replace(fragment: '/l/${encode()}');

  static SharedLedger decode(String payload) {
    final Map<String, Object?> map;
    try {
      final padded = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      map = (jsonDecode(utf8.decode(base64Url.decode(padded))) as Map)
          .cast<String, Object?>();
    } on FormatException {
      throw const SharedLedgerFormatException('This link is damaged.');
    } on TypeError {
      throw const SharedLedgerFormatException('This link is damaged.');
    }
    if (map['v'] != version) {
      throw const SharedLedgerFormatException(
        'This link is from a newer SplitBurn.',
      );
    }
    final checksum = map.remove('k');
    if (checksum != _checksum(jsonEncode(map))) {
      throw const SharedLedgerFormatException(
        'This link was cut off. Ask for it again.',
      );
    }
    try {
      return SharedLedger(
        title: map['t']! as String,
        payeeName: map['n']! as String,
        payeeHandle: map['h'] as String?,
        currencySymbol: map['c']! as String,
        lines: [
          for (final entry in map['l']! as List)
            SharedLedgerLine(
              label: (entry as List)[0] as String,
              amountMinor: entry[1] as int,
              date: _fromDay(entry[2] as int),
            ),
        ],
      );
    } on TypeError {
      throw const SharedLedgerFormatException('This link is damaged.');
    }
  }

  /// Extracts the payload from a `#/l/<payload>` fragment, if present.
  static String? payloadFromFragment(String fragment) {
    final match = RegExp(r'^/?l/([A-Za-z0-9_\-]+)$').firstMatch(fragment);
    return match?.group(1);
  }

  Map<String, Object?> _body() => {
    'v': version,
    't': title,
    'n': payeeName,
    if (payeeHandle != null) 'h': payeeHandle,
    'c': currencySymbol,
    'l': [
      for (final l in lines) [l.label, l.amountMinor, _toDay(l.date)],
    ],
  };

  static int _toDay(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime _fromDay(int v) =>
      DateTime(v ~/ 10000, v ~/ 100 % 100, v % 100);

  /// 32-bit FNV-1a over UTF-16 code units, as 8 hex chars. Must give the
  /// same result in the app (64-bit ints) and the web viewer (JS doubles).
  static String _checksum(String text) =>
      fnv1a32(text.codeUnits).toRadixString(16).padLeft(8, '0');
}

/// 32-bit FNV-1a. The prime 0x01000193 is `2^24 + 0x193`, so the multiply is
/// split into `h * 0x193` (< 2^41) plus `h << 24` masked to 32 bits: every
/// intermediate stays below 2^53, which keeps dart2js (doubles) and the VM
/// (64-bit ints) bit-for-bit identical. A plain `h * 0x01000193` loses
/// precision on the web and breaks shared links.
int fnv1a32(Iterable<int> units) {
  var hash = 0x811c9dc5;
  for (final unit in units) {
    hash = (hash ^ unit) & 0xffffffff;
    hash = (hash * 0x193 + ((hash << 24) & 0xffffffff)) & 0xffffffff;
  }
  return hash;
}
