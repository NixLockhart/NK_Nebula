# NK星云 WebSocket API 开发文档

## 概述

本文档描述 Flutter APP 与云服务器之间的 WebSocket 通信协议。

### 服务器信息

- **协议**: WebSocket
- **端口**: 8002
- **地址**: `ws://<服务器IP>:8002`

### 消息格式

所有消息采用 JSON 格式，基本结构如下：

```json
{
  "version": "1.0",
  "msg_id": "uuid-string",
  "timestamp": 1234567890123,
  "type": "消息类型",
  "user_id": "用户ID（可选）",
  "device_id": "设备ID（可选）",
  "payload": { ... }
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| version | string | 是 | 协议版本，固定为 "1.0" |
| msg_id | string | 是 | 消息唯一标识，UUID 格式 |
| timestamp | int | 是 | 时间戳（毫秒） |
| type | string | 是 | 消息类型 |
| user_id | string | 否 | 用户ID |
| device_id | string | 否 | 设备ID |
| payload | object | 是 | 消息载荷 |

---

## 一、认证相关

### 1.1 用户注册

**请求** `auth.register`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "auth.register",
  "payload": {
    "username": "用户名",
    "password": "密码"
  }
}
```

**响应** `auth.result`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "auth.result",
  "payload": {
    "success": true,
    "code": 0,
    "message": "注册成功",
    "data": {
      "user_id": "用户名",
      "token": "JWT令牌",
      "expires_at": 1234567890123
    }
  }
}
```

**用户名规则**:
- 长度: 3-50 字符
- 只能包含字母、数字和下划线

**密码规则**:
- 长度: 6-128 字符

---

### 1.2 用户登录

**请求** `auth.login`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "auth.login",
  "payload": {
    "username": "用户名",
    "password": "密码"
  }
}
```

**响应** `auth.result`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "auth.result",
  "payload": {
    "success": true,
    "code": 0,
    "message": "登录成功",
    "data": {
      "user_id": "用户名",
      "token": "JWT令牌",
      "expires_at": 1234567890123
    }
  }
}
```

---

### 1.3 用户登出

**请求** `auth.logout`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "auth.logout",
  "payload": {}
}
```

---

## 二、设备管理

### 2.1 获取设备列表

**请求** `device.list`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "device.list",
  "user_id": "用户名",
  "payload": {}
}
```

**响应** `device.list.result`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "device.list.result",
  "user_id": "用户名",
  "payload": {
    "success": true,
    "code": 0,
    "message": "success",
    "data": {
      "devices": [
        {
          "id": 1,
          "device_id": "SFP_001",
          "name": "我的设备",
          "status": "online",
          "firmware_version": "2.0",
          "last_heartbeat": 1234567890123,
          "created_at": 1234567890123
        }
      ]
    }
  }
}
```

> **注意**: 调用此接口后，APP 会自动订阅返回的所有设备的实时数据推送。

---

### 2.2 重命名设备

**请求** `device.rename`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "device.rename",
  "user_id": "用户名",
  "device_id": "SFP_001",
  "payload": {
    "name": "新名称"
  }
}
```

---

### 2.3 解绑设备

**请求** `device.unbind`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "device.unbind",
  "user_id": "用户名",
  "device_id": "SFP_001",
  "payload": {}
}
```

---

## 三、配置管理

### 3.1 获取设备配置

**请求** `config.get`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "config.get",
  "user_id": "用户名",
  "device_id": "SFP_001",
  "payload": {}
}
```

**响应** `config.get.result`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "config.get.result",
  "device_id": "SFP_001",
  "payload": {
    "success": true,
    "code": 0,
    "message": "success",
    "data": {
      "sensors": [
        {
          "id": 1,
          "field_key": "temp",
          "field_name": "温度",
          "unit": "°C",
          "icon": "thermostat",
          "display_order": 0,
          "is_enabled": true
        }
      ],
      "controls": [
        {
          "id": 1,
          "control_key": "light",
          "control_name": "补光灯",
          "cmd_on": "light_on",
          "cmd_off": "light_off",
          "icon": "lightbulb",
          "display_order": 0,
          "is_enabled": true
        }
      ],
      "actions": [
        {
          "id": 1,
          "action_key": "reboot",
          "action_name": "重启设备",
          "cmd": "reboot",
          "icon": "restart_alt",
          "display_order": 0,
          "is_enabled": true
        }
      ],
      "thresholds": [
        {
          "id": 1,
          "sensor_key": "soil",
          "control_key": "water",
          "condition": "lt",
          "value": 40.0,
          "action": "on",
          "is_enabled": true
        }
      ]
    }
  }
}
```

---

### 3.2 添加/删除配置

| 消息类型 | 说明 |
|----------|------|
| `config.sensor.add` | 添加传感器配置 |
| `config.sensor.del` | 删除传感器配置 |
| `config.control.add` | 添加控制配置 |
| `config.control.del` | 删除控制配置 |
| `config.action.add` | 添加操作配置 |
| `config.action.del` | 删除操作配置 |
| `config.threshold.add` | 添加阈值规则 |
| `config.threshold.del` | 删除阈值规则 |

**阈值条件 (condition)**:
- `gt`: 大于
- `lt`: 小于
- `gte`: 大于等于
- `lte`: 小于等于
- `eq`: 等于

---

## 四、控制命令

### 4.1 开关控制

**请求** `cmd.control`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "cmd.control",
  "user_id": "用户名",
  "device_id": "SFP_001",
  "payload": {
    "control_key": "light",
    "state": "on"
  }
}
```

**state 可选值**:
- `on`: 开启
- `off`: 关闭

### 4.2 功能操作

**请求** `cmd.action`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "cmd.action",
  "user_id": "用户名",
  "device_id": "SFP_001",
  "payload": {
    "action_key": "reboot"
  }
}
```

---

## 五、数据查询

### 5.1 获取历史数据

**请求** `data.history`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "data.history",
  "device_id": "SFP_001",
  "payload": {
    "start_time": 1234567890123,
    "end_time": 1234567890123,
    "interval": "1h",
    "fields": ["temp", "humi"]
  }
}
```

**interval 可选值**:
- `1m`: 1分钟
- `5m`: 5分钟
- `15m`: 15分钟
- `1h`: 1小时
- `1d`: 1天

---

## 六、推送消息（服务器 -> APP）

### 6.1 实时数据推送

**类型** `data.realtime`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "data.realtime",
  "user_id": "用户名",
  "device_id": "SFP_001",
  "payload": {
    "data": {
      "temp": 25,
      "humi": 60,
      "soil": 45,
      "light": 70
    },
    "status": {
      "mode": 0,
      "light": 1,
      "water": 0,
      "fan": 0
    },
    "recorded_at": 1234567890123
  }
}
```

### 6.2 设备状态变更

**类型** `device.status`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "device.status",
  "user_id": "用户名",
  "device_id": "SFP_001",
  "payload": {
    "status": "online",
    "last_heartbeat": 1234567890123
  }
}
```

---

## 七、系统消息

### 7.1 心跳

**请求** `sys.ping`

```json
{
  "version": "1.0",
  "msg_id": "uuid",
  "timestamp": 1234567890123,
  "type": "sys.ping",
  "payload": {}
}
```

**响应** `sys.pong`

> **建议**: 每 30 秒发送一次心跳，保持连接活跃。

---

## 八、错误码

### 认证错误 (1xxx)

| 错误码 | 说明 |
|--------|------|
| 1001 | 用户名已存在 |
| 1002 | 用户名格式无效 |
| 1003 | 密码格式无效 |
| 1004 | 用户不存在 |
| 1005 | 密码错误 |
| 1006 | 账户已禁用 |
| 1007 | Token 无效 / 未认证 |
| 1008 | Token 已过期 |

### 设备错误 (2xxx)

| 错误码 | 说明 |
|--------|------|
| 2001 | 设备离线 |
| 2002 | 设备不存在 |
| 2003 | 设备已绑定其他用户 |
| 2004 | 无权操作此设备 |
| 2005 | 设备注册失败 |
| 2006 | 命令执行超时 |
| 2007 | 命令执行失败 |

### 配置错误 (3xxx)

| 错误码 | 说明 |
|--------|------|
| 3001 | 配置项不存在 |
| 3002 | 配置项已存在 |
| 3003 | 配置参数无效 |
| 3004 | 超出配置数量限制 |

### 数据错误 (4xxx)

| 错误码 | 说明 |
|--------|------|
| 4001 | 数据格式错误 |
| 4002 | 时间范围无效 |
| 4003 | 数据不存在 |

---

## 九、最佳实践

1. **连接管理**: 保持单一 WebSocket 连接，断线后自动重连
2. **心跳保活**: 每 30 秒发送 `sys.ping`，防止连接超时断开
3. **消息匹配**: 使用 `msg_id` 或 `ref_msg_id` 匹配请求和响应
4. **数据合并**: 实时数据推送中 `data` 和 `status` 可能分开到达，需要合并处理
5. **超时处理**: 设置合理的请求超时时间（建议 5-10 秒）
6. **错误处理**: 根据错误码进行相应的用户提示

---

*文档版本: 1.0*
*最后更新: 2025-12-16*
