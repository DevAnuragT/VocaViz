import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/logger.dart';
import 'core/utils/env_config.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  await EnvConfig.init();

  // Configure system UI
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable logging for debugging
  AppLogger.enable();
  AppLogger.setTag('VocaViz');

  AppLogger.i('VocaViz starting...');
  AppLogger.i('Inference mode: ${EnvConfig.mode}');

  runApp(const ProviderScope(child: VocaVizApp()));
}
