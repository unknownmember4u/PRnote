import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prnote/core/constants/app_constants.dart';
import 'package:prnote/core/theme/app_theme.dart';

/// Theme mode enum including AMOLED
enum AppThemeMode { light, amoled }

/// Theme state notifier for global theme management
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.amoled) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(AppConstants.prefThemeMode) ?? AppConstants.themeModeAmoled;
    state = _fromString(themeStr);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, _toString(mode));
  }

  ThemeData get themeData {
    switch (state) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.amoled:
        return AppTheme.amoledTheme;
    }
  }

  AppThemeMode _fromString(String value) {
    switch (value) {
      case AppConstants.themeModeLight:
        return AppThemeMode.light;
      case AppConstants.themeModeAmoled:
        return AppThemeMode.amoled;
      default:
        return AppThemeMode.amoled;
    }
  }

  String _toString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return AppConstants.themeModeLight;
      case AppThemeMode.amoled:
        return AppConstants.themeModeAmoled;
    }
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// Convenience provider for current ThemeData
final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeProvider);
  switch (mode) {
    case AppThemeMode.light:
      return AppTheme.lightTheme;
    case AppThemeMode.amoled:
      return AppTheme.amoledTheme;
  }
});
