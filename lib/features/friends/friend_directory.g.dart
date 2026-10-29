// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_directory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(friendDirectory)
final friendDirectoryProvider = FriendDirectoryProvider._();

final class FriendDirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<FriendDirectory>,
          AsyncValue<FriendDirectory>,
          AsyncValue<FriendDirectory>
        >
    with $Provider<AsyncValue<FriendDirectory>> {
  FriendDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendDirectoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendDirectoryHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<FriendDirectory>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<FriendDirectory> create(Ref ref) {
    return friendDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<FriendDirectory> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<FriendDirectory>>(value),
    );
  }
}

String _$friendDirectoryHash() => r'30550a34639936d361f613eedb1c87cd4bc23aac';
