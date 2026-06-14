import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/workout_log_model.dart';
import '../../../providers/app_providers.dart';
import '../../../services/db_service.dart';
import '../../../data/config/programs_config.dart';

final homeProvider = StateNotifierProvider.autoDispose<HomeNotifier, HomeState>((ref) {
  final db = ref.watch(dbServiceProvider);
  final user = ref.watch(authStateProvider).user;
  final notifier = HomeNotifier(db, user?.uid ?? '', user?.program, user?.programDays);
  notifier.load();
  return notifier;
});

class HomeState {
  final bool isLoading;
  final int totalSessions;
  final int streak;
  final int gymDaysThisMonth;
  final String? todaySession;
  final bool isTodayDone;
  final List<PersonalRecord> latestPRs;

  const HomeState({
    this.isLoading = true,
    this.totalSessions = 0,
    this.streak = 0,
    this.gymDaysThisMonth = 0,
    this.todaySession,
    this.isTodayDone = false,
    this.latestPRs = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    int? totalSessions,
    int? streak,
    int? gymDaysThisMonth,
    String? todaySession,
    bool? isTodayDone,
    List<PersonalRecord>? latestPRs,
    bool clearSession = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      totalSessions: totalSessions ?? this.totalSessions,
      streak: streak ?? this.streak,
      gymDaysThisMonth: gymDaysThisMonth ?? this.gymDaysThisMonth,
      todaySession: clearSession ? null : (todaySession ?? this.todaySession),
      isTodayDone: isTodayDone ?? this.isTodayDone,
      latestPRs: latestPRs ?? this.latestPRs,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final DbService _db;
  final String _uid;
  final String? _program;
  final int? _programDays;

  HomeNotifier(this._db, this._uid, this._program, this._programDays)
      : super(const HomeState());

  Future<void> load() async {
    if (_uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);

    final today = AppUtils.todayKey();
    final month = AppUtils.monthKey();

    // Attendance
    final att = await _db.getAttendance(_uid, month);
    final gymDays = att.values.where((v) => v == 'GYM').length;

    // All logs for stats
    final allLogs = await _db.getAllLogs(_uid);
    final totalSessions = allLogs.values.fold(0, (sum, m) => sum + m.length);

    // Streak
    final flatAtt = <String, String>{};
    final prevMonth = DateTime.now().subtract(const Duration(days: 31));
    final prevMonthKey = AppUtils.monthKeyFor(prevMonth);
    final prevAtt = await _db.getAttendance(_uid, prevMonthKey);
    flatAtt.addAll(prevAtt);
    flatAtt.addAll(att);
    final streak = AppUtils.calcStreak(flatAtt);

    // Today's session
    final String? todaySession = _getTodaySession(allLogs);

    // Is today done?
    final isTodayDone = todaySession != null &&
        allLogs[today] != null &&
        allLogs[today]!.containsKey(todaySession);

    // Latest PRs
    final prs = await _computePRs(allLogs);

    state = HomeState(
      isLoading: false,
      totalSessions: totalSessions,
      streak: streak,
      gymDaysThisMonth: gymDays,
      todaySession: todaySession,
      isTodayDone: isTodayDone,
      latestPRs: prs,
    );
  }

  String? _getTodaySession(Map<String, Map<String, WorkoutLog>> allLogs) {
    if (_program == null || _programDays == null) return null;

    final cfg = TrainingPrograms.findById(_program!);
    if (cfg == null) return null;

    final sessions = cfg.getSessions(_programDays!);
    if (sessions.isEmpty) return null;

    // Count completed sessions to determine which is next
    int completedCount = 0;
    final sortedDates = allLogs.keys.toList()..sort();
    for (final date in sortedDates) {
      completedCount += allLogs[date]!.length;
    }

    final nextIndex = completedCount % sessions.length;
    return sessions[nextIndex];
  }

  Future<List<PersonalRecord>> _computePRs(
      Map<String, Map<String, WorkoutLog>> allLogs) async {
    final prMap = <String, PersonalRecord>{};

    final sortedDates = allLogs.keys.toList()..sort();
    for (final date in sortedDates) {
      for (final log in allLogs[date]!.values) {
        for (final ex in log.exercises) {
          final ep = ex.epley1RM;
          final bestSet = ex.bestSet;
          if (bestSet == null || ep <= 0) continue;

          final existing = prMap[ex.name];
          if (existing == null || ep > existing.epley) {
            prMap[ex.name] = PersonalRecord(
              exerciseName: ex.name,
              weight: bestSet.weight,
              reps: bestSet.reps,
              epley: ep,
              date: date,
            );
          }
        }
      }
    }

    final prs = prMap.values.toList();
    prs.sort((a, b) => b.epley.compareTo(a.epley));
    return prs;
  }

  Future<void> refresh() async {
    await load();
  }
}
