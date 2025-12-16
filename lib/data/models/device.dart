/// 设备模型
class Device {
  final String deviceId;
  final String name;
  final String status; // 'online' or 'offline'
  final String? firmwareVersion;
  final DateTime? createdAt;
  final DateTime? lastHeartbeat;

  Device({
    required this.deviceId,
    required this.name,
    this.status = 'offline',
    this.firmwareVersion,
    this.createdAt,
    this.lastHeartbeat,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['device_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      firmwareVersion: json['firmware_version'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastHeartbeat: json['last_heartbeat'] != null
          ? DateTime.tryParse(json['last_heartbeat'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'name': name,
        'status': status,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      };

  Device copyWith({
    String? deviceId,
    String? name,
    String? status,
    String? firmwareVersion,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      status: status ?? this.status,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      createdAt: createdAt,
      lastHeartbeat: lastHeartbeat,
    );
  }

  bool get isOnline => status == 'online';
}

/// 传感器配置
class SensorConfig {
  final int? id;
  final String fieldKey;
  final String fieldName;
  final String unit;
  final String icon;
  final int displayOrder;
  final bool isEnabled;

  SensorConfig({
    this.id,
    required this.fieldKey,
    required this.fieldName,
    this.unit = '',
    this.icon = '',
    this.displayOrder = 0,
    this.isEnabled = true,
  });

  factory SensorConfig.fromJson(Map<String, dynamic> json) {
    return SensorConfig(
      id: json['id'] as int?,
      fieldKey: json['field_key'] as String? ?? json['key'] as String? ?? '',
      fieldName: json['field_name'] as String? ?? json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? json['order'] as int? ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'key': fieldKey,
        'name': fieldName,
        'unit': unit,
        'icon': icon,
        'order': displayOrder,
      };
}

/// 控制配置
class ControlConfig {
  final int? id;
  final String controlKey;
  final String controlName;
  final String cmdOn;
  final String cmdOff;
  final String icon;
  final int displayOrder;
  final bool isEnabled;

  ControlConfig({
    this.id,
    required this.controlKey,
    required this.controlName,
    required this.cmdOn,
    required this.cmdOff,
    this.icon = '',
    this.displayOrder = 0,
    this.isEnabled = true,
  });

  factory ControlConfig.fromJson(Map<String, dynamic> json) {
    return ControlConfig(
      id: json['id'] as int?,
      controlKey:
          json['control_key'] as String? ?? json['key'] as String? ?? '',
      controlName:
          json['control_name'] as String? ?? json['name'] as String? ?? '',
      cmdOn: json['cmd_on'] as String? ?? '',
      cmdOff: json['cmd_off'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? json['order'] as int? ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'key': controlKey,
        'name': controlName,
        'cmd_on': cmdOn,
        'cmd_off': cmdOff,
        'icon': icon,
        'order': displayOrder,
      };
}

/// 操作配置
class ActionConfig {
  final int? id;
  final String actionKey;
  final String actionName;
  final String cmd;
  final String icon;
  final int displayOrder;
  final bool isEnabled;

  ActionConfig({
    this.id,
    required this.actionKey,
    required this.actionName,
    required this.cmd,
    this.icon = '',
    this.displayOrder = 0,
    this.isEnabled = true,
  });

  factory ActionConfig.fromJson(Map<String, dynamic> json) {
    return ActionConfig(
      id: json['id'] as int?,
      actionKey: json['action_key'] as String? ?? json['key'] as String? ?? '',
      actionName:
          json['action_name'] as String? ?? json['name'] as String? ?? '',
      cmd: json['cmd'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      displayOrder: json['display_order'] as int? ?? json['order'] as int? ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'key': actionKey,
        'name': actionName,
        'cmd': cmd,
        'icon': icon,
        'order': displayOrder,
      };
}

/// 阈值配置
class ThresholdConfig {
  final int? id;
  final String sensorKey;
  final String controlKey;
  final String conditionType; // 'gt', 'lt', 'eq', 'gte', 'lte'
  final double thresholdValue;
  final String triggerAction; // 'on' or 'off'
  final bool isEnabled;

  ThresholdConfig({
    this.id,
    required this.sensorKey,
    required this.controlKey,
    required this.conditionType,
    required this.thresholdValue,
    required this.triggerAction,
    this.isEnabled = true,
  });

  factory ThresholdConfig.fromJson(Map<String, dynamic> json) {
    return ThresholdConfig(
      id: json['id'] as int?,
      sensorKey: json['sensor_key'] as String? ?? '',
      controlKey: json['control_key'] as String? ?? '',
      conditionType:
          json['condition_type'] as String? ?? json['condition'] as String? ?? 'gt',
      thresholdValue: (json['threshold_value'] ?? json['value'] ?? 0).toDouble(),
      triggerAction:
          json['trigger_action'] as String? ?? json['action'] as String? ?? 'on',
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'sensor_key': sensorKey,
        'control_key': controlKey,
        'condition': conditionType,
        'value': thresholdValue,
        'action': triggerAction,
      };

  /// 获取条件显示文本
  String get conditionDisplay {
    switch (conditionType) {
      case 'gt':
        return '>';
      case 'lt':
        return '<';
      case 'eq':
        return '=';
      case 'gte':
        return '>=';
      case 'lte':
        return '<=';
      default:
        return conditionType;
    }
  }
}

/// 设备完整配置
class DeviceConfig {
  final List<SensorConfig> sensors;
  final List<ControlConfig> controls;
  final List<ActionConfig> actions;
  final List<ThresholdConfig> thresholds;

  DeviceConfig({
    this.sensors = const [],
    this.controls = const [],
    this.actions = const [],
    this.thresholds = const [],
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    return DeviceConfig(
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((e) => SensorConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      controls: (json['controls'] as List<dynamic>?)
              ?.map((e) => ControlConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => ActionConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      thresholds: (json['thresholds'] as List<dynamic>?)
              ?.map((e) => ThresholdConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 获取启用的传感器
  List<SensorConfig> get enabledSensors =>
      sensors.where((s) => s.isEnabled).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  /// 获取启用的控制
  List<ControlConfig> get enabledControls =>
      controls.where((c) => c.isEnabled).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  /// 获取启用的操作
  List<ActionConfig> get enabledActions =>
      actions.where((a) => a.isEnabled).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  /// 获取启用的阈值
  List<ThresholdConfig> get enabledThresholds =>
      thresholds.where((t) => t.isEnabled).toList();
}
