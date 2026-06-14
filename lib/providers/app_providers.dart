import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/secure_storage_service.dart';

// ── SharedPreferences ──────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize via override in main');
});

// ── Connectivity ───────────────────────────────────────
final isOnlineProvider = StateProvider<bool>((ref) => true);

// ── App Settings ───────────────────────────────────────
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final db = ref.watch(dbServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppSettingsNotifier(db, prefs);
});

class AppSettings {
  final AppThemeType themeType;
  final Color accentColor;
  final String language; // 'ar' | 'en'
  final String handMode; // 'right' | 'left'
  final int restTimerDuration;
  final String restTimerSound;
  final bool showOldValues;
  final bool showEpley;
  final bool showRPE;
  final bool showRepSuggest;
  final bool showVolume;
  final bool wakeLock;
  final bool notifications;
  final bool motivationalMsgs;

  const AppSettings({
    this.themeType = AppThemeType.dark,
    this.accentColor = AppColors.accent,
    this.language = 'ar',
    this.handMode = 'right',
    this.restTimerDuration = AppConstants.defaultRestTimerSecs,
    this.restTimerSound = 'bell',
    this.showOldValues = true,
    this.showEpley = true,
    this.showRPE = true,
    this.showRepSuggest = true,
    this.showVolume = true,
    this.wakeLock = true,
    this.notifications = true,
    this.motivationalMsgs = true,
  });

  Locale get locale => Locale(language);

  TextDirection get textDirection {
    final isAr = language == 'ar';
    final isLeft = handMode == 'left';
    if (isAr) return isLeft ? TextDirection.ltr : TextDirection.rtl;
    return isLeft ? TextDirection.rtl : TextDirection.ltr;
  }

  AppSettings copyWith({
    AppThemeType? themeType,
    Color? accentColor,
    String? language,
    String? handMode,
    int? restTimerDuration,
    String? restTimerSound,
    bool? showOldValues,
    bool? showEpley,
    bool? showRPE,
    bool? showRepSuggest,
    bool? showVolume,
    bool? wakeLock,
    bool? notifications,
    bool? motivationalMsgs,
  }) {
    return AppSettings(
      themeType: themeType ?? this.themeType,
      accentColor: accentColor ?? this.accentColor,
      language: language ?? this.language,
      handMode: handMode ?? this.handMode,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      restTimerSound: restTimerSound ?? this.restTimerSound,
      showOldValues: showOldValues ?? this.showOldValues,
      showEpley: showEpley ?? this.showEpley,
      showRPE: showRPE ?? this.showRPE,
      showRepSuggest: showRepSuggest ?? this.showRepSuggest,
      showVolume: showVolume ?? this.showVolume,
      wakeLock: wakeLock ?? this.wakeLock,
      notifications: notifications ?? this.notifications,
      motivationalMsgs: motivationalMsgs ?? this.motivationalMsgs,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final DbService _db;
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._db, this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = _prefs.getString(AppConstants.keyTheme) ?? 'dark';
    final accentHex = _prefs.getString(AppConstants.keyAccentColor) ?? '#7C6EFF';
    final lang = _prefs.getString(AppConstants.keyLanguage) ?? 'ar';
    final hand = _prefs.getString(AppConstants.keyHandMode) ?? 'right';
    final restDur = _prefs.getInt(AppConstants.keyRestTimerDuration) ??
        AppConstants.defaultRestTimerSecs;
    final restSound = _prefs.getString(AppConstants.keyRestTimerSound) ?? 'bell';

    state = state.copyWith(
      themeType: _parseTheme(theme),
      accentColor: _parseColor(accentHex),
      language: lang,
      handMode: hand,
      restTimerDuration: restDur,
      restTimerSound: restSound,
      showOldValues: _prefs.getBool(AppConstants.keyShowOldValues) ?? true,
      showEpley: _prefs.getBool(AppConstants.keyShowEpley) ?? true,
      showRPE: _prefs.getBool(AppConstants.keyShowRPE) ?? true,
      showRepSuggest: _prefs.getBool(AppConstants.keyShowRepSuggest) ?? true,
      showVolume: _prefs.getBool(AppConstants.keyShowVolume) ?? true,
      wakeLock: _prefs.getBool(AppConstants.keyWakeLock) ?? true,
      notifications: _prefs.getBool(AppConstants.keyNotifications) ?? true,
      motivationalMsgs: _prefs.getBool(AppConstants.keyMotivationalMsgs) ?? true,
    );
  }

  Future<void> setTheme(AppThemeType type) async {
    state = state.copyWith(themeType: type);
    await _prefs.setString(AppConstants.keyTheme, type.name);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    await _prefs.setString(AppConstants.keyAccentColor, hex);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _prefs.setString(AppConstants.keyLanguage, lang);
  }

  Future<void> setHandMode(String mode) async {
    state = state.copyWith(handMode: mode);
    await _prefs.setString(AppConstants.keyHandMode, mode);
  }

  Future<void> setRestTimerDuration(int seconds) async {
    state = state.copyWith(restTimerDuration: seconds);
    await _prefs.setInt(AppConstants.keyRestTimerDuration, seconds);
  }

  Future<void> setRestTimerSound(String sound) async {
    state = state.copyWith(restTimerSound: sound);
    await _prefs.setString(AppConstants.keyRestTimerSound, sound);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    switch (key) {
      case AppConstants.keyShowOldValues:
        state = state.copyWith(showOldValues: value);
        break;
      case AppConstants.keyShowEpley:
        state = state.copyWith(showEpley: value);
        break;
      case AppConstants.keyShowRPE:
        state = state.copyWith(showRPE: value);
        break;
      case AppConstants.keyShowRepSuggest:
        state = state.copyWith(showRepSuggest: value);
        break;
      case AppConstants.keyShowVolume:
        state = state.copyWith(showVolume: value);
        break;
      case AppConstants.keyWakeLock:
        state = state.copyWith(wakeLock: value);
        break;
      case AppConstants.keyNotifications:
        state = state.copyWith(notifications: value);
        break;
      case AppConstants.keyMotivationalMsgs:
        state = state.copyWith(motivationalMsgs: value);
        break;
    }
  }

  static AppThemeType _parseTheme(String theme) {
    switch (theme) {
      case 'light': return AppThemeType.light;
      case 'luxury': return AppThemeType.luxury;
      case 'sports': return AppThemeType.sports;
      default: return AppThemeType.dark;
    }
  }

  static Color _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.accent;
    }
  }
}

// ── Auth State ─────────────────────────────────────────
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(dbServiceProvider);
  final api = ref.watch(apiServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  final secure = ref.watch(secureStorageProvider);
  return AuthNotifier(db, api, sync, secure);
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isFirstRun;
  final Map<String, dynamic>? subConfig;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isFirstRun = false,
    this.subConfig,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isFirstRun,
    Map<String, dynamic>? subConfig,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isFirstRun: isFirstRun ?? this.isFirstRun,
      subConfig: subConfig ?? this.subConfig,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final DbService _db;
  final ApiService _api;
  final SyncService _sync;
  final SecureStorageService _secure;

  AuthNotifier(this._db, this._api, this._sync, this._secure)
      : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final user = await _db.getCurrentUser();
    final subConfig = await _db.getSubscriptionConfig();

    if (user != null) {
      state = AuthState(
        user: user,
        isLoading: false,
        subConfig: subConfig,
      );
      _sync.startAutoSync();
      // Background refresh from server
      _refreshUserFromServer(user.uid);
    } else {
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> _refreshUserFromServer(String uid) async {
    try {
      final data = await _api.fetchUserData(uid);
      if (data != null) {
        final updated = UserModel.fromJson(data);
        await _db.upsertUser(updated);

        // Check force logout
        final savedToken = await _secure.get('force_logout_seen_$uid');
        if (updated.forceLogoutToken != null &&
            updated.forceLogoutToken != savedToken) {
          await logout();
          return;
        }

        state = state.copyWith(user: updated);
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.login(email, password);

      if (res['ok'] != true) {
        state = state.copyWith(
          isLoading: false,
          error: res['err']?.toString() ?? 'login_failed',
        );
        return false;
      }

      final userData = res['user'] ?? res['data'];
      if (userData == null) {
        state = state.copyWith(isLoading: false, error: 'no_user_data');
        return false;
      }

      final user = UserModel.fromJson(Map<String, dynamic>.from(userData));
      await _db.setCurrentUser(user);

      final subConfig = await _db.getSubscriptionConfig();
      state = AuthState(user: user, subConfig: subConfig);

      _sync.startAutoSync();
      _sync.pullFromServer(user.uid);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.register(userData);
      if (res['ok'] != true) {
        state = state.copyWith(
          isLoading: false,
          error: res['err']?.toString() ?? 'register_failed',
        );
        return false;
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> loginAsGuest(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.guestLogin(code);
      if (res['ok'] != true) {
        state = state.copyWith(isLoading: false, error: 'invalid_guest_code');
        return false;
      }
      final userData = res['user'] ?? res['data'];
      if (userData == null) {
        state = state.copyWith(isLoading: false, error: 'no_user_data');
        return false;
      }
      final user = UserModel.fromJson(Map<String, dynamic>.from(userData));
      await _db.setCurrentUser(user);
      state = AuthState(user: user);
      _sync.startAutoSync();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    _sync.stopAutoSync();
    await _secure.clearSessionToken();
    await _db.clearCurrentUser();
    state = const AuthState();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.upsertUser(user);
    state = state.copyWith(user: user);
  }

  Future<void> refreshUser() async {
    final user = state.user;
    if (user == null) return;
    await _refreshUserFromServer(user.uid);
  }

  Future<void> loadSubConfig() async {
    final cfg = await _db.getSubscriptionConfig();
    state = state.copyWith(subConfig: cfg);
  }
}

// ── View-as-user mode ──────────────────────────────────
final viewAsUserProvider = StateProvider<String?>((ref) => null);

// ── Unread notification count ──────────────────────────
final unreadNotifCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(authStateProvider).user;
  if (user == null) return 0;
  final db = ref.watch(dbServiceProvider);
  return db.getUnreadNotificationCount(user.uid);
});
