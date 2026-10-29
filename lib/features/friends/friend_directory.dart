import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/ledger_models.dart';
import '../../core/providers/database_providers.dart';
import '../../domain/expense_draft.dart';

part 'friend_directory.g.dart';

/// Friends the user has split with, looked up by name (case-insensitive).
/// Unknown names become new friends with a fresh id.
class FriendDirectory {
  FriendDirectory(Iterable<FriendBalance> balances)
    : friends = [for (final b in balances) b.friend],
      _byName = {
        for (final b in balances) b.friend.name.toLowerCase(): b.friend,
      };

  final List<FriendRef> friends;
  final Map<String, FriendRef> _byName;
  final Map<String, FriendRef> _created = {};

  static const _uuid = Uuid();

  FriendRef? find(String name) => _byName[name.trim().toLowerCase()];

  /// The existing friend called [name], or the same new friend for repeated
  /// lookups of a name nobody has used yet.
  FriendRef resolve(String name) {
    final key = name.trim().toLowerCase();
    return _byName[key] ??
        _created.putIfAbsent(
          key,
          () => FriendRef(id: _uuid.v4(), name: name.trim()),
        );
  }

  /// Name suggestions for autocomplete.
  Iterable<FriendRef> matching(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return friends;
    return friends.where((f) => f.name.toLowerCase().contains(q));
  }
}

@riverpod
AsyncValue<FriendDirectory> friendDirectory(Ref ref) =>
    ref.watch(friendBalancesProvider).whenData(FriendDirectory.new);
