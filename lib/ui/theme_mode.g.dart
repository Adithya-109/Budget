// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Preferences loaded in `main()` before the first frame (so the saved theme
/// never flashes). Null in tests and when the plugin is unavailable: the
/// choice then lives for the session only.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Preferences loaded in `main()` before the first frame (so the saved theme
/// never flashes). Null in tests and when the plugin is unavailable: the
/// choice then lives for the session only.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences?,
          SharedPreferences?,
          SharedPreferences?
        >
    with $Provider<SharedPreferences?> {
  /// Preferences loaded in `main()` before the first frame (so the saved theme
  /// never flashes). Null in tests and when the plugin is unavailable: the
  /// choice then lives for the session only.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences? create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences?>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'efc8dcb2ecba79b47bc2d0862a052964c20a8faa';

/// System / Light / Dark. A UI preference, so it lives in SharedPreferences,
/// not the shared ledger.

@ProviderFor(AppThemeMode)
final appThemeModeProvider = AppThemeModeProvider._();

/// System / Light / Dark. A UI preference, so it lives in SharedPreferences,
/// not the shared ledger.
final class AppThemeModeProvider
    extends $NotifierProvider<AppThemeMode, ThemeMode> {
  /// System / Light / Dark. A UI preference, so it lives in SharedPreferences,
  /// not the shared ledger.
  AppThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  AppThemeMode create() => AppThemeMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appThemeModeHash() => r'56e68ef35632f04b75a6ab5deb702c1c88b01859';

/// System / Light / Dark. A UI preference, so it lives in SharedPreferences,
/// not the shared ledger.

abstract class _$AppThemeMode extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
