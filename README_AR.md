# وسيطك — نسخة البداية (Flutter + Supabase)

نسخة أولية لتطبيق إعلانات مبوبة للإسكان والوظائف في بورسعيد، بواجهة عربية خضراء وبيضاء.

## الموجود حاليًا
- واجهة عربية RTL.
- قسم الإسكان وقسم الوظائف.
- بحث في العناوين والوصف والمنطقة.
- بطاقات للإعلانات التجريبية.
- نموذج إضافة إعلان.
- اتصال اختياري بقاعدة بيانات Supabase.
- الإعلانات الجديدة تُرسل بحالة `pending` للمراجعة ولا تظهر للعامة حتى نشرها.

## المتطلبات
1. كمبيوتر Windows أو macOS أو Linux.
2. تثبيت Flutter SDK: https://docs.flutter.dev/get-started/install
3. تثبيت Android Studio (لأدوات أندرويد): https://developer.android.com/studio
4. محرر مثل VS Code: https://code.visualstudio.com/
5. حساب Supabase: https://supabase.com/

## تشغيل نسخة العرض بدون قاعدة بيانات
من داخل مجلد المشروع:
```bash
flutter pub get
flutter run
```
سيعمل التطبيق في وضع تجريبي ويعرض إعلانين نموذجيين. نموذج الإضافة لا يحفظ البيانات في الوضع التجريبي.

## ربط Supabase
1. أنشئ مشروعًا جديدًا في Supabase.
2. افتح SQL Editor.
3. انسخ محتوى `supabase/schema.sql` وشغّله.
4. من إعدادات المشروع انسخ Project URL وPublishable/anon key.
5. شغّل التطبيق هكذا (استبدل القيم بقيم مشروعك):
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```
على Windows PowerShell اكتب الأمر في سطر واحد:
```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

**لا تضع أبدًا `service_role` key داخل التطبيق.** استخدم المفتاح العام فقط. سياسات RLS في SQL تسمح بقراءة الإعلانات المنشورة وإرسال إعلانات معلقة للمراجعة. هذه حماية أولية فقط؛ قبل الإطلاق العام أضف تسجيل دخول، حدودًا لمكافحة السبام، ومسار إدارة آمنًا لنشر الإعلانات.

## بناء نسخة Android
بعد إعداد Android SDK:
```bash
flutter build apk --release
```
ملف APK يكون عادة في:
`build/app/outputs/flutter-apk/app-release.apk`

## iPhone / iOS
بناء نسخة iOS يحتاج جهاز Mac عليه Xcode. بعد إعداد التوقيع وحساب Apple:
```bash
flutter build ios --release
```
ثم يتم أرشفة التطبيق ورفعه عبر Xcode/Transporter وفق متطلبات Apple. لا يمكن بناء أو توقيع نسخة iOS نهائية من Windows فقط.

## قبل النشر العام
هذه نسخة MVP أولية وليست منتجًا جاهزًا للإطلاق التجاري. يلزم إكمال:
- تسجيل المستخدمين واستعادة كلمة المرور.
- رفع صور حقيقي باستخدام Supabase Storage.
- لوحة تحكم إدارية آمنة لمراجعة الإعلانات.
- سياسة خصوصية وشروط استخدام وحذف الحساب.
- الإبلاغ عن الاحتيال والإعلانات الوهمية.
- اختبار على أجهزة حقيقية، واختبار سياسات المتاجر.
- حماية إضافية ضد الرسائل المزعجة والطلبات الآلية.
