import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/preference_service.dart';
import '../../screens/login_screen.dart';
import '../../screens/admin/admin_login_screen.dart';

/// يطلب الدخول قبل إجراء محمي: يفتح شاشة الدخول إن لم يكن متصلاً.
/// يرجع true فقط إن كان الحساب متصلاً (يظهر مباشرة في كل الصفحات).
Future<bool> requireLogin(BuildContext context, {String? reason}) async {
  if (context.read<UserProvider>().isLoggedIn) return true;
  if (reason != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(reason)));
  }
  await Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  if (!context.mounted) return false;
  return context.read<UserProvider>().isLoggedIn;
}

/// فتح لوحة إدارة محمية: يقبل دور طاقم/مدير أو دخول إدارة سابق،
/// وإلا يوجّه لشاشة دخول الإدارة (تُستعمل في كل نقاط الدخول).
Future<void> openAdmin(BuildContext context, Widget screen) async {
  bool ok = context.read<UserProvider>().canAccessAdminPanel;
  ok = ok || await PreferenceService.isAdminLoggedIn();
  if (!context.mounted) return;
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ok ? screen : const AdminLoginScreen()));
}
/// حارس لوحات الإدارة (دفاع إضافي داخل build).
class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    if (up.isInitialized && up.canAccessAdminPanel) return child;
    return FutureBuilder<bool>(
      future: PreferenceService.isAdminLoggedIn(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == true) return child;
        return Scaffold(
          appBar: GlassAppBar(title: const Text('منطقة محمية'), centerTitle: true),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 48, color: Colors.white24),
                const SizedBox(height: 12),
                const Text('هذه اللوحة للطاقم والإدارة فقط',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminLoginScreen())),
                  child: const Text('دخول الإدارة'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
