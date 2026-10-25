import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/utils/photo_utils.dart';
import '../models/progres_student_data.dart';
import 'firebase_service.dart';

/// Service to interact with the PROGRES/WebEtu API
/// Endpoints verified from open-source AliAkrem/progres (MIT License)
/// Base URL: https://progres.mesrs.dz/api
///
/// LOGIN RULE (strict): a student MUST exist in PROGRES, otherwise no entry.
/// - Mobile/desktop: direct PROGRES calls.
/// - Web: same verification via our Cloudflare Worker proxy (browser CORS).
/// - Staff accounts (admin/staf/trav stored in D1) log in locally (no PROGRES).
class ProgresApiService {
  static const String baseUrl = "https://progres.mesrs.dz/api";

  /// Web browsers can't call PROGRES directly (CORS) -> Worker proxy.
  static bool get _viaProxy => kIsWeb;
  final ApiClient _proxy = ApiClient();
  
  String? _authToken;
  String? _uuid;
  String? _userName;
  
  // Student profile data
  String? _firstNameAr;
  String? _lastNameAr;
  String? _firstNameFr;
  String? _lastNameFr;
  String? _levelAr;     // المستوى بالعربية (السنة الأولى ليسانس...)
  String? _levelFr;     // المستوى بالفرنسية
  String? _cycleAr;     // الطور (ليسانس/ماستر/دكتوراه)
  String? _cycleFr;     
  String? _registrationNumber; // رقم التسجيل
  String? _photo;       // صورة الطالب (Base64)
  String? _dateOfBirth;
  String? _placeOfBirthAr;
  String? _role;
  bool _isActive = true;

  /// كل بيانات PROGRES (الهوية، التسجيلات، التخصص، الإيواء، المسار الدراسي...)
  ProgresStudentData? _studentData;

  /// يُنادى بعد كل تحديث ناجح للبيانات الكاملة (لتحديث الواجهة).
  void Function()? onStudentDataUpdated;

  // Login using official PROGRES REST API (POST /authentication/v1/)
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (_viaProxy) return _loginViaProxy(username, password);
    return _loginDirectApi(username, password);
  }

  // POST /authentication/v1/ — REAL PROGRES verification (no bypass).
  // Returns success only if the account truly exists in PROGRES.
  Future<Map<String, dynamic>> _loginDirectApi(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/authentication/v1/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        _uuid = data['uuid'];
        _userName = data['userName'];

        // Save session locally (only username and password as requested)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);

        return {
          "success": true,
          "message": "تم تسجيل الدخول بنجاح",
        };
      } else if (response.statusCode == 401) {
        return {"success": false, "code": "INVALID_CREDENTIALS", "message": "اسم المستخدم أو كلمة المرور غير صحيحة"};
      } else {
        return {"success": false, "code": "PROGRES_ERROR", "message": "خطأ في السيرفر: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "code": "NETWORK", "message": "تعذر الاتصال بالسيرفر"};
    }
  }

  /// Web login through our Worker proxy (official POST /authentication/v1/ with CORS handling).
  Future<Map<String, dynamic>> _loginViaProxy(String username, String password) async {
    try {
      final res = await _proxy.post(ApiConstants.progresLogin, body: {
        "username": username,
        "password": password,
      });
      if (res != null && res['success'] == true) {
        _authToken = res['token'];
        _uuid = res['uuid']?.toString();
        _userName = res['userName'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);

        return {"success": true, "message": "تم تسجيل الدخول بنجاح"};
      }
      return {
        "success": false,
        "code": "INVALID_CREDENTIALS",
        "message": res?['message'] ?? "اسم المستخدم أو كلمة المرور غير صحيحة"
      };
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('غير صحيحة')) {
        return {
          "success": false,
          "code": "INVALID_CREDENTIALS",
          "message": "اسم المستخدم أو كلمة المرور غير صحيحة"
        };
      }
      return {
        "success": false,
        "code": "NETWORK",
        "message": "تعذر الاتصال بسيرفر PROGRES حالياً"
      };
    }
  }

  Map<String, String> get _proxyAuthHeader => {'authorization': _authToken ?? ''};

  // ----------------------------------------------------------------
  // جلب كل بيانات PROGRES المتوفرة للطالب
  // ----------------------------------------------------------------

  static const String _studentDataKey = 'progres_student_data_snapshot';

  /// قراءة عامة من PROGRES (مباشرة على الهاتف/الحاسوب، عبر وسيط الـ Worker على الويب).
  /// لا ترمي استثناء أبداً: تُرجع null عند أي فشل حتى لا تُفقد بقية البيانات.
  Future<dynamic> _getProgres(String directPath, String proxyUrl) async {
    try {
      if (_viaProxy) {
        final res = await _proxy.get(proxyUrl, headers: _proxyAuthHeader);
        if (res != null && res['success'] == true) return res['data'];
        return null;
      }
      final r = await http.get(
        Uri.parse('$baseUrl$directPath'),
        headers: {'authorization': _authToken!},
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return null;
      final decoded = jsonDecode(r.body);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _mapOf(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _listOf(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// يجلب كل بيانات الطالب من PROGRES: الهوية، البكالوريا، كل التسجيلات
  /// الإدارية (مع الإيواء والتخصص)، الأفواج، المسار الدراسي، النقاط، والمعاملات.
  Future<ProgresStudentData?> fetchStudentData() async {
    if (_authToken == null || _uuid == null) return _studentData;
    final uuid = _uuid!;

    // الموجة 1 — مصادر مستقلة تُجلب بالتوازي.
    final wave1 = await Future.wait([
      _getProgres('/infos/bac/$uuid/individu', '${ApiConstants.progresIndividu}/$uuid'),
      _getProgres('/infos/bac/$uuid/', '${ApiConstants.progresBac}/$uuid'),
      _getProgres('/infos/bac/$uuid/dias', '${ApiConstants.progresDias}/$uuid'),
      _getProgres('/infos/bac/$uuid/notes', '${ApiConstants.progresBacNotes}/$uuid'),
    ]);

    final individu = _mapOf(wave1[0]);
    final bac = _mapOf(wave1[1]);
    final dias = _listOf(wave1[2]);
    final bacNotes = _listOf(wave1[3]);

    if (individu.isEmpty && bac.isEmpty && dias.isEmpty && _studentData != null) {
      return _studentData; // فشل الشبكة — نبقي البيانات القديمة
    }

    // أحدث تسجيل إداري (أكبر سنة جامعية) = التسجيل الحالي.
    int? diaId;
    int bestYear = -1;
    int? offerId;
    int? levelId;
    for (final d in dias) {
      final y = (d['anneeAcademiqueId'] as num?)?.toInt() ?? 0;
      final id = (d['id'] as num?)?.toInt();
      if (id != null && y >= bestYear) {
        bestYear = y;
        diaId = id;
        offerId = (d['ouvertureOffreFormationId'] as num?)?.toInt() ??
            (d['offreFormationId'] as num?)?.toInt();
        levelId = (d['niveauId'] as num?)?.toInt();
      }
    }

    // الموجة 2 — تفاصيل التسجيل الحالي.
    List<Map<String, dynamic>> groups = [];
    List<Map<String, dynamic>> bilans = [];
    List<Map<String, dynamic>> notesCc = [];
    List<Map<String, dynamic>> notesExam = [];
    List<Map<String, dynamic>> coefficients = [];
    if (diaId != null) {
      final wave2 = await Future.wait([
        _getProgres('/infos/dia/$diaId/groups', '${ApiConstants.progresGroups}/$diaId'),
        _getProgres('/infos/bac/$uuid/dias/$diaId/periode/bilans',
            '${ApiConstants.progresBilans}/$uuid/$diaId'),
        _getProgres('/infos/controleContinue/dia/$diaId/notesCC',
            '${ApiConstants.progresNotesCc}/$diaId'),
        _getProgres('/infos/planningSession/dia/$diaId/noteExamens',
            '${ApiConstants.progresNotesExam}/$diaId'),
        (offerId != null && levelId != null)
            ? _getProgres('/infos/offreFormation/$offerId/niveau/$levelId/Coefficients',
                '${ApiConstants.progresCoefficients}/$offerId/$levelId')
            : Future<dynamic>.value(null),
      ]);
      groups = _listOf(wave2[0]);
      bilans = _listOf(wave2[1]);
      notesCc = _listOf(wave2[2]);
      notesExam = _listOf(wave2[3]);
      coefficients = _listOf(wave2[4]);
    }

    // العطل الأكاديمية — فقط للسنوات التي فيها إشارة إلى عطلة (بالتوازي).
    final congeYears = <int>[];
    for (final d in dias) {
      if (d['congeAcademiqueId'] == null) continue;
      final year = (d['anneeAcademiqueId'] as num?)?.toInt();
      if (year != null && !congeYears.contains(year)) congeYears.add(year);
    }
    final conges = <Map<String, dynamic>>[];
    if (congeYears.isNotEmpty) {
      final wave3 = await Future.wait([
        for (final year in congeYears.take(4))
          _getProgres(
            '/infos/bac/$uuid/anneeAcademique/$year/congeacademique',
            '${ApiConstants.progresConge}/$uuid/$year',
          ),
      ]);
      for (final res in wave3) {
        conges.addAll(_listOf(res));
      }
    }

    // الهوية من نقطة individu (مصدر أدق) مع الاحتفاظ بباقي الحقول.
    if (individu.isNotEmpty) {
      _firstNameAr = individu['prenomArabe'] ?? _firstNameAr;
      _lastNameAr = individu['nomArabe'] ?? _lastNameAr;
      _firstNameFr = individu['prenomLatin'] ?? _firstNameFr;
      _lastNameFr = individu['nomLatin'] ?? _lastNameFr;
      _dateOfBirth = individu['dateNaissance'] ?? _dateOfBirth;
      _placeOfBirthAr = individu['lieuNaissanceArabe'] ?? _placeOfBirthAr;
    }

    final data = ProgresStudentData(
      individu: individu,
      bac: bac,
      bacNotes: bacNotes,
      registrations: dias,
      groups: groups,
      bilans: bilans,
      notesCc: notesCc,
      notesExam: notesExam,
      coefficients: coefficients,
      conges: conges,
      photoBase64: _photo,
      fetchedAt: DateTime.now(),
    );

    // تعبئة الحقول الأساسية إن كانت فارغة (المستوى/الطور/رقم التسجيل).
    _levelAr ??= data.levelAr;
    _levelFr ??= data.levelFr;
    _cycleAr ??= data.cycleAr;
    _cycleFr ??= data.cycleFr;
    _registrationNumber ??= data.registrationNumber;

    _studentData = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveStudentDataSnapshot(prefs, data);
    } catch (_) {}
    onStudentDataUpdated?.call();
    return data;
  }

  Future<void> _saveStudentDataSnapshot(
      SharedPreferences prefs, ProgresStudentData data) async {
    try {
      await prefs.setString(_studentDataKey, jsonEncode(data.toJson()));
    } catch (_) {}
  }

  /// استرجاع البيانات الكاملة من النسخة المحلية (بلا شبكة).
  void hydrateStudentData(SharedPreferences prefs) {
    if (_studentData != null) return;
    try {
      final raw = prefs.getString(_studentDataKey);
      final data = ProgresStudentData.fromJsonString(raw);
      if (data != null) _studentData = data;
    } catch (_) {}
  }

  ProgresStudentData? get studentData => _studentData;

  String? get specialtyAr => _studentData?.specialtyAr;
  String? get specialtyFr => _studentData?.specialtyFr;
  String? get domainAr => _studentData?.domainAr;
  String? get fieldAr => _studentData?.fieldAr;
  String? get universityAr => _studentData?.universityAr;
  String? get academicYear => _studentData?.academicYear;
  String? get email => _studentData?.email;
  String? get groupName => _studentData?.groupName;
  String? get sectionName => _studentData?.sectionName;

  // GET /infos/bac/{uuid}/individu — Basic student info (name, DOB, birthplace)
  Future<Map<String, dynamic>> fetchBasicInfo() async {
    if (_authToken == null || _uuid == null) {
      return {"success": false, "message": "يجب تسجيل الدخول أولاً"};
    }
    if (_viaProxy) {
      try {
        final res = await _proxy.get('${ApiConstants.progresIndividu}/$_uuid',
            headers: _proxyAuthHeader);
        if (res != null && res['success'] == true) {
          final data = res['data'];
          _applyBasicInfo(data);
          return {"success": true, "data": data};
        }
        return {"success": false, "message": "خطأ في جلب المعلومات"};
      } catch (_) {
        return {"success": false, "message": "خطأ في جلب المعلومات"};
      }
    }
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/infos/bac/$_uuid/individu"),
        headers: {"authorization": _authToken!},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _firstNameAr = data['prenomArabe'];
        _lastNameAr = data['nomArabe'];
        _firstNameFr = data['prenomLatin'];
        _lastNameFr = data['nomLatin'];
        _dateOfBirth = data['dateNaissance'];
        _placeOfBirthAr = data['lieuNaissanceArabe'];

        // Profile data is no longer saved in SharedPreferences

        return {"success": true, "data": data};
      }
      return {"success": false, "message": "خطأ: ${response.statusCode}"};
    } catch (e) {
      return {"success": false, "message": "خطأ في جلب المعلومات"};
    }
  }

  void _applyBasicInfo(dynamic data) {
    _firstNameAr = data['prenomArabe'];
    _lastNameAr = data['nomArabe'];
    _firstNameFr = data['prenomLatin'];
    _lastNameFr = data['nomLatin'];
    _dateOfBirth = data['dateNaissance'];
    _placeOfBirthAr = data['lieuNaissanceArabe'];
  }

  void _applyDetailedInfo(dynamic data) {
    _levelAr = data['niveauLibelleLongAr'];
    _levelFr = data['niveauLibelleLongLt'];
    _cycleAr = data['refLibelleCycleAr'];
    _cycleFr = data['refLibelleCycle'];
    _registrationNumber = data['numeroInscription'];
  }

  int _latestYearId(List<dynamic> enrollments) {
    int maxYearId = 0;
    for (var e in enrollments) {
      final yearId = e['anneeAcademiqueId'] as int? ?? 0;
      if (yearId > maxYearId) maxYearId = yearId;
    }
    return maxYearId;
  }
  // GET /infos/bac/{uuid}/dias — Get enrollments to find current academic year
  // GET /infos/bac/{uuid}/anneeAcademique/{yearId}/dia — Detailed info (level, cycle, specialty)
  Future<Map<String, dynamic>> fetchDetailedInfo() async {
    if (_authToken == null || _uuid == null) {
      return {"success": false, "message": "يجب تسجيل الدخول أولاً"};
    }
    if (_viaProxy) {
      try {
        final enrollRes = await _proxy.get('${ApiConstants.progresDias}/$_uuid',
            headers: _proxyAuthHeader);
        final List<dynamic> enrollments =
            (enrollRes?['data'] as List?) ?? [];
        if (enrollments.isEmpty) {
          return {"success": false, "message": "لا توجد تسجيلات"};
        }
        final maxYearId = _latestYearId(enrollments);
        final detailRes = await _proxy.get(
            '${ApiConstants.progresDia}/$_uuid/$maxYearId',
            headers: _proxyAuthHeader);
        if (detailRes != null && detailRes['success'] == true) {
          final data = detailRes['data'];
          _applyDetailedInfo(data);
          return {"success": true, "data": data};
        }
        return {"success": false, "message": "خطأ في جلب التفاصيل"};
      } catch (_) {
        return {"success": false, "message": "خطأ في جلب التفاصيل"};
      }
    }
    try {
      // Step 1: Get enrollments to find the current year
      final enrollRes = await http.get(
        Uri.parse("$baseUrl/infos/bac/$_uuid/dias"),
        headers: {"authorization": _authToken!},
      ).timeout(const Duration(seconds: 15));

      if (enrollRes.statusCode != 200) {
        return {"success": false, "message": "خطأ في جلب التسجيلات"};
      }

      final List<dynamic> enrollments = jsonDecode(enrollRes.body);
      if (enrollments.isEmpty) {
        return {"success": false, "message": "لا توجد تسجيلات"};
      }

      // Find the latest enrollment (biggest anneeAcademiqueId)
      int maxYearId = 0;
      for (var e in enrollments) {
        final yearId = e['anneeAcademiqueId'] as int? ?? 0;
        if (yearId > maxYearId) maxYearId = yearId;
      }

      // Step 2: Get detailed info for that year
      final detailRes = await http.get(
        Uri.parse("$baseUrl/infos/bac/$_uuid/anneeAcademique/$maxYearId/dia"),
        headers: {"authorization": _authToken!},
      ).timeout(const Duration(seconds: 15));

      if (detailRes.statusCode == 200) {
        final data = jsonDecode(detailRes.body);
        _levelAr = data['niveauLibelleLongAr'];
        _levelFr = data['niveauLibelleLongLt'];
        _cycleAr = data['refLibelleCycleAr'];
        _cycleFr = data['refLibelleCycle'];
        _registrationNumber = data['numeroInscription'];
        // Note: data['photo'] is a file path, not Base64. Actual image from /infos/image/{uuid}

        // Profile data is no longer saved in SharedPreferences

        return {"success": true, "data": data};
      }
      return {"success": false, "message": "خطأ: ${detailRes.statusCode}"};
    } catch (e) {
      return {"success": false, "message": "خطأ في جلب التفاصيل"};
    }
  }

  // GET /infos/image/{uuid} — Fetch student profile image as Base64
  Future<void> fetchProfileImage() async {
    if (_authToken == null || _uuid == null) return;
    if (_viaProxy) {
      try {
        final res = await _proxy.get('${ApiConstants.progresImage}/$_uuid',
            headers: _proxyAuthHeader);
        final body = (res?['base64'] as String?) ?? '';
        if (body.length > 100) _photo = body;
      } catch (_) {
        // Photo is optional, don't fail the whole flow
      }
      return;
    }
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/infos/image/$_uuid"),
        headers: {"authorization": _authToken!},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // The response body is the Base64 image string directly
        final body = response.body;
        if (body.isNotEmpty && body.length > 100) {
          _photo = body.replaceAll('"', '').trim();
          // Photo is not saved in SharedPreferences
        }
      }
    } catch (_) {
      // Photo is optional, don't fail the whole flow
    }
  }

  Future<Map<String, dynamic>> loginAndFetchProfile(String username, String password) async {
    // 1. Check D1 profile first (roles + deactivation + staff check)
    try {
      final firebaseProfile = await FirebaseService().getProfileByUsername(username);
      if (firebaseProfile != null) {
        // If the account has been deactivated by the admin, block them immediately
        if (firebaseProfile['isActive'] == false) {
          return {"success": false, "code": "DEACTIVATED", "message": "هذا الحساب معطل حالياً من طرف الإدارة"};
        }

        final storedRole = (firebaseProfile['role'] ?? 'etud').toString();
        final isStaff =
            storedRole == 'admin' || storedRole == 'staf' || storedRole == 'trav';

        // Staff have no PROGRES account -> local password verification in D1
        if (isStaff &&
            firebaseProfile.containsKey('password') &&
            firebaseProfile['password'] != null) {
          if (firebaseProfile['password'] != password) {
            return {"success": false, "code": "INVALID_CREDENTIALS", "message": "كلمة المرور غير صحيحة"};
          }

          // Setup local session for staff account
          _userName = username;
          _firstNameAr = firebaseProfile['firstNameAr'] ?? firebaseProfile['fullNameAr'];
          _lastNameAr = firebaseProfile['lastNameAr'] ?? '';
          _levelAr = firebaseProfile['levelAr'];
          _cycleAr = firebaseProfile['cycleAr'];
          _registrationNumber = firebaseProfile['registrationNumber'];
          _role = firebaseProfile['role'];
          _photo = firebaseProfile['photo'];
          _isActive = true;

          // Save session locally on device
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_username', username);
          await prefs.setString('saved_password', password);
          await _saveSessionSnapshot(prefs);

          return {
            "success": true,
            "message": "تم تسجيل الدخول بنجاح",
          };
        }
        // Students: fall through to MANDATORY live PROGRES verification
      }
    } catch (e) {
      debugPrint('D1 login check error: $e');
    }

    // 2. MANDATORY PROGRES verification (direct on mobile, Worker proxy on web).
    // PROGRES student passwords are NEVER saved in D1. Every login is verified live.
    final loginResult = await login(username, password);
    if (loginResult['success'] != true) return loginResult;

    // 3. Fetch the student's FULL info (name, photo, level...) from PROGRES
    // and save it to D1 (WITHOUT saving their PROGRES password).
    try {
      await fetchAndSaveProfile(username).timeout(const Duration(seconds: 50));
    } catch (_) {
      // Profile will retry on next launch via restoreSession.
    }

    // Cache the session locally so the app never disconnects on a
    // network outage (restoreSession hydrates from this snapshot).
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveSessionSnapshot(prefs);
    } catch (_) {}

    return {
      "success": true,
      "message": "تم تسجيل الدخول بنجاح",
    };
  }

  /// Fetches the FULL student profile from PROGRES (name, photo, level...)
  /// and saves it to D1. The 3 calls are independent -> run concurrently.
  /// Returns true if at least the basic info (name) was retrieved.
  /// Called awaited during login so the user enters WITH their data.
  Future<bool> fetchAndSaveProfile(String username) async {
    if (_authToken == null || _uuid == null) return false;
    try {
      final results = await Future.wait([
        fetchBasicInfo(),
        fetchDetailedInfo(),
        fetchProfileImage().then((_) => {"success": true}),
      ]).timeout(const Duration(seconds: 45));

      final basicOk = (results[0] as Map)['success'] == true;

      // البيانات الكاملة (التسجيلات، التخصص، الإيواء، المسار الدراسي...) في
      // الخلفية حتى لا تتأخر عملية الدخول، وتُحدّث الواجهة عند انتهائها.
      unawaited(fetchStudentData().catchError((_) => _studentData));

      final matricule = username;
      Map<String, dynamic>? existingProfile;
      
      try {
        existingProfile = await FirebaseService().getProfileByMatricule(matricule);
        if (existingProfile != null) {
          _role = existingProfile['role'] ?? 'etud';
          _isActive = existingProfile['isActive'] ?? true;
        } else {
          _role = 'etud';
          _isActive = true;
        }
      } catch (_) {
        _role = 'etud';
        _isActive = true;
      }

      final Map<String, dynamic> profileData = {
        'username': username,
        'fullNameAr': fullNameAr,
        'fullNameFr': fullNameFr,
        'firstNameAr': _firstNameAr,
        'lastNameAr': _lastNameAr,
        'levelAr': _levelAr,
        'cycleAr': _cycleAr,
        'registrationNumber': _registrationNumber,
        'photo': sanitizePhotoForSave(_photo),
        'isActive': _isActive,
      };

      if (existingProfile == null) {
        profileData['role'] = 'etud';
      }

      await FirebaseService().saveProfile(matricule, profileData);
      return basicOk;
    } catch (_) {
      return false;
    }
  }

  // Session management
  static const String _snapshotKey = 'session_profile_snapshot';

  /// حفظ نسخة محلية من بيانات الجلسة (الاسم/الدور/الصورة...) بحيث يبقى
  /// المستخدم داخل حسابه حتى لو انقطعت الشبكة أو تعطّل PROGRES.
  Future<void> _saveSessionSnapshot(SharedPreferences prefs) async {
    if (_userName == null || _role == null) return;
    final data = <String, dynamic>{
      'userName': _userName,
      'role': _role,
      'firstNameAr': _firstNameAr,
      'lastNameAr': _lastNameAr,
      'firstNameFr': _firstNameFr,
      'lastNameFr': _lastNameFr,
      'levelAr': _levelAr,
      'levelFr': _levelFr,
      'cycleAr': _cycleAr,
      'cycleFr': _cycleFr,
      'registrationNumber': _registrationNumber,
      'photo': sanitizePhotoForSave(_photo),
      'isActive': _isActive,
    };
    await prefs.setString(_snapshotKey, jsonEncode(data));
  }

  /// استرجاع الجلسة المحلية فوراً (بلا شبكة) ثم تحديث خلفي.
  ///
  /// القاعدة: الانقطاع/PROGRES المعطّل ما يطردش المستخدم — يُطرد فقط عند
  /// رفض صريح للكلمة (401) أو عند تعطيل الحساب من طرف الإدارة.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('saved_username');
    final password = prefs.getString('saved_password');

    // 0) hydrate the full student data snapshot (no network needed)
    hydrateStudentData(prefs);

    // 1) hydrate instantly from the local snapshot (no network needed)
    final hydrated = _hydrateSessionSnapshot(prefs, username);
    if (hydrated) {
      // Background refresh — never blocks startup, never logs out on a
      // network failure (only on an explicit rejection).
      _backgroundSessionRefresh(username, password);
      return;
    }

    // 2) no snapshot (first run after update / cleared data) -> live refresh.
    //    Failures are tolerated: we only drop the session on a definitive
    //    rejection (bad password / deactivated).
    if (username != null && password != null) {
      final res = await loginAndFetchProfile(username, password);
      final code = res['code'];
      if (res['success'] != true &&
          (code == 'INVALID_CREDENTIALS' || code == 'DEACTIVATED')) {
        await _clearStoredSession(prefs);
      }
    }
  }

  bool _hydrateSessionSnapshot(SharedPreferences prefs, String? username) {
    try {
      final raw = prefs.getString(_snapshotKey);
      if (raw == null || raw.isEmpty) return false;
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final snapUser = data['userName'] as String?;
      final snapRole = data['role'] as String?;
      if (snapUser == null || snapRole == null) return false;
      if (username != null && snapUser != username) return false;

      _userName = snapUser;
      _role = snapRole;
      _firstNameAr = data['firstNameAr'] as String?;
      _lastNameAr = data['lastNameAr'] as String?;
      _firstNameFr = data['firstNameFr'] as String?;
      _lastNameFr = data['lastNameFr'] as String?;
      _levelAr = data['levelAr'] as String?;
      _levelFr = data['levelFr'] as String?;
      _cycleAr = data['cycleAr'] as String?;
      _cycleFr = data['cycleFr'] as String?;
      _registrationNumber = data['registrationNumber'] as String?;
      _photo = data['photo'] as String?;
      _isActive = data['isActive'] != false;
      hydrateStudentData(prefs);
      return true;
    } catch (e) {
      debugPrint('session snapshot hydrate skipped: $e');
      return false;
    }
  }

  Future<void> _clearStoredSession(SharedPreferences prefs) async {
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    await prefs.remove(_snapshotKey);
  }

  /// يُستدعى بعد انتهاء التحديث الخلفي للجلسة (نجاح أو إنهاء صريح) —
  /// حتى يُنبه الـ Provider الواجهة إذا انتهى الحساب فعلاً.
  void Function()? onSessionRefreshed;

  Future<void> _backgroundSessionRefresh(
      String? username, String? password) async {
    if (username == null || password == null) return;
    try {
      final res = await loginAndFetchProfile(username, password);
      final code = res['code'];
      if (res['success'] != true) {
        // فقط رفض صريح يُنهي الجلسة — عطل الشبكة/PROGRES يبقى محسوباً.
        if (code == 'INVALID_CREDENTIALS' || code == 'DEACTIVATED') {
          final prefs = await SharedPreferences.getInstance();
          await _clearStoredSession(prefs);
          _authToken = null;
          _uuid = null;
          _userName = null;
          _role = null;
          _firstNameAr = null;
          _lastNameAr = null;
          _firstNameFr = null;
          _lastNameFr = null;
          _levelAr = null;
          _levelFr = null;
          _cycleAr = null;
          _cycleFr = null;
          _registrationNumber = null;
          _photo = null;
          _studentData = null;
          _isActive = true;
          onSessionRefreshed?.call();
        }
        return;
      }
      onSessionRefreshed?.call();
    } catch (e) {
      debugPrint('background session refresh skipped: $e');
    }
  }

  Future<bool> hasStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('saved_username') && prefs.containsKey('saved_password');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearStoredSession(prefs);
    
    _authToken = null; _uuid = null;
    _userName = null; _firstNameAr = null; _lastNameAr = null;
    _firstNameFr = null; _lastNameFr = null; _levelAr = null;
    _levelFr = null; _cycleAr = null; _cycleFr = null;
    _registrationNumber = null; _photo = null; _role = null; _isActive = true;
    _studentData = null;
  }

  // Getters
  String? get userName => _userName;
  String? get uuid => _uuid;
  bool get isLoggedIn => _authToken != null || (_userName != null && _role != null);
  String get fullNameAr => '${_firstNameAr ?? ''} ${_lastNameAr ?? ''}'.trim();
  String get fullNameFr => '${_firstNameFr ?? ''} ${_lastNameFr ?? ''}'.trim();
  String? get levelAr => _levelAr ?? _studentData?.levelAr;
  String? get levelFr => _levelFr ?? _studentData?.levelFr;
  String? get cycleAr => _cycleAr ?? _studentData?.cycleAr;
  String? get cycleFr => _cycleFr ?? _studentData?.cycleFr;
  String? get registrationNumber =>
      _registrationNumber ?? _studentData?.registrationNumber;
  String? get photo => _photo;
  String? get dateOfBirth => _dateOfBirth;
  String? get placeOfBirthAr => _placeOfBirthAr;
  String get role => _role ?? 'etud';
  bool get isActive => _isActive;
}
