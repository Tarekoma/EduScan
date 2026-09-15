import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_theme_mode';

/// App-wide light/dark toggle. Starts following the device theme; once the
/// user toggles it, the explicit choice is persisted and reused on future
/// launches instead of falling back to the device default.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences prefs) {
    switch (prefs.getString(_prefsKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Flips between light and dark, resolving `system` against the device's
  /// current brightness the first time it's toggled.
  Future<void> toggle(Brightness platformBrightness) async {
    final isDark = state == ThemeMode.dark ||
        (state == ThemeMode.system && platformBrightness == Brightness.dark);
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setString(_prefsKey, next == ThemeMode.dark ? 'dark' : 'light');
    emit(next);
  }
}
