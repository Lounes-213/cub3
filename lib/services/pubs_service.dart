import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/pub_item.dart';

/// إعلانات الإدارة (pubs): تُبرمج من اللوحة وتظهر في الرئيسية.
/// حذف إعلان يحذف صورته من التخزين (الباك-اند).
class PubsService {
  final ApiClient _api = ApiClient();

  Future<List<PubItem>> fetchPubs() async {
    try {
      final res = await _api.get(ApiConstants.pubs);
      final List list = (res?['pubs'] as List?) ?? [];
      return list
          .map((p) => PubItem.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ pubs fetch error: $e');
      return [];
    }
  }

  Future<List<PubItem>> fetchVisiblePubs() async {
    final all = await fetchPubs();
    return all.where((p) => p.isVisibleNow).toList();
  }

  Future<void> savePub({
    String? id,
    required String title,
    required String text,
    String? imageUrl,
    String? link,
    String? startDate,
    String? endDate,
    bool isActive = true,
  }) async {
    final res = await _api.post(ApiConstants.pubs, body: {
      'id': ?id,
      'title': title.trim(),
      'text': text.trim(),
      'imageUrl': imageUrl,
      'link': link,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
    });
    if (res == null || res['success'] != true) {
      throw Exception(res?['message'] ?? 'فشل الحفظ');
    }
  }

  Future<void> deletePub(String id) async {
    await _api.delete('${ApiConstants.pubs}/$id');
  }
}
