import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// خدمة إدارة صور وبيانات الأجنحة والمرافق والتخزين السحابي (Cloudflare R2).
class FacilityService {
  final ApiClient _api = ApiClient();

  /// رفع صورة جناح / مرفق إلى Cloudflare R2
  Future<String> uploadFacilityImage(Uint8List bytes, {String mime = 'image/jpeg'}) async {
    final base64Str = base64Encode(bytes);
    final res = await _api.post(ApiConstants.mediaUpload, body: {
      'base64': base64Str,
      'mime': mime,
    });
    final url = res?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception(res?['message'] ?? 'فشل رفع صورة المرفق');
    }
    return url;
  }

  /// حذف الصورة نهائياً من التخزين السحابي R2
  Future<bool> deleteMediaFromStorage(String imageUrl) async {
    if (imageUrl.isEmpty) return false;
    try {
      final res = await _api.post(ApiConstants.mediaDelete, body: {
        'url': imageUrl,
      });
      return res?['success'] == true;
    } catch (e) {
      debugPrint('⚠️ Error deleting media from R2: $e');
      return false;
    }
  }
}
