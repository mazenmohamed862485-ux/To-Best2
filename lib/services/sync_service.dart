import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/app_models.dart';
import 'api_service.dart';
import 'db_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final db = ref.watch(dbServiceProvider);
  return SyncService(api, db);
});

class SyncService {
  final ApiService _api;
  final DbService _db;

  Timer? _autoSyncTimer;
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  SyncService(this._api, this._db);

  // ── Start auto-sync ───────────────────────────────────
  void startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.autoSyncIntervalMs),
      (_) => flushQueue(),
    );

    // Sync on reconnect
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        flushQueue();
      }
    });
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _connectivitySub?.cancel();
    _autoSyncTimer = null;
    _connectivitySub = null;
  }

  // ── Check online ─────────────────────────────────────
  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ── Enqueue item ──────────────────────────────────────
  Future<void> enqueue({
    required String action,
    required String key,
    required String uid,
    required dynamic data,
  }) async {
    final item = SyncQueueItem(
      action: action,
      key: key,
      uid: uid,
      data: jsonEncode(data),
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.addToSyncQueue(item);

    // Try immediate sync if online
    if (await isOnline) {
      flushQueue();
    }
  }

  // ── Flush queue ───────────────────────────────────────
  Future<int> flushQueue() async {
    if (_isSyncing) return 0;
    if (!await isOnline) return 0;

    _isSyncing = true;
    int failed = 0;

    try {
      final queue = await _db.getSyncQueue();
      for (final item in queue) {
        if (item.retries >= 5) {
          // Give up after 5 retries
          if (item.id != null) await _db.removeFromSyncQueue(item.id!);
          continue;
        }

        try {
          final data = jsonDecode(item.data);
          final ok = await _api.pushToCloud(
            action: item.action,
            key: item.key,
            uid: item.uid,
            data: data,
          );

          if (ok) {
            if (item.id != null) await _db.removeFromSyncQueue(item.id!);
          } else {
            if (item.id != null) await _db.incrementRetry(item.id!);
            failed++;
          }
        } catch (_) {
          if (item.id != null) await _db.incrementRetry(item.id!);
          failed++;
        }
      }
    } finally {
      _isSyncing = false;
    }

    return failed;
  }

  // ── Sync workout log ──────────────────────────────────
  Future<void> syncWorkoutLog(String uid, String dateKey, dynamic logData) async {
    await enqueue(
      action: AppConstants.actionSaveLog,
      key: dateKey,
      uid: uid,
      data: logData,
    );
  }

  // ── Sync attendance ───────────────────────────────────
  Future<void> syncAttendance(
      String uid, String monthKey, Map<String, String> attData) async {
    await enqueue(
      action: AppConstants.actionSaveAtt,
      key: monthKey,
      uid: uid,
      data: attData,
    );
  }

  // ── Sync meals ────────────────────────────────────────
  Future<void> syncMeals(String uid, String dateKey, dynamic mealsData) async {
    await enqueue(
      action: AppConstants.actionSaveMeals,
      key: dateKey,
      uid: uid,
      data: mealsData,
    );
  }

  // ── Sync meal plan ────────────────────────────────────
  Future<void> syncMealPlan(String uid, dynamic planData) async {
    await enqueue(
      action: AppConstants.actionSaveMealPlan,
      key: uid,
      uid: uid,
      data: planData,
    );
  }

  // ── Sync measurement ──────────────────────────────────
  Future<void> syncMeasurement(String uid, String dateKey, dynamic data) async {
    await enqueue(
      action: AppConstants.actionMeasurement,
      key: 'meas_$dateKey',
      uid: uid,
      data: data,
    );
  }

  // ── Sync setting ──────────────────────────────────────
  Future<void> syncSetting(String uid, String key, dynamic value) async {
    await enqueue(
      action: AppConstants.actionSetting,
      key: key,
      uid: uid,
      data: value,
    );
  }

  // ── Sync ex swaps ─────────────────────────────────────
  Future<void> syncExSwaps(String uid, Map<String, String> swaps) async {
    await enqueue(
      action: AppConstants.actionExSwap,
      key: 'ex_swaps_$uid',
      uid: uid,
      data: swaps,
    );
  }

  // ── Full pull from server ─────────────────────────────
  Future<bool> pullFromServer(String uid) async {
    if (!await isOnline) return false;

    final data = await _api.fetchFullData(uid);
    if (data == null) {
      final profileData = await _api.fetchUserData(uid);
      if (profileData != null) {
        await _db.seedFromCloud(uid, profileData);
        return true;
      }
      return false;
    }

    await _db.seedFromCloud(uid, data);
    return true;
  }

  void dispose() {
    stopAutoSync();
  }
}
