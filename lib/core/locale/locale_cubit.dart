import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale';

/// App-wide language selection. Mirrors [ThemeCubit]'s shape, but unlike
/// theme mode this is persisted — a fresh install stays English (the
/// fallback) until the user explicitly switches, and the choice then
/// survives restarts.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(_load(_prefs)) {
    Intl.defaultLocale = state.languageCode;
  }

  final SharedPreferences _prefs;

  static Locale _load(SharedPreferences prefs) {
    return prefs.getString(_prefsKey) == 'ar'
        ? const Locale('ar')
        : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    await _prefs.setString(_prefsKey, locale.languageCode);
    Intl.defaultLocale = locale.languageCode;
    emit(locale);
  }

  void toggle() => setLocale(state.languageCode == 'ar'
      ? const Locale('en')
      : const Locale('ar'));
}
