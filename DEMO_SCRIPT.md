# VocaViz Demo Script

**Duration:** 2-3 minutes  
**Track:** Climate/Environment + Digital Equity

---

## Pre-Demo Checklist

- [ ] App builds and runs on device/emulator
- [ ] Camera permissions granted (if using live camera)
- [ ] Sample images load correctly
- [ ] Internet off (to demonstrate offline capability)

---

## Demo Flow

### Opening (15 seconds)

> "VocaViz helps farmers and technicians diagnose and repair water pump issues using just their phone camera - designed for low-connectivity environments where most agricultural work happens."

**Action:** Show app icon, open app

---

### Onboarding (20 seconds)

**Action:** Swipe through 4 onboarding pages

**Narration:**
- "Point & Analyze: Camera-first diagnosis"
- "See the Problem: Visual overlays highlight issues"
- "Follow Repair Steps: Step-by-step guidance"
- "Works Offline: No internet required"

> "The onboarding emphasizes this is a field tool, not a chatbot."

---

### Home Screen (10 seconds)

**Action:** Show home screen, point out key elements

**Narration:**
- "Clear primary action: Start Inspection"
- "Sample Images for demo reliability"
- "Supported machine type clearly stated"

---

### Sample Image Analysis (45 seconds)

**Action:** Tap "Sample Images" → Select "Loose Belt"

**Narration:**
> "In production, users point their camera at a real pump. For this demo, I'll use sample images."

**Action:** Watch analysis run with loading indicator

> "The app analyzes the image and returns structured results with confidence scores and highlighted problem regions."

**Action:** Show result screen with overlays

> "Red and orange boxes show detected issues - here we see belt sag indicating loose tension."

---

### Repair Guidance (45 seconds)

**Action:** Tap "Start Repair Guide"

**Narration:**
> "The repair flow is action-oriented with safety warnings built in. Each step is clear and includes caution notes where needed."

**Action:** Navigate through 2-3 repair steps

> "Notice the progress indicator, large buttons for field use, and safety tips. This isn't a chatbot - it's a guided workflow."

**Action:** Complete the repair

---

### Summary (15 seconds)

**Action:** Show summary screen

**Narration:**
> "Session summary shows confidence, detections, and steps completed. Users can start a new inspection or return home."

---

### Closing (15 seconds)

**Narration:**
> "VocaViz demonstrates how Gemma 4 can provide real-world impact in agriculture - offline-first, visual-first, and action-oriented. This is AI that works where it's needed most."

**Action:** Return to home screen

---

## Backup Demo Plan

If live demo fails:

1. **Use screen recording** of a previous successful run
2. **Show static screenshots** with narration
3. **Demo the code structure** to show inference abstraction

**Key message:** "The mock mode ensures demo reliability - the same abstraction layer will work with real Gemma 4 inference."

---

## Technical Talking Points

If asked about implementation:

| Topic | Response |
|-------|----------|
| **Gemma Integration** | "Currently mock mode for reliability. Architecture supports Gemma 4 multimodal API and on-device 2B model." |
| **Offline Capability** | "All repair knowledge is local JSON. Only inference requires connectivity - which can also run on-device." |
| **Accuracy** | "Mock data shows the UX. Real accuracy depends on Gemma 4's vision capabilities and fine-tuning." |
| **Scale** | "Starting with belt-driven pumps. Architecture supports adding machines via knowledge base." |

---

## Submission Checklist

- [ ] 3-minute demo video recorded
- [ ] Code pushed to GitHub
- [ ] README.md complete
- [ ] Technical write-up submitted
- [ ] Kaggle submission form completed

---

**Good luck at the hackathon!**
