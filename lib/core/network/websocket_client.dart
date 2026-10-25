import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

class WebSocketClient {
  static final WebSocketClient _instance = WebSocketClient._internal();
  factory WebSocketClient() => _instance;
  WebSocketClient._internal();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _stateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic> _currentState = {};
  Map<String, dynamic> get currentState => _currentState;

  /// كل مستمع جديد يحصل فوراً على آخر حالة مخزّنة ثم على التحديثات القادمة.
  /// هكلا لا تبقى أي شاشة عالقة في وضع التحميل بعد إعادة الاتصال،
  /// ويرجع اللاعب لنفس البلاصة اللي كان فيها.
  Stream<Map<String, dynamic>> get stateStream {
    return Stream<Map<String, dynamic>>.multi((controller) {
      final subscription = _stateController.stream.listen(
        controller.addSync,
        onError: controller.addErrorSync,
        onDone: controller.closeSync,
      );
      if (_currentState.isNotEmpty) {
        controller.addSync(_currentState);
      }
      controller.onCancel = subscription.cancel;
    });
  }

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _disposed = false;

  void connect() {
    if (_isConnected || _disposed) return;

    try {
      final uri = Uri.parse(ApiConstants.wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      debugPrint('🔗 Connecting to Cloudflare Durable Object WebSocket: $uri');

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          debugPrint('⚠️ WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('🔌 WebSocket connection closed.');
          _scheduleReconnect();
        },
      );

      _startHeartbeat();
    } catch (e) {
      debugPrint('⚠️ WebSocket connect exception: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final raw = data is String ? data : utf8.decode(data as List<int>);
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        final type = decoded['type'];
        if (type == 'error') {
          // أخطاء الأكشنز (مثلاً: صلاحية غير كافية) — نطبعها حتى ما يبانش
          // الزر "ما يخدمش" بلا أي سبب واضح في اللوق
          debugPrint('⚠️ Game action error: ${decoded['message']}');
        } else if (type == 'init' || type == 'state_update') {
          if (decoded['state'] != null) {
            _currentState = Map<String, dynamic>.from(decoded['state'] as Map);
            _stateController.add(_currentState);
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing WS message: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'action': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _scheduleReconnect() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    if (_disposed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('🔄 Reconnecting to Cloudflare WebSocket...');
      connect();
    });
  }

  /// Sends action to Cloudflare Durable Object
  Future<void> sendAction(String action, [Map<String, dynamic>? data]) async {
    final payload = {
      'action': action,
      ...?data,
    };

    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(payload));
        return;
      } catch (e) {
        debugPrint('Failed to send over WS, fallback to HTTP: $e');
      }
    }

    // Fallback to HTTP action endpoint
    try {
      final uri = Uri.parse(ApiConstants.gameAction);
      final response = await httpPost(uri, payload);
      if (response != null && response['state'] != null) {
        _currentState = Map<String, dynamic>.from(response['state'] as Map);
        _stateController.add(_currentState);
      }
    } catch (e) {
      debugPrint('Fallback HTTP action error: $e');
    }
  }

  static Future<Map<String, dynamic>?> httpPost(Uri uri, Map<String, dynamic> payload) async {
    try {
      final client = ApiClient();
      final res = await client.post(uri.toString(), body: payload);
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    return null;
  }

  void dispose() {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _stateController.close();
  }
}
