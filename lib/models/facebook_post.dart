class FacebookPost {
  final String id;
  final String title;
  final String text;
  final String type; // 'photo', 'video', 'text', 'repost'
  final List<String> mediaUrls;
  final String? videoUrl;
  final String date;
  final bool isRepost;
  final String? originalPageName;
  final String? postUrl;

  /// true = يظهر في الكاروسيل المتحرك بالرئيسية، false = مخفي من الرئيسية.
  final bool inCarousel;

  FacebookPost({
    required this.id,
    required this.title,
    required this.text,
    required this.type,
    this.mediaUrls = const [],
    this.videoUrl,
    required this.date,
    this.isRepost = false,
    this.originalPageName,
    this.postUrl,
    this.inCarousel = true,
  });

  factory FacebookPost.fromJson(Map<String, dynamic> json) {
    return FacebookPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      videoUrl: json['videoUrl'],
      date: json['date'] ?? '',
      isRepost: json['isRepost'] ?? false,
      originalPageName: json['originalPageName'],
      postUrl: json['postUrl'],
      inCarousel: json['inCarousel'] != false,
    );
  }

  /// منشور جديد: مشاركة أقل من `withinDays` يوماً (يُعرض له بادج «جديد»)
  bool isFresh({int withinDays = 15}) {
    final post = _parseDate();
    if (post == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final posted = DateTime(post.year, post.month, post.day);
    return today.difference(posted).inDays < withinDays;
  }

  DateTime? _parseDate() {
    final raw = date.trim();
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw.replaceAll(' ', 'T'));
    if (iso != null) return iso;
    final parts = raw.split(' ');
    if (parts.length < 2) return null;
    final dp = parts[0].split('/');
    final tp = parts[1].split(':');
    if (dp.length != 3 || tp.length < 2) return null;
    final a = int.tryParse(dp[0]) ?? 0;
    final b = int.tryParse(dp[1]) ?? 0;
    final c = int.tryParse(dp[2]) ?? 0;
    final h = int.tryParse(tp[0]) ?? 0;
    final m = int.tryParse(tp[1]) ?? 0;
    if (dp[0].length == 4) return DateTime(a, b, c, h, m);
    if (dp[2].length == 4) return DateTime(c, b, a, h, m);
    return null;
  }
}
