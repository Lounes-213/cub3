import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/facebook_post.dart';

/// منشورات الإقامة — تُبرمج 100% من لوحة الإدارة.
/// لا توجد منشورات ثابتة ولا جلب خارجي: القائمة فارغة حتى ينشر المدير.
class NewsService {
  final ApiClient _api = ApiClient();

  /// الحد الأقصى المسموح (مفروض أيضاً في الباك-اند لحماية R2)
  static const int maxPosts = 100;

  /// جلب منشورات الإدارة من Cloudflare D1
  Future<List<FacebookPost>> fetchAdminPosts() async {
    try {
      final res = await _api.get(ApiConstants.news);
      final List list = (res?['posts'] as List?) ?? [];
      return list
          .map((p) => FacebookPost.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ news fetch error: $e');
      return [];
    }
  }

  /// رفع صورة (base64) إلى R2 — صور فقط
  Future<String> uploadImage(String base64, {String mime = 'image/jpeg'}) async {
    final res = await _api.post(ApiConstants.mediaUpload, body: {
      'base64': base64,
      'mime': mime,
    });
    final url = res?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception(res?['message'] ?? 'فشل رفع الصورة');
    }
    return url;
  }

  /// نشر منشور جديد (يرفض الباك-اند عند بلوغ 100)
  Future<void> createPost({
    required String title,
    required String text,
    List<String> mediaUrls = const [],
    String postUrl = '',
    bool inCarousel = true,
  }) async {
    try {
      final res = await _api.post(ApiConstants.news, body: {
        'title': title.trim(),
        'text': text.trim(),
        'type': mediaUrls.isNotEmpty ? 'photo' : 'text',
        'mediaUrls': mediaUrls,
        'postUrl': postUrl.trim(),
        'inCarousel': inCarousel,
        'date': DateTime.now().toString().substring(0, 16).replaceAll('T', ' '),
      });
      if (res == null || res['success'] != true) {
        throw Exception(res?['message'] ?? 'فشل النشر');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('MAX_POSTS_REACHED')) {
        throw Exception('وصلت للحد الأقصى (100 منشور). احذف منشوراً قديماً أولاً.');
      }
      if (msg.contains('IMAGES_ONLY')) {
        throw Exception('مسموح بالصور فقط.');
      }
      if (msg.contains('FILE_TOO_LARGE')) {
        throw Exception('الصورة كبيرة جداً (الحد 5MB).');
      }
      rethrow;
    }
  }

  /// تعديل منشور موجود (العنوان / النص / الصورة / الرابط / الكاروسيل)
  Future<void> updatePost({
    required String id,
    required String title,
    required String text,
    List<String> mediaUrls = const [],
    String? postUrl,
    bool? inCarousel,
  }) async {
    try {
      final body = <String, dynamic>{
        'id': id,
        'title': title.trim(),
        'text': text.trim(),
        'mediaUrls': mediaUrls,
      };
      // الحقول المفقودة ما تُرسلش أصلاً — الباك-اند يحافظ على قيمتها.
      if (postUrl != null) body['postUrl'] = postUrl.trim();
      if (inCarousel != null) body['inCarousel'] = inCarousel;
      final res = await _api.put('${ApiConstants.news}/$id', body: body);
      if (res == null || res['success'] != true) {
        throw Exception(res?['message'] ?? 'تعذر تعديل المنشور');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('FILE_TOO_LARGE')) {
        throw Exception('الصورة كبيرة جداً (الحد 5MB).');
      }
      rethrow;
    }
  }

  /// تبديل حالة «يتحرك في الرئيسية» فقط (من قائمة الإدارة) —
  /// يُرسل الحقول الحالية كما هي حتى لا تُمسح.
  Future<void> setInCarousel({
    required FacebookPost post,
    required bool inCarousel,
  }) {
    return updatePost(
      id: post.id,
      title: post.title,
      text: post.text,
      mediaUrls: post.mediaUrls,
      postUrl: post.postUrl,
      inCarousel: inCarousel,
    );
  }

  /// حذف صورة من التخزين السحابي R2 (تُستعمل عند استبدال صورة قديمة
  /// أو عند إلغاء صورة لم تُنشر بعد حتى لا تبقى يتيمة في التخزين).
  Future<void> deleteMedia(String url) async {
    final target = url.trim();
    if (target.isEmpty) return;
    try {
      await _api.post(ApiConstants.mediaDelete, body: {'url': target});
    } catch (e) {
      debugPrint('⚠️ media delete error: $e');
    }
  }

  /// حذف منشور — الباك-اند يحذف صوره من R2 تلقائياً لتوفير المساحة
  Future<void> deletePost(String id) async {
    await _api.delete('${ApiConstants.news}/$id');
  }
}
