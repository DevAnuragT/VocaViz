# Gemma 4 Model Setup for VocaViz

This document describes how to integrate Gemma 4 for on-device inference in VocaViz.

## Overview

VocaViz supports three inference modes:

| Mode | Description | Requirements |
|------|-------------|--------------|
| `mock` | Predefined results for demo reliability | None (default) |
| `remote` | Google AI API (cloud) | API key from aistudio.google.com |
| `local` | On-device Gemma 4 via flutter_gemma (LiteRT-LM backend) | Model artifact file |

## Gemma 4 Model Artifact Requirements

### Required Format

For Android integration with flutter_gemma 0.11.x, VocaViz expects the Gemma 4 model in this format:

1. **`.litertlm` or `.task` format** (Required for flutter_gemma)
  - Path: `assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm`
  - Companion: `.bin` file with the same prefix
  - Size: ~2.4 GB (Gemma 4 E2B)
  - Best for: flutter_gemma on-device inference

**Note:** flutter_gemma handles model loading automatically. Just place the file in assets/models/.

### Where to Get Gemma 4 Models

#### Official Sources

1. **Google AI Edge Gallery** (Recommended for testing)
   - Install the [AI Edge Gallery app](https://github.com/google-ai-edge/gallery)
   - Download Gemma 4 E2B model directly on device
   - Copy model from app data to your project's `assets/models/`

2. **Hugging Face** (for production)
   - Search for `gemma-4-e2b-it` or `gemma-4-e4b-it`
   - Look for `.litertlm` or `.task` format files
   - Example: `google/gemma-4-e2b-it` (official)

3. **Google AI Studio** (for remote API)
   - Get API key: https://aistudio.google.com/app/apikey
   - Use with `remote` mode (no local artifact needed)

### Device Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Android Version | Android 8.0 (API 26) | Android 10+ |
| RAM | 4 GB free | 6+ GB free |
| Storage | 3 GB free | 4+ GB free |
| Chipset | Any ARM64 with GPU | Snapdragon 8 Gen 2+, Dimensity 9000+, Tensor G3+ |
| GPU | OpenGL ES 3.0+ | Vulkan or Metal |

### Performance Expectations (flutter_gemma 0.11.x)

| Device Class | Token Generation |
|--------------|------------------|
| High-end (GPU) | ~30-50 tokens/s |
| Mid-range | ~15-25 tokens/s |
| Low-end | ~5-10 tokens/s |

## Integration Steps

### Step 1: Download the Model

**Option A: Google AI Edge Gallery**
1. Install AI Edge Gallery app on Android device
2. Download Gemma 4 E2B model (~2.4 GB)
3. Copy model file from app data to your computer
4. Place in project's `assets/models/` directory

**Option B: Hugging Face**
```bash
cd vocaviz/assets/models/
# Download gemma-4-e2b-it model (requires login)
# Look for .litertlm or .task format
```

### Step 2: Place Model in Assets

```
assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm
assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm_9941790358430999734.bin
```

pubspec.yaml already includes `assets/models/` directory.

### Step 3: Configure .env

```bash
# For local mode (on-device)
INFERENCE_MODE=local

# For remote mode (alternative)
INFERENCE_MODE=remote
GEMMA_API_KEY=your_api_key_here
GEMMA_MODEL=gemma-4-2b
```

### Step 4: Build and Run

```bash
flutter pub get
flutter run
```

flutter_gemma handles model loading automatically. No additional dependencies needed.

## Current Scaffolding Status

### Implemented

- [x] `InferenceMode` enum with `local` option
- [x] `LocalModelStatus` enum for diagnostics
- [x] `checkLocalModelAvailability()` method
- [x] `initializeLocalModel()` using flutter_gemma
- [x] Graceful fallback to mock when model unavailable
- [x] Diagnostic messages for each failure mode
- [x] Multimodal input (image + text) support
- [x] Platform exception handling (GPU crashes, OOM)
- [x] Android configuration (GPU, ProGuard rules)
- [x] Model status UI widget

### TODO (Requires Model Artifact)

- [ ] Download Gemma 4 E2B model file
- [ ] Place at `assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm`
- [ ] Test on physical Android device with GPU
- [ ] Verify multimodal image analysis works
- [ ] Tune temperature/prompt for best results

## Troubleshooting

### Model Not Found (`artifactMissing`)

1. Verify file exists at `assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm`
2. Run `flutter pub get` to refresh assets
3. Check `flutter build apk` includes the model file

### Platform Crash (`initFailed`)

flutter_gemma may crash on some devices due to:
- GPU driver issues
- Insufficient RAM
- Incompatible Android version

**Fallback:** App gracefully falls back to mock mode.

### Low Performance

- Close other apps to free RAM
- Reduce max tokens in `getActiveModel(maxTokens: 1024)`
- Use mid-range quality settings

## API Key Points

### flutter_gemma Usage (0.11.x)

```dart
// Initialize once at startup
await FlutterGemma.initialize(huggingFaceToken: token);

// Get model
final model = await FlutterGemma.getActiveModel(maxTokens: 2048);

// Create chat
final chat = await model.createChat();

// Send image + text (multimodal)
await chat.addQueryChunk(
  Message.withImage(
    text: 'Analyze this image...',
    imageBytes: imageBytes,
    isUser: true,
  ),
);

// Get response
final response = await chat.generateChatResponse();
```

### Stability Wrapper

```dart
try {
  // flutter_gemma call
} on PlatformException catch (e) {
  // Handle GPU/init failures
  _localModelStatus = LocalModelStatus.initFailed;
  _localModelError = 'Platform error: ${e.message}';
  return fallbackResult;
}
```

## Resources

- [flutter_gemma pub.dev](https://pub.dev/packages/flutter_gemma)
- [Google AI Edge Gallery](https://github.com/google-ai-edge/gallery)
- [Gemma 4 on Hugging Face](https://huggingface.co/google/gemma-4-e2b-it)

---

**Last Updated**: 2026-04-13
**VocaViz Version**: 1.0.0 (Hackathon MVP)
**flutter_gemma Version**: 0.11.16
