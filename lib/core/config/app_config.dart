/// 应用配置
class AppConfig {
  /// WebSocket 服务器地址
  static const String wsHost = '111.228.6.160';
  static const int wsPort = 8002;

  /// 完整 WebSocket URL
  static String get wsUrl => 'ws://$wsHost:$wsPort';

  /// 协议版本
  static const String protocolVersion = '1.0';

  /// 心跳间隔 (秒)
  static const int heartbeatInterval = 30;

  /// 重连间隔 (秒)
  static const int reconnectInterval = 5;

  /// 最大重连次数 (0=无限)
  static const int maxReconnectAttempts = 0;

  /// 请求超时 (毫秒)
  static const int requestTimeout = 10000;

  /// 数据刷新间隔 (毫秒)
  static const int dataRefreshInterval = 3000;
}
