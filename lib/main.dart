
import 'package:flutter/material.dart';

void main() {
  runApp(const WasitakApp());
}

class WasitakApp extends StatelessWidget {
  const WasitakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وسيطك',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16834A),
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

  final List<Map<String, String>> ads = [
    {
      'title': 'شقة للإيجار في بورسعيد',
      'details': 'حي العرب • غرفتان • تشطيب جيد',
      'price': '6,000 جنيه شهريًا',
      'category': 'سكن',
      'icon': 'home',
    },
    {
      'title': 'مطلوب موظف مبيعات',
      'details': 'بورسعيد • دوام كامل',
      'price': 'راتب يحدد بالمقابلة',
      'category': 'وظائف',
      'icon': 'work',
    },
    {
      'title': 'شقة للبيع',
      'details': 'حي الزهور • 3 غرف • مساحة 120 متر',
      'price': '1,250,000 جنيه',
      'category': 'سكن',
      'icon': 'home',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAds = ads.where((ad) {
      final matchesCategory = selectedCategory == 0 ||
          (selectedCategory == 1 && ad['category'] == 'سكن') ||
          (selectedCategory == 2 && ad['category'] == 'وظائف');
      final matchesSearch =
          ad['title']!.contains(search) || ad['details']!.contains(search);
      return matchesCategory && matchesSearch;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16834A),
          foregroundColor: Colors.white,
          title: const Text(
            'وسيطك',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16834A),
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
              onChanged: (value) => setState(() => search = value.trim()),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${filteredAds.length} إعلانات',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredAds.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('مفيش إعلانات مطابقة للبحث')),
              ),
            ...filteredAds.map((ad) => _adCard(ad)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF16834A),
          foregroundColor: Colors.white,
          onPressed: () => _showAddAdDialog(),
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
          backgroundColor:
              selected ? const Color(0xFF16834A) : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => setState(() => selectedCategory = index),
        child: Text(label),
      ),
    );
  }

  Widget _adCard(Map<String, String> ad) {
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
                ad['icon'] == 'work' ? Icons.work_outline : Icons.home_outlined,
                color: const Color(0xFF16834A),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['title']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ad['details']!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    ad['price']!,
                    style: const TextStyle(
                      color: Color(0xFF16834A),
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

  void _showAddAdDialog() {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'سكن';

    showDialog(
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
                  decoration: const InputDecoration(labelText: 'عنوان الإعلان'),
                ),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(labelText: 'التفاصيل'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'السعر أو الراتب'),
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
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                setState(() {
                  ads.insert(0, {
                    'title': titleController.text.trim(),
                    'details': detailsController.text.trim(),
                    'price': priceController.text.trim().isEmpty
                        ? 'السعر عند التواصل'
                        : priceController.text.trim(),
                    'category': category,
                    'icon': category == 'وظائف' ? 'work' : 'home',
                  });
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}
