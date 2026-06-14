import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';
import '../../../widgets/common/app_text_field.dart';

class BanManagementScreen extends ConsumerStatefulWidget {
  const BanManagementScreen({super.key});
  @override
  ConsumerState<BanManagementScreen> createState() => _BanManagementScreenState();
}

class _BanManagementScreenState extends ConsumerState<BanManagementScreen> {
  List<dynamic> _bans = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = ref.read(apiServiceProvider);
    final res = await api.listBanned();
    if (mounted) setState(() { _bans = res['list'] ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة الحظر' : 'Ban Management', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _addBanDialog(context, isAr))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _bans.isEmpty ? Center(child: Text(isAr ? 'لا يوجد محظورون' : 'No bans', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _bans.length,
              itemBuilder: (ctx, i) {
                final b = _bans[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.block, color: AppColors.error),
                    title: Text(b['email'] ?? b['phone'] ?? b['deviceId'] ?? 'Unknown', style: const TextStyle(fontFamily: 'Cairo')),
                    subtitle: Text(b['reason'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        final api = ref.read(apiServiceProvider);
                        await api.unbanIdentity(b['id']);
                        await _load();
                      },
                    ),
                  ),
                );
              }),
    );
  }

  void _addBanDialog(BuildContext ctx, bool isAr) {
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    showDialog(context: ctx, builder: (dCtx) => AlertDialog(
      title: Text(isAr ? 'إضافة حظر' : 'Add Ban'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        AppTextField(controller: emailCtrl, label: 'Email', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 8),
        AppTextField(controller: phoneCtrl, label: isAr ? 'هاتف' : 'Phone', prefixIcon: Icons.phone),
        const SizedBox(height: 8),
        AppTextField(controller: reasonCtrl, label: isAr ? 'السبب' : 'Reason', prefixIcon: Icons.info_outline),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(dCtx);
          final api = ref.read(apiServiceProvider);
          await api.banIdentity({'email': emailCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'reason': reasonCtrl.text.trim(), 'bannedBy': ref.read(authStateProvider).user?.uid ?? '', 'ts': DateTime.now().millisecondsSinceEpoch, 'id': 'ban_${DateTime.now().millisecondsSinceEpoch}'});
          await _load();
          if (mounted) AppUtils.showSnack(ctx, isAr ? 'تم الحظر ✓' : 'Banned ✓', isSuccess: true);
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: Text(isAr ? 'حظر' : 'Ban')),
      ],
    ));
  }
}
