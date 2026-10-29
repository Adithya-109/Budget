import 'dart:math' as math;

/// [from] owes [to] [amountMinor] (integer minor units, always positive).
class Debt<K> {
  const Debt({required this.from, required this.to, required this.amountMinor});

  final K from;
  final K to;
  final int amountMinor;

  @override
  bool operator ==(Object other) =>
      other is Debt<K> &&
      other.from == from &&
      other.to == to &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(from, to, amountMinor);

  @override
  String toString() => 'Debt($from → $to: $amountMinor)';
}

/// One shared bill inside a friend group: [payer] fronted it and each
/// participant consumed [sharesMinor]. The payer's own share may be included.
class GroupExpense<K> {
  const GroupExpense({required this.payer, required this.sharesMinor});

  final K payer;
  final Map<K, int> sharesMinor;
}

/// Min-cash-flow settlement for a friend group.
///
/// If A owes B ₹100 and B owes C ₹100, the group only needs one transfer:
/// A pays C. In general the people with a non-zero net balance can always
/// settle in `n − 1` transfers; the true minimum is `n − g`, where `g` is the
/// largest number of disjoint sub-groups whose balances each sum to zero.
/// Finding `g` is NP-hard, so groups of up to [defaultExactLimit] non-zero
/// members are solved exactly (O(2ⁿ·n) subset DP, ~0.5M steps at 15) and
/// larger groups fall back to pairing exact opposites, then greedy
/// largest-creditor / largest-debtor matching.
abstract final class DebtSimplifier {
  static const int defaultExactLimit = 15;

  /// Net position per person: positive = is owed money, negative = owes.
  /// People who net to zero are omitted. Iteration order is first appearance.
  static Map<K, int> netBalances<K>(Iterable<Debt<K>> debts) {
    final balances = <K, int>{};
    for (final debt in debts) {
      if (debt.amountMinor < 0) {
        throw ArgumentError.value(debt, 'debts', 'has a negative amount');
      }
      if (debt.from == debt.to || debt.amountMinor == 0) continue;
      balances[debt.from] = (balances[debt.from] ?? 0) - debt.amountMinor;
      balances[debt.to] = (balances[debt.to] ?? 0) + debt.amountMinor;
    }
    balances.removeWhere((_, v) => v == 0);
    return balances;
  }

  /// Raw "who owes the payer" edges for a set of group bills.
  static List<Debt<K>> debtsFromExpenses<K>(
    Iterable<GroupExpense<K>> expenses,
  ) {
    return [
      for (final expense in expenses)
        for (final MapEntry(key: person, value: share)
            in expense.sharesMinor.entries)
          if (person != expense.payer && share > 0)
            Debt(from: person, to: expense.payer, amountMinor: share),
    ];
  }

  /// The fewest transfers that leave everyone square.
  ///
  /// Above [exactLimit] the heuristic treats everyone as one group, which can
  /// cost more transfers than people who never shared a bill need; each
  /// connected sub-group is then also settled on its own and the shorter
  /// answer wins, so the result never exceeds the original debt count.
  static List<Debt<K>> simplify<K>(
    Iterable<Debt<K>> debts, {
    int exactLimit = defaultExactLimit,
  }) {
    final list = debts.toList(growable: false);
    final balances = netBalances(list);
    final settled = settleBalances(balances, exactLimit: exactLimit);
    if (balances.length <= exactLimit) return settled;

    final bySubGroup = [
      for (final group in _connectedGroups(list, balances))
        ...settleBalances(group, exactLimit: exactLimit),
    ];
    return bySubGroup.length < settled.length ? bySubGroup : settled;
  }

  /// [balances] split by who is linked through [debts] (union-find).
  static List<Map<K, int>> _connectedGroups<K>(
    List<Debt<K>> debts,
    Map<K, int> balances,
  ) {
    final parent = <K, K>{};
    K root(K p) {
      var r = parent.putIfAbsent(p, () => p);
      while (r != parent[r]) {
        r = parent[r] as K;
      }
      parent[p] = r;
      return r;
    }

    for (final d in debts) {
      if (d.from != d.to && d.amountMinor > 0) {
        parent[root(d.from)] = root(d.to);
      }
    }
    final groups = <K, Map<K, int>>{};
    balances.forEach((person, amount) {
      (groups[root(person)] ??= {})[person] = amount;
    });
    return groups.values.toList();
  }

  /// Settles arbitrary net [balances] (must sum to zero).
  static List<Debt<K>> settleBalances<K>(
    Map<K, int> balances, {
    int exactLimit = defaultExactLimit,
  }) {
    final people = <K>[];
    final amounts = <int>[];
    balances.forEach((person, amount) {
      if (amount != 0) {
        people.add(person);
        amounts.add(amount);
      }
    });
    final total = amounts.fold<int>(0, (a, b) => a + b);
    if (total != 0) {
      throw ArgumentError.value(balances, 'balances', 'sum to $total, not 0');
    }
    if (people.isEmpty) return const [];

    final groups = people.length <= exactLimit
        ? _optimalZeroSumGroups(amounts)
        : _heuristicGroups(amounts);

    final transfers = <Debt<K>>[];
    for (final group in groups) {
      _settleGroupGreedily(group, amounts, people, transfers);
    }
    return transfers;
  }

  /// Partitions indices into the maximum number of zero-sum groups.
  static List<List<int>> _optimalZeroSumGroups(List<int> amounts) {
    final n = amounts.length;
    final size = 1 << n;
    final sums = List<int>.filled(size, 0);
    for (var mask = 1; mask < size; mask++) {
      final lowBit = mask & -mask;
      sums[mask] = sums[mask ^ lowBit] + amounts[lowBit.bitLength - 1];
    }
    // dp[mask] = most zero-sum masks on a removal chain from mask down to ∅,
    // counting mask itself if it sums to zero.
    final dp = List<int>.filled(size, 0);
    for (var mask = 1; mask < size; mask++) {
      var best = 0;
      for (var i = 0; i < n; i++) {
        if (mask & (1 << i) != 0) best = math.max(best, dp[mask ^ (1 << i)]);
      }
      dp[mask] = best + (sums[mask] == 0 ? 1 : 0);
    }

    final groups = <List<int>>[];
    var mask = size - 1;
    var groupStart = mask;
    while (mask != 0) {
      final target = dp[mask] - (sums[mask] == 0 ? 1 : 0);
      var removed = -1;
      for (var i = 0; i < n; i++) {
        if (mask & (1 << i) != 0 && dp[mask ^ (1 << i)] == target) {
          removed = i;
          break;
        }
      }
      mask ^= 1 << removed;
      if (sums[mask] == 0) {
        groups.add(_bitsOf(groupStart ^ mask, n));
        groupStart = mask;
      }
    }
    return groups;
  }

  /// Large groups: pull out exact opposite pairs (one transfer each), then
  /// treat everyone left as one group.
  static List<List<int>> _heuristicGroups(List<int> amounts) {
    final groups = <List<int>>[];
    final waitingByAmount = <int, List<int>>{};
    final paired = <int>{};
    for (var i = 0; i < amounts.length; i++) {
      final partners = waitingByAmount[-amounts[i]];
      if (partners != null && partners.isNotEmpty) {
        final j = partners.removeAt(0);
        groups.add([j, i]);
        paired
          ..add(i)
          ..add(j);
      } else {
        (waitingByAmount[amounts[i]] ??= []).add(i);
      }
    }
    final rest = [
      for (var i = 0; i < amounts.length; i++)
        if (!paired.contains(i)) i,
    ];
    if (rest.isNotEmpty) groups.add(rest);
    return groups;
  }

  /// Largest debtor pays largest creditor until the group is square. Each
  /// transfer zeroes at least one member, so a group of k takes ≤ k − 1.
  static void _settleGroupGreedily<K>(
    List<int> group,
    List<int> amounts,
    List<K> people,
    List<Debt<K>> out,
  ) {
    final remaining = {for (final i in group) i: amounts[i]};
    while (true) {
      int? creditor;
      int? debtor;
      for (final i in group) {
        final v = remaining[i]!;
        if (v > 0 && (creditor == null || v > remaining[creditor]!)) {
          creditor = i;
        }
        if (v < 0 && (debtor == null || v < remaining[debtor]!)) {
          debtor = i;
        }
      }
      if (creditor == null || debtor == null) return;
      final amount = math.min(remaining[creditor]!, -remaining[debtor]!);
      out.add(
        Debt(from: people[debtor], to: people[creditor], amountMinor: amount),
      );
      remaining[creditor] = remaining[creditor]! - amount;
      remaining[debtor] = remaining[debtor]! + amount;
    }
  }

  static List<int> _bitsOf(int mask, int n) => [
    for (var i = 0; i < n; i++)
      if (mask & (1 << i) != 0) i,
  ];
}
