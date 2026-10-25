import 'package:flutter/material.dart';
import '../widgets/glass_app_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../localization/app_strings.dart';
import '../theme/theme.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String _selectedType = 'elec';
  final _roomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _sent = false;

  final List<Map<String, dynamic>> _types = [
    {'key': 'elec', 'icon': Icons.electrical_services},
    {'key': 'plumbing', 'icon': Icons.water_damage},
    {'key': 'doors', 'icon': Icons.door_front_door},
    {'key': 'furniture', 'icon': Icons.chair},
    {'key': 'other', 'icon': Icons.build},
  ];

  @override
  void dispose() {
    _roomCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_roomCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _sent = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sent = false);
    });
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
          s('maintenance_title'),
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
          Text(
            s('maintenance_desc'),
            style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),

          // Issue type selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final isSelected = _selectedType == t['key'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.black : textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s(t['key'] as String),
                      style: TextStyle(
                        color: isSelected ? Colors.black : textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColor.primaryColor,
                backgroundColor: surface,
                side: BorderSide(
                  color: isSelected
                      ? AppColor.primaryColor
                      : textSecondary.withValues(alpha: 0.2),
                ),
                onSelected: (_) {
                  setState(() => _selectedType = t['key'] as String);
                },
              );
            }).toList(),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          // Room field
          TextField(
            controller: _roomCtrl,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: s('room_num'),
              labelStyle: TextStyle(color: textSecondary),
              prefixIcon: Icon(Icons.meeting_room, color: textSecondary),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: s('description'),
              labelStyle: TextStyle(color: textSecondary),
              prefixIcon: Icon(Icons.description, color: textSecondary),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.3),
              ),
              onPressed: _send,
              icon: const Icon(Icons.send, size: 20),
              label: Text(
                _sent ? '✓ ${s('confirm')}' : s('send_report'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ).animate().fadeIn(),

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
                        s('maintenance_rules'),
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
                      _ruleItem(context, '1', s('mr_rule_1')),
                      _ruleItem(context, '2', s('mr_rule_2')),
                      _ruleItem(context, '3', s('mr_rule_3')),
                      _ruleItem(context, '4', s('mr_rule_4')),
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
