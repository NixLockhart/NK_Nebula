import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'message_types.dart';

const _uuid = Uuid();

/// APP-Server 消息基类
class AppMessage {
  final String version;
  final String msgId;
  final int timestamp;
  final String type;
  final String? userId;
  final String? deviceId;
  final Map<String, dynamic> payload;

  AppMessage({
    String? version,
    String? msgId,
    int? timestamp,
    required this.type,
    this.userId,
    this.deviceId,
    Map<String, dynamic>? payload,
  })  : version = version ?? AppConfig.protocolVersion,
        msgId = msgId ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch,
        payload = payload ?? {};

  /// 从 JSON 解析
  factory AppMessage.fromJson(Map<String, dynamic> json) {
    return AppMessage(
      version: json['version'] as String? ?? AppConfig.protocolVersion,
      msgId: json['msg_id'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      userId: json['user_id'] as String?,
      deviceId: json['device_id'] as String?,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }

  /// 从 JSON 字符串解析
  factory AppMessage.fromJsonString(String jsonString) {
    return AppMessage.fromJson(jsonDecode(jsonString));
  }

  /// 转为 JSON Map
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'version': version,
      'msg_id': msgId,
      'timestamp': timestamp,
      'type': type,
      'payload': payload,
    };
    if (userId != null) map['user_id'] = userId;
    if (deviceId != null) map['device_id'] = deviceId;
    return map;
  }

  /// 转为 JSON 字符串
  String toJsonString() => jsonEncode(toJson());

  /// 检查是否为响应消息
  bool get isResponse =>
      type.endsWith('.result') || type == MessageType.authResult;

  /// 检查是否为推送消息
  bool get isPush =>
      type == MessageType.dataRealtime || type == MessageType.deviceStatus;

  /// 检查是否成功 (响应消息)
  bool get isSuccess => payload['success'] == true || payload['code'] == 0;

  /// 获取错误消息
  String? get errorMessage => payload['message'] as String?;

  /// 获取错误码
  int? get errorCode => payload['code'] as int?;

  @override
  String toString() => 'AppMessage(type: $type, msgId: $msgId)';
}

/// 消息工厂
class MessageFactory {
  // ===== 认证消息 =====

  /// 创建注册消息
  static AppMessage createRegister(String username, String password) {
    return AppMessage(
      type: MessageType.authRegister,
      payload: {
        'username': username,
        'password': password,
      },
    );
  }

  /// 创建登录消息
  static AppMessage createLogin(String username, String password) {
    return AppMessage(
      type: MessageType.authLogin,
      payload: {
        'username': username,
        'password': password,
      },
    );
  }

  /// 创建登出消息
  static AppMessage createLogout(String userId) {
    return AppMessage(
      type: MessageType.authLogout,
      userId: userId,
    );
  }

  // ===== 设备管理消息 =====

  /// 获取设备列表
  static AppMessage createDeviceList(String userId) {
    return AppMessage(
      type: MessageType.deviceList,
      userId: userId,
    );
  }

  /// 重命名设备
  static AppMessage createDeviceRename(
      String userId, String deviceId, String newName) {
    return AppMessage(
      type: MessageType.deviceRename,
      userId: userId,
      deviceId: deviceId,
      payload: {'name': newName},
    );
  }

  /// 解绑设备
  static AppMessage createDeviceUnbind(String userId, String deviceId) {
    return AppMessage(
      type: MessageType.deviceUnbind,
      userId: userId,
      deviceId: deviceId,
    );
  }

  // ===== 配置管理消息 =====

  /// 获取设备配置
  static AppMessage createConfigGet(String userId, String deviceId) {
    return AppMessage(
      type: MessageType.configGet,
      userId: userId,
      deviceId: deviceId,
    );
  }

  /// 添加传感器配置
  static AppMessage createSensorAdd(
    String userId,
    String deviceId, {
    required String key,
    required String name,
    String? unit,
    String? icon,
    int? order,
  }) {
    return AppMessage(
      type: MessageType.configSensorAdd,
      userId: userId,
      deviceId: deviceId,
      payload: {
        'key': key,
        'name': name,
        if (unit != null) 'unit': unit,
        if (icon != null) 'icon': icon,
        if (order != null) 'order': order,
      },
    );
  }

  /// 删除传感器配置
  static AppMessage createSensorDel(
      String userId, String deviceId, String key) {
    return AppMessage(
      type: MessageType.configSensorDel,
      userId: userId,
      deviceId: deviceId,
      payload: {'key': key},
    );
  }

  /// 添加控制配置
  static AppMessage createControlAdd(
    String userId,
    String deviceId, {
    required String key,
    required String name,
    required String cmdOn,
    required String cmdOff,
    String? icon,
    int? order,
  }) {
    return AppMessage(
      type: MessageType.configControlAdd,
      userId: userId,
      deviceId: deviceId,
      payload: {
        'key': key,
        'name': name,
        'cmd_on': cmdOn,
        'cmd_off': cmdOff,
        if (icon != null) 'icon': icon,
        if (order != null) 'order': order,
      },
    );
  }

  /// 删除控制配置
  static AppMessage createControlDel(
      String userId, String deviceId, String key) {
    return AppMessage(
      type: MessageType.configControlDel,
      userId: userId,
      deviceId: deviceId,
      payload: {'key': key},
    );
  }

  /// 添加操作配置
  static AppMessage createActionAdd(
    String userId,
    String deviceId, {
    required String key,
    required String name,
    required String cmd,
    String? icon,
    int? order,
  }) {
    return AppMessage(
      type: MessageType.configActionAdd,
      userId: userId,
      deviceId: deviceId,
      payload: {
        'key': key,
        'name': name,
        'cmd': cmd,
        if (icon != null) 'icon': icon,
        if (order != null) 'order': order,
      },
    );
  }

  /// 删除操作配置
  static AppMessage createActionDel(
      String userId, String deviceId, String key) {
    return AppMessage(
      type: MessageType.configActionDel,
      userId: userId,
      deviceId: deviceId,
      payload: {'key': key},
    );
  }

  /// 添加阈值配置
  static AppMessage createThresholdAdd(
    String userId,
    String deviceId, {
    required String sensorKey,
    required String controlKey,
    required String condition,
    required double value,
    required String action,
  }) {
    return AppMessage(
      type: MessageType.configThresholdAdd,
      userId: userId,
      deviceId: deviceId,
      payload: {
        'sensor_key': sensorKey,
        'control_key': controlKey,
        'condition': condition,
        'value': value,
        'action': action,
      },
    );
  }

  /// 删除阈值配置
  static AppMessage createThresholdDel(
      String userId, String deviceId, int thresholdId) {
    return AppMessage(
      type: MessageType.configThresholdDel,
      userId: userId,
      deviceId: deviceId,
      payload: {'id': thresholdId},
    );
  }

  // ===== 数据消息 =====

  /// 获取历史数据
  static AppMessage createDataHistory(
    String userId,
    String deviceId, {
    int? startTime,
    int? endTime,
    String interval = '1h',
    List<String>? fields,
  }) {
    return AppMessage(
      type: MessageType.dataHistory,
      userId: userId,
      deviceId: deviceId,
      payload: {
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        'interval': interval,
        if (fields != null) 'fields': fields,
      },
    );
  }

  // ===== 控制命令消息 =====

  /// 开关控制
  static AppMessage createControlCmd(
    String userId,
    String deviceId, {
    required String controlKey,
    required String state, // "on" or "off"
  }) {
    return AppMessage(
      type: MessageType.cmdControl,
      userId: userId,
      deviceId: deviceId,
      payload: {
        'control_key': controlKey,
        'state': state,
      },
    );
  }

  /// 功能操作
  static AppMessage createActionCmd(
    String userId,
    String deviceId, {
    required String actionKey,
  }) {
    return AppMessage(
      type: MessageType.cmdAction,
      userId: userId,
      deviceId: deviceId,
      payload: {
        'action_key': actionKey,
      },
    );
  }

  // ===== 系统消息 =====

  /// 心跳
  static AppMessage createPing() {
    return AppMessage(type: MessageType.sysPing);
  }
}
