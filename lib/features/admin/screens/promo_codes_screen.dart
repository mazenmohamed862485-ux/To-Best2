import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';
import '../../../widgets/common/app_text_field.dart';

class PromoCodesScreen extends ConsumerStatefulWidget {
  const PromoCodesScreen({super.key});
  @override
  ConsumerState<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends ConsumerState<PromoCodesScreen> {
  List<dynamic> _promos = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = ref.read(apiServiceProvider);
    final res = await api.listPromos();
    if (mounted) setState(() { _promos = res['codes'] ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'أكواد الخصم' : 'Promo Codes', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _addPromoDialog(context, isAr))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _promos.isEmpty ? Center(child: Text(isAr ? 'لا توجد أكواد' : 'No codes', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _promos.length,
              itemBuilder: (ctx, i) {
                final p = _promos[i];
                return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                  leading: const Icon(Icons.discount_outlined, color: AppColors.accent),
                  title: Text(p['code']?.toString() ?? '', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  subtitle: Text('${p['discount']}% off  •  ${p['usedCount'] ?? 0}/${p['maxUses'] ?? "∞"} ${isAr ? "استخدام" : "uses"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () async {
                    await ref.read(apiServiceProvider).deletePromo(p['code']);
                    await _load();
                  }),
                ));
              }),
    );
  }

  void _addPromoDialog(BuildContext ctx, bool isAr) {
    final codeCtrl = TextEditingController();
    final discCtrl = TextEditingController(text: '10');
    final maxCtrl = TextEditingController(text: '100');
    showDialog(context: ctx, builder: (dCtx) => AlertDialog(
      title: Text(isAr ? 'إنشاء كود' : 'Create Promo'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        AppTextField(controller: codeCtrl, label: isAr ? 'الكود' : 'Code', prefixIcon: Icons.code),
        const SizedBox(height: 8),
        AppTextField(controller: discCtrl, label: isAr ? 'الخصم %' : 'Discount %', prefixIcon: Icons.percent, keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        AppTextField(controller: maxCtrl, label: isAr ? 'أقصى استخدام' : 'Max Uses', prefixIcon: Icons.repeat, keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(dCtx);
          await ref.read(apiServiceProvider).createPromo(codeCtrl.text.trim(), double.tryParse(discCtrl.text) ?? 10, int.tryParse(maxCtrl.text) ?? 100);
          await _load();
          if (mounted) AppUtils.showSnack(ctx, isAr ? 'تم الإنشاء ✓' : 'Created ✓', isSuccess: true);
        }, child: Text(isAr ? 'إنشاء' : 'Create')),
      ],
    ));
  }
}
