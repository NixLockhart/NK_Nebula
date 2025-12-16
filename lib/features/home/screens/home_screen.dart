import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 加载设备列表
    Future.microtask(() {
      ref.read(devicesProvider.notifier).loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final devicesState = ref.watch(devicesProvider);
    final selectedDevice = ref.watch(selectedDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_florist),
            const SizedBox(width: 8),
            Text(selectedDevice?.name ?? '我的设备'),
            const SizedBox(width: 4),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                padding: EdgeInsets.zero,
                tooltip: '刷新设备',
                onPressed: () {
                  ref.read(devicesProvider.notifier).loadDevices();
                  final deviceId = selectedDevice?.deviceId;
                  if (deviceId != null) {
                    ref.read(deviceConfigProvider.notifier).loadConfig(deviceId);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          // 设备选择
          if (devicesState.devices.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.devices),
              onSelected: (deviceId) {
                ref.read(selectedDeviceIdProvider.notifier).state = deviceId;
                _loadDeviceData(deviceId);
              },
              itemBuilder: (context) {
                return devicesState.devices.map((device) {
                  return PopupMenuItem(
                    value: device.deviceId,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: device.isOnline ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(device.name),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          // 设置
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '仪表盘',
          ),
          NavigationDestination(
            icon: Icon(Icons.toggle_off_outlined),
            selectedIcon: Icon(Icons.toggle_on),
            label: '控制',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: '配置',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final selectedDevice = ref.watch(selectedDeviceProvider);

    if (selectedDevice == null || selectedDevice.deviceId.isEmpty) {
      return _buildNoDeviceView();
    }

    switch (_currentIndex) {
      case 0:
        return DashboardView(deviceId: selectedDevice.deviceId);
      case 1:
        return ControlView(deviceId: selectedDevice.deviceId);
      case 2:
        return HistoryView(deviceId: selectedDevice.deviceId);
      case 3:
        return ConfigView(deviceId: selectedDevice.deviceId);
      default:
        return const SizedBox();
    }
  }

  Widget _buildNoDeviceView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无设备',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请在开发板上配置并绑定设备',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () {
              ref.read(devicesProvider.notifier).loadDevices();
            },
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }

  void _loadDeviceData(String deviceId) {
    ref.read(deviceConfigProvider.notifier).loadConfig(deviceId);
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(ref.read(currentUserProvider)?.username ?? ''),
                subtitle: const Text('当前账号'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('刷新设备'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(devicesProvider.notifier).loadDevices();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// 仪表盘视图
class DashboardView extends ConsumerStatefulWidget {
  final String deviceId;

  const DashboardView({super.key, required this.deviceId});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 延迟执行，避免在 widget 生命周期内修改 provider
    Future.microtask(() => _loadConfig());
  }

  @override
  void didUpdateWidget(DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      // 同样延迟执行
      Future.microtask(() => _loadConfig());
    }
  }

  void _loadConfig() {
    ref.read(deviceConfigProvider.notifier).loadConfig(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(deviceConfigProvider);
    final realtimeData = ref.watch(realtimeDataProvider);
    final device = ref.watch(selectedDeviceProvider);

    if (configState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = configState.config;
    final sensors = config?.enabledSensors ?? [];

    return RefreshIndicator(
      onRefresh: () async => _loadConfig(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 设备状态卡片
          _buildStatusCard(device),
          const SizedBox(height: 16),

          // 传感器网格
          if (sensors.isNotEmpty) ...[
            Text(
              '环境监测',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                final value = realtimeData.sensorData?[sensor.fieldKey];
                return _SensorCard(sensor: sensor, value: value);
              },
            ),
          ] else
            _buildEmptyConfigCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Device? device) {
    final isOnline = device?.isOnline ?? false;
    final realtimeData = ref.watch(realtimeDataProvider);
    final status = realtimeData.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOnline
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? '设备在线' : '设备离线',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status != null
                        ? (status.isAutoMode ? '自动模式' : '手动模式')
                        : '等待数据...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (realtimeData.lastUpdate != null)
              Text(
                _formatTime(realtimeData.lastUpdate!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.settings_suggest, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无传感器配置',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 传感器卡片
class _SensorCard extends StatelessWidget {
  final SensorConfig sensor;
  final dynamic value;

  const _SensorCard({required this.sensor, this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.toString() ?? '--';
    final iconData = _getIconData(sensor.icon);
    final color = _getColor(sensor.fieldKey);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(iconData, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  sensor.fieldName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (sensor.unit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      sensor.unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon.toLowerCase()) {
      case 'thermostat':
      case 'temp':
        return Icons.thermostat;
      case 'water_drop':
      case 'humi':
        return Icons.water_drop;
      case 'grass':
      case 'soil':
        return Icons.grass;
      case 'light_mode':
      case 'light':
        return Icons.light_mode;
      default:
        return Icons.sensors;
    }
  }

  Color _getColor(String key) {
    switch (key.toLowerCase()) {
      case 'temp':
        return Colors.orange;
      case 'humi':
        return Colors.blue;
      case 'soil':
        return Colors.brown;
      case 'light':
        return Colors.amber;
      default:
        return Colors.teal;
    }
  }
}

/// 控制视图
class ControlView extends ConsumerWidget {
  final String deviceId;

  const ControlView({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(deviceConfigProvider);
    final realtimeData = ref.watch(realtimeDataProvider);

    final config = configState.config;
    final controls = config?.enabledControls ?? [];
    final actions = config?.enabledActions ?? [];
    final status = realtimeData.status;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 模式切换
        _ModeSwitch(status: status, deviceId: deviceId),
        const SizedBox(height: 24),

        // 开关控制
        if (controls.isNotEmpty) ...[
          Text(
            '设备控制',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...controls.map((control) {
            final isOn = status?.isOn(control.controlKey) ?? false;
            final enabled = status?.isManualMode ?? false;
            return _ControlTile(
              control: control,
              isOn: isOn,
              enabled: enabled,
              deviceId: deviceId,
            );
          }),
        ],

        const SizedBox(height: 24),

        // 功能操作
        if (actions.isNotEmpty) ...[
          Text(
            '功能操作',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return _ActionButton(action: action, deviceId: deviceId);
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// 模式切换
class _ModeSwitch extends ConsumerWidget {
  final DeviceStatus? status;
  final String deviceId;

  const _ModeSwitch({this.status, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAutoMode = status?.isAutoMode ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_mode),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '运行模式',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isAutoMode ? '自动控制' : '手动控制',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('自动')),
                  ButtonSegment(value: false, label: Text('手动')),
                ],
                selected: {isAutoMode},
                onSelectionChanged: (selected) async {
                  final newMode = selected.first;
                  final success = await sendModeCommand(ref, deviceId, newMode);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('模式切换失败')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 控制项
class _ControlTile extends ConsumerWidget {
  final ControlConfig control;
  final bool isOn;
  final bool enabled;
  final String deviceId;

  const _ControlTile({
    required this.control,
    required this.isOn,
    required this.enabled,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getIconData(control.icon),
          color: isOn ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(control.controlName),
        subtitle: Text(isOn ? '已开启' : '已关闭'),
        trailing: Switch(
          value: isOn,
          onChanged: enabled
              ? (value) async {
                  final success = await sendControlCommand(
                    ref,
                    deviceId,
                    control.controlKey,
                    value,
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('命令发送失败')),
                    );
                  }
                }
              : null,
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon.toLowerCase()) {
      case 'water':
      case 'water_drop':
        return Icons.water_drop;
      case 'fan':
      case 'air':
        return Icons.air;
      case 'light':
      case 'lightbulb':
        return Icons.lightbulb;
      case 'heat':
      case 'whatshot':
        return Icons.whatshot;
      default:
        return Icons.power_settings_new;
    }
  }
}

/// 操作按钮
class _ActionButton extends ConsumerWidget {
  final ActionConfig action;
  final String deviceId;

  const _ActionButton({required this.action, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonal(
      onPressed: () async {
        final success = await sendActionCommand(
          ref,
          deviceId,
          action.actionKey,
        );
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作执行失败')),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${action.actionName} 已执行')),
          );
        }
      },
      child: Text(action.actionName),
    );
  }
}

/// 历史数据视图
class HistoryView extends ConsumerStatefulWidget {
  final String deviceId;

  const HistoryView({super.key, required this.deviceId});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  String _selectedField = 'temp';
  String _selectedInterval = '30s';
  String _selectedRange = '24h';

  final Map<String, String> _intervalLabels = {
    '30s': '原始',
    '1m': '1分钟',
    '5m': '5分钟',
    '15m': '15分钟',
    '1h': '1小时',
  };

  final Map<String, Duration> _rangeOptions = {
    '1h': Duration(hours: 1),
    '6h': Duration(hours: 6),
    '24h': Duration(hours: 24),
    '7d': Duration(days: 7),
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  @override
  void didUpdateWidget(HistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      Future.microtask(() => _loadData());
    }
  }

  void _loadData() {
    final range = _rangeOptions[_selectedRange] ?? const Duration(hours: 24);
    final now = DateTime.now();
    final start = now.subtract(range);

    ref.read(historyDataProvider.notifier).loadHistory(
          deviceId: widget.deviceId,
          startTime: start,
          endTime: now,
          interval: _selectedInterval,
        );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyDataProvider);
    final configState = ref.watch(deviceConfigProvider);
    final sensors = configState.config?.enabledSensors ?? [];

    // 如果有传感器配置且当前选择的字段不在列表中，选择第一个
    if (sensors.isNotEmpty &&
        !sensors.any((s) => s.fieldKey == _selectedField)) {
      _selectedField = sensors.first.fieldKey;
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 时间范围选择
          _buildRangeSelector(),
          const SizedBox(height: 12),

          // 时间间隔选择
          _buildIntervalSelector(),
          const SizedBox(height: 12),

          // 传感器字段选择
          if (sensors.isNotEmpty) ...[
            _buildFieldSelector(sensors),
            const SizedBox(height: 16),
          ],

          // 图表
          _buildChart(historyState, sensors),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                const Text('时间范围'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '1h', label: Text('1h')),
                  ButtonSegment(value: '6h', label: Text('6h')),
                  ButtonSegment(value: '24h', label: Text('24h')),
                  ButtonSegment(value: '7d', label: Text('7d')),
                ],
                selected: {_selectedRange},
                onSelectionChanged: (selected) {
                  setState(() => _selectedRange = selected.first);
                  _loadData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.timer, size: 20),
            const SizedBox(width: 8),
            const Text('采样间隔'),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedInterval,
              underline: const SizedBox(),
              items: _intervalLabels.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedInterval = value);
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldSelector(List<SensorConfig> sensors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.sensors, size: 20),
            const SizedBox(width: 8),
            const Text('数据类型'),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedField,
              underline: const SizedBox(),
              items: sensors.map((s) {
                return DropdownMenuItem(
                  value: s.fieldKey,
                  child: Text('${s.fieldName} (${s.unit})'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedField = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(HistoryDataState state, List<SensorConfig> sensors) {
    if (state.isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 8),
              Text(state.error!, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadData,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.records.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('暂无历史数据', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    // 获取当前传感器配置
    final sensor = sensors.firstWhere(
      (s) => s.fieldKey == _selectedField,
      orElse: () => SensorConfig(
        fieldKey: _selectedField,
        fieldName: _selectedField,
        unit: '',
      ),
    );

    // 准备图表数据
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < state.records.length; i++) {
      final record = state.records[i];
      final value = record.getValue(_selectedField);
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
        if (value < minY) minY = value;
        if (value > maxY) maxY = value;
      }
    }

    if (spots.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text('所选字段无数据', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    // 添加 Y 轴边距
    final yMargin = (maxY - minY) * 0.1;
    minY = minY - yMargin;
    maxY = maxY + yMargin;
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconForField(_selectedField),
                    color: _getColorForField(_selectedField)),
                const SizedBox(width: 8),
                Text(
                  '${sensor.fieldName}变化趋势',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (state.records.length / 4).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= state.records.length) {
                            return const SizedBox();
                          }
                          final time = state.records[index].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('HH:mm').format(time),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (state.records.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: _getColorForField(_selectedField),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _getColorForField(_selectedField)
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final time = state.records[index].timestamp;
                          return LineTooltipItem(
                            '${DateFormat('MM/dd HH:mm').format(time)}\n${spot.y.toStringAsFixed(1)} ${sensor.unit}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${state.records.length} 条数据',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForField(String field) {
    switch (field.toLowerCase()) {
      case 'temp':
        return Icons.thermostat;
      case 'humi':
        return Icons.water_drop;
      case 'soil':
        return Icons.grass;
      case 'light':
        return Icons.light_mode;
      default:
        return Icons.sensors;
    }
  }

  Color _getColorForField(String field) {
    switch (field.toLowerCase()) {
      case 'temp':
        return Colors.orange;
      case 'humi':
        return Colors.blue;
      case 'soil':
        return Colors.brown;
      case 'light':
        return Colors.amber;
      default:
        return Colors.teal;
    }
  }
}

/// 配置管理视图
class ConfigView extends ConsumerStatefulWidget {
  final String deviceId;

  const ConfigView({super.key, required this.deviceId});

  @override
  ConsumerState<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends ConsumerState<ConfigView> {
  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(deviceConfigProvider);
    final config = configState.config;

    if (configState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 传感器配置
        _buildSectionHeader(context, '传感器配置', Icons.sensors,
          onAdd: () => _showAddSensorDialog(context)),
        const SizedBox(height: 8),
        _buildSensorList(config?.sensors ?? []),

        const SizedBox(height: 24),

        // 控制配置 (开关类)
        _buildSectionHeader(context, '开关控制', Icons.toggle_on,
          onAdd: () => _showAddControlDialog(context)),
        const SizedBox(height: 8),
        _buildControlList(config?.controls ?? []),

        const SizedBox(height: 24),

        // 操作配置 (执行类)
        _buildSectionHeader(context, '执行操作', Icons.touch_app,
          onAdd: () => _showAddActionDialog(context)),
        const SizedBox(height: 8),
        _buildActionList(config?.actions ?? []),

        const SizedBox(height: 24),

        // 阈值配置 (待开发)
        _buildSectionHeader(context, '阈值规则', Icons.rule),
        const SizedBox(height: 8),
        _buildComingSoonCard('阈值规则功能正在开发中'),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {VoidCallback? onAdd}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAdd,
            tooltip: '添加',
          ),
      ],
    );
  }

  Widget _buildComingSoonCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.construction, size: 40, color: Colors.orange[400]),
              const SizedBox(height: 8),
              Text('待开发', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThresholdList(List<ThresholdConfig> thresholds) {
    if (thresholds.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.rule, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('暂无阈值规则', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  '阈值规则可实现传感器数据触发自动控制',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: thresholds.map((threshold) {
        return _ThresholdCard(
          threshold: threshold,
          deviceId: widget.deviceId,
          onDelete: () => _deleteThreshold(threshold.id!),
        );
      }).toList(),
    );
  }

  Widget _buildAddThresholdButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showAddThresholdDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('添加阈值规则'),
    );
  }

  Widget _buildSensorList(List<SensorConfig> sensors) {
    if (sensors.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.sensors, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('暂无传感器配置', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  '添加传感器后可在仪表盘显示数据',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: sensors.map((sensor) {
          return ListTile(
            leading: Icon(_getSensorIcon(sensor.icon)),
            title: Text(sensor.fieldName),
            subtitle: Text('键值: ${sensor.fieldKey}  单位: ${sensor.unit.isEmpty ? "无" : sensor.unit}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteSensor(sensor.fieldKey),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControlList(List<ControlConfig> controls) {
    if (controls.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.toggle_on, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('暂无开关控制', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  '开关控制用于控制设备的开/关状态',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: controls.map((control) {
          return ListTile(
            leading: Icon(_getControlIcon(control.icon)),
            title: Text(control.controlName),
            subtitle: Text('键值: ${control.controlKey}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteControl(control.controlKey),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionList(List<ActionConfig> actions) {
    if (actions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.touch_app, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('暂无执行操作', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  '执行操作用于触发一次性动作',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: actions.map((action) {
          return ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(action.actionName),
            subtitle: Text('键值: ${action.actionKey}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteAction(action.actionKey),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddThresholdDialog(BuildContext context) {
    final configState = ref.read(deviceConfigProvider);
    final sensors = configState.config?.enabledSensors ?? [];
    final controls = configState.config?.enabledControls ?? [];

    if (sensors.isEmpty || controls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要先配置传感器和控制项')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddThresholdDialog(
        deviceId: widget.deviceId,
        sensors: sensors,
        controls: controls,
      ),
    );
  }

  Future<void> _deleteThreshold(int thresholdId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除阈值规则'),
        content: const Text('确定要删除这条阈值规则吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(deviceConfigProvider.notifier)
          .deleteThreshold(widget.deviceId, thresholdId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? '删除成功' : '删除失败')),
        );
      }
    }
  }

  IconData _getSensorIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'thermostat':
      case 'temp':
        return Icons.thermostat;
      case 'water_drop':
      case 'humi':
        return Icons.water_drop;
      case 'grass':
      case 'soil':
        return Icons.grass;
      case 'light_mode':
      case 'light':
        return Icons.light_mode;
      default:
        return Icons.sensors;
    }
  }

  IconData _getControlIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'water':
      case 'water_drop':
        return Icons.water_drop;
      case 'fan':
      case 'air':
        return Icons.air;
      case 'light':
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.power_settings_new;
    }
  }

  // ========== 添加对话框方法 ==========

  void _showAddSensorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddSensorDialog(deviceId: widget.deviceId),
    );
  }

  void _showAddControlDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddControlDialog(deviceId: widget.deviceId),
    );
  }

  void _showAddActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddActionDialog(deviceId: widget.deviceId),
    );
  }

  // ========== 删除方法 ==========

  Future<void> _deleteSensor(String key) async {
    final confirmed = await _showDeleteConfirmDialog('传感器');
    if (confirmed == true) {
      final success = await ref
          .read(deviceConfigProvider.notifier)
          .deleteSensor(widget.deviceId, key);
      _showResultSnackBar(success);
    }
  }

  Future<void> _deleteControl(String key) async {
    final confirmed = await _showDeleteConfirmDialog('开关控制');
    if (confirmed == true) {
      final success = await ref
          .read(deviceConfigProvider.notifier)
          .deleteControl(widget.deviceId, key);
      _showResultSnackBar(success);
    }
  }

  Future<void> _deleteAction(String key) async {
    final confirmed = await _showDeleteConfirmDialog('执行操作');
    if (confirmed == true) {
      final success = await ref
          .read(deviceConfigProvider.notifier)
          .deleteAction(widget.deviceId, key);
      _showResultSnackBar(success);
    }
  }

  Future<bool?> _showDeleteConfirmDialog(String itemType) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除$itemType'),
        content: Text('确定要删除这个$itemType吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showResultSnackBar(bool success) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '删除成功' : '删除失败')),
      );
    }
  }
}

/// 阈值卡片
class _ThresholdCard extends StatelessWidget {
  final ThresholdConfig threshold;
  final String deviceId;
  final VoidCallback onDelete;

  const _ThresholdCard({
    required this.threshold,
    required this.deviceId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.rule),
        ),
        title: Text(
          '${threshold.sensorKey} ${threshold.conditionDisplay} ${threshold.thresholdValue}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '触发 ${threshold.controlKey} ${threshold.triggerAction == "on" ? "开启" : "关闭"}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

/// 添加阈值对话框
class _AddThresholdDialog extends ConsumerStatefulWidget {
  final String deviceId;
  final List<SensorConfig> sensors;
  final List<ControlConfig> controls;

  const _AddThresholdDialog({
    required this.deviceId,
    required this.sensors,
    required this.controls,
  });

  @override
  ConsumerState<_AddThresholdDialog> createState() =>
      _AddThresholdDialogState();
}

class _AddThresholdDialogState extends ConsumerState<_AddThresholdDialog> {
  late String _selectedSensor;
  late String _selectedControl;
  String _selectedCondition = 'lt';
  String _selectedAction = 'on';
  final _valueController = TextEditingController();
  bool _isLoading = false;

  final Map<String, String> _conditionLabels = {
    'gt': '大于 (>)',
    'lt': '小于 (<)',
    'gte': '大于等于 (>=)',
    'lte': '小于等于 (<=)',
    'eq': '等于 (=)',
  };

  @override
  void initState() {
    super.initState();
    _selectedSensor = widget.sensors.first.fieldKey;
    _selectedControl = widget.controls.first.controlKey;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加阈值规则'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 传感器选择
            const Text('当传感器'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSensor,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.sensors.map((s) {
                return DropdownMenuItem(
                  value: s.fieldKey,
                  child: Text('${s.fieldName} (${s.fieldKey})'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedSensor = value);
              },
            ),

            const SizedBox(height: 16),

            // 条件选择
            const Text('满足条件'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCondition,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _conditionLabels.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCondition = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '阈值',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 触发动作
            const Text('触发动作'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedControl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.controls.map((c) {
                return DropdownMenuItem(
                  value: c.controlKey,
                  child: Text(c.controlName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedControl = value);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'on', label: Text('开启')),
                  ButtonSegment(value: 'off', label: Text('关闭')),
                ],
                selected: {_selectedAction},
                onSelectionChanged: (selected) {
                  setState(() => _selectedAction = selected.first);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入阈值')),
      );
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效数字')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(deviceConfigProvider.notifier).addThreshold(
          deviceId: widget.deviceId,
          sensorKey: _selectedSensor,
          controlKey: _selectedControl,
          condition: _selectedCondition,
          value: value,
          action: _selectedAction,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('阈值规则添加成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加失败')),
        );
      }
    }
  }
}

/// 添加传感器对话框
class _AddSensorDialog extends ConsumerStatefulWidget {
  final String deviceId;

  const _AddSensorDialog({required this.deviceId});

  @override
  ConsumerState<_AddSensorDialog> createState() => _AddSensorDialogState();
}

class _AddSensorDialogState extends ConsumerState<_AddSensorDialog> {
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  String _selectedIcon = 'sensors';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'value': 'sensors', 'icon': Icons.sensors, 'label': '通用'},
    {'value': 'thermostat', 'icon': Icons.thermostat, 'label': '温度'},
    {'value': 'water_drop', 'icon': Icons.water_drop, 'label': '湿度'},
    {'value': 'grass', 'icon': Icons.grass, 'label': '土壤'},
    {'value': 'light_mode', 'icon': Icons.light_mode, 'label': '光照'},
    {'value': 'air', 'icon': Icons.air, 'label': '气体'},
    {'value': 'speed', 'icon': Icons.speed, 'label': '速度'},
    {'value': 'bolt', 'icon': Icons.bolt, 'label': '电量'},
  ];

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加传感器'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('键值 (用于匹配开发板数据)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: gas, pressure',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('显示名称'),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: 气体浓度',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('单位 (可选)'),
            const SizedBox(height: 4),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: %, ppm, °C',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('图标'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((opt) {
                final isSelected = _selectedIcon == opt['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(opt['icon'] as IconData, size: 18),
                      const SizedBox(width: 4),
                      Text(opt['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedIcon = opt['value'] as String);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final key = _keyController.text.trim();
    final name = _nameController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入键值')));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入显示名称')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(deviceConfigProvider.notifier).addSensor(
          deviceId: widget.deviceId,
          key: key,
          name: name,
          unit: _unitController.text.trim(),
          icon: _selectedIcon,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('传感器添加成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加失败')));
      }
    }
  }
}

/// 添加开关控制对话框
class _AddControlDialog extends ConsumerStatefulWidget {
  final String deviceId;

  const _AddControlDialog({required this.deviceId});

  @override
  ConsumerState<_AddControlDialog> createState() => _AddControlDialogState();
}

class _AddControlDialogState extends ConsumerState<_AddControlDialog> {
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedIcon = 'power_settings_new';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'value': 'power_settings_new', 'icon': Icons.power_settings_new, 'label': '开关'},
    {'value': 'water_drop', 'icon': Icons.water_drop, 'label': '水泵'},
    {'value': 'air', 'icon': Icons.air, 'label': '风扇'},
    {'value': 'lightbulb', 'icon': Icons.lightbulb, 'label': '灯光'},
    {'value': 'bluetooth', 'icon': Icons.bluetooth, 'label': '蓝牙'},
    {'value': 'wifi', 'icon': Icons.wifi, 'label': 'WiFi'},
    {'value': 'whatshot', 'icon': Icons.whatshot, 'label': '加热'},
    {'value': 'ac_unit', 'icon': Icons.ac_unit, 'label': '制冷'},
  ];

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加开关控制'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('键值 (发送给开发板的标识)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: bluetooth, heater',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('显示名称'),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: 蓝牙开关',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('图标'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((opt) {
                final isSelected = _selectedIcon == opt['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(opt['icon'] as IconData, size: 18),
                      const SizedBox(width: 4),
                      Text(opt['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedIcon = opt['value'] as String);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '开关控制会发送 on/off 状态给开发板，请在开发板代码中处理该键值',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final key = _keyController.text.trim();
    final name = _nameController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入键值')));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入显示名称')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(deviceConfigProvider.notifier).addControl(
          deviceId: widget.deviceId,
          key: key,
          name: name,
          cmdOn: '${key}_on',
          cmdOff: '${key}_off',
          icon: _selectedIcon,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('开关控制添加成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加失败')));
      }
    }
  }
}

/// 添加执行操作对话框
class _AddActionDialog extends ConsumerStatefulWidget {
  final String deviceId;

  const _AddActionDialog({required this.deviceId});

  @override
  ConsumerState<_AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends ConsumerState<_AddActionDialog> {
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加执行操作'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('键值 (发送给开发板的标识)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: calibrate, reset',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text('显示名称'),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: 传感器校准',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '执行操作是一次性触发，点击后会发送该键值给开发板',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final key = _keyController.text.trim();
    final name = _nameController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入键值')));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入显示名称')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(deviceConfigProvider.notifier).addAction(
          deviceId: widget.deviceId,
          key: key,
          name: name,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('执行操作添加成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加失败')));
      }
    }
  }
}