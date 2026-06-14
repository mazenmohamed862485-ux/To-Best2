import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../services/db_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isConfigured = false;
  bool _checkingConfig = true;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final db = ref.read(dbServiceProvider);
    final url = await db.getSetting('webAppUrl');
    if (mounted) {
      setState(() {
        _isConfigured = url != null && url.isNotEmpty;
        _checkingConfig = false;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      AppUtils.showSnack(context, 'يرجى إدخال البريد وكلمة المرور', isError: true);
      return;
    }
    if (!AppUtils.isValidEmail(email)) {
      AppUtils.showSnack(context, 'البريد الإلكتروني غير صحيح', isError: true);
      return;
    }

    final ok = await ref.read(authStateProvider.notifier).login(email, pass);
    if (ok && mounted) {
      context.go(AppRoutes.home);
    } else if (mounted) {
      final err = ref.read(authStateProvider).error ?? 'login_failed';
      AppUtils.showSnack(context, _translateError(err), isError: true);
    }
  }

  String _translateError(String err) {
    switch (err) {
      case 'not_configured': return 'يرجى إعداد رابط السيرفر أولاً';
      case 'invalid_credentials': return 'البريد أو كلمة المرور غير صحيحة';
      case 'network': return 'تعذر الاتصال بالسيرفر';
      case 'banned': return 'تم حظر هذا الحساب';
      default: return 'حدث خطأ، حاول مرة أخرى';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // ── Logo ──────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/icons/icon_dark.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(Icons.fitness_center,
                                size: 48, color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TO Best',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      isAr ? 'نظام التدريب والتغذية الاحترافي' : 'Professional Training & Nutrition',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Not configured warning ────────────
              if (!_checkingConfig && !_isConfigured)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warn.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warn.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.warn, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'لم يتم إعداد رابط السيرفر. اضغط على الإعدادات أولاً.'
                              : 'Server URL not configured. Go to Settings first.',
                          style: const TextStyle(
                              color: AppColors.warn, fontSize: 12, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Email ─────────────────────────────
              AppTextField(
                controller: _emailCtrl,
                label: isAr ? 'البريد الإلكتروني' : 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // ── Password ──────────────────────────
              AppTextField(
                controller: _passCtrl,
                label: isAr ? 'كلمة المرور' : 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 8),

              // ── Forgot password ───────────────────
              Align(
                alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: Text(isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),

              // ── Login button ──────────────────────
              AppButton(
                label: isAr ? 'دخول' : 'Login',
                icon: Icons.login,
                isLoading: authState.isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 12),

              // ── Register ──────────────────────────
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.register),
                child: Text(isAr ? 'إنشاء حساب جديد' : 'Create new account'),
              ),
              const SizedBox(height: 12),

              // ── Guest login ───────────────────────
              TextButton.icon(
                onPressed: () => _showGuestDialog(context, isAr),
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(isAr ? 'دخول كضيف' : 'Guest Login'),
              ),

              const SizedBox(height: 32),

              // ── Setup link ────────────────────────
              Center(
                child: TextButton.icon(
                  onPressed: () => _showSetupDialog(context, isAr),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: Text(
                    isAr ? 'إعداد السيرفر' : 'Server Setup',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuestDialog(BuildContext ctx, bool isAr) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'دخول كضيف' : 'Guest Login'),
        content: AppTextField(
          controller: codeCtrl,
          label: isAr ? 'كود الضيف' : 'Guest Code',
          prefixIcon: Icons.vpn_key_outlined,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              final ok = await ref
                  .read(authStateProvider.notifier)
                  .loginAsGuest(codeCtrl.text.trim());
              if (ok && mounted) {
                context.go(AppRoutes.home);
              } else if (mounted) {
                AppUtils.showSnack(
                    context, isAr ? 'كود ضيف غير صحيح' : 'Invalid guest code',
                    isError: true);
              }
            },
            child: Text(isAr ? 'دخول' : 'Login'),
          ),
        ],
      ),
    );
  }

  void _showSetupDialog(BuildContext ctx, bool isAr) {
    final urlCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'إعداد السيرفر' : 'Server Setup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: urlCtrl,
                label: isAr ? 'رابط WebApp' : 'WebApp URL',
                prefixIcon: Icons.link,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: keyCtrl,
                label: isAr ? 'مفتاح الأمان' : 'Secret Key',
                prefixIcon: Icons.vpn_key,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(dbServiceProvider);
              final secure = ref.read(secureStorageProvider);
              final url = urlCtrl.text.trim();
              final key = keyCtrl.text.trim();
              if (url.isNotEmpty) await db.setSetting('webAppUrl', url);
              if (key.isNotEmpty) await secure.setSecretKey(key);
              if (mounted) {
                Navigator.pop(dCtx);
                await _checkConfiguration();
                AppUtils.showSnack(
                    context, isAr ? 'تم الحفظ ✓' : 'Saved ✓',
                    isSuccess: true);
              }
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}
