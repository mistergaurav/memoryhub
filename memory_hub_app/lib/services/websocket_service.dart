import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

enum WebSocketConnectionState {
  connected,
  disconnected,
  connecting,
  error,
}

class WebSocketEvent {
  final String type;
  final Map<String, dynamic> data;

  WebSocketEvent({
    required this.type,
    required this.data,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: json['event'] as String? ?? json['type'] as String? ?? 'unknown',
      data: json['data'] as Map<String, dynamic>? ?? json,
    );
  }
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  WebSocketChannel? _channel;
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  final StreamController<WebSocketEvent> _eventController = StreamController<WebSocketEvent>.broadcast();
  final StreamController<WebSocketConnectionState> _stateController = StreamController<WebSocketConnectionState>.broadcast();
  
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _basePingInterval = Duration(seconds: 30);
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  bool _isDisposed = false;
  String? _lastToken;

  Stream<WebSocketEvent> get events => _eventController.stream;
  Stream<WebSocketConnectionState> get connectionState => _stateController.stream;
  WebSocketConnectionState get currentState => _connectionState;

  Future<void> connect() async {
    if (_isDisposed) {
      return;
    }

    if (_connectionState == WebSocketConnectionState.connected ||
        _connectionState == WebSocketConnectionState.connecting) {
      return;
    }

    try {
      _updateConnectionState(WebSocketConnectionState.connecting);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        _updateConnectionState(WebSocketConnectionState.error);
        _addEvent(WebSocketEvent(
          type: 'error',
          data: {'message': 'No authentication token available'},
        ));
        return;
      }

      _lastToken = token;

      final wsUrl = _buildWebSocketUrl(token);
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;

      _startPingTimer();

      _addEvent(WebSocketEvent(
        type: 'connection.established',
        data: {'message': 'WebSocket connected successfully'},
      ));
    } catch (e) {
      _handleError(e);
    }
  }

  String _buildWebSocketUrl(String token) {
    final wsBase = ApiConfig.wsBaseUrl;
    final encodedToken = Uri.encodeComponent(token);
    
    if (wsBase.startsWith('/')) {
      final base = Uri.base;
      final wsProtocol = base.scheme == 'https' ? 'wss' : 'ws';
      return '$wsProtocol://${base.host}${base.port != 0 && base.port != 80 && base.port != 443 ? ':${base.port}' : ''}$wsBase/notifications?token=$encodedToken';
    }
    
    return '$wsBase/notifications?token=$encodedToken';
  }

  void _handleMessage(dynamic message) {
    try {
      if (_isDisposed) return;

      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final event = WebSocketEvent.fromJson(data);

      if (event.type == 'pong') {
        return;
      }

      _addEvent(event);
    } catch (e) {
      _addEvent(WebSocketEvent(
        type: 'error',
        data: {'message': 'Failed to parse WebSocket message', 'error': e.toString()},
      ));
    }
  }

  void _handleError(dynamic error) {
    if (_isDisposed) return;

    _updateConnectionState(WebSocketConnectionState.error);
    _addEvent(WebSocketEvent(
      type: 'error',
      data: {'message': 'WebSocket error', 'error': error.toString()},
    ));

    _attemptReconnect();
  }

  void _handleDisconnect() {
    if (_isDisposed) return;

    _updateConnectionState(WebSocketConnectionState.disconnected);
    _pingTimer?.cancel();
    _pingTimer = null;

    _addEvent(WebSocketEvent(
      type: 'connection.closed',
      data: {'message': 'WebSocket connection closed'},
    ));

    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_isDisposed) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _addEvent(WebSocketEvent(
        type: 'error',
        data: {'message': 'Max reconnection attempts reached'},
      ));
      return;
    }

    _reconnectTimer?.cancel();

    final delay = _calculateBackoffDelay(_reconnectAttempts);
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  Duration _calculateBackoffDelay(int attempt) {
    final delayMs = _baseReconnectDelay.inMilliseconds * (1 << attempt);
    final maxDelayMs = _maxReconnectDelay.inMilliseconds;
    return Duration(milliseconds: delayMs > maxDelayMs ? maxDelayMs : delayMs);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_basePingInterval, (_) {
      if (_connectionState == WebSocketConnectionState.connected) {
        _sendPing();
      }
    });
  }

  void _sendPing() {
    try {
      if (_channel != null && _connectionState == WebSocketConnectionState.connected) {
        _channel!.sink.add(jsonEncode({
          'event': 'ping',
          'data': {'timestamp': DateTime.now().toIso8601String()},
        }));
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _updateConnectionState(WebSocketConnectionState state) {
    if (_isDisposed) return;
    _connectionState = state;
    _stateController.add(state);
  }

  void _addEvent(WebSocketEvent event) {
    if (_isDisposed) return;
    _eventController.add(event);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;

    try {
      _channel?.sink.close(status.normalClosure);
    } catch (e) {
    }

    _channel = null;
    _reconnectAttempts = 0;
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
