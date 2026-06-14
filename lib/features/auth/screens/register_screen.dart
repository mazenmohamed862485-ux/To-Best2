import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _confCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim(); final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim(); final conf = _confCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || pass.isEmpty) { AppUtils.showSnack(context, 'يرجى إكمال جميع الحقول', isError: true); return; }
    if (!AppUtils.isValidEmail(email)) { AppUtils.showSnack(context, 'البريد غير صحيح', isError: true); return; }
    if (pass != conf) { AppUtils.showSnack(context, 'كلمتا المرور لا تتطابقان', isError: true); return; }
    if (!AppUtils.isValidPassword(pass)) { AppUtils.showSnack(context, 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل وأرقام وحروف', isError: true); return; }
    final ok = await ref.read(authStateProvider.notifier).register({'name': name, 'email': email, 'password': pass, 'phone': _phoneCtrl.text.trim()});
    if (ok && mounted) { context.go(AppRoutes.pending); }
    else if (mounted) { AppUtils.showSnack(context, ref.read(authStateProvider).error ?? 'فشل التسجيل', isError: true); }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'حساب جديد' : 'New Account', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppTextField(controller: _nameCtrl, label: isAr ? 'الاسم الكامل' : 'Full Name', prefixIcon: Icons.person, textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        AppTextField(controller: _emailCtrl, label: isAr ? 'البريد الإلكتروني' : 'Email', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        AppTextField(controller: _phoneCtrl, label: isAr ? 'رقم الهاتف' : 'Phone', prefixIcon: Icons.phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        AppTextField(controller: _passCtrl, label: isAr ? 'كلمة المرور' : 'Password', prefixIcon: Icons.lock, obscureText: _obscure, textInputAction: TextInputAction.next, suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure))),
        const SizedBox(height: 12),
        AppTextField(controller: _confCtrl, label: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password', prefixIcon: Icons.lock_outline, obscureText: _obscure, textInputAction: TextInputAction.done, onSubmitted: (_) => _register()),
        const SizedBox(height: 24),
        AppButton(label: isAr ? 'إنشاء حساب' : 'Create Account', icon: Icons.person_add, isLoading: authState.isLoading, onPressed: _register),
        const SizedBox(height: 12),
        TextButton(onPressed: () => context.pop(), child: Text(isAr ? 'لديك حساب؟ سجل دخولك' : 'Already have account? Login')),
      ]))),
    );
  }
}
