import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('⏳', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 24),
      Text(isAr ? 'في انتظار الموافقة' : 'Pending Approval', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(isAr ? 'تم إرسال طلبك للمدرب. ستصلك إشعار عند الموافقة على حسابك.' : 'Your request was sent to the coach. You will be notified upon approval.', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
      const SizedBox(height: 32),
      OutlinedButton.icon(icon: const Icon(Icons.arrow_back), label: Text(isAr ? 'العودة لتسجيل الدخول' : 'Back to Login'), onPressed: () { ref.read(authStateProvider.notifier).logout(); context.go(AppRoutes.login); }),
    ]))));
  }
}
