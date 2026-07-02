import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

export 'light_theme.dart';
export 'dark_theme.dart';

/// Notifier class to manage the active theme mode state.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Provider exposing the active theme mode.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// A convenience class to group Light and Dark themes.
class AppTheme {
  AppTheme._();

  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;
}
