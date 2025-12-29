import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/websocket_client.dart';
import '../../core/protocol/app_message.dart';
import '../models/models.dart';

/// WebSocket 客户端 Provider
final wsClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// 连接状态 Provider
final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  final client = ref.watch(wsClientProvider);
  return client.stateStream;
});

/// 认证状态
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 认证状态数据
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
}

/// 认证状态 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final WebSocketClient _client;

  AuthNotifier(this._client) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    // 尝试从本地存储恢复登录状态
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final username = prefs.getString('username');
    final token = prefs.getString('token');
    final expiresAt = prefs.getInt('token_expires_at');

    if (userId != null && token != null) {
      final user = User(
        userId: userId,
        username: username ?? userId,
        token: token,
        tokenExpiresAt: expiresAt,
      );

      if (user.isTokenValid) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        // 尝试连接服务器
        _connectToServer();
      } else {
        // Token 过期
        await _clearStoredAuth();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _connectToServer() async {
    if (!_client.isConnected) {
      await _client.connect();
    }
  }

  /// 注册
  Future<bool> register(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      // 确保连接
      if (!_client.isConnected) {
        await _client.connect();
      }

      final message = MessageFactory.createRegister(username, password);
      final response = await _client.send(message);

      if (response.isSuccess) {
        // 服务器返回格式: payload.data.{user_id, token, expires_at}
        final data = response.payload['data'] as Map<String, dynamic>? ?? {};
        // 确保 username 被正确设置（服务器可能不返回 username）
        if (!data.containsKey('username') || (data['username'] as String?)?.isEmpty == true) {
          data['username'] = username;
        }
        final user = User.fromJson(data);
        await _saveAuth(user);
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.error,
          error: response.errorMessage ?? '注册失败',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      return false;
    }
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      // 确保连接
      if (!_client.isConnected) {
        await _client.connect();
      }

      final message = MessageFactory.createLogin(username, password);
      final response = await _client.send(message);

      if (response.isSuccess) {
        // 服务器返回格式: payload.data.{user_id, token, expires_at}
        final data = response.payload['data'] as Map<String, dynamic>? ?? {};
        // 确保 username 被正确设置（服务器可能不返回 username）
        if (!data.containsKey('username') || (data['username'] as String?)?.isEmpty == true) {
          data['username'] = username;
        }
        final user = User.fromJson(data);
        await _saveAuth(user);
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.error,
          error: response.errorMessage ?? '登录失败',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    if (state.user != null && _client.isConnected) {
      try {
        final message = MessageFactory.createLogout(state.user!.userId);
        _client.sendNoWait(message);
      } catch (_) {}
    }

    await _clearStoredAuth();
    _client.disconnect();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _saveAuth(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.userId);
    await prefs.setString('username', user.username);
    if (user.token != null) {
      await prefs.setString('token', user.token!);
    }
    if (user.tokenExpiresAt != null) {
      await prefs.setInt('token_expires_at', user.tokenExpiresAt!);
    }
  }

  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('token');
    await prefs.remove('token_expires_at');
  }
}

/// 认证状态 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // 使用 ref.read 避免重建
  final client = ref.read(wsClientProvider);
  return AuthNotifier(client);
});

/// 当前用户 Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// 是否已登录 Provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
