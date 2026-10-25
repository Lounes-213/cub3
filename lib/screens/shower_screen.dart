import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../localization/app_strings.dart';
import '../providers/app_config_provider.dart';
import '../widgets/programmed_info_banner.dart';
import '../theme/theme.dart';

class ShowerBooking {
  final int showerId;
  final DateTime start;
  final DateTime end;

  ShowerBooking({
    required this.showerId,
    required this.start,
    required this.end,
  });
}

class ShowerScreen extends StatefulWidget {
  const ShowerScreen({super.key});

  @override
  State<ShowerScreen> createState() => _ShowerScreenState();
}

class _ShowerScreenState extends State<ShowerScreen> {
  final int _totalShowers = 14;

  /// الضغط على دش متاح: الخدمة مزالت غير مبرمجة (تُعرض المواقيت الرسمية).
  void _showNotProgrammedDialog(BuildContext context, int showerId) {
    final cfg = context.read<AppConfigProvider>().config;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('دش رقم $showerId',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المواقيت الرسمية:\nصباحاً: ${cfg.showerMorningStart} - ${cfg.showerMorningEnd}\nمساءً: ${cfg.showerEveningStart} - ${cfg.showerEveningEnd}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.8),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'خدمة الحجز الإلكتروني مزالت غير مبرمجة.',
                style: TextStyle(
                    color: Colors.orangeAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

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
          s('showers_title'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ProgrammedInfoBanner.shower(context),
          const SizedBox(height: 8),
          Text(
            s('showers_desc'),
            style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _infoChip(Icons.timer, s('max_duration'), textSecondary),
              _infoChip(Icons.schedule, s('gap_rule'), textSecondary),
              _infoChip(Icons.no_accounts, s('no_plastic'), textSecondary),
            ],
          ),
          const SizedBox(height: 24),

          // Shower grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _totalShowers,
            itemBuilder: (context, index) {
              final id = index + 1;
              return GestureDetector(
                onTap: () => _showNotProgrammedDialog(context, id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shower,
                        color: textPrimary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$id',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        s('available'),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'خدمة الحجز الإلكتروني مزالت غير مبرمجة — المواقيت أعلاه هي الرسمية.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Rules
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColor.warningColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.warningColor.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColor.warningColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s('shower_rules'),
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ruleItem(context, '1', s('sr_rule_1')),
                      _ruleItem(context, '2', s('sr_rule_2')),
                      _ruleItem(context, '3', s('sr_rule_3')),
                      _ruleItem(context, '4', s('sr_rule_4')),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color textSecondary) {
    return Chip(
      avatar: Icon(icon, size: 16, color: textSecondary),
      label: Text(text, style: TextStyle(fontSize: 11, color: textSecondary)),
      backgroundColor: textSecondary.withValues(alpha: 0.05),
      side: BorderSide.none,
    );
  }

  Widget _ruleItem(BuildContext context, String num, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColor.warningColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: AppColor.warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textPrimary, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
