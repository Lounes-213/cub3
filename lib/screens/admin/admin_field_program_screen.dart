import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../theme/theme.dart';
import '../../widgets/glass_app_bar.dart';

/// برنامج الملاعب — الأدمين يبرمج شكون يلعب وساعة في كل نهار،
/// والطلبة يشوفو الجدول اليومي في شاشة حجز الملعب (مشاهدة فقط).
class AdminFieldProgramScreen extends StatefulWidget {
  const AdminFieldProgramScreen({super.key});

  @override
  State<AdminFieldProgramScreen> createState() =>
      _AdminFieldProgramScreenState();
}

class _AdminFieldProgramScreenState extends State<AdminFieldProgramScreen> {
  final ApiClient _api = ApiClient();
  DateTime _selectedDay = _today();
  List<dynamic> _items = [];
  bool _loading = true;
  bool _saving = false;

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
    final today = _today();
    final diff = d.difference(today).inDays;
    final name = names[d.weekday % 7];
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    return name;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر تحميل البرنامج. تحقق من الاتصال.')),
      );
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        title: const Text('حذف المباراة',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text('هل تريد حذف هذه المباراة من البرنامج؟',
            style: TextStyle(color: Colors.white70, fontSize: 13.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style: TextStyle(color: AppColor.wrongColor))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('${ApiConstants.fieldProgram}/$id');
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف المباراة.')),
      );
    }
  }

  Future<void> _addMatch() async {
    final formKey = GlobalKey<FormState>();
    final teamACtrl = TextEditingController();
    final teamBCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String field = 'football';
    TimeOfDay time = const TimeOfDay(hour: 17, minute: 0);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColor.surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('إضافة مباراة',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dayLabel(_selectedDay),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 14),
                  const Text('الفريق الأول',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: teamACtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration:
                        const InputDecoration(hintText: 'مثال: جناح 1'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'أدخل الفريق الأول'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  const Text('الفريق الثاني',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: teamBCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration:
                        const InputDecoration(hintText: 'مثال: جناح 4'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'أدخل الفريق الثاني'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: field,
                          dropdownColor: AppColor.surfaceColor,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                              labelText: 'الملعب',
                              labelStyle: TextStyle(
                                  color: Colors.white54, fontSize: 11.5)),
                          items: const [
                            DropdownMenuItem(
                                value: 'football',
                                child: Text('ملعب كرة القدم')),
                            DropdownMenuItem(
                                value: 'basketball',
                                child: Text('ملعب كرة السلة')),
                          ],
                          onChanged: (v) => setDialogState(
                              () => field = v ?? 'football'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: ctx, initialTime: time);
                            if (picked != null) {
                              setDialogState(() => time = picked);
                            }
                          },
                          icon: const Icon(Icons.schedule,
                              size: 16, color: AppColor.primaryColor),
                          label: Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppColor.primaryColor
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: noteCtrl,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    decoration: const InputDecoration(
                        hintText: 'ملاحظة (اختياري)',
                        labelText: 'ملاحظة',
                        labelStyle:
                            TextStyle(color: Colors.white54, fontSize: 11.5)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => _saving = true);
                      try {
                        await _api.post(ApiConstants.fieldProgram, body: {
                          'playDate': _dateKey(_selectedDay),
                          'time':
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          'field': field,
                          'teamA': teamACtrl.text.trim(),
                          'teamB': teamBCtrl.text.trim(),
                          'note': noteCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() => _saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('تعذر حفظ المباراة. حاول مرة أخرى.')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.black),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _load();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: _today().subtract(const Duration(days: 7)),
      lastDate: _today().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(
          () => _selectedDay = DateTime(picked.year, picked.month, picked.day));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        title: const Text('برنامج الملاعب',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined,
                color: AppColor.primaryColor),
            tooltip: 'اختيار نهار آخر',
            onPressed: _pickDay,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMatch,
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مباراة',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _daySelector(),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColor.primaryColor)),
            )
          else if (_items.isEmpty)
            _emptyState()
          else
            ..._items.asMap().entries.map((e) => _matchCard(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _daySelector() {
    final days = List.generate(7, (i) => _today().add(Duration(days: i)));
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == days.length) {
            return ActionChip(
              avatar: const Icon(Icons.edit_calendar,
                  size: 16, color: AppColor.primaryColor),
              label: const Text('آخر',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              backgroundColor: AppColor.surfaceColor,
              side:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              onPressed: _pickDay,
            );
          }
          final d = days[i];
          final selected =
              _dateKey(d) == _dateKey(_selectedDay);
          return ChoiceChip(
            label: Text(_dayLabel(d),
                style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            selected: selected,
            selectedColor: AppColor.primaryColor,
            backgroundColor: AppColor.surfaceColor,
            side: BorderSide(
                color: selected
                    ? AppColor.primaryColor
                    : Colors.white.withValues(alpha: 0.1)),
            onSelected: (_) {
              setState(() => _selectedDay = d);
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.sports_soccer, size: 52, color: Colors.white12),
          SizedBox(height: 14),
          Text('لا توجد مباريات مبرمجة لهذا النهار',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('اضغط «إضافة مباراة» لبرمجة موعد وفرق.',
              style: TextStyle(color: Colors.white38, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _matchCard(dynamic raw, int index) {
    final m = raw is Map ? raw : const {};
    final isFootball = (m['field'] ?? 'football') == 'football';
    final color = isFootball
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${m['time'] ?? ''}',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m['teamA'] ?? ''} × ${m['teamB'] ?? ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(isFootball
                        ? Icons.sports_soccer
                        : Icons.sports_basketball),
                    const SizedBox(width: 5),
                    Text(
                        isFootball ? 'ملعب كرة القدم' : 'ملعب كرة السلة',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10.5)),
                    if ((m['note'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${m['note']}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColor.wrongColor, size: 20),
            tooltip: 'حذف',
            onPressed: () => _delete('${m['id']}'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.05);
  }
}
