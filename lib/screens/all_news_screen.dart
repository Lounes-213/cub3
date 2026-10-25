import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../models/facebook_post.dart';
import '../providers/app_config_provider.dart';
import 'news_detail_screen.dart';

class AllNewsScreen extends StatelessWidget {
  final List<FacebookPost> posts;

  const AllNewsScreen({super.key, required this.posts});

  /// زر فيسبوك يفتح صفحة الإقامة (نفس الرابط المبرمج في الرئيسية).
  void _openFacebook(BuildContext context) {
    final configured =
        context.read<AppConfigProvider>().config.fbResidence.trim();
    final pageUrl = configured.isNotEmpty
        ? configured
        : 'https://m.facebook.com/profile.php?id=100064333142859';
    launchUrl(
      Uri.parse('fb://facewebmodal/f?href=$pageUrl'),
      mode: LaunchMode.externalApplication,
    ).catchError((_) {
      return launchUrl(Uri.parse(pageUrl), mode: LaunchMode.externalApplication);
    });
  }

  /// فتح رابط المنشور في المتصفح/التطبيق.
  void _openPostLink(String url) {
    final raw = url.trim();
    if (raw.isEmpty) return;
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(raw)
        ? raw
        : 'https://$raw';
    try {
      launchUrl(Uri.parse(withScheme), mode: LaunchMode.externalApplication)
          .catchError((_) => false);
    } catch (_) {
      // رابط معطوب: نتجاهل بصمت.
    }
  }

  static String _linkHost(String url) {
    try {
      return Uri.parse(url.trim()).host.replaceFirst('www.', '');
    } catch (_) {
      return url.trim();
    }
  }

  String _formatRelativeDate(String dateStr) {
    if (dateStr == 'الآن') return dateStr;
    try {
      final parts = dateStr.split(' ');
      if (parts.length != 2) return dateStr;
      
      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      
      if (dateParts.length != 3 || timeParts.length != 2) return dateStr;
      
      final postDate = DateTime(
        int.parse(dateParts[0]), 
        int.parse(dateParts[1]), 
        int.parse(dateParts[2]),
      );
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final difference = today.difference(postDate).inDays;
      
      final timeStr = parts[1];
      
      if (difference == 0) {
        return "اليوم $timeStr";
      } else if (difference == 1) {
        return "منذ يوم $timeStr";
      } else if (difference == 2) {
        return "منذ يومين $timeStr";
      } else if (difference >= 3 && difference <= 10) {
        return "منذ $difference أيام $timeStr";
      } else {
        return "منذ $difference يوماً $timeStr";
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        title: const Text('جميع الأخبار', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColor.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.3),
              ),
              onPressed: () => _openFacebook(context),
              icon: const Icon(Icons.facebook),
              label: const Text('تابع صفحتنا على فيسبوك', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailScreen(post: post),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColor.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        if (post.type != 'text' && post.mediaUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                            child: Image.network(
                              post.mediaUrls.first,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                            ),
                            child: const Icon(Icons.newspaper, color: Colors.white24, size: 40),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (post.isFresh() || post.isRepost)
                                      Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: post.isRepost
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : AppColor.primaryColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        post.isRepost ? 'إعادة نشر' : 'جديد',
                                        style: TextStyle(
                                          color: post.isRepost ? Colors.white70 : AppColor.primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(_formatRelativeDate(post.date), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  post.type == 'text' ? post.text : post.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                if ((post.postUrl ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => _openPostLink(post.postUrl!),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.link,
                                            size: 13, color: AppColor.primaryColor),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            _linkHost(post.postUrl!),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColor.primaryColor,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
}
