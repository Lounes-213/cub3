import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../core/auth/guards.dart';
import '../providers/user_provider.dart';
import '../providers/app_config_provider.dart';
import '../services/medical_orders_service.dart';
import '../localization/app_strings.dart';

class MedicalScreen extends StatefulWidget {
  const MedicalScreen({super.key});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  final MedicalOrdersService _orders = MedicalOrdersService();
  String _selectedSpecialty = 'طب عام';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();
  bool _booking = false;

  List<Map<String, dynamic>> _myAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final matricule = context.read<UserProvider>().matricule;
    if (matricule.isEmpty) return;
    final list = await _orders.myOrders(matricule);
    if (mounted) setState(() => _myAppointments = list);
  }

  final List<Map<String, dynamic>> _firstAidGuides = [
    {
      'title': 'الإغماء وتراجع الضغط',
      'icon': Icons.airline_seat_flat_angled,
      'steps':
          '1. ضع المصاب مستلقياً على ظهره.\n2. ارفع قدمي المصاب قليلاً لمساعدة تدفق الدم للدماغ.\n3. تأكد من تهوية المكان وفك الملابس الضيقة.\n4. اتصل بالمصلحة فوراً إذا طال الإغماء.',
    },
    {
      'title': 'الحروق الطفيفة السطحية',
      'icon': Icons.local_fire_department_outlined,
      'steps':
          '1. ضع الحرق تحت ماء بارد جاري لـ 10 إلى 15 دقيقة.\n2. لا تضع الثلج مباشرة على مكان الحرق.\n3. قم بتغطية الحرق بقطعة شاش معقمة ونظيفة.\n4. لا تقم بفتح الفقاعات الجلدية الناتجة.',
    },
    {
      'title': 'الكسور والالتواءات',
      'icon': Icons.healing_outlined,
      'steps':
          '1. لا تحاول تحريك العظم المكسور أو إعادته لمكانه.\n2. ثبت الطرف المصاب بجبيرة مؤقتة مسطحة.\n3. ضع كيس ثلج مغطى بقماش لتخفيف التورم.\n4. انقل المصاب لأقرب نقطة طبية بحذر.',
    },
  ];

  /// رقم المصلحة الطبية: يُبرمج من الإدارة فقط، وإلا فنرجع لأول رقم طوارئ.
  String get _medicalCallNumber {
    final cfg = context.read<AppConfigProvider>().config;
    final direct = cfg.medicalPhone.trim();
    if (direct.isNotEmpty) return direct;
    for (final e in cfg.emergencyNumbers) {
      final n = (e['number'] ?? '').trim();
      if (n.isNotEmpty) return n;
    }
    return '';
  }

  void _callMedical() {
    final number = _medicalCallNumber;
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رقم المصلحة الطبية غير مبرمج بعد — يُبرمج من لوحة الإدارة.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    launchUrl(
      Uri.parse('tel:$number'),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري الاتصال بالرقم $number'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _bookAppointment() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب سبب الزيارة أولاً')),
      );
      return;
    }
    // الحجز يتطلب حساباً متصلاً (يظهر في لوحة الإدارة)
    final ok = await requireLogin(context,
        reason: 'سجل الدخول أولاً لحجز موعد طبي');
    if (!ok || !mounted) return;

    final up = context.read<UserProvider>();
    setState(() => _booking = true);
    try {
      final id = await _orders.create(
        matricule: up.matricule,
        name: up.fullNameAr,
        specialty: _selectedSpecialty,
        date: _selectedDate.toString().split(' ')[0],
        notes: _reasonController.text.trim(),
      );
      _reasonController.clear();
      await _loadOrders();
      if (!mounted) return;
      _showTicketDialog(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحجز — تحقق من الاتصال')),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showTicketDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColor.correctColor),
            SizedBox(width: 12),
            Text(
              'تم تأكيد الحجز!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لقد تم تسجيل موعدك الطبي بنجاح. يرجى إظهار التذكرة التالية للممرض عند وصولك.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'رمز التذكرة:',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      Text(
                        id,
                        style: const TextStyle(
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'التخصص:',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      Text(
                        _selectedSpecialty,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تاريخ الموعد:',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      Text(
                        _selectedDate.toString().split(' ')[0],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'التوقيت المتوقع:',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      const Text(
                        'يُحدد عند الحضور',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 36),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.3),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'حسناً',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFirstAidDetails(Map<String, dynamic> guide) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColor.surfaceColor
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(guide['icon'], color: Colors.blueAccent, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    guide['title'],
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'خطوات الإسعاف الأولي السريعة:',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                guide['steps'],
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: 12,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'فهمت',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
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
          AppStrings.of(context, 'dept_medical'),
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
              // Emergency contact call lines
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Colors.redAccent,
                      size: 24,
                    ).animate(onPlay: (c) => c.repeat()).shake(hz: 3),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خط الطوارئ للمصلحة الطبية',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'خدمة إسعاف وتدخل طبي عاجل على مدار 24 ساعة.',
                          style: TextStyle(color: textSecondary, fontSize: 10),
                        ),
                        Builder(builder: (context) {
                          final number = _medicalCallNumber;
                          if (number.isEmpty) return const SizedBox.shrink();
                          return Text(
                            'الرقم: $number',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: _callMedical,
                    child: const Text(
                      'اتصل الآن',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Form card for Booking Medical Appointment
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
                    'حجز موعد فحص طبي جديد',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر التخصص المطلوب وتوقيت الاستشارة المناسب لك.',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'عيادة الفحص المحددة:',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSpecialty,
                    dropdownColor: AppColor.surfaceColor,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items:
                        [
                          'طب عام',
                          'طب الأسنان',
                          'متابعة نفسية',
                          'مصلحة التمريض',
                        ].map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSpecialty = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تاريخ الفحص:',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate.toString().split(' ')[0],
                            style: TextStyle(color: textPrimary),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColor.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'الأعراض أو سبب الزيارة:',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'وصف سريع للأعراض (مثال: ألم بالأسنان، حمى وصداع...)',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 11),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.all(12),
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: _booking ? null : _bookAppointment,
                    child: _booking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text(
                            'تأكيد وحجز الموعد',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Active medical schedule appointments list
            if (_myAppointments.isNotEmpty) ...[
              const Text(
                'حجوزاتي ومواعيدي الطبية القادمة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myAppointments.length,
                itemBuilder: (context, index) {
                  final appt = _myAppointments[index];
                  return Card(
                    color: surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        child: const Icon(
                          Icons.healing_outlined,
                          color: Colors.blueAccent,
                        ),
                      ),
                      title: Text(
                        appt['specialty']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'التاريخ: ${appt['date']} - وقت الحضور المتوقع: ${appt['time']}',
                        style: TextStyle(color: textSecondary, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: Text(
                        appt['id']!,
                        style: const TextStyle(
                          color: AppColor.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
            ],

            // First aid guidelines list slider
            Text(
              'دليل الإسعافات الأولية السريعة 🩹',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _firstAidGuides.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final guide = _firstAidGuides[index];
                  return GestureDetector(
                    onTap: () => _showFirstAidDetails(guide),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            guide['icon'],
                            color: Colors.blueAccent,
                            size: 26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            guide['title'],
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط لقراءة الدليل الكامل',
                            style: TextStyle(color: textSecondary, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
