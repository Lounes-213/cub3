import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'image_pick_api.dart';

/// الويب: مدخل ملف أصلي (input file) — يفتح دائماً بدون إضافات.
Future<PickedImageBytes?> pickPostImage() {
  final completer = Completer<PickedImageBytes?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';
  bool done = false;
  void finish(PickedImageBytes? v) {
    if (!done) {
      done = true;
      completer.complete(v);
    }
  }

  // toJS لا يقبل Future في نوع الإرجاع — الدالة خارجية ترجع void.
  Future<void> handleChange() async {
    try {
      final file = input.files?.item(0);
      if (file == null) {
        finish(null);
        return;
      }
      final jsBuf = await file.arrayBuffer().toDart;
      final bytes = jsBuf.toDart.asUint8List();
      final mime = file.type.isNotEmpty ? file.type : 'image/jpeg';
      finish(PickedImageBytes(bytes: bytes, mime: mime, name: file.name));
    } catch (_) {
      finish(null);
    }
  }

  input.onchange = (web.Event _) {
    handleChange();
  }.toJS;

  // إلغاء المستخدم = لا شيء (نفس سلوك المعرض)
  input.click();
  return completer.future;
}
