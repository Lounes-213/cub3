import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../localization/app_strings.dart';
import '../theme/theme.dart';

/// برنامج الملاعب (مشاهدة فقط) — الأدمين يبرمج شكون يلعب وساعة في كل نهار،
/// والطالب يشوف جدول اليوم هنا.
class FieldBookingScreen extends StatefulWidget {
  const FieldBookingScreen({super.key});

  @override
  State<FieldBookingScreen> createState() => _FieldBookingScreenState();
}

class _FieldBookingScreenState extends State<FieldBookingScreen> {
  final ApiClient _api = ApiClient();
  DateTime _selectedDay = _today();
  List<dynamic> _items = [];
  bool _loading = true;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateKey(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _dayLabel(DateTime d) {
    const names = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    final diff = d.difference(_today()).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    return names[d.weekday % 7];
  }

  String _fullDayLabel(DateTime d) {
    const names = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    String two(int v) => v.toString().padLeft(2, '0');
    return '${names[d.weekday % 7]} ${two(d.day)}/${two(d.month)}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api
          .get('${ApiConstants.fieldProgram}?date=${_dateKey(_selectedDay)}');
      final list = (res is Map && res['program'] is List)
          ? res['program'] as List
          : const [];
      if (!mounted) return;
      setState(() {
        _items = List<dynamic>.from(list);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: _today(),
      lastDate: _today().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(
          () => _selectedDay = DateTime(picked.year, picked.month, picked.day));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.of(context, k);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: GlassAppBar(
        title: Text(
          s('book_field'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: textPrimary),
            tooltip: 'اختيار نهار آخر',
            onPressed: _pickDay,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimary),
            tooltip: 'تحديث',
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColor.primaryColor,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              s('book_field_desc'),
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 18),
            _daySelector(surface, textPrimary, textSecondary),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.event_note,
                    size: 18, color: AppColor.primaryColor),
                const SizedBox(width: 8),
                Text('برنامج ${_fullDayLabel(_selectedDay)}',
                    style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5)),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColor.primaryColor)),
              )
            else if (_items.isEmpty)
              _emptyState(surface, textSecondary)
            else
              ..._items.asMap().entries.map(
                  (e) => _matchCard(e.value, e.key, surface, textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _daySelector(
      Color surface, Color textPrimary, Color textSecondary) {
    final days = List.generate(7, (i) => _today().add(Duration(days: i)));
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final selected = _dateKey(d) == _dateKey(_selectedDay);
          return ChoiceChip(
            label: Text(_dayLabel(d),
                style: TextStyle(
                    color: selected ? Colors.black : textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            selected: selected,
            selectedColor: AppColor.primaryColor,
            backgroundColor: surface,
            side: BorderSide(
                color: selected
                    ? AppColor.primaryColor
                    : textSecondary.withValues(alpha: 0.2)),
            onSelected: (_) {
              setState(() => _selectedDay = d);
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(Color surface, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 18),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_soccer, size: 48, color: Colors.black12),
          const SizedBox(height: 14),
          Text('لا توجد مباريات مبرمجة لهذا النهار',
              style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 6),
          const Text('برنامج المباريات يحدده مصلحة النشاطات في الإقامة.',
              style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _matchCard(
      dynamic raw, int index, Color surface, Color textPrimary) {
    final m = raw is Map ? raw : const {};
    final isFootball = (m['field'] ?? 'football') == 'football';
    final color =
        isFootball ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${m['time'] ?? ''}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m['teamA'] ?? ''} × ${m['teamB'] ?? ''}',
                    style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isFootball
                          ? Icons.sports_soccer
                          : Icons.sports_basketball,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                        isFootball ? 'ملعب كرة القدم' : 'ملعب كرة السلة',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 11)),
                    if ((m['note'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('• ${m['note']}',
                            style: const TextStyle(
                                color: Colors.black38, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.05);
  }
}
