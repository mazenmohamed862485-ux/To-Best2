class AppConstants {
    AppConstants._();

    static const String appName = 'TO Best';
    static const String appVersion = '1.0.0';
    static const String packageName = 'com.tobest.app';

    // ── Default Config ────────────────────────────────────
    static const String defaultWebAppUrl =
        'https://script.google.com/macros/s/AKfycbwQrKSMoGJfnyrUG9zmqd_ou-TqDGyDYcky_WAbZaXrpWA-9JfnNOZLOi33w0q2TYdq/exec';
    static const String defaultSecretKey = 'Mazen124261';

    // ── Roles ────────────────────────────────────────────
    static const String roleSuperAdmin = 'SUPER_ADMIN';
    static const String roleAdmin = 'ADMIN';
    static const String roleCoach = 'COACH';
    static const String roleTrainee = 'TRAINEE';
    static const String roleViewer = 'VIEWER';

    // ── Subscription Plans ───────────────────────────────
    static const String planLight = 'light';
    static const String planFull = 'full';

    // ── Subscription Status ──────────────────────────────
    static const String subNone = 'none';
    static const String subPending = 'payment_pending';
    static const String subActive = 'active';
    static const String subExpired = 'expired';

    // ── Attendance ───────────────────────────────────────
    static const String attGym = 'GYM';
    static const String attAbsent = 'ABS';
    static const String attRest = 'REST';

    // ── Settings Keys ────────────────────────────────────
    static const String keyTheme = 'theme';
    static const String keyAccentColor = 'accentColor';
    static const String keyLanguage = 'lang';
    static const String keyHandMode = 'handMode';
    static const String keyWebAppUrl = 'webAppUrl';
    static const String keySecretKey = 'secretKey';
    static const String keySessionToken = 'sessionToken';
    static const String keyCurrentUser = 'currentUser';
    static const String keyRestTimerDuration = 'restTimerDuration';
    static const String keyRestTimerSound = 'restTimerSound';
    static const String keyShowOldValues = 'showOldValues';
    static const String keyShowEpley = 'showEpley';
    static const String keyShowRPE = 'showRPE';
    static const String keyShowRepSuggest = 'showRepSuggest';
    static const String keyShowVolume = 'showVolume';
    static const String keyWakeLock = 'wakeLock';
    static const String keyNotifications = 'notifications';
    static const String keySelectedProgram = 'selectedProgram';
    static const String keyProgramDays = 'programDays';
    static const String keyGymDays = 'gymDays';
    static const String keyMotivationalMsgs = 'motivationalMsgs';
    static const String keyGeminiApiKey = 'geminiApiKey';

    // ── DB Tables ─────────────────────────────────────────
    static const String tableSettings = 'settings';
    static const String tableWorkoutLogs = 'workout_logs';
    static const String tableAttendance = 'attendance';
    static const String tableMeals = 'meals';
    static const String tableMealPlans = 'meal_plans';
    static const String tableSyncQueue = 'sync_queue';
    static const String tableNotifications = 'notifications';
    static const String tableMeasurements = 'measurements';
    static const String tableProgressPhotos = 'progress_photos';
    static const String tableExSwaps = 'ex_swaps';
    static const String tableCustomExercises = 'custom_exercises';

    // ── Sync Actions ─────────────────────────────────────
    static const String actionSaveLog = 'SAVE_LOG';
    static const String actionSaveAtt = 'SAVE_ATT';
    static const String actionSaveMeals = 'SAVE_MEALS';
    static const String actionSaveMealPlan = 'SAVE_MEAL_PLAN';
    static const String actionSetting = 'SETTING';
    static const String actionCustomEx = 'CUSTOM_EX';
    static const String actionExSwap = 'EX_SWAP';
    static const String actionMeasurement = 'MEASUREMENT';
    static const String actionSendMsg = 'SEND_MSG';

    // ── Timer ─────────────────────────────────────────────
    static const int defaultRestTimerSecs = 180;
    static const int chatPollIntervalMs = 8000;
    static const int autoSyncIntervalMs = 30000;
    static const int apiTimeoutMs = 14000;

    // ── Stagnation ─────────────────────────────────────────
    static const int stagnationWeeks = 3;
    static const int repsUpThreshold = 12;
    static const int repsDownThreshold = 4;

    // ── UI ────────────────────────────────────────────────
    static const double defaultPadding = 16.0;
    static const double cardRadius = 16.0;
    static const double buttonRadius = 12.0;
    static const double smallRadius = 8.0;

    // ── Chat Rooms ────────────────────────────────────────
    static const String chatRoomGeneral = 'general';
    static const String chatRoomPrefix = 'coach_';
  }
  