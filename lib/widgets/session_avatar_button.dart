import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/photo_utils.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';

/// زر الحساب الظاهر في كل الصفحات:
/// صورة المتصل إن كان داخلاً (تظهر مباشرة)، وإلا زر دخول.
class SessionAvatarButton extends StatelessWidget {
  final Color? iconColor;
  const SessionAvatarButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    final color =
        iconColor ?? Theme.of(context).iconTheme.color ?? Colors.white70;
    final loggedIn = up.isInitialized && up.isLoggedIn;
    final bytes = loggedIn ? tryDecodePhoto(up.photo) : null;
    return IconButton(
      tooltip: loggedIn && up.fullNameAr.isNotEmpty ? up.fullNameAr : 'دخول',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                loggedIn ? const ProfileScreen() : const LoginScreen()),
      ),
      icon: bytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes,
                  width: 28, height: 28, fit: BoxFit.cover),
            )
          : Icon(loggedIn ? Icons.account_circle : Icons.login,
              size: 28, color: color),
    );
  }
}
