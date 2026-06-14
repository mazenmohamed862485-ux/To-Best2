import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _loading = false;
  bool _codeSent = false;

  @override
  void dispose() { _emailCtrl.dispose(); _codeCtrl.dispose(); _newPassCtrl.dispose(); super.dispose(); }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (!AppUtils.isValidEmail(email)) { AppUtils.showSnack(context, 'البريد غير صحيح', isError: true); return; }
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    final res = await api.forgotPassword(email);
    if (mounted) {
      setState(() { _loading = false; if (res['ok'] == true) _codeSent = true; });
      AppUtils.showSnack(context, res['ok'] == true ? 'تم إرسال الكود ✓' : 'البريد غير موجود', isSuccess: res['ok'] == true, isError: res['ok'] != true);
    }
  }

  Future<void> _resetPassword() async {
    final pass = _newPassCtrl.text.trim();
    if (_codeCtrl.text.isEmpty || pass.length < 8) { AppUtils.showSnack(context, 'يرجى إدخال الكود وكلمة المرور الجديدة (8 أحرف على الأقل)', isError: true); return; }
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    final res = await api.resetPassword(_emailCtrl.text.trim(), _codeCtrl.text.trim(), pass);
    if (mounted) {
      setState(() => _loading = false);
      if (res['ok'] == true) { AppUtils.showSnack(context, 'تم تغيير كلمة المرور ✓', isSuccess: true); context.pop(); }
      else { AppUtils.showSnack(context, 'كود غير صحيح أو منتهي الصلاحية', isError: true); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'نسيت كلمة المرور' : 'Forgot Password', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700))),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(isAr ? 'أدخل بريدك الإلكتروني وسنرسل لك كود لإعادة تعيين كلمة المرور.' : 'Enter your email and we\'ll send a reset code.', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
        const SizedBox(height: 20),
        AppTextField(controller: _emailCtrl, label: isAr ? 'البريد الإلكتروني' : 'Email', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress, readOnly: _codeSent),
        const SizedBox(height: 12),
        AppButton(label: isAr ? 'إرسال الكود' : 'Send Code', icon: Icons.send, isLoading: _loading && !_codeSent, onPressed: _codeSent ? null : _sendCode),
        if (_codeSent) ...[
          const SizedBox(height: 20),
          AppTextField(controller: _codeCtrl, label: isAr ? 'الكود المرسل' : 'Reset Code', prefixIcon: Icons.pin),
          const SizedBox(height: 12),
          AppTextField(controller: _newPassCtrl, label: isAr ? 'كلمة المرور الجديدة' : 'New Password', prefixIcon: Icons.lock, obscureText: true),
          const SizedBox(height: 12),
          AppButton(label: isAr ? 'تغيير كلمة المرور' : 'Reset Password', icon: Icons.check, isLoading: _loading && _codeSent, onPressed: _resetPassword),
        ],
      ]))),
    );
  }
}
