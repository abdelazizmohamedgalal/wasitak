
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://xjmvzigoptweolpdsfhp.supabase.co';
const supabaseKey =
    'sb_publishable_YePsC3nUCuCKqA0Sa997Qg_IJ0eEUVW';

const green = Color(0xFF123D32);
const green2 = Color(0xFF1B6651);
const gold = Color(0xFFC7A45B);
const ivory = Color(0xFFF7F5EF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(const WasitakApp());
}

final db = Supabase.instance.client;

class WasitakApp extends StatelessWidget {
  const WasitakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وسيطك',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: ivory,
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: gold,
          foregroundColor: green,
        ),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedCategory = 0;
  String search = '';
  List<Map<String, dynamic>> ads = [];
  bool loading = true;
  bool saving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      final response = await db
          .from('listings')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        ads = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = 'تعذر تحميل الإعلانات. تأكد من اتصال الإنترنت.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAds = ads.where((ad) {
      final category = ad['category'] == 'housing' ? 'سكن' : 'وظائف';
      final matchesCategory = selectedCategory == 0 ||
          (selectedCategory == 1 && category == 'سكن') ||
          (selectedCategory == 2 && category == 'وظائف');

      final title = (ad['title'] ?? '').toString();
      final details = (ad['description'] ?? '').toString();
      final matchesSearch =
          title.contains(search) || details.contains(search);

      return matchesCategory && matchesSearch;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ivory,
        appBar: AppBar(
          backgroundColor: green,
          foregroundColor: Colors.white,
          title: const Text(
            'وسيطك',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          actions: [
            IconButton(onPressed: _showAdminLogin, icon: const Icon(Icons.admin_panel_settings_outlined), tooltip: 'لوحة الإدارة'),
            IconButton(onPressed: _loadAds, icon: const Icon(Icons.refresh), tooltip: 'تحديث الإعلانات'),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAds,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [green, green2],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: green.withOpacity(0.16),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وسيطك | فرصتك أقرب',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'دليلك للسكن والشغل في بورسعيد',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) =>
                    setState(() => search = value.trim()),
                decoration: InputDecoration(
                  hintText: 'دور على شقة أو وظيفة...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _categoryButton('الكل', 0),
                  const SizedBox(width: 8),
                  _categoryButton('سكن', 1),
                  const SizedBox(width: 8),
                  _categoryButton('وظائف', 2),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'أحدث الإعلانات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${filteredAds.length} إعلانات',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (loadError != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(loadError!),
                      TextButton(
                        onPressed: _loadAds,
                        child: const Text('حاول مرة أخرى'),
                      ),
                    ],
                  ),
                )
              else if (filteredAds.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('مفيش إعلانات منشورة حاليًا'),
                  ),
                )
              else
                ...filteredAds.map(_adCard),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: green,
          foregroundColor: Colors.white,
          onPressed: saving ? null : _showAddAdDialog,
          icon: const Icon(Icons.add),
          label: const Text('أضف إعلان'),
        ),
      ),
    );
  }

  Widget _categoryButton(String label, int index) {
    final selected = selectedCategory == index;

    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: selected ? green : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        onPressed: () => setState(() => selectedCategory = index),
        child: Text(label),
      ),
    );
  }

  Widget _adCard(Map<String, dynamic> ad) {
    final isJob = ad['category'] == 'jobs';
    final title = (ad['title'] ?? '').toString();
    final description = (ad['description'] ?? '').toString();
    final location = (ad['location'] ?? 'بورسعيد').toString();
    final price = (ad['price_text'] ?? '').toString();

    final images = (ad['image_urls'] as List<dynamic>? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final phone = (ad['contact_phone'] ?? '').toString();
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E0D5)),
      ),
      child: InkWell(onTap: () => _showAdDetails(ad), borderRadius: BorderRadius.circular(20), child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (images.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(images.first, height: 155, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          if (images.isNotEmpty) const SizedBox(height: 10),
          Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFE8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isJob ? Icons.work_outline : Icons.home_outlined,
                color: green,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$location • $description',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    price.isEmpty ? 'السعر عند التواصل' : price,
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (phone.isNotEmpty) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _callPhone(phone), icon: const Icon(Icons.phone), label: Text(phone))),
        ]),
      ),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) { await launchUrl(uri); }
    else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الاتصال على الجهاز')));
  }

  void _showAdDetails(Map<String, dynamic> ad) {
    final images = (ad['image_urls'] as List<dynamic>? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final phone = (ad['contact_phone'] ?? '').toString();
    showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: Text((ad['title'] ?? '').toString()),
      content: SizedBox(width: 360, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        for (final url in images) Padding(padding: const EdgeInsets.only(bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
        Text((ad['description'] ?? '').toString()), const SizedBox(height: 8), Text('المكان: ${(ad['location'] ?? 'بورسعيد').toString()}'), Text('السعر: ${(ad['price_text'] ?? 'عند التواصل').toString()}'),
        if (phone.isNotEmpty) TextButton.icon(onPressed: () => _callPhone(phone), icon: const Icon(Icons.phone), label: Text('اتصل: $phone')),
      ]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
    )));
  }

  Future<void> _showAdminLogin() async {
    final email = TextEditingController(text: 'abdelazizmohamedgalal@gmail.com');
    final password = TextEditingController();
    await showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('دخول الإدارة'), content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), TextButton(onPressed: () async {
        try {
          final response = await db.auth.signUp(email: email.text.trim(), password: password.text);
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.session == null ? 'تم إنشاء الطلب. لو طلب Supabase تأكيد البريد، افتح رسالة التأكيد ثم سجّل الدخول.' : 'تم إنشاء الحساب. يلزم تفعيله كمدير من قاعدة البيانات.')));
        } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الحساب: $e'))); }
      }, child: const Text('إنشاء حساب المدير')), FilledButton(onPressed: () async {
        try {
          final response = await db.auth.signInWithPassword(email: email.text.trim(), password: password.text);
          if (response.user == null) throw Exception('تعذر تسجيل الدخول');
          final admin = await db.from('admin_users').select('user_id').eq('user_id', response.user!.id).maybeSingle();
          if (admin == null) { await db.auth.signOut(); throw Exception('الحساب غير مضاف كمدير في قاعدة البيانات بعد.'); }
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) await _showAdminDashboard();
        } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل دخول الإدارة: $e'))); }
      }, child: const Text('دخول'))],
    )));
    email.dispose(); password.dispose();
  }

  Future<void> _showAdminDashboard() async {
    try {
      final rows = await db.from('listings').select().order('created_at', ascending: false);
      if (!mounted) return;
      await showDialog(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
        title: const Text('لوحة إدارة الإعلانات'), content: SizedBox(width: 480, height: 480, child: ListView(children: [
          for (final item in List<Map<String,dynamic>>.from(rows)) Card(child: ListTile(title: Text((item['title'] ?? '').toString()), subtitle: Text('الحالة: ${item['status']} • ${item['category'] == 'housing' ? 'سكن' : 'وظائف'}'), onTap: () => _showAdDetails(item), trailing: item['status'] == 'pending' ? Wrap(children: [IconButton(tooltip: 'قبول', icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () async { await db.from('listings').update({'status':'published'}).eq('id', item['id']); if (ctx.mounted) Navigator.pop(ctx); await _loadAds(); await _showAdminDashboard(); }), IconButton(tooltip: 'رفض', icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () async { await db.from('listings').update({'status':'rejected'}).eq('id', item['id']); if (ctx.mounted) Navigator.pop(ctx); await _loadAds(); await _showAdminDashboard(); })]) : null)),
        ])), actions: [TextButton(onPressed: () async { await db.auth.signOut(); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('خروج الإدارة')), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      )));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر فتح لوحة الإدارة: $e'))); }
  }

  Future<List<String>> _uploadImages(List<XFile> files, String userId) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
      final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';
      await db.storage.from('listing-images').upload(path, File(file.path), fileOptions: const FileOptions(upsert: false));
      urls.add(db.storage.from('listing-images').getPublicUrl(path));
    }
    return urls;
  }

  Future<void> _showAddAdDialog() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final priceController = TextEditingController();
    final phoneController = TextEditingController();
    final pickedImages = <XFile>[];
    final picker = ImagePicker();
    String category = 'سكن';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          title: const Text('إضافة إعلان جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الإعلان',
                  ),
                ),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'التفاصيل',
                  ),
                ),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر أو الراتب')),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الموبايل للتواصل')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () async { final files = await picker.pickMultiImage(imageQuality: 82); if (files.isNotEmpty) refreshDialog(() { pickedImages..clear()..addAll(files.take(5)); }); }, icon: const Icon(Icons.photo_library_outlined), label: Text(pickedImages.isEmpty ? 'اختيار صور (حتى 5)' : 'تم اختيار ${pickedImages.length} صور')),
                if (pickedImages.isNotEmpty) Text(pickedImages.map((x) => x.name).join('، '), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'القسم'),
                  items: const [
                    DropdownMenuItem(value: 'سكن', child: Text('سكن')),
                    DropdownMenuItem(value: 'وظائف', child: Text('وظائف')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      refreshDialog(() => category = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty || saving) return;

                setState(() => saving = true);
                Navigator.pop(dialogContext);

                try {
                  var user = db.auth.currentUser;

                  if (user == null) {
                    final authResponse =
                        await db.auth.signInAnonymously();
                    user = authResponse.user;
                  }

                  if (user == null) {
                    throw Exception('تعذر إنشاء جلسة مستخدم');
                  }

                  await db.from('listings').insert({
                    'title': title,
                    'description': detailsController.text.trim(),
                    'category': category == 'سكن' ? 'housing' : 'jobs',
                    'price_text': priceController.text.trim().isEmpty
                        ? 'السعر عند التواصل'
                        : priceController.text.trim(),
                    'location': 'بورسعيد',
                    'contact_phone': phoneController.text.trim(),
                    'image_urls': await _uploadImages(pickedImages.take(5).toList(), user.id),
                    'user_id': user.id,
                    'status': 'pending',
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم إرسال إعلانك للمراجعة بنجاح',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('تعذر حفظ الإعلان: $e'),
                    ),
                  );
                } finally {
                  titleController.dispose();
                  detailsController.dispose();
                  priceController.dispose();
                  phoneController.dispose();

                  if (mounted) setState(() => saving = false);
                }
              },
              child: const Text('إرسال للمراجعة'),
            ),
          ],
        ),
      ),
    );
  }
}
