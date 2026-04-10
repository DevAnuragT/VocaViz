import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/utils/logger.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const VocaVizApp());
}
