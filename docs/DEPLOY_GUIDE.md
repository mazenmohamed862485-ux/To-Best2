# TO Best — دليل النشر والبناء

## المتطلبات الأساسية

| الأداة | الإصدار المطلوب |
|--------|----------------|
| Flutter SDK | 3.x (stable) |
| Dart SDK | 3.2+ |
| Android Studio / VS Code | أحدث إصدار |
| Java JDK | 17 |
| Android SDK | API 34+ |

---

## 1. إعداد بيئة التطوير

```bash
# تحقق من إعداد Flutter
flutter doctor -v

# تثبيت الحزم
cd to_best
flutter pub get

# توليد ملفات الترجمة
flutter gen-l10n
```

---

## 2. ملف إعداد السيرفر (مطلوب قبل التشغيل)

أنشئ الملف `android/local.properties`:
```properties
sdk.dir=/path/to/your/android/sdk
flutter.sdk=/path/to/your/flutter/sdk
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
```

---

## 3. إعداد مفاتيح التوقيع (Keystore)

### إنشاء Keystore جديد

```bash
keytool -genkey -v \
  -keystore ~/tobest-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias tobest
```

### إنشاء ملف key.properties

أنشئ الملف `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=tobest
storeFile=/absolute/path/to/tobest-release.jks
```

> ⚠️ **تحذير**: لا تضف `key.properties` أو ملف الـ `.jks` إلى Git!

---

## 4. بناء APK

### Debug APK (للاختبار)
```bash
flutter build apk --debug
# الناتج: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (للتوزيع المباشر)
```bash
flutter build apk --release
# الناتج: build/app/outputs/flutter-apk/app-release.apk
```

### Release APK (حجم مصغّر لكل ABI)
```bash
flutter build apk --release --split-per-abi
# الناتج:
#   app-armeabi-v7a-release.apk   (~15 MB)
#   app-arm64-v8a-release.apk     (~16 MB)
#   app-x86_64-release.apk        (~17 MB)
```

---

## 5. بناء AAB (للنشر على Google Play)

```bash
flutter build appbundle --release
# الناتج: build/app/outputs/bundle/release/app-release.aab
```

---

## 6. تحديد رقم الإصدار

في `pubspec.yaml`:
```yaml
version: 1.0.0+1
# الصيغة: versionName+versionCode
# مثال: 1.2.3+45
```

أو عند البناء:
```bash
flutter build apk --release \
  --build-name=1.2.0 \
  --build-number=45
```

---

## 7. إعداد Codemagic

### المتغيرات المطلوبة في Codemagic Dashboard:

| المتغير | الوصف |
|---------|-------|
| `CM_KEYSTORE` | Keystore مشفر بـ Base64 |
| `CM_KEYSTORE_PASSWORD` | كلمة مرور الـ Keystore |
| `CM_KEY_PASSWORD` | كلمة مرور المفتاح |
| `CM_KEY_ALIAS` | اسم المفتاح (tobest) |

### تحويل Keystore إلى Base64:
```bash
base64 -i tobest-release.jks | pbcopy
# أو على Linux:
base64 tobest-release.jks | xclip -selection clipboard
```

### تشغيل البناء عبر Codemagic:
1. ارفع الكود إلى GitHub/GitLab
2. اربط المستودع بـ Codemagic
3. اختر `android-release` workflow
4. أضف المتغيرات في Credentials Group
5. ابدأ البناء

---

## 8. النشر على Google Play

### الخطوات:
1. سجّل في [Google Play Console](https://play.google.com/console)
2. أنشئ تطبيقاً جديداً بـ Package Name: `com.tobest.app`
3. أكمل معلومات التطبيق (وصف، صور شاشات، أيقونة)
4. ارفع الـ `app-release.aab`
5. ابدأ بـ Internal Testing ثم تدرّج إلى Production

---

## 9. متطلبات Google Play

| المتطلب | المواصفات |
|---------|----------|
| أيقونة التطبيق | 512×512 PNG |
| Feature Graphic | 1024×500 PNG/JPG |
| صور الشاشات | بين 320px و 3840px |
| حجم APK | أقل من 100MB (AAB بدون قيود) |
| minSdk | 21 (Android 5.0) |
| Privacy Policy | مطلوب للنشر |

---

## 10. نسخة Release Checklist

قبل النشر تأكد من:

- [ ] تحديث `version` في `pubspec.yaml`
- [ ] إعداد `key.properties` بصحة
- [ ] اختبار APK على جهاز حقيقي
- [ ] التحقق من اتصال السيرفر (Test Connection)
- [ ] التأكد من RTL للعربية و LTR للإنجليزية
- [ ] اختبار ثيم داكن وفاتح
- [ ] اختبار الوضع Offline
- [ ] مراجعة صلاحيات الأدوار
- [ ] التحقق من عمل المزامنة
- [ ] اختبار تسجيل الدخول والخروج

---

## 11. تقليل حجم APK

```bash
# بناء مع تفعيل تصغير الكود
flutter build apk \
  --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/debug-info
```

في `android/app/build.gradle` (مفعّل مسبقاً):
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
    }
}
```

---

## 12. متغيرات البيئة المطلوبة في التطبيق

هذه الإعدادات تُدخل من داخل التطبيق (شاشة Login > إعداد السيرفر):

| الإعداد | المكان | الغرض |
|---------|-------|-------|
| WebApp URL | SharedPreferences | رابط Google Apps Script |
| Secret Key | SecureStorage | مفتاح التحقق |

> لا توجد متغيرات بيئة في الكود نفسه — كل الإعدادات تُدار من داخل التطبيق.

---

## 13. الترقية والتحديث

```bash
# تحديث Flutter
flutter upgrade

# تحديث حزم المشروع
flutter pub upgrade

# فحص الحزم القديمة
flutter pub outdated

# إعادة بناء من صفر
flutter clean && flutter pub get
```

---

## ملاحظات مهمة

> ⚠️ **لا تضع Keystore أو key.properties في Git** - استخدم `.gitignore`

> 📌 **السيرفر هو Google Apps Script** - تأكد من نشر الـ Script كـ WebApp مع صلاحية "Anyone"

> 🔒 **Secret Key** - احفظه في مكان آمن وشاركه فقط مع المدراء

> 🌐 **Google Play** - يتطلب بريد إلكتروني للتواصل ورسوم تسجيل 25$
