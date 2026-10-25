import 'package:flutter/material.dart';

/// الأنواع الرسمية للحسابات في تطبيق cube_iii
/// كل نوع عنده دوره وصلاحياته الخاصة داخل التطبيق.
enum AppRole {
  admin,
  staf,
  trav,
  etud,
  guest,
}

extension AppRoleX on AppRole {
  String get code {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.staf:
        return 'staf';
      case AppRole.trav:
        return 'trav';
      case AppRole.etud:
        return 'etud';
      case AppRole.guest:
        return 'guest';
    }
  }

  String get labelAr {
    switch (this) {
      case AppRole.admin:
        return 'مدير النظام';
      case AppRole.staf:
        return 'مسؤول الأنشطة';
      case AppRole.trav:
        return 'عامل الخدمات';
      case AppRole.etud:
        return 'طالب جامعي';
      case AppRole.guest:
        return 'زائر';
    }
  }

  String get descriptionAr {
    switch (this) {
      case AppRole.admin:
        return 'تحكم كامل: برمجة التطبيق، المستخدمين، المسابقات، الأسئلة والفرق.';
      case AppRole.staf:
        return 'تنظيم الأنشطة والمسابقات: إنشاء وتسيير المسابقات والفرق والأسئلة.';
      case AppRole.trav:
        return 'تسيير الخدمات اليومية: الإطعام، النقل، المكتبة، الحمامات، الصيانة.';
      case AppRole.etud:
        return 'المشاركة في المسابقات والاستفادة من كل خدمات الإقامة.';
      case AppRole.guest:
        return 'تصفح الأخبار والخدمات والمشاهدة كمتفرج فقط.';
    }
  }

  Color get color {
    switch (this) {
      case AppRole.admin:
        return Colors.redAccent;
      case AppRole.staf:
        return Colors.blueAccent;
      case AppRole.trav:
        return Colors.orangeAccent;
      case AppRole.etud:
        return const Color(0xFFD4AF37);
      case AppRole.guest:
        return Colors.white24;
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.admin:
        return Icons.admin_panel_settings;
      case AppRole.staf:
        return Icons.event_available;
      case AppRole.trav:
        return Icons.handyman_outlined;
      case AppRole.etud:
        return Icons.school_outlined;
      case AppRole.guest:
        return Icons.visibility_outlined;
    }
  }

  // ---------- الصلاحيات ----------

  /// برمجة كل إعدادات التطبيق (الاسم، الإعلانات، القوائم، المواقيت...)
  bool get canProgramApp => this == AppRole.admin;

  /// إدارة حسابات المستخدمين وتغيير أدوارهم
  bool get canManageUsers => this == AppRole.admin;

  /// إدارة المسابقات (إنشاء / بدء / إنهاء)
  bool get canManageCompetitions =>
      this == AppRole.admin || this == AppRole.staf;

  /// بنك الأسئلة
  bool get canManageQuestions =>
      this == AppRole.admin || this == AppRole.staf;

  /// إدارة الفرق والنقاط
  bool get canManageTeams =>
      this == AppRole.admin || this == AppRole.staf;

  /// تحديث الخدمات اليومية (قوائم الأكل، النقل، الحمامات...)
  bool get canManageServices =>
      this == AppRole.admin || this == AppRole.trav || this == AppRole.staf;

  /// اللعب كلاعب داخل فريق
  bool get canPlay => this == AppRole.etud || this == AppRole.admin || this == AppRole.staf;

  /// المشاهدة كمتفرج
  bool get canSpectate => true;

  /// الدخول للوحة الإدارة
  bool get canAccessAdminPanel =>
      this == AppRole.admin || this == AppRole.staf || this == AppRole.trav;

  static AppRole fromString(String? code) {
    switch (code) {
      case 'admin':
        return AppRole.admin;
      case 'staf':
        return AppRole.staf;
      case 'trav':
        return AppRole.trav;
      case 'etud':
        return AppRole.etud;
      default:
        return AppRole.guest;
    }
  }

  static List<AppRole> get manageableRoles =>
      [AppRole.admin, AppRole.staf, AppRole.trav, AppRole.etud];
}
