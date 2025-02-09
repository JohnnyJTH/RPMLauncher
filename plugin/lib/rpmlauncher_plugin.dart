import 'dart:async';

import 'package:flutter/services.dart';

class RPMLauncherPlugin {
  static const MethodChannel _channel = MethodChannel('rpmlauncher_plugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// 僅適用於 Windows 單位為 MB
  static Future<int> getTotalPhysicalMemory() async {
    double _memory = await _channel.invokeMethod('getTotalPhysicalMemory');

    int memory = _memory / 1024 ~/ 1024;

    memory = memory - (memory % 1024);
    return memory;
  }
}
