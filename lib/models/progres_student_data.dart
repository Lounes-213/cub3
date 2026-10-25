import 'dart:convert';

/// كل البيانات التي يوفّرها PROGRES للطالب، مجمّعة في كائن واحد:
/// الهوية الشخصية، التسجيلات الإدارية (dias)، التخصص (تخصص/ميدان/شعبة)،
/// المؤسسة، الطور والمستوى، الإيواء (iqama) والغرفة، المنحة،
/// الأفواج البيداغوجية، المسار الدراسي (bilans/cursus)، النقاط، والبكالوريا.
///
/// ملاحظة: PROGRES يُرجع الحقول غير الفارغة فقط، لذلك كل القراءات هنا آمنة
/// وتُرجع null عند غياب المعلومة.
class ProgresStudentData {
  final Map<String, dynamic> individu;
  final Map<String, dynamic> bac;
  final List<Map<String, dynamic>> bacNotes;
  final List<Map<String, dynamic>> registrations;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> bilans;
  final List<Map<String, dynamic>> notesCc;
  final List<Map<String, dynamic>> notesExam;
  final List<Map<String, dynamic>> coefficients;
  final List<Map<String, dynamic>> conges;
  final String? photoBase64;
  final DateTime? fetchedAt;

  ProgresStudentData({
    Map<String, dynamic>? individu,
    Map<String, dynamic>? bac,
    List<Map<String, dynamic>>? bacNotes,
    List<Map<String, dynamic>>? registrations,
    List<Map<String, dynamic>>? groups,
    List<Map<String, dynamic>>? bilans,
    List<Map<String, dynamic>>? notesCc,
    List<Map<String, dynamic>>? notesExam,
    List<Map<String, dynamic>>? coefficients,
    List<Map<String, dynamic>>? conges,
    this.photoBase64,
    this.fetchedAt,
  })  : individu = individu ?? const {},
        bac = bac ?? const {},
        bacNotes = bacNotes ?? const [],
        registrations = _sortedDias(registrations ?? const []),
        groups = groups ?? const [],
        bilans = bilans ?? const [],
        notesCc = notesCc ?? const [],
        notesExam = notesExam ?? const [],
        coefficients = coefficients ?? const [],
        conges = conges ?? const [];

  // ----------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------

  static String? _str(Map<String, dynamic>? map, String key) {
    final v = map?[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static bool? _bool(Map<String, dynamic>? map, String key) {
    final v = map?[key];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static String? _first(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static List<Map<String, dynamic>> _asList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static List<Map<String, dynamic>> _sortedDias(List<Map<String, dynamic>> list) {
    final copy = List<Map<String, dynamic>>.from(list);
    copy.sort((a, b) {
      final ya = (a['anneeAcademiqueId'] as num?)?.toInt() ?? 0;
      final yb = (b['anneeAcademiqueId'] as num?)?.toInt() ?? 0;
      return yb.compareTo(ya);
    });
    return copy;
  }

  /// أحدث تسجيل إداري (السنة الجامعية الحالية).
  Map<String, dynamic>? get currentRegistration =>
      registrations.isEmpty ? null : registrations.first;

  /// كل التسجيلات الإدارية (من الأقدم إلى الأحدث).
  List<Map<String, dynamic>> get registrationsAscending =>
      registrations.reversed.toList();

  Map<String, dynamic> get _i => individu;
  Map<String, dynamic> get _d => currentRegistration ?? const {};

  // ----------------------------------------------------------------
  // الهوية الشخصية
  // ----------------------------------------------------------------

  String? get lastNameAr =>
      _first([_str(_i, 'nomArabe'), _str(_d, 'individuNomArabe'), _str(_d, 'nomArabe')]);
  String? get firstNameAr =>
      _first([_str(_i, 'prenomArabe'), _str(_d, 'individuPrenomArabe'), _str(_d, 'prenomAr')]);
  String? get lastNameFr =>
      _first([_str(_i, 'nomLatin'), _str(_d, 'individuNomLatin'), _str(_d, 'nomFr')]);
  String? get firstNameFr =>
      _first([_str(_i, 'prenomLatin'), _str(_d, 'individuPrenomLatin'), _str(_d, 'prenomFr')]);

  String get fullNameAr =>
      '${firstNameAr ?? ''} ${lastNameAr ?? ''}'.trim();
  String get fullNameFr => '${firstNameFr ?? ''} ${lastNameFr ?? ''}'.trim();

  String? get nin => _first([_str(_i, 'identifiant'), _str(_d, 'nin'), _str(bac, 'Nin')]);
  String? get dateOfBirth =>
      _first([_str(_i, 'dateNaissance'), _str(_d, 'individuDateNaissance')]);
  String? get placeOfBirthAr => _first(
      [_str(_i, 'lieuNaissanceArabe'), _str(_d, 'individuLieuNaissanceArabe')]);
  String? get placeOfBirthFr =>
      _first([_str(_i, 'lieuNaissance'), _str(_d, 'individuLieuNaissance')]);
  String? get email => _first([_str(_i, 'email'), _str(_d, 'email')]);
  String? get phone => _first([_str(bac, 'Telephone'), _str(_d, 'telephoneBachelier')]);
  String? get address =>
      _first([_str(_d, 'adresseResidence'), _str(bac, 'adresseResidence')]);
  String? get gender =>
      _first([_str(_d, 'individuCiviliteLibelleLongAr'), _str(_d, 'etudiantCivilite')]);
  String? get nationality => _str(_d, 'individuNationaliteLibelleLongAr');
  String? get familySituation => _str(_d, 'individuSituationFamilialeLibelleLongAr');
  String? get bloodGroup => _str(_d, 'individuGroupeSanguinLibelleLongAr');
  String? get nationalService => _str(_d, 'individuServiceNationalLibelleLongAr');
  String? get fatherName => _str(_d, 'individuPrenomPereArabe') ?? _str(bac, 'prenomPere');
  String? get motherName => _first([
        (_str(_d, 'individuPrenomMereArabe') != null && _str(_d, 'individuNomMereArabe') != null)
            ? '${_str(_d, 'individuPrenomMereArabe')} ${_str(_d, 'individuNomMereArabe')}'
            : null,
        _str(bac, 'nomPrenomMere'),
      ]);
  String? get birthWilaya => _first([
        _str(_d, 'individuWilayaNaissanceLibelleLongAr'),
        _str(_d, 'individuibelleWilayaNaissance'),
      ]);

  // ----------------------------------------------------------------
  // المعلومات الجامعية (التسجيل الحالي)
  // ----------------------------------------------------------------

  String? get universityAr =>
      _first([_str(_d, 'llEtablissementArabe'), _str(_d, 'etablissementAr')]);
  String? get universityFr =>
      _first([_str(_d, 'llEtablissementLatin'), _str(_d, 'llEtablissementFr')]);
  String? get establishmentCode => _str(_d, 'refCodeEtablissement');

  /// الميدان (domaine)
  String? get domainAr =>
      _first([_str(_d, 'llDomaineArabe'), _str(_d, 'ofLlDomaineArabe'), _str(_d, 'refLibelleDomaineArabe')]);
  String? get domainFr => _first([_str(_d, 'llDomaine'), _str(_d, 'ofLlDomaine')]);

  /// الشعبة (filière)
  String? get fieldAr =>
      _first([_str(_d, 'llFiliereArabe'), _str(_d, 'ofLlFiliereArabe'), _str(_d, 'refLibelleFiliereArabe')]);
  String? get fieldFr => _first([_str(_d, 'llFiliere'), _str(_d, 'ofLlFiliere')]);

  /// التخصص (takhasus)
  String? get specialtyAr =>
      _first([_str(_d, 'ofLlSpecialiteArabe'), _str(_d, 'refLibelleSpecialiteArabe')]);
  String? get specialtyFr => _str(_d, 'ofLlSpecialite');
  String? get specialtyCode => _str(_d, 'ofCodeSpecialite');

  String? get cycleAr => _first([_str(_d, 'refLibelleCycleAr'), _str(_d, 'cycleLibelleLongAr')]);
  String? get cycleFr => _first([_str(_d, 'refLibelleCycle'), _str(_d, 'cycleLibelleLongLt')]);
  String? get levelAr => _first([_str(_d, 'niveauLibelleLongAr'), _str(_d, 'refLibelleNiveauArabe')]);
  String? get levelFr => _first([_str(_d, 'niveauLibelleLongLt'), _str(_d, 'refLibelleNiveau')]);
  int? get levelId => (_d['niveauId'] as num?)?.toInt();
  int? get offerId => (_d['ouvertureOffreFormationId'] as num?)?.toInt() ??
      (_d['offreFormationId'] as num?)?.toInt();

  String? get academicYear => _str(_d, 'anneeAcademiqueCode');
  String? get academicYearId => _str(_d, 'anneeAcademiqueId');
  String? get registrationNumber => _str(_d, 'numeroInscription');
  String? get registrationType => _str(_d, 'refLibelleTypeInscription');
  String? get registrationNature => _str(_d, 'refLibelleNatureInscription');
  String? get studentStatus => _str(_d, 'refLibelleStatutEtudiant');
  String? get registrationDate => _str(_d, 'dateInscription');
  String? get academicCenter => _str(_d, 'centreScolarite');
  String? get situation =>
      _first([_str(_d, 'situationLibelleAr'), _str(_d, 'situationLibelleFr')]);
  String? get rank => _str(_d, 'rang');
  String? get lastAverage => _str(_d, 'lastMoyenne');
  String? get bacAverageFromCard => _str(_d, 'moyenneBac');
  int? get cardId => (_d['id'] as num?)?.toInt();

  // ----------------------------------------------------------------
  // الإيواء (iqama)
  // ----------------------------------------------------------------

  bool? get accommodationRequested => _bool(_d, 'herbergementDemande');
  bool? get accommodationGranted => _bool(_d, 'herbergementAccorde');
  String? get accommodationRequestTypeAr => _str(_d, 'typeDemandeHebergementLibelleAr');
  String? get accommodationRequestTypeFr => _str(_d, 'typeDemandeHebergementLibelleFr');
  String? get accommodationTypeAr => _str(_d, 'typeHebergementLibelleAr');
  String? get accommodationTypeFr => _str(_d, 'typeHebergementLibelleFr');
  String? get accommodationPlace => _str(_d, 'lieuHebergement');
  String? get accommodationSeniority => _str(_d, 'ancienneteHebergement');
  String? get accommodationObservation => _str(_d, 'observationOnouHebergement');
  String? get accommodationScoolarityObservation =>
      _str(_d, 'observationScolariteHebergement');

  // ----------------------------------------------------------------
  // المنحة (bourse)
  // ----------------------------------------------------------------

  bool? get scholarshipRequested => _bool(_d, 'bourseDemandee');
  bool? get scholarshipGranted => _bool(_d, 'bourseAccordee');
  String? get scholarshipAmount => _str(_d, 'montantBourse');
  String? get scholarshipTypeAr => _str(_d, 'typeDemandeBourseLibelleAr');
  String? get scholarshipTypeFr => _str(_d, 'typeDemandeBourseLibelleFr');
  String? get scholarshipSeniority => _str(_d, 'ancienneteBourse');
  String? get scholarshipObservation => _str(_d, 'observationOnouBourse');

  // ----------------------------------------------------------------
  // الأفواج البيداغوجية
  // ----------------------------------------------------------------

  Map<String, dynamic>? get mainGroup => groups.isEmpty ? null : groups.first;
  String? get groupName => mainGroup == null ? null : _str(mainGroup, 'nomGroupePedagogique');
  String? get groupCode => mainGroup == null ? null : _str(mainGroup, 'codeGroupePedagogique');
  String? get sectionName => mainGroup == null ? null : _str(mainGroup, 'nomSection');
  String? get sectionCode => mainGroup == null ? null : _str(mainGroup, 'codeSection');
  String? get groupAssignmentDate =>
      mainGroup == null ? null : _str(mainGroup, 'dateAffectation');

  // ----------------------------------------------------------------
  // المسار الدراسي (cursus / bilans)
  // ----------------------------------------------------------------

  /// آخر تقرير سنوي (أحدث سنة).
  Map<String, dynamic>? get latestBilan => bilans.isEmpty ? null : bilans.first;

  String? get average => latestBilan == null
      ? null
      : _first([
          _str(latestBilan, 'formattedMG'),
          _str(latestBilan, 'moyenneGenerale'),
          _str(latestBilan, 'moyenne'),
        ]);
  String? get credits =>
      latestBilan == null ? null : _str(latestBilan, 'creditAcquis');
  String? get creditsTotal => latestBilan == null ? null : _str(latestBilan, 'credit');
  String? get decision => latestBilan == null
      ? null
      : _first([
          _str(latestBilan, 'typeDecisionLibelleAr'),
          _str(latestBilan, 'typeDecisionLibelleFr'),
        ]);
  String? get mention => latestBilan == null
      ? null
      : _first([_str(latestBilan, 'mentionLibelleAr'), _str(latestBilan, 'mentionLibelle')]);
  String? get successRate => latestBilan == null ? null : _str(latestBilan, 'tauxReussite');
  String? get promoAverage => latestBilan == null ? null : _str(latestBilan, 'moyennePromo');
  bool? get admitted => latestBilan == null ? null : _bool(latestBilan, 'admis');
  String? get bilanYear => latestBilan == null
      ? null
      : _first([_str(latestBilan, 'anneeAcademiqueCode'), _str(latestBilan, 'anneeAcademique')]);
  String? get bilanLevel =>
      latestBilan == null ? null : _str(latestBilan, 'niveauLibelleLongAr');
  String? get bilanOffer =>
      latestBilan == null ? null : _str(latestBilan, 'offreFormationLibelleAr');

  /// كل الوحدات (UE) من آخر تقرير.
  List<Map<String, dynamic>> get latestBilanUes =>
      _asList(latestBilan?['bilanUes']);

  // ----------------------------------------------------------------
  // البكالوريا
  // ----------------------------------------------------------------

  String? get bacSerie =>
      _first([_str(bac, 'libelleSerieBac'), _str(bac, 'refCodeSerieBac')]);
  String? get bacYear => _str(bac, 'anneeBac');
  String? get bacAverage => _str(bac, 'moyenneBac');
  String? get bacMatricule => _str(bac, 'Matricule');
  String? get bacSchool => _str(bac, 'refCodeEtablissement');
  String? get bacField => _str(bac, 'libelleFiliereAffectation');

  /// نقاط البكالوريا (المادة + العلامة).
  List<Map<String, dynamic>> get bacSubjects {
    final list = _asList(bac['notesBacheliers']);
    return list.isNotEmpty ? list : bacNotes;
  }

  // ----------------------------------------------------------------
  // Serialization (snapshot محلي — بدون الصورة لتفادي الحجم الكبير)
  // ----------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'individu': individu,
        'bac': bac,
        'bacNotes': bacNotes,
        'registrations': registrations,
        'groups': groups,
        'bilans': bilans,
        'notesCc': notesCc,
        'notesExam': notesExam,
        'coefficients': coefficients,
        'conges': conges,
        'fetchedAt': fetchedAt?.toIso8601String(),
      };

  static ProgresStudentData? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return ProgresStudentData(
        individu: map['individu'] is Map
            ? Map<String, dynamic>.from(map['individu'] as Map)
            : null,
        bac: map['bac'] is Map ? Map<String, dynamic>.from(map['bac'] as Map) : null,
        bacNotes: _asList(map['bacNotes']),
        registrations: _asList(map['registrations']),
        groups: _asList(map['groups']),
        bilans: _asList(map['bilans']),
        notesCc: _asList(map['notesCc']),
        notesExam: _asList(map['notesExam']),
        coefficients: _asList(map['coefficients']),
        conges: _asList(map['conges']),
        fetchedAt: DateTime.tryParse((map['fetchedAt'] ?? '').toString()),
      );
    } catch (_) {
      return null;
    }
  }
}

/// تسميات عربية لحقول PROGRES (تُستعمل لعرض «كل المعلومات» بدون فقدان أي حقل).
class ProgresLabels {
  static const Map<String, String> ar = {
    // الهوية
    'id': 'المعرّف',
    'identifiant': 'رقم التعريف الوطني',
    'nin': 'رقم التعريف الوطني',
    'dateNaissance': 'تاريخ الميلاد',
    'individuDateNaissance': 'تاريخ الميلاد',
    'nomArabe': 'اللقب (عربي)',
    'prenomArabe': 'الاسم (عربي)',
    'nomLatin': 'اللقب (لاتيني)',
    'prenomLatin': 'الاسم (لاتيني)',
    'individuNomArabe': 'اللقب (عربي)',
    'individuPrenomArabe': 'الاسم (عربي)',
    'individuNomLatin': 'اللقب (لاتيني)',
    'individuPrenomLatin': 'الاسم (لاتيني)',
    'lieuNaissance': 'مكان الميلاد',
    'lieuNaissanceArabe': 'مكان الميلاد (عربي)',
    'individuLieuNaissance': 'مكان الميلاد',
    'individuLieuNaissanceArabe': 'مكان الميلاد (عربي)',
    'email': 'البريد الإلكتروني',
    'Telephone': 'الهاتف',
    'telephoneBachelier': 'الهاتف',
    'adresseResidence': 'عنوان الإقامة',
    'sexe': 'الجنس',
    'refCodeSexe': 'رمز الجنس',
    'individuCiviliteLibelleLongAr': 'الجنس/اللقب',
    'individuNationaliteLibelleLongAr': 'الجنسية',
    'individuSituationFamilialeLibelleLongAr': 'الحالة العائلية',
    'individuGroupeSanguinLibelleLongAr': 'الزمرة الدموية',
    'individuServiceNationalLibelleLongAr': 'الخدمة الوطنية',
    'individuPrenomPereArabe': 'اسم الأب',
    'individuPrenomMereArabe': 'اسم الأم',
    'individuNomMereArabe': 'لقب الأم',
    'individuWilayaNaissanceLibelleLongAr': 'ولاية الميلاد',
    // المؤسسة والدراسة
    'llEtablissementArabe': 'المؤسسة',
    'llEtablissementLatin': 'المؤسسة (لاتيني)',
    'refCodeEtablissement': 'رمز المؤسسة',
    'anneeAcademiqueCode': 'السنة الجامعية',
    'anneeAcademiqueId': 'معرّف السنة الجامعية',
    'refLibelleCycle': 'الطور',
    'refLibelleCycleAr': 'الطور',
    'refLibelleNiveau': 'المستوى',
    'niveauLibelleLongAr': 'المستوى',
    'niveauLibelleLongLt': 'المستوى (لاتيني)',
    'niveauId': 'معرّف المستوى',
    'niveauRang': 'رتبة المستوى',
    'llDomaine': 'الميدان',
    'llDomaineArabe': 'الميدان',
    'ofLlDomaine': 'الميدان',
    'ofLlDomaineArabe': 'الميدان',
    'llFiliere': 'الشعبة',
    'llFiliereArabe': 'الشعبة',
    'ofLlFiliere': 'الشعبة',
    'ofLlFiliereArabe': 'الشعبة',
    'ofLlSpecialite': 'التخصص',
    'ofLlSpecialiteArabe': 'التخصص',
    'ofCodeSpecialite': 'رمز التخصص',
    'refLibelleSpecialiteArabe': 'التخصص',
    'numeroInscription': 'رقم التسجيل',
    'numeroMatricule': 'رقم التسجيل',
    'refLibelleTypeInscription': 'نوع التسجيل',
    'refLibelleNatureInscription': 'طبيعة التسجيل',
    'refLibelleStatutEtudiant': 'صفة الطالب',
    'dateInscription': 'تاريخ التسجيل',
    'centreScolarite': 'مركز التمدرس',
    'rang': 'الرتبة',
    'situationLibelleAr': 'الوضعية',
    'situationLibelleFr': 'الوضعية (فرنسي)',
    'lastMoyenne': 'آخر معدل',
    'moyenneBac': 'معدل البكالوريا',
    'typeDossierLibelleAr': 'نوع الملف',
    'offreFormationLibelleAr': 'عرض التكوين',
    'offreFormationLibelleFr': 'عرض التكوين (فرنسي)',
    'ouvertureOffreFormationId': 'معرّف عرض التكوين',
    'offreFormationId': 'معرّف عرض التكوين',
    // الإيواء
    'herbergementDemande': 'طلب الإيواء',
    'herbergementAccorde': 'الإيواء مقبول',
    'typeDemandeHebergementLibelleAr': 'نوع طلب الإيواء',
    'typeHebergementLibelleAr': 'نوع الإيواء',
    'typeHebergementLibelleFr': 'نوع الإيواء (فرنسي)',
    'lieuHebergement': 'مكان الإيواء',
    'ancienneteHebergement': 'أقدمية الإيواء',
    'observationOnouHebergement': 'ملاحظة الديوان',
    'observationScolariteHebergement': 'ملاحظة التمدرس',
    // المنحة
    'bourseDemandee': 'طلب المنحة',
    'bourseAccordee': 'المنحة مقبولة',
    'montantBourse': 'مبلغ المنحة',
    'ancienneteBourse': 'أقدمية المنحة',
    'observationOnouBourse': 'ملاحظة المنحة',
    // البكالوريا
    'Matricule': 'رقم تسجيل البكالوريا',
    'matriculeBac': 'رقم تسجيل البكالوريا',
    'anneeBac': 'سنة البكالوريا',
    'libelleSerieBac': 'الشعبة',
    'libelleVilleNaissance': 'مدينة الميلاد',
    'libelleFiliereAffectation': 'التوجيه',
    'Note': 'العلامة',
    'refCodeMatiereLibelleFr': 'المادة',
    // الأفواج
    'nomGroupePedagogique': 'الفوج البيداغوجي',
    'codeGroupePedagogique': 'رمز الفوج',
    'nomSection': 'القسم',
    'codeSection': 'رمز القسم',
    'dateAffectation': 'تاريخ التوجيه',
    // المسار الدراسي
    'formattedMG': 'المعدل العام',
    'moyenneGenerale': 'المعدل العام',
    'moyenne': 'المعدل',
    'moyenneSn': 'معدل الدورة العادية',
    'credit': 'الأرصدة',
    'creditAcquis': 'الأرصدة المكتسبة',
    'creditObtenu': 'الأرصدة المحصلة',
    'cumulCreditPrecedent': 'الأرصدة السابقة',
    'typeDecisionLibelleAr': 'القرار',
    'mentionLibelleAr': 'التقدير',
    'mentionLibelle': 'التقدير',
    'tauxReussite': 'نسبة النجاح',
    'moyennePromo': 'معدل الدفعة',
    'admis': 'ناجح',
    'sessionIntitule': 'الدورة',
    'periodeLibelleAr': 'الدورة',
    'periodeLibelleFr': 'الدورة (فرنسي)',
    'noteExamen': 'نقطة الامتحان',
    'note': 'النقطة',
    'rattachementMcMcLibelleAr': 'المقياس',
    'mcLibelleAr': 'المقياس',
    'rattachementMcCoefficient': 'المعامل',
    'rattachementMcCredit': 'الأرصدة',
    'ueCode': 'رمز الوحدة',
    'planningSessionIntitule': 'الدورة',
    'absent': 'غائب',
    'observation': 'ملاحظة',
  };

  static String label(String key) => ar[key] ?? key;

  /// يُرجع التسمية العربية إذا وُجدت، وإلا ينسّق المفتاح الخام.
  static String displayKey(String key) {
    final known = ar[key];
    if (known != null) return known;
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced;
  }

  /// هل القيمة قابلة للعرض كنص مفرد؟
  static bool isScalar(dynamic v) =>
      v == null || v is String || v is num || v is bool;
}
