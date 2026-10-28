import '../core/database/enums.dart';
import 'category_classifier.dart';
import 'expense_draft.dart';

/// "Spent 450 on Domino's with Rahul and Priya" → ₹450, Domino's, Food,
/// split with Rahul and Priya.
class ParsedExpense {
  const ParsedExpense({
    required this.amountMinor,
    required this.merchant,
    required this.friends,
    required this.payer,
    required this.category,
  });

  final int amountMinor;
  final String merchant;

  /// Everyone on the bill except the user, in the order they were mentioned
  /// (includes [payer] when a friend paid).
  final List<String> friends;

  /// The friend who paid, or `null` when the user paid.
  final String? payer;
  final TxnCategory category;

  /// An equal split between the user and [friends]. [resolveFriend] maps a
  /// spoken name to a known friend (or a new one).
  ExpenseDraft toDraft({
    required FriendRef Function(String name) resolveFriend,
    TxnSource source = TxnSource.app,
    DateTime? createdAt,
  }) {
    final refs = {for (final name in friends) name: resolveFriend(name)};
    return ExpenseDraft.equalSplit(
      merchant: merchant,
      totalMinor: amountMinor,
      friends: refs.values.toList(),
      category: category,
      payer: payer == null ? const PaidByMe() : PaidByFriend(refs[payer]!),
      source: source,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'ParsedExpense($amountMinor, $merchant, $friends, payer: $payer, '
      '${category.code})';
}

/// Regex + token parser for one-line expense phrases (command bar, Siri,
/// Action Button). Ported 1:1 to Swift in `ios/Runner/ExpensePhraseParser.swift`;
/// both are checked against `test/fixtures/expense_phrases.json`.
///
/// 1. **Amount**: the first number with a currency marker (`₹`, `Rs`, `INR`,
///    `$`, trailing `rs`/`rupees`/`bucks`), otherwise the largest bare
///    number. Supports `1,200`, `1,20,000`, `45.50`, `1.2k`.
/// 2. **Payer**: `Rahul paid …` at the very start, or `… paid by Rahul`.
/// 3. **Clauses**: `with/between/among` start the friend list (one name per
///    word, separated by `and`, `&`, `+` or commas; `me` is dropped);
///    `on/for` describe the item, `at/from/to/in` the place; `for me and X`
///    is a friend list. Words before any keyword describe the item.
/// 4. **Merchant**: the place if given, else the item, else "Quick expense".
///    All-lowercase words are title-cased; leading articles are dropped.
/// 5. **Category**: [CategoryClassifier] over the item and place words.
abstract final class ExpensePhraseParser {
  static const fallbackMerchant = 'Quick expense';

  static final RegExp _amountPattern = RegExp(
    r'(?<![\w.,])(₹|rs\.?|inr|\$|usd)?\s*(\d{1,3}(?:,\d{2,3})+|\d+)'
    r'(?:\.(\d{1,2}))?(k\b)?(?:\s*(rs\.?|rupees?|bucks|inr|dollars?))?(?!\w)',
    caseSensitive: false,
  );

  static final RegExp _tokenPattern = RegExp(
    r"[\p{L}\p{N}'’&@._-]+|[,&+]",
    unicode: true,
  );

  static const _fillers = {
    'spent',
    'spend',
    'spending',
    'paid',
    'pay',
    'paying',
    'bought',
    'buy',
    'got',
    'log',
    'logged',
    'add',
    'added',
    'split',
    'splitting',
    'just',
    'total',
    'i',
    'me',
    'myself',
    'us',
    'we',
    'rs',
    'rupees',
    'bucks',
  };
  static const _friendIntroducers = {'with', 'between', 'among', 'amongst'};
  static const _itemIntroducers = {'on', 'for'};
  static const _placeIntroducers = {'at', 'from', 'to', 'in'};
  static const _separators = {'and', '&', '+', ','};
  static const _selfWords = {'me', 'myself', 'i', 'us'};
  static const _articles = {'a', 'an', 'the', 'some'};

  /// Returns `null` when the phrase has no amount.
  static ParsedExpense? parse(String phrase) {
    final amount = _extractAmount(phrase);
    if (amount == null) return null;
    final rest =
        '${phrase.substring(0, amount.start)} ${phrase.substring(amount.end)}';

    final tokens = [
      for (final m in _tokenPattern.allMatches(rest))
        if (_clean(m[0]!) case final t when t.isNotEmpty) t,
    ];
    final lower = [for (final t in tokens) t.toLowerCase()];

    final friends = <String>[];
    String? payer;
    void addFriend(String raw) {
      final name = _normalizeName(raw);
      if (!friends.any((f) => f.toLowerCase() == name.toLowerCase())) {
        friends.add(name);
      }
    }

    var start = 0;
    // "Rahul paid 600 for pizza": a single name, then "paid" (not "paid by").
    if (tokens.length >= 2 &&
        lower[1] == 'paid' &&
        (tokens.length < 3 || lower[2] != 'by') &&
        _isNameCandidate(lower[0])) {
      payer = _normalizeName(tokens[0]);
      addFriend(tokens[0]);
      start = 2;
    }

    final item = <String>[];
    final place = <String>[];
    var mode = _Mode.item;
    for (var i = start; i < tokens.length; i++) {
      final word = lower[i];
      if (word == 'paid' && i + 1 < tokens.length && lower[i + 1] == 'by') {
        mode = _Mode.payer;
        i++;
        continue;
      }
      if (_friendIntroducers.contains(word)) {
        mode = _Mode.friends;
        continue;
      }
      if (word == 'for' &&
          i + 1 < tokens.length &&
          _selfWords.contains(lower[i + 1])) {
        mode = _Mode.friends;
        continue;
      }
      if (_itemIntroducers.contains(word)) {
        mode = _Mode.item;
        continue;
      }
      if (_placeIntroducers.contains(word)) {
        mode = _Mode.place;
        continue;
      }
      switch (mode) {
        case _Mode.friends:
          if (_separators.contains(word) ||
              _selfWords.contains(word) ||
              _articles.contains(word)) {
            continue;
          }
          addFriend(tokens[i]);
        case _Mode.payer:
          if (_separators.contains(word) || !_isNameCandidate(word)) continue;
          payer = _normalizeName(tokens[i]);
          addFriend(tokens[i]);
          mode = _Mode.item;
        case _Mode.item:
        case _Mode.place:
          if (_fillers.contains(word) || _separators.contains(word)) continue;
          (mode == _Mode.item ? item : place).add(tokens[i]);
      }
    }

    return ParsedExpense(
      amountMinor: amount.minor,
      merchant: _merchantFrom(place.isNotEmpty ? place : item),
      friends: List.unmodifiable(friends),
      payer: payer,
      category: CategoryClassifier.classifyWords([...item, ...place]),
    );
  }

  static _Amount? _extractAmount(String phrase) {
    _Amount? marked;
    _Amount? largest;
    for (final m in _amountPattern.allMatches(phrase)) {
      final integer = int.tryParse(m[2]!.replaceAll(',', ''));
      if (integer == null || integer > 9999999999) continue;
      final fraction = int.parse((m[3] ?? '').padRight(2, '0'));
      var minor = integer * 100 + fraction;
      if (m[4] != null) minor *= 1000;
      final amount = _Amount(minor, m.start, m.end);
      if (m[1] != null || m[5] != null) {
        marked ??= amount;
      } else if (largest == null || minor > largest.minor) {
        largest = amount;
      }
    }
    final chosen = marked ?? largest;
    return chosen == null || chosen.minor <= 0 ? null : chosen;
  }

  static bool _isNameCandidate(String lowerWord) =>
      !_fillers.contains(lowerWord) &&
      !_selfWords.contains(lowerWord) &&
      !_separators.contains(lowerWord) &&
      !_articles.contains(lowerWord) &&
      !_friendIntroducers.contains(lowerWord) &&
      !_itemIntroducers.contains(lowerWord) &&
      !_placeIntroducers.contains(lowerWord) &&
      CategoryClassifier.classifyWords([lowerWord]) == TxnCategory.other;

  static String _clean(String token) =>
      token.replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');

  static String _normalizeName(String raw) {
    final isAllLower = raw == raw.toLowerCase();
    final isAllUpper = raw.length > 1 && raw == raw.toUpperCase();
    if (!isAllLower && !isAllUpper) return raw;
    final lower = raw.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static String _merchantFrom(List<String> words) {
    final trimmed = [...words];
    while (trimmed.isNotEmpty &&
        _articles.contains(trimmed.first.toLowerCase())) {
      trimmed.removeAt(0);
    }
    if (trimmed.isEmpty) return fallbackMerchant;
    final text = trimmed.join(' ');
    if (text != text.toLowerCase()) return text;
    return [for (final w in trimmed) w[0].toUpperCase() + w.substring(1)]
        .join(' ');
  }
}

enum _Mode { item, place, friends, payer }

class _Amount {
  const _Amount(this.minor, this.start, this.end);

  final int minor;
  final int start;
  final int end;
}
