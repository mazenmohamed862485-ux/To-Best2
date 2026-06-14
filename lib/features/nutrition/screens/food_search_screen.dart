import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_text_field.dart';
import '../providers/nutrition_provider.dart';
import '../data/food_database.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  final String? mealType;
  const FoodSearchScreen({super.key, this.mealType});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedMeal = 'snack';
  double _amount = 100;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.mealType ?? 'snack';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FoodItem> get _filtered {
    if (_query.isEmpty) return FoodDatabase.all.take(40).toList();
    final q = _query.toLowerCase();
    return FoodDatabase.all
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.nameEn.toLowerCase().contains(q) ||
            (f.category?.toLowerCase().contains(q) ?? false))
        .take(50)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    final mealLabels = {
      'breakfast': isAr ? 'الإفطار' : 'Breakfast',
      'lunch': isAr ? 'الغداء' : 'Lunch',
      'dinner': isAr ? 'العشاء' : 'Dinner',
      'snack': isAr ? 'وجبة خفيفة' : 'Snack',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'ابحث عن طعام' : 'Search Food',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppTextField(
              controller: _searchCtrl,
              hint: isAr ? 'ابحث بالاسم...' : 'Search by name...',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _query = v),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      })
                  : null,
            ),
          ),
          // ── Meal type + amount ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMeal,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الوجبة' : 'Meal',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: mealLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedMeal = v ?? 'snack'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: AppTextField(
                    initialValue: '100',
                    label: isAr ? 'كمية (g)' : 'Amount (g)',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 100),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Results ────────────────────────────
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final food = _filtered[i];
                final cals = (food.cals * _amount / 100).toStringAsFixed(0);
                final protein = (food.p * _amount / 100).toStringAsFixed(1);
                final carbs = (food.c * _amount / 100).toStringAsFixed(1);
                final fat = (food.f * _amount / 100).toStringAsFixed(1);

                return ListTile(
                  title: Text(isAr ? food.name : (food.nameEn.isNotEmpty ? food.nameEn : food.name),
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${_amount.toStringAsFixed(0)}g  |  $cals kcal  |  P:$protein  C:$carbs  F:$fat',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
                    onPressed: () => _addFood(ctx, food, isAr),
                  ),
                  onTap: () => _showFoodDetail(ctx, food, isAr),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addFood(BuildContext ctx, FoodItem food, bool isAr) {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    final entry = food.toMealEntry(
      uid: user.uid,
      date: AppUtils.todayKey(),
      mealType: _selectedMeal,
      amount: _amount,
      id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
    );

    ref.read(nutritionProvider.notifier).addMeal(entry);
    AppUtils.showSnack(ctx, isAr ? 'تمت الإضافة ✓' : 'Added ✓', isSuccess: true);
    Navigator.pop(ctx);
  }

  void _showFoodDetail(BuildContext ctx, FoodItem food, bool isAr) {
    showModalBottomSheet(
      context: ctx,
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
              if (food.nameEn.isNotEmpty)
                Text(food.nameEn, style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              Text('${isAr ? "لكل 100g" : "Per 100g"}:',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              _FoodDetailRow('🔥 ${isAr ? "سعرات" : "Calories"}', '${food.cals.toStringAsFixed(0)} kcal'),
              _FoodDetailRow('🥩 ${isAr ? "بروتين" : "Protein"}', '${food.p.toStringAsFixed(1)}g'),
              _FoodDetailRow('🌾 ${isAr ? "كربوهيدرات" : "Carbs"}', '${food.c.toStringAsFixed(1)}g'),
              _FoodDetailRow('🥑 ${isAr ? "دهون" : "Fat"}', '${food.f.toStringAsFixed(1)}g'),
              if (food.fiber != null)
                _FoodDetailRow('🌿 ${isAr ? "ألياف" : "Fiber"}', '${food.fiber!.toStringAsFixed(1)}g'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(bCtx);
                    _addFood(ctx, food, isAr);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(isAr ? 'إضافة ${_amount.toStringAsFixed(0)}g' : 'Add ${_amount.toStringAsFixed(0)}g'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _FoodDetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
