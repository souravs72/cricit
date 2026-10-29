import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.language = 'en',
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.notifications = true,
    this.autoplay = false,
    this.onboarded = false,
    this.signedIn = false,
    this.displayName = '',
    this.bookmarks = const {},
  });

  final String language;
  final ThemeMode themeMode;
  final double textScale;
  final bool notifications;
  final bool autoplay;
  final bool onboarded;
  final bool signedIn;
  final String displayName;
  final Set<String> bookmarks;

  bool get isHindi => language == 'hi';

  AppSettings copyWith({
    String? language,
    ThemeMode? themeMode,
    double? textScale,
    bool? notifications,
    bool? autoplay,
    bool? onboarded,
    bool? signedIn,
    String? displayName,
    Set<String>? bookmarks,
  }) {
    return AppSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      notifications: notifications ?? this.notifications,
      autoplay: autoplay ?? this.autoplay,
      onboarded: onboarded ?? this.onboarded,
      signedIn: signedIn ?? this.signedIn,
      displayName: displayName ?? this.displayName,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }

  static AppSettings fromPrefs(SharedPreferences prefs) {
    final theme = prefs.getString(_theme) ?? 'system';
    return AppSettings(
      language: prefs.getString(_lang) ?? 'en',
      themeMode: theme == 'light'
          ? ThemeMode.light
          : theme == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
      textScale: prefs.getDouble(_scale) ?? 1.0,
      notifications: prefs.getBool(_notify) ?? true,
      autoplay: prefs.getBool(_autoplay) ?? false,
      onboarded: prefs.getBool(_onboarded) ?? false,
      signedIn: prefs.getBool(_signedIn) ?? false,
      displayName: prefs.getString(_name) ?? '',
      bookmarks: {
        ...(prefs.getStringList(_bookmarks) ??
            const [
              '0192f1a0-0000-7000-8000-000000000001',
              '0192f1a0-0000-7000-8000-000000000004',
              '0192f1a0-0000-7000-8000-000000000011',
            ]),
      },
    );
  }
}

const _lang = 'language';
const _theme = 'theme_mode';
const _scale = 'text_scale';
const _notify = 'notifications';
const _autoplay = 'autoplay';
const _onboarded = 'onboarded';
const _signedIn = 'signed_in';
const _name = 'display_name';
const _bookmarks = 'bookmarks';

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences? _prefs;
  var _ready = false;

  bool get ready => _ready;

  @override
  AppSettings build() => const AppSettings();

  Future<void> hydrate() async {
    _prefs = await SharedPreferences.getInstance();
    state = AppSettings.fromPrefs(_prefs!);
    _ready = true;
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _prefs?.setString(_lang, language);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setString(
      _theme,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system',
    );
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    await _prefs?.setDouble(_scale, scale);
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notifications: value);
    await _prefs?.setBool(_notify, value);
  }

  Future<void> setAutoplay(bool value) async {
    state = state.copyWith(autoplay: value);
    await _prefs?.setBool(_autoplay, value);
  }

  Future<void> completeOnboarding({
    bool signedIn = false,
    String displayName = '',
  }) async {
    state = state.copyWith(
      onboarded: true,
      signedIn: signedIn,
      displayName: displayName,
    );
    await _prefs?.setBool(_onboarded, true);
    await _prefs?.setBool(_signedIn, signedIn);
    await _prefs?.setString(_name, displayName);
  }

  Future<void> setDisplayName(String name) async {
    state = state.copyWith(displayName: name);
    await _prefs?.setString(_name, name);
  }

  Future<void> toggleBookmark(String id) async {
    final next = {...state.bookmarks};
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(bookmarks: next);
    await _prefs?.setStringList(_bookmarks, next.toList());
  }

  Future<void> signOut() async {
    state = state.copyWith(signedIn: false, displayName: '');
    await _prefs?.setBool(_signedIn, false);
    await _prefs?.setString(_name, '');
  }

  Future<void> deleteAccount() async {
    state = const AppSettings(onboarded: true);
    await _prefs?.clear();
    await _prefs?.setBool(_onboarded, true);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final bootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(settingsProvider.notifier).hydrate();
});
