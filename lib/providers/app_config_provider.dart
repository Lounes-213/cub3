import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/facility_data.dart';
import '../services/facility_service.dart';

/// الإعدادات القابلة للبرمجة من لوحة الإدارة في cube_iii.
/// أي تغيير هنا ينعكس مباشرة على كل شاشات التطبيق.
class AppConfig {
  String appName;
  String residenceName;

  // الإعلان المبرمج (يظهر في أعلى الرئيسية)
  bool announcementEnabled;
  String announcementText;
  String announcementStart; // yyyy-MM-dd
  String announcementEnd; // yyyy-MM-dd

  // أقسام الإدارة (تفعيل / تعطيل)
  bool showActivities;
  bool showHousing;
  bool showCatering;
  bool showMedical;

  // الخدمات (تفعيل / تعطيل + نصوص مبرمجة)
  bool showMealMenu;
  String mealBreakfast;
  String mealLunch;
  String mealDinner;
  String mealNotes;

  bool showTransport;
  String transportMorning;
  String transportEvening;
  String transportNotes;

  bool showLibrary;
  String libraryHours;
  String libraryNotes;

  bool showShowers;
  String showerMorningStart;
  String showerMorningEnd;
  String showerEveningStart;
  String showerEveningEnd;
  String showerNotes;

  bool showMap;
  bool showGuide;
  bool enableCompetition;

  // أرقام الطوارئ (يبرمجها المدير: حماية مدنية، إسعاف، أمن داخلي...)
  // [{name, number}]
  List<Map<String, String>> emergencyNumbers;

  // روابط الأخبار (تُبرمج من الإدارة)
  String fbResidence;
  String fbDirection;
  String fbClub;
  String webDirection;
  String webProgres;

  // قيم افتراضية للمسابقات
  int defaultNumTeams;
  int defaultTeamSize;
  int defaultChronoSeconds;

  // صيانة / دعم
  String supportPhone;
  String maintenanceNotes;

  // رقم المصلحة الطبية (يُبرمج من الإدارة فقط — زر «اتصل الآن» يتصل به)
  String medicalPhone;

  // الأجنحة والمرافق (صور + أرقام رؤساء الأجنحة والملاحظات)
  Map<String, FacilityData> facilitiesData;

  AppConfig({
    this.appName = 'cube3',
    this.residenceName = 'الإقامة الجامعية باب الزوار 3',
    this.announcementEnabled = false,
    this.announcementText = '',
    this.announcementStart = '',
    this.announcementEnd = '',
    this.showActivities = true,
    this.showHousing = true,
    this.showCatering = true,
    this.showMedical = true,
    this.showMealMenu = true,
    this.mealBreakfast = '',
    this.mealLunch = '',
    this.mealDinner = '',
    this.mealNotes = '',
    this.showTransport = true,
    this.transportMorning = '07:30 - 08:30 كل 15 دقيقة',
    this.transportEvening = '16:30 - 18:00 كل 20 دقيقة',
    this.transportNotes = 'النقل خاص بالمقيمين، احترموا التوقيت.',
    this.showLibrary = true,
    this.libraryHours = '09:00 - 17:00 (الأحد - الخميس)',
    this.libraryNotes = 'الهدوء إجباري داخل قاعة المطالعة.',
    this.showShowers = true,
    this.showerMorningStart = '07:00',
    this.showerMorningEnd = '11:00',
    this.showerEveningStart = '17:00',
    this.showerEveningEnd = '21:00',
    this.showerNotes = 'الماء الساخن حسب البرنامج المعلن.',
    this.showMap = true,
    this.showGuide = true,
    this.enableCompetition = true,
    this.fbResidence = 'https://web.facebook.com/profile.php?id=100064333142859',
    this.fbDirection = 'https://web.facebook.com/doualgere',
    this.fbClub = 'https://www.facebook.com/profile.php?id=61572096481712',
    this.webDirection = 'https://www.dou-algerest.org/',
    this.webProgres = 'https://progres.mesrs.dz/webetu/',
    this.defaultNumTeams = 4,
    this.defaultTeamSize = 4,
    this.defaultChronoSeconds = 25,
    this.supportPhone = '',
    this.maintenanceNotes = '',
    this.medicalPhone = '',
    this.emergencyNumbers = const [],
    this.facilitiesData = const {},
  });


  Map<String, dynamic> toMap() => {
        'appName': appName,
        'residenceName': residenceName,
        'announcementEnabled': announcementEnabled,
        'announcementText': announcementText,
        'announcementStart': announcementStart,
        'announcementEnd': announcementEnd,
        'showActivities': showActivities,
        'showHousing': showHousing,
        'showCatering': showCatering,
        'showMedical': showMedical,
        'showMealMenu': showMealMenu,
        'mealBreakfast': mealBreakfast,
        'mealLunch': mealLunch,
        'mealDinner': mealDinner,
        'mealNotes': mealNotes,
        'showTransport': showTransport,
        'transportMorning': transportMorning,
        'transportEvening': transportEvening,
        'transportNotes': transportNotes,
        'showLibrary': showLibrary,
        'libraryHours': libraryHours,
        'libraryNotes': libraryNotes,
        'showShowers': showShowers,
        'showerMorningStart': showerMorningStart,
        'showerMorningEnd': showerMorningEnd,
        'showerEveningStart': showerEveningStart,
        'showerEveningEnd': showerEveningEnd,
        'showerNotes': showerNotes,
        'showMap': showMap,
        'showGuide': showGuide,
        'enableCompetition': enableCompetition,
        'fbResidence': fbResidence,
        'fbDirection': fbDirection,
        'fbClub': fbClub,
        'webDirection': webDirection,
        'webProgres': webProgres,
        'defaultNumTeams': defaultNumTeams,
        'defaultTeamSize': defaultTeamSize,
        'defaultChronoSeconds': defaultChronoSeconds,
        'supportPhone': supportPhone,
        'maintenanceNotes': maintenanceNotes,
        'medicalPhone': medicalPhone,
        'emergencyNumbers': emergencyNumbers,
        'facilitiesData':
            facilitiesData.map((k, v) => MapEntry(k, v.toMap())),
      };

  factory AppConfig.fromMap(Map<String, dynamic> m) {
    final d = AppConfig();
    T get<T>(String k, T fallback) {
      final v = m[k];
      if (v == null) return fallback;
      return v as T;
    }

    return AppConfig(
      appName: get('appName', d.appName),
      residenceName: get('residenceName', d.residenceName),
      announcementEnabled: get('announcementEnabled', d.announcementEnabled),
      announcementText: get('announcementText', d.announcementText),
      announcementStart: get('announcementStart', d.announcementStart),
      announcementEnd: get('announcementEnd', d.announcementEnd),
      showActivities: get('showActivities', d.showActivities),
      showHousing: get('showHousing', d.showHousing),
      showCatering: get('showCatering', d.showCatering),
      showMedical: get('showMedical', d.showMedical),
      showMealMenu: get('showMealMenu', d.showMealMenu),
      mealBreakfast: get('mealBreakfast', d.mealBreakfast),
      mealLunch: get('mealLunch', d.mealLunch),
      mealDinner: get('mealDinner', d.mealDinner),
      mealNotes: get('mealNotes', d.mealNotes),
      showTransport: get('showTransport', d.showTransport),
      transportMorning: get('transportMorning', d.transportMorning),
      transportEvening: get('transportEvening', d.transportEvening),
      transportNotes: get('transportNotes', d.transportNotes),
      showLibrary: get('showLibrary', d.showLibrary),
      libraryHours: get('libraryHours', d.libraryHours),
      libraryNotes: get('libraryNotes', d.libraryNotes),
      showShowers: get('showShowers', d.showShowers),
      showerMorningStart:
          (m['showerMorningStart'] ?? '07:00').toString(),
      showerMorningEnd:
          (m['showerMorningEnd'] ?? '11:00').toString(),
      showerEveningStart:
          (m['showerEveningStart'] ?? '17:00').toString(),
      showerEveningEnd:
          (m['showerEveningEnd'] ?? '21:00').toString(),
      showerNotes: get('showerNotes', d.showerNotes),
      showMap: get('showMap', d.showMap),
      showGuide: get('showGuide', d.showGuide),
      enableCompetition: get('enableCompetition', d.enableCompetition),
      fbResidence: get('fbResidence', d.fbResidence),
      fbDirection: get('fbDirection', d.fbDirection),
      fbClub: get('fbClub', d.fbClub),
      webDirection: get('webDirection', d.webDirection),
      webProgres: get('webProgres', d.webProgres),
      defaultNumTeams: (m['defaultNumTeams'] as num?)?.toInt() ?? d.defaultNumTeams,
      defaultTeamSize: (m['defaultTeamSize'] as num?)?.toInt() ?? d.defaultTeamSize,
      defaultChronoSeconds:
          (m['defaultChronoSeconds'] as num?)?.toInt() ?? d.defaultChronoSeconds,
      supportPhone: get('supportPhone', d.supportPhone),
      maintenanceNotes: get('maintenanceNotes', d.maintenanceNotes),
      medicalPhone: get('medicalPhone', d.medicalPhone),
      emergencyNumbers: _parseEmergencyNumbers(m['emergencyNumbers']),
      facilitiesData: _parseFacilities(m['facilitiesData']),
    );
  }

  static Map<String, FacilityData> _parseFacilities(dynamic raw) {
    if (raw is! Map) return {};
    final res = <String, FacilityData>{};
    raw.forEach((k, v) {
      if (v is Map) {
        res[k.toString()] = FacilityData.fromMap(Map<String, dynamic>.from(v));
      }
    });
    return res;
  }

  /// إرجاع بيانات الجناح أو المرفق المبرمجة مع دمج القيم الافتراضية
  FacilityData getFacility(String key,
      {String? defaultType, String? defaultDedication}) {
    if (facilitiesData.containsKey(key)) {
      final existing = facilitiesData[key]!;
      if (defaultDedication != null &&
          existing.dedication.trim().isEmpty &&
          defaultDedication.trim().isNotEmpty) {
        return existing.copyWith(dedication: defaultDedication);
      }
      return existing;
    }
    return FacilityData(
      id: key,
      name: key,
      type: defaultType ?? (key.startsWith('جناح') ? 'pavilion' : 'service'),
      dedication: defaultDedication ?? '',
    );
  }

  /// أرقام الطوارئ قد تأتي List<Map> من السحابة أو المحلي.
  static List<Map<String, String>> _parseEmergencyNumbers(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => {
              'name': (e['name'] ?? '').toString(),
              'number': (e['number'] ?? '').toString(),
            })
        .where((e) => e['name']!.isNotEmpty && e['number']!.isNotEmpty)
        .toList();
  }


  bool get isAnnouncementActiveNow {
    if (!announcementEnabled || announcementText.trim().isEmpty) return false;
    try {
      final now = DateTime.now();
      if (announcementStart.trim().isNotEmpty) {
        final s = DateTime.tryParse(announcementStart);
        if (s != null && now.isBefore(s)) return false;
      }
      if (announcementEnd.trim().isNotEmpty) {
        final e = DateTime.tryParse(announcementEnd);
        if (e != null && now.isAfter(e.add(const Duration(days: 1)))) return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}

class AppConfigProvider extends ChangeNotifier {
  static const _key = 'cube_iii_app_config_v1';
  AppConfig _config = AppConfig();
  bool _loaded = false;

  AppConfig get config => _config;
  bool get isLoaded => _loaded;

  AppConfigProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _config = AppConfig.fromMap(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
        // ترحيل الاسم القديم إلى الاسم الظاهر الجديد
        if (_config.appName == 'cube_iii') {
          _config.appName = 'cube3';
          await prefs.setString(_key, jsonEncode(_config.toMap()));
        }
        // ترحيل: مسح قيم الوجبات الافتراضية المخترعة (لا معلومات وهمية)
        var migratedMeals = false;
        if (_config.mealBreakfast == 'قهوة + خبز + جبن') {
          _config.mealBreakfast = '';
          migratedMeals = true;
        }
        if (_config.mealLunch == 'كسكس بالخضار') {
          _config.mealLunch = '';
          migratedMeals = true;
        }
        if (_config.mealDinner == 'شوربة + طبق رئيسي') {
          _config.mealDinner = '';
          migratedMeals = true;
        }
        if (_config.mealNotes ==
            'تُقدَّم الوجبات في المطعم المركزي حسب التوقيت المعلق.') {
          _config.mealNotes = '';
          migratedMeals = true;
        }
        if (migratedMeals) {
          await prefs.setString(_key, jsonEncode(_config.toMap()));
        }
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
    // المزامنة السحابية: برمجة الإدارة تصل كل الأجهزة (خلفية، لا تمنع الدخول)
    _pullRemote();
  }

  /// جلب برمجة الإدارة من السحابة (إن وُجدت) وتطبيقها محلياً.
  Future<void> _pullRemote() async {
    try {
      final res = await ApiClient()
          .get(ApiConstants.appConfig)
          .timeout(const Duration(seconds: 10));
      final cfg = res?['config'];
      if (cfg is Map) {
        _config = AppConfig.fromMap(Map<String, dynamic>.from(cfg));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, jsonEncode(_config.toMap()));
        notifyListeners();
      }
    } catch (_) {
      // بدون اتصال: تبقى النسخة المحلية
    }
  }

  Future<void> save(AppConfig updated) async {
    _config = updated;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_config.toMap()));
    // دفع برمجة الإدارة إلى السحابة لتصل كل الأجهزة
    try {
      await ApiClient()
          .post(ApiConstants.appConfig, body: {'config': _config.toMap()})
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // تُحفظ محلياً وتُدفع لاحقاً عند أول حفظ ناجح
    }
  }

  Future<void> update(void Function(AppConfig c) mutate) async {
    mutate(_config);
    await save(_config);
  }

  /// حفظ أو تحديث بيانات جناح أو مرفق (صور + هاتف رئيس الجناح...)
  Future<void> saveFacility(FacilityData facility) async {
    final updatedMap =
        Map<String, FacilityData>.from(_config.facilitiesData);
    updatedMap[facility.name] = facility;
    _config.facilitiesData = updatedMap;
    await save(_config);
  }

  /// حذف صورة من جناح/مرفق وحذفها فوراً من التخزين السحابي Cloudflare R2
  Future<void> deleteFacilityImage(
      String facilityName, String imageUrl) async {
    // 1. حذف من R2 storage
    await FacilityService().deleteMediaFromStorage(imageUrl);

    // 2. تحديث الإعدادات
    final current = _config.getFacility(facilityName);
    final updatedImages =
        current.images.where((img) => img != imageUrl).toList();
    final updated = current.copyWith(images: updatedImages);
    await saveFacility(updated);
  }

  /// حذف بيانات الجناح ومسح كل صوره من التخزين السحابي
  Future<void> deleteFacility(String facilityName) async {
    final current = _config.facilitiesData[facilityName];
    if (current != null) {
      for (final img in current.images) {
        await FacilityService().deleteMediaFromStorage(img);
      }
      final updatedMap =
          Map<String, FacilityData>.from(_config.facilitiesData);
      updatedMap.remove(facilityName);
      _config.facilitiesData = updatedMap;
      await save(_config);
    }
  }

  Future<void> resetToDefaults() async {
    await save(AppConfig());
  }
}

