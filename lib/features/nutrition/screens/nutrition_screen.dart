import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_button.dart';
import '../providers/nutrition_provider.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionProvider);
    final user = ref.watch(authStateProvider).user;
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';

    final targets = DailyNutrition(
      calories: user?.dailyCals ?? 0,
      protein: user?.dailyProtein ?? 0,
      carbs: user?.dailyCarbs ?? 0,
      fat: user?.dailyFat ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'التغذية' : 'Nutrition',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: isAr ? 'خطة الوجبات' : 'Meal Plan',
            onPressed: () => context.push('/nutrition/plan'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(nutritionProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/nutrition/search'),
        icon: const Icon(Icons.add),
        label: Text(isAr ? 'إضافة وجبة' : 'Add Food',
            style: const TextStyle(fontFamily: 'Cairo')),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(nutritionProvider.notifier).refresh(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Date nav ──────────────────────
                  _DateNav(state: state, notifier: ref.read(nutritionProvider.notifier), isAr: isAr),
                  const SizedBox(height: 16),

                  // ── Calories ring ────────────────
                  _CaloriesRing(consumed: state.totals.calories, target: targets.calories, isAr: isAr),
                  const SizedBox(height: 16),

                  // ── Macro bars ───────────────────
                  _MacroBarsCard(totals: state.totals, targets: targets, isAr: isAr),
                  const SizedBox(height: 16),

                  // ── Water tracker ────────────────
                  _WaterCard(waterMl: state.waterMl, isAr: isAr,
                      onAdd: (ml) => ref.read(nutritionProvider.notifier).addWater(ml),
                      onRemove: () => ref.read(nutritionProvider.notifier).removeWater()),
                  const SizedBox(height: 16),

                  // ── Meals list ───────────────────
                  _MealsList(state: state, isAr: isAr,
                      onDelete: (id) => ref.read(nutritionProvider.notifier).deleteMeal(id)),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}

// ── Date Nav ──────────────────────────────────────────
class _DateNav extends StatelessWidget {
  final NutritionState state;
  final NutritionNotifier notifier;
  final bool isAr;
  const _DateNav({required this.state, required this.notifier, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final isToday = state.date == AppUtils.todayKey();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: notifier.prevDay),
        Text(
          isToday ? (isAr ? '🗓 اليوم' : '🗓 Today') : state.date,
          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 15),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday ? null : notifier.nextDay,
        ),
      ],
    );
  }
}

// ── Calories Ring ─────────────────────────────────────
class _CaloriesRing extends StatelessWidget {
  final double consumed;
  final double target;
  final bool isAr;
  const _CaloriesRing({required this.consumed, required this.target, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.5) : 0.0;
    final remaining = (target - consumed).clamp(0.0, double.infinity);
    final isOver = consumed > target && target > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 100, height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100, height: 100,
                    child: CircularProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(
                          isOver ? AppColors.error : theme.colorScheme.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        consumed.toStringAsFixed(0),
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary, fontFamily: 'Cairo'),
                      ),
                      Text(isAr ? 'سعرة' : 'kcal',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalRow(isAr ? 'الهدف' : 'Target', target.toStringAsFixed(0), Colors.grey),
                  const SizedBox(height: 8),
                  _CalRow(isAr ? 'المستهلك' : 'Consumed', consumed.toStringAsFixed(0), theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  _CalRow(
                    isAr ? (isOver ? 'تجاوزت!' : 'المتبقي') : (isOver ? 'Over!' : 'Remaining'),
                    remaining.toStringAsFixed(0),
                    isOver ? AppColors.error : AppColors.ok,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CalRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.grey)),
        Text('$value kcal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: color, fontFamily: 'Cairo')),
      ],
    );
  }
}

// ── Macro Bars Card ───────────────────────────────────
class _MacroBarsCard extends StatelessWidget {
  final DailyNutrition totals;
  final DailyNutrition targets;
  final bool isAr;
  const _MacroBarsCard({required this.totals, required this.targets, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MacroRow(
              label: isAr ? 'بروتين' : 'Protein',
              current: totals.protein,
              target: targets.protein,
              color: AppColors.proteinColor,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _MacroRow(
              label: isAr ? 'كربوهيدرات' : 'Carbs',
              current: totals.carbs,
              target: targets.carbs,
              color: AppColors.carbsColor,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _MacroRow(
              label: isAr ? 'دهون' : 'Fat',
              current: totals.fat,
              target: targets.fat,
              color: AppColors.fatColor,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _MacroRow(
              label: isAr ? 'ألياف' : 'Fiber',
              current: totals.fiber,
              target: 30,
              color: AppColors.fiberColor,
              unit: 'g',
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;
  const _MacroRow({required this.label, required this.current,
      required this.target, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
            Text(
              '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(0)}$unit',
              style: TextStyle(fontSize: 11, color: color, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ── Water Card ────────────────────────────────────────
class _WaterCard extends StatelessWidget {
  final int waterMl;
  final bool isAr;
  final ValueChanged<int> onAdd;
  final VoidCallback onRemove;
  const _WaterCard({required this.waterMl, required this.isAr, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final glasses = waterMl ~/ 250;
    const target = 8;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💧', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(isAr ? 'الماء' : 'Water',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
                const Spacer(),
                Text(
                  '${waterMl}ml / 2000ml',
                  style: TextStyle(fontSize: 12, color: AppColors.waterColor,
                      fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(target, (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < glasses ? Icons.water_drop : Icons.water_drop_outlined,
                    color: i < glasses ? AppColors.waterColor : Colors.grey.withOpacity(0.3),
                    size: 22,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onAdd(250),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(isAr ? '+250ml' : '+250ml', style: const TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.waterColor,
                        side: const BorderSide(color: AppColors.waterColor)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: waterMl > 0 ? onRemove : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meals List ────────────────────────────────────────
class _MealsList extends StatelessWidget {
  final NutritionState state;
  final bool isAr;
  final ValueChanged<String> onDelete;
  const _MealsList({required this.state, required this.isAr, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final byMeal = <String, List<MealEntry>>{};
    for (final m in state.meals) {
      (byMeal[m.mealType] ??= []).add(m);
    }

    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
    final mealLabels = {
      'breakfast': isAr ? 'الإفطار 🌅' : 'Breakfast 🌅',
      'lunch': isAr ? 'الغداء ☀️' : 'Lunch ☀️',
      'dinner': isAr ? 'العشاء 🌙' : 'Dinner 🌙',
      'snack': isAr ? 'وجبة خفيفة 🍎' : 'Snack 🍎',
    };

    return Column(
      children: mealTypes.map((type) {
        final entries = byMeal[type] ?? [];
        final typeCals = entries.fold(0.0, (s, e) => s + e.calories);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            title: Row(
              children: [
                Text(mealLabels[type] ?? type,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
                const Spacer(),
                if (typeCals > 0)
                  Text('${typeCals.toStringAsFixed(0)} kcal',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
              ],
            ),
            children: [
              ...entries.map((e) => ListTile(
                    dense: true,
                    title: Text(e.foodName,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    subtitle: Text(
                        '${e.amount.toStringAsFixed(0)}g  •  ${e.calories.toStringAsFixed(0)} kcal  •  P:${e.protein.toStringAsFixed(1)}  C:${e.carbs.toStringAsFixed(1)}  F:${e.fat.toStringAsFixed(1)}',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () => onDelete(e.id),
                    ),
                  )),
              ListTile(
                dense: true,
                leading: const Icon(Icons.add, size: 18),
                title: Text(isAr ? 'إضافة' : 'Add',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                onTap: () => GoRouter.of(context).push('/nutrition/search?meal=$type'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
