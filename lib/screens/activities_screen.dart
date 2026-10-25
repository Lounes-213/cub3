import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../services/firebase_service.dart';
import '../localization/app_strings.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'admin/admin_competitions_screen.dart';
import 'game_router.dart';
import 'field_booking_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.of(context, k);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: GlassAppBar(
        title: Text(
          s('activities_title'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_basketball,
                size: 100,
                color: AppColor.primaryColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                s('activities_welcome'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                s('activities_desc'),
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              StreamBuilder<Map<String, dynamic>>(
                stream: FirebaseService().gameInfoStream,
                builder: (context, snapshot) {
                  final gameData = snapshot.data ?? {};
                  final status = gameData['status'] ?? 'none';
                  final isLive = status == 'playing' || status == 'waiting';

                  return SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLive
                            ? Colors.redAccent
                            : AppColor.primaryColor,
                        foregroundColor: isLive ? Colors.white : Colors.white,
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        final userProvider = context.read<UserProvider>();
                        if (userProvider.canAccessAdminPanel || userProvider.canManageCompetitions) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCompetitionsScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GameRouter(),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        isLive ? Icons.sensors : Icons.emoji_events,
                        size: 28,
                      ),
                      label: Text(
                        isLive ? s('game_live') : s('game_challenges'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FieldBookingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sports_soccer, size: 28),
                  label: Text(
                    s('book_field'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
