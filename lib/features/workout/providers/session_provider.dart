import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/workout_log_model.dart';
import '../../../providers/app_providers.dart';
import '../../../services/db_service.dart';
import '../../../services/sync_service.dart';
import '../../../data/config/programs_config.dart';

final sessionProvider = StateNotifierProvider.family
    .autoDispose<SessionNotifier, SessionState, String>(
  (ref, sessionName) {
    final db = ref.watch(dbServiceProvider);
    final sync = ref.watch(syncServiceProvider);
    final user = ref.watch(authStateProvider).user;
    final settings = ref.watch(appSettingsProvider);
    return SessionNotifier(
      db: db,
      sync: sync,
      uid: user?.uid ?? '',
      sessionName: sessionName,
      restTimerDuration: settings.restTimerDuration,
    )..load();
  },
);

class SessionState {
  final bool isLoading;
  final bool warmupDone;
  final List<ExerciseDef> exercises;
  final int currentExIndex;
  final Map<String, List<ExerciseSet>> currentSets;
  final Map<String, ExerciseLog> prevLogs;
  final Map<String, String> swaps;
  final bool restTimerActive;
  final int restTimeRemaining;
  final int restTimerDuration;
  final bool isComplete;
  final List<PersonalRecord> newPRs;

  const SessionState({
    this.isLoading = true,
    this.warmupDone = false,
    this.exercises = const [],
    this.currentExIndex = 0,
    this.currentSets = const {},
    this.prevLogs = const {},
    this.swaps = const {},
    this.restTimerActive = false,
    this.restTimeRemaining = 180,
    this.restTimerDuration = 180,
    this.isComplete = false,
    this.newPRs = const [],
  });

  SessionState copyWith({
    bool? isLoading,
    bool? warmupDone,
    List<ExerciseDef>? exercises,
    int? currentExIndex,
    Map<String, List<ExerciseSet>>? currentSets,
    Map<String, ExerciseLog>? prevLogs,
    Map<String, String>? swaps,
    bool? restTimerActive,
    int? restTimeRemaining,
    int? restTimerDuration,
    bool? isComplete,
    List<PersonalRecord>? newPRs,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      warmupDone: warmupDone ?? this.warmupDone,
      exercises: exercises ?? this.exercises,
      currentExIndex: currentExIndex ?? this.currentExIndex,
      currentSets: currentSets ?? this.currentSets,
      prevLogs: prevLogs ?? this.prevLogs,
      swaps: swaps ?? this.swaps,
      restTimerActive: restTimerActive ?? this.restTimerActive,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      isComplete: isComplete ?? this.isComplete,
      newPRs: newPRs ?? this.newPRs,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final DbService _db;
  final SyncService _sync;
  final String _uid;
  final String _sessionName;
  Timer? _restTimer;
  final int _startTime;

  SessionNotifier({
    required DbService db,
    required SyncService sync,
    required String uid,
    required String sessionName,
    int restTimerDuration = AppConstants.defaultRestTimerSecs,
  })  : _db = db,
        _sync = sync,
        _uid = uid,
        _sessionName = sessionName,
        _startTime = DateTime.now().millisecondsSinceEpoch,
        super(SessionState(restTimerDuration: restTimerDuration,
            restTimeRemaining: restTimerDuration));

  Future<void> load() async {
    // Load exercise list
    final exercises = ExerciseDatabase.getForSession(_sessionName);

    // Load previous logs for this session (last time it was done)
    final prevLogs = await _loadPrevLogs(_sessionName);

    // Load saved swaps
    final swaps = await _db.getExSwaps(_uid);

    // Load partial session if exists (app was closed mid-session)
    final today = AppUtils.todayKey();
    final existing = await _db.getWorkoutLog(_uid, today, _sessionName);

    Map<String, List<ExerciseSet>> currentSets = {};
    if (existing != null) {
      for (final ex in existing.exercises) {
        currentSets[ex.name] = ex.sets;
      }
    } else {
      // Pre-populate from previous session for UX
      for (final ex in exercises) {
        final prev = prevLogs[ex.name];
        if (prev != null && prev.sets.isNotEmpty) {
          currentSets[ex.name] = prev.sets.map((s) => s).toList();
        } else {
          currentSets[ex.name] = List.generate(
            ex.sets,
            (_) => ExerciseSet(weight: 0, reps: ex.repsMin),
          );
        }
      }
    }

    state = state.copyWith(
      isLoading: false,
      exercises: exercises,
      prevLogs: prevLogs,
      swaps: Map.from(swaps),
      currentSets: currentSets,
    );
  }

  Future<Map<String, ExerciseLog>> _loadPrevLogs(String session) async {
    final allLogs = await _db.getAllLogs(_uid);
    final today = AppUtils.todayKey();

    // Find the last time this session was done (before today)
    final sortedDates = allLogs.keys
        .where((d) => d != today)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    for (final date in sortedDates) {
      if (allLogs[date]?[session] != null) {
        final log = allLogs[date]![session]!;
        return {for (final ex in log.exercises) ex.name: ex};
      }
    }
    return {};
  }

  // ── Warmup ────────────────────────────────────────────
  void completeWarmup() {
    state = state.copyWith(warmupDone: true);
  }

  // ── Sets ──────────────────────────────────────────────
  void updateSet(String exerciseName, int setIndex,
      {double? weight, int? reps, double? rpe}) {
    final newSets = Map<String, List<ExerciseSet>>.from(state.currentSets);
    final sets = List<ExerciseSet>.from(newSets[exerciseName] ?? []);

    while (sets.length <= setIndex) {
      sets.add(const ExerciseSet());
    }

    final old = sets[setIndex];
    sets[setIndex] = ExerciseSet(
      weight: weight ?? old.weight,
      reps: reps ?? old.reps,
      rpe: rpe ?? old.rpe,
    );
    newSets[exerciseName] = sets;
    state = state.copyWith(currentSets: newSets);
  }

  // ── Navigation ────────────────────────────────────────
  void nextExercise() {
    _autoSavePartial();
    stopRestTimer();
    state = state.copyWith(currentExIndex: state.currentExIndex + 1);
  }

  void prevExercise() {
    if (state.currentExIndex > 0) {
      stopRestTimer();
      state = state.copyWith(currentExIndex: state.currentExIndex - 1);
    }
  }

  // ── Swaps ─────────────────────────────────────────────
  Future<void> setSwap(String exName, String swapName) async {
    await _db.setExSwap(_uid, exName, swapName);
    // Copy sets over
    final newSets = Map<String, List<ExerciseSet>>.from(state.currentSets);
    if (newSets.containsKey(exName)) {
      newSets[swapName] = newSets[exName]!;
    }
    final newSwaps = Map<String, String>.from(state.swaps);
    newSwaps[exName] = swapName;
    state = state.copyWith(swaps: newSwaps, currentSets: newSets);
    _sync.syncExSwaps(_uid, newSwaps);
  }

  Future<void> removeSwap(String exName) async {
    await _db.removeExSwap(_uid, exName);
    final newSwaps = Map<String, String>.from(state.swaps)..remove(exName);
    state = state.copyWith(swaps: newSwaps);
    _sync.syncExSwaps(_uid, newSwaps);
  }

  // ── Rest timer ────────────────────────────────────────
  void startRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(
      restTimerActive: true,
      restTimeRemaining: state.restTimerDuration,
    );
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.restTimeRemaining <= 1) {
        stopRestTimer();
        // Sound would play here via audio service
      } else {
        state = state.copyWith(restTimeRemaining: state.restTimeRemaining - 1);
      }
    });
  }

  void stopRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    state = state.copyWith(restTimerActive: false);
  }

  void resetRestTimer() {
    stopRestTimer();
    state = state.copyWith(restTimeRemaining: state.restTimerDuration);
  }

  // ── Finish session ────────────────────────────────────
  Future<void> finishSession() async {
    stopRestTimer();
    final log = _buildLog();
    await _saveLog(log);

    // Detect new PRs
    final newPRs = await _detectNewPRs(log);

    state = state.copyWith(isComplete: true, newPRs: newPRs);
  }

  Future<void> saveAndExit() async {
    stopRestTimer();
    final log = _buildLog();
    if (log.exercises.isNotEmpty) {
      await _saveLog(log);
    }
  }

  WorkoutLog _buildLog() {
    final exercises = <ExerciseLog>[];
    for (final ex in state.exercises) {
      final exName = state.swaps[ex.name] ?? ex.name;
      final sets = state.currentSets[exName] ?? [];
      final validSets = sets.where((s) => s.weight > 0 && s.reps > 0).toList();
      if (validSets.isEmpty) continue;
      exercises.add(ExerciseLog(
        name: exName,
        sets: validSets,
        altUsed: state.swaps[ex.name] != null ? ex.name : null,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    final endTime = DateTime.now().millisecondsSinceEpoch;
    return WorkoutLog(
      uid: _uid,
      date: AppUtils.todayKey(),
      session: _sessionName,
      exercises: exercises,
      duration: (endTime - _startTime) ~/ 1000,
      startTime: _startTime,
      endTime: endTime,
    );
  }

  Future<void> _saveLog(WorkoutLog log) async {
    await _db.saveWorkoutLog(log);
    await _sync.syncWorkoutLog(
      _uid,
      log.date,
      jsonEncode(log.toJson()),
    );
  }

  Future<void> _autoSavePartial() async {
    final log = _buildLog();
    if (log.exercises.isNotEmpty) {
      await _db.saveWorkoutLog(log);
    }
  }

  Future<List<PersonalRecord>> _detectNewPRs(WorkoutLog log) async {
    final allLogs = await _db.getAllLogs(_uid);
    final prs = <PersonalRecord>[];

    for (final ex in log.exercises) {
      double prevBestEpley = 0;
      for (final date in allLogs.keys) {
        if (date == log.date) continue;
        for (final sessionLog in allLogs[date]!.values) {
          for (final exLog in sessionLog.exercises) {
            if (exLog.name == ex.name) {
              final ep = exLog.epley1RM;
              if (ep > prevBestEpley) prevBestEpley = ep;
            }
          }
        }
      }
      final current = ex.epley1RM;
      if (current > prevBestEpley && current > 0) {
        prs.add(PersonalRecord(
          exerciseName: ex.name,
          weight: ex.bestSet?.weight ?? 0,
          reps: ex.bestSet?.reps ?? 0,
          epley: current,
          date: log.date,
        ));
      }
    }
    return prs;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
