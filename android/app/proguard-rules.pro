# flutter_gemma / LiteRT-LM proguard rules
# Prevents obfuscation of MediaPipe and protobuf classes

-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
-keep class com.google.ai.edge.litert.** { *; }

# Keep FlutterGemma classes
-keep class com.google.ai.** { *; }

# Keep model classes
-keep class io.flutter.plugins.flutter_gemma.** { *; }
