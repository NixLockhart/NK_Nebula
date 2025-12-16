/// 传感器实时数据
class SensorData {
  final Map<String, dynamic> values;
  final DateTime recordedAt;

  SensorData({
    required this.values,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final recordedAt = json['recorded_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['recorded_at'] as int)
        : DateTime.now();

    // 移除非传感器字段
    final values = Map<String, dynamic>.from(json)
      ..remove('recorded_at')
      ..remove('timestamp');

    return SensorData(values: values, recordedAt: recordedAt);
  }

  /// 获取传感器值
  dynamic operator [](String key) => values[key];

  /// 获取整数值
  int? getInt(String key) {
    final value = values[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 获取浮点值
  double? getDouble(String key) {
    final value = values[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// 设备状态数据
class DeviceStatus {
  final int mode; // 0=自动, 1=手动
  final Map<String, int> controlStates;
  final DateTime updatedAt;

  DeviceStatus({
    this.mode = 0,
    required this.controlStates,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as int? ?? 0;
    final controlStates = <String, int>{};

    json.forEach((key, value) {
      if (key != 'mode' && key != 'recorded_at' && value is int) {
        controlStates[key] = value;
      }
    });

    return DeviceStatus(mode: mode, controlStates: controlStates);
  }

  /// 获取控制状态
  bool isOn(String key) => controlStates[key] == 1;

  /// 是否为自动模式
  bool get isAutoMode => mode == 0;

  /// 是否为手动模式
  bool get isManualMode => mode == 1;
}

/// 实时数据包
class RealtimeData {
  final String deviceId;
  final SensorData? sensorData;
  final DeviceStatus? status;
  final DateTime receivedAt;

  RealtimeData({
    required this.deviceId,
    this.sensorData,
    this.status,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory RealtimeData.fromJson(Map<String, dynamic> json) {
    final deviceId = json['device_id'] as String? ?? '';
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final statusJson = json['status'] as Map<String, dynamic>?;

    return RealtimeData(
      deviceId: deviceId,
      sensorData: data.isNotEmpty ? SensorData.fromJson(data) : null,
      status: statusJson != null ? DeviceStatus.fromJson(statusJson) : null,
      receivedAt: json['recorded_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['recorded_at'] as int)
          : DateTime.now(),
    );
  }
}

/// 历史数据记录
class HistoryRecord {
  final DateTime timestamp;
  final Map<String, dynamic> values;

  HistoryRecord({
    required this.timestamp,
    required this.values,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'] ?? json['recorded_at'];
    final timestamp = ts is int
        ? DateTime.fromMillisecondsSinceEpoch(ts)
        : DateTime.tryParse(ts as String? ?? '') ?? DateTime.now();

    final values = Map<String, dynamic>.from(json)
      ..remove('timestamp')
      ..remove('recorded_at');

    return HistoryRecord(timestamp: timestamp, values: values);
  }
}
