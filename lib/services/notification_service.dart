import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'reservation_service.dart';

/// تنبيهات محلية (النظام): تذكير تلقائي عند اقتراب انتهاء حجز الإطعام.
/// تعمل على الهاتف؛ على الويب تُتجاهل بأمان (التنبيه داخل التطبيق يكفي).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cube3_reservations',
    'تذكيرات الحجز',
    description: 'تنبيهات حجز الإطعام والخدمات',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        // التوقيت المحلي للجزائر — حتى يُحسب ميعاد الإشعار بشكل صحيح.
        tz.setLocalLocation(tz.getLocation('Africa/Algiers'));
      } catch (_) {
        // يبقى UTC كخيار أخير — التنبيه يبقى صحيحاً لأن الأساس DateTime محلي.
      }
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('notifications init skipped: $e');
    }
  }

  /// جدولة تذكير قبل انتهاء الحجز بـ [before] (تُستبدل أي جدولة سابقة).
  static Future<void> scheduleReservationReminder(DateTime expiry) async {
    try {
      await init();
      if (kIsWeb) return;
      const id = 1001;
      await _plugin.cancel(id);
      final when = expiry.subtract(const Duration(hours: 8));
      if (when.isBefore(DateTime.now())) return; // فات الأوان — التنبيه الفوري يكفي
      await _plugin.zonedSchedule(
        id,
        'تذكير حجز الإطعام 🍽️ (باقي 8 ساعات)',
        'ينتهي حجز الإطعام الخاص بك بعد 8 ساعات — يرجى التجديد الآن',
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cube3_reservations',
            'تذكيرات الحجز',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('schedule reminder skipped: $e');
    }
  }

  /// تنبيه فوري (يُستدعى عند فتح التطبيق والحجز على وشك الانتهاء).
  static Future<void> showExpiringNow() async {
    try {
      await init();
      if (kIsWeb) return;
      await _plugin.show(
        1002,
        'حجز الإطعام ينتهي قريباً ⏰',
        'بقي أقل من 24 ساعة — جدّد حجزك من مصلحة الإطعام',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cube3_reservations',
            'تذكيرات الحجز',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('instant reminder skipped: $e');
    }
  }

  /// فحص تلقائي عند الدخول: تنبيه إذا كان الحجز منتهياً أو قريب الانتهاء.
  /// يرجع الحالة لعرضها داخل التطبيق أيضاً.
  /// يعيد أيضاً برمجة تذكير الـ 8 ساعات (يدوّر بعد إعادة تشغيل الهاتف
  /// أو بعد إغلاق التطبيق — الإشعارات المجدولة تُلغى مع كل إقلاع).
  static Future<String> checkOnEntry() async {
    final data = await ReservationService.load();
    if (data == null) return 'none';
    if (!ReservationService.isActive(data)) return 'expired';
    if (ReservationService.isExpiringSoon(data)) {
      await showExpiringNow();
      return 'soon';
    }
    // حجز فعّال ولم يبقَ عليه 8 ساعات بعد → أعد برمجة التذكير (idempotent).
    final exp = ReservationService.expiryOf(data);
    if (exp != null) await scheduleReservationReminder(exp);
    return 'ok';
  }
}
