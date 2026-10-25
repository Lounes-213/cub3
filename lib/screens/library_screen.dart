import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/app_config_provider.dart';
import '../widgets/programmed_info_banner.dart';
import '../localization/app_strings.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allBooks = [
    {
      'title': 'مقدمة في الذكاء الاصطناعي',
      'author': 'د. كمال أحمد',
      'category': 'موجز برمجيات',
      'status': 'متاح',
      'color': Colors.greenAccent,
    },
    {
      'title': 'الفيزياء الأساسية للجامعات',
      'author': 'أ.د. سليم عمر',
      'category': 'علوم دقيقة',
      'status': 'متاح',
      'color': Colors.greenAccent,
    },
    {
      'title': 'هندسة العمارة الإسلامية',
      'author': 'م. ياسمين بلقاسم',
      'category': 'فنون وتاريخ',
      'status': 'مستعار',
      'color': Colors.redAccent,
    },
    {
      'title': 'خوارزميات البنية وهياكل البيانات',
      'author': 'د. رياض صالح',
      'category': 'موجز برمجيات',
      'status': 'متاح',
      'color': Colors.greenAccent,
    },
    {
      'title': 'تاريخ الجزائر المعاصر',
      'author': 'أ.د. عبد الحميد مهري',
      'category': 'علوم إنسانية',
      'status': 'مستعار',
      'color': Colors.redAccent,
    },
  ];

  List<Map<String, dynamic>> _filteredBooks = [];

  final List<Map<String, dynamic>> _myBorrowedBooks = [
    {
      'title': 'خوارزميات البنية وهياكل البيانات',
      'borrowDate': '2026-05-01',
      'dueDate': '2026-05-20',
      'daysLeft': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredBooks = List.from(_allBooks);
  }

  void _searchBooks(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredBooks = List.from(_allBooks);
      } else {
        _filteredBooks = _allBooks.where((book) {
          return book['title']!.contains(query) ||
              book['author']!.contains(query);
        }).toList();
      }
    });
  }

  /// الضغط على مقعد متاح: الحجز مزال غير مبرمج.
  void _bookSeat(int seatNumber) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('مقعد رقم $seatNumber',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('خدمة حجز المقاعد مزالت غير مبرمجة.',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 13)),
            SizedBox(height: 8),
            Text('الحجز حالياً مباشرة لدى أعوان المكتبة.',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  void _renewBook(int index) {
    setState(() {
      _myBorrowedBooks[index]['dueDate'] = '2026-05-30';
      _myBorrowedBooks[index]['daysLeft'] = 13;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم تمديد استعارة الكتاب بنظام المكتبة بنجاح لمدة 10 أيام إضافية.',
        ),
        backgroundColor: AppColor.correctColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlassAppBar(
        title: Text(
          AppStrings.of(context, 'library'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgrammedInfoBanner.library(context),
            const SizedBox(height: 12),
            // Library Seat Layout Grid Booking
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.indigoAccent.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'حجز مقعد قاعة المطالعة',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context
                              .read<AppConfigProvider>()
                              .config
                              .libraryHours,
                          style: const TextStyle(
                            color: Colors.indigoAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر مقعدك المفضل لحجزه وتأمين مساحة هادئة للدراسة والمراجعة.',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  // Mini seat layout grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: 24, // 24 mock seats
                    itemBuilder: (context, index) {
                      final seatNumber = index + 1;
                      // المقاعد للعرض فقط — الحجز مزال غير مبرمج
                      const seatColor = Colors.white10;

                      return GestureDetector(
                        onTap: () => _bookSeat(seatNumber),
                        child: Container(
                          decoration: BoxDecoration(
                            color: seatColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white10,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$seatNumber',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'اضغط على أي مقعد: خدمة الحجز مزالت غير مبرمجة.',
                      style: TextStyle(
                          color: Colors.orangeAccent, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),
            const SizedBox(height: 28),

            // Book Search bar and catalog
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'محرك البحث في كتب المكتبة 📚',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search input
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: textPrimary),
                    onChanged: _searchBooks,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن اسم الكتاب، الكاتب، أو التخصص...',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 11),
                      prefixIcon: Icon(
                        Icons.search,
                        color: textSecondary,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Render filtered list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredBooks.length > 3
                        ? 3
                        : _filteredBooks.length,
                    separatorBuilder: (context, index) => Divider(
                      color: isDark ? Colors.white10 : Colors.black12,
                      height: 16,
                    ),
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];

                      return Row(
                        children: [
                          Icon(Icons.book, color: textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['title']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'الكاتب: ${book['author']} | الفئة: ${book['category']}',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (book['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              book['status']!,
                              style: TextStyle(
                                color: book['color'] as Color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 28),

            // Borrowed books progress return
            if (_myBorrowedBooks.isNotEmpty) ...[
              Text(
                'كتبي المستعارة الحالية',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myBorrowedBooks.length,
                itemBuilder: (context, index) {
                  final borrow = _myBorrowedBooks[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: Colors.indigoAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                borrow['title']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'تاريخ الإرجاع الأقصى: ${borrow['dueDate']} (${borrow['daysLeft']} أيام متبقية)',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 6,
                            shadowColor: Colors.black.withValues(alpha: 0.3),
                          ),
                          onPressed: () => _renewBook(index),
                          child: const Text(
                            'تمديد الاستعارة',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
