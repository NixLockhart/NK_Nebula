import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../protocol/app_message.dart';
import '../protocol/message_types.dart';

/// 连接状态
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  authenticated,
  error,
}

/// WebSocket 客户端
class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  ConnectionState _state = ConnectionState.disconnected;
  int _reconnectAttempts = 0;

  /// 待处理的请求 (msgId -> Completer)
  final Map<String, Completer<AppMessage>> _pendingRequests = {};

  /// 事件流控制器
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<AppMessage>.broadcast();

  /// 状态流
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// 消息流 (推送消息)
  Stream<AppMessage> get messageStream => _messageController.stream;

  /// 当前状态
  ConnectionState get state => _state;

  /// 是否已连接
  bool get isConnected =>
      _state == ConnectionState.connected ||
      _state == ConnectionState.authenticated;

  /// 连接服务器
  Future<bool> connect([String? url]) async {
    if (_state == ConnectionState.connecting) {
      return false;
    }

    _setState(ConnectionState.connecting);

    try {
      final wsUrl = url ?? AppConfig.wsUrl;
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _setState(ConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      return true;
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _setState(ConnectionState.error);
      _scheduleReconnect();
      return false;
    }
  }

  /// 断开连接
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(ConnectionState.disconnected);

    // 取消所有待处理的请求
    for (final completer in _pendingRequests.values) {
      completer.completeError('Connection closed');
    }
    _pendingRequests.clear();
  }

  /// 发送消息并等待响应
  Future<AppMessage> send(AppMessage message,
      {Duration? timeout}) async {
    if (!isConnected) {
      throw Exception('Not connected');
    }

    final completer = Completer<AppMessage>();
    _pendingRequests[message.msgId] = completer;

    debugPrint('WS Send: ${message.type}, msgId: ${message.msgId}');

    try {
      _channel!.sink.add(message.toJsonString());
    } catch (e) {
      _pendingRequests.remove(message.msgId);
      rethrow;
    }

    // 设置超时
    final timeoutDuration =
        timeout ?? Duration(milliseconds: AppConfig.requestTimeout);
    return completer.future.timeout(
      timeoutDuration,
      onTimeout: () {
        debugPrint('WS Timeout: ${message.type}, msgId: ${message.msgId}');
        _pendingRequests.remove(message.msgId);
        throw TimeoutException('Request timeout', timeoutDuration);
      },
    );
  }

  /// 发送消息不等待响应
  void sendNoWait(AppMessage message) {
    if (!isConnected) {
      return;
    }
    try {
      _channel!.sink.add(message.toJsonString());
    } catch (e) {
      debugPrint('Send error: $e');
    }
  }

  void _setState(ConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = AppMessage.fromJson(json);

      debugPrint('WS Received: ${message.type}, msgId: ${message.msgId}');

      // 检查是否为响应消息（通过 msg_id 匹配或通过 payload 中的 ref_msg_id 匹配）
      final msgId = message.msgId;
      final refMsgId = message.payload['ref_msg_id'] as String?;

      // 优先使用 ref_msg_id 匹配（服务器响应通常带有 ref_msg_id）
      if (refMsgId != null && _pendingRequests.containsKey(refMsgId)) {
        _pendingRequests.remove(refMsgId)?.complete(message);
        return;
      }

      // 然后尝试使用 msg_id 匹配
      if (_pendingRequests.containsKey(msgId)) {
        _pendingRequests.remove(msgId)?.complete(message);
        return;
      }

      // 对于结果类型的消息，尝试通过类型前缀匹配
      if (message.type.endsWith('.result')) {
        // 查找匹配的待处理请求
        final baseType = message.type.replaceAll('.result', '');
        for (final entry in _pendingRequests.entries.toList()) {
          // 简单匹配：找到一个等待的请求就返回
          _pendingRequests.remove(entry.key)?.complete(message);
          return;
        }
      }

      // 处理 Pong
      if (message.type == MessageType.sysPong) {
        return;
      }

      // 推送消息
      _messageController.add(message);
    } catch (e) {
      debugPrint('Message parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('WebSocket error: $error');
    _setState(ConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket closed');
    _setState(ConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: AppConfig.heartbeatInterval),
      (_) => _sendPing(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendPing() {
    sendNoWait(MessageFactory.createPing());
  }

  void _scheduleReconnect() {
    if (AppConfig.maxReconnectAttempts > 0 &&
        _reconnectAttempts >= AppConfig.maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: AppConfig.reconnectInterval),
      () {
        _reconnectAttempts++;
        connect();
      },
    );
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}
