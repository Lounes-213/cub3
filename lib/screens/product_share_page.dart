import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';

/// علم عام: هل صفحة الغرض المستقلة مفتوحة حالياً؟
/// يُستعمل لتجنّب فتحها مرتين (من onGenerateRoute ومن فحص الرابط عند الإقلاع).
bool isProductSharePageOpen = false;

/// =====================================================================
/// صفحة الغرض المستقلة (تفتح من رابط المشاركة `/p/<id>` خارج التطبيق)
/// صفحة خفيفة لا تحتاج تسجيل دخول ولا تدخل في تطبيق cube3.
/// الرابط: `https://cube3-dz.pages.dev/p/<id>`
/// =====================================================================
class ProductSharePage extends StatefulWidget {
  final String productId;
  const ProductSharePage({super.key, required this.productId});

  @override
  State<ProductSharePage> createState() => _ProductSharePageState();
}

class _ProductSharePageState extends State<ProductSharePage> {
  final MarketplaceService _service = MarketplaceService();
  MarketplaceItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    isProductSharePageOpen = true;
    _load();
  }

  @override
  void dispose() {
    isProductSharePageOpen = false;
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // API واحد خفيف: جلب الغرض مباشرة بمعرّفه
      final item = await _service.getProductById(widget.productId);

      // معرّف متغيّر الحالة (آخر حرف قد يكون كبيراً أو صغيراً)؟ نجرّب الحالة الأخرى.
      MarketplaceItem? found = item;
      if (found == null &&
          widget.productId.isNotEmpty &&
          widget.productId.length > 1) {
        final needle = widget.productId;
        final last = needle.substring(needle.length - 1);
        if (last == last.toLowerCase() && last == last.toUpperCase()) {
          final alt = needle.substring(0, needle.length - 1) + last.toUpperCase();
          found = await _service.getProductById(alt);
        }
      }

      if (mounted) setState(() { _item = found; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openApp() {
    const appUrl = 'https://cube3-dz.pages.dev/';
    launchUrl(Uri.parse(appUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _whatsapp(String phone, String title) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final num = clean.startsWith('0') ? '213${clean.substring(1)}' : clean;
    final uri = Uri.parse(
        'https://wa.me/$num?text=${Uri.encodeComponent('السلام عليكم، بخصوص إعلانك: $title')}');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor))
          : (_item == null ? _buildNotFound() : _buildProduct(_item!)),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 54, color: AppColor.primaryColor),
            ),
            const SizedBox(height: 18),
            const Text('هذا الغرض غير موجود',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('قد يكون تم حذفه أو بيعه.',
                style: TextStyle(color: AppColor.textMuted, fontSize: 12.5)),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: AppColor.primaryColor),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(
                      color: AppColor.primaryColor,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduct(MarketplaceItem item) {
    final isSold = item.isSold;
    final isFree = !isSold && item.isFree;
    final priceText = isFree
        ? 'مجاني / إعارة'
        : item.formattedPrice;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== الشعار + العنوان =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_rounded,
                          size: 14, color: AppColor.primaryColor),
                      SizedBox(width: 6),
                      Text('سوق الطلبة — cube3',
                          style: TextStyle(
                              color: AppColor.primaryColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ===== صورة المنتج =====
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: Container(
                  color: AppColor.cardLight,
                  child: item.hasImages
                      ? Image.network(item.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                              child: Icon(item.categoryIcon,
                                  color: item.categoryColor.withValues(alpha: 0.5),
                                  size: 60)))
                      : Center(
                          child: Icon(item.categoryIcon,
                              color: item.categoryColor.withValues(alpha: 0.65),
                              size: 64)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== الفئة + الحالة =====
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(item.categoryIcon, item.categoryLabelAr, item.categoryColor),
                if (isSold) _chip(Icons.check_circle, 'تم البيع', AppColor.correctColor),
                if (isFree) _chip(Icons.card_giftcard, 'مجاني / إعارة', AppColor.correctColor),
              ],
            ),
            const SizedBox(height: 14),

            // ===== العنوان =====
            Text(item.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.25)),
            const SizedBox(height: 12),

            // ===== السعر =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sell_rounded,
                      color: AppColor.primaryColor, size: 26),
                  const SizedBox(width: 12),
                  Text(isSold ? 'غير متوفر' : priceText,
                      style: TextStyle(
                          color: isSold
                              ? Colors.white38
                              : (isFree ? AppColor.correctColor : AppColor.primaryColor),
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ===== الوصف =====
            if (item.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColor.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(item.description,
                    style: TextStyle(
                        color: AppColor.textSecondary, fontSize: 13, height: 1.6)),
              ),
              const SizedBox(height: 12),
            ],

            // ===== معلومات البائع =====
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColor.primaryColor,
                    radius: 20,
                    child: Icon(Icons.person, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.sellerName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(
                          item.pavilion.isNotEmpty
                              ? '${item.pavilion}${item.roomNumber.isNotEmpty ? ' · غرفة ${item.roomNumber}' : ''}'
                              : 'طالب بالإقامة الجامعية',
                          style: TextStyle(color: AppColor.textMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ===== أزرار التواصل =====
            if (!isSold) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.correctColor,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('اتصال',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: () => _call(item.cleanPhone),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('واتساب',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: () => _whatsapp(item.cleanPhone, item.title),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ===== زر فتح التطبيق (اختياري) =====
            TextButton.icon(
              onPressed: _openApp,
              icon: Icon(Icons.open_in_new_rounded,
                  size: 15, color: AppColor.textMuted),
              label: const Text('فتح التطبيق لاستكشاف المزيد من الأغراض',
                  style: TextStyle(
                      color: AppColor.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
