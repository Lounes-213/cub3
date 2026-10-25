import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/facebook_post.dart';

/// خدمة جلب بيانات فيسبوك وتخزينها في Cloudflare D1
class FacebookScraperService {
  final String apiEndpoint = "https://rss.app/feeds/v1.1/jBZADppmk84APvsa.json";
  final ApiClient _api = ApiClient();

  Future<List<FacebookPost>> fetchPosts() async {
    // 1. التحقق من قاعدة بيانات Cloudflare D1 أولاً
    try {
      final res = await _api.get(ApiConstants.news);
      if (res != null && res['posts'] != null) {
        final List postsList = res['posts'];
        if (postsList.isNotEmpty) {
          debugPrint('✅ تم جلب المنشورات من Cloudflare D1 (${postsList.length} منشور)');
          return postsList.map((p) {
            final Map<String, dynamic> postMap = Map<String, dynamic>.from(p);
            return FacebookPost(
              id: postMap['id'] ?? '',
              title: postMap['title'] ?? '',
              text: postMap['text'] ?? '',
              type: postMap['type'] ?? 'text',
              mediaUrls: List<String>.from(postMap['mediaUrls'] ?? []),
              videoUrl: postMap['videoUrl'],
              date: postMap['date'] ?? 'الآن',
              isRepost: postMap['isRepost'] ?? false,
              originalPageName: postMap['originalPageName'],
              postUrl: postMap['postUrl'],
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في قراءة Cloudflare D1: $e');
    }

    // 2. إذا لم تكن البيانات في Cloudflare -> اطلبها من أداة الإنترنت
    if (apiEndpoint.isNotEmpty) {
      try {
        debugPrint('🌐 جاري الاتصال بأداة الإنترنت لتحديث المنشورات...');
        final response = await http.get(Uri.parse(apiEndpoint));

        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final data = json.decode(decodedBody);

          if (data['items'] != null) {
            final List items = data['items'];
            List<FacebookPost> posts = items.take(20).map((item) {
              String text = item['content_text'] ?? '';

              List<String> images = [];
              if (item['image'] != null) images.add(item['image']);

              if (item['attachments'] != null) {
                for (var attachment in item['attachments']) {
                  if (attachment['url'] != null && !images.contains(attachment['url'])) {
                    images.add(attachment['url']);
                  }
                }
              }

              bool isVideo = images.isNotEmpty && images.first.contains('video');

              String dateRaw = item['date_published'] ?? 'الآن';
              String cleanDate = dateRaw;
              try {
                if (dateRaw != 'الآن') {
                  final DateTime parsed = DateTime.parse(dateRaw);
                  cleanDate =
                      "${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
                }
              } catch (_) {}

              return FacebookPost(
                id: item['id'] ?? DateTime.now().toString(),
                title: text.isNotEmpty ? (text.length > 30 ? '${text.substring(0, 30)}...' : text) : 'إعلان',
                text: text,
                type: isVideo ? 'video' : (images.isNotEmpty ? 'photo' : 'text'),
                mediaUrls: images,
                date: cleanDate,
                postUrl: item['url'],
              );
            }).toList();

            // 3. حفظ البيانات الجديدة في Cloudflare D1
            try {
              final payload = posts
                  .map((p) => {
                        'id': p.id,
                        'title': p.title,
                        'text': p.text,
                        'type': p.type,
                        'mediaUrls': p.mediaUrls,
                        'videoUrl': p.videoUrl,
                        'date': p.date,
                        'isRepost': p.isRepost,
                        'originalPageName': p.originalPageName,
                        'postUrl': p.postUrl,
                      })
                  .toList();
              await _api.post(ApiConstants.newsBatch, body: payload);
              debugPrint('💾 تم حفظ أحدث المنشورات في Cloudflare D1 بنجاح!');
            } catch (e) {
              debugPrint('⚠️ خطأ في حفظ Cloudflare D1: $e');
            }

            return posts;
          }
        }
      } catch (e) {
        debugPrint("❌ خطأ في أداة الإنترنت: $e");
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    return getFallbackPosts();
  }

  /// المنشورات الاحتياطية (تظهر حتى تضع رابط الأداة)
  List<FacebookPost> getFallbackPosts() {
    return [
      FacebookPost(
        id: '1',
        title: 'استئناف الدراسة والنشاطات',
        text: 'نعلم جميع الطلبة المقيمين بالإقامة الجامعية باب الزوار 3 باستئناف النشاطات الثقافية والرياضية ابتداءً من الأسبوع القادم.',
        type: 'text',
        date: 'منذ ساعتين',
      ),
      FacebookPost(
        id: '2',
        title: 'المسابقة الفكرية الكبرى CUBE III',
        text: 'انطلاق فعاليات مسابقة مكعب باب الزوار للثقافة العامة والعلوم بين أجنحة الإقامة.',
        type: 'photo',
        mediaUrls: [],
        date: 'منذ 5 ساعات',
      ),
    ];
  }
}
