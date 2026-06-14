import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/config/programs_config.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';
import '../providers/admin_provider.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String uid;
  const UserDetailScreen({super.key, required this.uid});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _saving = false;
  String? _selectedProgram;
  int? _selectedDays;
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final user = adminState.getUserById(widget.uid);
    final me = ref.watch(authStateProvider).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isAr ? 'المستخدم' : 'User')),
        body: Center(child: Text(isAr ? 'لم يتم العثور على المستخدم' : 'User not found',
            style: const TextStyle(fontFamily: 'Cairo'))),
      );
    }

    _selectedProgram ??= user.program;
    _selectedDays ??= user.programDays;
    _selectedRole ??= user.role;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [
          if (me?.isSuperAdmin == true && user.uid != me?.uid)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, isAr),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile card ──────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      backgroundImage: user.pictureUrl != null ? NetworkImage(user.pictureUrl!) : null,
                      child: user.pictureUrl == null
                          ? Text(AppUtils.initials(user.name),
                              style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800, fontFamily: 'Cairo'))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                    Text(user.email, style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 13)),
                    if (user.phone.isNotEmpty)
                      Text(user.phone, style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 12)),
                    const SizedBox(height: 8),
                    _StatusBadge(status: user.status, isAr: isAr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Program assignment ────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAr ? 'البرنامج التدريبي' : 'Training Program',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedProgram,
                      decoration: InputDecoration(
                        labelText: isAr ? 'البرنامج' : 'Program',
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(isAr ? '-- بدون برنامج --' : '-- No Program --', style: const TextStyle(fontFamily: 'Cairo'))),
                        ...TrainingPrograms.all.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.nameAr, style: const TextStyle(fontFamily: 'Cairo')),
                        )),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedProgram = v;
                          _selectedDays = v != null ? TrainingPrograms.findById(v)?.daysOptions.first : null;
                        });
                      },
                    ),
                    if (_selectedProgram != null) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _selectedDays,
                        decoration: InputDecoration(
                          labelText: isAr ? 'عدد الأيام' : 'Days per Week',
                          isDense: true,
                        ),
                        items: (TrainingPrograms.findById(_selectedProgram!)?.daysOptions ?? [4])
                            .map((d) => DropdownMenuItem(value: d, child: Text('$d ${isAr ? "أيام" : "days"}', style: const TextStyle(fontFamily: 'Cairo'))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedDays = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppButton(
                      label: isAr ? 'تعيين البرنامج' : 'Assign Program',
                      icon: Icons.fitness_center,
                      isLoading: _saving,
                      onPressed: () => _saveProgram(isAr),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Role assignment ───────────────────
            if (me?.isSuperAdmin == true)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAr ? 'الدور' : 'Role',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(labelText: isAr ? 'الدور' : 'Role', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'TRAINEE', child: Text('Trainee', style: TextStyle(fontFamily: 'Cairo'))),
                          DropdownMenuItem(value: 'COACH', child: Text('Coach', style: TextStyle(fontFamily: 'Cairo'))),
                          DropdownMenuItem(value: 'ADMIN', child: Text('Admin', style: TextStyle(fontFamily: 'Cairo'))),
                          DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin', style: TextStyle(fontFamily: 'Cairo'))),
                        ],
                        onChanged: (v) => setState(() => _selectedRole = v),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: isAr ? 'تحديث الدور' : 'Update Role',
                        icon: Icons.security,
                        isLoading: _saving,
                        onPressed: () => _saveRole(isAr),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // ── Macros ────────────────────────────
            _MacrosCard(user: user, isAr: isAr),
            const SizedBox(height: 16),

            // ── Subscription ──────────────────────
            _SubCard(user: user, isAr: isAr),
            const SizedBox(height: 16),

            // ── Status actions ────────────────────
            if (user.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: isAr ? 'موافقة' : 'Approve',
                      icon: Icons.check_circle,
                      color: AppColors.ok,
                      onPressed: () async {
                        await ref.read(adminProvider.notifier).approveUser(user.uid);
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: isAr ? 'رفض' : 'Reject',
                      icon: Icons.cancel,
                      color: AppColors.error,
                      onPressed: () async {
                        await ref.read(adminProvider.notifier).rejectUser(user.uid, '');
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProgram(bool isAr) async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await ref.read(adminProvider.notifier).updateUser(widget.uid, {
      'program': _selectedProgram,
      'programDays': _selectedDays,
      'status': 'active',
    });
    if (mounted) {
      setState(() => _saving = false);
      AppUtils.showSnack(context,
          ok ? (isAr ? 'تم حفظ البرنامج ✓' : 'Program saved ✓') : (isAr ? 'فشل الحفظ' : 'Save failed'),
          isSuccess: ok, isError: !ok);
    }
  }

  Future<void> _saveRole(bool isAr) async {
    if (_saving || _selectedRole == null) return;
    setState(() => _saving = true);
    final ok = await ref.read(adminProvider.notifier).updateUser(widget.uid, {'role': _selectedRole});
    if (mounted) {
      setState(() => _saving = false);
      AppUtils.showSnack(context,
          ok ? (isAr ? 'تم تحديث الدور ✓' : 'Role updated ✓') : (isAr ? 'فشل' : 'Failed'),
          isSuccess: ok, isError: !ok);
    }
  }

  void _confirmDelete(BuildContext ctx, bool isAr) {
    final user = ref.read(adminProvider).getUserById(widget.uid);
    if (user == null) return;
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'حذف المستخدم؟' : 'Delete User?'),
        content: Text('${user.name} — ${user.email}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await ref.read(adminProvider.notifier).deleteUser(widget.uid);
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isAr;
  const _StatusBadge({required this.status, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final color = status == 'active' ? AppColors.ok : status == 'pending' ? AppColors.warn : AppColors.error;
    final label = status == 'active' ? (isAr ? 'نشط' : 'Active')
        : status == 'pending' ? (isAr ? 'انتظار' : 'Pending') : (isAr ? 'مرفوض' : 'Rejected');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: color, fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
    );
  }
}

class _MacrosCard extends ConsumerWidget {
  final dynamic user;
  final bool isAr;
  const _MacrosCard({required this.user, required this.isAr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calsCtrl = TextEditingController(text: user.dailyCals.toStringAsFixed(0));
    final protCtrl = TextEditingController(text: user.dailyProtein.toStringAsFixed(0));
    final carbCtrl = TextEditingController(text: user.dailyCarbs.toStringAsFixed(0));
    final fatCtrl = TextEditingController(text: user.dailyFat.toStringAsFixed(0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAr ? 'الماكروز اليومية' : 'Daily Macros',
                style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppTextField(controller: calsCtrl, label: isAr ? 'سعرات' : 'Calories', keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: AppTextField(controller: protCtrl, label: isAr ? 'بروتين g' : 'Protein g', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: AppTextField(controller: carbCtrl, label: isAr ? 'كارب g' : 'Carbs g', keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: AppTextField(controller: fatCtrl, label: isAr ? 'دهون g' : 'Fat g', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: isAr ? 'حفظ الماكروز' : 'Save Macros',
              icon: Icons.save,
              onPressed: () async {
                final ok = await ref.read(adminProvider.notifier).updateUser(user.uid, {
                  'dailyCals': double.tryParse(calsCtrl.text) ?? 0,
                  'dailyProtein': double.tryParse(protCtrl.text) ?? 0,
                  'dailyCarbs': double.tryParse(carbCtrl.text) ?? 0,
                  'dailyFat': double.tryParse(fatCtrl.text) ?? 0,
                });
                if (context.mounted) {
                  AppUtils.showSnack(context, ok ? '✓' : 'Failed', isSuccess: ok, isError: !ok);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubCard extends ConsumerWidget {
  final dynamic user;
  final bool isAr;
  const _SubCard({required this.user, required this.isAr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = user.isSubscriptionActive ? AppColors.ok : AppColors.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(isAr ? 'الاشتراك' : 'Subscription',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(user.subscriptionStatus, style: TextStyle(color: color, fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${isAr ? "النوع" : "Plan"}: ${user.subscriptionType ?? "-"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            if (user.subscriptionEnd != null && user.subscriptionEnd! > 0)
              Text('${isAr ? "ينتهي" : "Ends"}: ${DateTime.fromMillisecondsSinceEpoch(user.subscriptionEnd!).toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
