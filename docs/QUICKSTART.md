# TO Best — دليل التشغيل السريع

## ⚡ من الصفر إلى التشغيل في 5 دقائق

---

## الخطوة 1: المتطلبات

```bash
# تحقق من Flutter
flutter --version   # يجب أن يكون 3.x+
dart --version      # يجب أن يكون 3.2+

# تحقق من Android
flutter doctor
```

---

## الخطوة 2: استنساخ أو فتح المشروع

```bash
cd to_best/
```

---

## الخطوة 3: تثبيت الحزم

```bash
flutter pub get
```

---

## الخطوة 4: توليد ملفات الترجمة

```bash
flutter gen-l10n
```

---

## الخطوة 5: التشغيل

```bash
# تشغيل على الجهاز المتصل
flutter run

# تشغيل على محاكي Android
flutter run -d android

# تشغيل في وضع release
flutter run --release
```

---

## الخطوة 6: إعداد السيرفر (مطلوب!)

بعد فتح التطبيق:
1. في شاشة Login اضغط **"إعداد السيرفر"**
2. أدخل **رابط WebApp** الخاص بـ Google Apps Script
3. أدخل **مفتاح الأمان** (Secret Key)
4. اضغط **حفظ**
5. اضغط **"اختبار الاتصال"** للتأكد

---

## هيكل المشروع بسرعة

```
lib/
├── main.dart           ← نقطة البداية
├── app.dart            ← MaterialApp + Routing + Theming
├── core/               ← ثوابت، ثيمات، ترجمات، دوال
├── models/             ← نماذج البيانات
├── services/           ← API, SQLite, Sync, SecureStorage
├── providers/          ← Riverpod (Auth, Settings)
├── data/               ← قاعدة التمارين والأطعمة
├── features/           ← شاشات ومنطق كل قسم
└── widgets/            ← مكونات مشتركة
```

---

## أوامر مفيدة

```bash
# بناء APK تجريبي
flutter build apk --debug

# بناء APK للإصدار
flutter build apk --release

# بناء AAB للـ Google Play
flutter build appbundle --release

# تحليل الكود
flutter analyze

# تشغيل الاختبارات
flutter test

# تنظيف وإعادة البناء
flutter clean && flutter pub get

# فحص الأجهزة المتصلة
flutter devices

# عرض الـ Logs
flutter run --verbose
```

---

## إضافة ميزة جديدة

1. **نموذج البيانات** ← `lib/models/`
2. **المستودع** ← `lib/services/` أو `lib/features/xxx/providers/`
3. **Provider** ← `lib/features/xxx/providers/xxx_provider.dart`
4. **الشاشة** ← `lib/features/xxx/screens/xxx_screen.dart`
5. **المسار** ← `lib/core/constants/routes.dart`
6. **الترجمات** ← `lib/core/localization/arb/app_ar.arb` + `app_en.arb`

---

## هيكل Provider (نموذج)

```dart
// State
class MyState {
  final bool isLoading;
  final List<Item> items;
  const MyState({this.isLoading = false, this.items = const []});
}

// Notifier
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(const MyState());
  
  Future<void> load() async {
    state = MyState(isLoading: true);
    final items = await _fetch();
    state = MyState(items: items);
  }
}

// Provider
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier()..load();
});

// في الشاشة
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return state.isLoading
        ? CircularProgressIndicator()
        : ListView.builder(...);
  }
}
```

---

## الأخطاء الشائعة والحلول

| الخطأ | الحل |
|-------|------|
| `flutter gen-l10n` يفشل | تأكد من وجود `l10n.yaml` وملفات `.arb` |
| `Null check operator` | تأكد من null-safety في النماذج |
| عدم اتصال بالسيرفر | تحقق من WebApp URL و Secret Key |
| RTL لا يعمل | تأكد من `Directionality` في `app.dart` |
| الصور لا تُحمَّل | تأكد من `INTERNET` في AndroidManifest.xml |
| SQLite errors | `flutter clean && flutter pub get` |

---

## المتغيرات الحساسة (لا تضعها في الكود!)

| المتغير | المكان الصحيح |
|---------|-------------|
| WebApp URL | داخل التطبيق (SharedPreferences) |
| Secret Key | داخل التطبيق (SecureStorage) |
| Keystore | `android/key.properties` (خارج Git) |

---

## ملف `.gitignore` المقترح

```gitignore
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/

# Android secrets
android/key.properties
android/app/*.jks
android/app/*.keystore

# Local settings
local.properties
*.env

# IDE
.idea/
.vscode/
*.iml
```

---

## تحديث الحزم

```bash
# عرض الحزم القديمة
flutter pub outdated

# تحديث جميع الحزم
flutter pub upgrade

# تحديث حزمة محددة
flutter pub upgrade flutter_riverpod
```

---

## إضافة حقل ترجمة جديد

في `lib/core/localization/arb/app_ar.arb`:
```json
"myNewKey": "النص بالعربي",
```

في `lib/core/localization/arb/app_en.arb`:
```json
"myNewKey": "Text in English",
```

ثم:
```bash
flutter gen-l10n
```

---

## الدعم والتواصل

- 📁 **التوثيق الشامل**: `docs/PROJECT_DOCS.md`
- 🚀 **دليل النشر**: `docs/DEPLOY_GUIDE.md`
- ⚙️ **Codemagic**: `codemagic.yaml`
