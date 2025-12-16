# NK星云 - Flutter 客户端

通用物联网设备控制平台 Flutter 客户端，通过 WebSocket 与云服务器通信，实现对物联网设备的远程监控和控制。

![Flutter](https://img.shields.io/badge/Flutter-3.24-blue)
![Dart](https://img.shields.io/badge/Dart-3.10-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 简介

NK星云是一款通用的物联网设备控制平台客户端，支持动态配置传感器、控制项和自动化规则。通过 WebSocket 长连接与云服务器通信，实现实时数据推送和远程控制。

## 功能特性

### 核心功能

| 功能 | 说明 |
|------|------|
| **实时监控** | 实时显示设备传感器数据，支持动态配置显示项 |
| **远程控制** | 开关控制和功能操作，支持自定义命令 |
| **历史数据** | 趋势图表展示，支持多种时间范围和采样间隔 |
| **动态配置** | 运行时添加/删除传感器、控制项、操作和阈值规则 |
| **多设备管理** | 支持绑定和管理多个物联网设备 |
| **自动化规则** | 基于阈值的自动控制规则配置 |

### 界面说明

| 界面 | 功能描述 |
|------|----------|
| **登录** | 用户注册/登录，支持本地登录状态持久化 |
| **仪表盘** | 设备状态、运行模式、传感器实时数据卡片 |
| **控制** | 模式切换、开关控制、功能操作按钮 |
| **历史** | 传感器数据趋势图表，支持 30s/1m/5m/15m/1h 采样间隔 |
| **配置** | 传感器、控制项、操作、阈值规则的增删管理 |

## 技术栈

| 类别 | 技术 | 版本 |
|------|------|------|
| 框架 | Flutter | 3.24+ |
| 语言 | Dart | 3.10+ |
| 状态管理 | flutter_riverpod | 2.6.x |
| 网络通信 | web_socket_channel | 3.0.x |
| 本地存储 | shared_preferences | 2.3.x |
| 图表 | fl_chart | 0.69.x |
| 动画 | flutter_animate | 4.5.x |
| 工具 | uuid, intl | - |

## 工程结构

```
app/
├── lib/
│   ├── main.dart                       # 应用入口，主题配置，认证路由
│   ├── core/                           # 核心模块
│   │   ├── config/
│   │   │   └── app_config.dart         # 服务器地址、超时、心跳等配置
│   │   ├── network/
│   │   │   └── websocket_client.dart   # WebSocket 客户端，连接/重连/心跳
│   │   └── protocol/
│   │       ├── app_message.dart        # 消息封装，工厂方法
│   │       └── message_types.dart      # 消息类型常量定义
│   ├── data/                           # 数据层
│   │   ├── models/
│   │   │   ├── user.dart               # 用户模型，Token 管理
│   │   │   ├── device.dart             # 设备、传感器、控制、阈值配置模型
│   │   │   └── sensor_data.dart        # 实时数据、历史数据模型
│   │   └── providers/
│   │       ├── auth_provider.dart      # 认证状态，登录/注册/登出
│   │       ├── device_provider.dart    # 设备列表，重命名/解绑
│   │       └── data_provider.dart      # 实时数据、历史数据、配置管理
│   └── features/                       # 功能模块
│       ├── auth/screens/
│       │   └── login_screen.dart       # 登录/注册界面
│       └── home/screens/
│           └── home_screen.dart        # 主界面 (仪表盘/控制/历史/配置)
├── android/                            # Android 平台代码
├── ios/                                # iOS 平台代码
├── windows/                            # Windows 平台代码
├── web/                                # Web 平台代码
├── icon.png                            # 应用图标源文件 (1024x1024)
├── pubspec.yaml                        # 依赖和资源配置
└── README.md                           # 本文件
```

## 快速开始

### 环境要求

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android SDK (Android 开发)
- Visual Studio 2022+ (Windows 开发)
- Xcode 15+ (iOS/macOS 开发)

### 安装步骤

```bash
# 1. 进入 app 目录
cd app

# 2. 安装依赖
flutter pub get

# 3. 生成应用图标 (可选，如果修改了 icon.png)
flutter pub run flutter_launcher_icons
```

### 配置服务器

修改 `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String wsHost = '你的服务器IP';
  static const int wsPort = 8002;
  static const int heartbeatInterval = 30;   // 心跳间隔(秒)
  static const int reconnectInterval = 5;    // 重连间隔(秒)
  static const int requestTimeout = 10000;   // 请求超时(毫秒)
}
```

### 运行与构建

```bash
# 调试运行
flutter run

# 构建 Android APK
flutter build apk --release

# 构建 Windows
flutter build windows --release

# 构建 Web
flutter build web --release
```

**构建输出位置:**
- Android: `build/app/outputs/flutter-apk/app-release.apk`
- Windows: `build/windows/x64/runner/Release/`
- Web: `build/web/`

## 通信协议

### 连接信息

| 项目 | 值 |
|------|------|
| 协议 | WebSocket |
| 端口 | 8002 |
| 格式 | JSON |
| 心跳 | 30秒 ping/pong |

### 消息格式

```json
{
  "version": "1.0",
  "msg_id": "uuid-string",
  "timestamp": 1234567890123,
  "type": "消息类型",
  "user_id": "用户ID",
  "device_id": "设备ID",
  "payload": { ... }
}
```

### 消息类型

| 类别 | 类型 | 说明 |
|------|------|------|
| 认证 | `auth.register` | 用户注册 |
| | `auth.login` | 用户登录 |
| | `auth.logout` | 用户登出 |
| | `auth.result` | 认证结果 |
| 设备 | `device.list` | 获取设备列表 |
| | `device.rename` | 重命名设备 |
| | `device.unbind` | 解绑设备 |
| | `device.status` | 设备状态变更(推送) |
| 配置 | `config.get` | 获取设备配置 |
| | `config.sensor.add/del` | 添加/删除传感器配置 |
| | `config.control.add/del` | 添加/删除控制配置 |
| | `config.action.add/del` | 添加/删除操作配置 |
| | `config.threshold.add/del` | 添加/删除阈值规则 |
| 数据 | `data.realtime` | 实时数据推送 |
| | `data.history` | 请求历史数据 |
| 控制 | `cmd.control` | 开关控制命令 |
| | `cmd.action` | 功能操作命令 |
| 系统 | `sys.ping/pong` | 心跳 |

### 示例

```json
// 登录
{
  "type": "auth.login",
  "payload": { "username": "user", "password": "pwd" }
}

// 开关控制
{
  "type": "cmd.control",
  "user_id": "user",
  "device_id": "DEV_001",
  "payload": { "control_key": "light", "state": "on" }
}

// 实时数据推送
{
  "type": "data.realtime",
  "device_id": "DEV_001",
  "payload": {
    "data": { "temp": 25, "humi": 60 },
    "status": { "mode": 0, "light": 1 }
  }
}
```

## 状态管理

项目使用 Riverpod 进行状态管理:

| Provider | 说明 |
|----------|------|
| `wsClientProvider` | WebSocket 客户端单例 |
| `connectionStateProvider` | 连接状态流 |
| `authProvider` | 用户认证状态 |
| `currentUserProvider` | 当前用户 |
| `devicesProvider` | 设备列表 |
| `selectedDeviceProvider` | 当前选中设备 |
| `deviceConfigProvider` | 设备配置 |
| `realtimeDataProvider` | 实时数据 |
| `historyDataProvider` | 历史数据 |

## 数据模型

### 设备配置 (`DeviceConfig`)

```dart
class DeviceConfig {
  List<SensorConfig> sensors;     // 传感器配置
  List<ControlConfig> controls;   // 控制配置
  List<ActionConfig> actions;     // 操作配置
  List<ThresholdConfig> thresholds; // 阈值规则
}
```

### 传感器配置 (`SensorConfig`)

```dart
class SensorConfig {
  String fieldKey;      // 字段键名 (temp, humi, soil, light)
  String fieldName;     // 显示名称
  String unit;          // 单位 (°C, %, lux)
  String icon;          // 图标名称
  int displayOrder;     // 显示顺序
}
```

### 阈值规则 (`ThresholdConfig`)

```dart
class ThresholdConfig {
  String sensorKey;     // 传感器键名
  String controlKey;    // 控制键名
  String conditionType; // 条件: gt, lt, gte, lte, eq
  double thresholdValue; // 阈值
  String triggerAction; // 触发动作: on, off
}
```

## 开发文档

详细的 API 文档和开发指南请参考 `docs/` 目录:

| 文档 | 说明 |
|------|------|
| [`API_Protocol.md`](docs/API_Protocol.md) | WebSocket 通信协议详细文档 |
| [`Custom_Config_Guide.md`](docs/Custom_Config_Guide.md) | 自定义配置开发指南 |

## 版本历史

- **V2.0.0** (2025-12)
  - 重命名为 NK星云，定位为通用物联网平台
  - Riverpod 状态管理架构
  - 动态配置传感器、控制项、操作、阈值
  - 历史数据图表
  - 多平台支持 (Android/iOS/Windows/Web)
  - Material 3 设计

- **V1.0.0** (2025-06)
  - 初始版本，智能花盆专用

## 许可证

MIT License

## 作者

NixStudio (Nix Lockhart)
