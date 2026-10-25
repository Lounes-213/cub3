import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _isAdminLoggedInKey = 'is_admin_logged_in';
  static const String _teamRegisteredSlotKey = 'team_registered_slot';
  static const String _teamNameKey = 'team_name';
  static const String _isSpectatorKey = 'is_spectator';
  static const String _userRoleKey = 'user_role'; // 'admin', 'participant', 'spectator'

  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<void> setAdminLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdminLoggedInKey, value);
    if (value) await setUserRole('admin');
  }

  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminLoggedInKey) ?? false;
  }

  static const String _teamColorKey = 'team_color';

  static Future<void> saveTeamRegistration(int slot, String name, int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_teamRegisteredSlotKey, slot);
    await prefs.setString(_teamNameKey, name);
    await prefs.setInt(_teamColorKey, colorValue);
    await setUserRole('participant');
  }

  static Future<Map<String, dynamic>?> getTeamRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final slot = prefs.getInt(_teamRegisteredSlotKey);
    final name = prefs.getString(_teamNameKey);
    final color = prefs.getInt(_teamColorKey);
    if (slot != null && name != null) {
      return {'slot': slot, 'name': name, 'color': color};
    }
    return null;
  }

  static Future<void> setSpectator(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSpectatorKey, value);
    if (value) await setUserRole('spectator');
  }

  static Future<bool> isSpectator() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSpectatorKey) ?? false;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// يمسح جلسة المنافسة فقط (الفريق/المتفرج/الدور) ويُبقي الحساب والإعدادات.
  /// يُستعمل عند إغلاق مسابقة — لا يمسح الدخول ولا برمجة الإدارة.
  static Future<void> clearCompetitionSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teamRegisteredSlotKey);
    await prefs.remove(_teamNameKey);
    await prefs.remove(_teamColorKey);
    await prefs.remove(_isSpectatorKey);
    await prefs.remove(_userRoleKey);
  }

  /// يمسح كل آثار الجلسة عند تسجيل الخروج (مع بقاء برمجة التطبيق).
  static Future<void> clearSession() async {
    await clearCompetitionSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isAdminLoggedInKey);
  }
}
