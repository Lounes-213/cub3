import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/firebase_service.dart';
import '../providers/user_provider.dart';
import '../core/auth/guards.dart';
import '../core/utils/photo_utils.dart';
import '../localization/app_strings.dart';
import 'login_screen.dart';
import 'student_data_screen.dart';
import 'admin/admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (!userProvider.isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLoggedIn = userProvider.isLoggedIn;
    final isAdmin = userProvider.role == 'admin';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (!isLoggedIn) _buildGuestView() else _buildProfileView(),
                  const SizedBox(height: 24),
                  if (isLoggedIn) ...[
                    _buildStudentDataTile(),
                    const SizedBox(height: 32),
                  ],
                  if (isLoggedIn && isAdmin) ...[
                    _buildAdminNavigationButton(),
                    const SizedBox(height: 32),
                  ],
                  _buildSettingsSection(),
                  const SizedBox(height: 40),
                  if (isLoggedIn) _buildLogoutButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.of(context, 'logout'),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد تسجيل الخروج؟',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.of(context, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: const StadiumBorder(),
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await context.read<UserProvider>().logout();
    }
  }

  Widget _buildSliverAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: surface,
      title: Text(
        AppStrings.of(context, 'profile'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: textPrimary,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColor.primaryColor.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white38 : Colors.black38;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 60,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.of(context, 'guest'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سجل دخولك للوصول إلى معلوماتك الجامعية',
            style: TextStyle(color: textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildHasananStyleButton(AppStrings.of(context, 'login'), () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildProfileView() {
    final userProvider = context.read<UserProvider>();
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirebaseService().getProfileByMatriculeStream(
        userProvider.matricule,
      ),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final fullNameAr = profile?['fullNameAr'] ?? userProvider.fullNameAr;
        final photo = profile?['photo'] ?? userProvider.photo;
        final regNum = profile?['registrationNumber'] ?? '';
        final levelAr = profile?['levelAr'] ?? '';
        final cycleAr = profile?['cycleAr'] ?? '';
        final dateOfBirth = profile?['dateOfBirth'] ?? '';
        final role = profile?['role'] ?? userProvider.role;

        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow effect
                Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColor.primaryColor.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      duration: 3.seconds,
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      curve: Curves.easeInOut,
                    ),

                // Border container
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColor.primaryColor,
                        AppColor.primaryColor.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.surfaceColor,
                    ),
                    child: Builder(
                      builder: (context) {
                        final photoBytes = tryDecodePhoto(photo);
                        if (photoBytes == null) {
                          return Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.backgroundColor,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white10,
                            ),
                          );
                        }
                        return ClipOval(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            color: Colors.white.withValues(alpha: 0.03),
                            child: Image.memory(
                              photoBytes,
                              width: 110,
                              height: 110,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white10,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              fullNameAr.isNotEmpty ? fullNameAr : 'اسم الطالب',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(role).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _getRoleLabel(role),
                    style: TextStyle(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    regNum ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColor.surfaceColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.school,
                    'الطور الدراسي',
                    cycleAr ?? 'غير متوفر',
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  _buildInfoRow(
                    Icons.layers,
                    'المستوى',
                    levelAr ?? 'غير متوفر',
                  ),
                  if ((userProvider.specialtyAr ?? '').isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 32),
                    _buildInfoRow(
                      Icons.workspace_premium_outlined,
                      'التخصص',
                      userProvider.specialtyAr!,
                    ),
                  ],
                  if ((userProvider.fieldAr ?? '').isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 32),
                    _buildInfoRow(
                      Icons.account_tree_outlined,
                      'الشعبة',
                      userProvider.fieldAr!,
                    ),
                  ],
                  if ((userProvider.domainAr ?? '').isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 32),
                    _buildInfoRow(
                      Icons.category_outlined,
                      'الميدان',
                      userProvider.domainAr!,
                    ),
                  ],
                  if ((userProvider.universityAr ?? '').isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 32),
                    _buildInfoRow(
                      Icons.apartment_outlined,
                      'المؤسسة',
                      userProvider.universityAr!,
                    ),
                  ],
                  if ((userProvider.academicYear ?? '').isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 32),
                    _buildInfoRow(
                      Icons.event_outlined,
                      'السنة الجامعية',
                      userProvider.academicYear!,
                    ),
                  ],
                  if (dateOfBirth != null) ...[
                    const Divider(color: Colors.white10, height: 32),
                    _buildInfoRow(Icons.cake, 'تاريخ الميلاد', dateOfBirth),
                  ],
                ],
              ),
            ),
          ],
        ).animate().fadeIn();
      },
    );
  }

  /// زر الوصول إلى كل بيانات PROGRES (التسجيلات، المسار الدراسي، الإيواء...)
  Widget _buildStudentDataTile() {
    final user = context.watch<UserProvider>();
    return Material(
      color: AppColor.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColor.primaryColor.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        leading: const Icon(Icons.badge_outlined, color: AppColor.primaryColor),
        title: const Text(
          'معلوماتي الجامعية الكاملة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user.hasStudentData
              ? [user.specialtyAr, user.levelAr, user.academicYear]
                  .whereType<String>()
                  .join(' • ')
              : 'التسجيلات، التخصص، الإيواء، المسار الدراسي والنقاط',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
          maxLines: 2,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white24,
          size: 14,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentDataScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(
                Icons.settings,
                color: AppColor.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.of(context, 'settings'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dividerColor),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                Icons.dark_mode_outlined,
                AppStrings.of(context, 'dark_mode'),
                trailing: Consumer<ThemeProvider>(
                  builder: (context, theme, _) => Switch(
                    activeTrackColor: AppColor.primaryColor,
                    value: theme.isDarkMode,
                    onChanged: (val) => theme.toggleTheme(),
                  ),
                ),
              ),
              Divider(color: dividerColor, height: 1, indent: 48),
              _buildLanguageTile(),
              Divider(color: dividerColor, height: 1, indent: 48),
              _buildSettingsTile(
                Icons.notifications_outlined,
                AppStrings.of(context, 'notifications'),
                trailing: Switch(
                  activeTrackColor: AppColor.primaryColor,
                  value: true,
                  onChanged: (val) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHasananStyleButton(String label, VoidCallback onTap) {
    return Center(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primaryColor,
            foregroundColor: Colors.black,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 60),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent.withValues(alpha: 0.7),
        ),
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: Text(
          AppStrings.of(context, 'logout'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    return Row(
      children: [
        Icon(icon, color: AppColor.primaryColor, size: 20),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageTile() {
    final localeProvider = context.read<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return ListTile(
      leading: Icon(
        Icons.translate,
        color: isDark ? Colors.white54 : Colors.black45,
        size: 22,
      ),
      title: Text(
        AppStrings.of(context, 'language'),
        style: TextStyle(color: textPrimary, fontSize: 14),
      ),
      trailing: Consumer<LocaleProvider>(
        builder: (context, locale, _) => Text(
          localeProvider.getLanguageLabel(locale.locale.languageCode),
          style: const TextStyle(
            color: AppColor.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.of(context, 'choose_language'),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangOption(ctx, localeProvider, const Locale('ar', 'AE')),
            _buildLangOption(ctx, localeProvider, const Locale('fr', 'FR')),
            _buildLangOption(ctx, localeProvider, const Locale('en', 'US')),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(
    BuildContext ctx,
    LocaleProvider provider,
    Locale locale,
  ) {
    final isSelected = provider.locale.languageCode == locale.languageCode;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return ListTile(
      title: Text(
        provider.getLanguageLabel(locale.languageCode),
        style: TextStyle(
          color: isSelected
              ? AppColor.primaryColor
              : (isDark ? Colors.white70 : Colors.black54),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColor.primaryColor)
          : null,
      onTap: () {
        provider.setLocale(locale);
        Navigator.pop(ctx);
      },
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white54 : Colors.black45,
        size: 22,
      ),
      title: Text(title, style: TextStyle(color: textPrimary, fontSize: 14)),
      trailing: trailing,
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'staf':
        return 'مسؤول الأنشطة';
      case 'trav':
        return 'عامل الخدمات';
      case 'etud':
        return 'طالب جامعي';
      default:
        return 'مستخدم';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.redAccent;
      case 'staf':
        return Colors.blueAccent;
      case 'trav':
        return Colors.orangeAccent;
      case 'etud':
        return AppColor.primaryColor;
      default:
        return Colors.white24;
    }
  }

  Widget _buildAdminNavigationButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.redAccent,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'إدارة النظام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: AppColor.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            leading: const Icon(Icons.dashboard_customize_outlined, color: Colors.redAccent),
            title: const Text(
              'لوحة الإدارة 🛠️',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'الحسابات، المنشورات، الإعلانات، البرمجة والطلبات',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
            onTap: () {
              openAdmin(context, const AdminPanelScreen());
            },
          ),
        ),
      ],
    );
  }
}
