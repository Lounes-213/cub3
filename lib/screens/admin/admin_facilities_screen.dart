import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme.dart';
import '../../models/facility_data.dart';
import '../../providers/app_config_provider.dart';
import '../../services/facility_service.dart';
import '../../core/utils/image_pick.dart';
import '../../core/utils/photo_utils.dart';
import '../../widgets/image_viewer_dialog.dart';

/// الشاشة الاحترافية لإدارة الأجنحة والمرافق:
/// - برمجة رقم هاتف رئيس الجناح أو مسؤول المرفق
/// - رفع حتى 3 صور كحد أقصى لكل جناح/مرفق
/// - حذف الصور ومسحها فورياً من التخزين السحابي Cloudflare R2
class AdminFacilitiesScreen extends StatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  State<AdminFacilitiesScreen> createState() => _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends State<AdminFacilitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FacilityService _facilityService = FacilityService();
  String _searchQuery = '';
  final Set<String> _uploadingFacilities = {};

  // الأجنحة الافتراضية
  final List<_DefaultFacilityItem> _defaultPavilions = [
    _DefaultFacilityItem('جناح A', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح B', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح C', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح D', 'pavilion', Icons.business,
        defaultDedication: 'إهداء للعزيز D36 🌹'),
    _DefaultFacilityItem('جناح E', 'pavilion', Icons.business,
        defaultDedication: 'إهداء لـ E23.. الأسرار والأنوار ✨'),
    _DefaultFacilityItem('جناح F', 'pavilion', Icons.business,
        defaultDedication: 'إهداء لـ ناس F47 و F51 ❤️'),
    _DefaultFacilityItem('جناح G', 'pavilion', Icons.business,
        defaultDedication: 'إهداء للزعيم G36 👑'),
    _DefaultFacilityItem('جناح H', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح I', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح J', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح K', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح L', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح M', 'pavilion', Icons.business),
    _DefaultFacilityItem('جناح N', 'pavilion', Icons.business),
  ];

  // المرافق العامة والخدمات
  final List<_DefaultFacilityItem> _defaultServices = [
    _DefaultFacilityItem('مطعم الإقامة', 'service', Icons.restaurant),
    _DefaultFacilityItem('وجبات سريعة', 'service', Icons.fastfood),
    _DefaultFacilityItem('مصلى الاعتصام', 'service', Icons.mosque),
    _DefaultFacilityItem('المتجر', 'service', Icons.shopping_cart),
    _DefaultFacilityItem('المرشات', 'service', Icons.shower),
    _DefaultFacilityItem('ملعب الإقامة', 'service', Icons.sports_soccer),
    _DefaultFacilityItem('ملعب رملي', 'service', Icons.sports_volleyball),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // رفع صورة جديدة للمرفق
  Future<void> _pickAndUploadImage(
      BuildContext context, FacilityData facility) async {
    if (facility.images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ الحد الأقصى هو 3 صور لكل جناح أو مرفق'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    try {
      final picked = await pickPostImage();
      if (picked == null) return;

      setState(() => _uploadingFacilities.add(facility.name));

      final imageUrl = await _facilityService.uploadFacilityImage(
        picked.bytes,
        mime: picked.mime,
      );

      final updatedImages = List<String>.from(facility.images)..add(imageUrl);
      final updated = facility.copyWith(images: updatedImages);

      if (!context.mounted) return;
      await context.read<AppConfigProvider>().saveFacility(updated);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفع الصورة بنجاح وتحديث الجناح ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanUploadErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingFacilities.remove(facility.name));
      }
    }
  }

  // حذف صورة ومسحها من التخزين السحابي Cloudflare R2
  Future<void> _confirmDeleteImage(
      BuildContext context, FacilityData facility, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('حذف الصورة؟',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: const Text(
          'سيتم حذف هذه الصورة نهائياً ومسحها من التخزين السحابي لتوفير المساحة.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف من التخزين'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await context
          .read<AppConfigProvider>()
          .deleteFacilityImage(facility.name, imageUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الصورة من التخزين السحابي 🗑️'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذّر الحذف — تحقق من الاتصال وحاول مرة أخرى'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // فتح نافذة تعديل بيانات الجناح (رقم الهاتف، الاسم، الملاحظات)
  void _openFacilityEditor(BuildContext context, FacilityData facility) {
    showDialog(
      context: context,
      builder: (_) => _FacilityEditDialog(
        facility: facility,
        onSave: (updated) async {
          await context.read<AppConfigProvider>().saveFacility(updated);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حفظ بيانات الجناح بنجاح ✅'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigProvider>().config;

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text(
          'إدارة الأجنحة والمرافق 🏢🗺️',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColor.primaryColor,
          indicatorWeight: 3,
          labelColor: AppColor.primaryColor,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.apartment), text: 'أجنحة الطلبة (Pavillons)'),
            Tab(icon: Icon(Icons.hub_outlined), text: 'المرافق والخدمات'),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث عن جناح أو مرفق...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColor.primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: AppColor.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: AppColor.primaryColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: AppColor.primaryColor.withValues(alpha: 0.15)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFacilitiesList(
                  items: _defaultPavilions,
                  config: config,
                  isPavilion: true,
                ),
                _buildFacilitiesList(
                  items: _defaultServices,
                  config: config,
                  isPavilion: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesList({
    required List<_DefaultFacilityItem> items,
    required dynamic config,
    required bool isPavilion,
  }) {
    final filtered = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('لا توجد نتائج تطابق بحثك',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final defItem = filtered[index];
        final facility = config.getFacility(
          defItem.name,
          defaultType: defItem.type,
          defaultDedication: defItem.defaultDedication,
        );

        final isUploading = _uploadingFacilities.contains(facility.name);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColor.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isPavilion
                  ? AppColor.primaryColor.withValues(alpha: 0.25)
                  : AppColor.accentColor.withValues(alpha: 0.25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isPavilion
                                ? AppColor.primaryColor
                                : AppColor.accentColor)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        defItem.icon,
                        color: isPavilion
                            ? AppColor.primaryColor
                            : AppColor.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facility.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isPavilion ? 'إقامة طلبة' : 'مرفق خدمي عام',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // زر التعديل الشامل
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColor.primaryColor),
                      tooltip: 'تعديل البيانات ورقم الهاتف',
                      onPressed: () => _openFacilityEditor(context, facility),
                    ),
                  ],
                ),

                if (facility.dedication.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColor.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      facility.dedication,
                      style: const TextStyle(
                        color: AppColor.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),

                // قسم رقم هاتف رئيس الجناح
                Row(
                  children: [
                    Icon(
                      facility.hasChiefPhone
                          ? Icons.phone_in_talk
                          : Icons.phone_disabled_outlined,
                      color: facility.hasChiefPhone
                          ? Colors.greenAccent
                          : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPavilion
                                ? (facility.chiefName.isNotEmpty
                                    ? facility.chiefName
                                    : 'رقم رئيس الجناح')
                                : (facility.chiefName.isNotEmpty
                                    ? facility.chiefName
                                    : 'رقم مسؤول المرفق'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            facility.hasChiefPhone
                                ? facility.chiefPhone
                                : 'لم يُبرمج بعد — اضغط لتحديده',
                            style: TextStyle(
                              color: facility.hasChiefPhone
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 13,
                              fontWeight: facility.hasChiefPhone
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              letterSpacing: facility.hasChiefPhone ? 1.0 : 0,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                    if (facility.hasChiefPhone) ...[
                      IconButton(
                        icon: const Icon(Icons.copy,
                            size: 16, color: Colors.white54),
                        tooltip: 'نسخ الرقم',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: facility.chiefPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الرقم 📋'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.call,
                            size: 18, color: Colors.greenAccent),
                        tooltip: 'اتصال تجريبي',
                        onPressed: () {
                          launchUrl(
                            Uri.parse('tel:${facility.cleanPhone}'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ] else
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('إضافة رقم',
                            style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColor.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _openFacilityEditor(context, facility),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),

                // قسم الصور (3 صور كحد أقصى)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 16, color: AppColor.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'صور الجناح (${facility.images.length}/3)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (facility.images.length < 3)
                      TextButton.icon(
                        icon: isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.primaryColor,
                                ),
                              )
                            : const Icon(Icons.add_a_photo_outlined, size: 16),
                        label: Text(
                          isUploading ? 'جاري الرفع...' : 'إضافة صورة',
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColor.primaryColor,
                        ),
                        onPressed: isUploading
                            ? null
                            : () => _pickAndUploadImage(context, facility),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'الحد الأقصى مكتمل (3/3)',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // عرض شبكة الصور الحالية
                if (facility.images.isNotEmpty)
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: facility.images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, imgIndex) {
                        final imgUrl = facility.images[imgIndex];
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => ImageViewerDialog.show(
                                context,
                                images: facility.images,
                                initialIndex: imgIndex,
                                title: facility.name,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imgUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, prog) {
                                    if (prog == null) return child;
                                    return Container(
                                      width: 90,
                                      height: 90,
                                      color: Colors.white10,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, _, _) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white30),
                                  ),
                                ),
                              ),
                            ),
                            // زر حذف الصورة
                            Positioned(
                              top: -4,
                              left: -4,
                              child: GestureDetector(
                                onTap: () => _confirmDeleteImage(
                                    context, facility, imgUrl),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported_outlined,
                            size: 18, color: Colors.white30),
                        const SizedBox(width: 8),
                        Text(
                          'لا توجد صور بعد لهذا ${isPavilion ? 'الجناح' : 'المرفق'} (أضف حتى 3 صور)',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DefaultFacilityItem {
  final String name;
  final String type;
  final IconData icon;
  final String? defaultDedication;

  _DefaultFacilityItem(this.name, this.type, this.icon,
      {this.defaultDedication});
}

/// نافذة تعديل بيانات الجناح (رقم الهاتف، الاسم، الملاحظات)
class _FacilityEditDialog extends StatefulWidget {
  final FacilityData facility;
  final Future<void> Function(FacilityData updated) onSave;

  const _FacilityEditDialog({
    required this.facility,
    required this.onSave,
  });

  @override
  State<_FacilityEditDialog> createState() => _FacilityEditDialogState();
}

class _FacilityEditDialogState extends State<_FacilityEditDialog> {
  late TextEditingController _phoneController;
  late TextEditingController _chiefNameController;
  late TextEditingController _dedicationController;
  late TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phoneController =
        TextEditingController(text: widget.facility.chiefPhone);
    _chiefNameController =
        TextEditingController(text: widget.facility.chiefName);
    _dedicationController =
        TextEditingController(text: widget.facility.dedication);
    _notesController = TextEditingController(text: widget.facility.notes);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _chiefNameController.dispose();
    _dedicationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final updated = widget.facility.copyWith(
        chiefPhone: _phoneController.text.trim(),
        chiefName: _chiefNameController.text.trim(),
        dedication: _dedicationController.text.trim(),
        notes: _notesController.text.trim(),
      );
      await widget.onSave(updated);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPavilion = widget.facility.isPavilion;

    return AlertDialog(
      backgroundColor: AppColor.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(isPavilion ? Icons.apartment : Icons.hub_outlined,
              color: AppColor.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'برمجة: ${widget.facility.name}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حقل رقم هاتف رئيس الجناح
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: isPavilion
                    ? 'رقم هاتف رئيس الجناح *'
                    : 'رقم هاتف مسؤول المرفق *',
                hintText: 'مثال: 0550123456 أو 0661...',
                prefixIcon: const Icon(Icons.phone, color: Colors.greenAccent),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            // اسم أو لقب المسؤول
            TextField(
              controller: _chiefNameController,
              decoration: InputDecoration(
                labelText: isPavilion
                    ? 'اسم أو صفة رئيس الجناح (اختياري)'
                    : 'اسم أو صفة المسؤول (اختياري)',
                hintText: 'مثال: رئيس الجناح أ. كمال',
                prefixIcon: const Icon(Icons.person, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            // الإهداء الخاص للجناح
            TextField(
              controller: _dedicationController,
              decoration: InputDecoration(
                labelText: 'إهداء أو رسالة الجناح (اختياري)',
                hintText: 'مثال: إهداء لـ طلبة الغرفة 24 🌹',
                prefixIcon:
                    const Icon(Icons.favorite_border, color: Colors.amber),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            // ملاحظات إضافية
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظات أو مواعيد العمل (اختياري)',
                hintText: 'مثال: متاح طوال أيام الأسبوع',
                prefixIcon:
                    const Icon(Icons.notes_outlined, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primaryColor,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : const Text('حفظ التغييرات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
