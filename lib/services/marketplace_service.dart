import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/marketplace_item.dart';

/// خدمة سوق الطلبة والتبادل الداخلي (Cloudflare D1 & R2).
class MarketplaceService {
  final ApiClient _api = ApiClient();

  /// جلب قائمة المعروضات مع إمكانية الفلترة
  Future<List<MarketplaceItem>> fetchItems({
    String? category,
    String? matricule,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty && category != 'all') {
        queryParams['category'] = category;
      }
      if (matricule != null && matricule.isNotEmpty) {
        queryParams['matricule'] = matricule;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(ApiConstants.marketplace)
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final res = await _api.get(uri.toString());
      final List list = (res?['items'] as List?) ?? [];
      return list
          .map((item) =>
              MarketplaceItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching marketplace items: $e');
      return [];
    }
  }

  /// جلب غرض واحد حسب المعرّف (لصفحة المشاركة المستقلة `/p/<id>`)
  Future<MarketplaceItem?> getProductById(String id) async {
    if (id.trim().isEmpty) return null;
    try {
      final res = await _api.get('${ApiConstants.marketplace}/$id');
      if (res == null || res['success'] != true || res['item'] == null) {
        return null;
      }
      return MarketplaceItem.fromJson(
          Map<String, dynamic>.from(res['item'] as Map));
    } catch (e) {
      debugPrint('⚠️ Error fetching marketplace item $id: $e');
      return null;
    }
  }

  /// حساب عدد الأغراض المعروضة حالياً للطالب (بحد أقصى 3)
  Future<int> fetchUserActiveCount(String matricule) async {
    if (matricule.isEmpty) return 0;
    final items = await fetchItems(matricule: matricule, status: 'available');
    return items.length;
  }

  /// نشر غرض جديد للبيع أو التبادل (مع فحص حد 3 أغراض)
  Future<String> createItem(MarketplaceItem item) async {
    final res = await _api.post(
      ApiConstants.marketplace,
      body: item.toJson(),
    );

    if (res == null || res['success'] != true) {
      final message = res?['message'] ?? 'فشل نشر الغرض';
      throw Exception(message);
    }

    return (res['id'] ?? '').toString();
  }

  /// تغيير حالة الغرض (متاح / مباع)
  Future<void> updateItemStatus(String id, String status) async {
    final res = await _api.put(
      '${ApiConstants.marketplace}/$id/status',
      body: {'status': status},
    );
    if (res == null || res['success'] != true) {
      throw Exception(res?['message'] ?? 'فشل تحديث الحالة');
    }
  }

  /// تعديل بيانات الغرض (العنوان، الوصف، السعر، الصور...)
  Future<void> updateItem(String id, MarketplaceItem item) async {
    final res = await _api.put(
      '${ApiConstants.marketplace}/$id',
      body: item.toJson(),
    );
    if (res == null || res['success'] != true) {
      throw Exception(res?['message'] ?? 'فشل تعديل الغرض');
    }
  }

  /// حذف الغرض نهائياً وحذف صوره من Cloudflare R2
  Future<void> deleteItem(String id) async {
    final res = await _api.delete('${ApiConstants.marketplace}/$id');
    if (res == null || res['success'] != true) {
      throw Exception(res?['message'] ?? 'فشل حذف الغرض');
    }
  }
}
