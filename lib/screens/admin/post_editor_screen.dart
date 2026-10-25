import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/image_pick.dart';
import '../../core/utils/photo_utils.dart';
import '../../models/facebook_post.dart';
import '../../services/news_service.dart';
import '../../theme/theme.dart';
import '../../widgets/glass_app_bar.dart';

/// صفحة كاملة (موبايل/ويب) لنشر منشور جديد أو تعديل منشور موجود.
/// الواجهة واحدة: العنوان + النص + الصورة (الصورة إجبارية).
class PostEditorScreen extends StatefulWidget {
  final NewsService news;
  final VoidCallback onSaved;
  final FacebookPost? post;

  const PostEditorScreen({
    super.key,
    required this.news,
    required this.onSaved,
    this.post,
  });

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _textCtrl;
  late final TextEditingController _linkCtrl;
  PickedImageBytes? _image;
  String? _existingImageUrl;
  late bool _inCarousel;

  /// الصورة الأصلية للمنشور وقت فتح الصفحة (ما تتغيرش) —
  /// إذا ما عادت مستعملة بعد الحفظ نحذفها من R2.
  String? _originalImageUrl;

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.post?.title ?? '');
    _textCtrl = TextEditingController(text: widget.post?.text ?? '');
    _linkCtrl = TextEditingController(text: widget.post?.postUrl ?? '');
    _inCarousel = widget.post?.inCarousel ?? true;
    final media = widget.post?.mediaUrls ?? const [];
    if (media.isNotEmpty) {
      _existingImageUrl = media.first;
      _originalImageUrl = media.first;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  /// يُعيد الرابط بعد تطبيعه (يضيف https:// إن نقص) أو null إذا كان فارغاً.
  /// يرمي [ArgumentError] إذا لم يكن رابطاً صالحاً.
  String? _normalizedLink() {
    final raw = _linkCtrl.text.trim();
    if (raw.isEmpty) return null;
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(raw)
        ? raw
        : 'https://$raw';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw ArgumentError('bad-link');
    }
    return withScheme;
  }

  Future<void> _pickImage() async {
    try {
      final picked = await pickPostImage();
      if (picked == null) return;
      if (picked.bytes.length > 5 * 1024 * 1024) {
        setState(() => _error = 'الصورة كبيرة جداً (الحد 5MB). اختر صورة أصغر.');
        return;
      }
      setState(() {
        _image = picked;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'تعذر اختيار الصورة');
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final text = _textCtrl.text.trim();
    if (title.isEmpty && text.isEmpty) {
      setState(() => _error = 'اكتب عنواناً أو نصاً للمنشور أولاً');
      return;
    }
    final hasImage =
        _image != null || (_existingImageUrl ?? '').trim().isNotEmpty;
    if (!hasImage) {
      setState(() => _error = 'الصورة إجبارية — كل منشور لازم يكون فيه صورة');
      return;
    }

    String? link;
    try {
      link = _normalizedLink();
    } on ArgumentError {
      setState(() => _error = 'الرابط غير صالح — مثال: https://example.com');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    String? uploadedUrl;
    try {
      final urls = <String>[];
      if (_image != null) {
        uploadedUrl = await widget.news.uploadImage(
          base64Encode(_image!.bytes),
          mime: _image!.mime,
        );
        urls.add(uploadedUrl);
      } else if ((_existingImageUrl ?? '').trim().isNotEmpty) {
        urls.add(_existingImageUrl!.trim());
      }

      if (_isEditing) {
        await widget.news.updatePost(
          id: widget.post!.id,
          title: title,
          text: text,
          mediaUrls: urls,
          postUrl: link ?? '',
          inCarousel: _inCarousel,
        );
      } else {
        await widget.news.createPost(
          title: title,
          text: text,
          mediaUrls: urls,
          postUrl: link ?? '',
          inCarousel: _inCarousel,
        );
      }

      // حفظ ناجح: الصورة القديمة إذا ما عادت مذكورة نحذفها من R2
      final original = _originalImageUrl;
      if (original != null && original.isNotEmpty && !urls.contains(original)) {
        await widget.news.deleteMedia(original);
      }

      widget.onSaved();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تعديل المنشور' : 'تم نشر المنشور'),
          backgroundColor: AppColor.correctColor,
        ),
      );
    } catch (e) {
      // فشل الحفظ: الصورة الجديدة اللي رُفعت ما نشرش — نحذفها من R2
      // حتى لا تبقى يتيمة، والصورة القديمة تبقى كما هي.
      if (uploadedUrl != null) {
        await widget.news.deleteMedia(uploadedUrl);
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _error = cleanUploadErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black45;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل المنشور' : 'منشور جديد',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Icon(_isEditing ? Icons.save : Icons.publish, size: 20),
              label: Text(
                _isEditing ? 'حفظ التعديلات' : 'نشر المنشور',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _imageCard(),
          const SizedBox(height: 14),
          _sectionLabel('معلومات المنشور', textPrimary),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: textPrimary, fontSize: 15),
            maxLength: 200,
            decoration: _dec('العنوان'),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            style: TextStyle(color: textPrimary, fontSize: 14, height: 1.5),
            decoration: _dec('نص المنشور...'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _linkCtrl,
            style: TextStyle(color: textPrimary, fontSize: 14),
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            maxLength: 500,
            decoration: _dec('رابط اختياري (يظهر أسفل المنشور)'),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColor.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.view_carousel_outlined,
                  size: 18,
                  color: _inCarousel ? AppColor.primaryColor : textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'يتحرك في الصفحة الرئيسية',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _inCarousel
                            ? 'يظهر ضمن الكاروسيل المتحرك (أول 8 منشورات)'
                            : 'مخفي من الرئيسية — يبقى في «مزيد» فقط',
                        style: TextStyle(
                            color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _inCarousel,
                  activeTrackColor: AppColor.primaryColor,
                  onChanged: (v) => setState(() => _inCarousel = v),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            _isEditing
                ? 'التعديلات تنعكس مباشرة على الصفحة الرئيسية.'
                : 'المفعّل «يتحرك» = يظهر في كاروسيل الرئيسية (أول 8). المعطّل = يبقى في «مزيد» فقط.',
            style: TextStyle(color: textSecondary, fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ).animate().fadeIn(duration: 240.ms),
    );
  }

  Widget _imageCard() {
    final hasImage = _image != null || _existingImageUrl != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (hasImage ? AppColor.primaryColor : Colors.redAccent)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_outlined,
                    color: AppColor.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('صورة المنشور',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13.5)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (hasImage ? AppColor.correctColor : Colors.redAccent)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  hasImage ? 'مُضافة' : 'إجبارية',
                  style: TextStyle(
                    color: hasImage ? AppColor.correctColor : Colors.redAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasImage)
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white38, size: 34),
                    const SizedBox(height: 8),
                    Text('اضغط لإضافة صورة',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12.5)),
                  ],
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _image != null
                    ? Image.memory(_image!.bytes, fit: BoxFit.cover)
                    : Image.network(
                        _existingImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white24, size: 32),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('تغيير الصورة'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _image = null;
                    _existingImageUrl = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 13,
          decoration: BoxDecoration(
            color: AppColor.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
              height: 1, color: Colors.white.withValues(alpha: 0.07)),
        ),
      ],
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: AppColor.surfaceColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}
