import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'سجل الإلتزام' : 'Attendance Log',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () => ref.read(attendanceProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Month navigation ──────────────────────
          _MonthNav(state: state, notifier: ref.read(attendanceProvider.notifier), isAr: isAr),

          // ── Stats row ────────────────────────────
          _StatsRow(state: state, isAr: isAr),

          // ── Calendar grid ────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _CalendarGrid(state: state, notifier: ref.read(attendanceProvider.notifier), isAr: isAr),
            ),
          ),

          // ── Mark today buttons ───────────────────
          _MarkTodayButtons(state: state, notifier: ref.read(attendanceProvider.notifier), isAr: isAr),
        ],
      ),
    );
  }
}

class _MonthNav extends StatelessWidget {
  final AttendanceState state;
  final AttendanceNotifier notifier;
  final bool isAr;
  const _MonthNav({required this.state, required this.notifier, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime(state.year, state.month);
    final months = isAr
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
           'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: notifier.prevMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${months[state.month - 1]} ${state.year}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
          ),
          IconButton(
            onPressed: notifier.nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AttendanceState state;
  final bool isAr;
  const _StatsRow({required this.state, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final gym = state.attendance.values.where((v) => v == AppConstants.attGym).length;
    final abs = state.attendance.values.where((v) => v == AppConstants.attAbsent).length;
    final rest = state.attendance.values.where((v) => v == AppConstants.attRest).length;
    final total = gym + abs;
    final pct = total > 0 ? (gym / total * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          _StatBadge(value: '$gym', label: isAr ? 'حضور' : 'Gym', color: AppColors.attGym),
          const Spacer(),
          _StatBadge(value: '$abs', label: isAr ? 'غياب' : 'Absent', color: AppColors.attAbsent),
          const Spacer(),
          _StatBadge(value: '$rest', label: isAr ? 'راحة' : 'Rest', color: AppColors.attRest),
          const Spacer(),
          _StatBadge(
            value: '$pct%',
            label: isAr ? 'الإلتزام' : 'Rate',
            color: pct >= 80
                ? AppColors.ok
                : pct >= 60
                    ? AppColors.warn
                    : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBadge({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: color, fontFamily: 'Cairo')),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final AttendanceState state;
  final AttendanceNotifier notifier;
  final bool isAr;
  const _CalendarGrid({required this.state, required this.notifier, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(state.year, state.month + 1, 0).day;
    final firstDayOfWeek = DateTime(state.year, state.month, 1).weekday;
    final today = AppUtils.todayKey();

    final dayNames = isAr
        ? ['أح', 'إث', 'ث', 'أر', 'خ', 'ج', 'س']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Day names header
        Row(
          children: dayNames
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: Colors.grey, fontFamily: 'Cairo')),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: daysInMonth + (firstDayOfWeek % 7),
          itemBuilder: (ctx, i) {
            final offset = firstDayOfWeek % 7;
            if (i < offset) return const SizedBox.shrink();

            final day = i - offset + 1;
            final dateKey =
                '${state.year}-${state.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final val = state.attendance[dateKey];
            final isToday = dateKey == today;

            Color bg = Colors.transparent;
            Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
            String? emoji;
            if (val == AppConstants.attGym) {
              bg = AppColors.attGym.withOpacity(0.2);
              textColor = AppColors.attGym;
              emoji = '✔';
            } else if (val == AppConstants.attAbsent) {
              bg = AppColors.attAbsent.withOpacity(0.2);
              textColor = AppColors.attAbsent;
              emoji = '✘';
            } else if (val == AppConstants.attRest) {
              bg = AppColors.attRest.withOpacity(0.1);
              textColor = AppColors.attRest;
              emoji = '🛌';
            }

            return GestureDetector(
              onTap: () => _showDayPicker(ctx, dateKey, val, isAr, notifier),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(
                          color: Theme.of(ctx).colorScheme.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: textColor, fontFamily: 'Cairo')),
                    if (emoji != null)
                      Text(emoji, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDayPicker(BuildContext ctx, String dateKey, String? current,
      bool isAr, AttendanceNotifier notifier) {
    showModalBottomSheet(
      context: ctx,
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dateKey,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check, color: AppColors.attGym),
                title: Text(isAr ? 'حضور ✔' : 'Gym ✔',
                    style: const TextStyle(fontFamily: 'Cairo')),
                selected: current == AppConstants.attGym,
                onTap: () {
                  notifier.mark(dateKey, AppConstants.attGym);
                  Navigator.pop(bCtx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.attAbsent),
                title: Text(isAr ? 'غياب ✘' : 'Absent ✘',
                    style: const TextStyle(fontFamily: 'Cairo')),
                selected: current == AppConstants.attAbsent,
                onTap: () {
                  notifier.mark(dateKey, AppConstants.attAbsent);
                  Navigator.pop(bCtx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.hotel, color: AppColors.attRest),
                title: Text(isAr ? 'راحة 🛌' : 'Rest 🛌',
                    style: const TextStyle(fontFamily: 'Cairo')),
                selected: current == AppConstants.attRest,
                onTap: () {
                  notifier.mark(dateKey, AppConstants.attRest);
                  Navigator.pop(bCtx);
                },
              ),
              if (current != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.grey),
                  title: Text(isAr ? 'حذف' : 'Clear',
                      style: const TextStyle(fontFamily: 'Cairo')),
                  onTap: () {
                    notifier.clear(dateKey);
                    Navigator.pop(bCtx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkTodayButtons extends StatelessWidget {
  final AttendanceState state;
  final AttendanceNotifier notifier;
  final bool isAr;
  const _MarkTodayButtons({required this.state, required this.notifier, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final today = AppUtils.todayKey();
    final current = state.attendance[today];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(isAr ? 'سجّل اليوم' : "Mark Today",
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: current == AppConstants.attGym
                        ? null
                        : () => notifier.mark(today, AppConstants.attGym),
                    icon: const Icon(Icons.fitness_center, size: 16),
                    label: Text(isAr ? 'حضور ✔' : 'Gym ✔'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.attGym,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: current == AppConstants.attAbsent
                        ? null
                        : () => notifier.mark(today, AppConstants.attAbsent),
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(isAr ? 'غياب ✘' : 'Absent ✘'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.attAbsent,
                        side: const BorderSide(color: AppColors.attAbsent)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: current == AppConstants.attRest
                      ? null
                      : () => notifier.mark(today, AppConstants.attRest),
                  icon: const Icon(Icons.hotel, size: 16),
                  label: Text(isAr ? 'راحة' : 'Rest'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
