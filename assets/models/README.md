# Gemma 4 Model Directory

Place your Gemma 4 model artifact here for on-device inference.

## Required File

**Filename:** `gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm`
**Companion:** `gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm_9941790358430999734.bin`

**Expected path:** `assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm`

## Where to Get the Model

1. **Google AI Edge Gallery** (for testing)
   - Install the AI Edge Gallery app on Android
   - Download Gemma 4 E2B model
   - Export/copy to this directory

2. **Hugging Face** (for production)
   - Official: `google/gemma-4-tflite` (coming soon)
   - Reference: `google/gemma-2b-it-tflite` (existing 2B format)
   - Look for INT4 quantized variants (~1.1-1.5 GB)

3. **Google AI Studio** (for remote API alternative)
   - If local model unavailable, use remote mode
   - Get API key: https://aistudio.google.com/app/apikey

## File Size Expectations

| Model | Quantization | Size |
|-------|--------------|------|
| Gemma 4 E2B | 2-bit | ~1.2 GB |
| Gemma 4 E2B | 4-bit (INT4) | ~1.5 GB |
| Gemma 4 E4B | 4-bit | ~2.5 GB |

## After Adding the Model

1. Update `.env`:
   ```
   INFERENCE_MODE=local
   LOCAL_MODEL_PATH=assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm
   ```

2. Run `flutter pub get` to refresh assets

3. Build and run on Android device

## Verification

The app will automatically detect the model and report status via:
- `InferenceService.localModelStatus`
- `LocalModelStatus.ready` = model loaded successfully
- `LocalModelStatus.artifactMissing` = file not found

See [GEMMA4_MODEL_SETUP.md](../../GEMMA4_MODEL_SETUP.md) for full setup instructions.
