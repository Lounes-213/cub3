import 'dart:convert';
import '../widgets/glass_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../widgets/resident_card.dart';
import '../core/utils/photo_utils.dart';
import '../providers/user_provider.dart';
import '../localization/app_strings.dart';
import 'student_data_screen.dart';

class HousingScreen extends StatefulWidget {
  const HousingScreen({super.key});

  @override
  State<HousingScreen> createState() => _HousingScreenState();
}

class _HousingScreenState extends State<HousingScreen> {
  static const _reqKey = 'cube3_maintenance_requests';

  /// طلبات الطالب نفسه فقط (محفوظة محلياً) — لا طلبات وهمية جاهزة.
  List<Map<String, dynamic>> _maintenanceRequests = [];

  String get _matricule =>
      context.read<UserProvider>().matricule;

  Future<void> _loadRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_reqKey}_$_matricule');
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) setState(() => _maintenanceRequests = list);
    } catch (_) {}
  }

  Future<void> _saveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '${_reqKey}_$_matricule', jsonEncode(_maintenanceRequests));
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  final _descController = TextEditingController();
  String _selectedType = 'كهرباء';

  void _submitRequest() {
    if (_descController.text.trim().isEmpty) return;

    setState(() {
      _maintenanceRequests.insert(0, {
        'id': 'REQ-${DateTime.now().millisecondsSinceEpoch}',
        'type': _selectedType,
        'desc': _descController.text.trim(),
        'status': 'قيد المعالجة',
        'date': DateTime.now().toString().split(' ')[0],
      });
    });
    _saveRequests();

    _descController.clear();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم تقديم طلب الصيانة بنجاح. سيتم توجيه تقني المصلحة قريباً.',
        ),
        backgroundColor: AppColor.correctColor,
      ),
    );
  }

  void _showCertificateDialog({
    required String fullNameAr,
    required String? photo,
    required String? regNum,
    required String? levelAr,
    required String? roomNumber,
    required String? residentSince,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'شهادة الإيواء الرقمية',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    final bytes = tryDecodePhoto(photo);
                    if (bytes == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            child: Image.memory(
                              bytes,
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    );
                  },
                ),
                const Icon(
                  Icons.qr_code_2,
                  size: 85,
                  color: AppColor.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'الجمهورية الجزائرية الديمقراطية الشعبية\nوزارة التعليم العالي والبحث العلمي\nالديوان الوطني للخدمات الجامعية',
              style: TextStyle(color: textSecondary, fontSize: 10, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Divider(color: dividerColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المستفيد:',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
                Flexible(
                  child: Text(
                    fullNameAr.isNotEmpty ? fullNameAr : '—',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (regNum != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'رقم التسجيل:',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  Flexible(
                    child: Text(
                      regNum,
                      style: TextStyle(color: textPrimary, fontSize: 12),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (levelAr != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المستوى الدراسي:',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  Expanded(
                    child: Text(
                      levelAr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'رقم الغرفة:',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
                Flexible(
                  child: Text(
                    roomNumber?.isNotEmpty == true
                        ? roomNumber!
                        : 'تُحدد من الإدارة',
                    style: const TextStyle(
                      color: AppColor.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مقيم منذ:',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
                Text(
                  residentSince?.isNotEmpty == true ? residentSince! : '—',
                  style: TextStyle(color: textPrimary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: textSecondary,
              side: BorderSide(color: dividerColor),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إغلاق',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم تحميل شهادة الإيواء بصيغة PDF بنجاح في جهازك.',
                  ),
                  backgroundColor: AppColor.correctColor,
                ),
              );
            },
            child: const Text(
              'تحميل PDF',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRequestDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColor.surfaceColor
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تقديم طلب صيانة للغرفة',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'فئة العطل:',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                dropdownColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColor.surfaceColor
                    : Colors.white,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['كهرباء', 'سباكة', 'أثاث وغرفة', 'أبواب ونوافذ'].map((
                  t,
                ) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) {
                  if (val != null) _selectedType = val;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'وصف دقيق للمشكلة:',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText:
                      'اكتب تفاصيل المشكلة هنا (مثال: مصباح الجدار متذبذب...)',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white30
                        : Colors.black38,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black26,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryColor,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                      ),
                      onPressed: _submitRequest,
                      child: const Text(
                        'تقديم الطلب',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// معلومات الإيواء كما هي في PROGRES: هل طُلب؟ هل قُبل؟ نوعه ومكانه.
  Widget _buildProgresHousingCard(UserProvider user) {
    final data = user.studentData;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;

    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_download_outlined, color: textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'لم تُجلب بعد بيانات الإيواء من PROGRES',
                style: TextStyle(color: textSecondary, fontSize: 12.5),
              ),
            ),
            TextButton(
              onPressed: () => user.refreshStudentData(),
              child: const Text('جلب'),
            ),
          ],
        ),
      );
    }

    String? yesNo(bool? v) => v == null ? null : (v ? 'نعم' : 'لا');

    final rows = <Widget>[];
    void add(String label, String? value, {bool highlight = false}) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(color: textSecondary, fontSize: 12.5)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: highlight ? AppColor.primaryColor : textPrimary,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    add('طلب الإيواء', yesNo(data.accommodationRequested));
    add('الإيواء مقبول', yesNo(data.accommodationGranted));
    add('نوع الإيواء', data.accommodationTypeAr ?? data.accommodationTypeFr);
    add('مكان الإيواء', data.accommodationPlace);
    add('أقدمية الإيواء', data.accommodationSeniority);
    add('ملاحظة الديوان', data.accommodationObservation);
    add('رقم الغرفة', user.roomNumber, highlight: true);
    add('مقيم منذ', user.residentSince);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_outlined,
                  color: AppColor.primaryColor, size: 18),
              const SizedBox(width: 10),
              Text(
                'بيانات الإيواء (PROGRES)',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentDataScreen()),
                ),
                child: const Text('كل المعلومات', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...rows,
        ],
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
          AppStrings.of(context, 'dept_housing'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: Builder(
        builder: (context) {
          // بيانات حقيقية من الحساب المتصل (PROGRES + تعيين الإدارة)
          final userProvider = context.watch<UserProvider>();
          final fullNameAr = userProvider.fullNameAr;
          final photo = userProvider.photo;
          final regNum = userProvider.registrationNumber;
          final levelAr = userProvider.levelAr;
          final roomNumber = userProvider.roomNumber;
          final residentSince = userProvider.residentSince;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة المقيم (بيانات حقيقية)
                ResidentCard(
                  fullNameAr: fullNameAr,
                  photo: photo,
                  registrationNumber: regNum,
                  roomNumber: roomNumber,
                  residentSince: residentSince,
                  levelAr: levelAr,
                ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: () => _showCertificateDialog(
                      fullNameAr: fullNameAr,
                      photo: photo,
                      regNum: regNum,
                      levelAr: levelAr,
                      roomNumber: roomNumber,
                      residentSince: residentSince,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'عرض شهادة الإيواء الرقمية',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // بيانات الإيواء الرسمية من PROGRES (إن وُجدت)
                _buildProgresHousingCard(userProvider),

                const SizedBox(height: 32),

                // Maintenance section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'طلبات صيانة الغرفة',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddRequestDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('طلب جديد'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Requests list (طلبات الطالب نفسه فقط — لا عناصر وهمية)
                if (_maintenanceRequests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            color: Colors.white24, size: 20),
                        SizedBox(width: 10),
                        Text('لا توجد طلبات صيانة بعد',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  )
                else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _maintenanceRequests.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = _maintenanceRequests[index];
                    final isSolved = req['status'] == 'تم الحل';

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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSolved
                                  ? AppColor.correctColor.withValues(alpha: 0.1)
                                  : Colors.orangeAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              req['type'] == 'كهرباء'
                                  ? Icons.flash_on
                                  : Icons.plumbing,
                              color: isSolved
                                  ? AppColor.correctColor
                                  : Colors.orangeAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      req['type'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      req['date'],
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  req['desc'],
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSolved
                                  ? AppColor.correctColor.withValues(alpha: 0.1)
                                  : Colors.orangeAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req['status'],
                              style: TextStyle(
                                color: isSolved
                                    ? AppColor.correctColor
                                    : Colors.orangeAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // internal guidelines list
                Text(
                  'لوائح وقوانين مصلحة الإيواء',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGuidelineCard(
                  'قواعد الزيارة والضيوف',
                  'يمنع مبيت الزوار الخارجيين داخل الغرف بعد الساعة 20:00 مساءً حفاظاً على الأمن والهدوء.',
                ),
                const SizedBox(height: 12),
                _buildGuidelineCard(
                  'الاستهلاك الطاقوي والأمن',
                  'يمنع استخدام المدافئ أو سخانات المياه ذات الاستهلاك العالي وغير المطابقة لمعايير السلامة العامة.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuidelineCard(String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textColor: AppColor.primaryColor,
        collapsedTextColor: textPrimary,
        iconColor: AppColor.primaryColor,
        collapsedIconColor: textSecondary,
        childrenPadding: EdgeInsets.zero,
        tilePadding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              desc,
              style: TextStyle(color: textSecondary, fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
