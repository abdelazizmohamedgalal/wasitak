
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://xjmvzigoptweolpdsfhp.supabase.co';
const supabaseKey =
    'sb_publishable_YePsC3nUCuCKqA0Sa997Qg_IJ0eEUVW';

const green = Color(0xFF16834A);

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
        backgroundColor: const Color(0xFFF6F8F6),
        appBar: AppBar(
          backgroundColor: green,
          foregroundColor: Colors.white,
          title: const Text(
            'وسيطك',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          actions: [
            IconButton(
              onPressed: _loadAds,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث الإعلانات',
            ),
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
                  color: green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كل اللي بتدور عليه في مكان واحد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'سكن ووظائف في بورسعيد',
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
                    borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5EAE6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F4E9),
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
      ),
    );
  }

  Future<void> _showAddAdDialog() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final priceController = TextEditingController();
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
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر أو الراتب',
                  ),
                ),
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
