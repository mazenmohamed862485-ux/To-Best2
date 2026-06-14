import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';

class ProgressPhotosScreen extends ConsumerWidget {
  const ProgressPhotosScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'صور التقدم' : 'Progress Photos', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
      body: Center(child: Text(isAr ? 'قريباً: صور التقدم 📸' : 'Coming soon: Progress Photos 📸', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 16))),
    );
  }
}
