import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/preference_service.dart';
import '../../theme/theme.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _hasError = false;

  void _handleLogin() async {
    if (_passwordController.text == 'cube3ebuc') {
      await PreferenceService.setAdminLoggedIn(true);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: GlassAppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings, size: 80, color: AppColor.primaryColor),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 32),
              
              Text(
                'دخول الإدارة المركزي',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'الرجاء إدخال كلمة المرور للوصول إلى لوحة التحكم والمزامنة الحية',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColor.getTextSecondary(context)),
              ),
              
              const SizedBox(height: 48),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: 4,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  hintStyle: TextStyle(
                    letterSpacing: 0,
                    fontSize: 16,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  errorText: _hasError ? 'كلمة المرور غير صحيحة' : null,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text('تسجيل الدخول'),
              ),
              
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'العودة لشاشة البداية',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
