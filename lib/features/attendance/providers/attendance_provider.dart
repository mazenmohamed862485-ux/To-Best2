import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../services/db_service.dart';
import '../../../services/sync_service.dart';

final attendanceProvider =
    StateNotifierProvider.autoDispose<AttendanceNotifier, AttendanceState>((ref) {
  final db = ref.watch(dbServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  final user = ref.watch(authStateProvider).user;
  final now = DateTime.now();
  final notifier = AttendanceNotifier(db, sync, user?.uid ?? '', now.year, now.month);
  notifier.load();
  return notifier;
});

class AttendanceState {
  final bool isLoading;
  final int year;
  final int month;
  final Map<String, String> attendance; // "YYYY-MM-DD" -> "GYM"|"ABS"|"REST"

  const AttendanceState({
    this.isLoading = true,
    required this.year,
    required this.month,
    this.attendance = const {},
  });

  AttendanceState copyWith({
    bool? isLoading,
    int? year,
    int? month,
    Map<String, String>? attendance,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      year: year ?? this.year,
      month: month ?? this.month,
      attendance: attendance ?? this.attendance,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final DbService _db;
  final SyncService _sync;
  final String _uid;

  AttendanceNotifier(this._db, this._sync, this._uid, int year, int month)
      : super(AttendanceState(year: year, month: month));

  Future<void> load() async {
    if (_uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    final monthKey = '${state.year}-${state.month.toString().padLeft(2, '0')}';
    final data = await _db.getAttendance(_uid, monthKey);
    state = state.copyWith(isLoading: false, attendance: data);
  }

  void prevMonth() {
    final dt = DateTime(state.year, state.month - 1);
    state = state.copyWith(year: dt.year, month: dt.month, attendance: {});
    load();
  }

  void nextMonth() {
    final dt = DateTime(state.year, state.month + 1);
    state = state.copyWith(year: dt.year, month: dt.month, attendance: {});
    load();
  }

  Future<void> mark(String dateKey, String value) async {
    final updated = Map<String, String>.from(state.attendance);
    updated[dateKey] = value;
    state = state.copyWith(attendance: updated);

    final monthKey = '${state.year}-${state.month.toString().padLeft(2, '0')}';
    await _db.saveAttendance(_uid, monthKey, updated);
    await _sync.syncAttendance(_uid, monthKey, updated);
  }

  Future<void> clear(String dateKey) async {
    final updated = Map<String, String>.from(state.attendance)..remove(dateKey);
    state = state.copyWith(attendance: updated);

    final monthKey = '${state.year}-${state.month.toString().padLeft(2, '0')}';
    await _db.saveAttendance(_uid, monthKey, updated);
    await _sync.syncAttendance(_uid, monthKey, updated);
  }

  Future<void> refresh() => load();
}
