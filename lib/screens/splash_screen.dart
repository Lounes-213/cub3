import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard.dart';
import '../theme/theme.dart';
import '../services/preference_service.dart';
import '../providers/user_provider.dart';

import 'game_router.dart';
import 'product_share_page.dart' show isProductSharePageOpen;
import '../services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'جاري فتح التطبيق...';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// الإقلاع: انتظار التحقق التلقائي من الجلسة ثم إعادة التوجيه للعبة أو لوحة الإدارة تلقائياً
  Future<void> _boot() async {
    final userProvider = context.read<UserProvider>();
    final minDelay = Future.delayed(const Duration(milliseconds: 1500));

    setState(() => _status = 'تحقق تلقائي من الحساب...');
    try {
      await userProvider.waitInit.timeout(const Duration(seconds: 15));
    } catch (_) {
      // مهلة الاتصال
    }

    final isAdmin = await PreferenceService.isAdminLoggedIn() ||
        userProvider.canAccessAdminPanel;
    final teamReg = await PreferenceService.getTeamRegistration();
    final isSpectator = await PreferenceService.isSpectator();

    Map<String, dynamic>? gameState;
    try {
      gameState = await FirebaseService().getGameStateOnce();
    } catch (_) {}

    await minDelay;
    if (!mounted) return;

    // من رابط مشاركة (`/p/<id>`) فُتحت صفحة الغرض المستقلة؟
    // لا نعيد التوجيه إلى التطبيق حتى لا تُمسح صفحة الغرض من فوقها.
    if (isProductSharePageOpen) return;

    setState(() => _status = 'تم التحقق ✅');
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final gameStatus = gameState?['status'] as String? ?? 'none';
    final isGameLive = gameStatus == 'playing' || gameStatus == 'waiting';

    // إذا كانت هناك مسابقة نشطة:
    // 1. المشرف الذي يملك المسابقة يعود مباشرة لمركز العمليات (Admin Dashboard)
    // 2. اللاعب المسجل يعود مباشرة إلى مكانه في اللعبة (GameRouter)
    if (isGameLive) {
      final creatorId = gameState?['creator_id'];
      final myMatricule = userProvider.matricule;

      if (isAdmin && (creatorId == null || creatorId == myMatricule || creatorId == 'admin')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
        return;
      }

      if (teamReg != null || isSpectator) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameRouter()),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.primaryColor.withValues(alpha: 0.1),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.5, 1.5),
                      duration: 4.seconds,
                    ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child:
                Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.secondaryColor.withValues(alpha: 0.1),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 3.seconds,
                    ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Container
                Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/aliqama_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    .animate()
                    .scale(duration: 1.seconds, curve: Curves.elasticOut)
                    .shimmer(delay: 2.seconds, duration: 2.seconds),
                const SizedBox(height: 40),

                // App Title
                Text(
                  'الإقامة الجامعية',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),

                Text(
                  'باب الزوار 3',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: AppColor.primaryColor,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),

                const SizedBox(height: 50),

                // Footer: Created by
                const Text(
                  'تم الإنشاء من طرف',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ).animate().fadeIn(delay: 1.seconds),
                const SizedBox(height: 12),

                // Small Circular Club Logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColor.primaryColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/club_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ).animate().fadeIn(delay: 1.2.seconds).scale(),

                const SizedBox(height: 40),

                // Loading indicator
                const SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColor.primaryColor,
                    ),
                  ),
                ).animate().fadeIn(delay: 1.5.seconds),
                const SizedBox(height: 12),
                Text(
                  _status,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
