import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Device capability checks to keep local inference safe on low-end hardware.
class DeviceCapabilities {
  static const int _minRamMbForLocalGemma = 8192;
  static bool? _cachedSupportsLocalGemma;

  static Future<bool> supportsLocalGemma() async {
    if (_cachedSupportsLocalGemma != null) {
      return _cachedSupportsLocalGemma!;
    }

    if (!Platform.isAndroid) {
      _cachedSupportsLocalGemma = false;
      return false;
    }

    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    final isLowRam = android.isLowRamDevice;
    final physicalRamMb = android.physicalRamSize;

    final supports = !isLowRam && physicalRamMb >= _minRamMbForLocalGemma;
    _cachedSupportsLocalGemma = supports;
    return supports;
  }
}
