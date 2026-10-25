import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/app_config_provider.dart';
import '../../theme/theme.dart';
import 'admin_facilities_screen.dart';

/// لوحة برمجة التطبيق — المدير يبرمج منها كل شيء بدون كود:
/// الاسم، الإعلان المجدول، الأقسام، الوجبات، النقل، المكتبة، الحمامات، الروابط، المسابقة.
class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _formKey = GlobalKey<FormState>();
  bool _init = false;

  late TextEditingController medicalPhone;

  late TextEditingController announcementText;
  late TextEditingController announcementStart;
  late TextEditingController announcementEnd;

  late TextEditingController libraryHours;
  late TextEditingController libraryNotes;
  late TextEditingController showerMorningStart;
  late TextEditingController showerMorningEnd;
  late TextEditingController showerEveningStart;
  late TextEditingController showerEveningEnd;
  late TextEditingController showerNotes;

  late TextEditingController fbResidence;
  late TextEditingController fbDirection;
  late TextEditingController fbClub;
  late TextEditingController webDirection;
  late TextEditingController webProgres;


  // أرقام الطوارئ (تُبنى ديناميكياً)
  final List<TextEditingController> _emgNames = [];
  final List<TextEditingController> _emgNumbers = [];
  bool _emgInit = false;

  void _initEmg(List<Map<String, String>> list) {
    for (final c in _emgNames) {
      c.dispose();
    }
    for (final c in _emgNumbers) {
      c.dispose();
    }
    _emgNames.clear();
    _emgNumbers.clear();
    for (final e in list) {
      _emgNames.add(TextEditingController(text: e['name'] ?? ''));
      _emgNumbers.add(TextEditingController(text: e['number'] ?? ''));
    }
    _emgInit = true;
  }

  void _initControllers(AppConfig c) {
    medicalPhone = TextEditingController(text: c.medicalPhone);
    announcementText = TextEditingController(text: c.announcementText);
    announcementStart = TextEditingController(text: c.announcementStart);
    announcementEnd = TextEditingController(text: c.announcementEnd);
    libraryHours = TextEditingController(text: c.libraryHours);
    libraryNotes = TextEditingController(text: c.libraryNotes);
    showerMorningStart = TextEditingController(text: c.showerMorningStart);
    showerMorningEnd = TextEditingController(text: c.showerMorningEnd);
    showerEveningStart = TextEditingController(text: c.showerEveningStart);
    showerEveningEnd = TextEditingController(text: c.showerEveningEnd);
    showerNotes = TextEditingController(text: c.showerNotes);
    fbResidence = TextEditingController(text: c.fbResidence);
    fbDirection = TextEditingController(text: c.fbDirection);
    fbClub = TextEditingController(text: c.fbClub);
    webDirection = TextEditingController(text: c.webDirection);
    webProgres = TextEditingController(text: c.webProgres);
    _init = true;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in _emgNames) {
      c.dispose();
    }
    for (final c in _emgNumbers) {
      c.dispose();
    }
    if (_init) {
      for (final c in [
        medicalPhone,
        announcementText, announcementStart, announcementEnd,
        libraryHours, libraryNotes,
        showerMorningStart, showerMorningEnd,
        showerEveningStart, showerEveningEnd, showerNotes,
        fbResidence, fbDirection, fbClub, webDirection, webProgres,
      ]) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController target) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(target.text) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      target.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final provider = context.read<AppConfigProvider>();
    final c = provider.config;
    c.medicalPhone = medicalPhone.text.trim();
    c.announcementText = announcementText.text.trim();
    c.announcementStart = announcementStart.text.trim();
    c.announcementEnd = announcementEnd.text.trim();
    c.libraryHours = libraryHours.text.trim();
    c.libraryNotes = libraryNotes.text.trim();
    c.showerMorningStart = showerMorningStart.text.trim().isEmpty ? '07:00' : showerMorningStart.text.trim();
    c.showerMorningEnd = showerMorningEnd.text.trim().isEmpty ? '11:00' : showerMorningEnd.text.trim();
    c.showerEveningStart = showerEveningStart.text.trim().isEmpty ? '17:00' : showerEveningStart.text.trim();
    c.showerEveningEnd = showerEveningEnd.text.trim().isEmpty ? '21:00' : showerEveningEnd.text.trim();
    c.showerNotes = showerNotes.text.trim();
    c.fbResidence = fbResidence.text.trim();
    c.fbDirection = fbDirection.text.trim();
    c.fbClub = fbClub.text.trim();
    c.webDirection = webDirection.text.trim();
    c.webProgres = webProgres.text.trim();
    // أرقام الطوارئ (استبدال كامل — تُدفع للسحابة مع الحفظ)
    final emg = <Map<String, String>>[];
    for (int i = 0; i < _emgNames.length; i++) {
      final name = _emgNames[i].text.trim();
      final number = _emgNumbers[i].text.trim();
      if (name.isNotEmpty && number.isNotEmpty) {
        emg.add({'name': name, 'number': number});
      }
    }
    c.emergencyNumbers = emg;
    await provider.save(c);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ برمجة التطبيق بنجاح ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppConfigProvider>();
    final c = provider.config;
    if (!_init) _initControllers(c);
    if (!_emgInit) _initEmg(c.emergencyNumbers);

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('برمجة التطبيق cube3',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColor.primaryColor,
          tabs: const [
            Tab(text: 'إعلان مبرمج'),
            Tab(text: 'الأقسام والخدمات'),
            Tab(text: 'الروابط'),
            Tab(text: 'طوارئ'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'استرجاع الافتراضي',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              final configProvider = context.read<AppConfigProvider>();
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('استرجاع الإعدادات الافتراضية؟'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('تأكيد')),
                  ],
                ),
              );
              if (ok == true) {
                await configProvider.resetToDefaults();
                if (mounted) {
                  setState(() {
                    _init = false;
                    _emgInit = false;
                  });
                }
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tab,
          children: [
            _tabAnnouncement(c),
            _tabServices(c),
            _tabLinks(),
            _tabEmergency(c),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('حفظ كل البرمجة',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabAnnouncement(AppConfig c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('تفعيل الإعلان المبرمج',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('يظهر كشريط في أعلى الصفحة الرئيسية',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          value: c.announcementEnabled,
          activeThumbColor: AppColor.primaryColor,
          onChanged: (v) =>
              context.read<AppConfigProvider>().update((x) => x.announcementEnabled = v),
        ),
        _field('نص الإعلان', announcementText, maxLines: 3,
            hint: 'مثال: التسجيلات للنشاط الرياضي مفتوحة إلى غاية الخميس'),
        Row(
          children: [
            Expanded(
              child: _field('تاريخ البداية (yyyy-MM-dd)', announcementStart,
                  hint: '2026-09-25',
                  suffix: IconButton(
                      icon: const Icon(Icons.calendar_month, size: 18),
                      onPressed: () => _pickDate(announcementStart))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field('تاريخ النهاية', announcementEnd,
                  hint: '2026-10-01',
                  suffix: IconButton(
                      icon: const Icon(Icons.calendar_month, size: 18),
                      onPressed: () => _pickDate(announcementEnd))),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Text(
            c.isAnnouncementActiveNow
                ? '✅ الإعلان نشط الآن وسيظهر للمستخدمين'
                : '⏸️ الإعلان غير نشط حالياً (تحقق من التفعيل والنص والتواريخ)',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _tabServices(AppConfig c) {
    final p = context.read<AppConfigProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('الأقسام الإدارية', [
          _switch('الأنشطة', c.showActivities, (v) => p.update((x) => x.showActivities = v)),
          _switch('السكن', c.showHousing, (v) => p.update((x) => x.showHousing = v)),
          _switch('الإطعام', c.showCatering, (v) => p.update((x) => x.showCatering = v)),
          _switch('الصحة', c.showMedical, (v) => p.update((x) => x.showMedical = v)),
        ]),
        _section('المكتبة والحمامات', [
          _switch('إظهار المكتبة', c.showLibrary,
              (v) => p.update((x) => x.showLibrary = v)),
          _field('توقيت المكتبة', libraryHours),
          _field('ملاحظات المكتبة', libraryNotes, maxLines: 2),
          _switch('إظهار الحمامات', c.showShowers,
              (v) => p.update((x) => x.showShowers = v)),
          Row(
            children: [
              Expanded(child: _field('صباحاً من', showerMorningStart, hint: '07:00')),
              const SizedBox(width: 8),
              Expanded(child: _field('صباحاً إلى', showerMorningEnd, hint: '11:00')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _field('مساءً من', showerEveningStart, hint: '17:00')),
              const SizedBox(width: 8),
              Expanded(child: _field('مساءً إلى', showerEveningEnd, hint: '21:00')),
            ],
          ),
          _field('ملاحظات الحمامات', showerNotes, maxLines: 2),
        ]),
        _section('خريطة الإقامة والأجنحة والمرافق', [
          _switch('إظهار الخريطة في الرئيسية', c.showMap, (v) => p.update((x) => x.showMap = v)),
          _switch('إظهار الدليل', c.showGuide, (v) => p.update((x) => x.showGuide = v)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.apartment),
              label: const Text('برمجة صور الأجنحة وأرقام رؤساء الأجنحة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFacilitiesScreen()),
                );
              },
            ),
          ),
        ]),
      ],
    );
  }

  Widget _tabLinks() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('فيسبوك الإقامة', fbResidence, keyboard: TextInputType.url),
        _field('فيسبوك المديرية', fbDirection, keyboard: TextInputType.url),
        _field('فيسبوك النادي', fbClub, keyboard: TextInputType.url),
        _field('موقع المديرية', webDirection, keyboard: TextInputType.url),
        _field('بوابة PROGRES', webProgres, keyboard: TextInputType.url),
      ],
    );
  }

  Widget _tabEmergency(AppConfig c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('المصلحة الطبية', [
          _field('رقم المصلحة الطبية', medicalPhone,
              keyboard: TextInputType.phone, hint: '05xxxxxxxx'),
          const Text(
            'هذا الرقم يُستعمل في زر «اتصل الآن» داخل خدمة الصحة. إذا تُرك فارغاً يُستعمل أول رقم طوارئ أدناه.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ]),
        const Text(
          'أرقام الطوارئ (حماية مدنية، إسعاف، أمن داخلي...) — تظهر في خدمة "أرقام الطوارئ" عند كل الطلبة.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...List.generate(_emgNames.length, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.surfaceColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: _field('الاسم', _emgNames[i],
                        hint: 'الحماية المدنية')),
                const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child: _field('الرقم', _emgNumbers[i],
                        hint: '1021',
                        keyboard: TextInputType.phone)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: () => setState(() {
                    _emgNames[i].dispose();
                    _emgNumbers[i].dispose();
                    _emgNames.removeAt(i);
                    _emgNumbers.removeAt(i);
                  }),
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _emgNames.add(TextEditingController());
            _emgNumbers.add(TextEditingController());
          }),
          icon: const Icon(Icons.add),
          label: const Text('إضافة رقم'),
        ),
        const SizedBox(height: 8),
        const Text('احفظ بالزر السفلي لدفع الأرقام لكل الأجهزة.',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColor.primaryColor,
                  fontSize: 14)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      activeThumbColor: AppColor.primaryColor,
      onChanged: onChanged,
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1,
      TextInputType? keyboard,
      String? hint,
      Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Colors.white24, fontSize: 12),
              filled: true,
              fillColor: AppColor.backgroundColor,
              suffixIcon: suffix,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
