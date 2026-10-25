import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/auth/app_roles.dart';
import '../core/auth/guards.dart';
import '../theme/theme.dart';
import '../services/preference_service.dart';
import '../services/firebase_service.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_panel_screen.dart';
import 'game_router.dart';
import 'login_screen.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginChoiceScreen extends StatefulWidget {
  const LoginChoiceScreen({super.key});

  @override
  State<LoginChoiceScreen> createState() => _LoginChoiceScreenState();
}

class _LoginChoiceScreenState extends State<LoginChoiceScreen> {
  final FirebaseService _firebase = FirebaseService();
  String _userRole = 'guest'; // 'admin', 'staf', 'trav', 'etud', 'guest'
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final userProvider = context.read<UserProvider>();
    if (mounted) {
      setState(() {
        _userRole = userProvider.isLoggedIn ? userProvider.role : 'guest';
        _fullName = userProvider.isLoggedIn ? userProvider.fullNameAr : '';
      });
    }
  }

  String _getRoleLabel(String role) {
    return AppRoleX.fromString(role).labelAr;
  }

  Color _getRoleColor(String role) {
    return AppRoleX.fromString(role).color;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: GlassAppBar(
        title: Text(
          'بطولات ومسابقات CUBE 3',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        backgroundColor: isDark ? AppColor.surfaceColor : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background soft glowing blob
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRoleColor(_userRole).withValues(alpha: isDark ? 0.03 : 0.06),
              ),
            ),
          ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Render screen based on current role
                  if (_userRole == 'admin' || _userRole == 'staf' || _userRole == 'trav')
                    _buildAdminStaffPanel(isDark)
                  else if (_userRole == 'etud')
                    _buildStudentPanel(isDark)
                  else
                    _buildGuestPanel(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 👑 ADMIN & STAFF PANEL (حسب الدور)
  // ----------------------------------------------------
  Widget _buildAdminStaffPanel(bool isDark) {
    final role = AppRoleX.fromString(_userRole);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColor.surfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _getRoleColor(_userRole).withValues(alpha: isDark ? 0.15 : 0.3)),
            boxShadow: !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getRoleColor(_userRole).withValues(alpha: 0.15),
                    child: Icon(role.icon, color: _getRoleColor(_userRole), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أهلاً بك، $_fullName 👋', 
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(_userRole).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRoleLabel(_userRole), 
                            style: TextStyle(color: _getRoleColor(_userRole), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                role.descriptionAr,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 32),

        Text(
          'الإدارة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // زر واحد للوحة الإدارة الموحدة (فيها كل شيء حسب الدور)
        _buildBentoActionCard(
          title: 'لوحة الإدارة',
          desc: 'الحسابات، المنشورات، الطلبات، الأجنحة والمرافق والبرمجة — كل شيء في مكان واحد.',
          icon: Icons.dashboard_customize_outlined,
          color: Colors.amber.shade700,
          isDark: isDark,
          onTap: () => openAdmin(context, const AdminPanelScreen()),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
      ],
    );
  }

  // ----------------------------------------------------
  // 🎓 STUDENT PANEL
  // ----------------------------------------------------
  Widget _buildStudentPanel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome student card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColor.surfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColor.primaryColor.withValues(alpha: isDark ? 0.15 : 0.3)),
            boxShadow: !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColor.primaryColor.withValues(alpha: 0.15),
                    child: const Icon(Icons.emoji_events_outlined, color: AppColor.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً بك، $_fullName 🏆', 
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مشارك - مسابقات الإقامة الجامعية', 
                          style: TextStyle(
                            color: isDark ? AppColor.textSecondary : Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 32),

        // Live Event Listen
        StreamBuilder<Map<String, dynamic>>(
          stream: _firebase.gameInfoStream,
          builder: (context, snapshot) {
            final gameData = snapshot.data ?? {};
            final status = gameData['status'] ?? 'none';
            final title = gameData['title'] ?? 'تحدي الإقامة الكبرى';
            final isRunning = status == 'playing' || status == 'waiting';

            if (!isRunning) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColor.surfaceColor.withValues(alpha: 0.5) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sports_esports_outlined, color: isDark ? Colors.white24 : Colors.black26, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'لا توجد مسابقة جارية الآن',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'سيقوم منشط الأنشطة بإطلاق التحدي قريباً. انتظر الإشارة!',
                            style: TextStyle(
                              color: isDark ? Colors.white30 : Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn();
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColor.primaryColor.withValues(alpha: 0.15), Colors.transparent]
                      : [AppColor.primaryColor.withValues(alpha: 0.12), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar, color: AppColor.primaryColor, size: 26).animate(onPlay: (c) => c.repeat()).shake(hz: 2, curve: Curves.easeInOut),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مسابقة نشطة جارية حالياً!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primaryColor, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98));
          },
        ),
        const SizedBox(height: 32),

        Text(
          'خيارات المشاركة والتفاعل', 
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Join as Player via QR
        _buildChoiceCard(
          title: 'انضمام كلاعب نشط',
          subtitle: 'قم بمسح رمز الاستجابة (QR Code) للانضمام لفريقك والإجابة على الأسئلة مباشرة من هاتفك!',
          icon: Icons.qr_code_scanner,
          color: AppColor.primaryColor,
          isDark: isDark,
          onTap: () async {
            await PreferenceService.setSpectator(false);
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GameRouter()));
            }
          },
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),

        // Spectate directly
        _buildChoiceCard(
          title: 'مشاهدة المسابقة كمتفرج',
          subtitle: 'تابع البث الحي للأسئلة، وتحديثات نقاط الفرق، ولائحة الصدارة لحظة بلحظة!',
          icon: Icons.visibility_outlined,
          color: AppColor.secondaryColor,
          isDark: isDark,
          onTap: () async {
            await PreferenceService.setSpectator(true);
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GameRouter()));
            }
          },
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
      ],
    );
  }

  // ----------------------------------------------------
  // 👤 GUEST PANEL
  // ----------------------------------------------------
  Widget _buildGuestPanel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guest Welcome banner with login invitation
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColor.surfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.08)),
            boxShadow: !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    child: Icon(Icons.account_circle_outlined, color: isDark ? Colors.white60 : Colors.black54, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أنت تتصفح كضيف زائر', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'مسابقات وتحديات CUBE 3', 
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'سجل دخولك بحسابك الطلابي الجامعي لتتمكن من التسجيل كلاعب في الفرق وتجميع النقاط والمنافسة على الألقاب الكبرى!',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black87,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    final loggedIn = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    if (loggedIn == true) {
                      _loadUserSession();
                    }
                  },
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('تسجيل الدخول الآن', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 32),

        Text(
          'خيارات الدخول المتاحة للزوار', 
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Guests can only spectate
        _buildChoiceCard(
          title: 'دخول في وضع المتفرجين',
          subtitle: 'متابعة البث المباشر للأسئلة والإجابات ولائحة المتصدرين الجارية بدون صلاحية اللعب كفريق.',
          icon: Icons.visibility_outlined,
          color: AppColor.secondaryColor,
          isDark: isDark,
          onTap: () async {
            await PreferenceService.setSpectator(true);
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GameRouter()));
            }
          },
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),

        // Admin Access Route
        _buildChoiceCard(
          title: 'بوابة الطاقم والمسؤولين',
          subtitle: 'التحكم الإداري الكامل بالبطولات ومستويات التحكم بالأسئلة والمزامنة.',
          icon: Icons.admin_panel_settings_outlined,
          color: isDark ? Colors.white24 : Colors.grey.shade600,
          isDark: isDark,
          onTap: () async {
            final loggedIn = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
            if (loggedIn == true) {
              _loadUserSession();
            }
          },
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
      ],
    );
  }

  // ----------------------------------------------------
  // HELPERS WIDGETS
  // ----------------------------------------------------
  Widget _buildBentoActionCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColor.surfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.15 : 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? color.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.1 : 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColor.textSecondary : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white24 : Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    String? desc,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColor.surfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.15 : 0.3), width: 1.5),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.1 : 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc ?? subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColor.textSecondary : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white24 : Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }
}
