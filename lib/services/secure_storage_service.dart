import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import '../core/constants/app_constants.dart';

  final secureStorageProvider = Provider<SecureStorageService>((ref) {
    return SecureStorageService();
  });

  class SecureStorageService {
    static const _storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );

    Future<void> set(String key, String value) async {
      await _storage.write(key: key, value: value);
    }

    Future<String?> get(String key) async {
      return _storage.read(key: key);
    }

    Future<void> delete(String key) async {
      await _storage.delete(key: key);
    }

    Future<void> clear() async {
      await _storage.deleteAll();
    }

    // ── Specific methods ──────────────────────────────────
    Future<void> setSecretKey(String value) async {
      await set('app_secret_key', value);
    }

    Future<String?> getSecretKey() async {
      final stored = await get('app_secret_key');
      return stored ?? AppConstants.defaultSecretKey;
    }

    Future<void> clearSecretKey() async {
      await delete('app_secret_key');
    }

    Future<void> setSessionToken(String token) async {
      await set('session_token', token);
    }

    Future<String?> getSessionToken() async {
      return get('session_token');
    }

    Future<void> clearSessionToken() async {
      await delete('session_token');
    }

    Future<void> clearAll() async {
      await clear();
    }
  }
  