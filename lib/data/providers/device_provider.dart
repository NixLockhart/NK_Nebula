import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/websocket_client.dart';
import '../../core/protocol/app_message.dart';
import '../../core/protocol/message_types.dart';
import '../models/models.dart';
import 'auth_provider.dart';

/// 设备列表状态
class DevicesState {
  final List<Device> devices;
  final bool isLoading;
  final String? error;

  const DevicesState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
  });

  DevicesState copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
  }) {
    return DevicesState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 设备列表 Notifier
class DevicesNotifier extends StateNotifier<DevicesState> {
  final WebSocketClient _client;
  final Ref _ref;
  StreamSubscription? _messageSubscription;

  DevicesNotifier(this._client, this._ref) : super(const DevicesState()) {
    _listenToMessages();
  }

  void _listenToMessages() {
    _messageSubscription = _client.messageStream.listen(_onMessage);
  }

  void _onMessage(AppMessage message) {
    // 处理设备状态变更消息
    if (message.type == MessageType.deviceStatus) {
      final deviceId = message.deviceId;
      final status = message.payload['status'] as String?;

      if (deviceId != null && status != null) {
        final devices = state.devices.map((d) {
          if (d.deviceId == deviceId) {
            return d.copyWith(status: status);
          }
          return d;
        }).toList();
        state = state.copyWith(devices: devices);
      }
    }
    // 当收到实时数据时，也标记设备为在线状态
    else if (message.type == MessageType.dataRealtime) {
      final deviceId = message.deviceId;
      if (deviceId != null) {
        final devices = state.devices.map((d) {
          if (d.deviceId == deviceId && d.status != 'online') {
            return d.copyWith(status: 'online');
          }
          return d;
        }).toList();
        // 只有状态真正变化时才更新
        if (devices.any((d) => d.deviceId == deviceId && d.status == 'online' &&
            state.devices.firstWhere((od) => od.deviceId == deviceId, orElse: () => d).status != 'online')) {
          state = state.copyWith(devices: devices);
        }
      }
    }
  }

  /// 加载设备列表
  Future<void> loadDevices() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final message = MessageFactory.createDeviceList(user.userId);
      final response = await _client.send(message);

      if (response.isSuccess) {
        // 服务器返回格式: payload.data.devices
        final data = response.payload['data'] as Map<String, dynamic>? ?? {};
        final devicesList = data['devices'] as List<dynamic>? ?? [];
        final devices = devicesList
            .map((d) => Device.fromJson(d as Map<String, dynamic>))
            .toList();
        state = DevicesState(devices: devices);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage ?? '加载设备列表失败',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 重命名设备
  Future<bool> renameDevice(String deviceId, String newName) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message =
          MessageFactory.createDeviceRename(user.userId, deviceId, newName);
      final response = await _client.send(message);

      if (response.isSuccess) {
        final devices = state.devices.map((d) {
          if (d.deviceId == deviceId) {
            return d.copyWith(name: newName);
          }
          return d;
        }).toList();
        state = state.copyWith(devices: devices);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 解绑设备
  Future<bool> unbindDevice(String deviceId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      final message = MessageFactory.createDeviceUnbind(user.userId, deviceId);
      final response = await _client.send(message);

      if (response.isSuccess) {
        final devices =
            state.devices.where((d) => d.deviceId != deviceId).toList();
        state = state.copyWith(devices: devices);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}

/// 设备列表 Provider
final devicesProvider =
    StateNotifierProvider<DevicesNotifier, DevicesState>((ref) {
  // 使用 ref.read 而不是 ref.watch，避免 Provider 被重建导致状态丢失
  final client = ref.read(wsClientProvider);
  return DevicesNotifier(client, ref);
});

/// 当前选中设备 Provider
final selectedDeviceIdProvider = StateProvider<String?>((ref) => null);

/// 当前选中设备 Provider
final selectedDeviceProvider = Provider<Device?>((ref) {
  final deviceId = ref.watch(selectedDeviceIdProvider);
  final devices = ref.watch(devicesProvider).devices;

  if (deviceId == null) return devices.isNotEmpty ? devices.first : null;
  return devices.firstWhere(
    (d) => d.deviceId == deviceId,
    orElse: () => devices.isNotEmpty ? devices.first : Device(deviceId: '', name: ''),
  );
});
