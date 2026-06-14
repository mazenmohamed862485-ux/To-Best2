import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_providers.dart';
import '../providers/admin_provider.dart';
import '../../../widgets/common/app_text_field.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _searchQ = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';

    if (currentUser?.isAdminLike != true) {
      return Scaffold(
        body: Center(
          child: Text(isAr ? '⛔ صلاحيات غير كافية' : '⛔ Access Denied',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 18)),
        ),
      );
    }

    final filtered = adminState.users.where((u) {
      if (_searchQ.isEmpty) return true;
      final q = _searchQ.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.phone.toLowerCase().contains(q));
    }).toList();

    final pending = adminState.users.where((u) => u.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'لوحة الإدارة' : 'Admin Panel',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [
          if (adminState.pendingSubRequests > 0)
            Badge(
              label: Text('${adminState.pendingSubRequests}'),
              child: IconButton(
                icon: const Icon(Icons.payment_outlined),
                onPressed: () => context.push('/admin/subscriptions'),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.payment_outlined),
              onPressed: () => context.push('/admin/subscriptions'),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/admin/audit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'bans': context.push('/admin/bans'); break;
                case 'promos': context.push('/admin/promos'); break;
                case 'refresh': ref.read(adminProvider.notifier).load(); break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'bans', child: Text(isAr ? 'الحظر' : 'Bans', style: const TextStyle(fontFamily: 'Cairo'))),
              PopupMenuItem(value: 'promos', child: Text(isAr ? 'الأكواد' : 'Promos', style: const TextStyle(fontFamily: 'Cairo'))),
              PopupMenuItem(value: 'refresh', child: Text(isAr ? 'تحديث' : 'Refresh', style: const TextStyle(fontFamily: 'Cairo'))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: isAr ? 'الكل (${adminState.users.length})' : 'All (${adminState.users.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isAr ? 'انتظار' : 'Pending'),
                  if (pending > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.warn, borderRadius: BorderRadius.circular(8)),
                      child: Text('$pending', style: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'Cairo')),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: isAr ? 'نشط' : 'Active'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Stats row ─────────────────────────
          _StatsRow(state: adminState, isAr: isAr),

          // ── Search ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: AppTextField(
              hint: isAr ? 'بحث بالاسم أو البريد...' : 'Search name or email...',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _searchQ = v),
            ),
          ),

          // ── Tab views ─────────────────────────
          Expanded(
            child: adminState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _UsersList(users: filtered, isAr: isAr, isSuperAdmin: currentUser?.isSuperAdmin == true),
                      _UsersList(users: filtered.where((u) => u.status == 'pending').toList(), isAr: isAr, isSuperAdmin: currentUser?.isSuperAdmin == true),
                      _UsersList(users: filtered.where((u) => u.status == 'active').toList(), isAr: isAr, isSuperAdmin: currentUser?.isSuperAdmin == true),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, isAr),
        icon: const Icon(Icons.person_add),
        label: Text(isAr ? 'إضافة مستخدم' : 'Add User', style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  void _showAddUserDialog(BuildContext ctx, bool isAr) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'إضافة مستخدم' : 'Add User', style: const TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: nameCtrl, label: isAr ? 'الاسم' : 'Name', prefixIcon: Icons.person),
              const SizedBox(height: 10),
              AppTextField(controller: emailCtrl, label: isAr ? 'البريد' : 'Email', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              AppTextField(controller: passCtrl, label: isAr ? 'كلمة المرور' : 'Password', prefixIcon: Icons.lock, obscureText: true),
              const SizedBox(height: 10),
              AppTextField(controller: phoneCtrl, label: isAr ? 'الهاتف' : 'Phone', prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              final ok = await ref.read(adminProvider.notifier).addUser({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'password': passCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
              });
              if (mounted) {
                AppUtils.showSnack(ctx,
                    ok ? (isAr ? 'تمت الإضافة ✓' : 'User added ✓') : (isAr ? 'فشلت الإضافة' : 'Failed'),
                    isSuccess: ok, isError: !ok);
              }
            },
            child: Text(isAr ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AdminState state;
  final bool isAr;
  const _StatsRow({required this.state, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state.users.where((u) => u.status == 'active').length;
    final pending = state.users.where((u) => u.status == 'pending').length;
    final total = state.users.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('$total', isAr ? 'المجموع' : 'Total', Colors.grey),
          _StatItem('$active', isAr ? 'نشط' : 'Active', AppColors.ok),
          _StatItem('$pending', isAr ? 'انتظار' : 'Pending', AppColors.warn),
          _StatItem('${state.pendingSubRequests}', isAr ? 'اشتراكات' : 'Subs', AppColors.accent),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, fontFamily: 'Cairo')),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
      ],
    );
  }
}

// ── Users List ────────────────────────────────────────
class _UsersList extends ConsumerWidget {
  final List<UserModel> users;
  final bool isAr;
  final bool isSuperAdmin;
  const _UsersList({required this.users, required this.isAr, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (users.isEmpty) {
      return Center(child: Text(isAr ? 'لا يوجد مستخدمون' : 'No users found',
          style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: users.length,
      itemBuilder: (ctx, i) => _UserTile(
        user: users[i],
        isAr: isAr,
        isSuperAdmin: isSuperAdmin,
        onTap: () => context.push('/admin/user/${users[i].uid}'),
        onApprove: () => ref.read(adminProvider.notifier).approveUser(users[i].uid),
        onReject: () => _showRejectDialog(ctx, ref, users[i], isAr),
        onDelete: isSuperAdmin
            ? () => _confirmDelete(ctx, ref, users[i], isAr)
            : null,
      ),
    );
  }

  void _showRejectDialog(BuildContext ctx, WidgetRef ref, UserModel u, bool isAr) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'سبب الرفض' : 'Reject Reason'),
        content: AppTextField(controller: reasonCtrl, label: isAr ? 'السبب (اختياري)' : 'Reason (optional)', prefixIcon: Icons.info_outline),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              ref.read(adminProvider.notifier).rejectUser(u.uid, reasonCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAr ? 'رفض' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, UserModel u, bool isAr) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'حذف المستخدم؟' : 'Delete User?'),
        content: Text('${u.name} — ${u.email}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              ref.read(adminProvider.notifier).deleteUser(u.uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isAr;
  final bool isSuperAdmin;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onDelete;

  const _UserTile({
    required this.user,
    required this.isAr,
    required this.isSuperAdmin,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = user.status == 'active'
        ? AppColors.ok
        : user.status == 'pending'
            ? AppColors.warn
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          backgroundImage: user.pictureUrl != null ? NetworkImage(user.pictureUrl!) : null,
          child: user.pictureUrl == null
              ? Text(AppUtils.initials(user.name),
                  style: TextStyle(color: theme.colorScheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.w800))
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(user.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.status == 'active' ? (isAr ? 'نشط' : 'Active')
                    : user.status == 'pending' ? (isAr ? 'انتظار' : 'Pending')
                    : (isAr ? 'مرفوض' : 'Rejected'),
                style: TextStyle(fontSize: 10, color: statusColor, fontFamily: 'Cairo', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Row(
              children: [
                Text(user.role, style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontFamily: 'Cairo')),
                if (user.program != null) ...[
                  const Text('  •  ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(user.program!, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                ],
              ],
            ),
          ],
        ),
        trailing: user.status == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: AppColors.ok, size: 22),
                    onPressed: onApprove,
                    tooltip: isAr ? 'موافقة' : 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.error, size: 22),
                    onPressed: onReject,
                    tooltip: isAr ? 'رفض' : 'Reject',
                  ),
                ],
              )
            : Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
      ),
    );
  }
}
