import 'dart:typed_data';

/// صورة مختارة (مشتركة بين الويب والهاتف).
class PickedImageBytes {
  final Uint8List bytes;
  final String mime;
  final String name;
  const PickedImageBytes(
      {required this.bytes, required this.mime, required this.name});
}
