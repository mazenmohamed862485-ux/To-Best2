import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import 'secure_storage_service.dart';
import 'db_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final dbService = ref.watch(dbServiceProvider);
  return ApiService(secureStorage, dbService);
});

class ApiService {
  final SecureStorageService _secureStorage;
  final DbService _db;

  late final Dio _dio;

  ApiService(this._secureStorage, this._db) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: AppConstants.apiTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeoutMs),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    ));
  }

  // ── Core fetch ────────────────────────────────────────
  Future<Map<String, dynamic>?> _fetch(Map<String, dynamic> payload) async {
    final url = await _db.getSetting(AppConstants.keyWebAppUrl);
    if (url == null || url.isEmpty) return null;

    final secret = await _secureStorage.getSecretKey();
    final token = await _secureStorage.get(AppConstants.keySessionToken);

    final fullPayload = {
      ...payload,
      'secret': secret ?? '',
      if (token != null && token.isNotEmpty) 'sessionToken': token,
    };

    try {
      final response = await _dio.post(
        url,
        data: 'payload=${Uri.encodeComponent(jsonEncode(fullPayload))}',
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>?;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        // Silent fail in production
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Public fetch — no secret required (for forgot-password, ping, etc.)
  Future<Map<String, dynamic>?> _fetchPublic(Map<String, dynamic> payload) async {
    final url = await _db.getSetting(AppConstants.keyWebAppUrl);
    if (url == null || url.isEmpty) return null;

    try {
      final response = await _dio.post(
        url,
        data: 'payload=${Uri.encodeComponent(jsonEncode(payload))}',
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode != 200) return null;
      final data = response.data;
      if (data is String) return jsonDecode(data) as Map<String, dynamic>?;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> get _isConfigured async {
    final url = await _db.getSetting(AppConstants.keyWebAppUrl);
    return url != null && url.isNotEmpty;
  }

  // ── Auth ──────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (!await _isConfigured) return {'ok': false, 'err': 'not_configured'};
    final res = await _fetch({'action': 'LOGIN', 'email': email, 'password': password});
    if (res == null) return {'ok': false, 'err': 'network'};
    if (res['ok'] == true && res['sessionToken'] != null) {
      await _secureStorage.set(AppConstants.keySessionToken, res['sessionToken']);
    }
    return res;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    if (!await _isConfigured) return {'ok': false, 'err': 'not_configured'};
    final res = await _fetch({'action': 'REGISTER', ...userData});
    return res ?? {'ok': false, 'err': 'network'};
  }

  Future<Map<String, dynamic>> changePassword(
      String uid, String oldPwd, String newPwd) async {
    final res = await _fetch({
      'action': 'CHANGE_PASSWORD',
      'uid': uid,
      'oldPwd': oldPwd,
      'newPwd': newPwd,
    });
    return res ?? {'ok': false};
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await _fetchPublic({'action': 'FORGOT_PASSWORD', 'email': email});
    return res ?? {'ok': false};
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword) async {
    final res = await _fetchPublic({
      'action': 'RESET_PASSWORD',
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
    return res ?? {'ok': false};
  }

  // ── Data sync ─────────────────────────────────────────
  Future<bool> pushToCloud({
    required String action,
    required String key,
    required String uid,
    required dynamic data,
  }) async {
    if (!await _isConfigured) return false;
    final res = await _fetch({'action': action, 'key': key, 'uid': uid, 'data': data});
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    if (!await _isConfigured) return null;
    final res = await _fetch({'action': 'FETCH_USER_DATA', 'uid': uid});
    return res?['ok'] == true ? res!['data'] : null;
  }

  Future<List<Map<String, dynamic>>?> fetchAllUsers() async {
    final res = await _fetch({'action': 'FETCH_ALL_USERS'});
    if (res?['ok'] != true) return null;
    return List<Map<String, dynamic>>.from(res!['users'] ?? []);
  }

  Future<Map<String, dynamic>?> fetchFullData(String uid) async {
    if (!await _isConfigured) return null;
    final res = await _fetch({'action': 'FULL_SYNC_PULL', 'uid': uid});
    return res?['ok'] == true ? res!['data'] : null;
  }

  // ── Admin ─────────────────────────────────────────────
  Future<bool> adminUpdateUser(String uid, Map<String, dynamic> fields) async {
    final res = await _fetch({'action': 'ADMIN_UPDATE_USER', 'uid': uid, 'fields': fields});
    return res?['ok'] == true;
  }

  Future<bool> adminApproveUser(String uid, bool approved) async {
    final res = await _fetch({'action': 'ADMIN_APPROVE', 'uid': uid, 'approved': approved});
    return res?['ok'] == true;
  }

  Future<bool> adminDeleteUser(String uid) async {
    final res = await _fetch({'action': 'ADMIN_DELETE_USER', 'uid': uid});
    return res?['ok'] == true;
  }

  Future<bool> approveProgram(String uid, String programId, int programDays) async {
    final res = await _fetch({
      'action': 'APPROVE_PROGRAM',
      'uid': uid,
      'programId': programId,
      'programDays': programDays,
    });
    return res?['ok'] == true;
  }

  // ── Chat ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchMessages(String roomId, int since) async {
    final res = await _fetch({'action': 'FETCH_MSGS', 'roomId': roomId, 'since': since});
    if (res?['ok'] != true) return [];
    return List<Map<String, dynamic>>.from(res!['messages'] ?? []);
  }

  Future<bool> sendMessage(String roomId, Map<String, dynamic> msg) async {
    final res = await _fetch({'action': 'SEND_MSG', 'roomId': roomId, 'msg': msg});
    return res?['ok'] == true;
  }

  Future<bool> deleteMessage(String roomId, String msgId) async {
    final res = await _fetch({'action': 'DELETE_MSG', 'roomId': roomId, 'msgId': msgId});
    return res?['ok'] == true;
  }

  Future<bool> editMessage(String roomId, String msgId, String newText) async {
    final res = await _fetch({
      'action': 'EDIT_MSG',
      'roomId': roomId,
      'msgId': msgId,
      'newText': newText,
    });
    return res?['ok'] == true;
  }

  Future<bool> pinMessage(String roomId, Map<String, dynamic> msg) async {
    final res = await _fetch({'action': 'PIN_MSG', 'roomId': roomId, 'msg': msg});
    return res?['ok'] == true;
  }

  Future<bool> unpinMessage(String roomId) async {
    final res = await _fetch({'action': 'UNPIN_MSG', 'roomId': roomId});
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>?> getPinnedMessage(String roomId) async {
    final res = await _fetch({'action': 'GET_PINNED', 'roomId': roomId});
    return res?['ok'] == true ? res!['pinned'] : null;
  }

  Future<bool> banUserFromChat(String uid, bool ban) async {
    final res = await _fetch({'action': 'CHAT_BAN', 'uid': uid, 'ban': ban});
    return res?['ok'] == true;
  }

  Future<bool> muteUserInChat(String uid, int muteUntil) async {
    final res = await _fetch({'action': 'CHAT_MUTE', 'uid': uid, 'muteUntil': muteUntil});
    return res?['ok'] == true;
  }

  // ── Subscriptions ─────────────────────────────────────
  Future<Map<String, dynamic>> submitSubscriptionPayment(
      String uid, Map<String, dynamic> data) async {
    if (!await _isConfigured) return {'ok': false, 'err': 'not_configured'};
    final res = await _fetch({'action': 'SUB_REQUEST', 'uid': uid, 'data': data});
    return res ?? {'ok': false, 'err': 'network'};
  }

  Future<List<Map<String, dynamic>>> getSubscriptionRequests() async {
    final res = await _fetch({'action': 'GET_SUB_REQUESTS'});
    if (res?['ok'] != true) return [];
    return List<Map<String, dynamic>>.from(res!['requests'] ?? []);
  }

  Future<bool> updateSubscriptionRequest(
      String id, String status, Map<String, dynamic> fields) async {
    final res = await _fetch({
      'action': 'UPDATE_SUB_REQUEST',
      'id': id,
      'status': status,
      'fields': fields,
    });
    return res?['ok'] == true;
  }

  Future<bool> saveSubscriptionConfig(Map<String, dynamic> config) async {
    final res = await _fetch({'action': 'SUB_CONFIG', 'data': config});
    return res?['ok'] == true;
  }

  // ── Promo codes ───────────────────────────────────────
  Future<Map<String, dynamic>> checkPromo(String code) async {
    if (!await _isConfigured || code.isEmpty) return {'ok': false};
    return (await _fetch({'action': 'PROMO_CHECK', 'code': code})) ?? {'ok': false};
  }

  Future<bool> createPromo(String code, double discount, int maxUses) async {
    final res = await _fetch({
      'action': 'PROMO_CREATE',
      'code': code,
      'discount': discount,
      'maxUses': maxUses,
    });
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>> listPromos() async {
    return (await _fetch({'action': 'PROMO_LIST'})) ?? {'ok': false, 'codes': []};
  }

  Future<bool> deletePromo(String code) async {
    final res = await _fetch({'action': 'PROMO_DELETE', 'code': code});
    return res?['ok'] == true;
  }

  // ── Guest codes ───────────────────────────────────────
  Future<Map<String, dynamic>> guestLogin(String code) async {
    return (await _fetchPublic({'action': 'GUEST_LOGIN', 'code': code})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> listGuestCodes() async {
    return (await _fetch({'action': 'GUEST_LIST'})) ?? {'ok': false, 'codes': []};
  }

  Future<bool> createGuestCode(String code) async {
    return (await _fetch({'action': 'GUEST_CREATE', 'code': code}))?['ok'] == true;
  }

  Future<bool> deleteGuestCode(String code) async {
    return (await _fetch({'action': 'GUEST_DELETE', 'code': code}))?['ok'] == true;
  }

  // ── Identity ban ──────────────────────────────────────
  Future<Map<String, dynamic>> banIdentity(Map<String, dynamic> banEntry) async {
    return (await _fetch({'action': 'BAN_IDENTITY', 'banEntry': banEntry})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> unbanIdentity(String banId) async {
    return (await _fetch({'action': 'UNBAN_IDENTITY', 'banId': banId})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> listBanned() async {
    return (await _fetch({'action': 'LIST_BANNED'})) ?? {'ok': false, 'list': []};
  }

  Future<Map<String, dynamic>> checkBan(String email, String phone) async {
    if (!await _isConfigured) return {'banned': false};
    return (await _fetchPublic({'action': 'CHECK_BAN', 'email': email, 'phone': phone})) ??
        {'banned': false};
  }

  // ── Force logout ──────────────────────────────────────
  Future<bool> forceLogoutUser(String uid, String token) async {
    final res = await _fetch({'action': 'FORCE_LOGOUT_USER', 'uid': uid, 'token': token});
    if (res?['ok'] == true) {
      await _secureStorage.delete(AppConstants.keySessionToken);
    }
    return res?['ok'] == true;
  }

  Future<bool> forceLogoutAllUsers(String token) async {
    return (await _fetch({'action': 'FORCE_LOGOUT_ALL', 'token': token}))?['ok'] == true;
  }

  // ── Profile picture ───────────────────────────────────
  Future<Map<String, dynamic>> saveProfilePicture(
      String uid, String imageData) async {
    if (!await _isConfigured) return {'ok': false, 'err': 'not_configured'};
    return (await _fetch({
          'action': 'SAVE_PROFILE_PIC',
          'uid': uid,
          'imageData': imageData,
        })) ??
        {'ok': false};
  }

  // ── Referral ──────────────────────────────────────────
  Future<Map<String, dynamic>> getReferralStats(String code) async {
    return (await _fetch({'action': 'GET_REFERRAL_STATS', 'code': code})) ?? {'ok': false};
  }

  // ── Audit log ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAuditLog() async {
    final res = await _fetch({'action': 'GET_AUDIT_LOG'});
    if (res?['ok'] != true) return [];
    return List<Map<String, dynamic>>.from(res!['logs'] ?? []);
  }

  // ── Connection test ───────────────────────────────────
  Future<bool> testConnection() async {
    final res = await _fetchPublic({'action': 'PING'});
    return res?['ok'] == true;
  }

  // ── AI (Gemini) ───────────────────────────────────────
  Future<String?> sendGeminiMessage(
      String apiKey, List<Map<String, dynamic>> messages) async {
    try {
      const endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
      final dio = Dio();
      final response = await dio.post(
        '$endpoint?key=$apiKey',
        data: jsonEncode({'contents': messages}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data;
      return data?['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString();
    } catch (_) {
      return null;
    }
  }
}
