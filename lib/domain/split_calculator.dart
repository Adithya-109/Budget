/// Splits a bill (in integer minor units) between participants of any key type.
///
/// Every method returns shares that sum exactly to the bill. Leftover minor
/// units from rounding go to the participants with the largest fractional
/// remainder, ties broken by list order, so callers should list the payer
/// first: the person who fronted the cash absorbs the stray paisa.
abstract final class SplitCalculator {
  /// `450` between 3 → `150, 150, 150`; `100` between 3 → `34, 33, 33`.
  static Map<K, int> equal<K>(int totalMinor, List<K> participants) {
    _requireParticipants(participants);
    return allocate(totalMinor, {for (final p in participants) p: 1});
  }

  /// Exact amounts typed per person. They must add up to [totalMinor].
  static Map<K, int> exact<K>(int totalMinor, Map<K, int> sharesMinor) {
    if (sharesMinor.isEmpty) {
      throw ArgumentError.value(sharesMinor, 'sharesMinor', 'is empty');
    }
    if (sharesMinor.values.any((s) => s < 0)) {
      throw ArgumentError.value(
        sharesMinor,
        'sharesMinor',
        'has a negative share',
      );
    }
    final sum = sharesMinor.values.fold<int>(0, (a, b) => a + b);
    if (sum != totalMinor) {
      throw SplitMismatchError(expectedMinor: totalMinor, actualMinor: sum);
    }
    return Map.unmodifiable(sharesMinor);
  }

  /// Percentage split in basis points (`2500` = 25%). Must total `10000`.
  static Map<K, int> percentage<K>(int totalMinor, Map<K, int> basisPoints) {
    if (basisPoints.isEmpty) {
      throw ArgumentError.value(basisPoints, 'basisPoints', 'is empty');
    }
    if (basisPoints.values.any((b) => b < 0)) {
      throw ArgumentError.value(
        basisPoints,
        'basisPoints',
        'has a negative percentage',
      );
    }
    final sum = basisPoints.values.fold<int>(0, (a, b) => a + b);
    if (sum != 10000) {
      throw ArgumentError.value(
        basisPoints,
        'basisPoints',
        'must total 100% (10000 bp), got $sum bp',
      );
    }
    return allocate(totalMinor, basisPoints);
  }

  /// Receipt line items: each item's price is split equally between the
  /// people who tapped it, then [extrasMinor] (tax + tip + service − discount)
  /// is spread in proportion to each person's item subtotal.
  ///
  /// Participants who claimed nothing get no share (and no tax). Items nobody
  /// claimed are an error: the receipt would not add up.
  static ItemizedSplit<K> itemized<K>(
    List<ReceiptLine<K>> items, {
    int extrasMinor = 0,
  }) {
    if (items.isEmpty) throw ArgumentError.value(items, 'items', 'is empty');
    final subtotals = <K, int>{};
    for (final item in items) {
      if (item.sharedBy.isEmpty) {
        throw UnclaimedItemError(item.label);
      }
      if (item.priceMinor < 0) {
        throw ArgumentError.value(
          item.priceMinor,
          item.label,
          'negative price',
        );
      }
      final perPerson = equal(item.priceMinor, item.sharedBy);
      perPerson.forEach((k, v) => subtotals[k] = (subtotals[k] ?? 0) + v);
    }
    final itemsTotal = subtotals.values.fold<int>(0, (a, b) => a + b);
    final extras = itemsTotal == 0
        ? {for (final k in subtotals.keys) k: 0}
        : allocate(extrasMinor, subtotals);
    final totals = {
      for (final k in subtotals.keys) k: subtotals[k]! + extras[k]!,
    };
    if (totals.values.any((t) => t < 0)) {
      throw ArgumentError.value(
        extrasMinor,
        'extrasMinor',
        'discount exceeds items',
      );
    }
    return ItemizedSplit(
      subtotalsMinor: Map.unmodifiable(subtotals),
      extrasMinor: Map.unmodifiable(extras),
      totalsMinor: Map.unmodifiable(totals),
    );
  }

  /// Largest-remainder (Hamilton) apportionment of [totalMinor] by integer
  /// [weights]. Negative totals (discounts) are apportioned by magnitude.
  static Map<K, int> allocate<K>(int totalMinor, Map<K, int> weights) {
    if (weights.isEmpty) {
      throw ArgumentError.value(weights, 'weights', 'is empty');
    }
    if (weights.values.any((w) => w < 0)) {
      throw ArgumentError.value(weights, 'weights', 'has a negative weight');
    }
    final weightSum = weights.values.fold<int>(0, (a, b) => a + b);
    if (weightSum == 0) {
      throw ArgumentError.value(weights, 'weights', 'sum to zero');
    }
    final sign = totalMinor < 0 ? -1 : 1;
    final magnitude = totalMinor.abs();
    final keys = weights.keys.toList(growable: false);
    final base = <int>[];
    final remainders = <int>[];
    var assigned = 0;
    for (final k in keys) {
      final numerator = magnitude * weights[k]!;
      base.add(numerator ~/ weightSum);
      remainders.add(numerator % weightSum);
      assigned += base.last;
    }
    final order = List<int>.generate(keys.length, (i) => i)
      ..sort((a, b) {
        final byRemainder = remainders[b].compareTo(remainders[a]);
        return byRemainder != 0 ? byRemainder : a.compareTo(b);
      });
    for (var i = 0; i < magnitude - assigned; i++) {
      base[order[i]] += 1;
    }
    return {for (var i = 0; i < keys.length; i++) keys[i]: sign * base[i]};
  }

  static void _requireParticipants<K>(List<K> participants) {
    if (participants.isEmpty) {
      throw ArgumentError.value(participants, 'participants', 'is empty');
    }
    if (participants.toSet().length != participants.length) {
      throw ArgumentError.value(participants, 'participants', 'has duplicates');
    }
  }
}

/// One line on a scanned receipt and who ate it.
class ReceiptLine<K> {
  const ReceiptLine({
    required this.label,
    required this.priceMinor,
    required this.sharedBy,
  });

  final String label;
  final int priceMinor;
  final List<K> sharedBy;
}

class ItemizedSplit<K> {
  const ItemizedSplit({
    required this.subtotalsMinor,
    required this.extrasMinor,
    required this.totalsMinor,
  });

  /// What each person's claimed items cost.
  final Map<K, int> subtotalsMinor;

  /// Each person's proportional slice of tax / tip / service / discount.
  final Map<K, int> extrasMinor;

  /// What each person owes in total.
  final Map<K, int> totalsMinor;

  int get billTotalMinor => totalsMinor.values.fold(0, (a, b) => a + b);
}

class SplitMismatchError extends ArgumentError {
  SplitMismatchError({required this.expectedMinor, required this.actualMinor})
    : super('Shares add up to $actualMinor but the bill is $expectedMinor');

  final int expectedMinor;
  final int actualMinor;
}

class UnclaimedItemError extends ArgumentError {
  UnclaimedItemError(this.itemLabel)
    : super('Nobody claimed "$itemLabel"; assign it before splitting');

  final String itemLabel;
}
