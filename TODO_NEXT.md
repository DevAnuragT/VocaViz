# TODO_NEXT.md - Post-Hackathon Roadmap

## Immediate Post-Hackathon Improvements

### 1. Real Gemma 4 Integration

**Priority:** High  
**Effort:** Medium  
**Status:** Scaffolding complete - needs model artifact

The inference architecture now supports Gemma 4 via three modes:
- `mock` - Demo reliability (default)
- `remote` - Google AI API with Gemma 4
- `local` - On-device Gemma 4 via LiteRT-LM

**What's done:**
- [x] `InferenceMode` enum with all three modes
- [x] `LocalModelStatus` diagnostics enum
- [x] `checkLocalModelAvailability()` method
- [x] `initializeLocalModel()` scaffolding
- [x] Graceful fallback to mock when model unavailable
- [x] Environment config for model selection
- [x] Documentation in [GEMMA4_MODEL_SETUP.md](GEMMA4_MODEL_SETUP.md)

**What's needed:**
- [ ] Place Gemma 4 `.litertlm` (and companion `.bin`) at `assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm`
- [ ] Add LiteRT-LM dependency to `android/app/build.gradle.kts`
- [ ] Implement actual model loading in `InferenceService.initializeLocalModel()`
- [ ] Add tokenizer integration (SentencePiece)
- [ ] Test on physical Android device with NPU

```dart
// Remote mode (ready to use):
INFERENCE_MODE=remote
GEMMA_API_KEY=your_key
GEMMA_MODEL=gemma-4-31b-it

// Local mode (needs model artifact):
INFERENCE_MODE=local
LOCAL_MODEL_PATH=assets/models/gemma4_2b_v09_obfus_fix_all_modalities_thinking.litertlm
```

**Files modified:**
- `lib/services/inference_service.dart` - Full scaffolding with diagnostics
- `lib/core/utils/env_config.dart` - Gemma 4 defaults, local mode support
- `lib/features/inspection/providers/analysis_controller.dart` - Mode selection logic

---

### 2. On-Device Inference (LiteRT-LM)

**Priority:** High (for offline story)  
**Effort:** High  
**Status:** Scaffolding complete - needs LiteRT-LM integration

See [GEMMA4_MODEL_SETUP.md](GEMMA4_MODEL_SETUP.md) for detailed setup instructions.

**What's needed:**
```kotlin
// In android/app/build.gradle.kts:
dependencies {
    implementation("com.google.ai.edge.litert:litert-lm-android:1.0.0")
}
```

**Implementation TODOs in `inference_service.dart`:**
```dart
// 1. Load model via LiteRT-LM
// 2. Initialize tokenizer (SentencePiece)
// 3. Convert image to model input format (resize, normalize)
// 4. Run inference: model.generateResponse(prompt + image)
// 5. Parse JSON response with existing _parseJsonResponse()
// 6. Handle streaming responses for better UX
```

**Dependencies to add:**
```yaml
# pubspec.yaml
dependencies:
  # Consider for LiteRT-LM Flutter bindings (if available)
  # litert_flutter: ^1.0.0  # Check pub.dev for availability
```

---

### 3. Expanded Machine Catalog

**Priority:** Medium  
**Effort:** Low

Add support for more machine types:

```dart
// TODO: Add machine type selection
// - Solar inverter panels (LED error codes)
// - Bicycle drivetrain (chain issues)
// - Small engine equipment (visual inspection)

enum MachineType {
  beltDrivenPump,
  solarInverter,
  bicycleDrivetrain,
  // Add more...
}
```

**Files to modify:**
- `lib/data/models/machine.dart`
- `lib/data/mock/mock_knowledge_base.dart`
- `lib/features/home/home_screen.dart` - Machine type selector

---

### 4. Real Sample Images

**Priority:** Medium  
**Effort:** Low

Replace placeholder with actual images:

```bash
# TODO: Add real pump images to assets
assets/images/sample_pumps/
├── loose_belt_1.jpg
├── loose_belt_2.jpg
├── worn_belt_1.jpg
├── worn_belt_2.jpg
├── misaligned_belt_1.jpg
└── misaligned_belt_2.jpg
```

**Files to modify:**
- `pubspec.yaml` - Asset declarations
- `lib/data/mock/mock_knowledge_base.dart` - Update paths

---

### 5. Session History

**Priority:** Low  
**Effort:** Medium

Persist recent inspections locally:

```dart
// TODO: Add local storage for session history
// - Use shared_preferences or sqflite
// - Store: timestamp, issue type, confidence, image path
// - Display in history screen
// - Add clear history function

// Dependencies to add:
// - shared_preferences: ^2.2.0
// - or sqflite: ^2.3.0
```

**Files to add:**
- `lib/features/history/history_screen.dart`
- `lib/data/repositories/session_repository.dart`

---

## Medium-Term Enhancements

### 6. Vector-Based Knowledge Retrieval

**Priority:** Low (only if scaling knowledge base)  
**Effort:** High

Use embeddings for repair knowledge lookup:

```dart
// TODO: Implement vector similarity search
// - Embed repair knowledge offline
// - Use on-device embedding model
// - Retrieve relevant steps by similarity
// - Cache frequently accessed knowledge

// Consider:
// - @vlads/sqflite-vec (SQLite with vector search)
// - Custom embedding + cosine similarity
```

---

### 7. True AR Overlays

**Priority:** Low (nice-to-have)  
**Effort:** High

Replace 2D overlays with ARCore/ARKit:

```dart
// TODO: Add AR anchoring for overlays
// - Use arcore_flutter_plugin or arkit_plugin
// - Anchor detection boxes to real-world coordinates
// - Track belt position as user moves camera
// - Show arrows pointing to problem areas

// Dependencies to add:
// - arcore_flutter_plugin: ^0.2.0 (Android)
// - arkit_plugin: ^1.0.0 (iOS)
```

**Files to modify:**
- `lib/core/widgets/overlay_painter.dart` - Replace with AR overlay
- `lib/features/inspection/camera_screen.dart` - AR session management

---

### 8. Voice Guidance

**Priority:** Medium (accessibility)  
**Effort:** Medium

Add spoken repair instructions:

```dart
// TODO: Implement text-to-speech for repair steps
// - Use flutter_tts package
// - Read instructions aloud
// - Pause/resume controls
// - Multi-language support

// Dependencies to add:
// - flutter_tts: ^3.8.0
```

---

### 9. Multi-Language Support

**Priority:** High (for global impact)  
**Effort:** Medium

Localize app for target regions:

```dart
// TODO: Add localization
// - Target languages: Hindi, Spanish, French, Swahili
// - Use flutter_localizations
// - Externalize all strings
// - RTL support if needed

// Dependencies to add:
// - flutter_localizations (from SDK)
// - intl: ^0.18.0
```

**Files to add:**
- `l10n.yaml`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hi.arb`
- `lib/l10n/app_es.arb`

---

### 10. Model Fine-Tuning

**Priority:** High (for accuracy)  
**Effort:** High

Fine-tune Gemma on pump repair images:

```
# TODO: Create fine-tuning dataset
# - Collect labeled pump images
# - Annotate fault regions
# - Train Gemma on structured output format
# - Evaluate on held-out test set
# - Deploy via Google AI API or convert for on-device
```

---

## Long-Term Vision

### 11. Technician Network

Connect users with local technicians when issues exceed DIY scope:

```dart
// TODO: Add technician referral system
// - Geolocation-based matching
// - In-app contact/request
// - Rating and feedback
// - Offline-capable contact cache
```

---

### 12. Predictive Maintenance

Track equipment health over time:

```dart
// TODO: Add maintenance tracking
// - Log inspections over time
// - Predict belt replacement needs
// - Send maintenance reminders
// - Generate equipment health reports
```

---

## Known Technical Debt

| Issue | Impact | Fix |
|-------|--------|-----|
| Mock inference only | Demo-only | Implement Gemma 4 integration |
| No image caching | Slow repeat views | Add cached_image package |
| Unused `_apiKey` field | Linter warning | Removed in progress |
| `withOpacity` deprecated | Future compatibility | Use `.withValues()` |
| No widget tests | Regression risk | Add comprehensive tests |

---

## Dependencies to Consider

```yaml
dependencies:
  # Current
  flutter_riverpod: ^2.5.1
  camera: ^0.11.0
  image_picker: ^1.1.2
  google_generative_ai: ^0.4.6
  path_provider: ^2.1.4
  
  # Future additions
  shared_preferences: ^2.2.0      # Local storage
  flutter_tts: ^3.8.0             # Text-to-speech
  flutter_localizations:          # i18n
  intl: ^0.18.0                   # i18n utilities
  cached_network_image: ^3.3.0    # Image caching
  sqflite: ^2.3.0                 # SQLite with optional vector
  arcore_flutter_plugin: ^0.2.0   # AR (Android)
```

---

**Last Updated:** 2026-04-10  
**Hackathon:** Kaggle Gemma 4 Good 2026
