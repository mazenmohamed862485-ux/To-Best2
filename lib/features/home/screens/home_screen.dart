import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_button.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final homeState = ref.watch(homeProvider);
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────
            SliverAppBar(
              floating: true,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              AppUtils.greeting(context),
                              style: const TextStyle(
                                  fontSize: 13, fontFamily: 'Cairo'),
                            ),
                            Text(
                              user.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.settings),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.15),
                          backgroundImage: user.pictureUrl != null
                              ? NetworkImage(user.pictureUrl!)
                              : null,
                          child: user.pictureUrl == null
                              ? Text(
                                  AppUtils.initials(user.name),
                                  style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Cairo'),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Row ──────────────────────
                  _StatsRow(homeState: homeState, isAr: isAr),
                  const SizedBox(height: 20),

                  // ── Today Session ──────────────────
                  _TodaySessionCard(homeState: homeState, isAr: isAr),
                  const SizedBox(height: 20),

                  // ── Subscription banner ────────────
                  if (!user.isAdminLike && !user.isSubscriptionActive)
                    _SubscriptionBanner(user: user, isAr: isAr),

                  // ── Quick access ───────────────────
                  _QuickAccessGrid(isAr: isAr),
                  const SizedBox(height: 20),

                  // ── Latest PRs ─────────────────────
                  _LatestPRsCard(homeState: homeState, isAr: isAr),
                  const SizedBox(height: 20),

                  // ── Admin quick link ───────────────
                  if (user.isAdminLike)
                    _AdminQuickCard(isAr: isAr),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final HomeState homeState;
  final bool isAr;
  const _StatsRow({required this.homeState, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${homeState.totalSessions}',
            label: isAr ? 'إجمالي الجلسات' : 'Total Sessions',
            icon: Icons.fitness_center,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${homeState.streak}',
            label: isAr ? 'سلسلة أيام 🔥' : 'Day Streak 🔥',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${homeState.gymDaysThisMonth}',
            label: isAr ? 'حضور الشهر' : 'Monthly Days',
            icon: Icons.calendar_today,
            color: AppColors.ok,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: color, fontFamily: 'Cairo')),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, fontFamily: 'Cairo', color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Today Session Card ────────────────────────────────
class _TodaySessionCard extends ConsumerWidget {
  final HomeState homeState;
  final bool isAr;
  const _TodaySessionCard({required this.homeState, required this.isAr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = homeState.todaySession;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'تمرين اليوم' : "Today's Session",
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (session == null) ...[
              Text(
                isAr ? '🛌 يوم راحة' : '🛌 Rest Day',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo', color: Colors.grey),
              ),
            ] else ...[
              Text(
                session,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo', color: theme.colorScheme.primary),
              ),
              if (homeState.isTodayDone) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.ok, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isAr ? 'انتهيت من الجلسة ✓' : 'Session completed ✓',
                      style: const TextStyle(
                          color: AppColors.ok, fontFamily: 'Cairo', fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              AppButton(
                label: homeState.isTodayDone
                    ? (isAr ? 'مراجعة الجلسة' : 'Review Session')
                    : (isAr ? 'ابدأ التمرين 💪' : 'Start Workout 💪'),
                icon: Icons.fitness_center,
                onPressed: () =>
                    context.go('${AppRoutes.workout}/session/$session'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Subscription Banner ───────────────────────────────
class _SubscriptionBanner extends StatelessWidget {
  final dynamic user;
  final bool isAr;
  const _SubscriptionBanner({required this.user, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warn.withOpacity(0.15), AppColors.warn.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warn.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_border, color: AppColors.warn),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'اشتراكك منتهٍ' : 'Subscription Expired',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                      color: AppColors.warn),
                ),
                Text(
                  isAr ? 'جدّد اشتراكك للوصول الكامل' : 'Renew to get full access',
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'Cairo', color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('${AppRoutes.subscription}?renewal=true'),
            child: Text(isAr ? 'تجديد' : 'Renew'),
          ),
        ],
      ),
    );
  }
}

// ── Quick Access Grid ─────────────────────────────────
class _QuickAccessGrid extends StatelessWidget {
  final bool isAr;
  const _QuickAccessGrid({required this.isAr});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(Icons.restaurant, isAr ? 'التغذية' : 'Nutrition',
          AppColors.proteinColor, AppRoutes.nutrition),
      _QuickItem(Icons.calendar_month, isAr ? 'الإلتزام' : 'Attendance',
          AppColors.accent, AppRoutes.attendance),
      _QuickItem(Icons.trending_up, isAr ? 'التقدم' : 'Progress',
          AppColors.carbsColor, AppRoutes.progress),
      _QuickItem(Icons.chat_bubble_outline, isAr ? 'الشات' : 'Chat',
          AppColors.warn, AppRoutes.chat),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isAr ? 'وصول سريع' : 'Quick Access',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
        const SizedBox(height: 10),
        Row(
          children: items.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickTile(item: item),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickItem(this.icon, this.label, this.color, this.route);
}

class _QuickTile extends StatelessWidget {
  final _QuickItem item;
  const _QuickTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(item.label,
                  style: const TextStyle(fontSize: 11, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Latest PRs Card ───────────────────────────────────
class _LatestPRsCard extends StatelessWidget {
  final HomeState homeState;
  final bool isAr;
  const _LatestPRsCard({required this.homeState, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(isAr ? 'أحدث الأرقام القياسية' : 'Latest PRs',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 12),
            if (homeState.latestPRs.isEmpty)
              Text(isAr ? 'لا توجد أرقام قياسية بعد' : 'No PRs yet',
                  style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'))
            else
              ...homeState.latestPRs.take(5).map((pr) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(pr.exerciseName,
                              style: const TextStyle(
                                  fontSize: 13, fontFamily: 'Cairo')),
                        ),
                        Text(
                          '${pr.weight}kg × ${pr.reps}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                              fontFamily: 'Cairo'),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${pr.epley.toStringAsFixed(0)} 1RM)',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey,
                              fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Admin Quick Card ──────────────────────────────────
class _AdminQuickCard extends StatelessWidget {
  final bool isAr;
  const _AdminQuickCard({required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.08),
      child: ListTile(
        leading: Icon(Icons.admin_panel_settings, color: theme.colorScheme.primary),
        title: Text(isAr ? 'لوحة الإدارة' : 'Admin Panel',
            style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
        subtitle: Text(isAr ? 'إدارة المستخدمين والاشتراكات' : 'Manage users & subscriptions',
            style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go(AppRoutes.admin),
      ),
    );
  }
}
