import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_button.dart';

class FirstRunWizardScreen extends ConsumerWidget {
  const FirstRunWizardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🏋️', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 24),
      Text('TO Best', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Theme.of(context).colorScheme.primary)),
      const SizedBox(height: 8),
      Text(isAr ? 'نظام التدريب والتغذية الاحترافي' : 'Professional Training & Nutrition', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
      const SizedBox(height: 48),
      AppButton(label: isAr ? 'ابدأ الآن' : 'Get Started', icon: Icons.arrow_forward, onPressed: () => context.go(AppRoutes.login)),
    ]))));
  }
}
