import 'package:image_picker/image_picker.dart';
import 'image_pick_api.dart';

/// الهاتف/سطح المكتب: معرض الصور عبر image_picker (مع ضغط تلقائي).
Future<PickedImageBytes?> pickPostImage() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1280,
    imageQuality: 85,
  );
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final name = picked.name.toLowerCase();
  final mime = name.endsWith('.png')
      ? 'image/png'
      : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
  return PickedImageBytes(bytes: bytes, mime: mime, name: picked.name);
}
