import 'dart:convert';
import '../../widgets/glass_app_bar.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../core/utils/image_pick.dart';
import '../../core/utils/photo_utils.dart';
import '../../models/pub_item.dart';
import '../../services/pubs_service.dart';
import '../../services/news_service.dart';

/// إدارة إعلانات الإقامة (pubs): صور + روابط + جدولة.
/// المدير وحده يتحكم في كل واجهات التطبيق من هنا.
class AdminPubsScreen extends StatefulWidget {
  const AdminPubsScreen({super.key});

  @override
  State<AdminPubsScreen> createState() => _AdminPubsScreenState();
}

class _AdminPubsScreenState extends State<AdminPubsScreen> {
  final PubsService _pubs = PubsService();

  List<PubItem> _items = [];
  bool _loading = true;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      _items = await _pubs.fetchPubs();
    } catch (_) {
      _items = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmDelete(PubItem pub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الإعلان؟'),
        content: const Text(
            'سيتم حذف الإعلان نهائياً مع صورته من التخزين.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف نهائي',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting.add(pub.id));
    try {
      await _pubs.deletePub(pub.id);
      if (mounted) {
        setState(() {
          _items.removeWhere((p) => p.id == pub.id);
          _deleting.remove(pub.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الإعلان 🗑️')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deleting.remove(pub.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحذف — تحقق من الاتصال')),
        );
      }
    }
  }

  void _openEditor({PubItem? existing}) {
    showDialog(
      context: context,
      builder: (_) => _PubEditorDialog(
        pubs: _pubs,
        existing: existing,
        onSaved: _reload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('إعلانات الإقامة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('إعلان جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: AppColor.primaryColor,
        onRefresh: _reload,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColor.primaryColor))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 48, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('لا توجد إعلانات بعد',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('أنشئ إعلاناً ليظهر في الصفحة الرئيسية',
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ..._items.map(_buildTile),
                  const SizedBox(height: 90),
                ],
              ),
      ),
    );
  }

  Widget _buildTile(PubItem pub) {
    final deleting = _deleting.contains(pub.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColor.surfaceColor.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: pub.isVisibleNow
                ? AppColor.correctColor.withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: pub.imageUrl != null && pub.imageUrl!.isNotEmpty
              ? Image.network(pub.imageUrl!,
                  width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                      width: 52,
                      height: 52,
                      color: Colors.white10,
                      child: const Icon(Icons.campaign,
                          color: AppColor.primaryColor)))
              : Container(
                  width: 52,
                  height: 52,
                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.campaign_outlined,
                      color: AppColor.primaryColor)),
        ),
        title: Text(
          pub.title.isEmpty ? '(بدون عنوان)' : pub.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          pub.isVisibleNow ? '● ظاهر الآن' : '○ مخفي/مجدول',
          style: TextStyle(
              color: pub.isVisibleNow
                  ? AppColor.correctColor
                  : Colors.white38,
              fontSize: 11),
        ),
        trailing: deleting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: Colors.white54),
                    onPressed: () => _openEditor(existing: pub),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _confirmDelete(pub),
                  ),
                ],
              ),
      ),
    ),
    );
  }
}

class _PubEditorDialog extends StatefulWidget {
  final PubsService pubs;
  final PubItem? existing;
  final VoidCallback onSaved;
  const _PubEditorDialog(
      {required this.pubs,
      this.existing,
      required this.onSaved});

  @override
  State<_PubEditorDialog> createState() => _PubEditorDialogState();
}

class _PubEditorDialogState extends State<_PubEditorDialog> {
  late TextEditingController _title;
  late TextEditingController _text;
  late TextEditingController _link;
  late TextEditingController _start;
  late TextEditingController _end;
  String? _imageUrl;
  bool _active = true;
  bool _uploading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _text = TextEditingController(text: e?.text ?? '');
    _link = TextEditingController(text: e?.link ?? '');
    _start = TextEditingController(text: e?.startDate ?? '');
    _end = TextEditingController(text: e?.endDate ?? '');
    _imageUrl = e?.imageUrl;
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _link.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController target) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(target.text) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      target.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _changeImage() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      // منتقي موحد: معرض الهاتف، ومدخل ملف أصلي على الويب (يفتح دائماً)
      final picked = await pickPostImage();
      if (picked == null) {
        setState(() => _uploading = false);
        return;
      }
      if (picked.bytes.length > 5 * 1024 * 1024) {
        throw Exception('الصورة كبيرة جداً (الحد 5MB)');
      }
      final url = await NewsService()
          .uploadImage(base64Encode(picked.bytes), mime: picked.mime);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = cleanUploadErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty &&
        _text.text.trim().isEmpty &&
        (_imageUrl ?? '').isEmpty) {
      setState(() => _error = 'أضف عنواناً أو نصاً أو صورة أولاً');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.pubs.savePub(
        id: widget.existing?.id,
        title: _title.text,
        text: _text.text,
        imageUrl: _imageUrl,
        link: _link.text.trim().isEmpty ? null : _link.text.trim(),
        startDate: _start.text.trim().isEmpty ? null : _start.text.trim(),
        endDate: _end.text.trim().isEmpty ? null : _end.text.trim(),
        isActive: _active,
      );
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعلان ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.existing == null ? 'إعلان جديد' : 'تعديل الإعلان',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageUrl != null && _imageUrl!.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_imageUrl!,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                            height: 130,
                            child: Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.white24)))),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                        onPressed: () =>
                            setState(() => _imageUrl = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _uploading ? null : _changeImage,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.image_outlined),
                label: Text(_uploading ? 'جاري الرفع...' : 'صورة الإعلان'),
              ),
            const SizedBox(height: 10),
            _f(_title, 'العنوان'),
            const SizedBox(height: 10),
            _f(_text, 'نص الإعلان...', maxLines: 3),
            const SizedBox(height: 10),
            _f(_link, 'الرابط عند الضغط (اختياري)',
                keyboard: TextInputType.url),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _f(_start, 'البداية',
                      suffix: IconButton(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          onPressed: () => _pickDate(_start))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _f(_end, 'النهاية',
                      suffix: IconButton(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          onPressed: () => _pickDate(_end))),
                ),
              ],
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('إعلان مفعّل',
                  style: TextStyle(fontSize: 13)),
              value: _active,
              activeThumbColor: AppColor.primaryColor,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_error != null)
              Text(_error!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primaryColor,
            foregroundColor: Colors.black,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : const Text('حفظ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _f(TextEditingController c, String hint,
      {int maxLines = 1, TextInputType? keyboard, Widget? suffix}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: AppColor.backgroundColor,
        suffixIcon: suffix,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
