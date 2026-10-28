import 'dart:convert';

import 'package:drift/drift.dart';

import 'enums.dart';

class TxnCategoryConverter extends TypeConverter<TxnCategory, String> {
  const TxnCategoryConverter();

  @override
  TxnCategory fromSql(String fromDb) => TxnCategory.fromCode(fromDb);

  @override
  String toSql(TxnCategory value) => value.code;
}

class TxnSourceConverter extends TypeConverter<TxnSource, String> {
  const TxnSourceConverter();

  @override
  TxnSource fromSql(String fromDb) => TxnSource.fromCode(fromDb);

  @override
  String toSql(TxnSource value) => value.code;
}

class SplitDirectionConverter extends TypeConverter<SplitDirection, String> {
  const SplitDirectionConverter();

  @override
  SplitDirection fromSql(String fromDb) => SplitDirection.fromCode(fromDb);

  @override
  String toSql(SplitDirection value) => value.code;
}

/// A flatmate on a recurring bill, stored in
/// `subscriptions.auto_split_group_json`.
///
/// JSON shape (shared with native code):
/// `[{"friend_id":"…","friend_name":"…","payment_handle":"…","share":250.0}]`
/// `payment_handle` and `share` are optional; a missing `share` means "split
/// what's left equally".
class SplitGroupMember {
  const SplitGroupMember({
    required this.friendId,
    required this.friendName,
    this.paymentHandle,
    this.share,
  });

  factory SplitGroupMember.fromJson(Map<String, Object?> json) {
    final share = json['share'];
    return SplitGroupMember(
      friendId: json['friend_id']! as String,
      friendName: json['friend_name']! as String,
      paymentHandle: json['payment_handle'] as String?,
      share: share == null ? null : (share as num).toDouble(),
    );
  }

  final String friendId;
  final String friendName;
  final String? paymentHandle;

  /// Fixed share in major units, or `null` for an equal split.
  final double? share;

  Map<String, Object?> toJson() => {
    'friend_id': friendId,
    'friend_name': friendName,
    if (paymentHandle != null) 'payment_handle': paymentHandle,
    if (share != null) 'share': share,
  };

  @override
  bool operator ==(Object other) =>
      other is SplitGroupMember &&
      other.friendId == friendId &&
      other.friendName == friendName &&
      other.paymentHandle == paymentHandle &&
      other.share == share;

  @override
  int get hashCode => Object.hash(friendId, friendName, paymentHandle, share);
}

class SplitGroupConverter
    extends TypeConverter<List<SplitGroupMember>, String> {
  const SplitGroupConverter();

  @override
  List<SplitGroupMember> fromSql(String fromDb) {
    if (fromDb.trim().isEmpty) return const [];
    final decoded = jsonDecode(fromDb) as List<Object?>;
    return [
      for (final entry in decoded)
        SplitGroupMember.fromJson((entry! as Map).cast<String, Object?>()),
    ];
  }

  @override
  String toSql(List<SplitGroupMember> value) =>
      jsonEncode([for (final member in value) member.toJson()]);
}
