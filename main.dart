import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSupabaseConfig =
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  if (hasSupabaseConfig) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(WasitakApp(onlineMode: hasSupabaseConfig));
}

class WasitakApp extends StatelessWidget {
  const WasitakApp({super.key, required this.onlineMode});
  final bool onlineMode;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF176B55);
    return MaterialApp(
      title: 'وسيطك',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF7F9F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: green,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7E2)),
          ),
        ),
      ),
      home: HomeScreen(onlineMode: onlineMode),
    );
  }
}

enum ListingCategory { housing, jobs }

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.area,
    required this.price,
    required this.contactPhone,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final ListingCategory category;
  final String area;
  final int? price;
  final String contactPhone;
  final String? imageUrl;

  factory Listing.fromMap(Map<String, dynamic> map) => Listing(
        id: map['id'].toString(),
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        category: map['category'] == 'jobs'
            ? ListingCategory.jobs
            : ListingCategory.housing,
        area: map['area'] as String? ?? 'بورسعيد',
        price: map['price'] is num ? (map['price'] as num).toInt() : null,
        contactPhone: map['contact_phone'] as String? ?? '',
        imageUrl: map['image_url'] as String?,
      );
}

const demoListings = <Listing>[
  Listing(
    id: 'demo-1',
    title: 'شقة للإيجار في حي العرب',
    description: 'شقة سكنية — مثال تجريبي، عدّل التفاصيل قبل النشر.',
    category: ListingCategory.housing,
    area: 'حي العرب، بورسعيد',
    price: 4500,
    contactPhone: '',
  ),
  Listing(
    id: 'demo-2',
    title: 'مطلوب موظف مبيعات',
    description: 'فرصة عمل تجريبية. تأكد من تفاصيل الوظيفة قبل التقديم.',
    category: ListingCategory.jobs,
    area: 'بورسعيد',
    price: null,
    contactPhone: '',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onlineMode});
  final bool onlineMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ListingCategory? selectedCategory;
  String searchText = '';
  late Future<List<Listing>> listingsFuture;

  @override
  void initState() {
    super.initState();
    listingsFuture = loadListings();
  }

  Future<List<Listing>> loadListings() async {
    if (!widget.onlineMode) return demoListings;
    try {
      final rows = await Supabase.instance.client
          .from('listings')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(100);
      return (rows as List)
          .map((row) => Listing.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return demoListings;
    }
  }

  Future<void> refreshListings() async {
    setState(() => listingsFuture = loadListings());
    await listingsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDemoOrLive = FutureBuilder<List<Listing>>(
      future: listingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data ?? demoListings;
        final query = searchText.trim().toLowerCase();
        final filtered = all.where((listing) {
          final categoryMatches =
              selectedCategory == null || listing.category == selectedCategory;
          final searchMatches = query.isEmpty ||
              listing.title.toLowerCase().contains(query) ||
              listing.area.toLowerCase().contains(query) ||
              listing.description.toLowerCase().contains(query);
          return categoryMatches && searchMatches;
        }).toList();

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('لا توجد إعلانات مطابقة. جرّب بحثًا آخر.')),
          );
        }
        return Column(
          children: filtered.map((item) => ListingCard(listing: item)).toList(),
        );
      },
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.apartment_rounded, size: 30),
              SizedBox(width: 8),
              Text('وسيطك', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث الإعلانات',
              onPressed: refreshListings,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: refreshListings,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF176B55),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('كل اللي بتدور عليه قريب منك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(height: 6),
                    Text('إسكان ووظائف في بورسعيد',
                        style: TextStyle(color: Color(0xFFD9F1E6))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => searchText = value),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن شقة أو وظيفة أو منطقة...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 18),
              const Text('تصفح الأقسام',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CategoryTile(
                      icon: Icons.home_work_outlined,
                      title: 'الإسكان والعقارات',
                      selected: selectedCategory == ListingCategory.housing,
                      onTap: () => setState(() => selectedCategory =
                          selectedCategory == ListingCategory.housing
                              ? null
                              : ListingCategory.housing),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CategoryTile(
                      icon: Icons.work_outline_rounded,
                      title: 'الوظائف',
                      selected: selectedCategory == ListingCategory.jobs,
                      onTap: () => setState(() => selectedCategory =
                          selectedCategory == ListingCategory.jobs
                              ? null
                              : ListingCategory.jobs),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text('أحدث الإعلانات',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Text(widget.onlineMode ? 'متصل بقاعدة البيانات' : 'وضع تجريبي',
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.onlineMode
                              ? const Color(0xFF176B55)
                              : Colors.grey.shade700)),
                ],
              ),
              const SizedBox(height: 10),
              filteredDemoOrLive,
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF176B55),
          foregroundColor: Colors.white,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddListingScreen(
                onlineMode: widget.onlineMode,
                onSaved: refreshListings,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('أضف إعلان'),
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F1E9) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF176B55)
                : const Color(0xFFE0E7E2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF176B55)),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isJob = listing.category == ListingCategory.jobs;
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F3ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isJob ? Icons.work_outline : Icons.apartment_rounded,
                size: 30,
                color: const Color(0xFF176B55),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 5),
                  Text(listing.area,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 5),
                  Text(listing.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  if (listing.price != null) ...[
                    const SizedBox(height: 8),
                    Text('${listing.price} جنيه${isJob ? ' شهريًا' : ' / شهريًا'}',
                        style: const TextStyle(
                            color: Color(0xFF176B55),
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({
    super.key,
    required this.onlineMode,
    required this.onSaved,
  });
  final bool onlineMode;
  final Future<void> Function() onSaved;

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final areaController = TextEditingController(text: 'بورسعيد');
  final priceController = TextEditingController();
  final phoneController = TextEditingController();
  ListingCategory category = ListingCategory.housing;
  bool saving = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    areaController.dispose();
    priceController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (!widget.onlineMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('هذه نسخة تجريبية. اربط Supabase لحفظ الإعلانات فعليًا.'),
      ));
      return;
    }
    setState(() => saving = true);
    try {
      final price = int.tryParse(priceController.text.trim());
      await Supabase.instance.client.from('listings').insert({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': category == ListingCategory.jobs ? 'jobs' : 'housing',
        'area': areaController.text.trim(),
        'price': price,
        'contact_phone': phoneController.text.trim(),
        'status': 'pending',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم إرسال الإعلان للمراجعة بنجاح.'),
      ));
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذر حفظ الإعلان: $e'),
      ));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة إعلان جديد')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<ListingCategory>(
                segments: const [
                  ButtonSegment(
                    value: ListingCategory.housing,
                    label: Text('إسكان'),
                    icon: Icon(Icons.home_work_outlined),
                  ),
                  ButtonSegment(
                    value: ListingCategory.jobs,
                    label: Text('وظائف'),
                    icon: Icon(Icons.work_outline),
                  ),
                ],
                selected: {category},
                onSelectionChanged: (value) =>
                    setState(() => category = value.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'عنوان الإعلان'),
                validator: (v) =>
                    v == null || v.trim().length < 4 ? 'اكتب عنوانًا واضحًا' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'التفاصيل'),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'اكتب تفاصيل أكثر'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: areaController,
                decoration: const InputDecoration(labelText: 'المنطقة / الحي'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب المنطقة' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: category == ListingCategory.jobs
                        ? 'الراتب الشهري (اختياري)'
                        : 'السعر أو الإيجار بالجنيه (اختياري)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'رقم التواصل (اختياري)'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(saving ? 'جارٍ الحفظ...' : 'إرسال للمراجعة'),
              ),
              const SizedBox(height: 10),
              const Text(
                'سيتم إرسال الإعلان للمراجعة قبل ظهوره للناس. لا تنشر بيانات شخصية غير ضرورية.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
