import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  final bool isRenewal;
  const SubscriptionScreen({super.key, this.isRenewal = false});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _selectedPlan = 'full';
  int _selectedMonths = 1;
  String? _promoCode;
  double _discount = 0;
  bool _promoChecked = false;
  bool _promoValid = false;
  bool _submitting = false;
  String? _paymentProofPath;
  final _promoCtrl = TextEditingController();

  static const Map<String, Map<String, dynamic>> _plans = {
    'light': {'nameAr': 'لايت 🌙', 'nameEn': 'Light 🌙', 'price': 100, 'features': ['تمرين', 'إلتزام', 'شات']},
    'full': {'nameAr': 'كامل ⭐', 'nameEn': 'Full ⭐', 'price': 200, 'features': ['تمرين', 'تغذية', 'إلتزام', 'تقدم', 'شات', 'دعم مباشر']},
  };

  @override
  void dispose() { _promoCtrl.dispose(); super.dispose(); }

  double get _finalPrice {
    final basePrice = (_plans[_selectedPlan]?['price'] as int? ?? 200) * _selectedMonths;
    return basePrice * (1 - _discount / 100);
  }

  Future<void> _checkPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    final api = ref.read(apiServiceProvider);
    final res = await api.checkPromo(code);
    setState(() {
      _promoChecked = true;
      _promoValid = res['ok'] == true;
      _discount = (res['discount'] as num?)?.toDouble() ?? 0;
      if (_promoValid) _promoCode = code;
    });
    AppUtils.showSnack(context, _promoValid ? 'كود صحيح! خصم $_discount%' : 'كود غير صحيح', isSuccess: _promoValid, isError: !_promoValid);
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (f != null && mounted) setState(() => _paymentProofPath = f.path);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final user = ref.read(authStateProvider).user;
    if (user == null) { setState(() => _submitting = false); return; }
    final api = ref.read(apiServiceProvider);
    final res = await api.submitSubscriptionPayment(user.uid, {
      'planId': _selectedPlan,
      'months': _selectedMonths,
      'amount': _finalPrice,
      'promoCode': _promoCode,
      'paymentProofUrl': _paymentProofPath,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    if (mounted) {
      setState(() => _submitting = false);
      if (res['ok'] == true) {
        AppUtils.showSnack(context, 'تم إرسال طلبك ✓ سيراجعه المدرب قريباً', isSuccess: true);
        context.go(AppRoutes.home);
      } else {
        AppUtils.showSnack(context, 'فشل الإرسال، حاول مرة أخرى', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRenewal ? (isAr ? 'تجديد الاشتراك' : 'Renew Subscription') : (isAr ? 'الاشتراك' : 'Subscribe'),
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Plan selection ─────────────────────
          Text(isAr ? 'اختر الخطة' : 'Choose Plan',
              style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 16)),
          const SizedBox(height: 12),
          ..._plans.entries.map((e) {
            final plan = e.value;
            final isSelected = _selectedPlan == e.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor, width: isSelected ? 2 : 1),
                  color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : theme.cardColor,
                ),
                child: Row(children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? theme.colorScheme.primary : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isAr ? plan['nameAr'] : plan['nameEn'],
                        style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 16,
                            color: isSelected ? theme.colorScheme.primary : null)),
                    const SizedBox(height: 4),
                    Text((plan['features'] as List).join(' • '),
                        style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.grey)),
                  ])),
                  Text('${plan['price']} ${isAr ? "جنيه/شهر" : "EGP/mo"}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo',
                          color: isSelected ? theme.colorScheme.primary : null)),
                ]),
              ),
            );
          }),

          // ── Duration ────────────────────────────
          const SizedBox(height: 8),
          Text(isAr ? 'المدة' : 'Duration', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [1, 3, 6, 12].map((m) => Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMonths = m),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _selectedMonths == m ? theme.colorScheme.primary : theme.dividerColor, width: _selectedMonths == m ? 2 : 1),
                  color: _selectedMonths == m ? theme.colorScheme.primary.withOpacity(0.1) : null,
                ),
                child: Column(children: [
                  Text('$m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, fontFamily: 'Cairo',
                      color: _selectedMonths == m ? theme.colorScheme.primary : null)),
                  Text(isAr ? 'شهر' : 'mo', style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.grey)),
                ]),
              ),
            ),
          ))).toList()),

          // ── Promo code ──────────────────────────
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: AppTextField(controller: _promoCtrl, label: isAr ? 'كود الخصم' : 'Promo Code', prefixIcon: Icons.discount_outlined)),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _checkPromo, child: Text(isAr ? 'تحقق' : 'Check', style: const TextStyle(fontFamily: 'Cairo'))),
          ]),
          if (_promoChecked) Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_promoValid ? '✓ خصم $_discount%' : '✗ كود غير صحيح',
                style: TextStyle(color: _promoValid ? AppColors.ok : AppColors.error, fontFamily: 'Cairo', fontSize: 12)),
          ),

          // ── Payment proof ────────────────────────
          const SizedBox(height: 16),
          Text(isAr ? 'إثبات الدفع' : 'Payment Proof', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickProof,
            icon: const Icon(Icons.upload_file),
            label: Text(_paymentProofPath != null ? (isAr ? 'تم الرفع ✓' : 'Uploaded ✓') : (isAr ? 'رفع الإيصال' : 'Upload Receipt'),
                style: const TextStyle(fontFamily: 'Cairo')),
            style: OutlinedButton.styleFrom(foregroundColor: _paymentProofPath != null ? AppColors.ok : null,
                side: BorderSide(color: _paymentProofPath != null ? AppColors.ok : theme.dividerColor)),
          ),

          // ── Summary ──────────────────────────────
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(isAr ? 'الإجمالي' : 'Total', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${_finalPrice.toStringAsFixed(0)} ${isAr ? "جنيه" : "EGP"}',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
            ]),
            if (_discount > 0) Text('${isAr ? "بعد خصم" : "After"} $_discount%', style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
          ]))),
          const SizedBox(height: 12),
          AppButton(label: isAr ? 'إرسال الطلب' : 'Submit Request', icon: Icons.send, isLoading: _submitting, onPressed: _submit),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}
