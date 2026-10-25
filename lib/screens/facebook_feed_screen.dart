import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';

/// شاشة عرض صفحة فيسبوك الإقامة مباشرة
class FacebookFeedScreen extends StatefulWidget {
  const FacebookFeedScreen({super.key});

  @override
  State<FacebookFeedScreen> createState() => _FacebookFeedScreenState();
}

class _FacebookFeedScreenState extends State<FacebookFeedScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isWebViewSupported = false;

  // رابط الصفحة المباشر (نسخة الموبايل تعمل بشكل أفضل في WebView)
  static const String _pageUrl = 'https://m.facebook.com/profile.php?id=100064333142859';

  @override
  void initState() {
    super.initState();
    
    // التحقق من دعم الـ WebView (مدعوم فقط على أندرويد و iOS في هذه المكتبة)
    _isWebViewSupported = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    if (_isWebViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColor.backgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
              _controller.runJavaScript('''
                var header = document.getElementById('header');
                if (header) header.style.display = 'none';
              ''');
            },
            onNavigationRequest: (NavigationRequest request) {
              if (!request.url.contains('facebook.com')) {
                launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_pageUrl));
    } else {
      // توجيه تلقائي على الويب والمكتبي لتجنب كراش الـ WebView
      _isLoading = false;
      _launchExternalUrl();
    }
  }

  void _launchExternalUrl() {
    launchUrl(
      Uri.parse('fb://facewebmodal/f?href=$_pageUrl'),
      mode: LaunchMode.externalApplication,
    ).catchError((_) {
      return launchUrl(Uri.parse(_pageUrl), mode: LaunchMode.externalApplication);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        backgroundColor: AppColor.surfaceColor,
        title: const Text('صفحة فيسبوك الإقامة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'فتح في التطبيق',
            onPressed: _launchExternalUrl,
          ),
          if (_isWebViewSupported)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _isLoading = true);
                _controller.reload();
              },
            ),
        ],
      ),
      body: _isWebViewSupported
          ? Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColor.primaryColor),
                        SizedBox(height: 16),
                        Text('جاري تحميل فيسبوك مباشرة...', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
              ],
            )
          : Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.blueAccent.withValues(alpha: 0.15), Colors.transparent],
                  radius: 1.2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2), width: 2),
                      ),
                      child: const Icon(Icons.facebook, size: 64, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'صفحة الإقامة الرسمية 🌐',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'بسبب قيود المتصفح المدمج على الويب والأجهزة المكتبية، يرجى تصفح الصفحة الرسمية للإقامة مباشرة في علامة تبويب جديدة لتجربة أسرع وأكثر سلاسة.',
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                      ),
                      onPressed: _launchExternalUrl,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('الانتقال إلى صفحة فيسبوك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('العودة للرئيسية', style: TextStyle(color: Colors.white38)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
