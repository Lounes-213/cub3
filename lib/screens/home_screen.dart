import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/app_config_provider.dart';
import '../core/utils/photo_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import 'meal_menu_screen.dart';
import 'emergency_numbers_screen.dart';
import 'news_detail_screen.dart';
import 'all_news_screen.dart';
import 'placeholder_screen.dart';
import 'activities_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'housing_screen.dart';
import 'catering_screen.dart';
import 'medical_screen.dart';
import 'transport_screen.dart';
import 'library_screen.dart';
import 'guide_screen.dart';
import 'shower_screen.dart';
import 'marketplace_screen.dart';
import '../services/firebase_service.dart';
import '../services/news_service.dart';
import '../models/facebook_post.dart';
import '../localization/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _newsController = PageController();
  int _currentNewsPage = 0;
  Timer? _newsTimer;

  /// true أثناء سحب المستخدم للكاروسيل — يتوقف التمرير التلقائي حتى لا
  /// ينفلت المنشور من تحت اليد (ويستأنف تلقائياً بعد نهاية السحب).
  bool _userScrolling = false;

  final NewsService _newsService = NewsService();
  List<FacebookPost>? _posts;

  /// المنشورات المعروضة بالكاروسيل: غير المفعّلة ما تبانش فالرئيسية أصلاً
  /// (تبقى في «مزيد» فقط). إذا ما اختار المدير حتى واحد -> قسم فارغ واضح.
  List<FacebookPost> get _displayPosts {
    final all = _posts ?? const <FacebookPost>[];
    return all.where((p) => p.inCarousel).take(8).toList();
  }

  @override
  void initState() {
    super.initState();
    _startNewsTimer();
    _fetchAdminPosts();
  }

  /// المنشورات تُبرمج من لوحة الإدارة فقط — لا منشورات ثابتة ولا خارجية
  Future<void> _fetchAdminPosts() async {
    final posts = await _newsService.fetchAdminPosts();
    if (mounted) {
      setState(() {
        _posts = posts;
        _currentNewsPage = 0;
      });
      // البيانات وصلت الآن — ابدأ التمرير التلقائي (حسب عدد المنشورات).
      _startNewsTimer();
    }
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    _newsController.dispose();
    super.dispose();
  }

  void _startNewsTimer() {
    _newsTimer?.cancel();
    final posts = _displayPosts;
    // منشور واحد أو أقل: التمرير التلقائي يนโยف ويرجع لنفس المنشور.
    if (_userScrolling || posts.length <= 1) return;
    _newsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_newsController.hasClients) return;
      _newsController.nextPage(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseNewsTimer() {
    if (_userScrolling) return;
    _userScrolling = true;
    _newsTimer?.cancel();
  }

  void _resumeNewsTimer() {
    if (!_userScrolling) return;
    _userScrolling = false;
    _startNewsTimer();
  }

  /// فتح رابط المنشور في المتصفح (أو تطبيقه إن وُجد).
  Future<void> _openPostLink(String url) async {
    final raw = url.trim();
    if (raw.isEmpty) return;
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(raw)
        ? raw
        : 'https://$raw';
    try {
      final uri = Uri.parse(withScheme);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('link launch failed: $withScheme');
      }
    } catch (_) {
      // رابط معطوب: نتجاهل بصمت بدل سناكبار تقني.
    }
  }

  static String _linkHost(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final appConfig = context.watch<AppConfigProvider>().config;
    final isLoggedIn = userProvider.isInitialized && userProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(userProvider, isLoggedIn, appConfig),
          if (appConfig.isAnnouncementActiveNow)
            SliverToBoxAdapter(child: _buildAnnouncementBanner(appConfig)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(
                        AppStrings.of(context, 'latest_news'),
                        Icons.newspaper,
                      ).animate().fadeIn(delay: 200.ms).slideX(),
                      OutlinedButton(
                        onPressed: () {
                          if (_posts != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AllNewsScreen(posts: _posts!),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColor.primaryColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: AppColor.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          AppStrings.of(context, 'see_more'),
                          style: const TextStyle(
                            color: AppColor.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNewsCarousel()
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    AppStrings.of(context, 'admin_depts'),
                    Icons.account_balance,
                  ).animate().fadeIn(delay: 600.ms).slideX(),
                  const SizedBox(height: 16),
                  _buildDepartmentsGrid()
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    AppStrings.of(context, 'services_facilities'),
                    Icons.room_service,
                  ).animate().fadeIn(delay: 1000.ms).slideX(),
                  const SizedBox(height: 16),
                  _buildServicesGrid()
                      .animate()
                      .fadeIn(delay: 1200.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFooterLinks(
              context,
            ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(UserProvider userProvider, bool isLoggedIn, AppConfig appConfig) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: surface,
      leadingWidth: 84,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                child: Image.asset(
                  'assets/images/cube3_logo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ClipOval(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  'assets/images/club_logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          icon: isLoggedIn
              ? StreamBuilder<Map<String, dynamic>?>(
                  stream: FirebaseService().getProfileByMatriculeStream(
                    userProvider.matricule,
                  ),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final photoBytes = tryDecodePhoto(
                        profile?['photo'] ?? userProvider.photo);
                    if (photoBytes != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          photoBytes,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.account_circle,
                            size: 30,
                            color: textPrimary,
                          ),
                        ),
                      );
                    }
                    return Icon(
                      Icons.account_circle,
                      size: 30,
                      color: textPrimary,
                    );
                  },
                )
              : Icon(Icons.account_circle, size: 30, color: textPrimary),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          '${appConfig.appName} • ${appConfig.residenceName}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hero_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              color: Colors.black.withValues(alpha: 0.35),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, _, _) => Container(
                color: AppColor.backgroundColor,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    AppColor.backgroundColor.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            Center(
              child:
                  Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/cube3_logo.png',
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        duration: 2.seconds,
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        duration: 2.seconds,
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(1, 1),
                        curve: Curves.easeInOut,
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(delay: 3.seconds, duration: 2.seconds)
                      .rotate(
                        begin: 0,
                        end: 0.05,
                        duration: 3.seconds,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .rotate(
                        begin: 0.05,
                        end: 0,
                        duration: 3.seconds,
                        curve: Curves.easeInOut,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return Row(
      children: [
        Icon(icon, color: AppColor.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
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

  Widget _buildNewsCarousel() {
    if (_posts == null) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(color: AppColor.primaryColor),
        ),
      );
    }

    if (_posts!.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textSecondary = isDark ? Colors.white54 : Colors.black54;
      return SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.newspaper_outlined, size: 40, color: textSecondary),
              const SizedBox(height: 8),
              Text(
                "لا توجد منشورات بعد",
                style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "تُنشر المنشورات من لوحة الإدارة",
                style: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    final displayPosts = _displayPosts;

    if (displayPosts.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textSecondary = isDark ? Colors.white54 : Colors.black54;
      return SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_carousel_outlined, size: 40, color: textSecondary),
              const SizedBox(height: 8),
              Text(
                "لا يوجد منشور مفعّل للحركة",
                style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "فعّل «يتحرك في الرئيسية» من لوحة الإدارة",
                style: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // سحب المستخدم -> أوقف التمرير التلقائي حتى لا يفلت المنشور.
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _pauseNewsTimer();
              } else if (notification is ScrollEndNotification ||
                  notification is ScrollUpdateNotification &&
                      notification.dragDetails == null) {
                _resumeNewsTimer();
              }
              return false;
            },
            child: AnimatedBuilder(
              animation: _newsController,
              builder: (context, child) {
                return PageView.builder(
                  controller: _newsController,
                  onPageChanged: (idx) => setState(
                    () => _currentNewsPage = idx % displayPosts.length,
                ),
                itemCount: 10000, // Infinite-like scroll
                itemBuilder: (context, index) {
                  final realIndex = index % displayPosts.length;
                  final post = displayPosts[realIndex];

                  // Calculate 3D rotation
                  double value = 0.0;
                  if (_newsController.position.haveDimensions) {
                    value = index.toDouble() - (_newsController.page ?? 0);
                  }

                  final rotation = (value * 0.4).clamp(
                    -1.0,
                    1.0,
                  ); // Adjust for 3D effect

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(rotation),
                    alignment: value > 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewsDetailScreen(post: post),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: post.type == 'text'
                              ? Colors.black
                              : AppColor.surfaceColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image:
                              post.type != 'text' && post.mediaUrls.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(post.mediaUrls.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            if (post.type == 'video')
                              const Center(
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.black45,
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(24),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(
                                        alpha: 0.6,
                                      ), // سوداء وشفافة
                                      Colors.black.withValues(alpha: 0.9),
                                    ],
                                    stops: const [0.0, 0.3, 1.0],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (post.isFresh() || post.isRepost)
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: post.isRepost
                                                  ? Colors.white
                                                      .withValues(alpha: 0.16)
                                                  : AppColor.primaryColor
                                                      .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: post.isRepost
                                                    ? Colors.white
                                                        .withValues(alpha: 0.4)
                                                    : AppColor.primaryColor
                                                        .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Text(
                                              post.isRepost
                                                  ? 'إعادة نشر'
                                                  : 'جديد',
                                              style: TextStyle(
                                                color: post.isRepost
                                                    ? Colors.white
                                                    : AppColor.primaryColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        const Spacer(),
                                        Text(
                                          _formatRelativeDate(post.date),
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      post.type == 'text'
                                          ? post.text
                                          : post.title,
                                      maxLines:
                                          (post.postUrl ?? '').isNotEmpty
                                              ? 1
                                              : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.white,
                                      ),
                                    ),
                                    if ((post.postUrl ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () =>
                                            _openPostLink(post.postUrl!),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.link,
                                                size: 14,
                                                color: AppColor.primaryColor),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _linkHost(post.postUrl!),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color:
                                                      AppColor.primaryColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                                Icons.open_in_new_rounded,
                                                size: 13,
                                                color: AppColor.primaryColor),
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
                    ),
                  );
                },
              );
            },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            displayPosts.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentNewsPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentNewsPage == index
                    ? AppColor.primaryColor
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementBanner(AppConfig appConfig) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primaryColor.withValues(alpha: 0.25),
            AppColor.primaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColor.primaryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign,
              color: AppColor.primaryColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              appConfig.announcementText,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildDepartmentsGrid() {
    final appConfig = context.read<AppConfigProvider>().config;
    final all = [
      {
        'key': 'activities',
        'enabled': appConfig.showActivities,
        'name': AppStrings.of(context, 'dept_activities'),
        'icon': Icons.sports_esports,
        'screen': const ActivitiesScreen(),
      },
      {
        'key': 'housing',
        'enabled': appConfig.showHousing,
        'name': AppStrings.of(context, 'dept_housing'),
        'icon': Icons.hotel,
        'screen': const HousingScreen(),
      },
      {
        'key': 'catering',
        'enabled': appConfig.showCatering,
        'name': AppStrings.of(context, 'dept_catering'),
        'icon': Icons.restaurant,
        'screen': const CateringScreen(),
      },
      {
        'key': 'medical',
        'enabled': appConfig.showMedical,
        'name': AppStrings.of(context, 'dept_medical'),
        'icon': Icons.medical_services,
        'screen': const MedicalScreen(),
      },
    ];
    final depts = all.where((e) => e['enabled'] == true).toList();
    if (depts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('تم تعطيل كل الأقسام من طرف الإدارة',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: depts.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => depts[index]['screen'] as Widget,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColor.surfaceColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  depts[index]['icon'] as IconData,
                  color: AppColor.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    depts[index]['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicesGrid() {
    final appConfig = context.read<AppConfigProvider>().config;
    final all = [
      {
        'enabled': appConfig.showMealMenu,
        'name': AppStrings.of(context, 'meal_menu'),
        'icon': Icons.menu_book,
        'screen': const MealMenuScreen(),
      },
      {
        'enabled': appConfig.showTransport,
        'name': AppStrings.of(context, 'transport'),
        'icon': Icons.directions_bus,
        'screen': const TransportScreen(),
      },
      {
        'enabled': appConfig.showLibrary,
        'name': AppStrings.of(context, 'library'),
        'icon': Icons.library_books,
        'screen': const LibraryScreen(),
      },
      {
        'enabled': appConfig.showShowers,
        'name': AppStrings.of(context, 'showers'),
        'icon': Icons.shower,
        'screen': const ShowerScreen(),
      },
      {
        'enabled': true,
        'name': 'سوق الطلبة',
        'icon': Icons.shopping_bag_outlined,
        'screen': const MarketplaceScreen(),
      },
      {
        'enabled': true,
        'name': AppStrings.of(context, 'emergency_numbers'),
        'icon': Icons.sos_outlined,
        'screen': const EmergencyNumbersScreen(),
      },
    ];
    final services = all.where((e) => e['enabled'] == true).toList();
    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('تم تعطيل كل الخدمات من طرف الإدارة',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => services[index]['screen'] as Widget,
              ),
            );
          },
          child: Column(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColor.primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  services[index]['icon'] as IconData,
                  color: AppColor.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                services[index]['name'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appConfig = context.read<AppConfigProvider>().config;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset('assets/images/cube3_logo.png', height: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مديرية الخدمات الجامعية',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      appConfig.residenceName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Links Grid
          Row(
            children: [
              if (appConfig.showMap)
                Expanded(
                  child: _buildFooterLink(
                    context,
                    Icons.map_outlined,
                    AppStrings.of(context, 'map'),
                    screen: const MapScreen(),
                  ),
                ),
              if (appConfig.showGuide)
                Expanded(
                  child: _buildFooterLink(
                    context,
                    Icons.description_outlined,
                    AppStrings.of(context, 'guide'),
                    screen: const GuideScreen(),
                  ),
                ),
              Expanded(
                child: _buildFooterLink(
                  context,
                  Icons.help_outline,
                  AppStrings.of(context, 'support'),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Divider(color: dividerColor),
          ),

          // Contact & Social
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildSocialBtn(Icons.facebook, _openFacebookPage),
                  const SizedBox(width: 8),
                  _buildSocialBtn(Icons.language, _showWebsitesBottomSheet),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.of(context, 'footer_rights'),
                    style: TextStyle(
                      color: textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    AppStrings.of(context, 'footer_region'),
                    style: const TextStyle(
                      color: AppColor.primaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(
    BuildContext context,
    IconData icon,
    String label, {
    Widget? screen,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => screen ?? PlaceholderScreen(title: label),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColor.primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 18,
        ),
      ),
    );
  }

  /// زر فيسبوك يعرض قائمة بجميع صفحات الإقامة والنادي والخدمات.
  void _openFacebookPage() {
    _showFacebookBottomSheet();
  }

  void _showFacebookBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appConfig = context.read<AppConfigProvider>().config;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white24 : Colors.black26;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'صفحات فيسبوك الرسمية',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLinkTile(
                Icons.facebook,
                'الصفحة الرسمية: ${appConfig.residenceName}',
                appConfig.fbResidence.isNotEmpty
                    ? appConfig.fbResidence
                    : 'https://www.facebook.com/ResidenceUniversitaireBabEzzouar3',
              ),
              _buildLinkTile(
                Icons.facebook,
                'صفحة النادي العلمي والثقافي',
                appConfig.fbClub.isNotEmpty
                    ? appConfig.fbClub
                    : 'https://www.facebook.com/club.alrasheed',
              ),
              _buildLinkTile(
                Icons.facebook,
                'مصلحة الأنشطة والخدمات الجامعية',
                'https://www.facebook.com/activites.babezzouar3',
              ),
              _buildLinkTile(
                Icons.facebook,
                'مديرية الخدمات الجامعية الجزائر شرق',
                appConfig.fbDirection.isNotEmpty
                    ? appConfig.fbDirection
                    : 'https://www.facebook.com/dou.alger.est',
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showWebsitesBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appConfig = context.read<AppConfigProvider>().config;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white24 : Colors.black26;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'المواقع الرسمية',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLinkTile(
                Icons.language,
                'الموقع الرسمي للمديرية',
                appConfig.webDirection,
              ),
              _buildLinkTile(
                Icons.school,
                'بوابة الطالب (PROGRES)',
                appConfig.webProgres,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinkTile(IconData icon, String title, String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white24 : Colors.black26;
    return ListTile(
      leading: Icon(icon, color: AppColor.primaryColor),
      title: Text(
        title,
        style: TextStyle(color: textPrimary, fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: Icon(Icons.open_in_new, color: iconColor, size: 16),
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}
