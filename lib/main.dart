import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/animated_widgets.dart';
import 'data/providers/providers.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: SmartFlowerPotApp(),
    ),
  );
}

class SmartFlowerPotApp extends ConsumerWidget {
  const SmartFlowerPotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'NK星云',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

/// 认证包装器 - 根据登录状态显示不同页面
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只监听认证状态的变化，不监听整个 authState 对象
    final status = ref.watch(authProvider.select((state) => state.status));
    final isAuthenticated = ref.watch(authProvider.select((state) => state.isAuthenticated));

    // 初始化中
    if (status == AuthStatus.initial) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseWidget(
                child: Image.asset('icon.png', width: 64, height: 64),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      );
    }

    // 已登录
    if (isAuthenticated) {
      return const HomeScreen();
    }

    // 未登录
    return const LoginScreen();
  }
}
