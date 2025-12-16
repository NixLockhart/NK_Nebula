/// 消息类型定义 - APP ↔ Server 协议
class MessageType {
  // ===== 认证相关 =====
  static const String authRegister = 'auth.register';
  static const String authLogin = 'auth.login';
  static const String authLogout = 'auth.logout';
  static const String authResult = 'auth.result';

  // ===== 设备管理 =====
  static const String deviceList = 'device.list';
  static const String deviceListResult = 'device.list.result';
  static const String deviceBind = 'device.bind';
  static const String deviceUnbind = 'device.unbind';
  static const String deviceRename = 'device.rename';
  static const String deviceStatus = 'device.status';
  static const String deviceResult = 'device.result';

  // ===== 配置管理 =====
  static const String configGet = 'config.get';
  static const String configGetResult = 'config.get.result';
  static const String configSensorAdd = 'config.sensor.add';
  static const String configSensorDel = 'config.sensor.del';
  static const String configControlAdd = 'config.control.add';
  static const String configControlDel = 'config.control.del';
  static const String configActionAdd = 'config.action.add';
  static const String configActionDel = 'config.action.del';
  static const String configThresholdAdd = 'config.threshold.add';
  static const String configThresholdDel = 'config.threshold.del';
  static const String configResult = 'config.result';

  // ===== 实时数据 =====
  static const String dataRealtime = 'data.realtime';
  static const String dataHistory = 'data.history';
  static const String dataHistoryResult = 'data.history.result';

  // ===== 控制命令 =====
  static const String cmdControl = 'cmd.control';
  static const String cmdAction = 'cmd.action';
  static const String cmdResult = 'cmd.result';

  // ===== 系统消息 =====
  static const String sysError = 'sys.error';
  static const String sysPing = 'sys.ping';
  static const String sysPong = 'sys.pong';
}
