import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-wide light/dark toggle. Starts following the device theme; in-memory
/// only, so it resets to the device default on a fresh app launch.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  /// Flips between light and dark, resolving `system` against the device's
  /// current brightness the first time it's toggled.
  void toggle(Brightness platformBrightness) {
    final isDark = state == ThemeMode.dark ||
        (state == ThemeMode.system && platformBrightness == Brightness.dark);
    emit(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
