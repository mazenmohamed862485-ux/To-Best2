import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/app_models.dart';
import '../models/workout_log_model.dart';

final dbServiceProvider = Provider<DbService>((ref) => DbService());

class DbService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'tobest.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSettings} (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableWorkoutLogs} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        session TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableAttendance} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        month TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableMeals} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        meal_type TEXT,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableMealPlans} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        data TEXT NOT NULL,
        updated_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncQueue} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        key_field TEXT NOT NULL,
        uid TEXT NOT NULL,
        data TEXT NOT NULL,
        ts INTEGER DEFAULT 0,
        retries INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotifications} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        data TEXT NOT NULL,
        read_flag INTEGER DEFAULT 0,
        created_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableMeasurements} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableProgressPhotos} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        local_path TEXT,
        server_url TEXT,
        notes TEXT,
        created_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableExSwaps} (
        uid TEXT NOT NULL,
        ex_name TEXT NOT NULL,
        swap_name TEXT NOT NULL,
        PRIMARY KEY (uid, ex_name)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableCustomExercises} (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        session TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE water_log (
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        amount_ml INTEGER DEFAULT 0,
        PRIMARY KEY (uid, date)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ─────────────────────────────────────────────────────
  // SETTINGS
  // ─────────────────────────────────────────────────────
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableSettings,
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      AppConstants.tableSettings,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(AppConstants.tableSettings, where: 'key = ?', whereArgs: [key]);
  }

  // ─────────────────────────────────────────────────────
  // USERS
  // ─────────────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    final db = await database;
    final rows = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    if (rows.isEmpty) return null;
    final data = jsonDecode(rows.first['data'] as String);
    return UserModel.fromJson(data);
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'updated_at DESC');
    return rows.map((r) {
      final data = jsonDecode(r['data'] as String);
      return UserModel.fromJson(data);
    }).toList();
  }

  Future<void> upsertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'uid': user.uid,
        'data': jsonEncode(user.toJson()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<UserModel?> getCurrentUser() async {
    final uid = await getSetting(AppConstants.keyCurrentUser);
    if (uid == null || uid.isEmpty) return null;
    return getUser(uid);
  }

  Future<void> setCurrentUser(UserModel user) async {
    await upsertUser(user);
    await setSetting(AppConstants.keyCurrentUser, user.uid);
  }

  Future<void> clearCurrentUser() async {
    await deleteSetting(AppConstants.keyCurrentUser);
  }

  // ─────────────────────────────────────────────────────
  // WORKOUT LOGS
  // ─────────────────────────────────────────────────────
  Future<void> saveWorkoutLog(WorkoutLog log) async {
    final db = await database;
    final id = '${log.uid}_${log.date}_${log.session}';
    await db.insert(
      AppConstants.tableWorkoutLogs,
      {
        'id': id,
        'uid': log.uid,
        'date': log.date,
        'session': log.session,
        'data': jsonEncode(log.toJson()),
        'synced': 0,
        'created_at': log.startTime > 0 ? log.startTime : DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WorkoutLog?> getWorkoutLog(String uid, String date, String session) async {
    final db = await database;
    final id = '${uid}_${date}_$session';
    final rows = await db.query(
      AppConstants.tableWorkoutLogs,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return WorkoutLog.fromJson(jsonDecode(rows.first['data'] as String));
  }

  /// Returns all logs for a user as Map<date, Map<session, WorkoutLog>>
  Future<Map<String, Map<String, WorkoutLog>>> getAllLogs(String uid) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableWorkoutLogs,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date DESC',
    );
    final result = <String, Map<String, WorkoutLog>>{};
    for (final row in rows) {
      final date = row['date'] as String;
      final session = row['session'] as String;
      final log = WorkoutLog.fromJson(jsonDecode(row['data'] as String));
      result[date] ??= {};
      result[date]![session] = log;
    }
    return result;
  }

  Future<List<WorkoutLog>> getLogsForExercise(String uid, String exerciseName) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableWorkoutLogs,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date ASC',
    );
    final result = <WorkoutLog>[];
    for (final row in rows) {
      final log = WorkoutLog.fromJson(jsonDecode(row['data'] as String));
      final hasEx = log.exercises.any((e) => e.name == exerciseName);
      if (hasEx) result.add(log);
    }
    return result;
  }

  Future<List<WorkoutLog>> getRecentLogs(String uid, {int limit = 10}) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableWorkoutLogs,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((r) => WorkoutLog.fromJson(jsonDecode(r['data'] as String))).toList();
  }

  // ─────────────────────────────────────────────────────
  // ATTENDANCE
  // ─────────────────────────────────────────────────────
  Future<Map<String, String>> getAttendance(String uid, String month) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableAttendance,
      where: 'uid = ? AND month = ?',
      whereArgs: [uid, month],
    );
    if (rows.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(rows.first['data'] as String));
  }

  Future<void> saveAttendance(
      String uid, String month, Map<String, String> data) async {
    final db = await database;
    await db.insert(
      AppConstants.tableAttendance,
      {
        'id': '${uid}_$month',
        'uid': uid,
        'month': month,
        'data': jsonEncode(data),
        'synced': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────
  // MEALS
  // ─────────────────────────────────────────────────────
  Future<List<MealEntry>> getMealsForDate(String uid, String date) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableMeals,
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => MealEntry.fromJson(jsonDecode(r['data'] as String))).toList();
  }

  Future<void> saveMealEntry(MealEntry entry) async {
    final db = await database;
    await db.insert(
      AppConstants.tableMeals,
      {
        'id': entry.id,
        'uid': entry.uid,
        'date': entry.date,
        'meal_type': entry.mealType,
        'data': jsonEncode(entry.toJson()),
        'synced': 0,
        'created_at': entry.ts,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMealEntry(String id) async {
    final db = await database;
    await db.delete(AppConstants.tableMeals, where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────
  // MEAL PLAN
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getMealPlan(String uid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableMealPlans,
        where: 'uid = ?', whereArgs: [uid]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String);
  }

  Future<void> saveMealPlan(String uid, Map<String, dynamic> plan) async {
    final db = await database;
    await db.insert(
      AppConstants.tableMealPlans,
      {
        'id': uid,
        'uid': uid,
        'data': jsonEncode(plan),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────
  // WATER LOG
  // ─────────────────────────────────────────────────────
  Future<int> getWaterLog(String uid, String date) async {
    final db = await database;
    final rows = await db.query(
      'water_log',
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['amount_ml'] as int?) ?? 0;
  }

  Future<void> saveWaterLog(String uid, String date, int amountMl) async {
    final db = await database;
    await db.insert(
      'water_log',
      {'uid': uid, 'date': date, 'amount_ml': amountMl},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────
  // MEASUREMENTS
  // ─────────────────────────────────────────────────────
  Future<List<Measurement>> getMeasurements(String uid) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableMeasurements,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date DESC',
    );
    return rows.map((r) => Measurement.fromJson(jsonDecode(r['data'] as String))).toList();
  }

  Future<void> saveMeasurement(Measurement m) async {
    final db = await database;
    final id = '${m.uid}_${m.date}';
    await db.insert(
      AppConstants.tableMeasurements,
      {
        'id': id,
        'uid': m.uid,
        'date': m.date,
        'data': jsonEncode(m.toJson()),
        'synced': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────
  // PROGRESS PHOTOS
  // ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getProgressPhotos(String uid) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableProgressPhotos,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date DESC',
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> saveProgressPhoto(Map<String, dynamic> photo) async {
    final db = await database;
    await db.insert(
      AppConstants.tableProgressPhotos,
      photo,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────
  // EX SWAPS
  // ─────────────────────────────────────────────────────
  Future<Map<String, String>> getExSwaps(String uid) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableExSwaps,
      where: 'uid = ?',
      whereArgs: [uid],
    );
    final result = <String, String>{};
    for (final r in rows) {
      result[r['ex_name'] as String] = r['swap_name'] as String;
    }
    return result;
  }

  Future<void> setExSwap(String uid, String exName, String swapName) async {
    final db = await database;
    await db.insert(
      AppConstants.tableExSwaps,
      {'uid': uid, 'ex_name': exName, 'swap_name': swapName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeExSwap(String uid, String exName) async {
    final db = await database;
    await db.delete(
      AppConstants.tableExSwaps,
      where: 'uid = ? AND ex_name = ?',
      whereArgs: [uid, exName],
    );
  }

  // ─────────────────────────────────────────────────────
  // SYNC QUEUE
  // ─────────────────────────────────────────────────────
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    final db = await database;
    await db.insert(AppConstants.tableSyncQueue, {
      'action': item.action,
      'key_field': item.key,
      'uid': item.uid,
      'data': item.data,
      'ts': item.ts > 0 ? item.ts : DateTime.now().millisecondsSinceEpoch,
      'retries': item.retries,
    });
  }

  Future<List<SyncQueueItem>> getSyncQueue() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableSyncQueue,
      orderBy: 'ts ASC',
      limit: 50,
    );
    return rows.map((r) => SyncQueueItem(
      id: r['id'] as int?,
      action: r['action'] as String,
      key: r['key_field'] as String,
      uid: r['uid'] as String,
      data: r['data'] as String,
      ts: r['ts'] as int,
      retries: (r['retries'] as int?) ?? 0,
    )).toList();
  }

  Future<void> removeFromSyncQueue(int id) async {
    final db = await database;
    await db.delete(AppConstants.tableSyncQueue, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ${AppConstants.tableSyncQueue} SET retries = retries + 1 WHERE id = ?',
      [id],
    );
  }

  // ─────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────────────────
  Future<List<AppNotification>> getNotifications(String uid) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableNotifications,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
      limit: 50,
    );
    return rows.map((r) => AppNotification.fromJson(jsonDecode(r['data'] as String))).toList();
  }

  Future<void> addNotification(String uid, Map<String, dynamic> notif) async {
    final db = await database;
    final id = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final full = {'id': id, 'uid': uid, ...notif, 'ts': DateTime.now().millisecondsSinceEpoch};
    await db.insert(AppConstants.tableNotifications, {
      'id': id,
      'uid': uid,
      'data': jsonEncode(full),
      'read_flag': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> markNotificationsRead(String uid) async {
    final db = await database;
    await db.update(
      AppConstants.tableNotifications,
      {'read_flag': 1},
      where: 'uid = ? AND read_flag = 0',
      whereArgs: [uid],
    );
  }

  Future<int> getUnreadNotificationCount(String uid) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppConstants.tableNotifications} WHERE uid = ? AND read_flag = 0',
      [uid],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─────────────────────────────────────────────────────
  // SUBSCRIPTION CONFIG
  // ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getSubscriptionConfig() async {
    final raw = await getSetting('sub_config');
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSubscriptionConfig(Map<String, dynamic> config) async {
    await setSetting('sub_config', jsonEncode(config));
  }

  // ─────────────────────────────────────────────────────
  // SEED FROM CLOUD
  // ─────────────────────────────────────────────────────
  Future<void> seedFromCloud(String uid, Map<String, dynamic> data) async {
    // Save workout logs
    if (data['logs'] is Map) {
      final logs = data['logs'] as Map;
      for (final dateEntry in logs.entries) {
        for (final sessionEntry in (dateEntry.value as Map).entries) {
          try {
            final log = WorkoutLog.fromJson(sessionEntry.value);
            await saveWorkoutLog(log);
          } catch (_) {}
        }
      }
    }

    // Save attendance
    if (data['attendance'] is Map) {
      final att = data['attendance'] as Map;
      for (final monthEntry in att.entries) {
        try {
          await saveAttendance(uid, monthEntry.key, Map<String, String>.from(monthEntry.value));
        } catch (_) {}
      }
    }

    // Save meals
    if (data['meals'] is Map) {
      final meals = data['meals'] as Map;
      for (final dateEntry in meals.entries) {
        if (dateEntry.value is List) {
          for (final m in dateEntry.value as List) {
            try {
              await saveMealEntry(MealEntry.fromJson(m));
            } catch (_) {}
          }
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────
  // CLOSE
  // ─────────────────────────────────────────────────────
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
