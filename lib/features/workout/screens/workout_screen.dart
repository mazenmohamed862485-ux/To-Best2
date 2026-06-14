import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/config/programs_config.dart';
import '../../../providers/app_providers.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);
    if (user == null) return const SizedBox.shrink();
    final program = user.program != null ? TrainingPrograms.findById(user.program!) : null;
    final sessions = program?.getSessions(user.programDays ?? 4) ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'التمرين' : 'Workout', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
      body: user.program == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(isAr ? 'لم يتم تعيين برنامج بعد' : 'No program assigned yet', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              Text(isAr ? 'تواصل مع مدربك لتعيين برنامجك' : 'Contact your coach to assign a program', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey, fontSize: 13)),
            ]))
          : CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.2), theme.colorScheme.primary.withOpacity(0.05)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3))),
                child: Row(children: [
                  Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(program?.nameAr ?? '', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 16, color: theme.colorScheme.primary)),
                    Text('${user.programDays ?? 4} ${isAr ? "أيام/أسبوع" : "days/week"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
                  ])),
                ])),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                  final session = sessions[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Text('${i + 1}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontFamily: 'Cairo'))),
                      title: Text(session, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 15)),
                      subtitle: Text('${ExerciseDatabase.getForSession(session).length} ${isAr ? "تمرين" : "exercises"}',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
                      trailing: ElevatedButton.icon(
                        onPressed: () => context.push('/workout/session/$session'),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text(isAr ? 'ابدأ' : 'Start', style: const TextStyle(fontFamily: 'Cairo')),
                      ),
                    ),
                  );
                }, childCount: sessions.length)),
              ),
            ]),
    );
  }
}
