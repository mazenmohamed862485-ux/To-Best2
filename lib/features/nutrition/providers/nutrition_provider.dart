import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../services/db_service.dart';
import '../../../services/sync_service.dart';

final nutritionProvider =
    StateNotifierProvider.autoDispose<NutritionNotifier, NutritionState>((ref) {
  final db = ref.watch(dbServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  final user = ref.watch(authStateProvider).user;
  final notifier = NutritionNotifier(db, sync, user?.uid ?? '');
  notifier.load();
  return notifier;
});

class NutritionState {
  final bool isLoading;
  final String date;
  final List<MealEntry> meals;
  final int waterMl;
  final DailyNutrition totals;

  const NutritionState({
    this.isLoading = true,
    required this.date,
    this.meals = const [],
    this.waterMl = 0,
    this.totals = const DailyNutrition(),
  });

  NutritionState copyWith({
    bool? isLoading,
    String? date,
    List<MealEntry>? meals,
    int? waterMl,
    DailyNutrition? totals,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      waterMl: waterMl ?? this.waterMl,
      totals: totals ?? this.totals,
    );
  }
}

class NutritionNotifier extends StateNotifier<NutritionState> {
  final DbService _db;
  final SyncService _sync;
  final String _uid;

  NutritionNotifier(this._db, this._sync, this._uid)
      : super(NutritionState(date: AppUtils.todayKey()));

  Future<void> load() async {
    if (_uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);

    final meals = await _db.getMealsForDate(_uid, state.date);
    final waterMl = await _db.getWaterLog(_uid, state.date);
    final totals = _calcTotals(meals);

    state = state.copyWith(
      isLoading: false,
      meals: meals,
      waterMl: waterMl,
      totals: totals,
    );
  }

  DailyNutrition _calcTotals(List<MealEntry> meals) {
    return meals.fold(
      const DailyNutrition(),
      (acc, m) => DailyNutrition(
        calories: acc.calories + m.calories,
        protein: acc.protein + m.protein,
        carbs: acc.carbs + m.carbs,
        fat: acc.fat + m.fat,
        fiber: acc.fiber + m.fiber,
      ),
    );
  }

  Future<void> addMeal(MealEntry entry) async {
    await _db.saveMealEntry(entry);
    final meals = [...state.meals, entry];
    state = state.copyWith(meals: meals, totals: _calcTotals(meals));
    await _syncMeals();
  }

  Future<void> deleteMeal(String id) async {
    await _db.deleteMealEntry(id);
    final meals = state.meals.where((m) => m.id != id).toList();
    state = state.copyWith(meals: meals, totals: _calcTotals(meals));
    await _syncMeals();
  }

  Future<void> _syncMeals() async {
    final data = state.meals.map((m) => m.toJson()).toList();
    await _sync.syncMeals(_uid, state.date, jsonEncode(data));
  }

  Future<void> addWater(int ml) async {
    final newTotal = state.waterMl + ml;
    await _db.saveWaterLog(_uid, state.date, newTotal);
    state = state.copyWith(waterMl: newTotal);
    await _sync.enqueue(
      action: 'SAVE_WATER',
      key: 'water_${state.date}',
      uid: _uid,
      data: {'date': state.date, 'waterMl': newTotal},
    );
  }

  Future<void> removeWater() async {
    final newTotal = (state.waterMl - 250).clamp(0, 10000);
    await _db.saveWaterLog(_uid, state.date, newTotal);
    state = state.copyWith(waterMl: newTotal);
  }

  void prevDay() {
    final dt = DateTime.parse(state.date).subtract(const Duration(days: 1));
    state = NutritionState(date: AppUtils.todayKey().replaceAll(
        AppUtils.todayKey(), '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}'));
    final newDate = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    state = NutritionState(date: newDate);
    load();
  }

  void nextDay() {
    final dt = DateTime.parse(state.date).add(const Duration(days: 1));
    final today = DateTime.now();
    if (dt.isAfter(today)) return;
    final newDate = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    state = NutritionState(date: newDate);
    load();
  }

  Future<void> refresh() => load();
}
