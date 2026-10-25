import '../../widgets/glass_app_bar.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../models/facebook_post.dart';
import '../../services/news_service.dart';
import 'post_editor_screen.dart';

/// إدارة منشورات الإقامة — المدير ينشر/يحذف، والصور تُحفظ في R2.
/// - الحد الأقصى 100 منشور (لحماية التخزين)
/// - صور فقط، بحد 5MB للصورة
/// - حذف منشور يحذف صوره من التخزين تلقائياً (الباك-اند)
class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final NewsService _news = NewsService();

  List<FacebookPost> _posts = [];
  bool _loading = true;
  String? _error;
  final Set<String> _deletingIds = {};
  final Set<String> _togglingIds = {};

  /// تبديل سريع: يتحرك في الرئيسية / مخفي من الرئيسية.
  Future<void> _toggleCarousel(FacebookPost post) async {
    final next = !post.inCarousel;
    setState(() {
      _togglingIds.add(post.id);
      _posts = [
        for (final p in _posts)
          p.id == post.id ? _withCarousel(p, next) : p,
      ];
    });
    try {
      await _news.setInCarousel(post: post, inCarousel: next);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next
              ? 'المنشور يتحرك الآن في الرئيسية'
              : 'المنشور أُخفي من الرئيسية (يبقى في «مزيد»)'),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _posts = [
            for (final p in _posts)
              p.id == post.id ? _withCarousel(p, !next) : p,
          ];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحفظ — تحقق من الاتصال')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingIds.remove(post.id));
    }
  }

  static FacebookPost _withCarousel(FacebookPost p, bool v) => FacebookPost(
        id: p.id,
        title: p.title,
        text: p.text,
        type: p.type,
        mediaUrls: p.mediaUrls,
        videoUrl: p.videoUrl,
        date: p.date,
        isRepost: p.isRepost,
        originalPageName: p.originalPageName,
        postUrl: p.postUrl,
        inCarousel: v,
      );

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _posts = await _news.fetchAdminPosts();
    } catch (e) {
      _error = 'تعذر تحميل المنشورات';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmDelete(FacebookPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المنشور؟'),
        content: Text(
          'سيتم حذف "${post.title.isEmpty ? 'بدون عنوان' : post.title}" نهائياً مع صوره من التخزين لتوفير المساحة.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deletingIds.add(post.id));
    try {
      await _news.deletePost(post.id);
      if (mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
          _deletingIds.remove(post.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المنشور وصوره من التخزين 🗑️')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deletingIds.remove(post.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحذف — تحقق من الاتصال')),
        );
      }
    }
  }

  void _openEditor([FacebookPost? post]) {
    if (post == null && _posts.length >= NewsService.maxPosts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('وصلت للحد الأقصى (100 منشور). احذف منشوراً قديماً أولاً.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostEditorScreen(
          news: _news,
          onSaved: _reload,
          post: post,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _posts.length;
    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('منشورات الإقامة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('منشور جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: AppColor.primaryColor,
        onRefresh: _reload,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColor.primaryColor))
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.redAccent))),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton(
                            onPressed: _reload, child: const Text('إعادة المحاولة')),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildQuotaCard(count),
                      const SizedBox(height: 12),
                      if (_posts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.newspaper_outlined,
                                  size: 48, color: Colors.white24),
                              SizedBox(height: 12),
                              Text('لا توجد منشورات بعد',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 14)),
                              SizedBox(height: 4),
                              Text('انشر أول منشور ليظهر في الصفحة الرئيسية',
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ..._posts.map(_buildPostTile),
                      const SizedBox(height: 90),
                    ],
                  ),
      ),
    );
  }

  Widget _buildQuotaCard(int count) {
    final ratio = count / NewsService.maxPosts;
    final nearFull = ratio >= 0.9;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (nearFull ? Colors.orangeAccent : AppColor.primaryColor)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('مساحة المنشورات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$count / ${NewsService.maxPosts}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: nearFull
                          ? Colors.orangeAccent
                          : AppColor.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                  nearFull ? Colors.orangeAccent : AppColor.primaryColor),
            ),
          ),
          if (nearFull)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('التخزين شبه ممتلئ — احذف المنشورات القديمة',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildPostTile(FacebookPost post) {
    final isDeleting = _deletingIds.contains(post.id);
    final thumb = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColor.surfaceColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: thumb != null
              ? Image.network(thumb,
                  width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                      width: 52,
                      height: 52,
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image,
                          color: Colors.white24, size: 22)))
              : Container(
                  width: 52,
                  height: 52,
                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.article_outlined,
                      color: AppColor.primaryColor, size: 24)),
        ),
        title: Text(
          post.title.isEmpty ? '(بدون عنوان)' : post.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${post.text} • ${post.date}',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isDeleting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _togglingIds.contains(post.id)
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: Icon(
                            post.inCarousel
                                ? Icons.view_carousel_outlined
                                : Icons.view_carousel,
                            color: post.inCarousel
                                ? AppColor.primaryColor
                                : Colors.white24,
                            size: 20,
                          ),
                          tooltip: post.inCarousel
                              ? 'يتحرك في الرئيسية — اضغط للإخفاء'
                              : 'مخفي من الرئيسية — اضغط للإظهار',
                          onPressed: () => _toggleCarousel(post),
                        ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColor.primaryColor),
                    tooltip: 'تعديل المنشور',
                    onPressed: () => _openEditor(post),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    tooltip: 'حذف المنشور وصوره',
                    onPressed: () => _confirmDelete(post),
                  ),
                ],
              ),
      ),
    ),
    );
  }
}

