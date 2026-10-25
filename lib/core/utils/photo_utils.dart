import 'dart:convert';
import 'dart:typed_data';

/// فك تشفير آمن لصور base64 (صور PROGRES وغيرها).
/// يرجع null بدل رمي خطأ — لا شاشة حمراء أبداً.
Uint8List? tryDecodePhoto(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.length < 100) return null;
  // إزالة بادئة data-URI إن وجدت
  final comma = s.indexOf(',');
  if (s.startsWith('data:') && comma != -1 && comma < 100) {
    s = s.substring(comma + 1);
  }
  s = s.replaceAll(RegExp(r'\s+'), '');
  try {
    final bytes = base64Decode(s);
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}

/// تنظيف صورة قبل حفظها (إزالة البادئة والفراغات + تحقق).
String? sanitizePhotoForSave(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  final comma = s.indexOf(',');
  if (s.startsWith('data:') && comma != -1 && comma < 100) {
    s = s.substring(comma + 1);
  }
  s = s.replaceAll(RegExp(r'\s+'), '').replaceAll('"', '');
  if (s.length < 100) return null;
  try {
    base64Decode(s);
    return s;
  } catch (_) {
    return null;
  }
}

/// تنظيف وإرجاع رسالة خطأ موحدة ونظيفة لعمليات رفع الصور بدون مسارات R2 أو التفاصيل التقنية.
String cleanUploadErrorMessage(dynamic error) {
  if (error == null) return 'حدث خطأ أثناء رفع الصورة';
  final raw = error.toString();

  if (raw.contains('كبيرة جداً') ||
      raw.contains('FILE_TOO_LARGE') ||
      raw.contains('5MB') ||
      raw.contains('5 ميغابايت')) {
    return 'حجم الصورة كبير جداً (الحد الأقصى 5 ميغابايت)';
  }
  if (raw.contains('IMAGES_ONLY') || raw.contains('صور فقط')) {
    return 'مسموح برفع ملفات الصور فقط';
  }
  if (raw.contains('MAX_POSTS_REACHED')) {
    return 'وصلت للحد الأقصى المسموح به';
  }

  // رسالة نظيفة عامة لأي خطأ آخر في رفع الصور أو التخزين السحابي
  return 'تعذر رفع الصورة. يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة.';
}
