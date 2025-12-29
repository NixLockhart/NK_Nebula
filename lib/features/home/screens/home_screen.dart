import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // 加载设备列表
    Future.microtask(() {
      ref.read(devicesProvider.notifier).loadDevices();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: AppTheme.animationNormal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesState = ref.watch(devicesProvider);
    final selectedDevice = ref.watch(selectedDeviceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(selectedDevice, devicesState, colorScheme),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildPageContent(0, selectedDevice),
          _buildPageContent(1, selectedDevice),
          _buildPageContent(2, selectedDevice),
          _buildPageContent(3, selectedDevice),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(colorScheme),
    );
  }

  Widget _buildPageContent(int index, Device? device) {
    if (device == null || device.deviceId.isEmpty) {
      return _buildNoDeviceView();
    }

    switch (index) {
      case 0:
        return DashboardView(deviceId: device.deviceId);
      case 1:
        return ControlView(deviceId: device.deviceId);
      case 2:
        return HistoryView(deviceId: device.deviceId);
      case 3:
        return ConfigView(deviceId: device.deviceId);
      default:
        return const SizedBox();
    }
  }

  PreferredSizeWidget _buildAppBar(
      Device? selectedDevice,
      DevicesState devicesState,
      ColorScheme colorScheme,
      ) {
    final hasMultipleDevices = devicesState.devices.length > 1;

    return AppBar(
      title: _buildDeviceSelector(
        selectedDevice,
        devicesState,
        colorScheme,
        hasMultipleDevices,
      ),
      actions: [
        // 刷新按钮
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: '刷新',
          onPressed: () {
            ref.read(devicesProvider.notifier).loadDevices();
            final deviceId = selectedDevice?.deviceId;
            if (deviceId != null) {
              ref.read(deviceConfigProvider.notifier).loadConfig(deviceId);
            }
          },
        ),
        // 设置
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: '设置',
          onPressed: () => _showSettingsSheet(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// 构建设备选择器（左上角）
  Widget _buildDeviceSelector(
      Device? selectedDevice,
      DevicesState devicesState,
      ColorScheme colorScheme,
      bool hasMultipleDevices,
      ) {
    final deviceInfoWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset('icon.png', width: 28, height: 28),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      selectedDevice?.name ?? '我的设备',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasMultipleDevices) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              if (selectedDevice != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusIndicator(
                      isActive: selectedDevice.isOnline,
                      size: 8,
                      animate: true,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedDevice.isOnline ? '在线' : '离线',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasMultipleDevices) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${devicesState.devices.length}台设备',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );

    // 如果只有一个设备，直接显示设备信息
    if (!hasMultipleDevices) {
      return deviceInfoWidget;
    }

    // 多个设备时，点击显示下拉菜单
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      onSelected: (deviceId) {
        ref.read(selectedDeviceIdProvider.notifier).state = deviceId;
        ref.read(deviceConfigProvider.notifier).loadConfig(deviceId);
      },
      itemBuilder: (context) {
        return devicesState.devices.map((device) {
          final isSelected = device.deviceId == selectedDevice?.deviceId;
          return PopupMenuItem<String>(
            value: device.deviceId,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      size: 18,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            StatusIndicator(
                              isActive: device.isOnline,
                              size: 6,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              device.isOnline ? '在线' : '离线',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              device.deviceId,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: colorScheme.primary, size: 20),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: deviceInfoWidget,
    );
  }

  Widget _buildBottomNav(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, '仪表盘'),
              _buildNavItem(1, Icons.toggle_off_outlined, Icons.toggle_on_rounded, '控制'),
              _buildNavItem(2, Icons.show_chart_outlined, Icons.show_chart_rounded, '历史'),
              _buildNavItem(3, Icons.tune_outlined, Icons.tune_rounded, '配置'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _onNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppTheme.animationFast,
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDeviceView() {
    return EmptyStateWidget(
      icon: Icons.devices_other_rounded,
      title: '暂无设备',
      subtitle: '请在设备端配置并绑定设备',
      action: FilledButton.tonal(
        onPressed: () {
          ref.read(devicesProvider.notifier).loadDevices();
        },
        child: const Text('刷新'),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final username = ref.read(currentUserProvider)?.username ?? '未知用户';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.person, color: colorScheme.primary),
                  ),
                  title: Text(username),
                  subtitle: const Text('当前账号'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                  title: const Text('刷新设备'),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(devicesProvider.notifier).loadDevices();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('退出登录', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).logout();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
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
    Future.microtask(() => _loadConfig());
  }

  @override
  void didUpdateWidget(DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
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
          FadeInWidget(
            child: _StatusCard(device: device, realtimeData: realtimeData),
          ),
          const SizedBox(height: 20),

          // 传感器网格
          if (sensors.isNotEmpty) ...[
            FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: _SectionHeader(
                title: '环境监测',
                icon: Icons.sensors_rounded,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                final value = realtimeData.sensorData?[sensor.fieldKey];
                return FadeInWidget(
                  delay: Duration(milliseconds: 150 + index * 50),
                  child: _SensorCard(sensor: sensor, value: value),
                );
              },
            ),
          ] else
            FadeInWidget(
              child: EmptyStateWidget(
                icon: Icons.sensors_rounded,
                title: '暂无传感器配置',
                subtitle: '前往配置页面添加传感器',
              ),
            ),
        ],
      ),
    );
  }
}

/// 状态卡片
class _StatusCard extends StatelessWidget {
  final Device? device;
  final RealtimeDataState realtimeData;

  const _StatusCard({this.device, required this.realtimeData});

  @override
  Widget build(BuildContext context) {
    final isOnline = device?.isOnline ?? false;
    final status = realtimeData.status;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isOnline
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withOpacity(0.3), AppColors.primaryDark.withOpacity(0.2)]
              : [AppColors.primaryPale.withOpacity(0.5), AppColors.primarySoft.withOpacity(0.3)],
        )
            : null,
        color: isOnline ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isOnline
              ? AppColors.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.primary.withOpacity(isDark ? 0.3 : 0.15)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: isOnline ? AppColors.primary : colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? '设备在线' : '设备离线',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (status?.isAutoMode ?? true)
                            ? AppColors.info.withOpacity(0.15)
                            : AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status != null
                            ? (status.isAutoMode ? '自动模式' : '手动模式')
                            : '等待数据...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: status != null
                              ? (status.isAutoMode ? AppColors.info : AppColors.warning)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (realtimeData.lastUpdate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 2),
                Text(
                  _formatTime(realtimeData.lastUpdate!),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
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

/// 分区标题
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
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
    final color = AppColors.getSensorColor(sensor.fieldKey);
    final lightColor = AppColors.getSensorLightColor(sensor.fieldKey);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleOnTap(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? color.withOpacity(0.2) : lightColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sensor.fieldName,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (value != null)
                  AnimatedNumber(
                    value: value is num ? value : 0,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    ),
                  )
                else
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
                  ),
                if (sensor.unit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      sensor.unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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
        return Icons.thermostat_rounded;
      case 'water_drop':
      case 'humi':
        return Icons.water_drop_rounded;
      case 'grass':
      case 'soil':
        return Icons.grass_rounded;
      case 'light_mode':
      case 'light':
        return Icons.light_mode_rounded;
      default:
        return Icons.sensors_rounded;
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
        FadeInWidget(
          child: _ModeSwitch(status: status, deviceId: deviceId),
        ),
        const SizedBox(height: 24),

        // 开关控制
        if (controls.isNotEmpty) ...[
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: _SectionHeader(title: '设备控制', icon: Icons.toggle_on_rounded),
          ),
          const SizedBox(height: 12),
          ...controls.asMap().entries.map((entry) {
            final index = entry.key;
            final control = entry.value;
            final isOn = status?.isOn(control.controlKey) ?? false;
            final enabled = status?.isManualMode ?? false;
            return FadeInWidget(
              delay: Duration(milliseconds: 150 + index * 50),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ControlTile(
                  control: control,
                  isOn: isOn,
                  enabled: enabled,
                  deviceId: deviceId,
                ),
              ),
            );
          }),
        ],

        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: _SectionHeader(title: '功能操作', icon: Icons.touch_app_rounded),
          ),
          const SizedBox(height: 12),
          FadeInWidget(
            delay: const Duration(milliseconds: 250),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions.map((action) {
                return _ActionButton(action: action, deviceId: deviceId);
              }).toList(),
            ),
          ),
        ],

        if (controls.isEmpty && actions.isEmpty)
          EmptyStateWidget(
            icon: Icons.toggle_off_rounded,
            title: '暂无控制配置',
            subtitle: '前往配置页面添加控制项',
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_mode_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '运行模式',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAutoMode ? '系统自动控制设备' : '需要手动控制设备',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text('自动'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.pan_tool_rounded, size: 18),
                  label: Text('手动'),
                ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final color = isOn ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isOn
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: AnimatedContainer(
          duration: AppTheme.animationFast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isOn
                ? colorScheme.primary.withOpacity(0.15)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconData(control.icon), color: color, size: 22),
        ),
        title: Text(
          control.controlName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isOn ? '已开启' : '已关闭',
          style: TextStyle(
            color: isOn ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
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
        return Icons.water_drop_rounded;
      case 'fan':
      case 'air':
        return Icons.air_rounded;
      case 'light':
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'heat':
      case 'whatshot':
        return Icons.whatshot_rounded;
      default:
        return Icons.power_settings_new_rounded;
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
    return ScaleOnTap(
      onTap: () async {
        final success = await sendActionCommand(ref, deviceId, action.actionKey);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '${action.actionName} 已执行' : '操作执行失败'),
            ),
          );
        }
      },
      child: FilledButton.tonal(
        onPressed: () async {
          final success = await sendActionCommand(ref, deviceId, action.actionKey);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? '${action.actionName} 已执行' : '操作执行失败'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(action.actionName),
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
          FadeInWidget(
            child: _buildRangeSelector(colorScheme),
          ),
          const SizedBox(height: 12),

          // 时间间隔和传感器选择
          FadeInWidget(
            delay: const Duration(milliseconds: 50),
            child: Row(
              children: [
                Expanded(child: _buildIntervalSelector(colorScheme)),
                const SizedBox(width: 12),
                if (sensors.isNotEmpty)
                  Expanded(child: _buildFieldSelector(sensors, colorScheme)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 图表
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: _buildChart(historyState, sensors, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('时间范围', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
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
    );
  }

  Widget _buildIntervalSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedInterval,
              underline: const SizedBox(),
              isDense: true,
              isExpanded: true,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSelector(List<SensorConfig> sensors, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors_rounded, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedField,
              underline: const SizedBox(),
              isDense: true,
              isExpanded: true,
              items: sensors.map((s) {
                return DropdownMenuItem(
                  value: s.fieldKey,
                  child: Text(s.fieldName, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedField = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(HistoryDataState state, List<SensorConfig> sensors, ColorScheme colorScheme) {
    if (state.isLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: '加载失败',
          subtitle: state.error,
          action: FilledButton.tonal(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
        ),
      );
    }

    if (state.records.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: const EmptyStateWidget(
          icon: Icons.show_chart_rounded,
          title: '暂无历史数据',
        ),
      );
    }

    final sensor = sensors.firstWhere(
          (s) => s.fieldKey == _selectedField,
      orElse: () => SensorConfig(
        fieldKey: _selectedField,
        fieldName: _selectedField,
        unit: '',
      ),
    );

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
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Center(
          child: Text('所选字段无数据', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ),
      );
    }

    final yMargin = (maxY - minY) * 0.1;
    minY = minY - yMargin;
    maxY = maxY + yMargin;
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    final chartColor = AppColors.getSensorColor(_selectedField);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForField(_selectedField),
                  color: chartColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${sensor.fieldName}变化趋势',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outline.withOpacity(0.15),
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
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
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
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    color: chartColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          chartColor.withOpacity(0.2),
                          chartColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.inverseSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final time = state.records[index].timestamp;
                        return LineTooltipItem(
                          '${DateFormat('MM/dd HH:mm').format(time)}\n${spot.y.toStringAsFixed(1)} ${sensor.unit}',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '共 ${state.records.length} 条数据',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _getIconForField(String field) {
    switch (field.toLowerCase()) {
      case 'temp':
        return Icons.thermostat_rounded;
      case 'humi':
        return Icons.water_drop_rounded;
      case 'soil':
        return Icons.grass_rounded;
      case 'light':
        return Icons.light_mode_rounded;
      default:
        return Icons.sensors_rounded;
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
    final colorScheme = Theme.of(context).colorScheme;

    if (configState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 传感器配置
        FadeInWidget(
          child: _buildConfigSection(
            context,
            title: '传感器配置',
            icon: Icons.sensors_rounded,
            onAdd: () => _showAddSensorDialog(context),
            child: _buildSensorList(config?.sensors ?? [], colorScheme),
          ),
        ),
        const SizedBox(height: 16),

        // 控制配置
        FadeInWidget(
          delay: const Duration(milliseconds: 50),
          child: _buildConfigSection(
            context,
            title: '开关控制',
            icon: Icons.toggle_on_rounded,
            onAdd: () => _showAddControlDialog(context),
            child: _buildControlList(config?.controls ?? [], colorScheme),
          ),
        ),
        const SizedBox(height: 16),

        // 操作配置
        FadeInWidget(
          delay: const Duration(milliseconds: 100),
          child: _buildConfigSection(
            context,
            title: '执行操作',
            icon: Icons.touch_app_rounded,
            onAdd: () => _showAddActionDialog(context),
            child: _buildActionList(config?.actions ?? [], colorScheme),
          ),
        ),
        const SizedBox(height: 16),

        // 阈值配置
        FadeInWidget(
          delay: const Duration(milliseconds: 150),
          child: _buildConfigSection(
            context,
            title: '阈值规则',
            icon: Icons.rule_rounded,
            child: _buildComingSoonCard(colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        VoidCallback? onAdd,
        required Widget child,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                if (onAdd != null)
                  IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary),
                    onPressed: onAdd,
                    tooltip: '添加',
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildComingSoonCard(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Icon(Icons.construction_rounded, size: 36, color: AppColors.warning),
            const SizedBox(height: 8),
            Text(
              '开发中',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '阈值规则功能正在开发中',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorList(List<SensorConfig> sensors, ColorScheme colorScheme) {
    if (sensors.isEmpty) {
      return _buildEmptyList('暂无传感器配置', '添加传感器后可在仪表盘显示数据', colorScheme);
    }

    return Column(
      children: sensors.map((sensor) {
        return _buildConfigItem(
          icon: _getSensorIcon(sensor.icon),
          iconColor: AppColors.getSensorColor(sensor.fieldKey),
          title: sensor.fieldName,
          subtitle: '键值: ${sensor.fieldKey}  单位: ${sensor.unit.isEmpty ? "无" : sensor.unit}',
          onDelete: () => _deleteSensor(sensor.fieldKey),
          colorScheme: colorScheme,
        );
      }).toList(),
    );
  }

  Widget _buildControlList(List<ControlConfig> controls, ColorScheme colorScheme) {
    if (controls.isEmpty) {
      return _buildEmptyList('暂无开关控制', '开关控制用于控制设备的开/关状态', colorScheme);
    }

    return Column(
      children: controls.map((control) {
        return _buildConfigItem(
          icon: _getControlIcon(control.icon),
          iconColor: colorScheme.primary,
          title: control.controlName,
          subtitle: '键值: ${control.controlKey}',
          onDelete: () => _deleteControl(control.controlKey),
          colorScheme: colorScheme,
        );
      }).toList(),
    );
  }

  Widget _buildActionList(List<ActionConfig> actions, ColorScheme colorScheme) {
    if (actions.isEmpty) {
      return _buildEmptyList('暂无执行操作', '执行操作用于触发一次性动作', colorScheme);
    }

    return Column(
      children: actions.map((action) {
        return _buildConfigItem(
          icon: Icons.play_circle_outline_rounded,
          iconColor: AppColors.info,
          title: action.actionName,
          subtitle: '键值: ${action.actionKey}',
          onDelete: () => _deleteAction(action.actionKey),
          colorScheme: colorScheme,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyList(String title, String subtitle, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onDelete,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error.withOpacity(0.7)),
        onPressed: onDelete,
      ),
    );
  }

  IconData _getSensorIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'thermostat':
      case 'temp':
        return Icons.thermostat_rounded;
      case 'water_drop':
      case 'humi':
        return Icons.water_drop_rounded;
      case 'grass':
      case 'soil':
        return Icons.grass_rounded;
      case 'light_mode':
      case 'light':
        return Icons.light_mode_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  IconData _getControlIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'water':
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'fan':
      case 'air':
        return Icons.air_rounded;
      case 'light':
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      default:
        return Icons.power_settings_new_rounded;
    }
  }

  // ===== 对话框方法 =====

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

  // ===== 删除方法 =====

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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

// ===== 添加对话框 =====

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
    {'value': 'sensors', 'icon': Icons.sensors_rounded, 'label': '通用'},
    {'value': 'thermostat', 'icon': Icons.thermostat_rounded, 'label': '温度'},
    {'value': 'water_drop', 'icon': Icons.water_drop_rounded, 'label': '湿度'},
    {'value': 'grass', 'icon': Icons.grass_rounded, 'label': '土壤'},
    {'value': 'light_mode', 'icon': Icons.light_mode_rounded, 'label': '光照'},
    {'value': 'air', 'icon': Icons.air_rounded, 'label': '气体'},
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('添加传感器'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('键值', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(hintText: '如: gas, pressure'),
            ),
            const SizedBox(height: 16),
            Text('显示名称', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: '如: 气体浓度'),
            ),
            const SizedBox(height: 16),
            Text('单位', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(hintText: '如: %, ppm, °C'),
            ),
            const SizedBox(height: 16),
            Text('图标', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
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
                      Icon(opt['icon'] as IconData, size: 16),
                      const SizedBox(width: 4),
                      Text(opt['label'] as String, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedIcon = opt['value'] as String);
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

    if (key.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写必填项')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加失败')));
      }
    }
  }
}

/// 添加控制对话框
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
    {'value': 'power_settings_new', 'icon': Icons.power_settings_new_rounded, 'label': '开关'},
    {'value': 'water_drop', 'icon': Icons.water_drop_rounded, 'label': '水泵'},
    {'value': 'air', 'icon': Icons.air_rounded, 'label': '风扇'},
    {'value': 'lightbulb', 'icon': Icons.lightbulb_rounded, 'label': '灯光'},
    {'value': 'whatshot', 'icon': Icons.whatshot_rounded, 'label': '加热'},
    {'value': 'ac_unit', 'icon': Icons.ac_unit_rounded, 'label': '制冷'},
  ];

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('添加开关控制'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('键值', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(hintText: '如: heater, pump'),
            ),
            const SizedBox(height: 16),
            Text('显示名称', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: '如: 加热器'),
            ),
            const SizedBox(height: 16),
            Text('图标', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
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
                      Icon(opt['icon'] as IconData, size: 16),
                      const SizedBox(width: 4),
                      Text(opt['label'] as String, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedIcon = opt['value'] as String);
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

    if (key.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写必填项')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加失败')));
      }
    }
  }
}

/// 添加操作对话框
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('添加执行操作'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('键值', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(hintText: '如: calibrate, reset'),
            ),
            const SizedBox(height: 16),
            Text('显示名称', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: '如: 传感器校准'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '执行操作是一次性触发，点击后会发送该键值给开发板',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
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

    if (key.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写必填项')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('添加失败')));
      }
    }
  }
}
