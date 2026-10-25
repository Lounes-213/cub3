import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  String _errorMsg = '';

  Future<void> _handleLogin() async {
    if (_userController.text.trim().isEmpty || _passController.text.trim().isEmpty) {
      setState(() => _errorMsg = 'الرجاء إدخال جميع البيانات');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final res = await userProvider.login(
      _userController.text.trim(),
      _passController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        Navigator.pop(context, true); // Return true to indicate successful login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدخول بنجاح!')),
        );
      } else {
        setState(() => _errorMsg = res['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.primaryColor.withValues(alpha: 0.08),
                          ),
                        ).animate(onPlay: (c) => c.repeat()).scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.6, 1.6)).fadeOut(),
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/cube3_logo.png', fit: BoxFit.cover),
                          ),
                        ).animate().shimmer(duration: 3.seconds).shake(hz: 1),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'بوابة الطالب PROGRES', 
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ادخل معلومات حسابك الجامعي الرسمي (PROGRES)', 
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يتم التحقق من حسابك في PROGRES في الخلفية', 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              _buildTextField(_userController, 'رقم التسجيل', Icons.person_outline, isDark: isDark),
              const SizedBox(height: 16),
              _buildTextField(_passController, 'كلمة المرور', Icons.lock_outline, isPassword: true, isDark: isDark),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 48),
              _buildHasananStyleButton('تسجيل الدخول', _handleLogin, isLoading: _isLoading),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, required bool isDark}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColor.primaryColor, size: 20),
        filled: true,
        fillColor: isDark ? AppColor.surfaceColor : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColor.primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildHasananStyleButton(String label, VoidCallback onTap, {bool isLoading = false}) {
    return Center(
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primaryColor,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 80),
            elevation: 4,
          ),
          onPressed: isLoading ? null : onTap,
          child: isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
