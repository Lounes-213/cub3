import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_app_bar.dart';
import '../theme/theme.dart';
import '../localization/app_strings.dart';
import '../services/reservation_service.dart';
import '../services/notification_service.dart';
import '../providers/user_provider.dart';

/// قسم الإطعام الجامعي: حجز الإطعام والتنبيهات
class CateringScreen extends StatefulWidget {
  const CateringScreen({super.key});

  @override
  State<CateringScreen> createState() => _CateringScreenState();
}

class _CateringScreenState extends State<CateringScreen> {
  Map<String, dynamic>? _reservation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final data = await ReservationService.load();
    if (!mounted) return;
    setState(() {
      _reservation = data;
      _loading = false;
    });
    if (data != null && ReservationService.isActive(data)) {
      if (ReservationService.isExpiringSoon(data)) {
        await NotificationService.showExpiringNow();
      } else {
        // أعد برمجة تذكير الـ 8 ساعات (يدوّر بعد إعادة تشغيل الهاتف).
        final exp = ReservationService.expiryOf(data);
        if (exp != null) {
          await NotificationService.scheduleReservationReminder(exp);
        }
      }
    }
  }

  Future<void> _reserve() async {
    final data = await ReservationService.reserveNow();
    final exp = ReservationService.expiryOf(data);
    if (exp != null) {
      await NotificationService.scheduleReservationReminder(exp);
    }

    if (mounted) {
      final user = context.read<UserProvider>();
      final matricule = user.matricule.isNotEmpty ? user.matricule : 'guest';
      final name = user.fullNameAr.isNotEmpty ? user.fullNameAr : 'طالب مقيم';
      ReservationService.syncToAdmin(matricule: matricule, name: name);
    }

    if (!mounted) return;
    setState(() => _reservation = data);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تسجيل وحفظ حجز الإطعام لـ 3 أيام ✅ وسيصلك تنبيه قبل 8 ساعات من الانتهاء'),
        backgroundColor: AppColor.correctColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColor.surfaceColor : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlassAppBar(
        title: Text(
          AppStrings.of(context, 'dept_catering'),
          style: TextStyle(fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.2),
        ),
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primaryColor))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                _buildReservationCard(surface, textPrimary, textSecondary)
                    .animate()
                    .fadeIn()
                    .slideY(begin: -0.04),
              ],
            ),
    );
  }

  Widget _buildReservationCard(
      Color surface, Color textPrimary, Color textSecondary) {
    final active =
        _reservation != null && ReservationService.isActive(_reservation);
    final soon = active && ReservationService.isExpiringSoon(_reservation);
    final statusColor = !active
        ? Colors.redAccent
        : soon
            ? Colors.orangeAccent
            : AppColor.correctColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              active ? Icons.event_available : Icons.event_busy,
              color: statusColor,
              size: 34,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حجز الإطعام',
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    !active
                        ? 'لا يوجد حجز نشط'
                        : soon
                            ? 'ينتهي قريباً ⏰'
                            : 'حجز نشط ✅',
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ReservationService.remainingLabel(_reservation),
                  style: TextStyle(color: textSecondary, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: _reserve,
                    icon: const Icon(Icons.notifications_active_outlined,
                        size: 18),
                    label: Text(
                      active ? 'تجديد الحجز (3 أيام)' : 'ذكّرني بالحجز 🔔',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
