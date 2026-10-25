import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import '../theme/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;
    return Scaffold(
      backgroundColor: bg,
      appBar: GlassAppBar(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: AppColor.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'هذه الواجهة قيد التطوير',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إضافة خدمات $title قريباً',
              style: TextStyle(fontSize: 16, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
