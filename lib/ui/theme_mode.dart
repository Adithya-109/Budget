import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode.g.dart';

/// Preferences loaded in `main()` before the first frame (so the saved theme
/// never flashes). Null in tests and when the plugin is unavailable: the
/// choice then lives for the session only.
@Riverpod(keepAlive: true)
SharedPreferences? sharedPreferences(Ref ref) => null;

/// System / Light / Dark. A UI preference, so it lives in SharedPreferences,
/// not the shared ledger.
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  static const prefsKey = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider)?.getString(prefsKey);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider)?.setString(prefsKey, mode.name);
  }

  /// The header toggle: flip whatever is showing now to an explicit mode.
  Future<void> toggleFrom(Brightness showing) =>
      set(showing == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
