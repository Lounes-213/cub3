import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../providers/app_config_provider.dart';
import '../localization/app_strings.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  Future<void> _call(String number, BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^\d+]'), ''));
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الاتصال: $number')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الاتصال: $number')),
        );
      }
    }
  }

  _EmergencyCategory _categorize(String name) {
    final n = name.toLowerCase();
    if (n.contains('إسعاف') || n.contains('اسعاف') || n.contains('صحي') || n.contains('طبي') || n.contains('medical') || n.contains('ambulance') || n.contains('sant')) {
      return _EmergencyCategory.medical;
    }
    if (n.contains('حماية') || n.contains('نار') || n.contains('حريق') || n.contains('fire') || n.contains('protection') || n.contains('civil')) {
      return _EmergencyCategory.fire;
    }
    if (n.contains('أمن') || n.contains('شرطة') || n.contains('darak') || n.contains('police') || n.contains('secur')) {
      return _EmergencyCategory.police;
    }
    if (n.contains('كهرباء') || n.contains('سون') || n.contains('سباكة') || n.contains('صيانة') || n.contains('gas') || n.contains('electric')) {
      return _EmergencyCategory.utility;
    }
    if (n.contains('الإقامة') || n.contains('مدير') || n.contains('رئيس') || n.contains('administration') || n.contains('residence')) {
      return _EmergencyCategory.admin;
    }
    return _EmergencyCategory.general;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final numbers = context.watch<AppConfigProvider>().config.emergencyNumbers;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlassAppBar(
        title: Text(
          AppStrings.of(context, 'emergency_numbers'),
          style: TextStyle(fontWeight: FontWeight.w900, color: textPrimary, fontSize: 17),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: Column(
        children: [
          // ===== Hero Header =====
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.sos_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اتصال سريع وآمن',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'اضغط على زر الاتصال للرد الفوري',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== Numbers List =====
          Expanded(
            child: numbers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sos_outlined,
                          size: 56,
                          color: textSecondary.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد أرقام مسجلة بعد',
                          style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'يبرمجها المدير من لوحة الإدارة',
                          style: TextStyle(
                            color: textSecondary.withValues(alpha: 0.7),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: numbers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final e = numbers[i];
                      final name = e['name'] ?? '';
                      final number = e['number'] ?? '';
                      final category = _categorize(name);
                      final catInfo = _catData(category);

                      return Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: catInfo.color.withValues(alpha: 0.18),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _call(number, context),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          catInfo.color,
                                          catInfo.color.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: catInfo.color.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(catInfo.icon, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),

                                  // Text info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Category Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: catInfo.color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            catInfo.label,
                                            style: TextStyle(
                                              color: catInfo.color,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: textPrimary,
                                            fontSize: 14.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            number,
                                            style: TextStyle(
                                              color: catInfo.color,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Call Button
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: catInfo.color,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: catInfo.color.withValues(alpha: 0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 0,
                                        ),
                                      ),
                                      onPressed: () => _call(number, context),
                                      icon: const Icon(Icons.call, size: 17),
                                      label: const Text(
                                        'اتصال',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (50 * i).ms, duration: 400.ms)
                          .slideY(begin: 0.12, end: 0, delay: (50 * i).ms, curve: Curves.easeOutQuart);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ===== Category System =====
enum _EmergencyCategory { medical, fire, police, utility, admin, general }

class _EmergencyCatInfo {
  final Color color;
  final IconData icon;
  final String label;
  const _EmergencyCatInfo(this.color, this.icon, this.label);
}

_EmergencyCatInfo _catData(_EmergencyCategory cat) {
  switch (cat) {
    case _EmergencyCategory.medical:
      return const _EmergencyCatInfo(Color(0xFFE53935), Icons.medical_services_rounded, 'إسعاف / صحي');
    case _EmergencyCategory.fire:
      return const _EmergencyCatInfo(Color(0xFFFF7043), Icons.local_fire_department_rounded, 'حماية مدنية');
    case _EmergencyCategory.police:
      return const _EmergencyCatInfo(Color(0xFF29B6F6), Icons.local_police_rounded, 'أمن وشرطة');
    case _EmergencyCategory.utility:
      return const _EmergencyCatInfo(Color(0xFFFFC107), Icons.build_circle_rounded, 'خدمات ومرافق');
    case _EmergencyCategory.admin:
      return const _EmergencyCatInfo(Color(0xFF7E57C2), Icons.apartment_rounded, 'إدارة الإقامة');
    case _EmergencyCategory.general:
      return const _EmergencyCatInfo(AppColor.primaryColor, Icons.support_agent_rounded, 'دعم ومساعدة');
  }
}
