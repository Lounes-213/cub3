/// إعلان/pub مبرمج من لوحة الإدارة (صورة + نص + رابط + جدولة).
class PubItem {
  final String id;
  final String title;
  final String text;
  final String? imageUrl;
  final String? link;
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd
  final bool isActive;

  PubItem({
    required this.id,
    this.title = '',
    this.text = '',
    this.imageUrl,
    this.link,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory PubItem.fromJson(Map<String, dynamic> j) => PubItem(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        imageUrl: j['imageUrl']?.toString(),
        link: j['link']?.toString(),
        startDate: j['startDate']?.toString(),
        endDate: j['endDate']?.toString(),
        isActive: j['isActive'] == true || j['isActive'] == 1,
      );

  /// ظاهر الآن؟ (مفعّل + داخل التواريخ)
  bool get isVisibleNow {
    if (!isActive) return false;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (startDate != null && startDate!.trim().isNotEmpty) {
        final s = DateTime.tryParse(startDate!);
        if (s != null && today.isBefore(DateTime(s.year, s.month, s.day))) {
          return false;
        }
      }
      if (endDate != null && endDate!.trim().isNotEmpty) {
        final e = DateTime.tryParse(endDate!);
        if (e != null &&
            today.isAfter(DateTime(e.year, e.month, e.day)
                .add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}
