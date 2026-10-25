import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../models/facebook_post.dart';

class NewsDetailScreen extends StatefulWidget {
  final FacebookPost post;

  const NewsDetailScreen({super.key, required this.post});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  WebViewController? _webViewController;
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.post.type == 'video' && widget.post.videoUrl != null) {
      final encodedUrl = Uri.encodeComponent(widget.post.videoUrl!);
      final embedUrl = 'https://www.facebook.com/plugins/video.php?href=$encodedUrl&show_text=0&width=560';
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) setState(() => _isVideoLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(embedUrl));
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: GlassAppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true, // Allow panning
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 1,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: CustomScrollView(
        slivers: [
          if (post.type != 'text' && post.mediaUrls.isNotEmpty)
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              backgroundColor: AppColor.surfaceColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (post.type == 'video' && _webViewController != null)
                      Stack(
                        children: [
                          WebViewWidget(controller: _webViewController!),
                          if (_isVideoLoading)
                            const Center(child: CircularProgressIndicator(color: AppColor.primaryColor)),
                        ],
                      )
                    else if (post.type == 'photo' && post.mediaUrls.length > 1)
                      PageView.builder(
                        itemCount: post.mediaUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _openFullScreenImage(context, post.mediaUrls[index]),
                            child: Image.network(
                              post.mediaUrls[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      )
                    else
                      GestureDetector(
                        onTap: () => _openFullScreenImage(context, post.mediaUrls.first),
                        child: Image.network(
                          post.mediaUrls.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                    
                    // Photo Indicator Overlay
                    if (post.type == 'photo' && post.mediaUrls.length > 1)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.photo_library, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('1 / ${post.mediaUrls.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            const SliverAppBar(
              pinned: true,
              backgroundColor: AppColor.backgroundColor,
              title: Text('التفاصيل'),
            ),
            
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.isRepost ? 'إعادة نشر 🔁' : 'أخبار الإقامة',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ).animate().fadeIn().slideX(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      Text(post.date, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ).animate().fadeIn(delay: 400.ms),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Colors.white10),
                  ),

                  // Repost Original Page Indicator
                  if (post.isRepost && post.originalPageName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.share, color: Colors.white54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('تمت إعادة النشر من:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                Text(post.originalPageName!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    post.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.8,
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                  if ((post.postUrl ?? '').isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _LinkCard(url: post.postUrl!)
                        .animate()
                        .fadeIn(delay: 750.ms)
                        .slideY(begin: 0.1),
                  ],

                  const SizedBox(height: 48),



                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة الرابط المرفق بالمنشور — ضغطة واحدة تفتحه في المتصفح/التطبيق.
class _LinkCard extends StatelessWidget {
  final String url;
  const _LinkCard({required this.url});

  String get _host {
    try {
      return Uri.parse(url.trim()).host.replaceFirst('www.', '');
    } catch (_) {
      return url.trim();
    }
  }

  Future<void> _open() async {
    final raw = url.trim();
    if (raw.isEmpty) return;
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(raw)
        ? raw
        : 'https://$raw';
    try {
      final uri = Uri.parse(withScheme);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // رابط معطوب: نتجاهل بصمت بدل رسالة تقنية.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              const Icon(Icons.link, color: AppColor.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('رابط المنشور',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      _host.isEmpty ? url : _host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded,
                  color: AppColor.primaryColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
