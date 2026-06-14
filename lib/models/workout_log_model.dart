// ── Exercise Set ──────────────────────────────────────
class ExerciseSet {
  final double weight;
  final int reps;
  final double? rpe;

  const ExerciseSet({
    this.weight = 0,
    this.reps = 0,
    this.rpe,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      weight: (json['w'] as num?)?.toDouble() ?? 0,
      reps: (json['r'] as num?)?.toInt() ?? 0,
      rpe: (json['rpe'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'w': weight,
    'r': reps,
    if (rpe != null) 'rpe': rpe,
  };

  ExerciseSet copyWith({double? weight, int? reps, double? rpe}) {
    return ExerciseSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
    );
  }
}

// ── Exercise Log Entry ────────────────────────────────
class ExerciseLog {
  final String name;
  final List<ExerciseSet> sets;
  final String? altUsed;
  final String? note;
  final int timestamp;

  const ExerciseLog({
    required this.name,
    required this.sets,
    this.altUsed,
    this.note,
    int? timestamp,
  }) : timestamp = timestamp ?? 0;

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      name: json['name']?.toString() ?? '',
      sets: (json['sets'] as List?)
              ?.map((s) => ExerciseSet.fromJson(s))
              .toList() ?? [],
      altUsed: json['altUsed']?.toString(),
      note: json['note']?.toString(),
      timestamp: (json['ts'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (altUsed != null) 'altUsed': altUsed,
    if (note != null) 'note': note,
    if (timestamp > 0) 'ts': timestamp,
  };

  double get epley1RM {
    if (sets.isEmpty) return 0;
    return sets.map((s) {
      if (s.weight <= 0 || s.reps <= 0) return 0.0;
      if (s.reps == 1) return s.weight;
      return s.weight * (1 + s.reps / 30);
    }).reduce((a, b) => a > b ? a : b);
  }

  double get volume {
    return sets.fold(0.0, (sum, s) => sum + s.weight * s.reps);
  }

  ExerciseSet? get bestSet {
    if (sets.isEmpty) return null;
    return sets.reduce((best, s) {
      final be = best.weight * (1 + best.reps / 30);
      final se = s.weight * (1 + s.reps / 30);
      return se > be ? s : best;
    });
  }
}

// ── Workout Log (one session) ─────────────────────────
class WorkoutLog {
  final String uid;
  final String date;       // YYYY-MM-DD
  final String session;    // e.g. "Upper A"
  final String? program;
  final List<ExerciseLog> exercises;
  final int duration;      // seconds
  final int startTime;     // epoch ms
  final int endTime;       // epoch ms

  const WorkoutLog({
    required this.uid,
    required this.date,
    required this.session,
    this.program,
    this.exercises = const [],
    this.duration = 0,
    int? startTime,
    int? endTime,
  })  : startTime = startTime ?? 0,
        endTime = endTime ?? 0;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      uid: json['uid']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      session: json['session']?.toString() ?? '',
      program: json['program']?.toString(),
      exercises: (json['exercises'] as List?)
              ?.map((e) => ExerciseLog.fromJson(e))
              .toList() ?? [],
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      startTime: (json['startTime'] as num?)?.toInt() ?? 0,
      endTime: (json['endTime'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'date': date,
    'session': session,
    if (program != null) 'program': program,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'duration': duration,
    'startTime': startTime,
    'endTime': endTime,
  };
}

// ── Exercise Definition (from config) ─────────────────
class ExerciseDef {
  final String name;
  final bool primary;
  final String warmupSets; // e.g. "1~2"
  final int sets;
  final String reps;       // e.g. "6~8"
  final String rest;       // e.g. "3~5"
  final String muscle;
  final String? alt1;
  final String? alt2;
  final String? note;
  final String? videoId;

  const ExerciseDef({
    required this.name,
    this.primary = true,
    this.warmupSets = '0',
    this.sets = 2,
    this.reps = '6~10',
    this.rest = '2~3',
    this.muscle = '',
    this.alt1,
    this.alt2,
    this.note,
    this.videoId,
  });

  factory ExerciseDef.fromJson(Map<String, dynamic> json) {
    return ExerciseDef(
      name: json['name']?.toString() ?? '',
      primary: json['primary'] == true,
      warmupSets: json['wu']?.toString() ?? '0',
      sets: (json['sets'] as num?)?.toInt() ?? 2,
      reps: json['reps']?.toString() ?? '6~10',
      rest: json['rest']?.toString() ?? '2~3',
      muscle: json['muscle']?.toString() ?? '',
      alt1: json['alt1']?.toString(),
      alt2: json['alt2']?.toString(),
      note: json['note']?.toString(),
      videoId: json['videoId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'primary': primary,
    'wu': warmupSets,
    'sets': sets,
    'reps': reps,
    'rest': rest,
    'muscle': muscle,
    if (alt1 != null && alt1!.isNotEmpty) 'alt1': alt1,
    if (alt2 != null && alt2!.isNotEmpty) 'alt2': alt2,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (videoId != null) 'videoId': videoId,
  };

  int get repsMin {
    final parts = reps.split('~');
    return int.tryParse(parts[0]) ?? 6;
  }

  int get repsMax {
    final parts = reps.split('~');
    return int.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 10;
  }

  int get restMin {
    final parts = rest.split('~');
    return int.tryParse(parts[0]) ?? 2;
  }

  int get restMax {
    final parts = rest.split('~');
    return int.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 3;
  }

  int get warmupSetsCount {
    // "1~2" → use midpoint or first value
    final parts = warmupSets.split('~');
    return int.tryParse(parts[0]) ?? 0;
  }
}

// ── Warmup Item ───────────────────────────────────────
class WarmupItem {
  final String name;
  final String reps;
  final bool hasWeight;
  final String note;
  final String? videoId;

  const WarmupItem({
    required this.name,
    required this.reps,
    this.hasWeight = false,
    this.note = '',
    this.videoId,
  });
}

// ── PR (Personal Record) ──────────────────────────────
class PersonalRecord {
  final String exerciseName;
  final double weight;
  final int reps;
  final double epley;
  final String date;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.epley,
    required this.date,
  });
}

// ── Evaluation Result ─────────────────────────────────
enum EvalType { s1, s2, s3, rv, gd, st, ws, dn, beg }

class EvalResult {
  final EvalType type;
  final String label;

  const EvalResult({required this.type, required this.label});
}
