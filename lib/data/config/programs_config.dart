import '../../models/workout_log_model.dart';

// ── Program Definitions ───────────────────────────────
class ProgramConfig {
  final String id;
  final String nameAr;
  final String nameEn;
  final List<int> daysOptions;
  final String descriptionAr;
  final String descriptionEn;
  final Map<int, List<String>> sessions;

  const ProgramConfig({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.daysOptions,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.sessions,
  });

  List<String> getSessions(int days) {
    return sessions[days] ?? sessions[daysOptions.first] ?? [];
  }

  String get name => nameAr;
}

class TrainingPrograms {
  static const List<ProgramConfig> all = [
    ProgramConfig(
      id: 'UL',
      nameAr: 'Upper / Lower',
      nameEn: 'Upper / Lower',
      daysOptions: [4],
      descriptionAr: 'تقسيم جسم علوي وسفلي',
      descriptionEn: 'Upper/Lower body split',
      sessions: {
        4: ['Upper A', 'Lower A', 'Upper B', 'Lower B'],
      },
    ),
    ProgramConfig(
      id: 'AP',
      nameAr: 'Anterior / Posterior',
      nameEn: 'Anterior / Posterior',
      daysOptions: [4],
      descriptionAr: 'نظام أمامي-خلفي',
      descriptionEn: 'Anterior-Posterior split',
      sessions: {
        4: ['Anterior A', 'Posterior A', 'Anterior B', 'Posterior B'],
      },
    ),
    ProgramConfig(
      id: 'FB',
      nameAr: 'Full Body',
      nameEn: 'Full Body',
      daysOptions: [3],
      descriptionAr: 'جسم كامل',
      descriptionEn: 'Full Body training',
      sessions: {
        3: ['Full Body #1', 'Full Body #2', 'Full Body #3'],
      },
    ),
    ProgramConfig(
      id: 'ARNOLD',
      nameAr: 'Arnold',
      nameEn: 'Arnold',
      daysOptions: [5],
      descriptionAr: 'برنامج أرنولد الكلاسيكي',
      descriptionEn: 'Classic Arnold program',
      sessions: {
        5: ['Chest & Back', 'Shoulders & Arms', 'Lower A', 'Upper', 'Lower B'],
      },
    ),
    ProgramConfig(
      id: 'PPL',
      nameAr: 'Push / Pull / Legs',
      nameEn: 'Push / Pull / Legs',
      daysOptions: [5],
      descriptionAr: 'ضغط-شد-أرجل',
      descriptionEn: 'Push-Pull-Legs',
      sessions: {
        5: ['PUSH', 'PULL', 'Lower A', 'Upper', 'Lower B'],
      },
    ),
    ProgramConfig(
      id: 'CUSTOM',
      nameAr: 'برنامج مخصص',
      nameEn: 'Custom Program',
      daysOptions: [3, 4, 5, 6],
      descriptionAr: 'أضف تمارينك وجلساتك بنفسك',
      descriptionEn: 'Build your own program',
      sessions: {3: [], 4: [], 5: [], 6: []},
    ),
  ];

  static ProgramConfig? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ── Activity Levels ───────────────────────────────────
class ActivityLevel {
  final String id;
  final String nameAr;
  final String nameEn;
  final double factor;

  const ActivityLevel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.factor,
  });
}

const List<ActivityLevel> kActivityLevels = [
  ActivityLevel(id: 'sedentary', nameAr: 'قليل جداً', nameEn: 'Sedentary', factor: 1.2),
  ActivityLevel(id: 'light', nameAr: 'خفيف', nameEn: 'Light', factor: 1.375),
  ActivityLevel(id: 'moderate', nameAr: 'متوسط', nameEn: 'Moderate', factor: 1.55),
  ActivityLevel(id: 'active', nameAr: 'نشيط', nameEn: 'Active', factor: 1.725),
  ActivityLevel(id: 'veryActive', nameAr: 'نشيط جداً', nameEn: 'Very Active', factor: 1.9),
];

// ── Warmup Items ───────────────────────────────────────
const List<WarmupItem> kWarmupItems = [
  WarmupItem(name: 'Pallof Press', reps: '10/side', hasWeight: true, note: 'ثبّت جسمك وحرك ذراعك فقط'),
  WarmupItem(name: 'Pallof Rotation', reps: '10/side', hasWeight: true, note: 'حوضك ثابت'),
  WarmupItem(name: 'External Rotation', reps: '10 reps', hasWeight: true, note: 'من الكتف فقط'),
  WarmupItem(name: 'Scapula Push Plus', reps: '10 reps', hasWeight: true, note: 'من لوح الكتف — وزن خفيف'),
  WarmupItem(name: 'Neck Extension', reps: '12 reps', hasWeight: true, note: 'وزن خفيف جداً — أسفل الرأس'),
  WarmupItem(name: 'Neck Flexion', reps: '12 reps', hasWeight: true, note: 'وزن خفيف — الذقن للصدر'),
];

// ── Exercise Database ─────────────────────────────────
class ExerciseDatabase {
  static Map<String, List<ExerciseDef>> get allSessions => {
    'Upper A': upperA,
    'Lower A': lowerA,
    'Upper B': upperB,
    'Lower B': lowerB,
    'Full Body #1': fullBody1,
    'Full Body #2': fullBody2,
    'Full Body #3': fullBody3,
    'Chest & Back': arnoldChestBack,
    'Shoulders & Arms': arnoldShouldersArms,
    'Lower A': lowerA,
    'Upper': arnoldUpper,
    'Lower B': lowerB,
    'Anterior A': anteriorA,
    'Posterior A': posteriorA,
    'Anterior B': anteriorB,
    'Posterior B': posteriorB,
    'PUSH': ppl_push,
    'PULL': ppl_pull,
  };

  static List<ExerciseDef> getForSession(String session) {
    return allSessions[session] ?? [];
  }

  static const List<ExerciseDef> upperA = [
    ExerciseDef(name: 'Smith High Incline Press', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر عالي', alt1: 'DB High Incline Press', note: 'ضم ايدك لجوه عشان تحاكي اتجاه الياف الصدر العالي'),
    ExerciseDef(name: 'Machine Wide Grip Lat Pulldown', primary: true, warmupSets: '1~3', sets: 2, reps: '6~8', rest: '3~5', muscle: 'لاتس', alt1: 'Cable Wide Grip Lat', note: 'ركز في مسار كوعك وانك بتضم كتافك مش بتسحب من كتفك'),
    ExerciseDef(name: 'Chest Press Machine', primary: false, warmupSets: '1~2', sets: 2, reps: '6~10', rest: '3~5', muscle: 'صدر مستوي', alt1: 'DB Flat Press'),
    ExerciseDef(name: 'T Bar Row', primary: true, warmupSets: '1~2', sets: 2, reps: '5~7', rest: '3~5', muscle: 'ظهر علوي', alt1: 'Incline DB Row', alt2: 'Cable Row', note: 'افتح كيعانك لبره حاول تقرب من زاوية 90'),
    ExerciseDef(name: 'SA Tricep Pushdown', primary: false, warmupSets: '0', sets: 2, reps: '6~10', rest: '2~3', muscle: 'ترايسبس', alt1: 'Double Rope Pushdown'),
    ExerciseDef(name: 'DB Preacher Curl', primary: true, warmupSets: '0', sets: 2, reps: '6~10', rest: '2~3', muscle: 'بايسبس', alt1: 'Face Away Curl', alt2: 'DB Curls', note: 'بلاش مدى حركي زياده من الكتف ومتمرجحش جسمك'),
    ExerciseDef(name: 'Reverse Grip Curls', primary: false, warmupSets: '0', sets: 2, reps: '6~10', rest: '2~3', muscle: 'ساعد أمامي', alt1: 'DB Reverse Curl', alt2: 'Barbell Reverse Curl'),
  ];

  static const List<ExerciseDef> lowerA = [
    ExerciseDef(name: 'Machine Lateral Raises', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'Cable Lateral Raises', alt2: 'DB Lateral Raises'),
    ExerciseDef(name: 'Leg Press Calf Raises', primary: false, warmupSets: '1~2', sets: 2, reps: '5~7', rest: '1~2', muscle: 'سمانة', alt1: 'Smith Calf Raises'),
    ExerciseDef(name: 'Hack Squat', primary: true, warmupSets: '1~3', sets: 1, reps: '5~8', rest: '3~5', muscle: 'رجل كوادز', alt1: 'Smith Squat', alt2: 'Leg Press', note: '120 درجه من ثني الركبه يكفي لاستهداف الكوادز'),
    ExerciseDef(name: 'SA Rear Delt Flies', primary: false, warmupSets: '0', sets: 1, reps: '6~10', rest: '2~3', muscle: 'كتف خلفي', alt1: 'Reverse Pec Dec'),
    ExerciseDef(name: 'Seated Leg Curl', primary: true, warmupSets: '1~2', sets: 1, reps: '8~12', rest: '2~3', muscle: 'رجل خلفيه', alt1: 'Lying Leg Curl'),
    ExerciseDef(name: 'Leg Extension', primary: true, warmupSets: '1~2', sets: 2, reps: '8~12', rest: '2~3', muscle: 'رجل أماميه'),
    ExerciseDef(name: 'Hip Adduction', primary: false, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '2~3', muscle: 'ضمه', alt1: 'Cable Hip Adduction'),
    ExerciseDef(name: 'Wrist Curls', primary: false, warmupSets: '0', sets: 3, reps: '6~10', rest: '1~2', muscle: 'ساعد خلفي'),
  ];

  static const List<ExerciseDef> upperB = [
    ExerciseDef(name: 'Chest Press Machine', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر مستوي', alt1: 'DB Flat Press', alt2: 'Smith Flat Press'),
    ExerciseDef(name: 'T Bar Row', primary: true, warmupSets: '1~2', sets: 2, reps: '5~7', rest: '3~5', muscle: 'ظهر علوي', alt1: 'Incline DB Row', alt2: 'Cable Row'),
    ExerciseDef(name: 'Incline Chest Press Machine', primary: false, warmupSets: '1~2', sets: 1, reps: '6~10', rest: '3~5', muscle: 'صدر عالي', alt1: 'DB Incline Press', alt2: 'Smith Incline Press'),
    ExerciseDef(name: 'SA Lat Row', primary: false, warmupSets: '0', sets: 1, reps: '6~10', rest: '2~3', muscle: 'لاتس', alt1: 'Cable SA Lat Row', alt2: 'DB SA Lat Row'),
    ExerciseDef(name: 'Face Away Curl', primary: true, warmupSets: '0', sets: 2, reps: '6~10', rest: '2~3', muscle: 'بايسبس', alt1: 'DB Preacher Curl', alt2: 'DB Curls'),
    ExerciseDef(name: 'Overhead Extension', primary: true, warmupSets: '0', sets: 2, reps: '6~10', rest: '2~3', muscle: 'ترايسبس', alt1: 'DB Skull Crusher'),
    ExerciseDef(name: 'Cable Shrugs', primary: false, warmupSets: '1', sets: 2, reps: '6~8', rest: '2~3', muscle: 'ترابيس', alt1: 'Smith Kelso Shrugs', alt2: 'DB Kelso Shrugs'),
  ];

  static const List<ExerciseDef> lowerB = [
    ExerciseDef(name: 'Cable Lateral Raises', primary: true, warmupSets: '1~2', sets: 2, reps: '5~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'DB Lateral Raises'),
    ExerciseDef(name: 'SLDL', primary: true, warmupSets: '1~3', sets: 1, reps: '5~7', rest: '3~5', muscle: 'جلوتس', alt1: 'RDL', alt2: 'Hip Extension'),
    ExerciseDef(name: 'Seated Leg Curl', primary: true, warmupSets: '1~2', sets: 2, reps: '8~12', rest: '2~3', muscle: 'رجل خلفيه', alt1: 'Lying Leg Curl'),
    ExerciseDef(name: 'Leg Extension', primary: false, warmupSets: '1~2', sets: 1, reps: '8~12', rest: '2~3', muscle: 'رجل أماميه'),
    ExerciseDef(name: 'Hip Adduction', primary: false, warmupSets: '1~2', sets: 1, reps: '6~8', rest: '2~3', muscle: 'ضمه', alt1: 'Cable Hip Adduction'),
    ExerciseDef(name: 'Lat Pulldown Crunches', primary: false, warmupSets: '0', sets: 1, reps: '6~10', rest: '1~2', muscle: 'بطن', alt1: 'Cable Crunch'),
  ];

  static const List<ExerciseDef> fullBody1 = [
    ExerciseDef(name: 'Smith High Incline Press', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر عالي', alt1: 'DB High Incline Press'),
    ExerciseDef(name: 'Machine Wide Grip Lat Pulldown', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'لاتس', alt1: 'Cable Wide Grip Lat'),
    ExerciseDef(name: 'Machine Lateral Raises', primary: true, warmupSets: '1', sets: 2, reps: '6~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'Cable Lateral Raises'),
    ExerciseDef(name: 'Hack Squat', primary: true, warmupSets: '1~3', sets: 2, reps: '6~10', rest: '3~5', muscle: 'رجل كوادز', alt1: 'Smith Squat', alt2: 'Leg Press'),
    ExerciseDef(name: 'SLDL', primary: true, warmupSets: '1~2', sets: 1, reps: '6~8', rest: '3~5', muscle: 'جلوتس', alt1: 'RDL'),
    ExerciseDef(name: 'SA Tricep Pushdown', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'ترايسبس', alt1: 'Double Rope Pushdown'),
    ExerciseDef(name: 'DB Preacher Curl', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'بايسبس', alt1: 'DB Curls'),
  ];

  static const List<ExerciseDef> fullBody2 = [
    ExerciseDef(name: 'Chest Press Machine', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر مستوي', alt1: 'DB Flat Press'),
    ExerciseDef(name: 'T Bar Row', primary: true, warmupSets: '1~2', sets: 2, reps: '5~7', rest: '3~5', muscle: 'ظهر علوي', alt1: 'Incline DB Row', alt2: 'Cable Row'),
    ExerciseDef(name: 'Cable Lateral Raises', primary: false, warmupSets: '1', sets: 2, reps: '6~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'DB Lateral Raises'),
    ExerciseDef(name: 'Leg Press', primary: true, warmupSets: '1~2', sets: 2, reps: '8~12', rest: '3~5', muscle: 'رجل كوادز'),
    ExerciseDef(name: 'Seated Leg Curl', primary: true, warmupSets: '1', sets: 2, reps: '8~12', rest: '2~3', muscle: 'رجل خلفيه', alt1: 'Lying Leg Curl'),
    ExerciseDef(name: 'Overhead Extension', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'ترايسبس', alt1: 'DB Skull Crusher'),
    ExerciseDef(name: 'Face Away Curl', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'بايسبس', alt1: 'DB Preacher Curl'),
  ];

  static const List<ExerciseDef> fullBody3 = [
    ExerciseDef(name: 'Smith High Incline Press', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر عالي', alt1: 'DB High Incline Press'),
    ExerciseDef(name: 'SA Lat Row', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'لاتس', alt1: 'Cable SA Lat Row'),
    ExerciseDef(name: 'Machine Lateral Raises', primary: false, warmupSets: '1', sets: 2, reps: '8~12', rest: '2~3', muscle: 'كتف جانبي', alt1: 'DB Lateral Raises'),
    ExerciseDef(name: 'Hack Squat', primary: true, warmupSets: '1~3', sets: 2, reps: '6~10', rest: '3~5', muscle: 'رجل كوادز', alt1: 'Leg Press'),
    ExerciseDef(name: 'SLDL', primary: false, warmupSets: '1', sets: 1, reps: '6~8', rest: '3~5', muscle: 'جلوتس', alt1: 'RDL'),
    ExerciseDef(name: 'Leg Extension', primary: false, warmupSets: '1', sets: 2, reps: '10~15', rest: '1~2', muscle: 'رجل أماميه'),
    ExerciseDef(name: 'Wrist Curls', primary: false, warmupSets: '0', sets: 2, reps: '10~15', rest: '1~2', muscle: 'ساعد'),
  ];

  // Arnold program
  static const List<ExerciseDef> arnoldChestBack = [
    ExerciseDef(name: 'Smith High Incline Press', primary: true, warmupSets: '1~2', sets: 3, reps: '6~8', rest: '3~5', muscle: 'صدر عالي', alt1: 'DB High Incline Press'),
    ExerciseDef(name: 'T Bar Row', primary: true, warmupSets: '1~2', sets: 3, reps: '5~7', rest: '3~5', muscle: 'ظهر علوي', alt1: 'Incline DB Row'),
    ExerciseDef(name: 'Chest Press Machine', primary: true, warmupSets: '1', sets: 2, reps: '6~10', rest: '3~5', muscle: 'صدر مستوي', alt1: 'DB Flat Press'),
    ExerciseDef(name: 'Machine Wide Grip Lat Pulldown', primary: true, warmupSets: '1', sets: 2, reps: '6~8', rest: '3~5', muscle: 'لاتس', alt1: 'Cable Wide Grip Lat'),
    ExerciseDef(name: 'SA Rear Delt Flies', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'كتف خلفي', alt1: 'Reverse Pec Dec'),
    ExerciseDef(name: 'Lat Pulldown Crunches', primary: false, warmupSets: '0', sets: 2, reps: '10~15', rest: '1~2', muscle: 'بطن', alt1: 'Cable Crunch'),
  ];

  static const List<ExerciseDef> arnoldShouldersArms = [
    ExerciseDef(name: 'Machine Lateral Raises', primary: true, warmupSets: '1', sets: 3, reps: '6~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'Cable Lateral Raises'),
    ExerciseDef(name: 'SA Rear Delt Flies', primary: true, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'كتف خلفي', alt1: 'Reverse Pec Dec'),
    ExerciseDef(name: 'DB Preacher Curl', primary: true, warmupSets: '0', sets: 3, reps: '6~10', rest: '2~3', muscle: 'بايسبس', alt1: 'Face Away Curl', alt2: 'DB Curls'),
    ExerciseDef(name: 'Overhead Extension', primary: true, warmupSets: '0', sets: 3, reps: '6~10', rest: '2~3', muscle: 'ترايسبس', alt1: 'DB Skull Crusher'),
    ExerciseDef(name: 'Reverse Grip Curls', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '1~2', muscle: 'ساعد أمامي', alt1: 'DB Reverse Curl'),
    ExerciseDef(name: 'Wrist Curls', primary: false, warmupSets: '0', sets: 2, reps: '10~15', rest: '1~2', muscle: 'ساعد خلفي'),
  ];

  static const List<ExerciseDef> arnoldUpper = [
    ExerciseDef(name: 'Chest Press Machine', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر مستوي', alt1: 'DB Flat Press'),
    ExerciseDef(name: 'Machine Wide Grip Lat Pulldown', primary: true, warmupSets: '1', sets: 2, reps: '6~8', rest: '3~5', muscle: 'لاتس', alt1: 'Cable Wide Grip Lat'),
    ExerciseDef(name: 'Incline Chest Press Machine', primary: false, warmupSets: '1', sets: 2, reps: '8~12', rest: '2~3', muscle: 'صدر عالي', alt1: 'DB Incline Press'),
    ExerciseDef(name: 'Cable Shrugs', primary: false, warmupSets: '1', sets: 2, reps: '6~8', rest: '2~3', muscle: 'ترابيس', alt1: 'Smith Kelso Shrugs'),
    ExerciseDef(name: 'Face Away Curl', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'بايسبس', alt1: 'DB Preacher Curl'),
    ExerciseDef(name: 'SA Tricep Pushdown', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'ترايسبس', alt1: 'Double Rope Pushdown'),
  ];

  // PPL
  static const List<ExerciseDef> ppl_push = [
    ExerciseDef(name: 'Machine Lateral Raises', primary: true, warmupSets: '1', sets: 3, reps: '6~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'Cable Lateral Raises', alt2: 'DB Lateral Raises'),
    ExerciseDef(name: 'Incline Chest Press Machine', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر عالي', alt1: 'DB Incline Press', alt2: 'Smith Incline Press'),
    ExerciseDef(name: 'Chest Press Machine', primary: true, warmupSets: '1~2', sets: 2, reps: '8~10', rest: '3~5', muscle: 'صدر مستوي', alt1: 'DB Flat Press', alt2: 'Smith Flat Press'),
    ExerciseDef(name: 'SA Tricep Pushdown', primary: true, warmupSets: '0', sets: 2, reps: '6~10', rest: '2~3', muscle: 'ترايسبس', alt1: 'Double Rope Pushdown'),
    ExerciseDef(name: 'Overhead Extension', primary: true, warmupSets: '1', sets: 2, reps: '6~10', rest: '2~3', muscle: 'ترايسبس', alt1: 'DB Skull Crusher'),
    ExerciseDef(name: 'Lat Pulldown Crunches', primary: false, warmupSets: '1', sets: 2, reps: '6~10', rest: '1~2', muscle: 'بطن', alt1: 'Cable Crunch'),
    ExerciseDef(name: 'Wrist Curls', primary: false, warmupSets: '1', sets: 2, reps: '6~10', rest: '1~2', muscle: 'ساعد خلفي'),
  ];

  static const List<ExerciseDef> ppl_pull = [
    ExerciseDef(name: 'T Bar Row', primary: true, warmupSets: '1~2', sets: 2, reps: '5~7', rest: '3~5', muscle: 'ظهر علوي', alt1: 'Incline DB Row', alt2: 'Cable Row'),
    ExerciseDef(name: 'SA Lat Row', primary: false, warmupSets: '1', sets: 1, reps: '6~10', rest: '3~5', muscle: 'لاتس', alt1: 'Cable SA Lat Row', alt2: 'DB SA Lat Row'),
    ExerciseDef(name: 'Machine Wide Grip Lat Pulldown', primary: true, warmupSets: '1', sets: 1, reps: '6~8', rest: '3~5', muscle: 'لاتس', alt1: 'Cable Wide Grip Lat'),
    ExerciseDef(name: 'Cable Shrugs', primary: false, warmupSets: '1', sets: 1, reps: '6~8', rest: '2~3', muscle: 'ترابيس', alt1: 'Smith Kelso Shrugs'),
    ExerciseDef(name: 'SA Rear Delt Flies', primary: false, warmupSets: '1', sets: 2, reps: '6~10', rest: '2~3', muscle: 'كتف خلفي', alt1: 'Reverse Pec Dec'),
    ExerciseDef(name: 'DB Curls', primary: true, warmupSets: '1', sets: 2, reps: '6~10', rest: '2~3', muscle: 'بايسبس'),
    ExerciseDef(name: 'DB Preacher Curl', primary: true, warmupSets: '1', sets: 2, reps: '6~10', rest: '2~3', muscle: 'بايسبس'),
  ];

  // Anterior/Posterior
  static const List<ExerciseDef> anteriorA = [
    ExerciseDef(name: 'Smith High Incline Press', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر عالي', alt1: 'DB High Incline Press'),
    ExerciseDef(name: 'Machine Lateral Raises', primary: true, warmupSets: '1', sets: 2, reps: '6~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'Cable Lateral Raises'),
    ExerciseDef(name: 'Hack Squat', primary: true, warmupSets: '1~3', sets: 2, reps: '6~10', rest: '3~5', muscle: 'رجل كوادز', alt1: 'Smith Squat', alt2: 'Leg Press'),
    ExerciseDef(name: 'Leg Extension', primary: false, warmupSets: '1', sets: 2, reps: '10~15', rest: '2~3', muscle: 'رجل أماميه'),
    ExerciseDef(name: 'SA Tricep Pushdown', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'ترايسبس', alt1: 'Double Rope Pushdown'),
    ExerciseDef(name: 'Overhead Extension', primary: false, warmupSets: '0', sets: 1, reps: '8~12', rest: '2~3', muscle: 'ترايسبس', alt1: 'DB Skull Crusher'),
  ];

  static const List<ExerciseDef> posteriorA = [
    ExerciseDef(name: 'T Bar Row', primary: true, warmupSets: '1~2', sets: 2, reps: '5~7', rest: '3~5', muscle: 'ظهر علوي', alt1: 'Incline DB Row', alt2: 'Cable Row'),
    ExerciseDef(name: 'Machine Wide Grip Lat Pulldown', primary: true, warmupSets: '1', sets: 2, reps: '6~8', rest: '3~5', muscle: 'لاتس', alt1: 'Cable Wide Grip Lat'),
    ExerciseDef(name: 'SLDL', primary: true, warmupSets: '1~3', sets: 2, reps: '5~7', rest: '3~5', muscle: 'جلوتس', alt1: 'RDL', alt2: 'Hip Extension'),
    ExerciseDef(name: 'Seated Leg Curl', primary: true, warmupSets: '1', sets: 2, reps: '8~12', rest: '2~3', muscle: 'رجل خلفيه', alt1: 'Lying Leg Curl'),
    ExerciseDef(name: 'SA Rear Delt Flies', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'كتف خلفي', alt1: 'Reverse Pec Dec'),
    ExerciseDef(name: 'DB Preacher Curl', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'بايسبس', alt1: 'Face Away Curl'),
  ];

  static const List<ExerciseDef> anteriorB = [
    ExerciseDef(name: 'Chest Press Machine', primary: true, warmupSets: '1~2', sets: 2, reps: '6~8', rest: '3~5', muscle: 'صدر مستوي', alt1: 'DB Flat Press'),
    ExerciseDef(name: 'Cable Lateral Raises', primary: true, warmupSets: '1', sets: 2, reps: '5~8', rest: '2~3', muscle: 'كتف جانبي', alt1: 'DB Lateral Raises'),
    ExerciseDef(name: 'Leg Press', primary: true, warmupSets: '1~2', sets: 2, reps: '8~12', rest: '3~5', muscle: 'رجل كوادز'),
    ExerciseDef(name: 'Hip Adduction', primary: false, warmupSets: '1', sets: 2, reps: '6~8', rest: '2~3', muscle: 'ضمه', alt1: 'Cable Hip Adduction'),
    ExerciseDef(name: 'Face Away Curl', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'بايسبس', alt1: 'DB Preacher Curl'),
    ExerciseDef(name: 'Reverse Grip Curls', primary: false, warmupSets: '0', sets: 1, reps: '8~12', rest: '1~2', muscle: 'ساعد أمامي'),
  ];

  static const List<ExerciseDef> posteriorB = [
    ExerciseDef(name: 'SA Lat Row', primary: true, warmupSets: '1', sets: 2, reps: '6~10', rest: '3~5', muscle: 'لاتس', alt1: 'Cable SA Lat Row'),
    ExerciseDef(name: 'Cable Shrugs', primary: false, warmupSets: '1', sets: 2, reps: '6~8', rest: '2~3', muscle: 'ترابيس', alt1: 'Smith Kelso Shrugs'),
    ExerciseDef(name: 'SLDL', primary: true, warmupSets: '1~2', sets: 2, reps: '5~7', rest: '3~5', muscle: 'جلوتس', alt1: 'RDL'),
    ExerciseDef(name: 'Leg Press Calf Raises', primary: false, warmupSets: '1', sets: 2, reps: '8~12', rest: '1~2', muscle: 'سمانة', alt1: 'Smith Calf Raises'),
    ExerciseDef(name: 'SA Rear Delt Flies', primary: false, warmupSets: '0', sets: 2, reps: '8~12', rest: '2~3', muscle: 'كتف خلفي', alt1: 'Reverse Pec Dec'),
    ExerciseDef(name: 'Lat Pulldown Crunches', primary: false, warmupSets: '0', sets: 2, reps: '10~15', rest: '1~2', muscle: 'بطن', alt1: 'Cable Crunch'),
  ];
}
