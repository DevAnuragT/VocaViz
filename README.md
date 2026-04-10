# VocaViz

**Camera-based repair guidance for low-connectivity environments**

VocaViz is a Flutter mobile app built for the [Kaggle Gemma 4 Good Hackathon](https://www.kaggle.com/competitions/gemma-4-good-hackathon/overview). It helps users identify machine issues through camera analysis and provides step-by-step visual repair guidance.

## Why VocaViz?

### The Problem
- Agricultural equipment in rural areas often goes unrepaired due to lack of technical knowledge
- Low-connectivity environments make cloud-dependent solutions impractical
- Generic chatbots can't provide visual, action-oriented guidance

### The Solution
VocaViz is **app-native** by design:
- **Live camera interaction** - Point and analyze in real-time
- **On-field usage** - Works right next to the equipment
- **Offline-first** - Functions without continuous internet
- **Visual overlays** - Highlights problem areas directly on the image
- **Step-by-step mode** - Action-oriented repair flow, not text chat

## MVP Scope

**Supported Machine:** Belt-driven water pump (agricultural/irrigation)

**Detected Issues:**
| Issue | Description | Visual Cues |
|-------|-------------|-------------|
| Loose Belt | Excessive belt sag | Belt droop between pulleys |
| Worn Belt | Surface cracks/wear | Visible damage patterns |
| Misaligned Belt | Off-center tracking | Belt running off pulley edge |

**Out of Scope:**
- Multi-machine support
- Audio diagnostics
- Internal mechanical faults
- Full AR anchoring

## Quick Start

### Prerequisites
- Flutter SDK 3.7+
- Android Studio / Xcode
- Android device or emulator (camera-capable)

### Run the App
```bash
cd vocaviz
flutter pub get
flutter run
```

### Demo Mode
The app includes sample images for reliable demos:
1. Tap "Sample Images" on home screen
2. Select a fault type (loose/worn/misaligned belt)
3. View analysis with overlays and repair steps

## Architecture

```
lib/
├── app/                    # App-level widget and navigation
├── core/                   # Shared utilities and widgets
│   ├── constants/          # App constants and colors
│   ├── utils/              # Logger and helpers
│   └── widgets/            # Reusable UI components
├── data/                   # Data layer
│   ├── models/             # Domain models
│   ├── mock/               # Mock data for demos
│   └── repositories/       # Data access
├── features/               # Feature-first organization
│   ├── onboarding/         # Intro screens
│   ├── home/               # Home screen
│   ├── inspection/         # Camera and analysis
│   ├── guidance/           # Repair steps
│   ├── summary/            # Session summary
│   └── sample/             # Sample images
└── services/               # Business logic services
    └── inference_service.dart  # AI analysis abstraction
```

### Inference Abstraction

The `InferenceService` supports three interchangeable modes:

| Mode | Description | Use Case |
|------|-------------|----------|
| `mock` | Predefined results | Reliable demos, offline |
| `local` | On-device Gemma | Future: offline AI |
| `remote` | Google AI API | Future: cloud inference |

```dart
final service = InferenceService(mode: InferenceMode.mock);
final result = await service.analyze(imageBytes: bytes);
```

### Structured Output Schema

```json
{
  "machine_type": "belt_driven_water_pump",
  "issue_type": "loose_belt",
  "confidence": 0.87,
  "summary": "Detected excessive belt sag...",
  "detections": [
    {"label": "belt", "x": 0.25, "y": 0.35, "width": 0.5, "height": 0.15, "severity": "medium"}
  ],
  "repair_steps": [...],
  "stop_conditions": [...]
}
```

## Hackathon Alignment

| Criterion | How VocaViz Addresses It |
|-----------|-------------------------|
| **Innovation (30%)** | Camera-first repair guidance vs. text chatbots |
| **Impact (30%)** | Agricultural irrigation = food security |
| **Execution (25%)** | Focused scope, reliable demo |
| **Accessibility (15%)** | Offline-first, low-bandwidth design |

**Track Fit:** Climate/Environment + Digital Equity

## Demo Flow (2 minutes)

1. **Open app** → See onboarding (4 screens, swipe through)
2. **Home screen** → Tap "Sample Images"
3. **Select "Loose Belt"** → Watch analysis run
4. **See overlays** → Red/yellow boxes highlight problem areas
5. **Tap "Start Repair Guide"** → Step-by-step instructions
6. **Complete repair** → See summary screen

**Fallback:** If camera is unstable, use sample images throughout.

## Current Limitations

- [ ] Mock inference only (real Gemma integration pending)
- [ ] Single machine type (belt-driven pumps)
- [ ] No persistent history
- [ ] Sample images are placeholders

## Post-Hackathon Roadmap

See [TODO_NEXT.md](TODO_NEXT.md) for future improvements:
- Real Gemma 4 multimodal integration
- On-device inference with Gemma 2B
- Expanded machine catalog
- Vector-based repair knowledge retrieval
- True AR overlay with ARCore/ARKit

## Safety Disclaimer

VocaViz provides guidance only. Always:
- Turn off power before working on equipment
- Wear appropriate safety gear
- Consult a qualified technician if unsure

## License

Apache 2.0 (aligned with Gemma 4 Good requirements)

---

**Built with Flutter and ❤️ for the Gemma 4 Good Hackathon 2026**
