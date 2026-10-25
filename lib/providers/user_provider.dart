import 'dart:async';
import 'package:flutter/material.dart';
import '../core/auth/app_roles.dart';
import '../models/progres_student_data.dart';
import '../services/progres_api_service.dart';
import '../services/firebase_service.dart';
import '../services/preference_service.dart';

class UserProvider extends ChangeNotifier {
  final ProgresApiService _api = ProgresApiService();
  final FirebaseService _firebase = FirebaseService();
  
  Map<String, dynamic>? _profileData;
  StreamSubscription? _profileSubscription;
  
  bool get isLoggedIn => _api.isLoggedIn;
  String get role => _profileData?['role'] ?? _api.role;
  AppRole get appRole => AppRoleX.fromString(role);
  bool get isAdmin => appRole == AppRole.admin;
  bool get isStaf => appRole == AppRole.staf;
  bool get isTrav => appRole == AppRole.trav;
  bool get isEtud => appRole == AppRole.etud;
  bool get canProgramApp => appRole.canProgramApp;
  bool get canManageUsers => appRole.canManageUsers;
  bool get canManageCompetitions => appRole.canManageCompetitions;
  bool get canManageServices => appRole.canManageServices;
  bool get canAccessAdminPanel => appRole.canAccessAdminPanel;
  String get matricule => _api.userName ?? '';
  Map<String, dynamic>? get profileData => _profileData;
  String get fullNameAr => _profileData?['fullNameAr'] ?? _api.fullNameAr;
  String? get photo => _profileData?['photo'] ?? _api.photo;
  String? get registrationNumber =>
      _profileData?['registrationNumber']?.toString() ?? _api.registrationNumber;
  String? get levelAr => _profileData?['levelAr']?.toString() ?? _api.levelAr;
  String? get cycleAr => _profileData?['cycleAr']?.toString() ?? _api.cycleAr;
  String? get roomNumber => _profileData?['roomNumber']?.toString();
  String? get residentSince => _profileData?['residentSince']?.toString();

  // ----------------------------------------------------------------
  // بيانات PROGRES الكاملة (الهوية، التسجيلات، التخصص، الإيواء، المسار...)
  // ----------------------------------------------------------------

  ProgresStudentData? get studentData => _api.studentData;

  /// هل توجد بيانات PROGRES مفصّلة جاهزة للعرض؟
  bool get hasStudentData => studentData != null;

  /// التخصص (takhasus)
  String? get specialtyAr => studentData?.specialtyAr;
  String? get specialtyFr => studentData?.specialtyFr;

  /// الميدان / الشعبة
  String? get domainAr => studentData?.domainAr;
  String? get fieldAr => studentData?.fieldAr;

  /// المؤسسة والسنة الجامعية
  String? get universityAr => studentData?.universityAr;
  String? get academicYear => studentData?.academicYear;

  /// الهوية الشخصية
  String? get fullNameFr => studentData?.fullNameFr;
  String? get dateOfBirth => studentData?.dateOfBirth;
  String? get placeOfBirthAr => studentData?.placeOfBirthAr;
  String? get nin => studentData?.nin;
  String? get email => studentData?.email;
  String? get phone => studentData?.phone;
  String? get address => studentData?.address;
  String? get gender => studentData?.gender;
  String? get nationality => studentData?.nationality;
  String? get bloodGroup => studentData?.bloodGroup;
  String? get familySituation => studentData?.familySituation;
  String? get fatherName => studentData?.fatherName;
  String? get motherName => studentData?.motherName;

  /// الإيواء (iqama)
  bool? get accommodationRequested => studentData?.accommodationRequested;
  bool? get accommodationGranted => studentData?.accommodationGranted;
  String? get accommodationTypeAr => studentData?.accommodationTypeAr;
  String? get accommodationPlace => studentData?.accommodationPlace;
  String? get accommodationRequestTypeAr => studentData?.accommodationRequestTypeAr;
  String? get accommodationSeniority => studentData?.accommodationSeniority;
  String? get accommodationObservation => studentData?.accommodationObservation;

  /// المنحة
  bool? get scholarshipRequested => studentData?.scholarshipRequested;
  bool? get scholarshipGranted => studentData?.scholarshipGranted;
  String? get scholarshipAmount => studentData?.scholarshipAmount;

  /// الفوج البيداغوجي
  String? get groupName => studentData?.groupName;
  String? get sectionName => studentData?.sectionName;

  /// آخر معدل/قرار من المسار الدراسي
  String? get average => studentData?.average;
  String? get credits => studentData?.credits;
  String? get decision => studentData?.decision;

  /// كل التسجيلات الإدارية
  List<Map<String, dynamic>> get registrations =>
      studentData?.registrations ?? const [];

  /// إعادة جلب بيانات PROGRES الكاملة (يدوياً من الواجهة).
  Future<bool> refreshStudentData() async {
    if (!_api.isLoggedIn) return false;
    final data = await _api.fetchStudentData();
    if (!_disposed) notifyListeners();
    return data != null;
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// يكتمل عند انتهاء استرجاع الجلسة + التحقق التلقائي عند دخول التطبيق.
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get waitInit => _initCompleter.future;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      // يُنبهنا إذا انتهى الحساب فعلاً في الخلفية (كلمة سر مرفوضة/معطّل).
      _api.onStudentDataUpdated = () {
        if (!_disposed) notifyListeners();
      };
      _api.onSessionRefreshed = () {
        if (_disposed) return;
        if (!_api.isLoggedIn) {
          _profileSubscription?.cancel();
          _profileSubscription = null;
          _profileData = null;
        }
        notifyListeners();
      };
      await _api.restoreSession();
      if (_api.isLoggedIn) {
        _startListening();
      }
    } finally {
      _isInitialized = true;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      if (!_disposed) notifyListeners();
    }
  }

  void _startListening() {
    _profileSubscription?.cancel();
    _profileSubscription = _firebase.getProfileByMatriculeStream(matricule).listen((data) {
      _profileData = data;
      notifyListeners();
    });
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await _api.loginAndFetchProfile(username, password);
    if (result['success'] == true) {
      _startListening();
    }
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _api.logout();
    await PreferenceService.clearSession();
    await _profileSubscription?.cancel();
    _profileData = null;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _profileSubscription?.cancel();
    super.dispose();
  }
}
