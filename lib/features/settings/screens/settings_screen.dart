import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';
import '../../../services/db_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/sync_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final user = ref.watch(authStateProvider).user;
    final isAr = settings.language == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الإعدادات' : 'Settings',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile ────────────────────────────────
          _buildSection(isAr ? 'الملف الشخصي' : 'Profile', [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: user?.pictureUrl != null
                    ? NetworkImage(user!.pictureUrl!)
                    : null,
                child: user?.pictureUrl == null
                    ? Text(AppUtils.initials(user?.name),
                        style: TextStyle(color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800, fontFamily: 'Cairo'))
                    : null,
              ),
              title: Text(user?.name ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              subtitle: Text(user?.email ?? '',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
              trailing: TextButton(
                onPressed: () => _changeNameDialog(context, isAr),
                child: Text(isAr ? 'تعديل' : 'Edit'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(isAr ? 'تغيير كلمة المرور' : 'Change Password',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _changePasswordDialog(context, isAr),
            ),
          ]),

          // ── Appearance ─────────────────────────────
          _buildSection(isAr ? 'المظهر' : 'Appearance', [
            // Theme
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(isAr ? 'الثيم' : 'Theme',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: DropdownButton<AppThemeType>(
                value: settings.themeType,
                underline: const SizedBox.shrink(),
                items: AppThemeType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_themeLabel(t, isAr),
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (t) {
                  if (t != null) ref.read(appSettingsProvider.notifier).setTheme(t);
                },
              ),
            ),
            // Accent color
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: Text(isAr ? 'لون التمييز' : 'Accent Color',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: _ColorPicker(
                current: settings.accentColor,
                onSelected: (c) =>
                    ref.read(appSettingsProvider.notifier).setAccentColor(c),
              ),
            ),
            // Language
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(isAr ? 'اللغة' : 'Language',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: DropdownButton<String>(
                value: settings.language,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'ar', child: Text('عربي', style: TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontFamily: 'Cairo'))),
                ],
                onChanged: (v) {
                  if (v != null) ref.read(appSettingsProvider.notifier).setLanguage(v);
                },
              ),
            ),
            // Hand mode
            ListTile(
              leading: const Icon(Icons.back_hand_outlined),
              title: Text(isAr ? 'وضع اليد' : 'Hand Mode',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: DropdownButton<String>(
                value: settings.handMode,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: 'right', child: Text(isAr ? 'يمين' : 'Right', style: const TextStyle(fontFamily: 'Cairo'))),
                  DropdownMenuItem(value: 'left', child: Text(isAr ? 'يسار' : 'Left', style: const TextStyle(fontFamily: 'Cairo'))),
                ],
                onChanged: (v) {
                  if (v != null) ref.read(appSettingsProvider.notifier).setHandMode(v);
                },
              ),
            ),
          ]),

          // ── Workout ────────────────────────────────
          _buildSection(isAr ? 'التمرين' : 'Workout', [
            ListTile(
              leading: const Icon(Icons.timer),
              title: Text(isAr ? 'مدة الراحة (ثواني)' : 'Rest Duration (sec)',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: DropdownButton<int>(
                value: settings.restTimerDuration,
                underline: const SizedBox.shrink(),
                items: [60, 90, 120, 150, 180, 240, 300]
                    .map((v) => DropdownMenuItem(value: v, child: Text('${v ~/ 60}:${(v % 60).toString().padLeft(2, '0')}')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) ref.read(appSettingsProvider.notifier).setRestTimerDuration(v);
                },
              ),
            ),
            _SwitchTile(
              icon: Icons.history,
              title: isAr ? 'إظهار القيم السابقة' : 'Show Previous Values',
              value: settings.showOldValues,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .setBool(AppConstants.keyShowOldValues, v),
            ),
            _SwitchTile(
              icon: Icons.bar_chart,
              title: isAr ? 'حساب 1RM (Epley)' : 'Show 1RM (Epley)',
              value: settings.showEpley,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .setBool(AppConstants.keyShowEpley, v),
            ),
            _SwitchTile(
              icon: Icons.speed,
              title: isAr ? 'إظهار RPE' : 'Show RPE',
              value: settings.showRPE,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .setBool(AppConstants.keyShowRPE, v),
            ),
            _SwitchTile(
              icon: Icons.stacked_bar_chart,
              title: isAr ? 'إظهار الحجم' : 'Show Volume',
              value: settings.showVolume,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .setBool(AppConstants.keyShowVolume, v),
            ),
            _SwitchTile(
              icon: Icons.brightness_high,
              title: isAr ? 'منع إيقاف الشاشة' : 'Keep Screen On',
              value: settings.wakeLock,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .setBool(AppConstants.keyWakeLock, v),
            ),
          ]),

          // ── Notifications ──────────────────────────
          _buildSection(isAr ? 'الإشعارات' : 'Notifications', [
            _SwitchTile(
              icon: Icons.notifications_outlined,
              title: isAr ? 'إشعارات' : 'Notifications',
              value: settings.notifications,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .setBool(AppConstants.keyNotifications, v),
            ),
            _SwitchTile(
              icon: Icons.emoji_emotions_outlined,
              title: isAr ? 'رسائل تحفيزية' : 'Motivational Messages',
              value: settings.motivationalMsgs,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .setBool(AppConstants.keyMotivationalMsgs, v),
            ),
          ]),

          // ── Server ─────────────────────────────────
          _buildSection(isAr ? 'إعداد السيرفر' : 'Server Setup', [
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(isAr ? 'رابط WebApp' : 'WebApp URL',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _editServerDialog(context, isAr),
            ),
            ListTile(
              leading: const Icon(Icons.wifi_find),
              title: Text(isAr ? 'اختبار الاتصال' : 'Test Connection',
                  style: const TextStyle(fontFamily: 'Cairo')),
              onTap: () => _testConnection(context, isAr),
            ),
          ]),

          // ── Sync ───────────────────────────────────
          _buildSection(isAr ? 'المزامنة' : 'Sync', [
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(isAr ? 'مزامنة الآن' : 'Sync Now',
                  style: const TextStyle(fontFamily: 'Cairo')),
              trailing: _syncing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _syncing ? null : () => _syncNow(context, isAr),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(isAr ? 'استعادة من السيرفر' : 'Restore from Server',
                  style: const TextStyle(fontFamily: 'Cairo')),
              onTap: () => _pullFromServer(context, isAr),
            ),
          ]),

          // ── Danger zone ────────────────────────────
          _buildSection(isAr ? 'تسجيل الخروج' : 'Account', [
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(isAr ? 'تسجيل الخروج' : 'Sign Out',
                  style: const TextStyle(color: AppColors.error, fontFamily: 'Cairo')),
              onTap: () => _confirmLogout(context, isAr),
            ),
          ]),

          // ── Version ────────────────────────────────
          if (_appVersion != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'TO Best v$_appVersion',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(title,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'Cairo', letterSpacing: 0.5)),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  String _themeLabel(AppThemeType t, bool isAr) {
    switch (t) {
      case AppThemeType.dark: return isAr ? 'داكن' : 'Dark';
      case AppThemeType.light: return isAr ? 'فاتح' : 'Light';
      case AppThemeType.luxury: return isAr ? 'فاخر' : 'Luxury';
      case AppThemeType.sports: return isAr ? 'رياضي' : 'Sports';
    }
  }

  Future<void> _testConnection(BuildContext ctx, bool isAr) async {
    final api = ref.read(apiServiceProvider);
    final ok = await api.testConnection();
    if (mounted) {
      AppUtils.showSnack(
        ctx,
        ok
            ? (isAr ? 'تم الاتصال بنجاح ✓' : 'Connected successfully ✓')
            : (isAr ? 'فشل الاتصال' : 'Connection failed'),
        isSuccess: ok,
        isError: !ok,
      );
    }
  }

  Future<void> _syncNow(BuildContext ctx, bool isAr) async {
    setState(() => _syncing = true);
    final sync = ref.read(syncServiceProvider);
    final failed = await sync.flushQueue();
    if (mounted) {
      setState(() => _syncing = false);
      AppUtils.showSnack(
        ctx,
        failed == 0
            ? (isAr ? 'تمت المزامنة ✓' : 'Sync done ✓')
            : (isAr ? 'بعض البيانات لم تُزامن ($failed)' : 'Some items failed ($failed)'),
        isSuccess: failed == 0,
        isError: failed > 0,
      );
    }
  }

  Future<void> _pullFromServer(BuildContext ctx, bool isAr) async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    final sync = ref.read(syncServiceProvider);
    final ok = await sync.pullFromServer(user.uid);
    if (mounted) {
      AppUtils.showSnack(ctx,
          ok ? (isAr ? 'تمت الاستعادة ✓' : 'Restored ✓') : (isAr ? 'فشلت الاستعادة' : 'Restore failed'),
          isSuccess: ok, isError: !ok);
    }
  }

  void _changeNameDialog(BuildContext ctx, bool isAr) {
    final user = ref.read(authStateProvider).user;
    final ctrl = TextEditingController(text: user?.name ?? '');
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'تغيير الاسم' : 'Change Name'),
        content: AppTextField(controller: ctrl, label: isAr ? 'الاسم' : 'Name', prefixIcon: Icons.person),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              final api = ref.read(apiServiceProvider);
              if (user != null) {
                await api.adminUpdateUser(user.uid, {'name': ctrl.text.trim()});
                await ref.read(authStateProvider.notifier).refreshUser();
              }
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _changePasswordDialog(BuildContext ctx, bool isAr) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'تغيير كلمة المرور' : 'Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: oldCtrl, label: isAr ? 'القديمة' : 'Current', prefixIcon: Icons.lock, obscureText: true),
              const SizedBox(height: 10),
              AppTextField(controller: newCtrl, label: isAr ? 'الجديدة' : 'New', prefixIcon: Icons.lock_open, obscureText: true),
              const SizedBox(height: 10),
              AppTextField(controller: confCtrl, label: isAr ? 'تأكيد' : 'Confirm', prefixIcon: Icons.check, obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confCtrl.text) {
                AppUtils.showSnack(ctx, isAr ? 'كلمتا المرور لا تتطابقان' : 'Passwords do not match', isError: true);
                return;
              }
              Navigator.pop(dCtx);
              final api = ref.read(apiServiceProvider);
              final user = ref.read(authStateProvider).user;
              if (user != null) {
                final res = await api.changePassword(user.uid, oldCtrl.text, newCtrl.text);
                if (mounted) {
                  AppUtils.showSnack(ctx,
                      res['ok'] == true
                          ? (isAr ? 'تم تغيير كلمة المرور ✓' : 'Password changed ✓')
                          : (isAr ? 'فشل التغيير' : 'Failed'),
                      isSuccess: res['ok'] == true, isError: res['ok'] != true);
                }
              }
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _editServerDialog(BuildContext ctx, bool isAr) async {
    final db = ref.read(dbServiceProvider);
    final secure = ref.read(secureStorageProvider);
    final currentUrl = await db.getSetting(AppConstants.keyWebAppUrl) ?? '';
    final urlCtrl = TextEditingController(text: currentUrl);
    final keyCtrl = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'إعداد السيرفر' : 'Server Setup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: urlCtrl, label: 'WebApp URL', prefixIcon: Icons.link, keyboardType: TextInputType.url),
              const SizedBox(height: 10),
              AppTextField(controller: keyCtrl, label: isAr ? 'مفتاح الأمان (اتركه فارغاً للإبقاء)' : 'Secret Key (leave empty to keep)',
                  prefixIcon: Icons.vpn_key, obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (urlCtrl.text.trim().isNotEmpty) {
                await db.setSetting(AppConstants.keyWebAppUrl, urlCtrl.text.trim());
              }
              if (keyCtrl.text.trim().isNotEmpty) {
                await secure.setSecretKey(keyCtrl.text.trim());
              }
              if (mounted) {
                Navigator.pop(dCtx);
                AppUtils.showSnack(ctx, isAr ? 'تم الحفظ ✓' : 'Saved ✓', isSuccess: true);
              }
            },
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext ctx, bool isAr) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(isAr ? 'تسجيل الخروج؟' : 'Sign Out?'),
        content: Text(isAr
            ? 'سيتم تسجيل خروجك من الحساب.'
            : 'You will be signed out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAr ? 'خروج' : 'Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onSelected;

  const _ColorPicker({required this.current, required this.onSelected});

  static const _colors = [
    Color(0xFF7C6EFF),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFD4AF37),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: current,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
      ),
    );
  }

  void _showPicker(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('اختر اللون', style: TextStyle(fontFamily: 'Cairo')),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((c) => GestureDetector(
            onTap: () {
              onSelected(c);
              Navigator.pop(dCtx);
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(18),
                border: c == current
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}
