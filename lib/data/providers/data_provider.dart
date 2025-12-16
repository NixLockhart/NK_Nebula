import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/websocket_client.dart';
import '../../core/protocol/app_message.dart';
import '../../core/protocol/message_types.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'device_provider.dart';

/// 历史数据记录
class HistoryRecord {
  final DateTime timestamp;
  final Map<String, dynamic> data;

  HistoryRecord({required this.timestamp, required this.data});

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int? ?? 0),
      data: Map<String, dynamic>.from(json)..remove('ts'),
    );
  }

  double? getValue(String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return null;
  }
}

/// 历史数据状态
class HistoryDataState {
  final List<HistoryRecord> records;
  final bool isLoading;
  final String? error;
  final String selectedInterval;
  final DateTime? startTime;
  final DateTime? endTime;

  const HistoryDataState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.selectedInterval = '30s',
    this.startTime,
    this.endTime,
  });

  HistoryDataState copyWith({
    List<HistoryRecord>? records,
    bool? isLoading,
    String? error,
    String? selectedInterval,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return HistoryDataState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedInterval: selectedInterval ?? this.selectedInterval,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// 历史数据 Notifier
class HistoryDataNotifier extends StateNotifier<HistoryDataState> {
  final WebSocketClient _client;
  final Ref _ref;

  HistoryDataNotifier(this._client, this._ref) : super(const HistoryDataState());

  /// 加载历史数据
  Future<void> loadHistory({
    required String deviceId,
    DateTime? startTime,
    DateTime? endTime,
    String interval = '30s',
    List<String>? fields,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    // 默认时间范围：最近24小时
    final now = DateTime.now();
    final start = startTime ?? now.subtract(const Duration(hours: 24));
    final end = endTime ?? now;

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedInterval: interval,
      startTime: start,
      endTime: end,
    );

    try {
      final message = MessageFactory.createDataHistory(
        user.userId,
        deviceId,
        startTime: start.millisecondsSinceEpoch,
        endTime: end.millisecondsSinceEpoch,
        interval: interval,
        fields: fields,
      );

      final response = await _client.send(message);

      if (response.isSuccess) {
        final data = response.payload['data'] as Map<String, dynamic>? ?? {};
        final recordsList = data['records'] as List<dynamic>? ?? [];

        final records = recordsList
            .map((e) => HistoryRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          records: records,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage ?? '加载历史数据失败',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 设置时间间隔
  void setInterval(String interval) {
    state = state.copyWith(selectedInterval: interval);
  }

  /// 清除数据
  void clear() {
    state = const HistoryDataState();
  }
}

/// 历史数据 Provider
final historyDataProvider =
    StateNotifierProvider<HistoryDataNotifier, HistoryDataState>((ref) {
  final client = ref.read(wsClientProvider);
  return HistoryDataNotifier(client, ref);
});

/// 实时数据状态
class RealtimeDataState {
  final SensorData? sensorData;
  final DeviceStatus? status;
  final DateTime? lastUpdate;
  final bool isLoading;
  final String? error;

  const RealtimeDataState({
    this.sensorData,
    this.status,
    this.lastUpdate,
    this.isLoading = false,
    this.error,
  });

  RealtimeDataState copyWith({
    SensorData? sensorData,
    DeviceStatus? status,
    DateTime? lastUpdate,
    bool? isLoading,
    String? error,
  }) {
    return RealtimeDataState(
      sensorData: sensorData ?? this.sensorData,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 实时数据 Notifier
class RealtimeDataNotifier extends StateNotifier<RealtimeDataState> {
  final WebSocketClient _client;
  final Ref _ref;
  StreamSubscription? _messageSubscription;

  RealtimeDataNotifier(this._client, this._ref)
      : super(const RealtimeDataState()) {
    _listenToMessages();
  }

  void _listenToMessages() {
    _messageSubscription = _client.messageStream.listen(_onMessage);
  }

  void _onMessage(AppMessage message) {
    if (message.type != MessageType.dataRealtime) return;

    // 获取当前选中的设备 - 需要考虑 selectedDeviceIdProvider 为 null 时使用默认设备
    final selectedDeviceId = _ref.read(selectedDeviceIdProvider);
    final selectedDevice = _ref.read(selectedDeviceProvider);
    final effectiveDeviceId = selectedDeviceId ?? selectedDevice?.deviceId;

    if (effectiveDeviceId == null || message.deviceId != effectiveDeviceId) return;

    final data = message.payload['data'] as Map<String, dynamic>?;
    final statusJson = message.payload['status'] as Map<String, dynamic>?;

    // 只更新有数据的字段，保留之前的数据
    // 服务器分开推送 sensor_data 和 status，所以需要合并而不是覆盖
    final hasData = data != null && data.isNotEmpty;
    final hasStatus = statusJson != null && statusJson.isNotEmpty;

    // 如果两者都没有数据，忽略这条消息
    if (!hasData && !hasStatus) return;

    state = state.copyWith(
      sensorData: hasData ? SensorData.fromJson(data) : state.sensorData,
      status: hasStatus ? DeviceStatus.fromJson(statusJson) : state.status,
      lastUpdate: DateTime.now(),
    );
  }

  /// 清除数据
  void clear() {
    state = const RealtimeDataState();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}

/// 实时数据 Provider
final realtimeDataProvider =
    StateNotifierProvider<RealtimeDataNotifier, RealtimeDataState>((ref) {
  // 使用 ref.read 而不是 ref.watch，避免 WebSocket 状态变化导致 Provider 重建
  final client = ref.read(wsClientProvider);
  return RealtimeDataNotifier(client, ref);
});

/// 设备配置状态
class DeviceConfigState {
  final DeviceConfig? config;
  final bool isLoading;
  final String? error;

  const DeviceConfigState({
    this.config,
    this.isLoading = false,
    this.error,
  });

  DeviceConfigState copyWith({
    DeviceConfig? config,
    bool? isLoading,
    String? error,
  }) {
    return DeviceConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 设备配置 Notifier
class DeviceConfigNotifier extends StateNotifier<DeviceConfigState> {
  final WebSocketClient _client;
  final Ref _ref;

  DeviceConfigNotifier(this._client, this._ref)
      : super(const DeviceConfigState());

  /// 加载设备配置
  Future<void> loadConfig(String deviceId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final message = MessageFactory.createConfigGet(user.userId, deviceId);
      final response = await _client.send(message);

      if (response.isSuccess) {
        // 服务器返回格式: payload.data.{sensors, controls, actions, thresholds}
        final data = response.payload['data'] as Map<String, dynamic>? ?? {};
        final config = DeviceConfig.fromJson(data);
        state = DeviceConfigState(config: config);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage ?? '加载配置失败',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 添加传感器
  Future<bool> addSensor({
    required String deviceId,
    required String key,
    required String name,
    String? unit,
    String? icon,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message = MessageFactory.createSensorAdd(
        user.userId,
        deviceId,
        key: key,
        name: name,
        unit: unit,
        icon: icon,
      );
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 删除传感器
  Future<bool> deleteSensor(String deviceId, String key) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message = MessageFactory.createSensorDel(user.userId, deviceId, key);
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 添加控制
  Future<bool> addControl({
    required String deviceId,
    required String key,
    required String name,
    required String cmdOn,
    required String cmdOff,
    String? icon,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message = MessageFactory.createControlAdd(
        user.userId,
        deviceId,
        key: key,
        name: name,
        cmdOn: cmdOn,
        cmdOff: cmdOff,
        icon: icon,
      );
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 删除控制
  Future<bool> deleteControl(String deviceId, String key) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message =
          MessageFactory.createControlDel(user.userId, deviceId, key);
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 添加操作
  Future<bool> addAction({
    required String deviceId,
    required String key,
    required String name,
    String? icon,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message = MessageFactory.createActionAdd(
        user.userId,
        deviceId,
        key: key,
        name: name,
        cmd: key,
        icon: icon,
      );
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 删除操作
  Future<bool> deleteAction(String deviceId, String key) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message =
          MessageFactory.createActionDel(user.userId, deviceId, key);
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 添加阈值
  Future<bool> addThreshold({
    required String deviceId,
    required String sensorKey,
    required String controlKey,
    required String condition,
    required double value,
    required String action,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message = MessageFactory.createThresholdAdd(
        user.userId,
        deviceId,
        sensorKey: sensorKey,
        controlKey: controlKey,
        condition: condition,
        value: value,
        action: action,
      );
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 删除阈值
  Future<bool> deleteThreshold(String deviceId, int thresholdId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message =
          MessageFactory.createThresholdDel(user.userId, deviceId, thresholdId);
      final response = await _client.send(message);

      if (response.isSuccess) {
        await loadConfig(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clear() {
    state = const DeviceConfigState();
  }
}

/// 设备配置 Provider
final deviceConfigProvider =
    StateNotifierProvider<DeviceConfigNotifier, DeviceConfigState>((ref) {
  // 使用 ref.read 而不是 ref.watch，避免 Provider 被重建导致状态丢失
  final client = ref.read(wsClientProvider);
  return DeviceConfigNotifier(client, ref);
});

/// 发送控制命令
Future<bool> sendControlCommand(
  WidgetRef ref,
  String deviceId,
  String controlKey,
  bool turnOn,
) async {
  final client = ref.read(wsClientProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) {
    debugPrint('sendControlCommand: user is null');
    return false;
  }

  try {
    final message = MessageFactory.createControlCmd(
      user.userId,
      deviceId,
      controlKey: controlKey,
      state: turnOn ? 'on' : 'off',
    );
    debugPrint('sendControlCommand: sending ${message.toJsonString()}');
    final response = await client.send(message);
    debugPrint('sendControlCommand: response ${response.type}, success=${response.isSuccess}, payload=${response.payload}');
    return response.isSuccess;
  } catch (e) {
    debugPrint('sendControlCommand: error $e');
    return false;
  }
}

/// 发送操作命令
Future<bool> sendActionCommand(
  WidgetRef ref,
  String deviceId,
  String actionKey,
) async {
  final client = ref.read(wsClientProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return false;

  try {
    final message = MessageFactory.createActionCmd(
      user.userId,
      deviceId,
      actionKey: actionKey,
    );
    final response = await client.send(message);
    return response.isSuccess;
  } catch (e) {
    return false;
  }
}

/// 发送模式切换命令
Future<bool> sendModeCommand(
  WidgetRef ref,
  String deviceId,
  bool autoMode,
) async {
  final client = ref.read(wsClientProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) {
    debugPrint('sendModeCommand: user is null');
    return false;
  }

  try {
    // mode 控制项：autoMode=true 表示自动模式(mode=0)，autoMode=false 表示手动模式(mode=1)
    // 服务器协议：state='on' 表示开启手动模式，state='off' 表示关闭手动模式(即自动模式)
    final message = MessageFactory.createControlCmd(
      user.userId,
      deviceId,
      controlKey: 'mode',
      state: autoMode ? 'off' : 'on',  // 自动模式发送 off，手动模式发送 on
    );
    debugPrint('sendModeCommand: sending ${message.toJsonString()}');
    final response = await client.send(message);
    debugPrint('sendModeCommand: response ${response.type}, success=${response.isSuccess}, payload=${response.payload}');
    return response.isSuccess;
  } catch (e) {
    debugPrint('sendModeCommand: error $e');
    return false;
  }
}
