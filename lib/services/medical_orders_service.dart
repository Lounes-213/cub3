import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// طلبات المواعيد الطبية: الطالب يحجز → تظهر في لوحة الإدارة.
class MedicalOrdersService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> myOrders(String matricule) async {
    try {
      final res =
          await _api.get('${ApiConstants.medicalOrders}/by-matricule/$matricule');
      final List list = (res?['orders'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('⚠️ medical orders fetch error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> allOrders() async {
    try {
      final res = await _api.get(ApiConstants.medicalOrders);
      final List list = (res?['orders'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('⚠️ medical orders fetch error: $e');
      return [];
    }
  }

  Future<String> create({
    required String matricule,
    required String name,
    required String specialty,
    required String date,
    String notes = '',
  }) async {
    final res = await _api.post(ApiConstants.medicalOrders, body: {
      'matricule': matricule,
      'name': name,
      'specialty': specialty,
      'date': date,
      'notes': notes,
    });
    if (res == null || res['success'] != true) {
      throw Exception(res?['message'] ?? 'فشل حجز الموعد');
    }
    return (res['id'] ?? '').toString();
  }

  Future<void> setStatus(String id, String status) async {
    await _api.put('${ApiConstants.medicalOrders}/$id',
        body: {'status': status});
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'مؤكد';
      case 'done':
        return 'تم';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'قيد المعالجة';
    }
  }
}
