import '../../core/database/enums.dart';
import '../../domain/expense_draft.dart';
import '../../domain/split_calculator.dart';
import 'receipt_parser.dart';

enum SplitMode { equal, exact, percentage, receipt }

/// A receipt line and who tapped it.
class ClaimedItem {
  const ClaimedItem({required this.item, required this.claimedBy});

  final ReceiptItem item;
  final Set<Participant> claimedBy;

  ClaimedItem toggle(Participant p) => ClaimedItem(
    item: item,
    claimedBy: claimedBy.contains(p)
        ? ({...claimedBy}..remove(p))
        : {...claimedBy, p},
  );
}

/// Result of validating the split form: a draft ready to save, or the reason
/// it can't be saved yet (shown inline in the sheet).
sealed class SplitOutcome {
  const SplitOutcome();
}

final class SplitReady extends SplitOutcome {
  const SplitReady(this.draft, this.allocation);

  final ExpenseDraft draft;
  final Map<Participant, int> allocation;
}

final class SplitInvalid extends SplitOutcome {
  const SplitInvalid(this.message, {this.remainingMinor});

  final String message;

  /// For exact / percentage modes: how much is still unassigned
  /// (minor units, or basis points for percentages). Negative = over.
  final int? remainingMinor;
}

/// The split sheet's state, turned into an [ExpenseDraft] by [build].
/// Immutable; the sheet keeps the latest copy in its State.
class SplitForm {
  const SplitForm({
    this.merchant = '',
    this.totalMinor = 0,
    this.category = TxnCategory.food,
    this.mode = SplitMode.equal,
    this.payer = const Me(),
    this.participants = const [Me()],
    this.exactMinor = const {},
    this.basisPoints = const {},
    this.claimedItems = const [],
    this.receiptExtrasMinor = 0,
    this.source = TxnSource.app,
  });

  final String merchant;
  final int totalMinor;
  final TxnCategory category;
  final SplitMode mode;

  /// [Me] or a [FriendParticipant] who is also in [participants].
  final Participant payer;

  /// Everyone on the bill; always includes [Me].
  final List<Participant> participants;
  final Map<Participant, int> exactMinor;
  final Map<Participant, int> basisPoints;
  final List<ClaimedItem> claimedItems;

  /// Tax + tip + service − discount from the receipt (editable).
  final int receiptExtrasMinor;
  final TxnSource source;

  int get receiptTotalMinor =>
      claimedItems.fold(0, (sum, c) => sum + c.item.priceMinor) +
      receiptExtrasMinor;

  /// The bill total this form will save.
  int get effectiveTotalMinor =>
      mode == SplitMode.receipt ? receiptTotalMinor : totalMinor;

  SplitForm copyWith({
    String? merchant,
    int? totalMinor,
    TxnCategory? category,
    SplitMode? mode,
    Participant? payer,
    List<Participant>? participants,
    Map<Participant, int>? exactMinor,
    Map<Participant, int>? basisPoints,
    List<ClaimedItem>? claimedItems,
    int? receiptExtrasMinor,
    TxnSource? source,
  }) {
    final people = participants ?? this.participants;
    final nextPayer = payer ?? this.payer;
    return SplitForm(
      merchant: merchant ?? this.merchant,
      totalMinor: totalMinor ?? this.totalMinor,
      category: category ?? this.category,
      mode: mode ?? this.mode,
      // A payer removed from the bill falls back to the user.
      payer: people.contains(nextPayer) ? nextPayer : const Me(),
      participants: people,
      exactMinor: exactMinor ?? this.exactMinor,
      basisPoints: basisPoints ?? this.basisPoints,
      claimedItems: claimedItems ?? this.claimedItems,
      receiptExtrasMinor: receiptExtrasMinor ?? this.receiptExtrasMinor,
      source: source ?? this.source,
    );
  }

  /// Payer first, so the payer absorbs rounding (CLAUDE.md split rule).
  List<Participant> get _orderedPeople => [
    payer,
    for (final p in participants)
      if (p != payer) p,
  ];

  SplitOutcome build({DateTime? createdAt, String? receiptImagePath}) {
    if (merchant.trim().isEmpty) {
      return const SplitInvalid('Add what it was for.');
    }
    final Map<Participant, int> allocation;
    switch (mode) {
      case SplitMode.equal:
        if (totalMinor <= 0) return const SplitInvalid('Enter the amount.');
        allocation = SplitCalculator.equal(totalMinor, _orderedPeople);
      case SplitMode.exact:
        if (totalMinor <= 0) return const SplitInvalid('Enter the amount.');
        final shares = {for (final p in participants) p: exactMinor[p] ?? 0};
        final remaining =
            totalMinor - shares.values.fold<int>(0, (a, b) => a + b);
        if (remaining != 0) {
          return SplitInvalid(
            remaining > 0
                ? 'Assign the rest of the bill.'
                : 'Shares are more than the bill.',
            remainingMinor: remaining,
          );
        }
        allocation = shares;
      case SplitMode.percentage:
        if (totalMinor <= 0) return const SplitInvalid('Enter the amount.');
        final bps = {for (final p in _orderedPeople) p: basisPoints[p] ?? 0};
        final remaining = 10000 - bps.values.fold<int>(0, (a, b) => a + b);
        if (remaining != 0) {
          return SplitInvalid(
            remaining > 0
                ? 'Percentages must add up to 100%.'
                : 'Percentages are over 100%.',
            remainingMinor: remaining,
          );
        }
        allocation = SplitCalculator.percentage(totalMinor, bps);
      case SplitMode.receipt:
        if (claimedItems.isEmpty) {
          return const SplitInvalid('Scan a receipt or add items.');
        }
        final unclaimed = claimedItems.where((c) => c.claimedBy.isEmpty);
        if (unclaimed.isNotEmpty) {
          return SplitInvalid('Who had "${unclaimed.first.item.label}"?');
        }
        final ordered = _orderedPeople;
        final itemized = SplitCalculator.itemized([
          for (final c in claimedItems)
            ReceiptLine(
              label: c.item.label,
              priceMinor: c.item.priceMinor,
              sharedBy: [
                for (final p in ordered)
                  if (c.claimedBy.contains(p)) p,
              ],
            ),
        ], extrasMinor: receiptExtrasMinor);
        allocation = {
          for (final p in participants) p: itemized.totalsMinor[p] ?? 0,
        };
    }

    final payerParticipant = payer;
    if (payerParticipant is FriendParticipant &&
        (allocation[const Me()] ?? 0) == 0) {
      return const SplitInvalid("You have no share in a bill a friend paid.");
    }
    try {
      final draft = ExpenseDraft.fromAllocation(
        merchant: merchant.trim(),
        allocation: allocation,
        payer: switch (payerParticipant) {
          Me() => const PaidByMe(),
          FriendParticipant(:final friend) => PaidByFriend(friend),
        },
        category: category,
        source: mode == SplitMode.receipt ? TxnSource.ocr : source,
        createdAt: createdAt,
        receiptImagePath: receiptImagePath,
      );
      return SplitReady(draft, allocation);
    } on ArgumentError catch (e) {
      return SplitInvalid(
        e.message?.toString() ?? 'This split does not add up.',
      );
    }
  }
}
