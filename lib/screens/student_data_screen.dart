import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/progres_student_data.dart';
import '../providers/user_provider.dart';
import '../theme/theme.dart';

/// شاشة «معلوماتي الجامعية» — كل ما يوفّره PROGRES للطالب:
/// الهوية، التخصص والميدان والشعبة، المؤسسة، الطور والمستوى،
/// الإيواء (iqama) والغرفة، المنحة، كل التسجيلات الإدارية،
/// الأفواج البيداغوجية، المسار الدراسي (cursus)، النقاط، والبكالوريا.
class StudentDataScreen extends StatefulWidget {
  const StudentDataScreen({super.key});

  @override
  State<StudentDataScreen> createState() => _StudentDataScreenState();
}

class _StudentDataScreenState extends State<StudentDataScreen> {
  bool _loading = false;
  bool _requestedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureData());
  }

  Future<void> _ensureData() async {
    final user = context.read<UserProvider>();
    if (user.studentData != null || _requestedOnce) return;
    _requestedOnce = true;
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await context.read<UserProvider>().refreshStudentData();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final data = user.studentData;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('معلوماتي الجامعية'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديث من PROGRES',
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: data == null
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  _buildHeader(user, data),
                  const SizedBox(height: 16),
                  ..._buildSections(data, user),
                  const SizedBox(height: 24),
                  _buildRawSection(data),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------------------
  // حالات فارغة / رأس الصفحة
  // ----------------------------------------------------------------

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'لم تُحمَّل بعد بياناتك من PROGRES',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط على الزر لجلب التسجيلات، التخصص، الإيواء والمسار الدراسي',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _refresh,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: const Text('جلب البيانات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserProvider user, ProgresStudentData data) {
    final fetched = data.fetchedAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColor.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.fullNameAr.isNotEmpty ? data.fullNameAr : user.fullNameAr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    data.specialtyAr,
                    data.levelAr,
                    data.academicYear,
                  ].whereType<String>().join(' • '),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (fetched != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'آخر تحديث: ${fetched.toString().split('.').first}',
                      style: const TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // الأقسام
  // ----------------------------------------------------------------

  List<Widget> _buildSections(ProgresStudentData data, UserProvider user) {
    final widgets = <Widget>[];

    widgets.add(_section(
      'الملف الشخصي',
      Icons.person_outline,
      [
        _kv('الاسم الكامل (عربي)', data.fullNameAr),
        _kv('الاسم الكامل (لاتيني)', data.fullNameFr),
        _kv('تاريخ الميلاد', data.dateOfBirth),
        _kv('مكان الميلاد', data.placeOfBirthAr ?? data.placeOfBirthFr),
        _kv('ولاية الميلاد', data.birthWilaya),
        _kv('رقم التعريف الوطني', data.nin),
        _kv('الجنس', data.gender),
        _kv('الهاتف', data.phone),
        _kv('البريد الإلكتروني', data.email),
        _kv('عنوان الإقامة', data.address),
        _kv('الجنسية', data.nationality),
        _kv('الحالة العائلية', data.familySituation),
        _kv('الزمرة الدموية', data.bloodGroup),
        _kv('الخدمة الوطنية', data.nationalService),
        _kv('اسم الأب', data.fatherName),
        _kv('اسم الأم', data.motherName),
      ],
    ));

    widgets.add(_section(
      'المعلومات الجامعية',
      Icons.school_outlined,
      [
        _kv('المؤسسة', data.universityAr ?? data.universityFr),
        _kv('الميدان', data.domainAr ?? data.domainFr),
        _kv('الشعبة', data.fieldAr ?? data.fieldFr),
        _kv('التخصص', data.specialtyAr ?? data.specialtyFr, highlight: true),
        _kv('رمز التخصص', data.specialtyCode),
        _kv('الطور', data.cycleAr ?? data.cycleFr),
        _kv('المستوى', data.levelAr ?? data.levelFr),
        _kv('السنة الجامعية', data.academicYear),
        _kv('رقم التسجيل', data.registrationNumber),
        _kv('نوع التسجيل', data.registrationType),
        _kv('طبيعة التسجيل', data.registrationNature),
        _kv('صفة الطالب', data.studentStatus),
        _kv('تاريخ التسجيل', data.registrationDate),
        _kv('مركز التمدرس', data.academicCenter),
        _kv('الوضعية', data.situation),
        _kv('الرتبة', data.rank),
        _kv('آخر معدل', data.lastAverage),
        _kv('الفوج البيداغوجي', data.groupName),
        _kv('القسم', data.sectionName),
        _kv('تاريخ التوجيه', data.groupAssignmentDate),
      ],
    ));

    widgets.add(_section(
      'الإيواء والمنحة',
      Icons.hotel_outlined,
      [
        _kv('طلب الإيواء', _yesNo(data.accommodationRequested)),
        _kv('الإيواء مقبول', _yesNo(data.accommodationGranted)),
        _kv('نوع طلب الإيواء', data.accommodationRequestTypeAr),
        _kv('نوع الإيواء', data.accommodationTypeAr ?? data.accommodationTypeFr),
        _kv('مكان الإيواء', data.accommodationPlace),
        _kv('أقدمية الإيواء', data.accommodationSeniority),
        _kv('ملاحظة الديوان', data.accommodationObservation),
        _kv('ملاحظة التمدرس', data.accommodationScoolarityObservation),
        _kv('رقم الغرفة', user.roomNumber, highlight: true),
        _kv('مقيم منذ', user.residentSince),
        _kv('طلب المنحة', _yesNo(data.scholarshipRequested)),
        _kv('المنحة مقبولة', _yesNo(data.scholarshipGranted)),
        _kv('مبلغ المنحة', data.scholarshipAmount),
        _kv('نوع المنحة', data.scholarshipTypeAr ?? data.scholarshipTypeFr),
        _kv('أقدمية المنحة', data.scholarshipSeniority),
        _kv('ملاحظة المنحة', data.scholarshipObservation),
      ],
    ));

    if (data.bilans.isNotEmpty) {
      widgets.add(_section(
        'المسار الدراسي (cursus)',
        Icons.timeline,
        [
          for (final b in data.bilans) _bilanTile(b),
        ],
      ));
    }

    if (data.registrations.isNotEmpty) {
      widgets.add(_section(
        'كل التسجيلات الإدارية',
        Icons.assignment_outlined,
        [
          for (final d in data.registrationsAscending) _registrationTile(d),
        ],
      ));
    }

    if (data.groups.isNotEmpty) {
      widgets.add(_section(
        'الأفواج البيداغوجية',
        Icons.groups_outlined,
        [
          for (final g in data.groups)
            _rawTile(
              title: _fmt(g['nomGroupePedagogique']) ?? 'فوج',
              subtitle: [
                _fmt(g['nomSection']),
                _fmt(g['periodeLibelleLongLt']),
              ].whereType<String>().join(' • '),
              map: g,
            ),
        ],
      ));
    }

    if (data.notesCc.isNotEmpty || data.notesExam.isNotEmpty) {
      widgets.add(_section(
        'النقاط',
        Icons.grade_outlined,
        [
          if (data.notesCc.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('الأعمال الموجهة / المراقبة المستمرة',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            for (final n in data.notesCc)
              _gradeRow(
                title: _fmt(n['rattachementMcMcLibelleAr']) ??
                    _fmt(n['rattachementMcMcLibelleFr']) ??
                    'مقياس',
                subtitle: _fmt(n['llPeriodeAr']) ?? _fmt(n['llPeriode']),
                note: n['absent'] == true ? 'غائب' : _fmt(n['note']),
              ),
            const SizedBox(height: 12),
          ],
          if (data.notesExam.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('نقاط الامتحانات',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            for (final n in data.notesExam)
              _gradeRow(
                title: _fmt(n['mcLibelleAr']) ?? _fmt(n['mcLibelleFr']) ?? 'مقياس',
                subtitle: _fmt(n['planningSessionIntitule']),
                note: _fmt(n['noteExamen']),
              ),
          ],
        ],
      ));
    }

    if (data.bac.isNotEmpty || data.bacSubjects.isNotEmpty) {
      widgets.add(_section(
        'شهادة البكالوريا',
        Icons.workspace_premium_outlined,
        [
          _kv('الشعبة', data.bacSerie),
          _kv('سنة البكالوريا', data.bacYear),
          _kv('المعدل', data.bacAverage),
          _kv('رقم تسجيل البكالوريا', data.bacMatricule),
          _kv('التوجيه', data.bacField),
          if (data.bacSubjects.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 24),
            const Text('نقاط المواد',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            for (final s in data.bacSubjects)
              _gradeRow(
                title: _fmt(s['refCodeMatiereLibelleFr']) ?? 'مادة',
                subtitle: _fmt(s['AnneeBac']),
                note: _fmt(s['Note']),
              ),
          ],
        ],
      ));
    }

    if (data.conges.isNotEmpty) {
      widgets.add(_section(
        'العطل الأكاديمية',
        Icons.event_busy_outlined,
        [
          for (final c in data.conges)
            _rawTile(
              title: _fmt(c['anneeAcademiqueCode']) ?? 'عطلة',
              subtitle: [
                _fmt(c['ncTypeCongeLibelleLongFr']),
                _fmt(c['dateDebutAccordee']),
                _fmt(c['dateFinAccordee']),
              ].whereType<String>().join(' • '),
              map: c,
            ),
        ],
      ));
    }

    return widgets;
  }

  Widget _bilanTile(Map<String, dynamic> b) {
    final ues = b['bilanUes'];
    return _rawTile(
      title: [
        _fmt(b['anneeAcademiqueCode']),
        _fmt(b['niveauLibelleLongAr']),
      ].whereType<String>().join(' • '),
      subtitle: [
        if (_fmt(b['formattedMG']) != null || _fmt(b['moyenne']) != null)
          'المعدل: ${_fmt(b['formattedMG']) ?? _fmt(b['moyenne'])}',
        if (_fmt(b['creditAcquis']) != null || _fmt(b['credit']) != null)
          'الأرصدة: ${_fmt(b['creditAcquis']) ?? '-'}/${_fmt(b['credit']) ?? '-'}',
        if (_fmt(b['typeDecisionLibelleAr']) != null)
          'القرار: ${_fmt(b['typeDecisionLibelleAr'])}',
        if (_fmt(b['mentionLibelleAr']) != null || _fmt(b['mentionLibelle']) != null)
          'التقدير: ${_fmt(b['mentionLibelleAr']) ?? _fmt(b['mentionLibelle'])}',
        if (_fmt(b['tauxReussite']) != null) 'نسبة النجاح: ${_fmt(b['tauxReussite'])}',
      ].join('\n'),
      map: b,
      extra: ues is List && ues.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('الوحدات (UE)',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                for (final u in ues.whereType<Map>())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      [
                        _fmt(u['ueLibelleAr']) ?? _fmt(u['ueLibelleFr']) ?? _fmt(u['ueCode']),
                        if (_fmt(u['moyenneUe']) != null) 'معدل: ${_fmt(u['moyenneUe'])}',
                        if (_fmt(u['creditAcquis']) != null)
                          'أرصدة: ${_fmt(u['creditAcquis'])}',
                      ].whereType<String>().join(' • '),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _registrationTile(Map<String, dynamic> d) {
    final title = [
      _fmt(d['anneeAcademiqueCode']),
      _fmt(d['ofLlSpecialiteArabe']) ?? _fmt(d['ofLlSpecialite']),
    ].whereType<String>().join(' • ');
    return _rawTile(
      title: title.isEmpty ? 'تسجيل' : title,
      subtitle: [
        if (_fmt(d['llEtablissementArabe']) != null) _fmt(d['llEtablissementArabe'])!,
        if (_fmt(d['refLibelleNiveau']) != null) _fmt(d['refLibelleNiveau'])!,
        if (_fmt(d['numeroInscription']) != null)
          'رقم التسجيل: ${_fmt(d['numeroInscription'])}',
        if (_fmt(d['refLibelleTypeInscription']) != null)
          _fmt(d['refLibelleTypeInscription'])!,
        if (d['herbergementAccorde'] == true)
          'الإيواء: ${_fmt(d['typeHebergementLibelleAr']) ?? 'مقبول'}',
      ].join('\n'),
      map: d,
    );
  }

  Widget _buildRawSection(ProgresStudentData data) {
    final current = data.currentRegistration;
    if (current == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColor.primaryColor,
        collapsedIconColor: Colors.white38,
        title: const Text(
          'كل حقول التسجيل الحالي (خام)',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: _rawRows(current),
      ),
    );
  }

  // ----------------------------------------------------------------
  // عناصر مساعدة
  // ----------------------------------------------------------------

  Widget _section(String title, IconData icon, List<Widget> children) {
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColor.primaryColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  /// صف مفتاح/قيمة — يُرجع SizedBox فارغاً إذا كانت القيمة غائبة.
  Widget _kv(String label, String? value, {bool highlight = false}) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value.trim(),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: highlight ? AppColor.primaryColor : Colors.white,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rawTile({
    required String title,
    required String subtitle,
    required Map<String, dynamic> map,
    Widget? extra,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        iconColor: AppColor.primaryColor,
        collapsedIconColor: Colors.white24,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
              ),
        children: [
          ?extra,
          ..._rawRows(map),
        ],
      ),
    );
  }

  /// يعرض كل الحقول الخام غير الفارغة (حتى لا تُفقد أي معلومة من PROGRES).
  List<Widget> _rawRows(Map<String, dynamic> map) {
    final rows = <Widget>[];
    map.forEach((key, value) {
      if (!ProgresLabels.isScalar(value)) return;
      final text = _fmt(value);
      if (text == null || text.isEmpty) return;
      rows.add(_kv(ProgresLabels.displayKey(key), text));
    });
    return rows;
  }

  Widget _gradeRow({required String title, String? subtitle, String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              note ?? '—',
              style: const TextStyle(
                color: AppColor.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _fmt(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v ? 'نعم' : 'لا';
    if (v is double) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toString();
    }
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static String? _yesNo(bool? v) {
    if (v == null) return null;
    return v ? 'نعم' : 'لا';
  }
}
