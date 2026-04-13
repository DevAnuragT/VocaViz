# Gemma 4 Model Setup for VocaViz

This document describes how to integrate Gemma 4 for on-device inference in VocaViz.

## Overview

VocaViz supports three inference modes:

| Mode | Description | Requirements |
|------|-------------|--------------|
| `mock` | Predefined results for demo reliability | None (default) |
| `remote` | Google AI API (cloud) | API key from aistudio.google.com |
| `local` | On-device Gemma 4 via LiteRT-LM | Model artifact file |

## Gemma 4 Model Artifact Requirements

### Required Format

For Android integration, VocaViz expects the Gemma 4 model in one of these formats:

1. **`.task` format** (Recommended - LiteRT-LM)
   - Path: `assets/models/gemma-4-2b.task`
   - Size: ~1.5 GB (quantized 2-bit/4-bit)
   - Best for: Production apps with LiteRT-LM SDK

2. **`.tflite` format** (Alternative)
   - Path: `assets/models/gemma-4-2b.tflite`
   - Size: ~1.1 GB (INT4 quantized)
   - Best for: Direct TFLite interpreter integration

### Where to Get Gemma 4 Models

#### Official Sources

1. **Google AI Edge Gallery** (for testing)
   - Install the [AI Edge Gallery app](https://github.com/google-ai-edge/gallery)
   - Download Gemma 4 E2B model directly on device
   - Use for prototyping before app integration

2. **Hugging Face** (for production)
   - Official: [`google/gemma-4-tflite`](https://huggingface.co/google/gemma-4-tflite) *(coming soon)*
   - Community: Check for INT4 quantized variants
   - Look for files named `gemma-4-2b-it-gpu-int4.tflite`

3. **Google AI Studio** (for remote API)
   - Get API key: https://aistudio.google.com/app/apikey
   - Use with `remote` mode (no local artifact needed)

### Device Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Android Version | Android 10 (API 29) | Android 14+ (AICore support) |
| RAM | 4 GB free | 6+ GB free |
| Storage | 2 GB free | 4+ GB free |
| Chipset | Any ARM64 | Snapdragon 8 Gen 2+, Dimensity 9000+, Tensor G3+ |
| NPU | Optional | Qualcomm Hexagon, MediaTek APU |

### Performance Expectations

| Device Class | Prefill Speed | Token Generation |
|--------------|---------------|------------------|
| High-end (NPU) | ~4000 tokens/s | ~40 tokens/s |
| Mid-range | ~1500 tokens/s | ~20 tokens/s |
| Low-end | ~500 tokens/s | ~8 tokens/s |

## Integration Steps

### Step 1: Download the Model

```bash
# Example: Download from Hugging Face (requires login)
cd vocaviz/assets/models/
wget https://huggingface.co/google/gemma-4-tflite/resolve/main/gemma-4-2b-it-gpu-int4.tflite
# Rename to expected name
mv gemma-4-2b-it-gpu-int4.tflite gemma-4-2b.task
```

### Step 2: Update pubspec.yaml

Add the model asset to your Flutter build:

```yaml
flutter:
  assets:
    - assets/images/sample_pumps/
    - assets/models/gemma-4-2b.task  # Add this line
```

### Step 3: Configure .env

```bash
# For local mode
INFERENCE_MODE=local
LOCAL_MODEL_PATH=assets/models/gemma-4-2b.task

# For remote mode (alternative)
INFERENCE_MODE=remote
GEMMA_API_KEY=your_api_key_here
GEMMA_MODEL=gemma-4-2b
```

### Step 4: Add LiteRT-LM Dependencies

In `android/app/build.gradle.kts`:

```kotlin
dependencies {
    // LiteRT-LM for Gemma 4 inference
    implementation("com.google.ai.edge.litert:litert-lm-android:1.0.0")
}
```

### Step 5: Implement Model Loading

The scaffolding is in place in `inference_service.dart`. Complete the TODOs:

```dart
// In InferenceService.initializeLocalModel():
// 1. Load model via LiteRT-LM
// 2. Initialize tokenizer (SentencePiece)
// 3. Configure inference options (temperature, max tokens)
```

## Current Scaffolding Status

### Implemented

- [x] `InferenceMode` enum with `local` option
- [x] `LocalModelStatus` enum for diagnostics
- [x] `checkLocalModelAvailability()` method
- [x] `initializeLocalModel()` method
- [x] Graceful fallback to mock when model unavailable
- [x] Diagnostic messages for each failure mode
- [x] Environment config for local model path

### TODO (Requires Model Artifact)

- [ ] Implement actual LiteRT-LM model loading
- [ ] Add tokenizer integration (SentencePiece)
- [ ] Convert image to model input format
- [ ] Implement streaming response handling
- [ ] Add memory management for large models
- [ ] Test on physical Android device

## Troubleshooting

### Model Not Found (`artifactMissing`)

1. Verify file exists at `assets/models/gemma-4-2b.task`
2. Run `flutter pub get` to refresh assets
3. Check `flutter build apk` includes the model file

### Incompatible Format (`artifactIncompatible`)

1. Ensure file is `.task` (LiteRT-LM) or `.tflite` format
2. Check file is not corrupted (verify checksum)
3. Try official Google model variants

### Device Insufficient (`deviceInsufficient`)

1. Close other apps to free RAM
2. Try smaller model variant (E2B vs E4B)
2. Consider using `remote` mode instead

### Init Failed (`initFailed`)

1. Check `_localModelError` for details
2. Verify LiteRT-LM dependencies are installed
3. Ensure Android version supports AICore

## Fallback Strategy

VocaViz implements a robust fallback chain:

```
local mode requested
    ↓
Check model availability
    ↓
Model ready? → Run local inference
    ↓ No
Fallback to mock + diagnostic message
    ↓
User sees: "Analysis complete (Local Gemma 4 model not installed)"
```

This ensures the app always works, even without the model artifact.

## Hackathon Submission Notes

For the Gemma 4 Good Hackathon:

1. **Primary target**: Gemma 4 (2B or 4B variant)
2. **Demo mode**: `mock` is acceptable for reliability
3. **Production path**: `local` mode with Gemma 4 artifact
4. **Fallback**: `remote` mode via Google AI API

The architecture supports all three modes - swap implementations without changing app logic.

## Resources

- [LiteRT-LM Documentation](https://developers.googleblog.com/bring-state-of-the-art-agentic-skills-to-the-edge-with-gemma-4)
- [Android AICore Developer Preview](https://android-developers.googleblog.com/2026/04/AI-Core-Developer-Preview.html)
- [Gemma 4 Mobile Guide](https://www.gemma4.app/mobile)
- [Hugging Face - Gemma 2B TFLite](https://huggingface.co/google/gemma-2b-it-tflite) (reference for format)

---

**Last Updated**: 2026-04-12
**VocaViz Version**: 1.0.0 (Hackathon MVP)
