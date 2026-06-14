import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/workout_log_model.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../services/db_service.dart';

final progressProvider =
    StateNotifierProvider.autoDispose<ProgressNotifier, ProgressState>((ref) {
  final db = ref.watch(dbServiceProvider);
  final user = ref.watch(authStateProvider).user;
  final n = ProgressNotifier(db, user?.uid ?? '');
  n.load();
  return n;
});

class PersonalRecordEntry {
  final String name;
  final double weight;
  final int reps;
  final double epley;
  final String date;
  const PersonalRecordEntry({required this.name, required this.weight, required this.reps, required this.epley, required this.date});
}

class ProgressState {
  final bool isLoading;
  final EvalResult? evalResult;
  final List<({String week, double volume})> weeklyVolume;
  final List<({String date, double weight})> weightHistory;
  final List<PersonalRecordEntry> prs;

  const ProgressState({
    this.isLoading = true,
    this.evalResult,
    this.weeklyVolume = const [],
    this.weightHistory = const [],
    this.prs = const [],
  });

  ProgressState copyWith({
    bool? isLoading,
    EvalResult? evalResult,
    List<({String week, double volume})>? weeklyVolume,
    List<({String date, double weight})>? weightHistory,
    List<PersonalRecordEntry>? prs,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      evalResult: evalResult ?? this.evalResult,
      weeklyVolume: weeklyVolume ?? this.weeklyVolume,
      weightHistory: weightHistory ?? this.weightHistory,
      prs: prs ?? this.prs,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final DbService _db;
  final String _uid;
  ProgressNotifier(this._db, this._uid) : super(const ProgressState());

  Future<void> load() async {
    if (_uid.isEmpty) { state = state.copyWith(isLoading: false); return; }
    state = state.copyWith(isLoading: true);
    final allLogs = await _db.getAllLogs(_uid);
    final measurements = await _db.getMeasurements(_uid);
    final weeklyVolume = _calcWeeklyVolume(allLogs);
    final prs = _calcPRs(allLogs);
    final evalResult = _evaluate(allLogs);
    final weightHistory = measurements.where((m) => m.weight != null)
        .map((m) => (date: m.date, weight: m.weight!)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    state = ProgressState(isLoading: false, evalResult: evalResult, weeklyVolume: weeklyVolume, weightHistory: weightHistory, prs: prs);
  }

  List<({String week, double volume})> _calcWeeklyVolume(Map<String, Map<String, WorkoutLog>> allLogs) {
    final byWeek = <String, double>{};
    for (final date in allLogs.keys) {
      final dt = DateTime.tryParse(date);
      if (dt == null) continue;
      final weekStart = dt.subtract(Duration(days: dt.weekday % 7));
      final key = '${weekStart.year}-${weekStart.month.toString().padLeft(2,'0')}-${weekStart.day.toString().padLeft(2,'0')}';
      for (final log in allLogs[date]!.values) {
        final vol = log.exercises.fold(0.0, (s, ex) => s + ex.volume);
        byWeek[key] = (byWeek[key] ?? 0) + vol;
      }
    }
    final sorted = byWeek.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final last12 = sorted.length > 12 ? sorted.sublist(sorted.length - 12) : sorted;
    return last12.map((e) => (week: e.key, volume: e.value)).toList();
  }

  List<PersonalRecordEntry> _calcPRs(Map<String, Map<String, WorkoutLog>> allLogs) {
    final prMap = <String, PersonalRecordEntry>{};
    final sortedDates = allLogs.keys.toList()..sort();
    for (final date in sortedDates) {
      for (final log in allLogs[date]!.values) {
        for (final ex in log.exercises) {
          final ep = ex.epley1RM;
          if (ep <= 0) continue;
          final existing = prMap[ex.name];
          if (existing == null || ep > existing.epley) {
            final best = ex.bestSet;
            if (best != null) prMap[ex.name] = PersonalRecordEntry(name: ex.name, weight: best.weight, reps: best.reps, epley: ep, date: date);
          }
        }
      }
    }
    final list = prMap.values.toList()..sort((a, b) => b.epley.compareTo(a.epley));
    return list;
  }

  EvalResult? _evaluate(Map<String, Map<String, WorkoutLog>> allLogs) {
    if (allLogs.length < 2) return EvalResult(type: EvalType.beg, label: 'بداية 🫡');
    final sortedDates = allLogs.keys.toList()..sort();
    final recent = sortedDates.length > AppConstants.stagnationWeeks * 4
        ? sortedDates.sublist(sortedDates.length - AppConstants.stagnationWeeks * 4)
        : sortedDates;
    if (recent.isEmpty) return EvalResult(type: EvalType.beg, label: 'بداية 🫡');
    double recentVol = 0, prevVol = 0;
    final half = recent.length ~/ 2;
    for (int i = 0; i < recent.length; i++) {
      final logVol = allLogs[recent[i]]!.values.fold(0.0, (s, l) => s + l.exercises.fold(0.0, (ss, ex) => ss + ex.volume));
      if (i >= half) recentVol += logVol; else prevVol += logVol;
    }
    if (prevVol == 0) return EvalResult(type: EvalType.beg, label: 'بداية 🫡');
    final ratio = recentVol / prevVol;
    if (ratio >= 1.15) return EvalResult(type: EvalType.s1, label: 'ممتاز جدا جدا 🔥');
    if (ratio >= 1.08) return EvalResult(type: EvalType.s2, label: 'ممتاز جدا 🌟');
    if (ratio >= 1.03) return EvalResult(type: EvalType.s3, label: 'ممتاز 💪');
    if (ratio >= 0.97) return EvalResult(type: EvalType.gd, label: 'جيد 👍');
    if (ratio >= 0.90) return EvalResult(type: EvalType.st, label: 'ثبات 😭');
    if (ratio >= 0.80) return EvalResult(type: EvalType.ws, label: '⚠️ ثبات ⚠️');
    return EvalResult(type: EvalType.dn, label: '⚠️ إنخفاض ⚠️');
  }
}
