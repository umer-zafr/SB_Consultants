import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Persistent storage key for user's selected ThemeMode.
const String _kThemeModePrefsKey = 'sb_consultants_theme_mode_v1';

/// Notifier that manages the active ThemeMode (Light vs Dark) with persistence
/// via [SharedPreferences] so the selection survives app restarts.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  bool get isDarkMode => state == ThemeMode.dark;

  /// Toggles between light and dark theme, persisting the choice.
  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await _persist(next);
  }

  /// Sets dark mode explicitly and persists the choice.
  Future<void> setDarkMode(bool isDark) async {
    final next = isDark ? ThemeMode.dark : ThemeMode.light;
    if (state != next) {
      state = next;
      await _persist(next);
    }
  }

  /// Allows callers to assign a [ThemeMode] directly with persistence.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state != mode) {
      state = mode;
      await _persist(mode);
    }
  }

  // ----- persistence helpers -----

  Future<void> _restore() async {
    try {
      final prefs = StorageService.instance;
      final saved = prefs.getString(_kThemeModePrefsKey);
      if (saved == 'dark' || saved == 'light' || saved == 'system') {
        final mode = switch (saved) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => ThemeMode.system,
        };
        // Use a microtask so the Notifier is fully built before state change.
        Future.microtask(() {
          try {
            state = mode;
          } catch (_) {
            // Notifier already disposed.
          }
        });
      }
    } catch (_) {
      // Graceful fallback: keep default ThemeMode.light.
    }
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final value = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
      await StorageService.instance.setString(_kThemeModePrefsKey, value);
    } catch (_) {
      // Persistence failure should not break the UI. Theme still updates.
    }
  }
}

/// Global provider for the application's persistent ThemeMode.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
