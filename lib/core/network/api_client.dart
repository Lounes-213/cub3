import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  Map<String, String> _headersWith(Map<String, String>? extra) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?extra,
      };

  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: _headersWith(headers)).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient GET Error ($url): $e');
      rethrow;
    }
  }

  Future<dynamic> post(String url, {dynamic body, Map<String, String>? headers}) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _headersWith(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient POST Error ($url): $e');
      rethrow;
    }
  }

  Future<dynamic> put(String url, {dynamic body, Map<String, String>? headers}) async {
    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: _headersWith(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient PUT Error ($url): $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client.delete(Uri.parse(url), headers: _headersWith(headers)).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient DELETE Error ($url): $e');
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP Error $status: ${response.body}');
    }
  }
}
