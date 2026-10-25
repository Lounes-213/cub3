import '../../../core/services/cloudflare_service.dart';

abstract class IMediaRepository {
  Future<String?> uploadImageBase64(String base64Image, {String mime});
}

class MediaRepository implements IMediaRepository {
  final CloudflareService _cf = CloudflareService();

  @override
  Future<String?> uploadImageBase64(String base64Image, {String mime = 'image/jpeg'}) {
    return _cf.uploadImageBase64(base64Image, mime: mime);
  }
}
