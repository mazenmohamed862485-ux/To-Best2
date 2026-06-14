import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'خطة الوجبات' : 'Meal Plan', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
      body: Center(child: Text(isAr ? 'خطة الوجبات ستظهر هنا' : 'Meal plan will appear here', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 16))),
    );
  }
}
