import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../services/db_service.dart';
import '../../../services/sync_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});
  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  List<Measurement> _list = [];
  bool _loading = true;
  bool _saving = false;

  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();
  final _armsCtrl = TextEditingController();
  final _thighsCtrl = TextEditingController();
  final _neckCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) { setState(() => _loading = false); return; }
    final db = ref.read(dbServiceProvider);
    final list = await db.getMeasurements(user.uid);
    if (mounted) setState(() { _list = list; _loading = false; });
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    setState(() => _saving = true);
    final m = Measurement(uid: user.uid, date: AppUtils.todayKey(),
      weight: double.tryParse(_weightCtrl.text), waist: double.tryParse(_waistCtrl.text),
      chest: double.tryParse(_chestCtrl.text), hips: double.tryParse(_hipsCtrl.text),
      arms: double.tryParse(_armsCtrl.text), thighs: double.tryParse(_thighsCtrl.text),
      neck: double.tryParse(_neckCtrl.text), notes: _notesCtrl.text.trim());
    final db = ref.read(dbServiceProvider);
    await db.saveMeasurement(m);
    final sync = ref.read(syncServiceProvider);
    await sync.syncMeasurement(user.uid, m.date, m.toJson());
    await _load();
    if (mounted) { setState(() => _saving = false); AppUtils.showSnack(context, 'تم الحفظ ✓', isSuccess: true); }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'القياسات' : 'Measurements', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isAr ? 'قياسات اليوم' : "Today's Measurements", style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppTextField(controller: _weightCtrl, label: isAr ? 'الوزن (كغ)' : 'Weight (kg)', keyboardType: TextInputType.number, prefixIcon: Icons.monitor_weight_outlined)),
            const SizedBox(width: 8),
            Expanded(child: AppTextField(controller: _waistCtrl, label: isAr ? 'الخصر (سم)' : 'Waist (cm)', keyboardType: TextInputType.number, prefixIcon: Icons.straighten)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: AppTextField(controller: _chestCtrl, label: isAr ? 'الصدر (سم)' : 'Chest (cm)', keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: AppTextField(controller: _hipsCtrl, label: isAr ? 'الأرداف (سم)' : 'Hips (cm)', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: AppTextField(controller: _armsCtrl, label: isAr ? 'الذراع (سم)' : 'Arms (cm)', keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: AppTextField(controller: _thighsCtrl, label: isAr ? 'الفخذ (سم)' : 'Thighs (cm)', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 8),
          AppTextField(controller: _neckCtrl, label: isAr ? 'الرقبة (سم)' : 'Neck (cm)', keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          AppTextField(controller: _notesCtrl, label: isAr ? 'ملاحظات' : 'Notes', prefixIcon: Icons.note_outlined, maxLines: 2),
          const SizedBox(height: 12),
          AppButton(label: isAr ? 'حفظ القياسات' : 'Save Measurements', icon: Icons.save, isLoading: _saving, onPressed: _save),
        ]))),
        const SizedBox(height: 16),
        if (_loading) const Center(child: CircularProgressIndicator())
        else ..._list.take(10).map((m) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          title: Text(m.date, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
          subtitle: Text([
            if (m.weight != null) '⚖️ ${m.weight}kg',
            if (m.waist != null) '📏 Waist ${m.waist}cm',
            if (m.chest != null) '📏 Chest ${m.chest}cm',
          ].join('  •  '), style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
        ))),
      ])),
    );
  }
}
