import '../core/database/enums.dart';

/// Keyword → category guesses for quick logs, voice phrases and auto-captured
/// UPI payments.
///
/// Mirrored in Swift (`ios/Runner/ExpensePhraseParser.swift`) and Kotlin
/// (`CategoryClassifier.kt`); keep the lists and the matching rule identical
/// (`test/fixtures/expense_phrases.json` checks the Dart and Swift copies).
///
/// Matching rule: a word is lowercased with apostrophes and hyphens removed,
/// then matches a keyword exactly, or by prefix when the keyword has at least
/// 4 letters (`dominos` → `domino`). Words are checked in order; the first
/// word that matches decides, with categories tried in declaration order.
abstract final class CategoryClassifier {
  static const Map<TxnCategory, List<String>> keywords = {
    TxnCategory.food: [
      'food',
      'lunch',
      'dinner',
      'breakfast',
      'brunch',
      'snack',
      'meal',
      'pizza',
      'burger',
      'biryani',
      'coffee',
      'chai',
      'tea',
      'cafe',
      'canteen',
      'mess',
      'restaurant',
      'dhaba',
      'domino',
      'swiggy',
      'zomato',
      'starbucks',
      'mcdonald',
      'mcd',
      'kfc',
      'subway',
      'juice',
      'icecream',
      'dessert',
      'bakery',
      'momo',
      'maggi',
      'thali',
      'dosa',
      'sandwich',
      'shawarma',
      'roll',
      'chaayos',
      'eatery',
    ],
    TxnCategory.groceries: [
      'grocery',
      'groceries',
      'blinkit',
      'zepto',
      'instamart',
      'bigbasket',
      'dmart',
      'kirana',
      'vegetable',
      'veggies',
      'fruit',
      'milk',
      'eggs',
      'supermarket',
      'jiomart',
    ],
    TxnCategory.transit: [
      'uber',
      'ola',
      'rapido',
      'auto',
      'cab',
      'taxi',
      'metro',
      'bus',
      'train',
      'irctc',
      'petrol',
      'diesel',
      'fuel',
      'parking',
      'toll',
      'flight',
      'indigo',
      'redbus',
      'rickshaw',
    ],
    TxnCategory.utilities: [
      'wifi',
      'internet',
      'broadband',
      'electricity',
      'electric',
      'rent',
      'recharge',
      'airtel',
      'jio',
      'vodafone',
      'bsnl',
      'gas',
      'maid',
      'cook',
      'laundry',
    ],
    TxnCategory.fun: [
      'movie',
      'cinema',
      'pvr',
      'inox',
      'netflix',
      'spotify',
      'prime',
      'hotstar',
      'bookmyshow',
      'concert',
      'party',
      'game',
      'gaming',
      'bowling',
      'club',
      'pub',
      'bar',
      'beer',
      'drinks',
      'trip',
      'outing',
      'steam',
    ],
  };

  static final RegExp _wordPattern = RegExp(r"[\p{L}\p{N}'’-]+", unicode: true);
  static final RegExp _stripPattern = RegExp(r"['’-]");

  /// Category of the first recognisable word in [words], else `Other`.
  static TxnCategory classifyWords(Iterable<String> words) {
    for (final word in words) {
      final normalized = word.toLowerCase().replaceAll(_stripPattern, '');
      if (normalized.isEmpty) continue;
      for (final MapEntry(key: category, value: list) in keywords.entries) {
        for (final keyword in list) {
          if (normalized == keyword ||
              (keyword.length >= 4 && normalized.startsWith(keyword))) {
            return category;
          }
        }
      }
    }
    return TxnCategory.other;
  }

  static TxnCategory classify(String text) =>
      classifyWords(_wordPattern.allMatches(text).map((m) => m[0]!));
}
