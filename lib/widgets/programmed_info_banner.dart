import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_config_provider.dart';
import '../theme/theme.dart';

/// شريط يعرض النص المبرمج من الإدارة داخل شاشات الخدمات.
class ProgrammedInfoBanner extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const ProgrammedInfoBanner(
      {super.key, required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColor.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColor.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget meal(BuildContext context) {
    final c = context.watch<AppConfigProvider>().config;
    // لا قيم مبرمجة من الإدارة = لا شيء يُعرض (لا معلومات وهمية)
    if (c.mealBreakfast.trim().isEmpty &&
        c.mealLunch.trim().isEmpty &&
        c.mealDinner.trim().isEmpty &&
        c.mealNotes.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final lines = <String>[
      if (c.mealBreakfast.trim().isNotEmpty) 'فطور: ${c.mealBreakfast}',
      if (c.mealLunch.trim().isNotEmpty) 'غداء: ${c.mealLunch}',
      if (c.mealDinner.trim().isNotEmpty) 'عشاء: ${c.mealDinner}',
      if (c.mealNotes.trim().isNotEmpty) c.mealNotes,
    ];
    return ProgrammedInfoBanner(
      title: 'برمجة الإدارة — قائمة اليوم',
      body: lines.join('\n'),
      icon: Icons.restaurant,
    );
  }

  static Widget transport(BuildContext context) {
    final c = context.watch<AppConfigProvider>().config;
    // لا قيم مبرمجة = لا شيء يُعرض
    final lines = <String>[
      if (c.transportMorning.trim().isNotEmpty) 'صباحاً: ${c.transportMorning}',
      if (c.transportEvening.trim().isNotEmpty) 'مساءً: ${c.transportEvening}',
      if (c.transportNotes.trim().isNotEmpty) c.transportNotes,
    ];
    return ProgrammedInfoBanner(
      title: 'برمجة الإدارة — النقل',
      body: lines.join('\n'),
      icon: Icons.directions_bus,
    );
  }

  static Widget library(BuildContext context) {
    final c = context.watch<AppConfigProvider>().config;
    return ProgrammedInfoBanner(
      title: 'برمجة الإدارة — المكتبة',
      body: '${c.libraryHours}\n${c.libraryNotes}',
      icon: Icons.library_books,
    );
  }

  static Widget shower(BuildContext context) {
    final c = context.watch<AppConfigProvider>().config;
    final lines = <String>[
      'صباحاً: ${c.showerMorningStart} - ${c.showerMorningEnd}',
      'مساءً: ${c.showerEveningStart} - ${c.showerEveningEnd}',
      if (c.showerNotes.trim().isNotEmpty) c.showerNotes,
    ];
    return ProgrammedInfoBanner(
      title: 'برمجة الإدارة — الحمامات',
      body: lines.join('\n'),
      icon: Icons.shower,
    );
  }
}
