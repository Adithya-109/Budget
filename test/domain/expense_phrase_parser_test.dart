import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitburn/core/database/enums.dart';
import 'package:splitburn/domain/category_classifier.dart';
import 'package:splitburn/domain/expense_draft.dart';
import 'package:splitburn/domain/expense_phrase_parser.dart';

void main() {
  // Shared with ios/RunnerTests so the Dart and Swift parsers stay identical.
  final fixtures = (jsonDecode(
    File('test/fixtures/expense_phrases.json').readAsStringSync(),
  ) as List).cast<Map<String, Object?>>();

  group('shared fixtures', () {
    for (final fixture in fixtures) {
      final input = fixture['input']! as String;
      test(input.isEmpty ? '(empty)' : input, () {
        final parsed = ExpensePhraseParser.parse(input);
        if (fixture['amount_minor'] == null) {
          expect(parsed, isNull);
          return;
        }
        expect(parsed, isNotNull);
        expect(parsed!.amountMinor, fixture['amount_minor']);
        expect(parsed.merchant, fixture['merchant']);
        expect(parsed.friends, (fixture['friends']! as List).cast<String>());
        expect(parsed.payer, fixture['payer']);
        expect(parsed.category.code, fixture['category']);
      });
    }
  });

  test('toDraft builds the 450 / 3 = 150 split', () {
    final parsed = ExpensePhraseParser.parse(
      "Spent 450 on Domino's with Rahul and Priya",
    )!;
    final draft = parsed.toDraft(
      resolveFriend: (name) => FriendRef(id: 'id-$name', name: name),
      source: TxnSource.voiceIntent,
    );
    expect(draft.myShareMinor, 15000);
    expect(draft.friendShares.values, [15000, 15000]);
    expect(draft.paidByMe, isTrue);
    expect(draft.source, TxnSource.voiceIntent);
  });

  test('toDraft for a friend-paid phrase owes the payer', () {
    final draft = ExpensePhraseParser.parse('Rahul paid 300 for chai')!.toDraft(
      resolveFriend: (name) => FriendRef(id: name, name: name),
    );
    expect(draft.payer, isA<PaidByFriend>());
    expect(draft.myShareMinor, 15000);
  });

  test('classifier matches by prefix only for 4+ letter keywords', () {
    expect(CategoryClassifier.classify("Domino's Pizza"), TxnCategory.food);
    expect(CategoryClassifier.classify('Olamide'), TxnCategory.other);
    expect(CategoryClassifier.classify('Ola cab'), TxnCategory.transit);
    expect(CategoryClassifier.classify('Wi-Fi'), TxnCategory.utilities);
  });
}
