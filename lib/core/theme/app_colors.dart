import 'package:flutter/material.dart';

/// 应用颜色系统
class AppColors {
  AppColors._();

  // ===== 主色调 (绿色系) =====
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySoft = Color(0xFF81C784);
  static const Color primaryPale = Color(0xFFC8E6C9);

  // ===== 传感器颜色 =====
  static const Color temperature = Color(0xFFFF7043);
  static const Color temperatureLight = Color(0xFFFFCCBC);
  static const Color humidity = Color(0xFF42A5F5);
  static const Color humidityLight = Color(0xFFBBDEFB);
  static const Color soil = Color(0xFF8D6E63);
  static const Color soilLight = Color(0xFFD7CCC8);
  static const Color light = Color(0xFFFFB74D);
  static const Color lightLight = Color(0xFFFFE0B2);

  // ===== 状态颜色 =====
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // ===== 浅色主题 =====
  static const Color lightBackground = Color(0xFFF5F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F4F0);
  static const Color lightOnBackground = Color(0xFF1C1B1F);
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  static const Color lightOnSurfaceVariant = Color(0xFF49454F);
  static const Color lightOutline = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // ===== 深色主题 =====
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkOnSurfaceVariant = Color(0xFFCAC4D0);
  static const Color darkOutline = Color(0xFF3C3C3C);
  static const Color darkDivider = Color(0xFF2C2C2C);

  // ===== 渐变色 =====
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  static const LinearGradient primarySoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primarySoft],
  );

  static const LinearGradient temperatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5722), temperature],
  );

  static const LinearGradient humidityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E88E5), humidity],
  );

  static const LinearGradient soilGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D4C41), soil],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFA726), light],
  );

  // ===== 工具方法 =====

  /// 根据传感器类型获取颜色
  static Color getSensorColor(String key) {
    switch (key.toLowerCase()) {
      case 'temp':
      case 'temperature':
        return temperature;
      case 'humi':
      case 'humidity':
        return humidity;
      case 'soil':
      case 'soil_humidity':
        return soil;
      case 'light':
      case 'light_intensity':
        return light;
      default:
        return primary;
    }
  }

  /// 根据传感器类型获取渐变
  static LinearGradient getSensorGradient(String key) {
    switch (key.toLowerCase()) {
      case 'temp':
      case 'temperature':
        return temperatureGradient;
      case 'humi':
      case 'humidity':
        return humidityGradient;
      case 'soil':
      case 'soil_humidity':
        return soilGradient;
      case 'light':
      case 'light_intensity':
        return lightGradient;
      default:
        return primarySoftGradient;
    }
  }

  /// 根据传感器类型获取浅色背景
  static Color getSensorLightColor(String key) {
    switch (key.toLowerCase()) {
      case 'temp':
      case 'temperature':
        return temperatureLight;
      case 'humi':
      case 'humidity':
        return humidityLight;
      case 'soil':
      case 'soil_humidity':
        return soilLight;
      case 'light':
      case 'light_intensity':
        return lightLight;
      default:
        return primaryPale;
    }
  }
}
