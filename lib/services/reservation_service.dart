import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// حجز الإطعام: دورة كل 3 أيام.
/// - الزر: تجديد الحجز (يضبط البداية الآن + 3 أيام).
/// - تنبيه تلقائي عند اقتراب الانتهاء (أقل من 24 ساعة).
class ReservationService {
  static const _key = 'cube3 catering reservation v1';
  static const validityDays = 3;

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// تجديد الحجز الآن (3 أيام جديدة).
  static Future<Map<String, dynamic>> reserveNow() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final data = {
      'reservedAt': now.toIso8601String(),
      'expiresAt':
          now.add(const Duration(days: validityDays)).toIso8601String(),
    };
    await prefs.setString(_key, jsonEncode(data));
    return data;
  }

  static DateTime? expiryOf(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      return DateTime.parse(data['expiresAt'] as String);
    } catch (_) {
      return null;
    }
  }

  static bool isActive(Map<String, dynamic>? data) {
    final exp = expiryOf(data);
    return exp != null && DateTime.now().isBefore(exp);
  }

  static bool isExpiringSoon(Map<String, dynamic>? data) {
    final exp = expiryOf(data);
    if (exp == null) return false;
    final left = exp.difference(DateTime.now());
    return !left.isNegative && left.inHours < 24;
  }

  static String remainingLabel(Map<String, dynamic>? data) {
    final exp = expiryOf(data);
    if (exp == null) return 'لا يوجد حجز';
    final left = exp.difference(DateTime.now());
    if (left.isNegative) return 'انتهى الحجز';
    if (left.inDays >= 1) {
      final h = left.inHours % 24;
      return 'متبقي ${left.inDays} يوم و $h ساعة';
    }
    if (left.inHours >= 1) return 'متبقي ${left.inHours} ساعة';
    return 'متبقي ${left.inMinutes} دقيقة';
  }

  /// مزامنة الحجز مع لوحة الإدارة (تظهر حجوزات الطلبة عند المدير).
  static Future<void> syncToAdmin({
    required String matricule,
    required String name,
  }) async {
    try {
      final data = await load();
      final exp = expiryOf(data);
      if (data == null || exp == null) return;
      await ApiClient().post(ApiConstants.cateringReservations, body: {
        'matricule': matricule,
        'name': name,
        'reservedAt': data['reservedAt'],
        'expiresAt': data['expiresAt'],
      });
    } catch (e) {
      debugPrint('⚠️ reservation sync skipped: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllForAdmin() async {
    try {
      final res = await ApiClient().get(ApiConstants.cateringReservations);
      final List list = (res?['reservations'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('⚠️ reservations fetch error: $e');
      return [];
    }
  }
}
